//! The report's text: header from the template, the answer stripped of its own header, the stamp.

use std::path::{Component, Path, PathBuf};

/// The template's first two non-empty lines, `<id>` replaced; a link whose target is not there
/// beside the report goes, and a line left with nothing goes with it.
pub fn header(template: &str, id: &str, folder: &Path) -> Vec<String> {
    template
        .lines()
        .filter(|line| !line.trim().is_empty())
        .take(2)
        .map(|line| keep_existing_links(&line.replace("<id>", id), folder))
        .filter(|line| !line.is_empty())
        .collect()
}

fn keep_existing_links(line: &str, folder: &Path) -> String {
    line.split(" · ")
        .filter(|part| match link_target(part) {
            Some(target) => {
                let file = target.split('#').next().unwrap_or(target);
                file.is_empty() || resolve(folder, file).exists()
            }
            None => true,
        })
        .collect::<Vec<_>>()
        .join(" · ")
}

/// `..` taken lexically: on a first record the report's folder does not exist yet, and the
/// system cannot walk `..` out of a missing folder.
fn resolve(folder: &Path, target: &str) -> PathBuf {
    let mut path = folder.to_path_buf();
    for part in Path::new(target).components() {
        match part {
            Component::ParentDir => {
                path.pop();
            }
            Component::CurDir => {}
            other => path.push(other),
        }
    }
    path
}

fn link_target(part: &str) -> Option<&str> {
    let part = part.trim();
    if !part.starts_with('[') || !part.ends_with(')') {
        return None;
    }
    let open = part.find("](")?;
    Some(&part[open + 2..part.len() - 1])
}

/// The answer from its first line that is not part of a header: blank lines, a `# Review` or `# QA`
/// title, a `[Story](` link line and a `Method version:` line are what `po` writes itself.
pub fn strip_own_header(answer: &str) -> &str {
    let mut start = 0;
    for line in answer.split_inclusive('\n') {
        let text = line.trim_end_matches(['\n', '\r']);
        let header = text.trim().is_empty()
            || text.starts_with("# Review")
            || text.starts_with("# QA")
            || text.starts_with("[Story](")
            || text.starts_with("Method version:");
        if !header {
            break;
        }
        start += line.len();
    }
    &answer[start..]
}

/// `lines` right after the first `## Tests` line; with none, a `## Tests` section holding them
/// before `## Findings`, else before `Max severity:`, else at the end.
pub fn insert_oracle(body: &str, lines: &[String]) -> String {
    let block: String = lines.iter().map(|line| format!("{line}\n")).collect();
    let section = format!("## Tests\n{block}\n");
    let mut offset = 0;
    let mut findings = None;
    let mut severity = None;
    for line in body.split_inclusive('\n') {
        let text = line.trim_end_matches(['\n', '\r']);
        if text.trim_end() == "## Tests" {
            let after = offset + line.len();
            let sep = if line.ends_with('\n') { "" } else { "\n" };
            return format!("{}{sep}{block}{}", &body[..after], &body[after..]);
        }
        if findings.is_none() && text.trim_end() == "## Findings" {
            findings = Some(offset);
        }
        if severity.is_none() && text.starts_with("Max severity:") {
            severity = Some(offset);
        }
        offset += line.len();
    }
    match findings.or(severity) {
        Some(at) => format!("{}{section}{}", &body[..at], &body[at..]),
        None => {
            let sep = if body.is_empty() || body.ends_with('\n') { "" } else { "\n" };
            format!("{body}{sep}\n{section}")
        }
    }
}

pub fn first_write(header: &[String], version: &str, body: &str) -> String {
    let mut text = String::new();
    for line in header {
        text.push_str(line);
        text.push_str("\n\n");
    }
    text.push_str(&format!("Method version: {version}\n\n"));
    text.push_str(body);
    text
}

pub fn append(existing: &str, version: &str, body: &str) -> String {
    let sep = if existing.ends_with('\n') { "" } else { "\n" };
    format!("{existing}{sep}\nMethod version: {version}\n\n{body}")
}
