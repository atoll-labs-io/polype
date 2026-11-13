//! The decisions waiting for the person (ADR-0107): `po inbox` lists them, `po inbox <id>` shows
//! one, `po inbox add` writes one. `po answer` comes with a later story of M21.

mod add;
mod decision;

use std::io;
use std::path::{Path, PathBuf};

use serde::Serialize;

use crate::output;
use crate::project::{Project, Setting};
use decision::{id_number, Decision};

pub struct Pending {
    pub ids: Vec<String>,
    pub unreadable: Vec<PathBuf>,
}

#[derive(Serialize)]
struct List {
    pending: Vec<Decision>,
}

pub fn main(args: &[String]) -> i32 {
    match args {
        [] => list(),
        [verb] if verb == "add" => add::main(),
        [id] if !id.starts_with('-') => show(id),
        _ => output::error(
            output::UNREADABLE,
            "unknown-option",
            format!("po inbox takes nothing, add, or one decision id; not {}", args.join(" ")),
        ),
    }
}

pub fn answer(_args: &[String]) -> i32 {
    output::not_built("answer")
}

/// The ids of the pending decisions of `dir`, oldest first; a missing folder holds none. Built on
/// the same reader as `po inbox`, so `po state` and the list never disagree.
pub fn pending_ids(dir: &Path) -> io::Result<Pending> {
    let (decisions, unreadable) = decision::read_dir(dir)?;
    let ids = decisions
        .into_iter()
        .filter(|decision| decision.status == "pending")
        .map(|decision| decision.id)
        .collect();
    Ok(Pending { ids, unreadable })
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
