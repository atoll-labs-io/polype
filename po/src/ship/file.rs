//! `po ship file <id> [--file] [--hold <line>]… [--fixed <line>]…`: files the open findings of the
//! last review once the story's landing commit is on `Target branch` (ADR-0090, ADR-0124, ADR-0130).
//! Bare, it files nothing and lists what `--file` would file. It reads the review as it landed, with
//! the shape `po-gate findings-shape` accepts, and never files a `[security]` item, a `critical` one
//! or a line it did not recognise. A finding's text reaches a tracker only through a file under one
//! owner-only temporary folder: never an argument, an environment variable or a log.

use std::collections::HashSet;
use std::fs::{DirBuilder, File, OpenOptions};
use std::io::{Read, Write};
use std::os::unix::fs::{DirBuilderExt, OpenOptionsExt};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use serde::Serialize;
use serde_json::{json, Value};

use super::push::{self, Gh};
use super::{forge, land};
use crate::output;

const USAGE: &str = "usage: po ship file <id> [--file] [--hold <line>]... [--fixed <line>]...";
const SEVERITIES: [&str; 3] = ["critical", "major", "minor"];
const MARK: &str = "[security]";
/// `gh issue list --limit`: a listing that reaches it may have left a title out.
const LIMIT: usize = 1000;

struct Request {
    id: String,
    file: bool,
    hold: Vec<usize>,
    fixed: Vec<usize>,
}

#[derive(Serialize, Clone)]
struct Finding {
    line: usize,
    last: usize,
    severity: &'static str,
    title: String,
}

#[derive(Serialize)]
struct Security {
    count: Option<usize>,
    decision: Option<String>,
    lines: Vec<usize>,
}

#[derive(Serialize, Debug, PartialEq)]
struct Unrecognised {
    line: usize,
    text: Option<String>,
}

#[derive(Serialize, Clone)]
struct Group {
    lines: Vec<usize>,
    title: String,
    #[serde(skip)]
    body: String,
}

#[derive(Serialize)]
struct Filed {
    lines: Vec<usize>,
    title: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    url: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    uuid: Option<String>,
}

#[derive(Serialize)]
struct Reply {
    #[serde(skip_serializing_if = "Option::is_none")]
    state: Option<&'static str>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<&'static str>,
    #[serde(skip_serializing_if = "Option::is_none")]
    message: Option<String>,
    id: String,
    landed: String,
    tracker: String,
    findings: Vec<Finding>,
    pending: Vec<Group>,
    filed: Vec<Filed>,
    already_open: Vec<Group>,
    held: Vec<usize>,
    fixed: Vec<usize>,
    critical: Vec<Finding>,
    security: Security,
    unrecognised: Vec<Unrecognised>,
}

// ---------------------------------------------------------------------------------------------
// The review, read as `po-gate findings-shape` reads it (`method/hooks/po-gate.sh`).

struct Item {
    line: usize,
    last: usize,
    severity: &'static str,
    title: String,
    security: bool,
}

struct Parsed {
    items: Vec<Item>,
    fix_loop: Option<String>,
    count: Option<usize>,
    decision: Option<String>,
    unrecognised: Vec<Unrecognised>,
}

/// What follows the list marker `- `, `* ` or `<digits>. ` at column 0.
fn list_rest(line: &str) -> Option<&str> {
    line.strip_prefix("- ").or_else(|| line.strip_prefix("* ")).or_else(|| {
        let digits = line.bytes().take_while(u8::is_ascii_digit).count();
        (digits > 0).then(|| line[digits..].strip_prefix(". ")).flatten()
    })
}

