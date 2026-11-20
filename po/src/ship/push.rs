//! `po ship push <id> --sha <sha> --body-file <file>`: under `Merge mode: pr`, sends the landing
//! commit to `story/<id>` on `origin` with a lease, opens or reuses its pull request and, under an
//! effective `automatic` only, waits for the forge's checks, reads the gate again and merges bound
//! to the commit sent (ADR-0080, ADR-0081, ADR-0130). It pushes only `story/<id>` and
//! `framing/ship-confirmation`, never `Target branch`. Every rerun resumes: the commit already on
//! `origin` wins over a rebuilt one, an open pull request is reused, a merged one ends the run.

use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use serde::Serialize;
use serde_json::Value;

use super::land::{self, Probe};
use super::{forge, git};
use crate::output;
use crate::project::{self, Project, Setting};
use crate::trust::forge::program;

const USAGE: &str = "usage: po ship push <id> --sha <sha> --body-file <file>";
const FRAMING: &str = "framing/ship-confirmation";
const CHORE: &str = "chore: Ship confirmation follows the forge";
const DRAFT_BODY: &str = "The forge's review rule no longer matches the `Ship confirmation` line of `AGENTS.local.md` \
(ADR-0079): this draft sets it to the value the forge implies. `/po-ship` already acts on that value; \
merging this pull request records it.\n";
const READINGS: u32 = 60;
/// Readings of a pull request's head before it is reported ready: a push may take a moment to
/// reach the forge's view of it.
const HEAD_READINGS: u32 = 10;
const POLL_SECONDS: u64 = 30;
const PR_FIELDS: &str = "number,state,url,headRefOid,isCrossRepository,headRepositoryOwner";

struct Request {
    id: String,
    sha: String,
    body: PathBuf,
}

struct Settings {
    target: String,
    line: String,
    forge_checks: Option<String>,
    wait: bool,
}

#[derive(Serialize)]
struct PullRequest {
    url: String,
    number: Option<u64>,
    created: bool,
}

#[derive(Serialize, Clone)]
struct CheckRun {
    name: String,
    bucket: String,
    link: Option<String>,
}

#[derive(Serialize)]
struct Rewrite {
    line: String,
    branch: Option<&'static str>,
    pushed: bool,
    url: Option<String>,
    refused: bool,
    /// What a person still does: `open-pull-request` from `branch` when no draft could be opened,
    /// `write-line` when `refused`; null when the draft is open or nothing is left to do.
    next: Option<&'static str>,
}

#[derive(Serialize)]
struct Pushed {
    id: String,
    sha: String,
    base: String,
    pushed: bool,
    pull_request: Option<PullRequest>,
    verdict: &'static str,
    effective: String,
    forge_checks: Option<String>,
    checks: Vec<CheckRun>,
    rewrite: Option<Rewrite>,
    state: &'static str,
}

#[derive(Serialize)]
struct ChecksFailed {
    error: &'static str,
    message: String,
    pull_request: String,
    checks: Vec<CheckRun>,
}

fn usage(message: impl Into<String>) -> i32 {
    output::error(output::UNREADABLE, "usage", message)
}

fn refused(error: &str, message: impl Into<String>) -> i32 {
    output::error(output::REFUSED, error, message)
}

fn parse(args: &[String]) -> Result<Request, i32> {
    let (mut id, mut sha, mut body) = (None, None, None);
    let mut rest = args.iter();
    while let Some(arg) = rest.next() {
        match arg.as_str() {
            "--sha" => match rest.next() {
                Some(value) if sha.is_none() && land::is_sha(value) => sha = Some(value.clone()),
                _ => return Err(usage(format!("--sha takes a full 40-hex commit, once; {USAGE}"))),
            },
            "--body-file" => match rest.next() {
                Some(value) if body.is_none() && !value.is_empty() => body = Some(PathBuf::from(value)),
                _ => return Err(usage(format!("--body-file takes a file, once; {USAGE}"))),
            },
            other if other.starts_with('-') => {
                return Err(output::error(
                    output::UNREADABLE,
                    "unknown-option",
                    format!("po ship push takes no option {other}; {USAGE}"),
                ))
            }
            other if id.is_none() && land::is_id(other) => id = Some(other.to_string()),
            other if id.is_none() => return Err(usage(format!("{other} is not a story id (s<number>-<slug>); {USAGE}"))),
            other => return Err(usage(format!("unexpected argument {other}; {USAGE}"))),
        }
    }
    let (Some(id), Some(sha), Some(body)) = (id, sha, body) else { return Err(usage(USAGE)) };
    let body = std::fs::canonicalize(&body)
        .ok()
        .filter(|path| std::fs::metadata(path).is_ok_and(|meta| meta.is_file() && meta.len() > 0))
        .ok_or_else(|| usage(format!("--body-file must name an existing, non-empty file; {USAGE}")))?;
    Ok(Request { id, sha, body })
}

