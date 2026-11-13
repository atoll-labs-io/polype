//! `po record review|qa <id>`: the subagent's answer comes on stdin and `po` writes the report
//! itself, in the story worktree it runs from — the template's header, the method version, the
//! answer as given, and the checks the report owes (ADR-0102, ADR-0104).

mod compose;
mod gate;

use std::io::Read;
use std::path::{Path, PathBuf};

use serde::Serialize;

use crate::output;
use crate::project::{self, Project};
use gate::Gate;

#[derive(Clone, Copy, PartialEq)]
enum Kind {
    Review,
    Qa,
}

impl Kind {
    fn name(self) -> &'static str {
        match self {
            Kind::Review => "review",
            Kind::Qa => "qa",
        }
    }

    fn report(self, id: &str) -> String {
        match self {
            Kind::Review => format!("docs/reviews/{id}.md"),
            Kind::Qa => format!("docs/qa/{id}/report.md"),
        }
    }
}

struct Request {
    kind: Kind,
    id: String,
    composed: bool,
}

#[derive(Serialize)]
struct Written {
    path: String,
    method_version: String,
}

#[derive(Serialize)]
struct Refusal {
    error: String,
    message: String,
    written: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    refused: Option<Vec<String>>,
}

fn refuse(code: i32, error: &str, message: impl Into<String>, written: bool) -> i32 {
    output::reply(
        Refusal { error: error.to_string(), message: message.into(), written, refused: None },
        code,
    )
}

const USAGE: &str = "usage: po record review <id> [--composed] | po record qa <id>, the answer on stdin";

fn parse(args: &[String]) -> Result<Request, i32> {
    let kind = match args.first().map(String::as_str) {
        Some("review") => Kind::Review,
        Some("qa") => Kind::Qa,
        _ => return Err(refuse(output::UNREADABLE, "usage", USAGE, false)),
    };
    let mut id = None;
    let mut composed = false;
    for arg in &args[1..] {
        if arg == "--composed" && kind == Kind::Review {
            composed = true;
        } else if arg.starts_with('-') {
            return Err(refuse(
                output::UNREADABLE,
                "unknown-option",
                format!("po record {} takes no option {arg}; {USAGE}", kind.name()),
                false,
            ));
        } else if id.is_none() && !arg.contains('/') && !arg.starts_with('.') && !arg.is_empty() {
            id = Some(arg.clone());
        } else {
            return Err(refuse(output::UNREADABLE, "usage", format!("unexpected argument {arg}; {USAGE}"), false));
        }
    }
    let Some(id) = id else {
        return Err(refuse(output::UNREADABLE, "usage", USAGE, false));
    };
    Ok(Request { kind, id, composed })
}

/// The worktree `po` runs in, once it is shown to be `story/<id>` of a Polype project.
fn worktree(id: &str) -> Result<PathBuf, i32> {
    let cwd = std::env::current_dir().ok();
    let found = cwd.as_deref().and_then(Project::find).zip(cwd.as_deref());
    let Some((_, cwd)) = found else {
        return Err(refuse(
            output::UNREADABLE,
            "not-a-project",
            "not inside a Polype project: no AGENTS.local.md nor .polype/version at the repository root",
            false,
        ));
    };
    // Project::root is the main checkout; the report belongs to the worktree the coordinator stands in.
    let top = project::git(cwd, &["rev-parse", "--show-toplevel"]).map(|out| PathBuf::from(out.trim()));
    let Some(top) = top else {
        return Err(refuse(output::UNREADABLE, "not-a-project", "no work tree around the current directory", false));
    };
    let branch = project::git(&top, &["rev-parse", "--abbrev-ref", "HEAD"]).map(|out| out.trim().to_string());
    let want = format!("story/{id}");
    if branch.as_deref() != Some(want.as_str()) {
        return Err(refuse(
            output::UNREADABLE,
            "wrong-branch",
            format!(
                "{} is on {}, not {want}: run po record in the story worktree",
                top.display(),
                branch.as_deref().unwrap_or("no branch")
            ),
            false,
        ));
    }
    Ok(top)
}

fn read_first_line(path: &Path) -> Option<String> {
    let text = std::fs::read_to_string(path).ok()?;
    let line = text.lines().next()?.trim().to_string();
    (!line.is_empty()).then_some(line)
}

