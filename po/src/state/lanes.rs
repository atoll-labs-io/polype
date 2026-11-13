//! The lanes in flight: worktrees, shipped stories and per-lane stops as po-session.sh reads them,
//! and each lane's stage through the lane's own po-gate.

use std::collections::HashSet;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use serde::Serialize;

use super::framing::Stories;
use super::{Settings, Warning, Warnings};
use crate::next::{self, NextAction};
use crate::project::Project;

#[derive(Serialize, Clone, Copy, Debug, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum Stage {
    Research,
    Design,
    Plan,
    Execute,
    Qa,
    Review,
    Ship,
}

#[derive(Serialize, Clone, Copy, Debug, PartialEq)]
#[serde(rename_all = "kebab-case")]
pub enum BlockedBy {
    RootCauseNotFound,
    TechnicalChoice,
    QaBlocked,
    MaxAttempts,
    MergeWaiting,
}

#[derive(Serialize, Clone, Debug, PartialEq)]
pub struct Lane {
    pub story: String,
    pub stage: Option<Stage>,
    pub next: Option<NextAction>,
    pub blocked_by: Option<BlockedBy>,
}

/// The stories landed on the target branch (and its origin copy), by commit subject: `<id>:`, or
/// the bare number `s<n>:` when no subject carries the id.
pub struct Shipped {
    full: HashSet<String>,
    short: HashSet<String>,
}

impl Shipped {
    pub fn read(project: &Project, target: &str) -> Shipped {
        let mut shipped = Shipped { full: HashSet::new(), short: HashSet::new() };
        let mut refs = vec![target.to_string()];
        let origin = format!("refs/remotes/origin/{target}");
        if project.git(&["rev-parse", "--verify", "-q", &origin]).is_some() {
            refs.push(format!("origin/{target}"));
        }
        let mut args = vec!["log", "--format=%s"];
        args.extend(refs.iter().map(String::as_str));
        args.push("--");
        let Some(subjects) = project.git(&args) else { return shipped };
        for subject in subjects.lines() {
            let Some((head, _)) = subject.split_once(':') else { continue };
            let Some(number) = head.strip_prefix('s') else { continue };
            let digits = number.chars().take_while(|c| c.is_ascii_digit()).count();
            if digits == 0 {
                continue;
            }
            let rest = &number[digits..];
            if rest.is_empty() {
                shipped.short.insert(head.to_string());
            } else if rest.len() > 1
                && rest.starts_with('-')
                && rest.chars().all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '-')
            {
                shipped.full.insert(head.to_string());
            }
        }
        shipped
    }

    pub fn contains(&self, id: &str) -> bool {
        let number = id.split('-').next().unwrap_or(id);
        self.full.contains(id) || self.short.contains(number)
    }
}

struct Worktree {
    path: PathBuf,
    branch: Option<String>,
}

fn worktrees(project: &Project) -> Vec<Worktree> {
    let Some(listing) = project.git(&["worktree", "list", "--porcelain"]) else { return Vec::new() };
    let mut found: Vec<Worktree> = Vec::new();
    for line in listing.lines() {
        if let Some(path) = line.strip_prefix("worktree ") {
            let path = PathBuf::from(path);
            let path = path.canonicalize().unwrap_or(path);
            found.push(Worktree { path, branch: None });
        } else if let Some(branch) = line.strip_prefix("branch refs/heads/") {
            if let Some(last) = found.last_mut() {
                last.branch = Some(branch.to_string());
            }
        }
    }
    found
}

fn shown(project: &Project, path: &Path) -> String {
    match path.strip_prefix(&project.root) {
        Ok(rel) => rel.display().to_string(),
        Err(_) => path.display().to_string(),
    }
}

/// A gate run as the lane's own po-gate, from inside the lane, so it judges the lane's code.
fn gate(lane: &Path, script: &Path, name: &str, id: &str) -> bool {
    Command::new("bash")
        .arg(script)
        .args([name, id])
        .current_dir(lane)
        .env("GIT_OPTIONAL_LOCKS", "0")
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .is_ok_and(|status| status.success())
}

/// The last `Name:` line of a file, first word of its value, as po-session's `last_value`.
fn last_value(text: &str, name: &str) -> Option<String> {
    let prefix = format!("{name}:");
    let line = text.lines().filter(|line| line.starts_with(&prefix)).last()?;
    line[prefix.len()..].split_whitespace().next().map(str::to_string)
}

struct LaneSettings {
    qa_stage: Option<String>,
    max_attempts: Option<String>,
    merge_mode: Option<String>,
    confirmation: Option<String>,
}

