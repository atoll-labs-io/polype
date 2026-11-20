//! The only git launcher of `po` that writes — fetch, commit, commit-tree, fast-forward, push —
//! reserved to `po/src/ship/` (ADR-0130). Every other module asks git through the read-only
//! `project::git`, which stays as it is.

use std::io::Write;
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
/// out of the user's language, so a refusal quotes the same words everywhere;
/// `GIT_TERMINAL_PROMPT=0` makes a push that lacks credentials fail instead of waiting on a prompt.
pub(super) fn run(dir: &Path, args: &[&str]) -> Ran {
    run_with(dir, args, None)
}

/// As `run`, with `input` written to git's stdin (`hash-object --stdin`, `mktree`).
pub(super) fn run_input(dir: &Path, args: &[&str], input: &[u8]) -> Ran {
    run_with(dir, args, Some(input))
}

fn run_with(dir: &Path, args: &[&str], input: Option<&[u8]>) -> Ran {
    let mut command = Command::new("git");
    command
        .args(args)
        .current_dir(dir)
        .env("LC_ALL", "C")
        .env("GIT_TERMINAL_PROMPT", "0")
        .stdin(if input.is_some() { Stdio::piped() } else { Stdio::null() })
        .stdout(Stdio::piped())
        .stderr(Stdio::piped());
    let output = command.spawn().and_then(|mut child| {
        if let (Some(input), Some(mut pipe)) = (input, child.stdin.take()) {
            // The inputs are small (one file, one tree listing): writing before reading cannot fill
            // git's output pipe.
            pipe.write_all(input)?;
        }
        child.wait_with_output()
    });
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
