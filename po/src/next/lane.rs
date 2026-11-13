//! A lane's next action: the first rule that holds, in the order of po-drive.md's `## Resuming`.
//! Stage and stops come from the context; only `qa-current` (stage `qa`) and `git log` (a review
//! that blocked) are asked again, and only for this lane.

use std::path::Path;
use std::process::{Command, Stdio};
use std::time::SystemTime;

use super::{holding_decision, NextAction};
use crate::context::{BlockedBy, Context, Lane, Stage};
use crate::project::{self, Setting};

fn act(action: &str, reason: impl Into<String>) -> NextAction {
    NextAction { action: action.to_string(), reason: reason.into() }
}

fn landed(context: &Context, id: &str) -> bool {
    context.landed.as_ref().is_some_and(|landed| landed.contains(id))
}

pub fn next(context: &Context, lane: &Lane) -> NextAction {
    let id = lane.story.as_str();
    let path = lane.path.as_path();
    if landed(context, id) {
        return act("ship", "landed");
    }
    if let Some(decision) = holding_decision(context, id) {
        return act("wait", format!("decision {decision}"));
    }
    let Some(stage) = lane.stage else {
        if !path.join(".polype/hooks/po-gate.sh").is_file() {
            return act("ask", "no po-gate");
        }
        return act("ask", "setting unreadable: QA stage");
    };
    let research = path.join(format!("docs/research/{id}.md")).is_file();
    let plan = path.join(format!("docs/plans/{id}.md")).is_file();
    if !research && !plan {
        return act("plan", "no research");
    }
    match lane.blocked_by {
        Some(BlockedBy::RootCauseNotFound) => return act("ask", "Root cause: not found"),
        Some(BlockedBy::TechnicalChoice) => return act("ask", "Technical choice: waiting for a human"),
        _ => {}
    }
    if !plan {
        return act("plan", "research, no plan");
    }
    if stage == Stage::Plan {
        return match setting(context, "Plan validation").as_deref() {
            Some("human") => act("validate-plan", "plan-validated refuses"),
            Some("autonomous") => act("plan", "plan-validated refuses"),
            _ => act("ask", "setting unreadable: Plan validation"),
        };
    }
    let has_screen = context
        .stories
        .as_ref()
        .and_then(|stories| stories.find(id))
        .is_some_and(|story| story.has_screen());
    if has_screen && !path.join(format!("docs/designs/{id}/design.md")).is_file() {
        if !path.join("docs/design-system.md").is_file() {
            return act("ask", "no docs/design-system.md");
        }
        return match setting(context, "Design source").as_deref() {
            None | Some("—") => act("ask", "Design source unset"),
            Some(_) => act("design", "no design"),
        };
    }
    match stage {
        Stage::Execute => act("execute", "verif-current refuses"),
        Stage::Qa => {
            if lane.blocked_by == Some(BlockedBy::QaBlocked) {
                act("ask", "QA status: blocked")
            } else if qa_gate_stderr(path, id).contains("is current but") {
                act("qa", "QA evidence not committed")
            } else {
                act("qa", "qa-current refuses")
            }
        }
        Stage::Ship => ship(context, lane),
        _ => review(context, lane),
    }
}

fn setting(context: &Context, name: &str) -> Option<String> {
    match context.project.setting(name) {
        Setting::Value(value) => Some(value),
        Setting::Missing => None,
    }
}

/// The lane's own `po-gate qa-current`, whose refusal text tells an uncommitted report apart.
fn qa_gate_stderr(lane: &Path, id: &str) -> String {
    Command::new("bash")
        .arg(lane.join(".polype/hooks/po-gate.sh"))
        .args(["qa-current", id])
        .current_dir(lane)
        .env("GIT_OPTIONAL_LOCKS", "0")
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::piped())
        .output()
        .map(|output| String::from_utf8_lossy(&output.stderr).into_owned())
        .unwrap_or_default()
}

/// The first word of the last `Name:` line.
fn last_value(text: &str, name: &str) -> Option<String> {
    let prefix = format!("{name}:");
    let line = text.lines().filter(|line| line.starts_with(&prefix)).last()?;
    line[prefix.len()..].split_whitespace().next().map(str::to_string)
}

