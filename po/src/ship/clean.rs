//! `po ship clean <id>`: removes a landed lane, from the repository root, once `po` proves the landing
//! itself. The proof is the one `file` reads: a commit of `Target branch` (as `origin` holds it under
//! `pr`) titled exactly `<id>: <title>`, so the cleanup asks no forge. Every check comes before the
//! first deletion; the deletions are the worktree (never forced), `refs/heads/story/<id>` and, under
//! `pr`, the same branch on `origin`, each skipped when it is already gone, so a rerun finishes what
//! an interruption left. A ref goes only once `po` has checked that what it holds has landed: the
//! local branch when the landing already holds all its changes, the remote branch while it still is the
//! story's landing, with a lease on the head observed.

use std::path::{Component, Path, PathBuf};

use serde::Serialize;

use super::push;
use super::{git, land};
use crate::output;
use crate::project::Project;

const USAGE: &str = "usage: po ship clean <id>";

#[derive(Serialize)]
struct Cleaned {
    state: &'static str,
    id: String,
    landed: String,
    worktree: &'static str,
    branch: &'static str,
    remote: Option<&'static str>,
    remote_head: Option<String>,
    message: Option<String>,
}

#[derive(Serialize)]
struct Refusal {
    error: &'static str,
    message: String,
    paths: Vec<String>,
}

fn usage(message: impl Into<String>) -> i32 {
    output::error(output::UNREADABLE, "usage", message)
}

fn parse(args: &[String]) -> Result<String, i32> {
    let mut id = None;
    for arg in args {
        if arg.starts_with('-') {
            return Err(output::error(
                output::UNREADABLE,
                "unknown-option",
                format!("po ship clean takes no option {arg}; {USAGE}"),
            ));
        }
        if id.is_some() {
            return Err(usage(format!("unexpected argument {arg}; {USAGE}")));
        }
        if !land::is_id(arg) {
            return Err(usage(format!("{arg} is not a story id (s<number>-<slug>); {USAGE}")));
        }
        id = Some(arg.clone());
    }
    id.ok_or_else(|| usage(USAGE))
}

struct Listed {
    path: PathBuf,
    branch: Option<String>,
}

/// The paths of `git worktree list --porcelain` with the branch each holds.
fn listing(root: &Path) -> Result<Vec<Listed>, i32> {
    let ran = git::run(root, &["worktree", "list", "--porcelain"]);
    if !ran.ok() {
        return Err(land::git_failed("git worktree list", &ran));
    }
    let mut found: Vec<Listed> = Vec::new();
    for line in ran.stdout.lines() {
        if let Some(path) = line.strip_prefix("worktree ") {
            found.push(Listed { path: PathBuf::from(path), branch: None });
        } else if let (Some(branch), Some(last)) = (line.strip_prefix("branch "), found.last_mut()) {
            last.branch = Some(branch.to_string());
        }
    }
    Ok(found)
}

/// `a/./b/../c` as `a/c`, with no access to the disk: the folder of a lane may be gone.
fn normal(path: &Path) -> PathBuf {
    let mut out = PathBuf::new();
    for part in path.components() {
        match part {
            Component::CurDir => {}
            Component::ParentDir => {
                out.pop();
            }
            other => out.push(other.as_os_str()),
        }
    }
    out
}

fn patch_id(root: &Path, sha: &str) -> Option<String> {
    let diff = git::run(root, &["diff-tree", "-p", sha]);
    if !diff.ok() || diff.bytes.is_empty() {
        return None;
    }
    let id = git::run_input(root, &["patch-id", "--verbatim"], &diff.bytes);
    id.ok().then(|| id.stdout.split_whitespace().next().map(str::to_string)).flatten()
}

/// The story branch's `head` has nothing left to lose once `landed` is on the base: merging it into
/// the landing changes nothing, so every change of the branch is in the landing.
fn is_in(root: &Path, head: &str, landed: &str) -> bool {
    let merged = git::run(root, &["merge-tree", "--write-tree", "--no-messages", landed, head]);
    merged.ok() && land::read(root, &["rev-parse", &format!("{landed}^{{tree}}")]).as_deref() == merged.stdout.lines().next()
}