/// `ships()` of the gate: the severity a list item opens with, bare or in bold, then `—`, `:` or `-`.
fn opens(line: &str) -> Option<&'static str> {
    let rest = list_rest(line)?;
    SEVERITIES.into_iter().find(|sev| {
        let bold = rest.strip_prefix("**").and_then(|r| r.strip_prefix(*sev));
        if bold.and_then(|r| r.strip_prefix(":**")).is_some() {
            return true;
        }
        let after = rest.strip_prefix(*sev).or_else(|| bold.and_then(|r| r.strip_prefix("**")));
        after.is_some_and(|r| r.trim_start_matches(' ').starts_with(['—', ':', '-']))
    })
}

fn word_byte(byte: u8) -> bool {
    byte.is_ascii_lowercase() || byte.is_ascii_digit() || byte == b'_'
}

/// `names()` of the gate: the text holds a severity as a whole word, in any case.
fn names(text: &str) -> bool {
    let lower = text.to_ascii_lowercase();
    let bytes = lower.as_bytes();
    SEVERITIES.iter().any(|word| {
        lower.match_indices(word).any(|(at, _)| {
            let end = at + word.len();
            (at == 0 || !word_byte(bytes[at - 1])) && (end == bytes.len() || !word_byte(bytes[end]))
        })
    })
}

/// `first()` of the gate: the first word, past any leading non-letter, is a severity.
fn first(text: &str) -> bool {
    let lower = text.trim_start_matches(|c: char| !c.is_ascii_alphabetic()).to_ascii_lowercase();
    SEVERITIES.iter().any(|word| {
        lower.strip_prefix(word).is_some_and(|rest| rest.bytes().next().is_none_or(|byte| !word_byte(byte)))
    })
}

fn verdict(line: &str) -> bool {
    let bare = line.strip_prefix("- ").or_else(|| line.strip_prefix("* ")).unwrap_or(line);
    bare.starts_with("Ship allowed:")
}

fn closes_section(line: &str) -> bool {
    let bare = line.strip_prefix("- ").or_else(|| line.strip_prefix("* ")).unwrap_or(line);
    line.starts_with("## ") || bare.starts_with("Max severity:") || bare.starts_with("Ship allowed:")
}

fn indented(line: &str) -> bool {
    line.starts_with([' ', '\t'])
}

/// `<id>: <severity> — <start>`, `<start>` the first line past its marker, severity and separator,
/// cut to 80 characters whatever the locale.
fn title_of(id: &str, severity: &str, line: &str) -> String {
    let mut start = list_rest(line).unwrap_or(line);
    start = start.strip_prefix("**").unwrap_or(start);
    start = start.strip_prefix(severity).unwrap_or(start);
    start = start.strip_prefix(':').unwrap_or(start);
    start = start.strip_prefix("**").unwrap_or(start);
    start = start.trim_start_matches(' ');
    start = start.strip_prefix(['—', ':', '-']).unwrap_or(start);
    start = start.trim_start_matches(' ');
    let cut: String = start.chars().take(80).collect();
    format!("{id}: {severity} — {}", cut.trim_end_matches(' ')).trim_end_matches(' ').to_string()
}

fn security_line(line: &str) -> Option<(Option<usize>, Option<String>)> {
    let rest = line.strip_prefix("Security findings:")?.trim();
    let (count, decision) = match rest.split_once(" — decision ") {
        Some((count, decision)) => (count.trim(), Some(decision.trim())),
        None => (rest.split_whitespace().next().unwrap_or_default(), None),
    };
    let decision = decision
        .filter(|d| d.strip_prefix("d-").is_some_and(|n| !n.is_empty() && n.bytes().all(|b| b.is_ascii_digit())))
        .map(str::to_string);
    Some((count.parse().ok(), decision))
}

