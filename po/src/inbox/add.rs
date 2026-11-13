//! `po inbox add`: one decision from stdin, validated, written under the next id, never into git.

use std::collections::HashSet;
use std::io::{self, Read, Write};
use std::path::{Component, Path, PathBuf};

use chrono::SecondsFormat;
use serde_json::Value;

use super::decision::{id_number, Decision, NewDecision};
use crate::output;
use crate::project::{self, Project};

const QUESTION_MAX: usize = 200;

pub fn main() -> i32 {
    let (project, dir) = match super::locate() {
        Ok(found) => found,
        Err(code) => return code,
    };
    let mut input = String::new();
    if let Err(err) = io::stdin().read_to_string(&mut input) {
        return malformed(format!("stdin is not readable text: {err}"));
    }
    let new: NewDecision = match serde_json::from_str(&input) {
        Ok(new) => new,
        Err(err) => return malformed(err.to_string()),
    };
    if let Err(message) = validate(&new) {
        return malformed(message);
    }
    if new.sensitive {
        let outside = new
            .context
            .as_deref()
            .map(Path::new)
            .is_some_and(|context| context.is_absolute() && place(&project, context) == Place::Outside);
        if !outside {
            return output::error(
                output::REFUSED,
                "sensitive-context-in-repo",
                "a sensitive decision needs a context: an absolute path outside the repository",
            );
        }
    }
    if !kept_out_of_git(&project, &dir) {
        return output::error(
            output::REFUSED,
            "inbox-not-ignored",
            format!(
                "{} lies in the repository and git does not ignore it: add it to .gitignore or set Decision inbox outside",
                dir.display()
            ),
        );
    }
    match write(&dir, new) {
        Ok(decision) => output::reply(decision, output::OK),
        Err(err) => output::error(
            output::UNREADABLE,
            "inbox-unwritable",
            format!("cannot write into {}: {err}", dir.display()),
        ),
    }
}

fn malformed(message: impl Into<String>) -> i32 {
    output::error(output::REFUSED, "malformed-decision", message)
}

fn validate(new: &NewDecision) -> Result<(), String> {
    let question = new.question.trim();
    if question.is_empty() {
        return Err("question is empty".into());
    }
    if new.question.contains(['\n', '\r']) {
        return Err("question spans several lines".into());
    }
    if new.question.chars().count() > QUESTION_MAX {
        return Err(format!("question runs over {QUESTION_MAX} characters"));
    }
    if !(2..=3).contains(&new.options.len()) {
        return Err(format!("options holds {}, not 2 or 3", new.options.len()));
    }
    let mut keys = HashSet::new();
    for choice in &new.options {
        if choice.key.is_empty() {
            return Err("an option has an empty key".into());
        }
        if !keys.insert(choice.key.as_str()) {
            return Err(format!("option key {} is given twice", choice.key));
        }
    }
    if !keys.contains(new.recommended.as_str()) {
        return Err(format!("recommended {} is not an option key", new.recommended));
    }
    if new.why.trim().is_empty() {
        return Err("why is empty".into());
    }
    Ok(())
}

#[derive(PartialEq, Eq, Debug)]
enum Place {
    Outside,
    /// Under the root, with the path relative to it.
    InRoot(PathBuf),
    /// In the repository but not under the root: a worktree placed elsewhere.
    Elsewhere,
}

