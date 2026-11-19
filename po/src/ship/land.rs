//! `po ship land <id>`: the ship gate, the checks of `/po-ship` Step 1, then the landing commit
//! built beside `story/<id>` (ADR-0081) and, under `Merge mode: local`, the fast-forward of the
//! root. Nothing is ever pushed. One JSON object on stdout; the checks' output goes to stderr.

use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use serde::Serialize;

use super::git;
use crate::output;
use crate::project::{self, Project, Setting};

const USAGE: &str = "usage: po ship land <id> [--routes yes|no] [--land] | po ship land <id> --sha <sha>";

enum Action {
    Build,
    BuildAndLand,
    Land(String),
}

struct Request {
    id: String,
    routes: Option<bool>,
    action: Action,
}

struct Settings {
    target: String,
    mode: String,
    full_suite: String,
    e2e_stage: String,
    build_stage: String,
    test: String,
    e2e: String,
    build: String,
}

#[derive(Serialize, Clone)]
struct Check {
    check: &'static str,
    outcome: &'static str,
    command: Option<String>,
}

#[derive(Serialize)]
struct Landing {
    id: String,
    mode: String,
    base: String,
    tree: String,
    sha: String,
    title: String,
    committed: Option<String>,
    checks: Vec<Check>,
    landed: bool,
    already_landed: bool,
}

#[derive(Serialize)]
struct Conflict {
    error: &'static str,
    message: String,
    paths: Vec<String>,
}

#[derive(Serialize)]
struct CheckFailed {
    error: &'static str,
    message: String,
    check: &'static str,
    exit: i32,
    checks: Vec<Check>,
}

fn usage(message: impl Into<String>) -> i32 {
    output::error(output::UNREADABLE, "usage", message)
}

/// `s<number>-<slug>`, as `po-run` accepts it.
fn is_id(text: &str) -> bool {
    let Some((number, slug)) = text.strip_prefix('s').and_then(|rest| rest.split_once('-')) else {
        return false;
    };
    !number.is_empty()
        && number.bytes().all(|b| b.is_ascii_digit())
        && slug.bytes().next().is_some_and(|b| b.is_ascii_lowercase() || b.is_ascii_digit())
        && slug.bytes().all(|b| b.is_ascii_lowercase() || b.is_ascii_digit() || b == b'-')
}

fn is_sha(text: &str) -> bool {
    text.len() == 40 && text.bytes().all(|b| b.is_ascii_digit() || (b'a'..=b'f').contains(&b))
}

fn parse(args: &[String]) -> Result<Request, i32> {
    let (mut id, mut routes, mut land, mut sha) = (None, None, false, None);
    let mut rest = args.iter();
    while let Some(arg) = rest.next() {
        match arg.as_str() {
            "--routes" => match rest.next().map(String::as_str) {
                Some("yes") if routes.is_none() => routes = Some(true),
                Some("no") if routes.is_none() => routes = Some(false),
                _ => return Err(usage(format!("--routes takes yes or no, once; {USAGE}"))),
            },
            "--land" if !land => land = true,
            "--land" => return Err(usage(format!("--land is given once; {USAGE}"))),
            "--sha" => match rest.next() {
                Some(value) if sha.is_none() && is_sha(value) => sha = Some(value.clone()),
                _ => return Err(usage(format!("--sha takes a full 40-hex commit, once; {USAGE}"))),
            },
            other if other.starts_with('-') => {
                return Err(output::error(
                    output::UNREADABLE,
                    "unknown-option",
                    format!("po ship land takes no option {other}; {USAGE}"),
                ))
            }
            other if id.is_none() && is_id(other) => id = Some(other.to_string()),
            other if id.is_none() => return Err(usage(format!("{other} is not a story id (s<number>-<slug>); {USAGE}"))),
            other => return Err(usage(format!("unexpected argument {other}; {USAGE}"))),
        }
    }
    let Some(id) = id else { return Err(usage(USAGE)) };
    let action = match (land, sha) {
        (true, Some(_)) => return Err(usage(format!("--land and --sha exclude each other; {USAGE}"))),
        (true, None) => Action::BuildAndLand,
        (false, Some(sha)) => Action::Land(sha),
        (false, None) => Action::Build,
    };
    Ok(Request { id, routes, action })
}