fn settings(project: &Project) -> Result<Settings, i32> {
    let target = land::setting(project, "Target branch", &[])?;
    if target == "—" {
        return Err(output::error(output::UNREADABLE, "missing-setting", "Target branch is — in AGENTS.local.md"));
    }
    if land::setting(project, "Merge mode", &["pr", "local"])? != "pr" {
        return Err(usage(format!(
            "po ship push is for Merge mode: pr; under local, po ship land --land or --sha lands the commit. {USAGE}"
        )));
    }
    let line = land::setting(project, "Ship confirmation", &[])?;
    let forge_checks = match project.setting("Forge checks") {
        Setting::Missing => None,
        Setting::Value(value) if value == "required" || value == "—" => Some(value),
        Setting::Value(value) => {
            return Err(output::error(
                output::UNREADABLE,
                "unreadable-setting",
                format!("Forge checks: {value} is none of required, —"),
            ))
        }
    };
    let e2e_stage = land::setting(project, "E2E stage", &["ship", "ci", "—"])?;
    let build_stage = land::setting(project, "Build stage", &["ship-if-route", "ship", "ci", "—"])?;
    let wait = forge_checks.as_deref() == Some("required") || e2e_stage == "ci" || build_stage == "ci";
    Ok(Settings { target, line, forge_checks, wait })
}

/// The head `origin` holds for `reference` right now, never the tracking ref a fetch may have left.
fn ls_remote(top: &Path, reference: &str) -> Result<Option<String>, git::Ran> {
    let ran = git::run(top, &["ls-remote", "origin", reference]);
    if !ran.ok() {
        return Err(ran);
    }
    Ok(ran.stdout.lines().find_map(|line| {
        let (sha, name) = line.split_once('\t')?;
        (name == reference && land::is_sha(sha)).then(|| sha.to_string())
    }))
}

/// `git push` of `sha` to `reference` only, leased on the head `ls-remote` observed (none: the ref
/// must not exist yet). A refusal is never forced further.
fn push(top: &Path, sha: &str, reference: &str, observed: Option<&str>) -> Result<(), i32> {
    let lease = format!("--force-with-lease={reference}:{}", observed.unwrap_or_default());
    let refspec = format!("{sha}:{reference}");
    let ran = git::run(top, &["push", "-q", &lease, "origin", &refspec]);
    if ran.ok() {
        Ok(())
    } else {
        Err(ran.code)
    }
}

enum Gh {
    Ran { ok: bool, stdout: String },
    Unstartable,
}

/// `gh` with its own login: no token is ever passed to it, and its stderr reaches `po`'s stderr.
fn gh(top: &Path, args: &[&str], stdin: Option<&str>) -> Gh {
    let mut command = Command::new(program("PO_GH", "gh"));
    command
        .args(args)
        .current_dir(top)
        .env("GH_PROMPT_DISABLED", "1")
        .stdin(if stdin.is_some() { Stdio::piped() } else { Stdio::null() })
        .stdout(Stdio::piped())
        .stderr(Stdio::inherit());
    let Ok(mut child) = command.spawn() else { return Gh::Unstartable };
    if let (Some(input), Some(mut pipe)) = (stdin, child.stdin.take()) {
        let _ = pipe.write_all(input.as_bytes());
    }
    match child.wait_with_output() {
        Ok(out) => Gh::Ran { ok: out.status.success(), stdout: String::from_utf8_lossy(&out.stdout).into_owned() },
        Err(_) => Gh::Unstartable,
    }
}

fn json(stdout: &str) -> Option<Value> {
    serde_json::from_str(stdout.trim()).ok()
}

fn text(value: &Value, key: &str) -> Option<String> {
    value.get(key).and_then(Value::as_str).map(str::to_string)
}

