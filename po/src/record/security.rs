//! Security findings of a reviewer's answer (ADR-0123): the items of `## Findings` marked
//! `- <severity> — [security] — <path>:<line> — <the problem>` leave the public body whole, with
//! their indented lines. Any other `[security]` makes the answer malformed, named by line number
//! only, so a refusal never repeats the text it protects. The text goes to a new owner-only file
//! under `Private folder`, named by a sensitive decision; `po` never deletes it.

use std::io::Write;
use std::os::unix::fs::{DirBuilderExt, OpenOptionsExt};
use std::path::{Path, PathBuf};

use crate::inbox::{self, Choice, Motive, NewDecision, Place};
use crate::output;
use crate::project::{Project, Setting};

const MARK: &str = "[security]";
const SEVERITIES: [&str; 3] = ["minor", "major", "critical"];

pub struct Split {
    /// The public body up to and including the `## Findings` line; the count line goes after it.
    pub head: String,
    pub tail: String,
    pub private: String,
    pub count: usize,
    /// Index into `SEVERITIES`: 0 minor, 1 major, 2 critical.
    highest: usize,
}

impl Split {
    pub fn holds_critical_or_major(&self) -> bool {
        self.count > 0 && self.highest >= 1
    }

    pub fn public(&self, count_line: &str) -> String {
        format!("{}{count_line}\n{}", self.head, self.tail)
    }
}

/// `offset` is the number of lines dropped from the top of the answer before `body`, so line
/// numbers match the answer as given on stdin.
pub fn split(body: &str, offset: usize) -> Result<Split, Vec<String>> {
    let lines: Vec<&str> = body.split_inclusive('\n').collect();
    let text = |n: usize| lines[n].trim_end_matches(['\n', '\r']);
    let start = (0..lines.len()).find(|&n| text(n).trim_end() == "## Findings");
    let end = start.map(|s| {
        (s + 1..lines.len()).find(|&n| closes_section(text(n))).unwrap_or(lines.len())
    });

    let mut private_lines = vec![false; lines.len()];
    let mut count = 0;
    let mut highest = 0;
    if let (Some(s), Some(e)) = (start, end) {
        let mut n = s + 1;
        while n < e {
            let Some(severity) = marked_item(text(n)) else {
                n += 1;
                continue;
            };
            count += 1;
            highest = highest.max(severity);
            private_lines[n] = true;
            let mut last = n;
            let mut k = n + 1;
            while k < e {
                let line = text(k);
                if line.trim().is_empty() {
                    k += 1;
                    continue;
                }
                if !line.starts_with([' ', '\t']) {
                    break;
                }
                last = k;
                k += 1;
            }
            for flag in &mut private_lines[n..=last] {
                *flag = true;
            }
            n = last + 1;
        }
    }

    let refused: Vec<String> = (0..lines.len())
        .filter(|&n| !private_lines[n] && text(n).to_lowercase().contains(MARK))
        .map(|n| {
            format!(
                "answer line {}: a [security] mark outside the shape `- <severity> — [security] — <path>:<line> — <the problem>` under ## Findings",
                n + 1 + offset
            )
        })
        .collect();
    if !refused.is_empty() {
        return Err(refused);
    }

    let mut head = String::new();
    let mut tail = String::new();
    let mut private = String::new();
    let cut = start.map_or(lines.len(), |s| s + 1);
    for (n, line) in lines.iter().enumerate() {
        if private_lines[n] {
            private.push_str(line);
            if !line.ends_with('\n') {
                private.push('\n');
            }
        } else if n < cut {
            head.push_str(line);
        } else {
            tail.push_str(line);
        }
    }
    if !head.is_empty() && !head.ends_with('\n') {
        head.push('\n');
    }
    Ok(Split { head, tail, private, count, highest })
}

fn closes_section(line: &str) -> bool {
    let bare = line.strip_prefix("- ").or_else(|| line.strip_prefix("* ")).unwrap_or(line);
    line.starts_with("## ") || bare.starts_with("Max severity:") || bare.starts_with("Ship allowed:")
}

/// The severity index of a well-marked item, or `None` for any other line.
fn marked_item(line: &str) -> Option<usize> {
    let rest = line.strip_prefix("- ").or_else(|| line.strip_prefix("* ")).or_else(|| {
        let digits = line.bytes().take_while(u8::is_ascii_digit).count();
        (digits > 0).then(|| line[digits..].strip_prefix(". ")).flatten()
    })?;
    let mut parts = rest.splitn(4, " — ");
    let first = parts.next()?;
    let severity = SEVERITIES.iter().position(|s| *s == first)?;
    if parts.next() != Some(MARK) {
        return None;
    }
    let (path, at) = parts.next()?.rsplit_once(':')?;
    let problem = parts.next()?;
    let filled = |s: &str| !s.is_empty() && s.trim_start() == s;
    (filled(path.trim_end()) && filled(at) && filled(problem.trim_end())).then_some(severity)
}

