//! The ready set of po-drive.md: which stories may open a lane now, and why the others wait.

use super::overlap::overlap;
use super::{holding_decision, Held};
use crate::context::{BlockedBy, Context, Lane, Story, Warning};
use crate::project::Setting;

/// `None` when the stories, the lanes or `Parallel` cannot be read.
pub fn ready_and_held(context: &Context) -> Option<(Vec<String>, Vec<Held>)> {
    let stories = context.stories.as_ref().filter(|stories| stories.present)?;
    let landed = context.landed.as_ref()?;
    let lanes = context.lanes.as_ref()?;
    let parallel: i64 = match context.project.setting("Parallel") {
        Setting::Value(value) if !value.is_empty() && value.bytes().all(|b| b.is_ascii_digit()) => value.parse().ok()?,
        _ => return None,
    };

    let lane_of = |id: &str| lanes.iter().find(|lane| lane.story == id);
    let frees = |lane: &Lane| landed.contains(&lane.story) || lane.blocked_by == Some(BlockedBy::MaxAttempts);
    let busy = lanes
        .iter()
        .filter(|lane| !frees(lane) && lane.blocked_by != Some(BlockedBy::MergeWaiting))
        .count() as i64;
    let mut slots = parallel - busy;

    let mut taken: Vec<&Story> = stories
        .list
        .iter()
        .filter(|story| lane_of(&story.id).is_some_and(|lane| !frees(lane)))
        .collect();

    let orphaned = |id: &str| {
        let branch = format!("story/{id}");
        context.warnings.list().iter().any(|warning| {
            matches!(warning, Warning::OrphanWorktree { branch: Some(b), .. } if *b == branch)
        })
    };

    let mut ready = Vec::new();
    let mut held = Vec::new();
    for story in &stories.list {
        let id = story.id.as_str();
        if landed.contains(id) || lane_of(id).is_some() || orphaned(id) {
            continue;
        }
        let hold = |reason: &str, reference: Option<String>| Held {
            story: id.to_string(),
            reason: reason.to_string(),
            reference,
        };
        if let Some(dependency) = story.depends_on.iter().find(|dep| !landed.contains(dep)) {
            held.push(hold("dependency", Some(dependency.clone())));
        } else if let Some(decision) = holding_decision(context, id) {
            held.push(hold("decision", Some(decision.to_string())));
        } else if let Some(holder) = taken.iter().find(|holder| {
            story.owns.iter().any(|mine| holder.owns.iter().any(|theirs| overlap(mine, theirs)))
        }) {
            held.push(hold("owns", Some(holder.id.clone())));
        } else if slots <= 0 {
            held.push(hold("parallel", None));
        } else {
            slots -= 1;
            ready.push(story.id.clone());
            taken.push(story);
        }
    }
    Some((ready, held))
}