enum Listing {
    Failed,
    /// A listed pull request does not say which repository its head lives in.
    Unsure,
}

/// Whether `pr`'s head branch lives in `owner`'s repository itself; `None` when gh did not say.
fn from_origin(pr: &Value, owner: &str) -> Option<bool> {
    let cross = pr.get("isCrossRepository")?.as_bool()?;
    let login = pr.get("headRepositoryOwner")?.get("login")?.as_str()?;
    Some(!cross && login.eq_ignore_ascii_case(owner))
}

/// The newest pull request (highest number) whose head is `head` in `repo` itself, in any state or
/// open only. Pull requests whose head lives elsewhere are left out, and one that cannot be placed
/// makes the whole listing unsure.
fn newest_pull_request(top: &Path, repo: &str, head: &str, state: &str) -> Result<Option<Value>, Listing> {
    let owner = repo.trim_start_matches("github.com/").split('/').next().unwrap_or_default();
    let Gh::Ran { ok: true, stdout } =
        gh(top, &["pr", "list", "--repo", repo, "--head", head, "--state", state, "--json", PR_FIELDS], None)
    else {
        return Err(Listing::Failed);
    };
    let Some(Value::Array(prs)) = json(&stdout) else { return Err(Listing::Failed) };
    let mut own = Vec::new();
    for pr in prs {
        match from_origin(&pr, owner) {
            Some(true) => own.push(pr),
            Some(false) => {}
            None => return Err(Listing::Unsure),
        }
    }
    Ok(own
        .into_iter()
        .filter(|pr| state == "all" || pr.get("state").and_then(Value::as_str) == Some("OPEN"))
        .max_by_key(|pr| pr.get("number").and_then(Value::as_u64).unwrap_or(0)))
}

fn head_of(top: &Path, repo: &str, url: &str) -> Result<Option<String>, ()> {
    match gh(top, &["pr", "view", url, "--repo", repo, "--json", "headRefOid"], None) {
        Gh::Unstartable => Err(()),
        Gh::Ran { stdout, .. } => Ok(json(&stdout).and_then(|value| text(&value, "headRefOid"))),
    }
}

/// Whether the pull request at `url` points at `sha`, read up to `HEAD_READINGS` times.
fn points_at(top: &Path, repo: &str, url: &str, sha: &str) -> bool {
    for reading in 0..HEAD_READINGS {
        if reading > 0 {
            std::thread::sleep(std::time::Duration::from_secs(poll_seconds()));
        }
        match head_of(top, repo, url) {
            Err(()) => return false,
            Ok(head) if head.as_deref() == Some(sha) => return true,
            Ok(_) => {}
        }
    }
    false
}

fn head_differs(url: &str, head: &str, sha: &str, id: &str) -> i32 {
    refused(
        "pr-head-differs",
        format!(
            "the pull request {url} of {head} does not point at the commit sent, {sha}: it is neither reported ready nor merged; \
             run po ship push {id} again, or a human looks"
        ),
    )
}

fn number_of(url: &str) -> Option<u64> {
    url.trim_end_matches('/').rsplit('/').next()?.parse().ok()
}

/// The URL `gh pr create` printed: its last line starting with `https://`.
fn created_url(stdout: &str) -> Option<String> {
    stdout.lines().rev().map(str::trim).find(|line| line.starts_with("https://")).map(str::to_string)
}

/// The first `Ship confirmation:` line holding a value, as `Project::setting` reads it.
fn confirmation(text: &str) -> Option<&str> {
    text.lines()
        .filter_map(|line| line.strip_prefix("Ship confirmation:"))
        .map(str::trim)
        .find(|value| !value.is_empty())
}

/// `text` with the value of that line replaced by `value`, its key and the spacing after the colon
/// kept.
fn with_confirmation(text: &str, value: &str) -> Option<String> {
    let mut done = false;
    let mut out = String::with_capacity(text.len() + value.len());
    for line in text.split_inclusive('\n') {
        let body = line.trim_end_matches(['\n', '\r']);
        match body.strip_prefix("Ship confirmation:") {
            Some(rest) if !done && !rest.trim().is_empty() => {
                let spacing = &rest[..rest.len() - rest.trim_start().len()];
                out.push_str(&format!("Ship confirmation:{spacing}{value}{}", &line[body.len()..]));
                done = true;
            }
            _ => out.push_str(line),
        }
    }
    done.then_some(out)
}

