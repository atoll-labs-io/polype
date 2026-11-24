//! The literal commands that open the lane of a ready story, for the lead to run one by one. `po`
//! runs none of them: the fetch, the worktree, the copies and `Install` are only text here.

use crate::context::{lane_prefix, Context};
use crate::project::Setting;

pub enum Opening {
    /// `None` when a setting the commands need cannot be read.
    Commands(Option<Vec<String>>),
    /// An `.env*` file at the root that git does not ignore: copying it would let it be committed.
    EnvNotIgnored,
}

pub fn open(context: &Context, id: &str) -> Opening {
    let project = &context.project;
    let Setting::Value(install) = project.setting("Install") else {
        return Opening::Commands(None);
    };
    let Some(unignored) = project.git(&["ls-files", "--others", "--exclude-standard", "-z", "--", ".env*"]) else {
        return Opening::Commands(None);
    };
    if !unignored.is_empty() {
        return Opening::EnvNotIgnored;
    }
    let worktree_root = match project.setting("Worktree root") {
        Setting::Value(value) if value != "—" => value,
        _ => return Opening::Commands(None),
    };
    let (Some(start), Some(ignored)) = (
        context.start.as_ref(),
        project.git(&["ls-files", "--others", "--ignored", "--exclude-standard", "-z", "--", ".env*"]),
    ) else {
        return Opening::Commands(None);
    };

    let root = quote(&project.root.display().to_string());
    let lane_path = format!("{}{id}", lane_prefix(project, &worktree_root));
    let lane = quote(&lane_path);
    let mut commands = Vec::new();
    if project.git(&["remote", "get-url", "origin"]).is_some() {
        commands.push(format!("git -C {root} fetch origin"));
    }
    let branch = format!("story/{id}");
    if project.git(&["rev-parse", "--verify", "-q", &format!("refs/heads/{branch}")]).is_some() {
        // A branch an earlier attempt left without its worktree: check it out rather than recreate it.
        commands.push(format!("git -C {root} worktree add {lane} {}", quote(&branch)));
    } else {
        commands.push(format!("git -C {root} worktree add -b {} {lane} {}", quote(&branch), quote(&start.reference)));
    }
    for file in ignored.split('\0').filter(|file| !file.is_empty()) {
        if let Some((dir, _)) = file.rsplit_once('/') {
            commands.push(format!("mkdir -p {}", quote(&format!("{lane_path}/{dir}"))));
        }
        let from = quote(&format!("{}/{file}", project.root.display()));
        commands.push(format!("cp {from} {}", quote(&format!("{lane_path}/{file}"))));
    }
    if install != "—" {
        // A subshell, so the lead's own shell never leaves where it started.
        commands.push(format!("(cd {lane} && {install})"));
    }
    Opening::Commands(Some(commands))
}

/// Bare when every byte is safe for a shell, else single-quoted with `'` written `'\''`.
fn quote(text: &str) -> String {
    let safe = |byte: u8| byte.is_ascii_alphanumeric() || b"_@%+=:,./-".contains(&byte);
    if !text.is_empty() && text.bytes().all(safe) {
        return text.to_string();
    }
    format!("'{}'", text.replace('\'', r"'\''"))
}