/// The `## Findings` of the last review block. Line numbers count from 1; `Err` says why nothing can
/// be read.
fn parse_review(id: &str, text: &str) -> Result<Parsed, &'static str> {
    let lines: Vec<&str> = text.lines().collect();
    let line = |n: usize| lines[n - 1];
    let verdicts: Vec<usize> = (1..=lines.len()).filter(|&n| verdict(line(n))).collect();
    let Some(&last) = verdicts.last() else { return Err("the review has no verdict block (no `Ship allowed:` line)") };
    let prev = verdicts.len().checked_sub(2).map_or(0, |at| verdicts[at]);
    let is_findings = |l: &str| l.strip_prefix("## Findings").is_some_and(|rest| rest.trim().is_empty());
    let Some(start) = (prev + 1..last).find(|&n| is_findings(line(n))) else {
        return Err("the last review block has no `## Findings` section");
    };
    let end = (start + 1..last).find(|&n| closes_section(line(n))).unwrap_or(last);
    let fix_loop = (1..last).rev().map(line).find(|l| l.starts_with("Fix loop:")).map(|l| l.trim_end().to_string());

    let mut parsed = Parsed { items: Vec::new(), fix_loop, count: None, decision: None, unrecognised: Vec::new() };
    let mut secret = vec![false; lines.len() + 1];
    let mut n = start + 1;
    while n < end {
        let Some(severity) = opens(line(n)) else {
            if parsed.count.is_none() && parsed.decision.is_none() {
                if let Some((count, decision)) = security_line(line(n)) {
                    (parsed.count, parsed.decision) = (count, decision);
                }
            }
            n += 1;
            continue;
        };
        let (mut item_last, mut k, mut blank) = (n, n + 1, false);
        while k < end {
            let l = line(k);
            if list_rest(l).is_some() || l.starts_with('#') {
                break;
            }
            if l.trim().is_empty() {
                blank = true;
            } else if blank && !indented(l) {
                break;
            } else {
                blank = false;
                item_last = k;
            }
            k += 1;
        }
        let security = (n..=item_last).any(|m| line(m).to_lowercase().contains(MARK));
        if security {
            secret[n..=item_last].fill(true);
        }
        let title = if security { String::new() } else { title_of(id, severity, line(n)) };
        parsed.items.push(Item { line: n, last: item_last, severity, title, security });
        n = item_last + 1;
    }

    for n in start + 1..end {
        let l = line(n);
        let bad = if opens(l).is_some() {
            false
        } else if l.starts_with('#') {
            names(l)
        } else if l.is_empty() || indented(l) {
            false
        } else if let Some(rest) = list_rest(l) {
            names(rest)
        } else {
            first(l)
        };
        if bad {
            let hidden = secret[n] || l.to_lowercase().contains(MARK);
            parsed.unrecognised.push(Unrecognised { line: n, text: (!hidden).then(|| l.to_string()) });
        }
    }
    Ok(parsed)
}

// ---------------------------------------------------------------------------------------------
// The run.

fn usage(message: impl Into<String>) -> i32 {
    output::error(output::UNREADABLE, "usage", message)
}

fn line_number(value: Option<&String>) -> Option<usize> {
    let value = value?;
    if value.is_empty() || !value.bytes().all(|b| b.is_ascii_digit()) {
        return None;
    }
    value.parse().ok().filter(|n| *n > 0)
}

fn parse(args: &[String]) -> Result<Request, i32> {
    let mut request = Request { id: String::new(), file: false, hold: Vec::new(), fixed: Vec::new() };
    let mut id = None;
    let mut rest = args.iter();
    while let Some(arg) = rest.next() {
        match arg.as_str() {
            "--file" if !request.file => request.file = true,
            "--file" => return Err(usage(format!("--file is given once; {USAGE}"))),
            option @ ("--hold" | "--fixed") => {
                let Some(n) = line_number(rest.next()) else {
                    return Err(usage(format!("{option} takes a line number of the review; {USAGE}")));
                };
                if request.hold.contains(&n) || request.fixed.contains(&n) {
                    return Err(usage(format!("line {n} is given twice; {USAGE}")));
                }
                if option == "--hold" {
                    request.hold.push(n);
                } else {
                    request.fixed.push(n);
                }
            }
            other if other.starts_with('-') => {
                return Err(output::error(
                    output::UNREADABLE,
                    "unknown-option",
                    format!("po ship file takes no option {other}; {USAGE}"),
                ))
            }
            other if id.is_none() && land::is_id(other) => id = Some(other.to_string()),
            other if id.is_none() => return Err(usage(format!("{other} is not a story id (s<number>-<slug>); {USAGE}"))),
            other => return Err(usage(format!("unexpected argument {other}; {USAGE}"))),
        }
    }
    request.id = id.ok_or_else(|| usage(USAGE))?;
    Ok(request)
}