/// The settings commit, built on `origin/<target>` beside any checkout: its `AGENTS.local.md` alone
/// changes. Objects only; no ref moves here.
fn settings_commit(top: &Path, base_ref: &str, text: &str) -> Option<String> {
    let blob = git::run_input(top, &["hash-object", "-w", "--stdin"], text.as_bytes());
    let blob = blob.stdout.trim();
    if !land::is_sha(blob) {
        return None;
    }
    let listing = git::run(top, &["ls-tree", "-z", base_ref]);
    if !listing.ok() {
        return None;
    }
    let mut swapped = false;
    let mut entries = Vec::new();
    for entry in listing.stdout.split('\0').filter(|entry| !entry.is_empty()) {
        let (meta, name) = entry.split_once('\t')?;
        if name == "AGENTS.local.md" {
            let mut fields = meta.split(' ');
            let (mode, kind) = (fields.next()?, fields.next()?);
            entries.push(format!("{mode} {kind} {blob}\t{name}"));
            swapped = true;
        } else {
            entries.push(entry.to_string());
        }
    }
    if !swapped {
        return None;
    }
    let mut input = entries.join("\0");
    input.push('\0');
    let tree = git::run_input(top, &["mktree", "-z"], input.as_bytes());
    let tree = tree.stdout.trim();
    if !land::is_sha(tree) {
        return None;
    }
    let commit = git::run(top, &["commit-tree", tree, "-p", base_ref, "-m", CHORE]);
    let commit = commit.stdout.trim();
    land::is_sha(commit).then(|| commit.to_string())
}

/// The draft that rewrites a `(forge)` line (ADR-0080): `framing/ship-confirmation` on `origin`,
/// never `Target branch`, and its draft pull request on GitHub. Nothing here stops the ship: a
/// failure reports `refused` and the line to write by hand.
fn rewrite(top: &Path, target: &str, value: &str, repo: Option<&str>) -> Rewrite {
    let mut done =
        Rewrite { line: format!("Ship confirmation: {value}"), branch: None, pushed: false, url: None, refused: false, next: None };
    let by_hand = |mut done: Rewrite| {
        done.refused = true;
        done.next = Some("write-line");
        done
    };
    let base_ref = format!("refs/remotes/origin/{target}");
    let Some(current) = project::git(top, &["show", &format!("{base_ref}:AGENTS.local.md")]) else { return by_hand(done) };
    if confirmation(&current) == Some(value) {
        return done;
    }
    let Some(new_text) = with_confirmation(&current, value) else { return by_hand(done) };
    done.branch = Some(FRAMING);
    let reference = format!("refs/heads/{FRAMING}");
    let Ok(observed) = ls_remote(top, &reference) else { return by_hand(done) };
    let holds = observed.as_deref().filter(|head| {
        project::git(top, &["show", &format!("{head}:AGENTS.local.md")]).is_some_and(|sent| confirmation(&sent) == Some(value))
    });
    let sent = match holds {
        Some(head) => head.to_string(),
        None => {
            let Some(commit) = settings_commit(top, &base_ref, &new_text)
                .filter(|commit| push(top, commit, &reference, observed.as_deref()).is_ok())
            else {
                return by_hand(done);
            };
            done.pushed = true;
            commit
        }
    };
    let Some(repo) = repo else {
        done.next = Some("open-pull-request");
        return done;
    };
    let repo = format!("github.com/{repo}");
    done.url = match newest_pull_request(top, &repo, FRAMING, "open") {
        Ok(Some(pr)) => text_of_url(&pr).filter(|_| text(&pr, "headRefOid").as_deref() == Some(sent.as_str())),
        Ok(None) => match gh(
            top,
            &["pr", "create", "--repo", &repo, "--draft", "--base", target, "--head", FRAMING, "--title", CHORE, "--body-file", "-"],
            Some(DRAFT_BODY),
        ) {
            Gh::Ran { ok: true, stdout } => created_url(&stdout),
            _ => None,
        },
        Err(_) => None,
    };
    if done.url.is_none() {
        return by_hand(done);
    }
    done
}

fn text_of_url(pr: &Value) -> Option<String> {
    text(pr, "url").filter(|url| !url.is_empty())
}

fn poll_seconds() -> u64 {
    std::env::var("PO_SHIP_POLL_SECONDS").ok().and_then(|value| value.trim().parse().ok()).unwrap_or(POLL_SECONDS)
}

