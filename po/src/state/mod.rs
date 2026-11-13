//! `po state`: the project's state as one JSON object, read from files and git only.

mod framing;
mod lanes;

use std::path::PathBuf;

use serde::Serialize;

use crate::project::{Project, Setting, PO_VERSION};
use crate::{inbox, next, output, run, trust};

pub use framing::{Framing, Milestone};
pub use lanes::{Lane, Stage};

#[derive(Serialize, Clone, Debug, PartialEq)]
#[serde(tag = "code", rename_all = "kebab-case")]
pub enum Warning {
    MethodVersionMismatch { po: String, project: String },
    MissingSetting { setting: String },
    UnreadableSetting { setting: String },
    OrphanWorktree { path: String, branch: Option<String> },
    UnreadableDecision { path: String },
    NoGate { story: String },
}

#[derive(Default)]
pub struct Warnings(Vec<Warning>);

impl Warnings {
    pub fn push(&mut self, warning: Warning) {
        if !self.0.contains(&warning) {
            self.0.push(warning);
        }
    }
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

/// The settings `po state` reads, each either a value or the warning already given for it.
pub struct Settings<'a> {
    project: &'a Project,
}

impl Settings<'_> {
    /// A value, or `None` after a `missing-setting` warning.
    pub fn required(&self, name: &str, warnings: &mut Warnings) -> Option<String> {
        match self.project.setting(name) {
            Setting::Value(value) => Some(value),
            Setting::Missing => {
                warnings.push(Warning::MissingSetting { setting: name.to_string() });
                None
            }
        }
    }

    /// Like `required`, but `—` cannot be used either and is named `unreadable-setting`.
    pub fn usable(&self, name: &str, warnings: &mut Warnings) -> Option<String> {
        let value = self.required(name, warnings)?;
        if value == "—" {
            warnings.push(Warning::UnreadableSetting { setting: name.to_string() });
            return None;
        }
        Some(value)
    }

    pub fn optional(&self, name: &str) -> Option<String> {
        match self.project.setting(name) {
            Setting::Value(value) => Some(value),
            Setting::Missing => None,
        }
    }
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
    output::reply(read(&project, &options), output::OK)
}

fn read(project: &Project, options: &trust::StateOptions) -> State {
    let mut warnings = Warnings::default();
    let settings = Settings { project };

    let method_version = project.method_version();
    if let Some(found) = &method_version {
        if found != PO_VERSION {
            warnings.push(Warning::MethodVersionMismatch {
                po: PO_VERSION.to_string(),
                project: found.clone(),
            });
        }
    }

    let target = settings.usable("Target branch", &mut warnings);
    let commit = target.as_deref().and_then(|target| project.commit(target));
    let stories = target.as_deref().map(|target| framing::Stories::read(project, target));
    let shipped = target.as_deref().map(|target| lanes::Shipped::read(project, target));

    let framing = if project.has_local_md() {
        target.as_deref().and_then(|target| {
            framing::framing(project, &settings, target, stories.as_ref()?, &mut warnings)
        })
    } else {
        Some(Framing::setup())
    };
    let milestone = match (&stories, &shipped) {
        (Some(stories), Some(shipped)) => framing::milestone(stories, shipped),
        _ => None,
    };

    let lanes = match (stories.as_ref(), shipped.as_ref()) {
        (Some(stories), Some(shipped)) => lanes::lanes(project, &settings, stories, shipped, &mut warnings),
        _ => {
            settings.usable("Worktree root", &mut warnings);
            None
        }
    };

    let waiting = waiting(project, &settings, &mut warnings);

    State {
        project: project.name(),
        commit,
        method_version,
        framing,
        milestone,
        session: run::session(),
        bounds: run::bounds(),
        waiting,
        lanes,
        ready: next::ready(),
        held: next::held(),
        shipped: trust::shipped(options),
        warnings: warnings.0,
    }
}

fn waiting(project: &Project, settings: &Settings, warnings: &mut Warnings) -> Option<Vec<String>> {
    let setting = settings.usable("Decision inbox", warnings)?;
    let dir = {
        let path = PathBuf::from(&setting);
        if path.is_absolute() { path } else { project.root.join(path) }
    };
    match inbox::pending_ids(&dir) {
        Ok(pending) => {
            for path in pending.unreadable {
                warnings.push(Warning::UnreadableDecision { path: path.display().to_string() });
            }
            Some(pending.ids)
        }
        Err(_) => {
            warnings.push(Warning::UnreadableDecision { path: dir.display().to_string() });
            None
        }
    }
}
