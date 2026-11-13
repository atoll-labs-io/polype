//! The shipped stories and their trust signals. Filled by a later story of M21; the types follow
//! docs/interface-agent.md and only this folder may reshape them.
#![allow(dead_code)]

use serde::Serialize;

#[derive(Serialize, Clone, Debug, PartialEq)]
pub struct Trust {
    pub checks: Option<String>,
    pub oracle: Option<String>,
    pub fix_loops: Option<u32>,
    pub max_severity: Option<String>,
    pub not_verified: Option<u32>,
    pub method_version: Option<String>,
    pub duration_s: Option<f64>,
    pub cost_usd: Option<f64>,
}

#[derive(Serialize, Clone, Debug, PartialEq)]
pub struct Shipped {
    pub story: String,
    pub commit: Option<String>,
    pub trust: Option<Trust>,
}

/// The options of `po state`. None is accepted yet: the story that computes `shipped` adds its own.
#[derive(Default, Debug)]
pub struct StateOptions {}

pub fn state_options(args: &[String]) -> Result<StateOptions, String> {
    match args.first() {
        None => Ok(StateOptions::default()),
        Some(arg) => Err(format!("po state takes no option {arg}")),
    }
}

pub fn shipped(_options: &StateOptions) -> Option<Vec<Shipped>> {
    None
}