/// The owner-only folder the tracker files go through, removed on every return.
struct Scratch(PathBuf);

impl Drop for Scratch {
    fn drop(&mut self) {
        let _ = std::fs::remove_dir_all(&self.0);
    }
}

impl Scratch {
    fn new() -> Option<Scratch> {
        let nanos = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).ok()?.as_nanos();
        let path = std::env::temp_dir().join(format!("po-ship-file-{}-{nanos}", std::process::id()));
        DirBuilder::new().mode(0o700).create(&path).ok()?;
        Some(Scratch(path))
    }

    fn write(&self, name: &str, value: &Value) -> Option<String> {
        let path = self.0.join(name);
        let mut file = OpenOptions::new().write(true).create_new(true).mode(0o600).open(&path).ok()?;
        file.write_all(&serde_json::to_vec(value).ok()?).ok()?;
        path.to_str().map(str::to_string)
    }
}

fn uuid() -> Option<String> {
    let mut b = [0u8; 16];
    File::open("/dev/urandom").ok()?.read_exact(&mut b).ok()?;
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    let hex: String = b.iter().map(|byte| format!("{byte:02x}")).collect();
    Some(format!("{}-{}-{}-{}-{}", &hex[0..8], &hex[8..12], &hex[12..16], &hex[16..20], &hex[20..32]))
}

enum Task {
    Ran { ok: bool, stdout: String },
    Unstartable,
}

/// `task`, first on `PATH`; its stdout is captured, and its stderr is dropped on an import, whose
/// messages may quote what it imports.
fn task(top: &Path, args: &[&str], quiet: bool) -> Task {
    let ran = Command::new("task")
        .args(args)
        .current_dir(top)
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(if quiet { Stdio::null() } else { Stdio::inherit() })
        .output();
    match ran {
        Ok(out) => Task::Ran { ok: out.status.success(), stdout: String::from_utf8_lossy(&out.stdout).into_owned() },
        Err(_) => Task::Unstartable,
    }
}

/// Every value of `key` in a JSON array of objects; `None` when any element lacks it.
fn listed(stdout: &str, key: &str) -> Option<Vec<String>> {
    let Some(Value::Array(items)) = push::json(stdout) else { return None };
    items.iter().map(|item| push::text(item, key)).collect()
}

enum Tracker {
    GitHub(String),
    Taskwarrior(String),
}

impl Tracker {
    /// The titles already open, or the refusal that files nothing.
    fn open_titles(&self, top: &Path) -> Result<Vec<String>, (&'static str, String)> {
        match self {
            Tracker::GitHub(repo) => {
                let repo = format!("github.com/{repo}");
                let limit = LIMIT.to_string();
                let args = ["issue", "list", "--repo", &repo, "--state", "open", "--limit", &limit, "--json", "title"];
                let titles = match push::gh(top, &args, None) {
                    Gh::Unstartable => return Err(("tracker-unavailable", "gh cannot start".to_string())),
                    Gh::Ran { ok: true, stdout } => listed(&stdout, "title"),
                    Gh::Ran { ok: false, .. } => None,
                };
                let titles = titles.ok_or_else(|| {
                    ("listing-failed", format!("gh issue list on {repo} failed or did not answer a list of titles"))
                })?;
                if titles.len() >= LIMIT {
                    return Err((
                        "too-many-open",
                        format!("{repo} lists {LIMIT} open issues, gh's limit: a duplicate cannot be ruled out"),
                    ));
                }
                Ok(titles)
            }
            Tracker::Taskwarrior(name) => {
                let project = format!("project:{name}");
                let args = ["rc.confirmation=off", &project, "+issue", "status:pending", "export"];
                let titles = match task(top, &args, false) {
                    Task::Unstartable => return Err(("tracker-unavailable", "task cannot start".to_string())),
                    Task::Ran { ok: true, stdout } => listed(&stdout, "description"),
                    Task::Ran { ok: false, .. } => None,
                };
                titles.ok_or_else(|| ("listing-failed", format!("task export of {project} failed or did not answer a list")))
            }
        }
    }

