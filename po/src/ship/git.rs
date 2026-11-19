//! The only git launcher of `po` that writes — fetch, commit, commit-tree, fast-forward — reserved
//! to `po/src/ship/` (ADR-0130). Every other module asks git through the read-only
//! `project::git`, which stays as it is.

use std::path::Path;
use std::process::{Command, Stdio};

pub(super) struct Ran {
    pub code: i32,
    pub stdout: String,
    pub stderr: String,
}

impl Ran {
    pub fn ok(&self) -> bool {
        self.code == 0
    }
}

/// Runs git in `dir` and keeps its exit code, stdout and stderr. `LC_ALL=C` keeps git's messages
/// out of the user's language, so a refusal quotes the same words everywhere.
pub(super) fn run(dir: &Path, args: &[&str]) -> Ran {
    let output = Command::new("git")
        .args(args)
        .current_dir(dir)
        .env("LC_ALL", "C")
        .stdin(Stdio::null())
        .output();
    match output {
        // A git killed by a signal has no code; -1 is never one of git's own.
        Ok(output) => Ran {
            code: output.status.code().unwrap_or(-1),
            stdout: String::from_utf8_lossy(&output.stdout).into_owned(),
            stderr: String::from_utf8_lossy(&output.stderr).into_owned(),
        },
        Err(err) => Ran { code: -1, stdout: String::new(), stderr: format!("git cannot start: {err}") },
    }
}