/// Where `path` lies against the project. A path prefix alone misses a symlink and a worktree
/// placed outside the root, so the nearest existing ancestor is resolved and asked for its git
/// common dir.
fn place(project: &Project, path: &Path) -> Place {
    let absolute = if path.is_absolute() { path.to_path_buf() } else { project.root.join(path) };
    let lexical = normalise(&absolute);
    if let Ok(rel) = lexical.strip_prefix(&project.root) {
        return Place::InRoot(rel.to_path_buf());
    }
    let mut ancestor = lexical.as_path();
    while !ancestor.exists() {
        match ancestor.parent() {
            Some(parent) => ancestor = parent,
            None => return Place::Outside,
        }
    }
    let Ok(resolved) = ancestor.canonicalize() else { return Place::Outside };
    if let Ok(rel) = resolved.strip_prefix(&project.root) {
        let rest = lexical.strip_prefix(ancestor).unwrap_or(Path::new(""));
        return Place::InRoot(rel.join(rest));
    }
    let dir = if resolved.is_dir() { resolved.clone() } else { resolved.parent().unwrap_or(&resolved).to_path_buf() };
    let common = |dir: &Path| {
        project::git(dir, &["rev-parse", "--path-format=absolute", "--git-common-dir"])
            .and_then(|out| PathBuf::from(out.trim()).canonicalize().ok())
    };
    match (common(&dir), common(&project.root)) {
        (Some(theirs), Some(ours)) if theirs == ours => Place::Elsewhere,
        _ => Place::Outside,
    }
}

fn normalise(path: &Path) -> PathBuf {
    let mut out = PathBuf::new();
    for component in path.components() {
        match component {
            Component::CurDir => {}
            Component::ParentDir => {
                out.pop();
            }
            other => out.push(other),
        }
    }
    out
}

/// The folder lies outside the repository, or git ignores what would be written in it; asked from
/// the root, never from a worktree whose own .gitignore could differ.
pub(super) fn kept_out_of_git(project: &Project, dir: &Path) -> bool {
    match place(project, dir) {
        Place::Outside => true,
        Place::Elsewhere => false,
        Place::InRoot(rel) => {
            let probe = rel.join("d-0000.json");
            let probe = probe.to_string_lossy();
            project.git(&["check-ignore", "-q", "--", &probe]).is_some()
        }
    }
}

fn next_id(dir: &Path) -> io::Result<u64> {
    let mut max = 0;
    for entry in std::fs::read_dir(dir)? {
        let name = entry?.file_name();
        let name = name.to_string_lossy();
        if let Some(n) = name.strip_suffix(".json").and_then(id_number) {
            max = max.max(n);
        }
    }
    Ok(max + 1)
}

/// The file appears whole under a name no other writer holds: written aside, then hard-linked,
/// which fails rather than overwrite when a parallel `po inbox add` took the id first.
fn write(dir: &Path, new: NewDecision) -> io::Result<Decision> {
    std::fs::create_dir_all(dir)?;
    let mut decision = Decision {
        id: String::new(),
        asked: Some(chrono::Local::now().to_rfc3339_opts(SecondsFormat::Secs, false)),
        motive: Some(serde_json::to_value(new.motive)?),
        sensitive: Some(new.sensitive),
        question: Some(new.question),
        context: new.context,
        options: Some(new.options.iter().map(serde_json::to_value).collect::<Result<Vec<Value>, _>>()?),
        recommended: Some(new.recommended),
        why: Some(new.why),
        reversible: Some(new.reversible),
        blocks: Some(new.blocks),
        status: "pending".to_string(),
        answer: None,
        consumed: None,
        extra: serde_json::Map::new(),
    };
    let mut number = next_id(dir)?;
    loop {
        decision.id = format!("d-{number:04}");
        let text = serde_json::to_string_pretty(&decision)? + "\n";
        let temp = dir.join(format!(".{}.json.{}.tmp", decision.id, std::process::id()));
        let written = std::fs::OpenOptions::new()
            .write(true)
            .create_new(true)
            .open(&temp)
            .and_then(|mut file| file.write_all(text.as_bytes()));
        let linked = written.and_then(|()| std::fs::hard_link(&temp, dir.join(format!("{}.json", decision.id))));
        let _ = std::fs::remove_file(&temp);
        match linked {
            Ok(()) => return Ok(decision),
            Err(err) if err.kind() == io::ErrorKind::AlreadyExists => number += 1,
            Err(err) => return Err(err),
        }
    }
}