/// The project and the top of the worktree `po` runs in, once it is shown to be on `story/<id>`.
fn worktree(id: &str) -> Result<(Project, PathBuf), i32> {
    let cwd = std::env::current_dir().ok();
    let Some((project, cwd)) = cwd.as_deref().and_then(Project::find).zip(cwd.as_deref()) else {
        return Err(output::error(
            output::UNREADABLE,
            "not-a-project",
            "not inside a Polype project: no AGENTS.local.md nor .polype/version at the repository root",
        ));
    };
    let Some(top) = project::git(cwd, &["rev-parse", "--show-toplevel"]).map(|out| PathBuf::from(out.trim())) else {
        return Err(output::error(output::UNREADABLE, "not-a-project", "no work tree around the current directory"));
    };
    let branch = project::git(&top, &["rev-parse", "--abbrev-ref", "HEAD"]).map(|out| out.trim().to_string());
    let want = format!("story/{id}");
    if branch.as_deref() != Some(want.as_str()) {
        return Err(output::error(
            output::UNREADABLE,
            "wrong-branch",
            format!(
                "{} is on {}, not {want}: run po ship land in the story worktree",
                top.display(),
                branch.as_deref().unwrap_or("no branch")
            ),
        ));
    }
    Ok((project, top))
}

enum Hook {
    Ran { code: i32, stderr: String },
    Missing,
    Unstartable(String),
}

/// A hook of `.polype/hooks/` run from the worktree. With `pass_through`, its stdout goes to `po`'s
/// stderr so that `po`'s stdout keeps its one JSON object.
fn hook(top: &Path, script: &str, args: &[&str], pass_through: bool) -> Hook {
    let path = top.join(".polype/hooks").join(script);
    if !path.is_file() {
        return Hook::Missing;
    }
    let mut command = Command::new("bash");
    command.arg(&path).args(args).current_dir(top).stdin(Stdio::null());
    let ran = if pass_through {
        command
            .stdout(Stdio::from(std::io::stderr()))
            .stderr(Stdio::inherit())
            .status()
            .map(|status| (status.code().unwrap_or(-1), String::new()))
    } else {
        command
            .env("GIT_OPTIONAL_LOCKS", "0")
            .output()
            .map(|out| (out.status.code().unwrap_or(-1), String::from_utf8_lossy(&out.stderr).into_owned()))
    };
    match ran {
        Ok((code, stderr)) => Hook::Ran { code, stderr },
        Err(err) => Hook::Unstartable(format!("bash cannot start: {err}")),
    }
}

fn gate(top: &Path, id: &str) -> Result<(), i32> {
    match hook(top, "po-gate.sh", &["ship-allowed", id], false) {
        Hook::Ran { code: 0, .. } => Ok(()),
        Hook::Ran { stderr, .. } => Err(output::error(output::REFUSED, "gate-refused", stderr.trim())),
        Hook::Missing => Err(output::error(
            output::UNREADABLE,
            "no-gate",
            ".polype/hooks/po-gate.sh is missing from the worktree: run polype install",
        )),
        Hook::Unstartable(message) => Err(output::error(output::UNREADABLE, "no-gate", message)),
    }
}

fn setting(project: &Project, name: &str, allowed: &[&str]) -> Result<String, i32> {
    let Setting::Value(value) = project.setting(name) else {
        return Err(output::error(output::UNREADABLE, "missing-setting", format!("no {name} in AGENTS.local.md")));
    };
    if !allowed.is_empty() && !allowed.contains(&value.as_str()) {
        return Err(output::error(
            output::UNREADABLE,
            "unreadable-setting",
            format!("{name}: {value} is none of {}", allowed.join(", ")),
        ));
    }
    Ok(value)
}

