//! A po-gate subcommand run from the worktree, its exit code and output kept.

use std::path::Path;
use std::process::{Command, Stdio};

pub enum Gate {
    Ran { code: i32, stdout: String, stderr: String },
    Missing,
    Unstartable(String),
}

pub fn run(top: &Path, name: &str, id: &str) -> Gate {
    let script = top.join(".polype/hooks/po-gate.sh");
    if !script.is_file() {
        return Gate::Missing;
    }
    let output = Command::new("bash")
        .arg(&script)
        .args([name, id])
        .current_dir(top)
        .env("GIT_OPTIONAL_LOCKS", "0")
        .stdin(Stdio::null())
        .output();
    match output {
        // A gate killed by a signal has no code; -1 is never one of the gate's own codes.
        Ok(output) => Gate::Ran {
            code: output.status.code().unwrap_or(-1),
            stdout: String::from_utf8_lossy(&output.stdout).into_owned(),
            stderr: String::from_utf8_lossy(&output.stderr).into_owned(),
        },
        Err(err) => Gate::Unstartable(format!("bash cannot start: {err}")),
    }
}
