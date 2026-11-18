//! The forge's checks on a landed commit and a branch's pull request, asked through `gh api` pinned
//! to github.com (ADR-0083), for `po state --remote` and `po next --remote`; and the launcher
//! `po ship forge` reads the forge with. `po` makes no HTTP call of its own: it launches the tools.

use std::ffi::OsString;
use std::io::{Read, Write};
use std::process::{Command, Stdio};

use serde_json::Value;

use crate::project::Project;

pub struct Forge {
    /// `<owner>/<repo>` on github.com.
    repo: String,
}

/// The program `var` names when it is set and non-empty, `default` otherwise, so tests can stand in
/// for a forge tool (`PO_GH`, `PO_CURL`, `PO_GLAB`, `PO_TEA`).
pub fn program(var: &str, default: &str) -> OsString {
    match std::env::var_os(var) {
        Some(program) if !program.is_empty() => program,
        _ => OsString::from(default),
    }
}

fn gh_program() -> OsString {
    program("PO_GH", "gh")
}

/// What a forge API answered, read from a tool run with `-i`: its HTTP status, headers and body, or
/// nothing that carries a status.
pub enum ApiAnswer {
    Status(u16, Response),
    Unreachable,
}

pub struct Response {
    headers: Vec<String>,
    body: String,
}

impl ApiAnswer {
    pub fn json(&self) -> Option<Value> {
        match self {
            ApiAnswer::Status(_, response) => serde_json::from_str(&response.body).ok(),
            ApiAnswer::Unreachable => None,
        }
    }

    /// The value of the header `name`, matched without regard to case.
    pub fn header(&self, name: &str) -> Option<&str> {
        let ApiAnswer::Status(_, response) = self else { return None };
        response.headers.iter().find_map(|line| {
            let (key, value) = line.split_once(':')?;
            key.trim().eq_ignore_ascii_case(name).then(|| value.trim())
        })
    }
}

/// The status of the first line `HTTP/<v> <code> …` and the body after the first blank line. A tool
/// that prints no status line, or several header blocks behind a redirect, gives no usable answer.
fn parse_included(out: &[u8]) -> ApiAnswer {
    let text = String::from_utf8_lossy(out);
    let Some((first, mut rest)) = text.split_once('\n') else { return ApiAnswer::Unreachable };
    let mut words = first.trim_end_matches('\r').split_whitespace();
    if !words.next().is_some_and(|proto| proto.starts_with("HTTP/")) {
        return ApiAnswer::Unreachable;
    }
    let Some(code) = words.next().and_then(|code| code.parse::<u16>().ok()) else {
        return ApiAnswer::Unreachable;
    };
    let mut headers = Vec::new();
    loop {
        let (line, after) = rest.split_once('\n').unwrap_or((rest, ""));
        let line = line.trim_end_matches('\r');
        if line.is_empty() {
            return ApiAnswer::Status(code, Response { headers, body: after.to_string() });
        }
        headers.push(line.to_string());
        rest = after;
    }
}

/// Runs a forge tool asked for its headers; `stdin`, when given, is written to it from another
/// thread, so a token reaches the tool without entering an argument. stderr is never read.
pub fn api_included(mut command: Command, stdin: Option<String>) -> ApiAnswer {
    command
        .stdin(if stdin.is_some() { Stdio::piped() } else { Stdio::null() })
        .stdout(Stdio::piped())
        .stderr(Stdio::null());
    let Ok(mut child) = command.spawn() else { return ApiAnswer::Unreachable };
    let writer = match (stdin, child.stdin.take()) {
        (Some(input), Some(mut pipe)) => Some(std::thread::spawn(move || pipe.write_all(input.as_bytes()))),
        _ => None,
    };
    let mut out = Vec::new();
    let read = child.stdout.take().map(|mut stdout| stdout.read_to_end(&mut out));
    if let Some(writer) = writer {
        let _ = writer.join();
    }
    let _ = child.wait();
    if !matches!(read, Some(Ok(_))) {
        return ApiAnswer::Unreachable;
    }
    parse_included(&out)
}

/// stdout of a tool that exited 0, its stdin and stderr closed.
pub fn quiet_output(mut command: Command) -> Option<Vec<u8>> {
    let output = command.stdin(Stdio::null()).stderr(Stdio::null()).output().ok()?;
    output.status.success().then_some(output.stdout)
}

/// `<owner>/<repo>` of a github.com remote URL, in its https, scp-like or ssh form.
fn github_repo(url: &str) -> Option<String> {
    let path = ["https://github.com/", "git@github.com:", "ssh://git@github.com/"]
        .iter()
        .find_map(|prefix| url.strip_prefix(prefix))?;
    let path = path.trim_end_matches('/');
    let path = path.strip_suffix(".git").unwrap_or(path);
    let (owner, repo) = path.split_once('/')?;
    let valid = |part: &str| !part.is_empty() && !part.contains('/');
    (valid(owner) && valid(repo)).then(|| format!("{owner}/{repo}"))
}

fn gh_api(path: &str) -> Option<Value> {
    let output = Command::new(gh_program())
        .args(["api", "--hostname", "github.com", path])
        .stdin(Stdio::null())
        .stderr(Stdio::null())
        .output()
        .ok()?;
    if !output.status.success() {
        return None;
    }
    serde_json::from_slice(&output.stdout).ok()
}

impl Forge {
    /// The project's forge, when its `origin` is on github.com.
    pub fn of(project: &Project) -> Option<Forge> {
        let url = project.git(&["config", "--get", "remote.origin.url"])?;
        Some(Forge { repo: github_repo(url.trim())? })
    }

    /// `passed`, `failed` or `none` for the check runs on `commit`; `None` when they cannot be read
    /// or one has not finished.
    pub fn checks(&self, commit: &str) -> Option<String> {
        let answer = gh_api(&format!("repos/{}/commits/{commit}/check-runs?per_page=100", self.repo))?;
        let total = answer.get("total_count")?.as_u64()?;
        let runs = answer.get("check_runs")?.as_array()?;
        if total > runs.len() as u64 {
            return None;
        }
        if total == 0 {
            return Some("none".to_string());
        }
        if runs.iter().any(|run| run.get("status").and_then(Value::as_str) != Some("completed")) {
            return None;
        }
        let failing = ["failure", "cancelled", "timed_out", "action_required", "startup_failure", "stale"];
        let failed = runs
            .iter()
            .any(|run| run.get("conclusion").and_then(Value::as_str).is_some_and(|c| failing.contains(&c)));
        Some(if failed { "failed" } else { "passed" }.to_string())
    }

    /// Whether the newest pull request of `branch` (highest `number`) was closed without a merge;
    /// `Some(false)` when the branch has none, `None` when the answer cannot be read.
    pub fn pull_request_closed(&self, branch: &str) -> Option<bool> {
        let owner = self.repo.split('/').next()?;
        let answer =
            gh_api(&format!("repos/{}/pulls?head={owner}:{branch}&state=all&per_page=100", self.repo))?;
        let newest = answer
            .as_array()?
            .iter()
            .max_by_key(|pull| pull.get("number").and_then(Value::as_u64).unwrap_or(0));
        Some(newest.is_some_and(|pull| {
            pull.get("state").and_then(Value::as_str) == Some("closed")
                && pull.get("merged_at").is_none_or(Value::is_null)
        }))
    }
}
