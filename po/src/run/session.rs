//! The lead session `po run` recorded, and whether Claude Code still runs it. The record lives
//! under the git common dir, so every worktree sees the same one and git never tracks it.

use std::ffi::OsString;
use std::fs::{self, OpenOptions};
use std::io::{self, Read, Write};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use serde::{Deserialize, Serialize};
use serde_json::Value;

use crate::project::Project;

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct Record {
    pub session: String,
    pub started: String,
    pub command: String,
}

impl Record {
    pub fn short_id(&self) -> String {
        self.session.chars().take(8).collect()
    }
}

/// `<git common dir>/polype/`, where `po run` keeps its machine files.
pub fn machine_dir(project: &Project) -> Option<PathBuf> {
    let common = project.git(&["rev-parse", "--path-format=absolute", "--git-common-dir"])?;
    let common = common.trim();
    (!common.is_empty()).then(|| PathBuf::from(common).join("polype"))
}

pub fn record_path(dir: &Path) -> PathBuf {
    dir.join("lead-session.json")
}

pub fn claude_program() -> OsString {
    match std::env::var_os("PO_CLAUDE") {
        Some(program) if !program.is_empty() => program,
        _ => OsString::from("claude"),
    }
}

/// `Ok(None)` when nothing was ever recorded; `Err` names what could not be read.
pub fn read_record(dir: &Path) -> Result<Option<Record>, String> {
    let path = record_path(dir);
    let text = match fs::read_to_string(&path) {
        Ok(text) => text,
        Err(err) if err.kind() == io::ErrorKind::NotFound => return Ok(None),
        Err(err) => return Err(format!("{} cannot be read: {err}", path.display())),
    };
    serde_json::from_str::<Record>(&text)
        .ok()
        .filter(|record| !record.session.is_empty())
        .map(Some)
        .ok_or_else(|| format!("{} does not parse as a session record", path.display()))
}

/// Whether Claude Code lists the session with a process: an entry carrying its `sessionId` and a
/// `pid`. A stopped session stays listed without one.
pub fn is_running(uuid: &str) -> Result<bool, String> {
    let program = claude_program();
    let shown = program.to_string_lossy().into_owned();
    let output = Command::new(&program)
        .args(["agents", "--json"])
        .stdin(Stdio::null())
        .stderr(Stdio::null())
        .output()
        .map_err(|err| format!("{shown} agents --json cannot be run: {err}"))?;
    if !output.status.success() {
        return Err(format!("{shown} agents --json exited with {}", output.status));
    }
    let listing: Vec<Value> = serde_json::from_slice(&output.stdout)
        .map_err(|_| format!("{shown} agents --json did not print a JSON array"))?;
    Ok(listing.iter().any(|entry| {
        entry.get("sessionId").and_then(Value::as_str) == Some(uuid)
            && entry.get("pid").is_some_and(|pid| !pid.is_null())
    }))
}

/// The record and whether its session runs; Claude Code is asked only when a record exists.
pub fn current(project: &Project) -> Result<Option<(Record, bool)>, String> {
    let dir = machine_dir(project).ok_or("the git common dir cannot be read")?;
    let Some(record) = read_record(&dir)? else { return Ok(None) };
    let running = is_running(&record.session)?;
    Ok(Some((record, running)))
}

/// Replaced whole: a reader never sees half a record.
pub fn write_record(dir: &Path, record: &Record) -> io::Result<()> {
    let path = record_path(dir);
    let temp = dir.join(format!(".lead-session.json.{}.tmp", std::process::id()));
    let written = serde_json::to_string_pretty(record)
        .map_err(io::Error::from)
        .and_then(|text| {
            let mut file = OpenOptions::new().write(true).create(true).truncate(true).open(&temp)?;
            file.write_all((text + "\n").as_bytes())?;
            file.sync_all()
        })
        .and_then(|()| fs::rename(&temp, &path));
    if written.is_err() {
        let _ = fs::remove_file(&temp);
    }
    written
}

/// A version 4 UUID from the system's random source; no crate makes UUIDs here (ADR-0118).
pub fn new_uuid() -> io::Result<String> {
    let mut bytes = [0u8; 16];
    fs::File::open("/dev/urandom")?.read_exact(&mut bytes)?;
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    let hex: String = bytes.iter().map(|b| format!("{b:02x}")).collect();
    Ok(format!("{}-{}-{}-{}-{}", &hex[0..8], &hex[8..12], &hex[12..16], &hex[16..20], &hex[20..32]))
}