fn settings(project: &Project) -> Result<Settings, i32> {
    let target = setting(project, "Target branch", &[])?;
    if target == "—" {
        return Err(output::error(output::UNREADABLE, "missing-setting", "Target branch is — in AGENTS.local.md"));
    }
    Ok(Settings {
        target,
        mode: setting(project, "Merge mode", &["pr", "local"])?,
        full_suite: setting(project, "Full suite", &["execute-end", "ship", "both"])?,
        e2e_stage: setting(project, "E2E stage", &["ship", "ci", "—"])?,
        build_stage: setting(project, "Build stage", &["ship-if-route", "ship", "ci", "—"])?,
        test: setting(project, "Test", &[])?,
        e2e: setting(project, "E2E", &[])?,
        build: setting(project, "Build", &[])?,
    })
}

fn remote_check(top: &Path, mode: &str) -> Result<(), i32> {
    let origin = project::git(top, &["remote", "get-url", "origin"]).is_some();
    match (mode, origin) {
        ("pr", false) => Err(output::error(
            output::REFUSED,
            "remote-check",
            "Merge mode: pr with no origin remote: a repository without a remote uses `local`",
        )),
        ("local", true) => Err(output::error(
            output::REFUSED,
            "remote-check",
            "`Merge mode: local` is only for a repository without a remote (ADR-0080); set it to `pr`.",
        )),
        _ => Ok(()),
    }
}

/// The title of the heading `## <id> — <title>` or `### <id> — <title>` of `docs/stories.md`.
fn title(top: &Path, id: &str) -> Result<String, i32> {
    let text = std::fs::read_to_string(top.join("docs/stories.md")).unwrap_or_default();
    let found = text.lines().find_map(|line| {
        let heading = line.strip_prefix("### ").or_else(|| line.strip_prefix("## "))?;
        let title = heading.strip_prefix(id)?.strip_prefix(" — ")?.trim();
        (!title.is_empty()).then(|| title.to_string())
    });
    found.ok_or_else(|| {
        output::error(output::UNREADABLE, "no-title", format!("docs/stories.md has no heading `## {id} — <title>`"))
    })
}

/// The root sits on `Target branch` with no staged or modified tracked file.
fn root_clean(project: &Project, target: &str) -> Result<(), i32> {
    let root = project.root.display();
    let branch = project.git(&["symbolic-ref", "--short", "-q", "HEAD"]).map(|out| out.trim().to_string());
    if branch.as_deref() != Some(target) {
        return Err(output::error(
            output::REFUSED,
            "root-not-clean",
            format!("{root} is on {}, not {target}", branch.as_deref().unwrap_or("no branch")),
        ));
    }
    match project.git(&["status", "--porcelain", "--untracked-files=no"]) {
        Some(status) if status.trim().is_empty() => Ok(()),
        Some(status) => Err(output::error(
            output::REFUSED,
            "root-not-clean",
            format!(
                "{root} holds uncommitted tracked changes: {}",
                status.lines().map(str::trim).collect::<Vec<_>>().join("; ")
            ),
        )),
        None => Err(output::error(output::REFUSED, "root-not-clean", format!("git status cannot read {root}"))),
    }
}

fn git_failed(what: &str, ran: &git::Ran) -> i32 {
    output::error(
        output::UNREADABLE,
        "git-failed",
        format!("{what} exited {}: {}", ran.code, ran.stderr.trim()),
    )
}

fn base(top: &Path, settings: &Settings) -> Result<String, i32> {
    let reference = if settings.mode == "pr" {
        let ran = git::run(top, &["fetch", "-q", "origin"]);
        if !ran.ok() {
            return Err(git_failed("git fetch origin", &ran));
        }
        format!("refs/remotes/origin/{}", settings.target)
    } else {
        format!("refs/heads/{}", settings.target)
    };
    project::git(top, &["rev-parse", "--verify", "-q", &format!("{reference}^{{commit}}")])
        .map(|out| out.trim().to_string())
        .filter(|sha| !sha.is_empty())
        .ok_or_else(|| output::error(output::UNREADABLE, "no-base", format!("{reference} does not exist")))
}

