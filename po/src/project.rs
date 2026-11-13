//! The project `po` runs in: its root, its settings and a read-only way to ask git.

use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

pub const PO_VERSION: &str = env!("CARGO_PKG_VERSION");

pub struct Project {
    pub root: PathBuf,
    local_md: Option<String>,
}

pub enum Setting {
    Missing,
    Value(String),
}

/// Runs a read-only git command in `dir`; its stdout when it succeeds. `po` never fetches, pulls,
/// pushes nor writes, and GIT_OPTIONAL_LOCKS=0 keeps even `status`-like reads from taking a lock.
pub fn git(dir: &Path, args: &[&str]) -> Option<String> {
    let output = Command::new("git")
        .args(args)
        .current_dir(dir)
        .env("GIT_OPTIONAL_LOCKS", "0")
        .stdin(Stdio::null())
        .stderr(Stdio::null())
        .output()
        .ok()?;
    if !output.status.success() {
        return None;
    }
    String::from_utf8(output.stdout).ok()
}

impl Project {
    /// The main checkout of the repository holding `cwd`, so a story worktree resolves to the
    /// project it belongs to. `None` outside a Polype project.
    pub fn find(cwd: &Path) -> Option<Project> {
        let common = git(cwd, &["rev-parse", "--path-format=absolute", "--git-common-dir"])?;
        let common = PathBuf::from(common.trim());
        let root = common.parent()?.canonicalize().ok()?;
        let local_path = root.join("AGENTS.local.md");
        if !local_path.is_file() && !root.join(".polype/version").is_file() {
            return None;
        }
        let local_md = std::fs::read_to_string(&local_path).ok();
        Some(Project { root, local_md })
    }

    pub fn has_local_md(&self) -> bool {
        self.local_md.is_some()
    }

    /// The first `Name:` line holding a value, trimmed, as po-session reads it.
    pub fn setting(&self, name: &str) -> Setting {
        let Some(text) = &self.local_md else { return Setting::Missing };
        let prefix = format!("{name}:");
        for line in text.lines() {
            if let Some(rest) = line.strip_prefix(&prefix) {
                let value = rest.trim();
                if !value.is_empty() {
                    return Setting::Value(value.to_string());
                }
            }
        }
        Setting::Missing
    }

    pub fn git(&self, args: &[&str]) -> Option<String> {
        git(&self.root, args)
    }

    pub fn name(&self) -> String {
        self.root
            .file_name()
            .map(|name| name.to_string_lossy().into_owned())
            .unwrap_or_default()
    }

    pub fn commit(&self, target: &str) -> Option<String> {
        self.git(&["rev-parse", "--verify", "-q", "--short=7", target])
            .map(|out| out.trim().to_string())
            .filter(|out| !out.is_empty())
    }

    pub fn method_version(&self) -> Option<String> {
        let text = std::fs::read_to_string(self.root.join(".polype/version")).ok()?;
        text.lines().next().map(|line| line.trim().to_string())
    }

    /// A file as committed on `target`, or `None` when it is not there.
    pub fn on_target(&self, target: &str, path: &str) -> Option<String> {
        self.git(&["show", &format!("{target}:{path}")])
    }
}
