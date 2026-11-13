//! Whether the subagents that hold the bounds load from the user's Claude Code configuration, carry
//! Polype's `po-bounds` hook, and find the script that hook calls. A copy in the repository's
//! `.claude/agents/` wins over the global one, and its hooks wait for the trust dialog a background
//! session never shows.

use std::fs;
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};

use super::Bounds;
use crate::project::Project;

const BOUNDED: [&str; 3] = ["implementer", "qa", "reviewer"];
const HOOK: &str = ".polype/hooks/po-bounds.sh";

fn config_dir() -> Option<PathBuf> {
    match std::env::var_os("CLAUDE_CONFIG_DIR") {
        Some(dir) if !dir.is_empty() => Some(PathBuf::from(dir)),
        _ => match std::env::var_os("HOME") {
            Some(home) if !home.is_empty() => Some(PathBuf::from(home).join(".claude")),
            _ => None,
        },
    }
}

/// The frontmatter of `<name>.md` names the subagent and wires the hook exactly as Polype ships it:
/// any other shape, however close, is not proof.
fn carries_hook(path: &Path, name: &str) -> bool {
    let Ok(text) = fs::read_to_string(path) else { return false };
    let mut lines = text.lines();
    if lines.next() != Some("---") {
        return false;
    }
    let front: Vec<&str> = lines.take_while(|line| *line != "---").collect();
    let command = format!(r#"command: '"$CLAUDE_PROJECT_DIR"/{HOOK} {name} || exit 2'"#);
    let wired = [
        "PreToolUse:",
        r#"- matcher: "Edit|Write|Bash""#,
        "hooks:",
        "- type: command",
        command.as_str(),
    ];
    front.contains(&format!("name: {name}").as_str())
        && front.iter().enumerate().any(|(at, line)| {
            *line == "hooks:"
                && front.len() > at + wired.len()
                && front[at + 1..=at + wired.len()].iter().map(|l| l.trim()).eq(wired)
        })
}

fn executable(path: &Path) -> bool {
    fs::metadata(path).is_ok_and(|meta| meta.is_file() && meta.permissions().mode() & 0o111 != 0)
}

pub fn bounds(project: &Project) -> Bounds {
    let Some(config) = config_dir() else { return Bounds::Unproven };
    let global = config.join("agents");
    let local = project.root.join(".claude/agents");
    let held = BOUNDED.iter().all(|name| carries_hook(&global.join(format!("{name}.md")), name))
        && BOUNDED.iter().all(|name| !local.join(format!("{name}.md")).exists())
        && executable(&project.root.join(HOOK));
    if held { Bounds::Held } else { Bounds::Unproven }
}