fn check_runs(value: &Value) -> Option<Vec<CheckRun>> {
    value
        .as_array()?
        .iter()
        .map(|check| {
            Some(CheckRun {
                name: text(check, "name").unwrap_or_default(),
                bucket: text(check, "bucket")?,
                link: text(check, "link").filter(|link| !link.is_empty()),
            })
        })
        .collect()
}

/// Reads the forge until every check of the commit sent passed, one failed, or the readings ran
/// out. An empty list is never a pass, and the decision comes from the JSON, never the exit code.
fn wait_for_checks(top: &Path, id: &str, repo: &str, url: &str, sha: &str) -> Result<Vec<CheckRun>, i32> {
    let unreadable = || refused("checks-unreadable", format!("gh cannot start to read the checks of {url}: a human looks; nothing was merged"));
    for reading in 0..READINGS {
        if reading > 0 {
            std::thread::sleep(std::time::Duration::from_secs(poll_seconds()));
        }
        let head = head_of(top, repo, url).map_err(|()| unreadable())?;
        if head.as_deref() != Some(sha) {
            continue;
        }
        let checks = match gh(top, &["pr", "checks", url, "--repo", repo, "--json", "name,bucket,link"], None) {
            Gh::Unstartable => return Err(unreadable()),
            Gh::Ran { stdout, .. } => json(&stdout).as_ref().and_then(check_runs),
        };
        let Some(checks) = checks.filter(|checks| !checks.is_empty()) else { continue };
        let failed: Vec<CheckRun> =
            checks.iter().filter(|check| matches!(check.bucket.as_str(), "fail" | "cancel")).cloned().collect();
        if !failed.is_empty() {
            let named: Vec<String> = failed
                .iter()
                .map(|check| format!("{} ({})", check.name, check.link.as_deref().unwrap_or("no link")))
                .collect();
            return Err(output::reply(
                ChecksFailed {
                    error: "checks-failed",
                    message: format!(
                        "the forge's checks failed on {url}: {}; nothing was merged, and the story goes back to /po-execute {id} as a fix run",
                        named.join(", ")
                    ),
                    pull_request: url.to_string(),
                    checks: failed,
                },
                output::REFUSED,
            ));
        }
        if checks.iter().all(|check| matches!(check.bucket.as_str(), "pass" | "skipping")) {
            return Ok(checks);
        }
    }
    Err(refused(
        "checks-timeout",
        format!("no complete, passing set of checks on {url} after {READINGS} readings: a human looks; nothing was merged"),
    ))
}

