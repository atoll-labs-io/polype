//! `po ship <step>`: the ship's steps (ADR-0130). `forge` reads the forge of `origin` and settles
//! the effective `Ship confirmation`; it writes nothing. `land` builds the landing commit; `push`
//! sends it, opens its pull request and, under an effective `automatic`, merges it. `file` files the
//! open findings of the last review once the landing is proven. `clean` removes the landed lane.

mod clean;
mod file;
mod forge;
mod git;
mod land;
mod push;

use serde::Serialize;

use crate::output;
use crate::project::{Project, Setting};

pub(crate) const USAGE: &str =
    "usage: po ship forge [--target <branch>] | po ship land <id> [--routes yes|no] [--land] | po ship land <id> --sha <sha> \
     | po ship push <id> --sha <sha> --body-file <file> | po ship file <id> [--file] [--hold <line>]... [--fixed <line>]... | po ship clean <id>";

#[derive(Serialize)]
struct ForgeReply {
    forge: Option<&'static str>,
    verdict: &'static str,
    signals: forge::Signals,
    failed: Vec<forge::Failure>,
    line: Option<String>,
    effective: Option<String>,
    rewrite: Option<&'static str>,
}

/// The value without its origin, and whether it follows the forge: `(forge)` or bare.
fn origin(line: &str) -> (&str, bool) {
    let line = line.trim_end();
    if let Some(value) = line.strip_suffix("(chosen)") {
        (value.trim_end(), false)
    } else {
        (line.strip_suffix("(forge)").unwrap_or(line).trim_end(), true)
    }
}

pub(super) fn effective(line: &str, verdict: &str) -> (String, Option<&'static str>) {
    let (value, follows) = origin(line);
    let effective = match verdict {
        "collaborative" => "human",
        "solo" if follows => "automatic",
        _ => value,
    };
    let rewrite = match verdict {
        "collaborative" if follows && value != "human" => Some("human (forge)"),
        "solo" if follows && value == "human" => Some("automatic (forge)"),
        _ => None,
    };
    (effective.to_string(), rewrite)
}

fn parse(args: &[String]) -> Result<Option<String>, i32> {
    if args.first().map(String::as_str) != Some("forge") {
        return Err(output::error(output::UNREADABLE, "usage", USAGE));
    }
    let mut target = None;
    let mut rest = args[1..].iter();
    while let Some(arg) = rest.next() {
        if arg == "--target" {
            match rest.next() {
                Some(value) if target.is_none() && !value.is_empty() && !value.starts_with('-') => {
                    target = Some(value.clone())
                }
                _ => return Err(output::error(output::UNREADABLE, "usage", USAGE)),
            }
        } else if arg.starts_with('-') {
            return Err(output::error(
                output::UNREADABLE,
                "unknown-option",
                format!("po ship forge takes no option {arg}; {USAGE}"),
            ));
        } else {
            return Err(output::error(output::UNREADABLE, "usage", format!("unexpected argument {arg}; {USAGE}")));
        }
    }
    Ok(target)
}

pub fn main(args: &[String]) -> i32 {
    match args.first().map(String::as_str) {
        Some("land") => return land::main(&args[1..]),
        Some("push") => return push::main(&args[1..]),
        Some("file") => return file::main(&args[1..]),
        Some("clean") => return clean::main(&args[1..]),
        _ => {}
    }
    let target = match parse(args) {
        Ok(target) => target,
        Err(code) => return code,
    };
    let Some(project) = std::env::current_dir().ok().as_deref().and_then(Project::find) else {
        return output::error(
            output::UNREADABLE,
            "not-a-project",
            "not inside a Polype project: no AGENTS.local.md nor .polype/version at the repository root",
        );
    };
    let target = match (target, project.setting("Target branch")) {
        (Some(target), _) => target,
        (None, Setting::Value(value)) if value != "—" => value,
        _ => {
            return output::error(
                output::UNREADABLE,
                "missing-setting",
                "no Target branch in AGENTS.local.md; pass --target <branch>",
            )
        }
    };
    let line = match project.setting("Ship confirmation") {
        Setting::Value(value) => Some(value),
        Setting::Missing => None,
    };
    let reading = forge::read(&project, &target);
    let verdict = reading.verdict();
    let (effective, rewrite) = match &line {
        Some(line) => {
            let (effective, rewrite) = effective(line, verdict);
            (Some(effective), rewrite)
        }
        None => (None, None),
    };
    output::reply(
        ForgeReply {
            forge: reading.forge,
            verdict,
            signals: reading.signals,
            failed: reading.failed,
            line,
            effective,
            rewrite,
        },
        output::OK,
    )
}
