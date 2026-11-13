//! The one way a decision file changes after `po inbox add`: under a lock of its own, read, checked,
//! then replaced whole.

use std::fs::{self, OpenOptions};
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::thread;
use std::time::Duration;

use super::decision::{self, id_number, Decision};
use crate::output;
use crate::project::Project;

const LOCK_TRIES: u32 = 50;
const LOCK_PAUSE: Duration = Duration::from_millis(20);

/// A refusal of the change: its code and message, printed with exit 1; nothing is written.
pub type Refusal = (&'static str, String);

/// Removes the lock on every way out of `rewrite`.
struct Lock(PathBuf);

impl Drop for Lock {
    fn drop(&mut self) {
        let _ = fs::remove_file(&self.0);
    }
}

pub fn now() -> String {
    chrono::Local::now().to_rfc3339_opts(chrono::SecondsFormat::Secs, false)
}

pub fn rewrite(
    project: &Project,
    dir: &Path,
    id: &str,
    change: impl FnOnce(&mut Decision) -> Result<(), Refusal>,
) -> i32 {
    // The id becomes a path: only `d-<digits>` may reach the filesystem.
    if id_number(id).is_none() {
        return super::unknown(id);
    }
    let path = dir.join(format!("{id}.json"));
    if !path.is_file() {
        return super::unknown(id);
    }
    if !super::add::kept_out_of_git(project, dir) {
        return output::error(
            output::REFUSED,
            "inbox-not-ignored",
            format!("{} lies in the repository and git does not ignore it", dir.display()),
        );
    }
    // A lock beside the file, not on it: the rename below puts a new inode in place, so a waiter
    // locking the decision itself would then read the old one.
    let lock_path = dir.join(format!(".{id}.lock"));
    let _lock = match take(&lock_path) {
        Ok(lock) => lock,
        Err(Some(err)) => return unwritable(dir, err),
        Err(None) => {
            return output::error(
                output::UNREADABLE,
                "inbox-busy",
                format!("{} is held by another po; remove it if no po is running", lock_path.display()),
            )
        }
    };
    let Some(mut decision) = decision::read_file(&path) else {
        return output::error(
            output::UNREADABLE,
            "unreadable-decision",
            format!("{} does not parse as a decision", path.display()),
        );
    };
    if let Err((code, message)) = change(&mut decision) {
        return output::error(output::REFUSED, code, message);
    }
    let temp = dir.join(format!(".{id}.json.{}.tmp", std::process::id()));
    let written = serde_json::to_string_pretty(&decision)
        .map_err(io::Error::from)
        .and_then(|text| {
            let mut file = OpenOptions::new().write(true).create(true).truncate(true).open(&temp)?;
            file.write_all((text + "\n").as_bytes())?;
            file.sync_all()
        })
        .and_then(|()| fs::rename(&temp, &path));
    if let Err(err) = written {
        let _ = fs::remove_file(&temp);
        return unwritable(dir, err);
    }
    output::reply(decision, output::OK)
}

/// The lock, `Err(None)` when another `po` still holds it after every try.
fn take(path: &Path) -> Result<Lock, Option<io::Error>> {
    for attempt in 0..LOCK_TRIES {
        match OpenOptions::new().write(true).create_new(true).open(path) {
            Ok(_) => return Ok(Lock(path.to_path_buf())),
            Err(err) if err.kind() == io::ErrorKind::AlreadyExists => {
                if attempt + 1 < LOCK_TRIES {
                    thread::sleep(LOCK_PAUSE);
                }
            }
            Err(err) => return Err(Some(err)),
        }
    }
    Err(None)
}

fn unwritable(dir: &Path, err: io::Error) -> i32 {
    output::error(
        output::UNREADABLE,
        "inbox-unwritable",
        format!("cannot write into {}: {err}", dir.display()),
    )
}
