//! The trust signals a review, a plan and a verification record carry, read from their text. What
//! a file does not say plainly is `None`, never a default.

use chrono::DateTime;

#[derive(Default)]
pub struct Review {
    pub method_version: Option<String>,
    pub fix_loops: Option<u32>,
    pub max_severity: Option<String>,
    pub not_verified: Option<u32>,
    pub oracle: Option<String>,
}

/// The last value of a `<prefix>` line among `lines`, trimmed.
fn last_value<'a>(lines: &[&'a str], prefix: &str) -> Option<&'a str> {
    lines.iter().rev().find_map(|line| line.strip_prefix(prefix)).map(str::trim)
}

/// Read in the last block `po record` stamped with `Method version:`, or in the whole file of a
/// review written before it did.
pub fn review(text: Option<&str>) -> Review {
    let Some(text) = text else { return Review::default() };
    let lines: Vec<&str> = text.lines().collect();
    let stamp = lines.iter().rposition(|line| line.starts_with("Method version:"));
    let block = &lines[stamp.map_or(0, |at| at + 1)..];
    Review {
        method_version: stamp
            .and_then(|at| lines[at].strip_prefix("Method version:"))
            .map(str::trim)
            .filter(|value| !value.is_empty())
            .map(str::to_string),
        fix_loops: last_value(block, "Fix loop:").and_then(|value| value.parse().ok()),
        max_severity: last_value(block, "Max severity:")
            .and_then(|value| value.split_whitespace().next())
            .filter(|word| ["none", "minor", "major", "critical"].contains(word))
            .map(str::to_string),
        not_verified: not_verified(block),
        oracle: stamp.and_then(|_| oracle(block)),
    }
}

fn not_verified(block: &[&str]) -> Option<u32> {
    let start = block.iter().rposition(|line| line.trim_end() == "## Not verified")? + 1;
    let body: Vec<&str> = block[start..]
        .iter()
        .take_while(|line| {
            !line.starts_with("## ") && !line.starts_with("Max severity:") && !line.starts_with("Ship allowed:")
        })
        .copied()
        .collect();
    let items = body.iter().filter(|line| line.starts_with("- ")).count() as u32;
    if items > 0 {
        return Some(items);
    }
    let rest = body.join("\n");
    matches!(rest.trim(), "" | "none" | "—").then_some(0)
}

/// The first oracle line of the block is the one `po record` wrote right after `## Tests`; a later
/// one may be an echo from the reviewer's answer.
fn oracle(block: &[&str]) -> Option<String> {
    let at = block.iter().position(|line| line.starts_with("- Oracle: `po-gate oracle-intact "))?;
    let (_, verdict) = block[at].rsplit_once('`')?;
    if verdict.trim() != "→ exit 0" {
        return None;
    }
    let output: Vec<&str> = block[at + 1..].iter().take_while(|line| line.starts_with("  ")).copied().collect();
    let value = if output.iter().any(|line| line.contains("has no oracle")) {
        "none"
    } else if output.iter().any(|line| line.contains(": changed, logged in ## Oracle changes")) {
        "changed-with-reason"
    } else {
        "intact"
    };
    Some(value.to_string())
}

/// `flow` or `full` from the plan's frontmatter; anything else is unreadable.
pub fn track(plan: Option<&str>) -> Option<String> {
    let mut lines = plan?.lines();
    if lines.next() != Some("---") {
        return None;
    }
    for line in lines {
        if line == "---" {
            return Some("full".to_string());
        }
        if let Some(value) = line.strip_prefix("track:") {
            return (value.trim() == "flow").then(|| "flow".to_string());
        }
    }
    None
}

/// From the start of the first `po-run` check to the end of the last, in whole seconds. Rows are
/// read as po-gate reads them, from both ends, the time in the last cell.
pub fn duration(record: Option<&str>) -> Option<u64> {
    let mut in_runs = false;
    let mut rows = 0;
    let mut times: Vec<(i64, Option<i64>)> = Vec::new();
    for line in record?.lines() {
        if line.starts_with("## ") {
            in_runs = line == "## Runs";
            rows = 0;
            continue;
        }
        let trimmed = line.trim();
        if !in_runs || !trimmed.starts_with('|') {
            continue;
        }
        rows += 1;
        let inner = trimmed.strip_prefix('|').unwrap_or(trimmed);
        let inner = inner.strip_suffix('|').unwrap_or(inner);
        let cells: Vec<&str> = inner.split('|').map(str::trim).collect();
        let n = cells.len();
        if rows == 1 || n < 5 {
            continue;
        }
        let (tree, code) = (cells[n - 2], cells[n - 3]);
        if tree.len() != 40 || !tree.bytes().all(|b| b.is_ascii_hexdigit() && !b.is_ascii_uppercase()) {
            continue;
        }
        if code.is_empty() || !code.bytes().all(|b| b.is_ascii_digit()) {
            continue;
        }
        times.push(time_cell(cells[n - 1])?);
    }
    let (first_end, first_length) = *times.first()?;
    let (last_end, _) = *times.last()?;
    let span = last_end - (first_end - first_length?);
    u64::try_from(span).ok()
}

/// `<rfc3339>` or `<rfc3339> (<n>s)`: the end time in seconds and the duration when given.
fn time_cell(cell: &str) -> Option<(i64, Option<i64>)> {
    let (time, length) = match cell.strip_suffix("s)").and_then(|rest| rest.rsplit_once(" (")) {
        Some((time, seconds)) => (time, Some(seconds.parse::<u32>().ok()? as i64)),
        None => (cell, None),
    };
    Some((DateTime::parse_from_rfc3339(time).ok()?.timestamp(), length))
}