    /// Files one group through a file of `scratch`; the issue URL or the task uuid.
    fn create(&self, top: &Path, scratch: &Scratch, n: usize, group: &Group) -> Option<Filed> {
        let mut filed = Filed { lines: group.lines.clone(), title: group.title.clone(), url: None, uuid: None };
        match self {
            Tracker::GitHub(repo) => {
                let input = scratch.write(&format!("issue-{n}.json"), &json!({"title": group.title, "body": group.body}))?;
                let path = format!("repos/{repo}/issues");
                let args = ["api", "--hostname", "github.com", "--method", "POST", &path, "--input", &input];
                let Gh::Ran { ok: true, stdout } = push::gh(top, &args, None) else { return None };
                filed.url = Some(push::json(&stdout).and_then(|value| push::text(&value, "html_url"))?);
            }
            Tracker::Taskwarrior(name) => {
                let uuid = uuid()?;
                let entry = chrono::Utc::now().format("%Y%m%dT%H%M%SZ").to_string();
                let value = json!({
                    "uuid": uuid,
                    "description": group.title,
                    "project": name,
                    "tags": ["issue"],
                    "status": "pending",
                    "annotations": [{"entry": entry, "description": group.body}],
                });
                let input = scratch.write(&format!("task-{n}.json"), &value)?;
                let Task::Ran { ok: true, .. } = task(top, &["rc.confirmation=off", "import", &input], true) else { return None };
                filed.uuid = Some(uuid);
            }
        }
        Some(filed)
    }
}

