//! The files the shipped stories landed with, read in one `git cat-file --batch`: one process
//! however many stories `--all` covers.

use std::collections::HashMap;
use std::io::{Read, Write};
use std::process::{Command, Stdio};

use crate::project::Project;

/// Each `<commit>:<path>` of `specs` that names a UTF-8 blob, with its text. A spec that is missing,
/// or a git that cannot start, is simply absent from the map.
pub fn read_blobs(project: &Project, specs: &[String]) -> HashMap<String, String> {
    let mut blobs = HashMap::new();
    if specs.is_empty() {
        return blobs;
    }
    let Ok(mut child) = Command::new("git")
        .args(["cat-file", "--batch"])
        .current_dir(&project.root)
        .env("GIT_OPTIONAL_LOCKS", "0")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
    else {
        return blobs;
    };
    let input: String = specs.iter().map(|spec| format!("{spec}\n")).collect();
    let Some(mut stdin) = child.stdin.take() else { return blobs };
    // Written from another thread: git answers while it reads, and a full stdout pipe would block it.
    let writer = std::thread::spawn(move || stdin.write_all(input.as_bytes()));
    let mut out = Vec::new();
    let read = child.stdout.take().map(|mut stdout| stdout.read_to_end(&mut out));
    let _ = writer.join();
    let _ = child.wait();
    if !matches!(read, Some(Ok(_))) {
        return blobs;
    }

    let mut at = 0;
    for spec in specs {
        let Some(end) = out[at..].iter().position(|b| *b == b'\n').map(|n| at + n) else { break };
        let header = String::from_utf8_lossy(&out[at..end]).into_owned();
        at = end + 1;
        let fields: Vec<&str> = header.split(' ').collect();
        let [_, kind, size] = fields[..] else { continue };
        let Ok(size) = size.parse::<usize>() else { break };
        if at + size > out.len() {
            break;
        }
        if kind == "blob" {
            if let Ok(text) = std::str::from_utf8(&out[at..at + size]) {
                blobs.insert(spec.clone(), text.to_string());
            }
        }
        at += size + 1;
    }
    blobs
}
