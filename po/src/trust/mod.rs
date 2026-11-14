//! The shipped stories and their trust signals, read from the files each story landed with. The
//! types follow docs/interface-agent.md and only this folder may reshape them.

pub mod forge;
mod landed;
mod signals;

use serde::Serialize;

use crate::context::Context;

#[derive(Serialize, Clone, Debug, PartialEq)]
pub struct Trust {
    pub checks: Option<String>,
    pub oracle: Option<String>,
    pub fix_loops: Option<u32>,
    pub max_severity: Option<String>,
    pub not_verified: Option<u32>,
    pub method_version: Option<String>,
    pub track: Option<String>,
    pub duration_s: Option<u64>,
    pub cost_usd: Option<f64>,
}

#[derive(Serialize, Clone, Debug, PartialEq)]
pub struct Shipped {
    pub story: String,
    pub commit: Option<String>,
    pub trust: Option<Trust>,
}

/// The options of `po state`: `--all` lists every shipped story, `--remote` asks the forge.
#[derive(Default, Debug)]
pub struct StateOptions {
    pub all: bool,
    pub remote: bool,
}

pub fn state_options(args: &[String]) -> Result<StateOptions, String> {
    let mut options = StateOptions::default();
    for arg in args {
        match arg.as_str() {
            "--all" => options.all = true,
            "--remote" => options.remote = true,
            _ => return Err(format!("po state takes no option {arg}")),
        }
    }
    Ok(options)
}

pub fn shipped(context: &Context, options: &StateOptions) -> Option<Vec<Shipped>> {
    let stories = context.stories.as_ref()?;
    let landed = context.landed.as_ref()?;
    let current = context.milestone.as_ref().map(|milestone| milestone.id.as_str());
    let selected: Vec<(&str, &str)> = stories
        .list
        .iter()
        .filter(|story| options.all || (current.is_some() && story.milestone.as_deref() == current))
        .filter_map(|story| Some((story.id.as_str(), landed.commit(&story.id)?)))
        .collect();

    let spec = |commit: &str, folder: &str, id: &str| format!("{commit}:docs/{folder}/{id}.md");
    let specs: Vec<String> = selected
        .iter()
        .flat_map(|(id, commit)| ["reviews", "plans", "verif"].map(|folder| spec(commit, folder, id)))
        .collect();
    let blobs = landed::read_blobs(&context.project, &specs);
    let forge = if options.remote { forge::Forge::of(&context.project) } else { None };

    Some(
        selected
            .iter()
            .map(|(id, commit)| {
                let file = |folder: &str| blobs.get(&spec(commit, folder, id)).map(String::as_str);
                let review = signals::review(file("reviews"));
                Shipped {
                    story: id.to_string(),
                    commit: commit.get(..7).map(str::to_string),
                    trust: Some(Trust {
                        checks: forge.as_ref().and_then(|forge| forge.checks(commit)),
                        oracle: review.oracle,
                        fix_loops: review.fix_loops,
                        max_severity: review.max_severity,
                        not_verified: review.not_verified,
                        method_version: review.method_version,
                        track: signals::track(file("plans")),
                        duration_s: signals::duration(file("verif")),
                        cost_usd: None,
                    }),
                }
            })
            .collect(),
    )
}