fn number(value: &str) -> Option<u64> {
    (!value.is_empty() && value.bytes().all(|b| b.is_ascii_digit())).then(|| value.parse().ok()).flatten()
}

/// Stage `review`: the verdict on disk decides between the reviewer, a fix run and a person.
fn review(context: &Context, lane: &Lane) -> NextAction {
    let id = lane.story.as_str();
    let Ok(text) = std::fs::read_to_string(lane.path.join(format!("docs/reviews/{id}.md"))) else {
        return act("review", "no review");
    };
    match last_value(&text, "Ship allowed").as_deref() {
        Some("yes") => return act("review", "ship-allowed refuses"),
        None => return act("ask", "review without verdict"),
        Some(_) => {}
    }
    let fix_loop = last_value(&text, "Fix loop").and_then(|value| number(&value)).unwrap_or(0);

    // Landings happen on the forge, so the local target branch can lag behind its origin copy:
    // what either one holds is not the implementer's, as `Landed::read` already reads both.
    let log = context.target.as_deref().and_then(|target| {
        let origin = format!("refs/remotes/origin/{target}");
        let mut args = vec!["log", "--format=%s", "HEAD", "--not", target];
        if project::git(&lane.path, &["rev-parse", "--verify", "-q", &origin]).is_some() {
            args.push(&origin);
        }
        args.push("--");
        project::git(&lane.path, &args)
    });
    let subjects: Vec<&str> = log.as_deref().map(|log| log.lines().collect()).unwrap_or_default();
    let evidence = format!("{id}: QA evidence");
    let implementer = subjects.iter().filter(|subject| **subject != evidence).count() as u64;
    if implementer > fix_loop + 1 {
        return act("review", "review judged earlier code");
    }

    let blocked = last_value(&text, "Review status").as_deref() == Some("blocked");
    let next_action = text.lines().filter(|line| line.starts_with("- Next action:")).last().unwrap_or("");
    if blocked && (next_action.contains("/po-qa") || next_action.contains("QA evidence")) {
        let at_tip = subjects.iter().take_while(|subject| **subject == evidence).count();
        if at_tip >= 2 {
            return act("ask", "QA evidence committed twice");
        }
        return act("review", "review waited for QA");
    }
    if blocked && next_action.contains("findings-shape") {
        return act("ask", "findings-shape refused");
    }
    let max = context.lane_settings.as_ref().and_then(|settings| settings.max_attempts.as_deref());
    match max.and_then(number) {
        None => act("ask", "setting unreadable: Max attempts"),
        Some(max) if fix_loop >= max => act("ask", "Max attempts reached"),
        Some(_) => act("fix", "Ship allowed: no"),
    }
}

/// Stage `ship`: one ship at a time, in the order the reviews were recorded.
fn ship(context: &Context, lane: &Lane) -> NextAction {
    if lane.blocked_by == Some(BlockedBy::MergeWaiting) {
        return act("wait", "merge waiting");
    }
    let lanes = context.lanes.as_deref().unwrap_or_default();
    let competing = lanes.iter().filter(|other| {
        other.stage == Some(Stage::Ship)
            && !landed(context, &other.story)
            && other.blocked_by != Some(BlockedBy::MergeWaiting)
            && holding_decision(context, &other.story).is_none()
    });
    let first = competing
        .min_by_key(|other| (reviewed_at(other), story_rank(context, &other.story), other.story.clone()))
        .map(|other| other.story.as_str())
        .unwrap_or(lane.story.as_str());
    if first == lane.story {
        act("ship", "ship-allowed passes")
    } else {
        act("wait", format!("ships serial: {first}"))
    }
}

/// The review file's modification time, which `po record` sets by its rename; a lane without one
/// sorts last.
fn reviewed_at(lane: &Lane) -> (bool, Option<SystemTime>) {
    let time = std::fs::metadata(lane.path.join(format!("docs/reviews/{}.md", lane.story)))
        .and_then(|meta| meta.modified())
        .ok();
    (time.is_none(), time)
}

fn story_rank(context: &Context, id: &str) -> usize {
    context
        .stories
        .as_ref()
        .and_then(|stories| stories.list.iter().position(|story| story.id == id))
        .unwrap_or(usize::MAX)
}