fn run(args: &[String]) -> Result<i32, i32> {
    let request = parse(args)?;
    let id = request.id.as_str();
    let (project, top) = land::worktree(id)?;
    let target = land::setting(&project, "Target branch", &[])?;
    if target == "—" {
        return Err(output::error(output::UNREADABLE, "missing-setting", "Target branch is — in AGENTS.local.md"));
    }
    let mode = land::setting(&project, "Merge mode", &["pr", "local"])?;
    let tracker = land::setting(&project, "Issue tracker", &["github", "taskwarrior", "—"])?;
    let title = land::title(&top, id)?;
    let base = land::base(&top, &mode, &target)?;
    let subject = format!("{id}: {title}");

    // Nothing is read from the review nor asked of a tracker before the landing is proven.
    let Some(landed) = land::landing_by_subject(&top, &base, id, &subject) else {
        return Err(output::error(
            output::REFUSED,
            "not-landed",
            format!("no commit of {target} is titled `{subject}`: {id} has not landed, and nothing is filed"),
        ));
    };
    let path = format!("docs/reviews/{id}.md");
    let Some(review) = land::read(&top, &["show", &format!("{landed}:{path}")]) else {
        return Err(output::error(output::UNREADABLE, "no-review", format!("the landing commit {landed} holds no {path}")));
    };
    let parsed = parse_review(id, &review).map_err(|why| output::error(output::UNREADABLE, "no-review", format!("{path}: {why}")))?;

    let openers: HashSet<usize> = parsed.items.iter().map(|item| item.line).collect();
    if let Some(n) = request.hold.iter().chain(&request.fixed).find(|n| !openers.contains(n)) {
        return Err(output::error(
            output::UNREADABLE,
            "unknown-finding",
            format!("line {n} of {path} opens no finding of the last review: nothing is filed"),
        ));
    }

    let finding = |item: &Item| Finding { line: item.line, last: item.last, severity: item.severity, title: item.title.clone() };
    let lines: Vec<&str> = review.lines().collect();
    let header = |severity: &str| {
        let fix_loop = parsed.fix_loop.as_deref().map(|l| format!("{l}\n")).unwrap_or_default();
        format!("Story: {id}\nReview: {path}\n{fix_loop}Severity: {severity}\nLanded: {landed}\n")
    };
    let mut pending: Vec<Group> = Vec::new();
    for item in parsed.items.iter().filter(|item| !item.security && item.severity != "critical") {
        if request.hold.contains(&item.line) || request.fixed.contains(&item.line) {
            continue;
        }
        let text = lines[item.line - 1..item.last].join("\n");
        match pending.iter_mut().find(|group| group.title == item.title) {
            Some(group) => {
                group.lines.push(item.line);
                group.body.push_str(&format!("\n\n{text}"));
            }
            None => pending.push(Group {
                lines: vec![item.line],
                title: item.title.clone(),
                body: format!("{}\n{text}", header(item.severity)),
            }),
        }
    }

    let mut reply = Reply {
        state: Some("listed"),
        error: None,
        message: None,
        id: id.to_string(),
        landed,
        tracker: tracker.clone(),
        findings: parsed.items.iter().filter(|i| !i.security && i.severity != "critical").map(finding).collect(),
        pending,
        filed: Vec::new(),
        already_open: Vec::new(),
        held: request.hold.clone(),
        fixed: request.fixed.clone(),
        critical: parsed
            .items
            .iter()
            .filter(|i| !i.security && i.severity == "critical" && !request.fixed.contains(&i.line))
            .map(finding)
            .collect(),
        security: Security {
            count: parsed.count,
            decision: parsed.decision,
            lines: parsed.items.iter().filter(|i| i.security).map(|i| i.line).collect(),
        },
        unrecognised: parsed.unrecognised,
    };
    if !request.file {
        return Ok(output::reply(reply, output::OK));
    }

    let tracker = match tracker.as_str() {
        "github" => match forge::github_repo(&project) {
            Some(repo) => Tracker::GitHub(repo),
            None => return Err(refuse(reply, "tracker-unavailable", "origin is not a github.com repository".to_string())),
        },
        "taskwarrior" => Tracker::Taskwarrior(forge::tracker_project(&project)),
        _ => {
            reply.state = Some("no-tracker");
            return Ok(output::reply(reply, output::OK));
        }
    };
    let open = match tracker.open_titles(&top) {
        Ok(open) => open,
        Err((error, message)) => return Err(refuse(reply, error, message)),
    };
    let Some(scratch) = Scratch::new() else {
        return Err(refuse(reply, "file-failed", "no owner-only temporary folder could be made: nothing is filed".to_string()));
    };
    let groups = std::mem::take(&mut reply.pending);
    for (n, group) in groups.iter().enumerate() {
        if open.contains(&group.title) {
            reply.already_open.push(group.clone());
            continue;
        }
        match tracker.create(&top, &scratch, n, group) {
            Some(filed) => reply.filed.push(filed),
            None => {
                reply.pending = groups[n..].iter().filter(|g| !open.contains(&g.title)).cloned().collect();
                let message = format!(
                    "filing `{}` failed after {} filed: run po ship file {id} --file again, which skips what is open",
                    group.title,
                    reply.filed.len()
                );
                return Err(refuse(reply, "file-failed", message));
            }
        }
    }
    reply.state = Some("filed");
    Ok(output::reply(reply, output::OK))
}

fn refuse(mut reply: Reply, error: &'static str, message: String) -> i32 {
    reply.state = None;
    reply.error = Some(error);
    reply.message = Some(message);
    output::reply(reply, output::REFUSED)
}

pub fn main(args: &[String]) -> i32 {
    match run(args) {
        Ok(code) | Err(code) => code,
    }
}

