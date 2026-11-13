//! The project lead's session, and whether the subagents' bounds hold in it. Filled by a later
//! story of M21; the types follow docs/interface-agent.md and only this folder may reshape them.
#![allow(dead_code)]

use serde::Serialize;

use crate::output;

#[derive(Serialize, Clone, Debug, PartialEq)]
pub struct Session {
    pub running: bool,
    pub id: Option<String>,
}

#[derive(Serialize, Clone, Copy, Debug, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum Bounds {
    Held,
    Unproven,
}

pub fn main(_args: &[String]) -> i32 {
    output::not_built("run")
}

pub fn resume(_args: &[String]) -> i32 {
    output::not_built("continue")
}

pub fn session() -> Option<Session> {
    None
}

pub fn bounds() -> Option<Bounds> {
    None
}
