//! `po run` and `po continue`: the project lead's session, launched through Claude Code with the
//! one command `po state` announces, and whether the subagents' bounds hold in it.

mod bounds;
mod session;

use std::fs::{self, OpenOptions};
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::thread;
use std::time::Duration;

use serde::Serialize;

use crate::context::Context;
use crate::project::Project;
use crate::{next, output};
use session::Record;

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

#[derive(Serialize)]
struct Started {
    session: String,
    started: String,
    command: String,
}

const LOCK_TRIES: u32 = 50;
const LOCK_PAUSE: Duration = Duration::from_millis(20);
const LOCK_STALE_AFTER: Duration = Duration::from_secs(600);

/// Removes the launch lock on every way out that runs destructors; `take_over` handles the others.
struct Lock(PathBuf);

impl Drop for Lock {
    fn drop(&mut self) {
        let _ = fs::remove_file(&self.0);
    }
}

pub fn main(args: &[String]) -> i32 {
    launch("run", args, false)
}

pub fn resume(args: &[String]) -> i32 {
    launch("continue", args, true)
}

pub fn session(context: &Context) -> Option<Session> {
    match session::current(&context.project).ok()? {
        None => Some(Session { running: false, id: None }),
        Some((record, running)) => Some(Session { running, id: Some(record.short_id()) }),
    }
}

pub fn bounds(context: &Context) -> Option<Bounds> {
    Some(bounds::bounds(&context.project))
}

fn launch(verb: &str, args: &[String], resume: bool) -> i32 {
    // The launched session's instruction is never anything the caller typed.
    if let Some(arg) = args.first() {
        return output::error(
            output::UNREADABLE,
            "unknown-option",
            format!("po {verb} takes no argument, and {arg:?} is none it knows"),
        );
    }
    let Some(project) = std::env::current_dir().ok().and_then(|cwd| Project::find(&cwd)) else {
        return output::error(
            output::UNREADABLE,
            "not-a-project",
            "not inside a Polype project: no AGENTS.local.md nor .polype/version at the repository root",
        );
    };
    let context = Context::read(project);
    let Some(dir) = session::machine_dir(&context.project) else {
        return output::error(output::UNREADABLE, "session-unreadable", "the git common dir cannot be read");
    };
    let lock_path = dir.join("run.lock");
    let _lock = match take(&dir, &lock_path) {
        Ok(lock) => lock,
        Err(Some(err)) => {
            return output::error(
                output::UNREADABLE,
                "session-unreadable",
                format!("cannot write into {}: {err}", dir.display()),
            )
        }
        Err(None) => {
            return output::error(
                output::REFUSED,
                "already-running",
                format!("another po is launching the lead ({} is held)", lock_path.display()),
            )
        }
    };

    let recorded = match session::current(&context.project) {
        Ok(recorded) => recorded,
        Err(message) => return output::error(output::UNREADABLE, "session-unreadable", message),
    };
    if let Some((record, true)) = &recorded {
        return output::error(
            output::REFUSED,
            "already-running",
            format!("the lead session {} is running", record.short_id()),
        );
    }
    if bounds::bounds(&context.project) == Bounds::Unproven {
        return output::error(
            output::REFUSED,
            "bounds-unproven",
            "implementer, qa and reviewer must be Polype's subagents with their po-bounds hook under the Claude Code configuration's agents/, none of them in the repository's .claude/agents/, and the project must hold an executable .polype/hooks/po-bounds.sh",
        );
    }
    let command = match command(&context) {
        Ok(command) => command,
        Err((code, error, message)) => return output::error(code, error, message),
    };

    let (uuid, flag) = match recorded.filter(|_| resume) {
        Some((record, _)) => (record.session, "--resume"),
        None => match session::new_uuid() {
            Ok(uuid) => (uuid, "--session-id"),
            Err(err) => {
                return output::error(output::UNREADABLE, "launch-failed", format!("no session id could be drawn: {err}"))
            }
        },
    };
    if let Err(message) = start(&context.project.root, flag, &uuid, &command) {
        return output::error(output::UNREADABLE, "launch-failed", message);
    }
    let record = Record { session: uuid, started: now(), command };
    if let Err(err) = session::write_record(&dir, &record) {
        return output::error(
            output::UNREADABLE,
            "session-unreadable",
            format!("the lead session {} was launched but cannot be recorded in {}: {err}", record.short_id(), dir.display()),
        );
    }
    output::reply(
        Started { session: record.short_id(), started: record.started, command: record.command },
        output::OK,
    )
}