fn run(args: &[String]) -> Result<i32, i32> {
    let request = parse(args)?;
    let id = request.id.as_str();
    let (project, top) = land::worktree(id)?;
    land::gate(&top, id)?;
    let settings = settings(&project)?;
    land::remote_check(&top, "pr")?;
    let title = land::title(&top, id)?;
    let base = land::base(&top, "pr", &settings.target)?;
    let subject = format!("{id}: {title}");

    // The effective value comes from the forge and the line alone: no caller can ask for a merge.
    let reading = forge::read(&project, &settings.target);
    let verdict = reading.verdict();
    let (effective, rewrite_to) = super::effective(&settings.line, verdict);
    let repo = forge::github_repo(&project);
    let rewrite = rewrite_to.map(|value| rewrite(&top, &settings.target, value, repo.as_deref()));

    let mut reply = Pushed {
        id: id.to_string(),
        sha: request.sha.clone(),
        base: base.clone(),
        pushed: false,
        pull_request: None,
        verdict,
        effective,
        forge_checks: settings.forge_checks.clone(),
        checks: Vec::new(),
        rewrite,
        state: "merged",
    };

    if let Some(landed) = land::landing_by_subject(&top, &base, id, &subject) {
        reply.sha = landed;
        return Ok(output::reply(reply, output::OK));
    }

    let tree = match land::probe(&top, &base, id)? {
        Probe::Clean(tree) => tree,
        Probe::Conflict(paths) => return Err(land::conflict(paths, "")),
    };

    // The commit already on origin wins while it is still the landing: a rebuilt one carries
    // another sha for the same tree, and sending it would replace what a pull request points at.
    let story_ref = format!("refs/heads/story/{id}");
    let observed = ls_remote(&top, &story_ref).map_err(|ran| land::git_failed("git ls-remote origin", &ran))?;
    match observed.as_deref() {
        Some(head) if land::still_the_landing(&top, head, &base, &subject, &tree) => reply.sha = head.to_string(),
        _ if land::still_the_landing(&top, &request.sha, &base, &subject, &tree) => {
            if let Err(code) = push(&top, &request.sha, &story_ref, observed.as_deref()) {
                return Err(refused(
                    "push-refused",
                    format!("git push of story/{id} exited {code}: origin or the lease refused it; it is never forced further, a human looks"),
                ));
            }
            reply.pushed = true;
        }
        _ => {
            return Err(refused(
                "stale-landing",
                format!("{} is no longer the landing of {id} on {}: run po ship land {id} again", request.sha, settings.target),
            ))
        }
    }

    let Some(repo) = repo else {
        reply.state = "no-pull-request";
        return Ok(output::reply(reply, output::OK));
    };
    let repo = format!("github.com/{repo}");
    let head = format!("story/{id}");
    let found = newest_pull_request(&top, &repo, &head, "all").map_err(|listing| match listing {
        Listing::Failed => refused("pr-unreadable", format!("gh pr list cannot read the pull requests of {head}")),
        Listing::Unsure => refused(
            "pr-unreadable",
            format!("a pull request of {head} does not say which repository it comes from: none is used; a human looks"),
        ),
    })?;
    let pull_request = match found {
        Some(pr) => {
            let url = text_of_url(&pr).ok_or_else(|| refused("pr-unreadable", format!("a pull request of {head} has no URL")))?;
            match pr.get("state").and_then(Value::as_str) {
                Some("MERGED") if text(&pr, "headRefOid").as_deref() != Some(reply.sha.as_str()) => {
                    return Err(head_differs(&url, &head, &reply.sha, id))
                }
                Some("MERGED") => {
                    reply.pull_request = Some(PullRequest { number: number_of(&url), url, created: false });
                    return Ok(output::reply(reply, output::OK));
                }
                Some("CLOSED") => {
                    return Err(refused(
                        "pull-request-closed",
                        format!("the pull request {url} of {head} was closed without a merge: a human decides"),
                    ))
                }
                Some("OPEN") => PullRequest { number: number_of(&url), url, created: false },
                _ => return Err(refused("pr-unreadable", format!("the pull request {url} has no readable state"))),
            }
        }
        None => {
            let body = request.body.to_string_lossy();
            let created = match gh(
                &top,
                &["pr", "create", "--repo", &repo, "--base", &settings.target, "--head", &head, "--title", &subject, "--body-file", &body],
                None,
            ) {
                Gh::Ran { ok: true, stdout } => created_url(&stdout),
                _ => None,
            };
            let url = created.ok_or_else(|| {
                refused("pr-failed", format!("gh pr create from {head} failed; the commit is sent, run po ship push {id} again"))
            })?;
            PullRequest { number: number_of(&url), url, created: true }
        }
    };
    let url = pull_request.url.clone();
    reply.pull_request = Some(pull_request);

    if reply.effective != "automatic" {
        if !points_at(&top, &repo, &url, &reply.sha) {
            return Err(head_differs(&url, &head, &reply.sha, id));
        }
        reply.state = "waiting-for-human";
        return Ok(output::reply(reply, output::OK));
    }

    if settings.wait {
        reply.checks = wait_for_checks(&top, id, &repo, &url, &reply.sha)?;
    }
    land::gate(&top, id)?;
    let merged = gh(&top, &["pr", "merge", &url, "--repo", &repo, "--rebase", "--match-head-commit", &reply.sha], None);
    if !matches!(merged, Gh::Ran { ok: true, .. }) {
        return Err(refused(
            "merge-refused",
            format!("gh pr merge {url} failed: nothing proves a merge; run po ship push {id} again or ask a human"),
        ));
    }
    reply.state = match gh(&top, &["pr", "view", &url, "--repo", &repo, "--json", "state"], None) {
        Gh::Ran { stdout, .. } if json(&stdout).and_then(|value| text(&value, "state")).as_deref() == Some("MERGED") => "merged",
        _ => "merging",
    };
    Ok(output::reply(reply, output::OK))
}

pub fn main(args: &[String]) -> i32 {
    match run(args) {
        Ok(code) | Err(code) => code,
    }
}