enum Probe {
    Clean(String),
    Conflict(Vec<String>),
}

/// `git merge-tree` of the base and the story branch, which writes objects but no ref.
fn probe(top: &Path, base: &str, id: &str) -> Result<Probe, i32> {
    let branch = format!("story/{id}");
    let ran = git::run(top, &["merge-tree", "--write-tree", "--name-only", "--no-messages", "-z", base, &branch]);
    let mut fields = ran.stdout.split('\0').map(str::trim);
    let tree = fields.next().unwrap_or_default().to_string();
    match ran.code {
        0 if !tree.is_empty() => Ok(Probe::Clean(tree)),
        1 => {
            let mut paths: Vec<String> = Vec::new();
            for path in fields.filter(|path| !path.is_empty()) {
                if !paths.iter().any(|seen| seen == path) {
                    paths.push(path.to_string());
                }
            }
            Ok(Probe::Conflict(paths))
        }
        _ => Err(git_failed("git merge-tree", &ran)),
    }
}

fn conflict(paths: Vec<String>, after: &str) -> i32 {
    output::reply(
        Conflict {
            error: "conflict",
            message: format!(
                "story branch and base conflict on {}{after}: a human resolves it",
                paths.join(", ")
            ),
            paths,
        },
        output::REFUSED,
    )
}