pub fn main(args: &[String]) -> i32 {
    let request = match parse(args) {
        Ok(request) => request,
        Err(code) => return code,
    };
    let (kind, id) = (request.kind, request.id.as_str());
    let top = match worktree(id) {
        Ok(top) => top,
        Err(code) => return code,
    };
    let Some(version) = read_first_line(&top.join(".polype/version")) else {
        return refuse(output::UNREADABLE, "no-method-version", ".polype/version is missing or unreadable in the worktree", false);
    };
    let template_path = top.join(format!(".polype/templates/{}.md", kind.name()));
    let Ok(template) = std::fs::read_to_string(&template_path) else {
        return refuse(
            output::UNREADABLE,
            "no-template",
            format!(".polype/templates/{}.md is missing or unreadable in the worktree", kind.name()),
            false,
        );
    };
    let mut bytes = Vec::new();
    if let Err(err) = std::io::stdin().read_to_end(&mut bytes) {
        return refuse(output::UNREADABLE, "unreadable-answer", format!("stdin cannot be read: {err}"), false);
    }
    let Ok(answer) = String::from_utf8(bytes) else {
        return refuse(output::UNREADABLE, "unreadable-answer", "the answer on stdin is not UTF-8 text", false);
    };
    if answer.trim().is_empty() {
        return refuse(output::REFUSED, "empty-answer", "stdin holds no answer", false);
    }
    if kind == Kind::Qa && !answer.lines().any(|line| line.starts_with("QA status:")) {
        return refuse(
            output::REFUSED,
            "no-qa-status",
            "the answer has no line starting QA status: — there is no report to record",
            false,
        );
    }

    let rel = kind.report(id);
    let path = top.join(&rel);
    let mut body = compose::strip_own_header(&answer).to_string();
    if kind == Kind::Review && !request.composed {
        let lines = match gate::run(&top, "oracle-intact", id) {
            Gate::Ran { code, stdout, stderr } => {
                let mut lines = vec![format!("- Oracle: `po-gate oracle-intact {id}` → exit {code}")];
                lines.extend(stdout.lines().chain(stderr.lines()).map(|line| format!("  {line}")));
                lines
            }
            Gate::Missing => vec![format!(
                "- Oracle: `po-gate oracle-intact {id}` → not run: .polype/hooks/po-gate.sh is missing"
            )],
            Gate::Unstartable(err) => {
                vec![format!("- Oracle: `po-gate oracle-intact {id}` → not run: {err}")]
            }
        };
        body = compose::insert_oracle(&body, &lines);
    }

    let existing = match kind {
        Kind::Review => std::fs::read_to_string(&path).ok(),
        Kind::Qa => None,
    };
    let text = match existing {
        Some(existing) => compose::append(&existing, &version, &body),
        None => {
            let folder = path.parent().unwrap_or(&top);
            let header = compose::header(&template, id, folder);
            compose::first_write(&header, &version, &body)
        }
    };
    if let Err(err) = write_atomic(&path, &text) {
        return refuse(output::UNREADABLE, "unwritable", format!("{rel} cannot be written: {err}"), false);
    }

    if kind == Kind::Review && !request.composed {
        match gate::run(&top, "findings-shape", id) {
            Gate::Ran { code: 0, .. } => {}
            Gate::Ran { code: 1, stderr, .. } => {
                return output::reply(
                    Refusal {
                        error: "findings-shape".to_string(),
                        message: format!("{rel} was written, but its findings are not in the shape of templates/review.md"),
                        written: true,
                        refused: Some(stderr.lines().map(str::to_string).collect()),
                    },
                    output::REFUSED,
                );
            }
            Gate::Ran { stderr, .. } => {
                return refuse(output::UNREADABLE, "findings-shape-unrunnable", stderr.trim_end(), true);
            }
            Gate::Missing => {
                return refuse(
                    output::UNREADABLE,
                    "findings-shape-unrunnable",
                    ".polype/hooks/po-gate.sh is missing",
                    true,
                );
            }
            Gate::Unstartable(err) => {
                return refuse(output::UNREADABLE, "findings-shape-unrunnable", err, true);
            }
        }
    }
    output::reply(Written { path: rel, method_version: version }, output::OK)
}

/// A temp file beside the report, then a rename: a report re-recorded from itself is read whole
/// before this runs, and a reader never sees half a file.
fn write_atomic(path: &Path, text: &str) -> std::io::Result<()> {
    let folder = path.parent().ok_or_else(|| std::io::Error::other("no parent folder"))?;
    std::fs::create_dir_all(folder)?;
    let name = path.file_name().map(|name| name.to_string_lossy().into_owned()).unwrap_or_default();
    let temp = folder.join(format!(".{name}.po-record.{}", std::process::id()));
    std::fs::write(&temp, text)?;
    std::fs::rename(&temp, path).inspect_err(|_| {
        let _ = std::fs::remove_file(&temp);
    })
}
