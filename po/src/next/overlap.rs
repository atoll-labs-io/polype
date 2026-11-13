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