/// What a check does at ship: run a command, or nothing, with the outcome saying why.
enum Plan {
    Run(String),
    Not(&'static str),
}

fn command(text: &str) -> Plan {
    if text == "—" {
        Plan::Not("absent")
    } else {
        Plan::Run(text.to_string())
    }
}

fn checks(top: &Path, id: &str, settings: &Settings, routes: Option<bool>) -> Result<Vec<Check>, i32> {
    let recorded = settings.full_suite == "execute-end"
        && matches!(hook(top, "po-gate.sh", &["verif-current", id], false), Hook::Ran { code: 0, .. });
    let unit = if recorded { Plan::Not("recorded") } else { command(&settings.test) };
    let e2e = if settings.e2e_stage == "ship" { command(&settings.e2e) } else { Plan::Not("not-at-ship") };
    let build = match (settings.build_stage.as_str(), routes) {
        ("ship", _) | ("ship-if-route", Some(true)) => command(&settings.build),
        ("ship-if-route", _) => Plan::Not("skipped"),
        _ => Plan::Not("not-at-ship"),
    };
    let mut done = Vec::new();
    for (check, plan) in [("unit suite", unit), ("end to end", e2e), ("build", build)] {
        let text = match plan {
            Plan::Not(outcome) => {
                done.push(Check { check, outcome, command: None });
                continue;
            }
            Plan::Run(text) => text,
        };
        let label = format!("ship: {check}");
        match hook(top, "po-run.sh", &["--story", id, "--label", &label, "--", &text], true) {
            Hook::Ran { code: 0, .. } => done.push(Check { check, outcome: "passed", command: Some(text) }),
            Hook::Ran { code: 125, .. } => {
                return Err(output::error(
                    output::UNREADABLE,
                    "check-unrunnable",
                    format!("po-run refused to run the {check} or to record it; its reason is on stderr"),
                ))
            }
            Hook::Ran { code, .. } => {
                return Err(output::reply(
                    CheckFailed {
                        error: "check-failed",
                        message: format!("the {check} `{text}` exited {code}: the story goes back to /po-execute {id} as a fix run"),
                        check,
                        exit: code,
                        checks: done,
                    },
                    output::REFUSED,
                ))
            }
            Hook::Missing => {
                return Err(output::error(
                    output::UNREADABLE,
                    "check-unrunnable",
                    ".polype/hooks/po-run.sh is missing from the worktree: run polype install",
                ))
            }
            Hook::Unstartable(message) => return Err(output::error(output::UNREADABLE, "check-unrunnable", message)),
        }
    }
    Ok(done)
}

/// Commits the review and the record rows the checks appended on `story/<id>`, so they land with it.
fn commit_docs(top: &Path, id: &str) -> Result<Option<String>, i32> {
    let paths: Vec<String> = [format!("docs/reviews/{id}.md"), format!("docs/verif/{id}.md")]
        .into_iter()
        .filter(|path| top.join(path).is_file())
        .filter(|path| project::git(top, &["status", "--porcelain", "--", path]).is_some_and(|out| !out.trim().is_empty()))
        .collect();
    if paths.is_empty() {
        return Ok(None);
    }
    let paths: Vec<&str> = paths.iter().map(String::as_str).collect();
    let ran = git::run(top, &[&["add", "--"][..], &paths].concat());
    if !ran.ok() {
        return Err(git_failed("git add", &ran));
    }
    let message = format!("{id}: review");
    let ran = git::run(top, &[&["commit", "-q", "-m", &message, "--"][..], &paths].concat());
    if !ran.ok() {
        return Err(git_failed("git commit", &ran));
    }
    Ok(project::git(top, &["rev-parse", "HEAD"]).map(|out| out.trim().to_string()))
}

fn fast_forward(project: &Project, settings: &Settings, sha: &str) -> Result<(), i32> {
    root_clean(project, &settings.target)?;
    let ran = git::run(&project.root, &["merge", "--ff-only", "-q", sha]);
    if ran.ok() {
        Ok(())
    } else {
        Err(git_failed("git merge --ff-only", &ran))
    }
}

/// The commit `sha` is still this story's landing on `base`: its only parent, its subject, its tree.
fn still_the_landing(top: &Path, sha: &str, base: &str, subject: &str, tree: &str) -> bool {
    read(top, &["rev-list", "--parents", "-n", "1", sha]).as_deref() == Some(format!("{sha} {base}").as_str())
        && read(top, &["log", "-1", "--format=%s", sha]).as_deref() == Some(subject)
        && read(top, &["rev-parse", &format!("{sha}^{{tree}}")]).as_deref() == Some(tree)
}

/// Under `local`, `--land` skips the person's Merge answer, so the line itself must read `automatic`:
/// with no remote there is no forge to override it (ADR-0080).
fn confirmation_allows_landing(project: &Project) -> Result<(), i32> {
    let Setting::Value(line) = project.setting("Ship confirmation") else {
        return Err(output::error(output::UNREADABLE, "missing-setting", "no Ship confirmation in AGENTS.local.md"));
    };
    match super::origin(&line).0 {
        "automatic" => Ok(()),
        value => Err(output::error(
            output::REFUSED,
            "confirmation-required",
            format!(
                "Ship confirmation is {value}, not automatic: build without --land, ask the person, then land with --sha <sha>"
            ),
        )),
    }
}

fn read(top: &Path, args: &[&str]) -> Option<String> {
    project::git(top, args).map(|out| out.trim_end_matches('\n').to_string())
}

/// The newest commit of `base` outside `story/<id>` whose subject is exactly `subject`. Ids are never
/// reused, so it is this story's landing whatever the base did to its lines afterwards.
fn landing_by_subject(top: &Path, base: &str, id: &str, subject: &str) -> Option<String> {
    let story = format!("^story/{id}");
    read(top, &["log", "-F", &format!("--grep={subject}"), "--format=%H%x1f%s", base, &story])?
        .lines()
        .find_map(|line| line.split_once('\x1f').filter(|(_, found)| *found == subject).map(|(sha, _)| sha.to_string()))
}

/// `story/<id>` holds no change of its own since it left `base`.
fn brings_nothing(top: &Path, base: &str, id: &str) -> bool {
    let branch = format!("story/{id}");
    let Some(fork) = read(top, &["merge-base", base, &branch]) else { return false };
    read(top, &["rev-parse", &format!("{branch}^{{tree}}")]) == read(top, &["rev-parse", &format!("{fork}^{{tree}}")])
}

fn already_landed(id: &str, mode: &str, base: String, tree: String, sha: String, title: String) -> i32 {
    output::reply(
        Landing {
            id: id.to_string(),
            mode: mode.to_string(),
            base,
            tree,
            sha,
            title,
            committed: None,
            checks: Vec::new(),
            landed: true,
            already_landed: true,
        },
        output::OK,
    )
}

fn run(args: &[String]) -> Result<i32, i32> {
    let request = parse(args)?;
    let id = request.id.as_str();
    let (project, top) = worktree(id)?;
    gate(&top, id)?;
    let settings = settings(&project)?;
    if settings.mode == "pr" && !matches!(request.action, Action::Build) {
        return Err(usage(format!(
            "--land and --sha are for Merge mode: local; under pr the landing commit goes through a pull request. {USAGE}"
        )));
    }
    if matches!(request.action, Action::BuildAndLand) {
        confirmation_allows_landing(&project)?;
    }
    if settings.build_stage == "ship-if-route" && request.routes.is_none() && !matches!(request.action, Action::Land(_)) {
        return Err(usage(format!("Build stage: ship-if-route needs --routes yes|no; {USAGE}")));
    }
    remote_check(&top, &settings.mode)?;
    let title = title(&top, id)?;
    let local = settings.mode == "local";
    if local {
        root_clean(&project, &settings.target)?;
    }
    let base = base(&top, &settings)?;
    let subject = format!("{id}: {title}");

    if let Some(sha) = landing_by_subject(&top, &base, id, &subject) {
        let tree = read(&top, &["rev-parse", &format!("{sha}^{{tree}}")]).unwrap_or_default();
        return Ok(already_landed(id, &settings.mode, base, tree, sha, title));
    }

    let probed = probe(&top, &base, id)?;

    if let Probe::Clean(tree) = &probed {
        if read(&top, &["rev-parse", &format!("{base}^{{tree}}")]).as_deref() == Some(tree.as_str()) {
            if brings_nothing(&top, &base, id) {
                return Err(output::error(
                    output::REFUSED,
                    "nothing-to-land",
                    format!("story/{id} holds no change of its own and no commit of {} is titled `{subject}`", settings.target),
                ));
            }
            return Ok(already_landed(id, &settings.mode, base.clone(), tree.clone(), base, title));
        }
    }

    if let Action::Land(sha) = &request.action {
        let tree = match probed {
            Probe::Clean(tree) if still_the_landing(&top, sha, &base, &subject, &tree) => tree,
            _ => {
                return Err(output::error(
                    output::REFUSED,
                    "stale-landing",
                    format!("{sha} is no longer the landing of {id} on {}: build it again", settings.target),
                ))
            }
        };
        fast_forward(&project, &settings, sha)?;
        return Ok(output::reply(
            Landing {
                id: id.to_string(),
                mode: settings.mode.clone(),
                base,
                tree,
                sha: sha.clone(),
                title,
                committed: None,
                checks: Vec::new(),
                landed: true,
                already_landed: false,
            },
            output::OK,
        ));
    }

    if let Probe::Conflict(paths) = probed {
        return Err(conflict(paths, ""));
    }
    let checks = checks(&top, id, &settings, request.routes)?;
    let committed = commit_docs(&top, id)?;
    let tree = match probe(&top, &base, id)? {
        Probe::Clean(tree) => tree,
        Probe::Conflict(paths) => return Err(conflict(paths, ", once the review was committed")),
    };
    let ran = git::run(&top, &["commit-tree", &tree, "-p", &base, "-m", &subject]);
    let sha = ran.stdout.trim().to_string();
    if !ran.ok() || !is_sha(&sha) {
        return Err(git_failed("git commit-tree", &ran));
    }
    let landed = local && matches!(request.action, Action::BuildAndLand);
    if landed {
        fast_forward(&project, &settings, &sha)?;
    }
    Ok(output::reply(
        Landing {
            id: id.to_string(),
            mode: settings.mode,
            base,
            tree,
            sha,
            title,
            committed,
            checks,
            landed,
            already_landed: false,
        },
        output::OK,
    ))
}

pub fn main(args: &[String]) -> i32 {
    match run(args) {
        Ok(code) | Err(code) => code,
    }
}
