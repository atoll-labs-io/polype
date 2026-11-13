//! `po state`: the project's state as one JSON object, composed from the project context.

use serde::Serialize;

use crate::context::{BlockedBy, Context, Framing, Milestone, Stage, Warning};
use crate::project::Project;
use crate::{next, output, run, trust};

#[derive(Serialize, Clone, Debug, PartialEq)]
pub struct Lane {
    pub story: String,
    pub stage: Option<Stage>,
    pub next: Option<next::NextAction>,
    pub blocked_by: Option<BlockedBy>,
}

#[derive(Serialize)]
pub struct State {
    pub project: String,
    pub commit: Option<String>,
    pub method_version: Option<String>,
    pub framing: Option<Framing>,
    pub milestone: Option<Milestone>,
    pub session: Option<run::Session>,
    pub bounds: Option<run::Bounds>,
    pub waiting: Option<Vec<String>>,
    pub lanes: Option<Vec<Lane>>,
    pub ready: Option<Vec<String>>,
    pub held: Option<Vec<next::Held>>,
    pub shipped: Option<Vec<trust::Shipped>>,
    pub warnings: Vec<Warning>,
}

pub fn main(args: &[String]) -> i32 {
    let options = match trust::state_options(args) {
        Ok(options) => options,
        Err(message) => return output::error(output::UNREADABLE, "unknown-option", message),
    };
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
    output::reply(compose(&context, &options), output::OK)
}

fn compose(context: &Context, options: &trust::StateOptions) -> State {
    let waiting = context.inbox.as_ref().map(|inbox| {
        inbox
            .decisions
            .iter()
            .filter(|decision| decision.status == "pending")
            .map(|decision| decision.id.clone())
            .collect()
    });
    let lanes = context.lanes.as_ref().map(|lanes| {
        lanes
            .iter()
            .map(|lane| Lane {
                story: lane.story.clone(),
                stage: lane.stage,
                next: next::lane_next(context, lane),
                blocked_by: lane.blocked_by,
            })
            .collect()
    });
    State {
        project: context.project.name(),
        commit: context.commit.clone(),
        method_version: context.method_version.clone(),
        framing: context.framing.clone(),
        milestone: context.milestone.clone(),
        session: run::session(context),
        bounds: run::bounds(context),
        waiting,
        lanes,
        ready: next::ready(context),
        held: next::held(context),
        shipped: trust::shipped(context, options),
        warnings: context.warnings.list().to_vec(),
    }
}