/// `head`, as `origin` holds it, is the landing of the story: the commit found on the target branch,
/// or one titled the same, on a parent that `base` holds, whose tree is the landing's tree. A merge
/// that rebased the commit onto a base that had moved has another tree but the same change, which
/// the patch id tells, byte for byte.
fn is_landing(root: &Path, head: &str, landed: &str, base: &str, subject: &str, branch_ref: &str) -> Result<bool, i32> {
    if head == landed {
        return Ok(true);
    }
    let have = |sha: &str| git::run(root, &["cat-file", "-e", &format!("{sha}^{{commit}}")]).ok();
    if !have(head) {
        let ran = git::run(root, &["fetch", "-q", "origin", branch_ref]);
        if !ran.ok() && !have(head) {
            return Err(land::git_failed("git fetch origin of the remote branch's head", &ran));
        }
    }
    if land::read(root, &["log", "-1", "--format=%s", head]).as_deref() != Some(subject) {
        return Ok(false);
    }
    let parents = land::read(root, &["rev-list", "--parents", "-n", "1", head]).unwrap_or_default();
    let mut ids = parents.split(' ');
    let (Some(_), Some(parent), None) = (ids.next(), ids.next(), ids.next()) else { return Ok(false) };
    if !git::run(root, &["merge-base", "--is-ancestor", parent, base]).ok() {
        return Ok(false);
    }
    let tree = |sha: &str| land::read(root, &["rev-parse", &format!("{sha}^{{tree}}")]);
    if tree(head).is_some() && tree(head) == tree(landed) {
        return Ok(true);
    }
    Ok(match (patch_id(root, head), patch_id(root, landed)) {
        (Some(a), Some(b)) => a == b,
        _ => false,
    })
}

