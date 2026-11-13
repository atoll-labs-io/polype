//! A decision as `po inbox add` takes it from the lead, and as it is written and read back.

use std::io;
use std::path::{Path, PathBuf};

use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};

#[derive(Serialize, Deserialize, Clone, Copy, PartialEq, Eq, Debug)]
#[serde(rename_all = "kebab-case")]
pub enum Motive {
    Incoherence,
    NewIdea,
    Strategic,
    TechnicalChoice,
    Stop,
    Security,
}

/// What the lead hands over: no id, date, status nor answer, and nothing the contract lacks.
#[derive(Deserialize, Debug)]
#[serde(deny_unknown_fields)]
pub struct NewDecision {
    pub motive: Motive,
    #[serde(default)]
    pub sensitive: bool,
    pub question: String,
    #[serde(default)]
    pub context: Option<String>,
    pub options: Vec<Choice>,
    pub recommended: String,
    pub why: String,
    pub reversible: bool,
    pub blocks: Vec<String>,
}

#[derive(Serialize, Deserialize, Debug)]
#[serde(deny_unknown_fields)]
pub struct Choice {
    pub key: String,
    pub label: String,
    pub consequence: String,
}

/// A decision file. A file written by another `po` may lack a field or carry a new one; neither
/// drops it (ADR-0117), so every field but `id` and `status` reads as `null` when absent, and
/// options and motive stay as written.
#[derive(Serialize, Deserialize, Debug)]
pub struct Decision {
    pub id: String,
    pub asked: Option<String>,
    pub motive: Option<Value>,
    pub sensitive: Option<bool>,
    pub question: Option<String>,
    pub context: Option<String>,
    pub options: Option<Vec<Value>>,
    pub recommended: Option<String>,
    pub why: Option<String>,
    pub reversible: Option<bool>,
    pub blocks: Option<Vec<String>>,
    pub status: String,
    pub answer: Option<Value>,
    /// What the answer produced, once the lead consumed it; absent until then, so an unconsumed
    /// decision keeps the contract's shape.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub consumed: Option<Value>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

/// The number of an id `d-<digits>`; anything else is no id `po` hands out.
pub fn id_number(id: &str) -> Option<u64> {
    let digits = id.strip_prefix("d-")?;
    if digits.is_empty() || !digits.bytes().all(|b| b.is_ascii_digit()) {
        return None;
    }
    digits.parse().ok()
}

/// The decisions of `dir` in id order, and the `*.json` files that do not parse. A missing folder
/// holds none.
pub fn read_dir(dir: &Path) -> io::Result<(Vec<Decision>, Vec<PathBuf>)> {
    let entries = match std::fs::read_dir(dir) {
        Ok(entries) => entries,
        Err(err) if err.kind() == io::ErrorKind::NotFound => return Ok((Vec::new(), Vec::new())),
        Err(err) => return Err(err),
    };
    let mut files: Vec<PathBuf> = entries
        .filter_map(|entry| entry.ok().map(|entry| entry.path()))
        .filter(|path| path.extension().is_some_and(|ext| ext == "json") && path.is_file())
        .collect();
    files.sort();
    let mut decisions = Vec::new();
    let mut unreadable = Vec::new();
    for path in files {
        match read_file(&path) {
            Some(decision) => decisions.push(decision),
            None => unreadable.push(path),
        }
    }
    // Numeric order, so d-10000 comes after d-9999; ids po never hands out go last.
    decisions.sort_by(|a, b| {
        let (na, nb) = (id_number(&a.id), id_number(&b.id));
        (na.is_none(), na, &a.id).cmp(&(nb.is_none(), nb, &b.id))
    });
    Ok((decisions, unreadable))
}

pub fn read_file(path: &Path) -> Option<Decision> {
    let text = std::fs::read_to_string(path).ok()?;
    serde_json::from_str(&text).ok()
}
