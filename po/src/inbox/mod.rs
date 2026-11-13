//! The decisions waiting for the person. `po inbox` and `po answer` come with a later story of M21;
//! `po state` already reads which decisions are pending.

use std::io;
use std::path::{Path, PathBuf};

use serde::Deserialize;

use crate::output;

/// The narrow view of a decision file: a newer `po` may add fields, which must not make this one
/// drop the file (ADR-0117), so unknown fields are ignored here.
#[derive(Deserialize, Debug)]
pub struct DecisionStatus {
    pub id: String,
    pub status: String,
}

pub struct Pending {
    pub ids: Vec<String>,
    pub unreadable: Vec<PathBuf>,
}

pub fn main(_args: &[String]) -> i32 {
    output::not_built("inbox")
}

pub fn answer(_args: &[String]) -> i32 {
    output::not_built("answer")
}

/// The ids of the pending decisions of `dir`, sorted; a missing folder holds none.
pub fn pending_ids(dir: &Path) -> io::Result<Pending> {
    let mut pending = Pending { ids: Vec::new(), unreadable: Vec::new() };
    let entries = match std::fs::read_dir(dir) {
        Ok(entries) => entries,
        Err(err) if err.kind() == io::ErrorKind::NotFound => return Ok(pending),
        Err(err) => return Err(err),
    };
    let mut files: Vec<PathBuf> = entries
        .filter_map(|entry| entry.ok().map(|entry| entry.path()))
        .filter(|path| path.extension().is_some_and(|ext| ext == "json") && path.is_file())
        .collect();
    files.sort();
    for path in files {
        let parsed = std::fs::read_to_string(&path)
            .ok()
            .and_then(|text| serde_json::from_str::<DecisionStatus>(&text).ok());
        match parsed {
            Some(decision) if decision.status == "pending" => pending.ids.push(decision.id),
            Some(_) => {}
            None => pending.unreadable.push(path),
        }
    }
    pending.ids.sort();
    Ok(pending)
}
