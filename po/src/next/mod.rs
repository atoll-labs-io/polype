//! What each lane does next, and which stories are ready or held, from files and git only. The
//! types follow docs/interface-agent.md and only this folder may reshape them.

mod lane;
mod overlap;
mod wave;

use serde::Serialize;

use crate::context::{self, Context, Warning};
use crate::output;
use crate::project::Project;
use crate::trust::forge::Forge;

#[derive(Serialize, Clone, Copy, Debug, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum Track {
    Full,
    Flow,
}

/// `track` is set on a `plan` action only.
#[derive(Serialize, Clone, Debug, PartialEq)]
pub struct NextAction {
    pub action: String,
    pub reason: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub track: Option<Track>,
}

#[derive(Serialize, Clone, Debug, PartialEq)]
pub struct Held {
    pub story: String,
    pub reason: String,
    #[serde(rename = "ref")]
    pub reference: Option<String>,
    /// For `owns` only: the overlapping pair of entries.
    #[serde(flatten)]
    pub collision: Option<Collision>,
}

#[derive(Serialize, Clone, Debug, PartialEq)]
pub struct Collision {
    pub entry: String,
    pub ref_entry: String,
    pub path: Option<String>,
}

#[derive(Serialize)]
struct Entry {
    story: String,
    action: String,
    reason: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    track: Option<Track>,
}

impl Entry {
    fn of(story: &str, next: NextAction) -> Entry {
        Entry { story: story.to_string(), action: next.action, reason: next.reason, track: next.track }
    }
}

#[derive(Serialize)]
struct Next {
    actions: Option<Vec<Entry>>,
    ready: Option<Vec<String>>,
    held: Option<Vec<Held>>,
    warnings: Vec<Warning>,
}

pub fn main(args: &[String]) -> i32 {
    if let Some(arg) = args.iter().find(|arg| *arg != "--remote") {
        return output::error(output::UNREADABLE, "unknown-option", format!("po next takes no option {arg}"));
    }
    let remote = !args.is_empty();
    let Ok(cwd) = std::env::current_dir() else {
        return output::error(output::UNREADABLE, "not-a-project", "the current directory cannot be read");
    };
    let Some(project) = Project::find(&cwd) else {
        return output::error(
            output::UNREADABLE,
            "not-a-project",
            "not inside a Polype project: no AGENTS.local.md nor .polype/version at the repository root",
        );
    };
    let context = Context::read(project);
    let closed = if remote { closed_pull_requests(&context) } else { Vec::new() };
    let wave = wave::ready_and_held(&context);
    let actions = context.lanes.as_ref().filter(|_| stories_read(&context)).map(|lanes| {
        let mut actions: Vec<Entry> = lanes
            .iter()
            .map(|lane| Entry::of(&lane.story, lane::next(&context, lane, &closed)))
            .collect();
        if let Some((ready, _)) = &wave {
            actions.extend(ready.iter().map(|id| Entry::of(id, lane::plan(&context, id, "ready"))));
        }
        actions
    });
    let (ready, held) = match wave {
        Some((ready, held)) => (Some(ready), Some(held)),
        None => (None, None),
    };
    output::reply(Next { actions, ready, held, warnings: context.warnings.list().to_vec() }, output::OK)
}

fn stories_read(context: &Context) -> bool {
    context.stories.as_ref().is_some_and(|stories| stories.present)
}

/// `None` only when `docs/stories.md` cannot be read on the target branch.
pub fn lane_next(context: &Context, lane: &context::Lane) -> Option<NextAction> {
    stories_read(context).then(|| lane::next(context, lane, &[]))
}

/// The lanes at `ship`, not landed nor held, whose pull request on github.com was closed without a
/// merge; under `Merge mode: pr` only. A forge that cannot be read closes nothing.
fn closed_pull_requests(context: &Context) -> Vec<String> {
    let pr = context.lane_settings.as_ref().and_then(|settings| settings.merge_mode.as_deref()) == Some("pr");
    let (Some(forge), true, Some(lanes)) = (Forge::of(&context.project), pr, context.lanes.as_ref()) else {
        return Vec::new();
    };
    lanes
        .iter()
        .filter(|lane| {
            lane.stage == Some(context::Stage::Ship)
                && !lane::landed(context, &lane.story)
                && waiting_dependency(context, &lane.story).is_none()
                && holding_decision(context, &lane.story).is_none()
                && forge.pull_request_closed(&format!("story/{}", lane.story)) == Some(true)
        })
        .map(|lane| lane.story.clone())
        .collect()
}

pub fn ready(context: &Context) -> Option<Vec<String>> {
    wave::ready_and_held(context).map(|(ready, _)| ready)
}

pub fn held(context: &Context) -> Option<Vec<Held>> {
    wave::ready_and_held(context).map(|(_, held)| held)
}

/// The first dependency of `id`, in declared order, that has not shipped.
fn waiting_dependency<'a>(context: &'a Context, id: &str) -> Option<&'a str> {
    let landed = context.landed.as_ref()?;
    let story = context.stories.as_ref()?.find(id)?;
    story.depends_on.iter().find(|dep| !landed.contains(dep)).map(String::as_str)
}

/// The first decision, in id order, that names `id` in `blocks` and has not been consumed.
fn holding_decision<'a>(context: &'a Context, id: &str) -> Option<&'a str> {
    let inbox = context.inbox.as_ref()?;
    inbox
        .decisions
        .iter()
        .find(|decision| {
            decision.consumed.is_none()
                && decision.blocks.as_ref().is_some_and(|blocks| blocks.iter().any(|b| b == id))
        })
        .map(|decision| decision.id.as_str())
}
