//! Whether two `Owns` entries may name a common path: the rule of check 8 of the stories-review
//! skill, hand-written since ADR-0118 admits no glob crate.

pub fn overlap(a: &str, b: &str) -> bool {
    let a = segments(a);
    let b = segments(b);
    let mut at = 0;
    loop {
        match (a.get(at), b.get(at)) {
            (None, None) => return true,
            (None, Some(_)) => return b[at..].iter().all(|s| *s == "**"),
            (Some(_), None) => return a[at..].iter().all(|s| *s == "**"),
            (Some(x), Some(y)) => {
                if *x == "**" || *y == "**" {
                    return true;
                }
                let (x_glob, y_glob) = (x.contains('*'), y.contains('*'));
                let goes_on = match (x_glob, y_glob) {
                    (false, false) => x == y,
                    (true, false) => matches(x, y),
                    (false, true) => matches(y, x),
                    (true, true) => true,
                };
                if !goes_on {
                    return false;
                }
            }
        }
        at += 1;
    }
}

/// A folder `x/` stands for `x/**`.
fn segments(entry: &str) -> Vec<&str> {
    let mut list: Vec<&str> = entry.split('/').filter(|s| !s.is_empty()).collect();
    if entry.ends_with('/') {
        list.push("**");
    }
    list
}

/// `*` matches any run of characters within one segment.
fn matches(pattern: &str, name: &str) -> bool {
    let parts: Vec<&str> = pattern.split('*').collect();
    let (first, last) = (parts[0], parts[parts.len() - 1]);
    if !name.starts_with(first) || name.len() < first.len() + last.len() || !name.ends_with(last) {
        return false;
    }
    let mut rest = &name[first.len()..name.len() - last.len()];
    for part in &parts[1..parts.len() - 1] {
        match rest.find(part) {
            Some(at) => rest = &rest[at + part.len()..],
            None => return false,
        }
    }
    true
}

/// One path both entries cover, for a pair `overlap` accepted; `None` when the overlap is kept by
/// prudence only (two wildcards in one segment, a `**` whose tail the other side cannot end with).
pub fn common_path(a: &str, b: &str) -> Option<String> {
    let a = segments(a);
    let b = segments(b);
    let mut path: Vec<&str> = Vec::new();
    let mut at = 0;
    loop {
        match (a.get(at), b.get(at)) {
            (None, None) | (None, Some(_)) | (Some(_), None) => return render(&path, &[], false),
            (Some(x), Some(y)) => {
                if *x == "**" || *y == "**" {
                    let from_a = (*x == "**").then(|| across(&path, &a[at + 1..], &b[at..])).flatten();
                    return from_a.or_else(|| (*y == "**").then(|| across(&path, &b[at + 1..], &a[at..])).flatten());
                }
                match (x.contains('*'), y.contains('*')) {
                    (false, false) if x == y => path.push(x),
                    (true, false) if matches(x, y) => path.push(y),
                    (false, true) if matches(y, x) => path.push(x),
                    _ => return None,
                }
            }
        }
        at += 1;
    }
}

/// `path` continued across a `**` followed by `after`, the other side going on with `rest`.
fn across(path: &[&str], after: &[&str], rest: &[&str]) -> Option<String> {
    if after.iter().any(|s| s.contains('*')) {
        return None;
    }
    let folder = rest.last() == Some(&"**");
    let body = if folder { &rest[..rest.len() - 1] } else { rest };
    if body.iter().any(|s| s.contains('*')) {
        return None;
    }
    let mut full: Vec<&str> = path.to_vec();
    full.extend_from_slice(body);
    if folder {
        render(&full, after, after.is_empty())
    } else if body.ends_with(after) {
        render(&full, &[], false)
    } else {
        None
    }
}

fn render(path: &[&str], after: &[&str], folder: bool) -> Option<String> {
    let all: Vec<&str> = path.iter().chain(after).copied().collect();
    if all.is_empty() {
        return None;
    }
    let mut text = all.join("/");
    if folder {
        text.push('/');
    }
    Some(text)
}