pub fn lanes(
    project: &Project,
    settings: &Settings,
    stories: &Stories,
    shipped: &Shipped,
    warnings: &mut Warnings,
) -> Option<Vec<Lane>> {
    let lane_settings = LaneSettings {
        qa_stage: settings.optional("QA stage"),
        max_attempts: settings.required("Max attempts", warnings),
        merge_mode: settings.required("Merge mode", warnings),
        confirmation: settings.required("Ship confirmation", warnings).map(|value| {
            let value = value.trim_end();
            let value = value
                .strip_suffix("(forge)")
                .or_else(|| value.strip_suffix("(chosen)"))
                .unwrap_or(value);
            value.trim_end().to_string()
        }),
    };
    let root = settings.usable("Worktree root", warnings)?;
    let prefix = if root.starts_with('/') { root } else { format!("{}/{}", project.root.display(), root) };

    let mut lanes = Vec::new();
    for worktree in worktrees(project) {
        if worktree.path == project.root {
            continue;
        }
        let path_text = worktree.path.display().to_string();
        let lane_id = path_text
            .strip_prefix(&prefix)
            .filter(|name| worktree.branch.as_deref() == Some(&format!("story/{name}")));
        match lane_id {
            Some(id) => {
                let id = id.to_string();
                let stage = stage(&worktree.path, &id, stories, shipped, &lane_settings, warnings);
                let blocked_by = blocked_by(project, &worktree.path, &id, shipped, &lane_settings);
                lanes.push(Lane { next: next::lane_next(&id, stage), story: id, stage, blocked_by });
            }
            None => {
                let under_root = path_text.starts_with(&prefix);
                let on_story = worktree.branch.as_deref().is_some_and(|b| b.starts_with("story/"));
                if under_root || on_story {
                    warnings.push(Warning::OrphanWorktree {
                        path: shown(project, &worktree.path),
                        branch: worktree.branch.clone(),
                    });
                }
            }
        }
    }
    Some(lanes)
}

fn stage(
    lane: &Path,
    id: &str,
    stories: &Stories,
    shipped: &Shipped,
    settings: &LaneSettings,
    warnings: &mut Warnings,
) -> Option<Stage> {
    if shipped.contains(id) {
        return Some(Stage::Ship);
    }
    let story = stories.find(id);
    let has_screen = story.is_some_and(|story| story.has_screen());
    if !lane.join(format!("docs/plans/{id}.md")).is_file() {
        if !lane.join(format!("docs/research/{id}.md")).is_file() {
            return Some(Stage::Research);
        }
        if has_screen && !lane.join(format!("docs/designs/{id}/design.md")).is_file() {
            return Some(Stage::Design);
        }
        return Some(Stage::Plan);
    }
    let script = lane.join(".polype/hooks/po-gate.sh");
    if !script.is_file() {
        warnings.push(Warning::NoGate { story: id.to_string() });
        return None;
    }
    if !gate(lane, &script, "plan-validated", id) {
        return Some(Stage::Plan);
    }
    if gate(lane, &script, "ship-allowed", id) {
        return Some(Stage::Ship);
    }
    if !gate(lane, &script, "verif-current", id) {
        return Some(Stage::Execute);
    }
    let has_surface = story.and_then(|story| story.surface.as_deref()).is_some_and(|surface| surface != "—");
    let goes_to_qa = match settings.qa_stage.as_deref() {
        None if has_screen || has_surface => {
            warnings.push(Warning::MissingSetting { setting: "QA stage".into() });
            return None;
        }
        None | Some("—") => false,
        Some("screens") => has_screen,
        Some("surfaces") => has_surface,
        Some(_) => {
            warnings.push(Warning::UnreadableSetting { setting: "QA stage".into() });
            return None;
        }
    };
    if goes_to_qa && !gate(lane, &script, "qa-current", id) {
        return Some(Stage::Qa);
    }
    Some(Stage::Review)
}

fn count(value: &str) -> Option<u64> {
    value.chars().all(|c| c.is_ascii_digit()).then(|| value.parse().ok()).flatten()
}

fn has_line(text: &Option<String>, line: &str) -> bool {
    text.as_deref().is_some_and(|text| text.lines().any(|l| l == line))
}

/// The first per-lane stop po-session reports for a person, as a code.
fn blocked_by(
    project: &Project,
    lane: &Path,
    id: &str,
    shipped: &Shipped,
    settings: &LaneSettings,
) -> Option<BlockedBy> {
    let read = |rel: String| std::fs::read_to_string(lane.join(rel)).ok();
    let research = read(format!("docs/research/{id}.md"));
    let plan = read(format!("docs/plans/{id}.md"));
    let qa = read(format!("docs/qa/{id}/report.md"));
    let review = read(format!("docs/reviews/{id}.md"));
    let validated = has_line(&plan, "validated: yes");

    if has_line(&research, "Root cause: not found") && !validated {
        return Some(BlockedBy::RootCauseNotFound);
    }
    if has_line(&plan, "Technical choice: waiting for a human") && !validated {
        return Some(BlockedBy::TechnicalChoice);
    }
    if qa.as_deref().and_then(|text| last_value(text, "QA status")).as_deref() == Some("blocked") {
        return Some(BlockedBy::QaBlocked);
    }
    let review = review.unwrap_or_default();
    let ship = last_value(&review, "Ship allowed");
    if ship.as_deref() == Some("no") {
        if let Some(max) = &settings.max_attempts {
            let status = last_value(&review, "Review status");
            let next_action = review.lines().filter(|line| line.starts_with("- Next action:")).last().unwrap_or("");
            let waits_for_qa = status.as_deref() == Some("blocked")
                && (next_action.contains("/po-qa") || next_action.contains("QA evidence"));
            let attempts = last_value(&review, "Fix loop").and_then(|value| count(&value));
            if !waits_for_qa {
                if let (Some(loops), Some(max)) = (attempts, count(max)) {
                    if loops >= max {
                        return Some(BlockedBy::MaxAttempts);
                    }
                }
            }
        }
    }
    if ship.as_deref() == Some("yes")
        && settings.merge_mode.as_deref() == Some("pr")
        && settings.confirmation.as_deref() == Some("human")
        && !shipped.contains(id)
        && project
            .git(&["rev-parse", "--verify", "-q", &format!("refs/remotes/origin/story/{id}")])
            .is_some()
    {
        return Some(BlockedBy::MergeWaiting);
    }
    None
}
