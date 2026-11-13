//! The project as every verb reads it: settings, stories, landed set, framing, lanes and inbox,
//! read once per call from files and git only.

mod framing;
mod lanes;
mod stories;

use std::path::PathBuf;

use serde::Serialize;

use crate::inbox::{self, Decision};
use crate::project::{Project, Setting, PO_VERSION};

pub use framing::{Framing, Milestone};
pub use lanes::{BlockedBy, Lane, LaneSettings, Landed, Stage};
pub use stories::Stories;

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

    pub fn list(&self) -> &[Warning] {
        &self.0
    }
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

/// The `Decision inbox` folder and what it holds.
// `dir` and `unreadable` wait for the verbs of later M21 stories.
#[allow(dead_code)]
pub struct Inbox {
    pub dir: PathBuf,
    /// In id order, every status.
    pub decisions: Vec<Decision>,
    /// The `*.json` files that do not parse.
    pub unreadable: Vec<PathBuf>,
}

/// One read of the project. `project.setting()` gives a later verb any other setting, read without
/// a warning, so the warnings `po state` prints never depend on which verb asked.
// Fields only the verbs of later M21 stories read (stories' deps and `Owns`, landed commits, lane
// paths, the inbox's decisions) would otherwise warn until those stories land.
#[allow(dead_code)]
pub struct Context {
    pub project: Project,
    pub method_version: Option<String>,
    pub target: Option<String>,
    /// The target branch's commit, short.
    pub commit: Option<String>,
    pub stories: Option<Stories>,
    pub landed: Option<Landed>,
    pub framing: Option<Framing>,
    /// The current milestone: the first holding a story not landed.
    pub milestone: Option<Milestone>,
    /// Read only when the stories and the landed set are.
    pub lane_settings: Option<LaneSettings>,
    pub lanes: Option<Vec<Lane>>,
    pub inbox: Option<Inbox>,
    pub warnings: Warnings,
}

impl Context {
    /// The reads happen in this order because it is the order of `po state`'s warnings.
    pub fn read(project: Project) -> Context {
        let mut warnings = Warnings::default();
        let settings = Settings { project: &project };

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
        let stories = target.as_deref().map(|target| Stories::read(&project, target));
        let landed = target.as_deref().map(|target| Landed::read(&project, target));

        let framing = if project.has_local_md() {
            target.as_deref().and_then(|target| {
                framing::framing(&project, &settings, target, stories.as_ref()?, &mut warnings)
            })
        } else {
            Some(Framing::setup())
        };
        let milestone = match (&stories, &landed) {
            (Some(stories), Some(landed)) => framing::milestone(stories, landed),
            _ => None,
        };

        let (lane_settings, lanes) = match (stories.as_ref(), landed.as_ref()) {
            (Some(stories), Some(landed)) => {
                let lane_settings = LaneSettings::read(&settings, &mut warnings);
                let lanes = settings.usable("Worktree root", &mut warnings).map(|root| {
                    lanes::lanes(&project, root, &lane_settings, stories, landed, &mut warnings)
                });
                (Some(lane_settings), lanes)
            }
            _ => {
                settings.usable("Worktree root", &mut warnings);
                (None, None)
            }
        };

        let inbox = read_inbox(&project, &settings, &mut warnings);

        Context {
            project,
            method_version,
            target,
            commit,
            stories,
            landed,
            framing,
            milestone,
            lane_settings,
            lanes,
            inbox,
            warnings,
        }
    }
}

fn read_inbox(project: &Project, settings: &Settings, warnings: &mut Warnings) -> Option<Inbox> {
    let setting = settings.usable("Decision inbox", warnings)?;
    let dir = {
        let path = PathBuf::from(&setting);
        if path.is_absolute() { path } else { project.root.join(path) }
    };
    match inbox::read_decisions(&dir) {
        Ok((decisions, unreadable)) => {
            for path in &unreadable {
                warnings.push(Warning::UnreadableDecision { path: path.display().to_string() });
            }
            Some(Inbox { dir, decisions, unreadable })
        }
        Err(_) => {
            warnings.push(Warning::UnreadableDecision { path: dir.display().to_string() });
            None
        }
    }
}
