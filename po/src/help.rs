//! `po <verb> --help`: the verb's usage, read from nothing and writing nothing.

use serde::Serialize;

use crate::output;

const STATE: &str = "usage: po state [--all] [--remote]";
const NEXT: &str = "usage: po next [--remote]";
const INBOX: &str = "usage: po inbox | po inbox add, one decision as JSON on stdin (see input) | po inbox --answered \
     | po inbox consume <id> <ref> | po inbox <id>";
const ANSWER: &str = "usage: po answer <id> <key>";
const RUN: &str = "usage: po run, no argument";
const CONTINUE: &str = "usage: po continue, no argument";

#[derive(Serialize)]
struct Help {
    verb: String,
    usage: &'static str,
    #[serde(skip_serializing_if = "Option::is_none")]
    input: Option<serde_json::Value>,
}

/// `Some(exit code)` when `args` asks for the help of a verb that has one.
pub fn main(verb: &str, args: &[String]) -> Option<i32> {
    if !args.iter().any(|arg| arg == "--help") {
        return None;
    }
    let usage = match verb {
        "state" => STATE,
        "next" => NEXT,
        "inbox" => INBOX,
        "answer" => ANSWER,
        "record" => crate::record::USAGE,
        "run" => RUN,
        "continue" => CONTINUE,
        "ship" => crate::ship::USAGE,
        _ => return None,
    };
    let input = (verb == "inbox").then(decision_form);
    Some(output::reply(Help { verb: verb.to_string(), usage, input }, output::OK))
}

/// A decision `po inbox add` accepts as it stands; `sensitive`, `context` and `story` may be added.
fn decision_form() -> serde_json::Value {
    serde_json::json!({
        "motive": "stop",
        "question": "Retry the lane of s01-example?",
        "options": [
            { "key": "a", "label": "Retry", "consequence": "one more run of the lane" },
            { "key": "b", "label": "Wait", "consequence": "the lane stays where it is" }
        ],
        "recommended": "a",
        "why": "the cause of the failure is known and fixed",
        "reversible": true,
        "blocks": []
    })
}
