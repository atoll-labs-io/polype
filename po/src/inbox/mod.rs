//! The decisions waiting for the person (ADR-0107): `po inbox` lists them, `po inbox <id>` shows
//! one, `po inbox add` writes one, `po answer` records the person's choice among its options.
//! `po inbox --answered` lists what the lead has not consumed yet, `po inbox consume` marks it.

mod add;
mod decision;
mod rewrite;

use std::io;
use std::path::{Path, PathBuf};

use serde::Serialize;

use crate::output;
use crate::project::{Project, Setting};
use decision::id_number;
pub use decision::Decision;

const REF_MAX: usize = 200;

#[derive(Serialize)]
struct List {
    pending: Vec<Decision>,
}

#[derive(Serialize)]
struct Answered {
    answered: Vec<Decision>,
}

pub fn main(args: &[String]) -> i32 {
    match args {
        [] => list(),
        [verb] if verb == "add" => add::main(),
        [flag] if flag == "--answered" => answered(),
        [verb, id, reference] if verb == "consume" => consume(id, reference),
        [verb, ..] if verb == "consume" => unknown_option("po inbox consume takes a decision id and a ref", args),
        [id] if !id.starts_with('-') => show(id),
        _ => unknown_option("po inbox takes nothing, add, --answered, consume <id> <ref>, or one decision id", args),
    }
}

/// `po answer <id> <key>`: the key must equal a listed option key byte for byte. It is never
/// trimmed, parsed, put into a path nor handed to a process.
pub fn answer(args: &[String]) -> i32 {
    let [id, key] = args else {
        return unknown_option("po answer takes a decision id and an option key", args);
    };
    let (project, dir) = match locate() {
        Ok(found) => found,
        Err(code) => return code,
    };
    rewrite::rewrite(&project, &dir, id, |decision| {
        if decision.status != "pending" {
            return Err(("already-answered", format!("{id} is {}, not pending", decision.status)));
        }
        let keys: Vec<&str> = decision
            .options
            .iter()
            .flatten()
            .filter_map(|option| option.get("key").and_then(|key| key.as_str()))
            .collect();
        if !keys.contains(&key.as_str()) {
            return Err(("not-an-option", format!("{key:?} is not an option of {id}; its keys: {}", keys.join(", "))));
        }
        decision.status = "answered".to_string();
        decision.answer = Some(serde_json::json!({ "key": key, "at": rewrite::now() }));
        Ok(())
    })
}

fn consume(id: &str, reference: &str) -> i32 {
    if reference.trim().is_empty() || reference.contains(['\n', '\r']) || reference.chars().count() > REF_MAX {
        return output::error(
            output::REFUSED,
            "malformed-ref",
            format!("the ref must be one non-empty line of at most {REF_MAX} characters"),
        );
    }
    let (project, dir) = match locate() {
        Ok(found) => found,
        Err(code) => return code,
    };
    rewrite::rewrite(&project, &dir, id, |decision| {
        if decision.status == "pending" {
            return Err(("not-answered", format!("{id} is still pending")));
        }
        if decision.consumed.is_some() {
            return Err(("already-consumed", format!("{id} was already consumed")));
        }
        decision.consumed = Some(serde_json::json!({ "ref": reference, "at": rewrite::now() }));
        Ok(())
    })
}

fn unknown_option(usage: &str, args: &[String]) -> i32 {
    output::error(output::UNREADABLE, "unknown-option", format!("{usage}; not {}", args.join(" ")))
}

/// Every decision of `dir` in id order, and the files that do not parse; a missing folder holds
/// none. The same reader as `po inbox`, so the project context and the list never disagree.
pub fn read_decisions(dir: &Path) -> io::Result<(Vec<Decision>, Vec<PathBuf>)> {
    decision::read_dir(dir)
}

/// The project and its inbox folder, or the exit code of the refusal already printed.
fn locate() -> Result<(Project, PathBuf), i32> {
    let project = std::env::current_dir().ok().and_then(|cwd| Project::find(&cwd));
    let Some(project) = project else {
        return Err(output::error(
            output::UNREADABLE,
            "not-a-project",
            "not inside a Polype project: no AGENTS.local.md nor .polype/version at the repository root",
        ));
    };
    let value = match project.setting("Decision inbox") {
        Setting::Value(value) if value != "—" => value,
        _ => {
            return Err(output::error(
                output::UNREADABLE,
                "no-inbox-setting",
                "AGENTS.local.md sets no Decision inbox folder",
            ))
        }
    };
    let path = PathBuf::from(&value);
    let dir = if path.is_absolute() { path } else { project.root.join(path) };
    Ok((project, dir))
}

fn list() -> i32 {
    let (_, dir) = match locate() {
        Ok(found) => found,
        Err(code) => return code,
    };
    // A file that does not parse is skipped here; `po state` names it as unreadable-decision.
    match decision::read_dir(&dir) {
        Ok((decisions, _)) => {
            let pending = decisions.into_iter().filter(|d| d.status == "pending").collect();
            output::reply(List { pending }, output::OK)
        }
        Err(err) => output::error(
            output::UNREADABLE,
            "unreadable-decision",
            format!("cannot read {}: {err}", dir.display()),
        ),
    }
}

fn answered() -> i32 {
    let (_, dir) = match locate() {
        Ok(found) => found,
        Err(code) => return code,
    };
    match decision::read_dir(&dir) {
        Ok((decisions, _)) => {
            let answered = decisions
                .into_iter()
                .filter(|d| d.status == "answered" && d.consumed.is_none())
                .collect();
            output::reply(Answered { answered }, output::OK)
        }
        Err(err) => output::error(
            output::UNREADABLE,
            "unreadable-decision",
            format!("cannot read {}: {err}", dir.display()),
        ),
    }
}

fn show(id: &str) -> i32 {
    let (_, dir) = match locate() {
        Ok(found) => found,
        Err(code) => return code,
    };
    // The id becomes a path: only `d-<digits>` may reach the filesystem.
    if id_number(id).is_none() {
        return unknown(id);
    }
    let path = dir.join(format!("{id}.json"));
    match std::fs::metadata(&path) {
        Err(err) if err.kind() == io::ErrorKind::NotFound => return unknown(id),
        _ => {}
    }
    match decision::read_file(&path) {
        Some(decision) => output::reply(decision, output::OK),
        None => output::error(
            output::UNREADABLE,
            "unreadable-decision",
            format!("{} does not parse as a decision", path.display()),
        ),
    }
}

fn unknown(id: &str) -> i32 {
    output::error(output::REFUSED, "unknown-decision", format!("no decision {id} in the inbox"))
}
