//! `docs/stories.md` as committed on the target branch: each story's id, surface, dependencies,
//! `Owns` and milestone, read by the rules of po-session.sh.

use crate::project::Project;

pub struct Story {
    pub id: String,
    /// The value of its `- **Surface**` line, lowercased and trimmed; `None` without one.
    pub surface: Option<String>,
    /// Every story id its `- **Depends on**` / `- **Dépend de**` line names.
    pub depends_on: Vec<String>,
    /// Each backticked entry of its `- **Owns**` line, verbatim.
    pub owns: Vec<String>,
    /// The `## M…` section it sits in.
    // Read by `po state`'s `shipped` (a later M21 story).
    #[allow(dead_code)]
    pub milestone: Option<String>,
}

impl Story {
    pub fn has_screen(&self) -> bool {
        self.surface.as_deref().is_some_and(says_screen)
    }
}

pub struct Section {
    pub id: String,
    pub stories: Vec<String>,
}

pub struct Stories {
    pub present: bool,
    pub list: Vec<Story>,
    pub milestones: Vec<Section>,
}

/// `s<n>-<slug>` at the start of `text`, as `^s[0-9]+-[a-z0-9-]+`.
fn story_id(text: &str) -> Option<String> {
    let rest = text.strip_prefix('s')?;
    let digits = rest.chars().take_while(|c| c.is_ascii_digit()).count();
    if digits == 0 || !rest[digits..].starts_with('-') {
        return None;
    }
    let slug = rest[digits + 1..]
        .chars()
        .take_while(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || *c == '-')
        .count();
    if slug == 0 {
        return None;
    }
    Some(text[..1 + digits + 1 + slug].to_string())
}

/// Every story id anywhere in `text`, left to right, as po-session's repeated awk `match`.
fn story_ids(text: &str) -> Vec<String> {
    let mut ids = Vec::new();
    let mut at = 0;
    while let Some(offset) = text[at..].find('s') {
        let start = at + offset;
        match story_id(&text[start..]) {
            Some(id) => {
                at = start + id.len();
                ids.push(id);
            }
            None => at = start + 1,
        }
    }
    ids
}

/// The backticked entries of `text`, in order.
fn backticked(text: &str) -> Vec<String> {
    text.split('`').skip(1).step_by(2).map(str::to_string).collect()
}

/// The value after the first colon of a `- **Name**: value` line.
fn value(line: &str) -> &str {
    line.split_once(':').map(|(_, v)| v).unwrap_or("")
}

/// The word `screen` on its own, as po-session's `(^|[^a-z])screen([^a-z]|$)`.
fn says_screen(value: &str) -> bool {
    let bytes = value.as_bytes();
    value.match_indices("screen").any(|(at, word)| {
        let before = at == 0 || !bytes[at - 1].is_ascii_lowercase();
        let end = at + word.len();
        let after = end == bytes.len() || !bytes[end].is_ascii_lowercase();
        before && after
    })
}

impl Stories {
    pub fn read(project: &Project, target: &str) -> Stories {
        match project.on_target(target, "docs/stories.md") {
            Some(text) => Stories::parse(&text),
            None => Stories { present: false, list: Vec::new(), milestones: Vec::new() },
        }
    }

    pub fn parse(text: &str) -> Stories {
        let mut list: Vec<Story> = Vec::new();
        let mut milestones: Vec<Section> = Vec::new();
        let mut in_story = false;
        let mut in_milestone = false;
        for line in text.lines() {
            let hashes = line.chars().take_while(|c| *c == '#').count();
            if hashes >= 2 && line[hashes..].starts_with(' ') {
                let heading = &line[hashes + 1..];
                if let Some(id) = story_id(heading) {
                    let mut milestone = None;
                    if in_milestone {
                        if let Some(section) = milestones.last_mut() {
                            section.stories.push(id.clone());
                            milestone = Some(section.id.clone());
                        }
                    }
                    list.push(Story { id, surface: None, depends_on: Vec::new(), owns: Vec::new(), milestone });
                    in_story = true;
                } else {
                    in_story = false;
                    if hashes == 2 {
                        let is_milestone = heading.starts_with('M')
                            && heading[1..].starts_with(|c: char| c.is_ascii_digit());
                        in_milestone = is_milestone;
                        if is_milestone {
                            let id = heading.split(" — ").next().unwrap_or(heading).trim();
                            milestones.push(Section { id: id.to_string(), stories: Vec::new() });
                        }
                    }
                }
                continue;
            }
            if !in_story {
                continue;
            }
            let Some(story) = list.last_mut() else { continue };
            if line.starts_with("- **Surface**") {
                story.surface = Some(value(line).trim().to_lowercase());
            } else if line.starts_with("- **Depends on**") || line.starts_with("- **Dépend de**") {
                story.depends_on.extend(story_ids(value(line)));
            } else if line.starts_with("- **Owns**") {
                story.owns.extend(backticked(value(line)));
            }
        }
        Stories { present: true, list, milestones }
    }

    pub fn find(&self, id: &str) -> Option<&Story> {
        self.list.iter().find(|story| story.id == id)
    }

    /// Stories exist, each has a Surface line and none says screen: the design system is not needed.
    pub fn no_story_has_a_screen(&self) -> bool {
        !self.list.is_empty() && self.list.iter().all(|story| story.surface.is_some() && !story.has_screen())
    }
}
