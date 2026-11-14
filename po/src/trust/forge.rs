//! The forge's checks on a landed commit, asked through `gh api` pinned to github.com (ADR-0083):
//! `po` reads no token and makes no HTTP call of its own. Only `po state --remote` gets here.

use std::ffi::OsString;
use std::process::{Command, Stdio};

use serde_json::Value;

use crate::project::Project;

pub struct Forge {
    /// `<owner>/<repo>` on github.com.
    repo: String,
}

/// `PO_GH` when set and non-empty, so tests can stand in for the forge.
fn gh_program() -> OsString {
    match std::env::var_os("PO_GH") {
        Some(program) if !program.is_empty() => program,
        _ => OsString::from("gh"),
    }
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

impl Forge {
    /// The project's forge, when its `origin` is on github.com.
    pub fn of(project: &Project) -> Option<Forge> {
        let url = project.git(&["config", "--get", "remote.origin.url"])?;
        Some(Forge { repo: github_repo(url.trim())? })
    }

    /// `passed`, `failed` or `none` for the check runs on `commit`; `None` when they cannot be read
    /// or one has not finished.
    pub fn checks(&self, commit: &str) -> Option<String> {
        let output = Command::new(gh_program())
            .args([
                "api",
                "--hostname",
                "github.com",
                &format!("repos/{}/commits/{commit}/check-runs?per_page=100", self.repo),
            ])
            .stdin(Stdio::null())
            .stderr(Stdio::null())
            .output()
            .ok()?;
        if !output.status.success() {
            return None;
        }
        let answer: Value = serde_json::from_slice(&output.stdout).ok()?;
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
}