fn run(args: &[String]) -> Result<i32, i32> {
    let id = parse(args)?;
    let Some(project) = std::env::current_dir().ok().as_deref().and_then(Project::find) else {
        return Err(output::error(
            output::UNREADABLE,
            "not-a-project",
            "not inside a Polype project: no AGENTS.local.md nor .polype/version at the repository root",
        ));
    };
    let root = project.root.clone();
    let root = root.as_path();
    let target = land::setting(&project, "Target branch", &[])?;
    if target == "—" {
        return Err(output::error(output::UNREADABLE, "missing-setting", "Target branch is — in AGENTS.local.md"));
    }
    let mode = land::setting(&project, "Merge mode", &["pr", "local"])?;
    let worktree_root = land::setting(&project, "Worktree root", &[])?;
    land::remote_check(root, &mode)?;
    let base = land::base(root, &mode, &target)?;
    let stories = land::read(root, &["show", &format!("{base}:docs/stories.md")]).unwrap_or_default();
    let title = land::title_in(&stories, &id)?;
    let subject = format!("{id}: {title}");

    let Some(landed) = land::landing_by_subject(root, &base, &id, &subject) else {
        return Err(output::error(
            output::REFUSED,
            "not-landed",
            format!("no commit of {target} is titled `{subject}`: {id} has not landed, and nothing is removed"),
        ));
    };

    let branch_ref = format!("refs/heads/story/{id}");
    let lane = normal(&root.join(&worktree_root).join(&id));
    let listed = listing(root)?;
    let at_lane = listed.iter().find(|entry| normal(&entry.path) == lane);
    if let Some(entry) = at_lane {
        if entry.branch.as_deref() != Some(branch_ref.as_str()) {
            return Err(output::error(
                output::REFUSED,
                "not-the-lane",
                format!(
                    "{} holds {}, not {branch_ref}: nothing is removed",
                    entry.path.display(),
                    entry.branch.as_deref().unwrap_or("no branch")
                ),
            ));
        }
    } else if let Some(other) = listed.iter().find(|entry| entry.branch.as_deref() == Some(branch_ref.as_str())) {
        return Err(output::error(
            output::REFUSED,
            "branch-in-use",
            format!("{branch_ref} is checked out at {}, not at the lane {}: nothing is removed", other.path.display(), lane.display()),
        ));
    }
    if let Some(entry) = at_lane.filter(|entry| entry.path.is_dir()) {
        let status = git::run(&entry.path, &["status", "--porcelain"]);
        if !status.ok() {
            return Err(land::git_failed("git status of the worktree", &status));
        }
        let paths: Vec<String> = status.stdout.lines().map(|line| line.trim().to_string()).collect();
        if !paths.is_empty() {
            return Err(output::reply(
                Refusal {
                    error: "dirty-worktree",
                    message: format!(
                        "{} holds uncommitted work: {}; nothing is removed",
                        entry.path.display(),
                        paths.join("; ")
                    ),
                    paths,
                },
                output::REFUSED,
            ));
        }
    }
    let local = land::read(root, &["rev-parse", "-q", "--verify", &branch_ref]);
    if let Some(head) = local.as_deref().filter(|head| !is_in(root, head, &landed)) {
        return Err(output::error(
            output::REFUSED,
            "branch-not-landed",
            format!("{branch_ref} holds {head}, whose changes are not all in {landed}: nothing is removed; a person looks at the branch and deletes it by hand"),
        ));
    }

    let mut remote_head = None;
    let mut remote_is_landing = false;
    if mode == "pr" {
        remote_head = push::ls_remote(root, &branch_ref).map_err(|ran| land::git_failed("git ls-remote origin", &ran))?;
        if let Some(head) = &remote_head {
            remote_is_landing = is_landing(root, head, &landed, &base, &subject, &branch_ref)?;
        }
    }

    // Past this point nothing is checked again: each step is skipped when its target is gone.
    let mut worktree = "absent";
    if let Some(entry) = at_lane {
        let path = entry.path.to_string_lossy().into_owned();
        let ran = git::run(root, &["worktree", "remove", &path]);
        if !ran.ok() {
            return Err(output::error(
                output::REFUSED,
                "worktree-refused",
                format!("git worktree remove exited {}: {}; nothing else is removed", ran.code, ran.stderr.trim()),
            ));
        }
        worktree = "removed";
    }
    let mut branch = "absent";
    if let Some(head) = &local {
        let ran = git::run(root, &["update-ref", "-d", &branch_ref, head]);
        if !ran.ok() {
            return Err(output::error(
                output::REFUSED,
                "branch-refused",
                format!("git update-ref -d exited {}: {}", ran.code, ran.stderr.trim()),
            ));
        }
        branch = "deleted";
    }
    let mut remote = (mode == "pr").then_some("absent");
    let mut state = "cleaned";
    let mut message = None;
    if let Some(head) = &remote_head {
        if remote_is_landing {
            let lease = format!("--force-with-lease={branch_ref}:{head}");
            let ran = git::run(root, &["push", "-q", &lease, "origin", "--delete", &branch_ref]);
            if !ran.ok() {
                return Err(output::error(
                    output::REFUSED,
                    "delete-refused",
                    format!(
                        "git push --delete exited {}: {}; the worktree and the local branch are already removed",
                        ran.code,
                        ran.stderr.trim()
                    ),
                ));
            }
            remote = Some("deleted");
        } else {
            state = "remote-kept";
            remote = Some("kept");
            message = Some(format!(
                "origin's {branch_ref} holds {head}, which is not the landing of {id}: it is kept; a person looks at it and deletes it by hand",
            ));
        }
    }
    let code = if state == "cleaned" { output::OK } else { output::REFUSED };
    Ok(output::reply(
        Cleaned {
            state,
            id,
            landed,
            worktree,
            branch,
            remote,
            remote_head: if state == "remote-kept" { remote_head } else { None },
            message,
        },
        code,
    ))
}

pub fn main(args: &[String]) -> i32 {
    match run(args) {
        Ok(code) | Err(code) => code,
    }
}

