//! What each lane does next, and which stories are ready or held. Filled by a later story of M21;
//! the types follow docs/interface-agent.md and only this folder may reshape them.
#![allow(dead_code)]

use serde::Serialize;

use crate::output;
use crate::context::{self, Context};

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

pub fn main(_args: &[String]) -> i32 {
    output::not_built("next")
}

pub fn lane_next(_context: &Context, _lane: &context::Lane) -> Option<NextAction> {
    None
}

pub fn ready(_context: &Context) -> Option<Vec<String>> {
    None
}

pub fn held(_context: &Context) -> Option<Vec<Held>> {
    None
}