/// The missing framing stage, else `/po-drive` when there is work; the refusal otherwise.
fn command(context: &Context) -> Result<String, (i32, &'static str, String)> {
    let unreadable = |what: &str| (output::UNREADABLE, "state-unreadable", format!("{what} cannot be read"));
    let framing = context.framing.as_ref().ok_or_else(|| unreadable("the framing"))?;
    if framing.stage != "done" {
        return framing.next.clone().ok_or_else(|| unreadable("the next framing stage"));
    }
    let lanes = context.lanes.as_ref();
    let ready = next::ready(context);
    let answered = context.inbox.as_ref().map(|inbox| {
        inbox.decisions.iter().any(|d| d.status == "answered" && d.consumed.is_none())
    });
    let work = lanes.is_some_and(|lanes| !lanes.is_empty())
        || ready.as_ref().is_some_and(|ready| !ready.is_empty())
        || answered == Some(true);
    if work {
        return Ok("/po-drive".to_string());
    }
    if lanes.is_none() {
        return Err(unreadable("the lanes"));
    }
    if ready.is_none() {
        return Err(unreadable("the ready stories"));
    }
    if answered.is_none() {
        return Err(unreadable("the decision inbox"));
    }
    Err((
        output::REFUSED,
        "nothing-to-do",
        "framing is done, no story is ready, no lane is on disk and no answered decision waits".to_string(),
    ))
}

/// Launches Claude Code in the background at the project root. Its output is never read: a
/// background child holding an inherited pipe would keep `po` waiting.
fn start(root: &Path, flag: &str, uuid: &str, command: &str) -> Result<(), String> {
    let program = session::claude_program();
    let shown = program.to_string_lossy().into_owned();
    let status = Command::new(&program)
        .args(["--bg", flag, uuid, command])
        .current_dir(root)
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .map_err(|err| format!("{shown} cannot be launched: {err}"))?;
    if !status.success() {
        return Err(format!("{shown} --bg exited with {status}"));
    }
    Ok(())
}

fn take(dir: &Path, path: &Path) -> Result<Lock, Option<io::Error>> {
    fs::create_dir_all(dir).map_err(Some)?;
    for attempt in 0..LOCK_TRIES {
        match OpenOptions::new().write(true).create_new(true).open(path) {
            Ok(mut file) => {
                let lock = Lock(path.to_path_buf());
                writeln!(file, "{}", std::process::id()).map_err(Some)?;
                return Ok(lock);
            }
            Err(err) if err.kind() == io::ErrorKind::AlreadyExists => {
                if take_over(dir, path) {
                    continue;
                }
                if attempt + 1 < LOCK_TRIES {
                    thread::sleep(LOCK_PAUSE);
                }
            }
            Err(err) => return Err(Some(err)),
        }
    }
    Err(None)
}

/// A lock is stale when the `po` whose pid it holds is gone, which a panic or a kill leaves behind,
/// or when it is older than any launch takes, which covers a pid reused since. It is moved aside
/// before it is removed, so two `po` judging it stale at once never remove each other's fresh lock.
fn take_over(dir: &Path, path: &Path) -> bool {
    let Ok(held) = fs::read_to_string(path) else { return false };
    if !stale(path, &held) {
        return false;
    }
    let aside = dir.join(format!("run.lock.{}.stale", std::process::id()));
    if fs::rename(path, &aside).is_err() {
        return false;
    }
    if fs::read_to_string(&aside).is_ok_and(|moved| moved == held) {
        let _ = fs::remove_file(&aside);
        return true;
    }
    // Another po replaced the stale lock between the read and the move: give its lock back.
    let _ = fs::hard_link(&aside, path);
    let _ = fs::remove_file(&aside);
    false
}

fn stale(path: &Path, held: &str) -> bool {
    let old = fs::metadata(path)
        .and_then(|meta| meta.modified())
        .ok()
        .and_then(|modified| modified.elapsed().ok())
        .is_some_and(|age| age > LOCK_STALE_AFTER);
    let gone = held.trim().parse::<u32>().is_ok_and(|pid| {
        // `kill -0` probes without signalling; a probe that cannot run proves nothing.
        Command::new("kill")
            .args(["-0", &pid.to_string()])
            .stdin(Stdio::null())
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .is_ok_and(|status| !status.success())
    });
    old || gone
}

fn now() -> String {
    chrono::Local::now().to_rfc3339_opts(chrono::SecondsFormat::Secs, false)
}
