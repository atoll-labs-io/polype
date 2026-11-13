//! What each lane does next, and which stories are ready or held, from files and git only. The
//! types follow docs/interface-agent.md and only this folder may reshape them.

mod lane;
mod overlap;
mod wave;

use serde::Serialize;

use crate::context::{self, Context, Warning};
use crate::output;
use crate::project::Project;

#[derive(Serialize, Clone, Debug, PartialEq)]
pub struct NextAction {
    pub action: String,
    pub reason: String,
}

#[derive(Serialize, Clone, Debug, PartialEq)]
pub struct Held {
    pub story: String,
    pub reason: String,
    #[serde(rename = "ref")]
    pub reference: Option<String>,
}

#[derive(Serialize)]
struct Entry {
    story: String,
    action: String,
    reason: String,
}

#[derive(Serialize)]
struct Next {
    actions: Option<Vec<Entry>>,
    ready: Option<Vec<String>>,
    held: Option<Vec<Held>>,
    warnings: Vec<Warning>,
}

pub fn main(args: &[String]) -> i32 {
    if let Some(arg) = args.first() {
        return output::error(output::UNREADABLE, "unknown-option", format!("po next takes no option {arg}"));
    }
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
    let wave = wave::ready_and_held(&context);
    let actions = context.lanes.as_ref().filter(|_| stories_read(&context)).map(|lanes| {
        let mut actions: Vec<Entry> = lanes
            .iter()
            .filter_map(|lane| {
                let next = lane_next(&context, lane)?;
                Some(Entry { story: lane.story.clone(), action: next.action, reason: next.reason })
            })
            .collect();
        if let Some((ready, _)) = &wave {
            actions.extend(ready.iter().map(|id| Entry {
                story: id.clone(),
                action: "plan".to_string(),
                reason: "ready".to_string(),
            }));
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
    stories_read(context).then(|| lane::next(context, lane))
}

pub fn ready(context: &Context) -> Option<Vec<String>> {
    wave::ready_and_held(context).map(|(ready, _)| ready)
}

pub fn held(context: &Context) -> Option<Vec<Held>> {
    wave::ready_and_held(context).map(|(_, held)| held)
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