type Refusal = (i32, &'static str, String);

/// Where the text and its decision would go, found before anything is written.
pub struct Keeper {
    project: Project,
    inbox_dir: PathBuf,
    folder: PathBuf,
}

pub fn prepare() -> Result<Keeper, Refusal> {
    let (project, inbox_dir) = inbox::find().map_err(|r| (r.code, r.error, r.message))?;
    let folder = private_folder(&project)?.join(project.name());
    Ok(Keeper { project, inbox_dir, folder })
}

/// Writes the private text and posts its decision; the decision id, or a refusal after which
/// nothing of the text is left on disk.
pub fn keep(keeper: &Keeper, id: &str, split: &Split) -> Result<String, Refusal> {
    let Keeper { project, inbox_dir, folder } = keeper;
    let file = write_private(folder, id, &split.private).map_err(|err| {
        (output::REFUSED, "private-folder-unusable", format!("Private folder: cannot write under {}: {err}", folder.display()))
    })?;
    let plural = if split.count == 1 { "" } else { "s" };
    let choice = |key: &str, label: &str, consequence: &str| Choice {
        key: key.into(),
        label: label.into(),
        consequence: consequence.into(),
    };
    let new = NewDecision {
        motive: Motive::Security,
        sensitive: true,
        question: format!("{id}: {} security finding{plural} from its review wait for you", split.count),
        context: Some(file.to_string_lossy().into_owned()),
        options: vec![
            choice("fix-here", "Fix them in this story", "the fix run reads the text from the context file"),
            choice("hold", "Hold the story", "the story waits while you handle the weakness yourself"),
            choice(
                "ship-later",
                "Ship if the review allows, handle them later",
                "a critical finding blocks the ship whatever is chosen",
            ),
        ],
        recommended: "fix-here".into(),
        why: "A weakness is best fixed before the story that found it is published.".into(),
        reversible: true,
        blocks: if split.holds_critical_or_major() { vec![id.to_string()] } else { Vec::new() },
    };
    match inbox::post_decision(project, inbox_dir, new) {
        Ok(decision) => Ok(decision.id),
        Err(refused) => {
            let _ = std::fs::remove_file(&file);
            Err((refused.code, refused.error, refused.message))
        }
    }
}

/// `Private folder` as ADR-0123 reads it: absolute, or `~/` expanded from HOME; outside the
/// repository by the rule a sensitive decision's context follows.
fn private_folder(project: &Project) -> Result<PathBuf, Refusal> {
    let value = match project.setting("Private folder") {
        Setting::Value(value) if value != "—" => value,
        _ => {
            return Err((
                output::UNREADABLE,
                "no-private-folder-setting",
                "AGENTS.local.md sets no Private folder, where po keeps the text of security findings off the repository; nothing was written".into(),
            ))
        }
    };
    let unusable = |why: &str| {
        (output::REFUSED, "private-folder-unusable", format!("Private folder {value:?} {why}; nothing was written"))
    };
    let path = match value.strip_prefix("~/") {
        Some(rest) => match std::env::var_os("HOME") {
            Some(home) if Path::new(&home).is_absolute() => Path::new(&home).join(rest),
            _ => return Err(unusable("starts with ~/ but HOME is not an absolute path")),
        },
        None => PathBuf::from(&value),
    };
    if !path.is_absolute() {
        return Err(unusable("is not an absolute path nor one starting with ~/"));
    }
    if inbox::place(project, &path) != Place::Outside {
        return Err(unusable("lies inside the repository"));
    }
    Ok(path)
}

fn write_private(folder: &Path, id: &str, text: &str) -> std::io::Result<PathBuf> {
    // Only the folders created here get 0700; one that exists keeps its mode.
    std::fs::DirBuilder::new().recursive(true).mode(0o700).create(folder)?;
    let stamp = chrono::Utc::now().format("%Y%m%dT%H%M%SZ");
    let file = folder.join(format!("{id}-{stamp}-{}.md", std::process::id()));
    let mut out = std::fs::OpenOptions::new().write(true).create_new(true).mode(0o600).open(&file)?;
    let written = out.write_all(format!("# Security findings — {id}\n\n{text}").as_bytes());
    if let Err(err) = written {
        let _ = std::fs::remove_file(&file);
        return Err(err);
    }
    Ok(file)
}
