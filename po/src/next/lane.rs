//! A lane's next action: the first rule that holds, in the order `next` checks them below.
//! Stage and stops come from the context; only `qa-current` (stage `qa`) and `git log` (a review
//! that blocked) are asked again, and only for this lane.

use std::path::Path;
use std::process::{Command, Stdio};
use std::time::UNIX_EPOCH;

use super::{holding_decision, waiting_dependency, NextAction, Track};
use crate::context::{goes_to_qa, BlockedBy, Context, Lane, Stage};
use crate::project::{self, Setting};

fn act(action: &str, reason: impl Into<String>) -> NextAction {
    NextAction { action: action.to_string(), reason: reason.into(), track: None }
}

/// A `plan` action with the story's track, or the `ask` of a track that cannot be read: `Story
/// track` first, then the signals that force `full`, then `Flow threshold` under `auto` only.
pub(super) fn plan(context: &Context, id: &str, reason: &str) -> NextAction {
    let mode = setting(context, "Story track");
    if !matches!(mode.as_deref(), Some("full" | "flow" | "auto")) {
        return act("ask", "setting unreadable: Story track");
    }
    let track = |track| NextAction { track: Some(track), ..act("plan", reason) };
    if mode.as_deref() == Some("full") {
        return track(Track::Full);
    }
    let story = context.stories.as_ref().and_then(|stories| stories.find(id));
    let qa_stage = context.lane_settings.as_ref().and_then(|settings| settings.qa_stage.as_deref());
    let forced = story.is_some_and(|story| story.fixes || story.has_screen());
    match goes_to_qa(story, qa_stage) {
        Err(_) => return act("ask", "setting unreadable: QA stage"),
        Ok(qa) if forced || qa => return track(Track::Full),
        Ok(_) => {}
    }
    if mode.as_deref() == Some("flow") {
        return track(Track::Flow);
    }
    let Some(threshold) = setting(context, "Flow threshold").as_deref().and_then(number) else {
        return act("ask", "setting unreadable: Flow threshold");
    };
    let Some(complexity) = story.and_then(|story| story.complexity) else {
        return act("ask", "no complexity");
    };
    track(if u64::from(complexity) <= threshold { Track::Flow } else { Track::Full })
}

pub(super) fn landed(context: &Context, id: &str) -> bool {
    context.landed.as_ref().is_some_and(|landed| landed.contains(id))
}

/// `closed` holds the lanes whose pull request the forge reads as closed without a merge.
pub fn next(context: &Context, lane: &Lane, closed: &[String]) -> NextAction {
    let id = lane.story.as_str();
    let path = lane.path.as_path();
    if landed(context, id) {
        return act("ship", "landed");
    }
    if let Some(dependency) = waiting_dependency(context, id) {
        return act("wait", format!("dependency {dependency}"));
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
    let planned = path.join(format!("docs/plans/{id}.md")).is_file();
    if !research && !planned {
        return plan(context, id, "no research");
    }
    match lane.blocked_by {
        Some(BlockedBy::RootCauseNotFound) => return act("ask", "Root cause: not found"),
        Some(BlockedBy::TechnicalChoice) => return act("ask", "Technical choice: waiting for a human"),
        _ => {}
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
    if !planned {
        return plan(context, id, "research, no plan");
    }
    if stage == Stage::Plan {
        return match setting(context, "Plan validation").as_deref() {
            Some("human") => act("validate-plan", "plan-validated refuses"),
            Some("autonomous") => plan(context, id, "plan-validated refuses"),
            _ => act("ask", "setting unreadable: Plan validation"),
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
        Stage::Ship => ship(context, lane, closed),
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

/// Stage `ship`: one ship at a time, in the order the reviews were recorded; a pull request closed
/// without a merge goes to a person and leaves that order.
fn ship(context: &Context, lane: &Lane, closed: &[String]) -> NextAction {
    if closed.contains(&lane.story) {
        return act("ask", "pull request closed");
    }
    if lane.blocked_by == Some(BlockedBy::MergeWaiting) {
        return act("wait", "merge waiting");
    }
    let lanes = context.lanes.as_deref().unwrap_or_default();
    let competing = lanes.iter().filter(|other| {
        other.stage == Some(Stage::Ship)
            && !landed(context, &other.story)
            && other.blocked_by != Some(BlockedBy::MergeWaiting)
            && !closed.contains(&other.story)
            && holding_decision(context, &other.story).is_none()
            && waiting_dependency(context, &other.story).is_none()
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

/// When the review was recorded, as seconds and nanoseconds since the epoch: the newest `Recorded:`
/// line `po record review` writes right under a `Method version:` line, else the file's
/// modification time for a review recorded before that line existed. A lane without either sorts
/// last.
fn reviewed_at(lane: &Lane) -> (bool, Option<(i64, u32)>) {
    let file = lane.path.join(format!("docs/reviews/{}.md", lane.story));
    let time = std::fs::read_to_string(&file)
        .ok()
        .and_then(|text| recorded(&text))
        .or_else(|| {
            let modified = std::fs::metadata(&file).and_then(|meta| meta.modified()).ok()?;
            let since = modified.duration_since(UNIX_EPOCH).ok()?;
            Some((i64::try_from(since.as_secs()).ok()?, since.subsec_nanos()))
        });
    (time.is_none(), time)
}

/// The newest rather than the last: a review recorded onto itself carries its older blocks, stamps
/// included, after the stamp of the block just written.
fn recorded(text: &str) -> Option<(i64, u32)> {
    let lines: Vec<&str> = text.lines().collect();
    lines
        .windows(2)
        .filter(|pair| pair[0].starts_with("Method version:"))
        .filter_map(|pair| pair[1].strip_prefix("Recorded:"))
        .filter_map(|value| chrono::DateTime::parse_from_rfc3339(value.trim()).ok())
        .map(|date| (date.timestamp(), 0))
        .max()
}

fn story_rank(context: &Context, id: &str) -> usize {
    context
        .stories
        .as_ref()
        .and_then(|stories| stories.list.iter().position(|story| story.id == id))
        .unwrap_or(usize::MAX)
}
