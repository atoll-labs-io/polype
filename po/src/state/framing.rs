//! The framing stage and the current milestone, by the rules of po-session.sh, read on the
//! target branch.

use serde::Serialize;

use super::lanes::Shipped;
use super::{Settings, Warning, Warnings};
use crate::project::Project;

#[derive(Serialize, Clone, Debug, PartialEq)]
pub struct Framing {
    pub stage: String,
    pub next: Option<String>,
}

impl Framing {
    pub fn setup() -> Framing {
        Framing { stage: "setup".into(), next: Some("/po-setup".into()) }
    }
}

#[derive(Serialize, Clone, Debug, PartialEq)]
pub struct Milestone {
    pub id: String,
    pub stories: usize,
    pub shipped: usize,
}

pub struct Story {
    pub id: String,
    /// The value of its `- **Surface**` line, lowercased and trimmed; `None` without one.
    pub surface: Option<String>,
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

/// `docs/stories.md` as committed on the target branch.
pub struct Stories {
    pub present: bool,
    pub list: Vec<Story>,
    pub milestones: Vec<Section>,
}

/// `s<n>-<slug>` at the start of a heading's text, as `^s[0-9]+-[a-z0-9-]+`.
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
                    if in_milestone {
                        if let Some(section) = milestones.last_mut() {
                            section.stories.push(id.clone());
                        }
                    }
                    list.push(Story { id, surface: None });
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
            if in_story && line.starts_with("- **Surface**") {
                if let Some(story) = list.last_mut() {
                    let value = line.split_once(':').map(|(_, v)| v).unwrap_or("");
                    story.surface = Some(value.trim().to_lowercase());
                }
            }
        }
        Stories { present: true, list, milestones }
    }

    pub fn find(&self, id: &str) -> Option<&Story> {
        self.list.iter().find(|story| story.id == id)
    }

    /// Stories exist, each has a Surface line and none says screen: the design system is not needed.
    fn no_story_has_a_screen(&self) -> bool {
        !self.list.is_empty() && self.list.iter().all(|story| story.surface.is_some() && !story.has_screen())
    }
}

fn frontmatter_status(text: &str) -> Option<String> {
    let mut lines = text.lines();
    if lines.next() != Some("---") {
        return None;
    }
    for line in lines {
        if line == "---" {
            return None;
        }
        if let Some(value) = line.strip_prefix("status:") {
            return Some(value.trim().to_string());
        }
    }
    None
}

pub fn framing(
    project: &Project,
    settings: &Settings,
    target: &str,
    stories: &Stories,
    warnings: &mut Warnings,
) -> Option<Framing> {
    let entry = settings.required("Entry mode", warnings)?;
    let scope = match entry.as_str() {
        "replace" | "adapt" => Some(("docs/prd.md", "/po-prd")),
        "new" => Some(("docs/brief.md", "/po-brief")),
        "—" => None,
        _ => {
            warnings.push(Warning::UnreadableSetting { setting: "Entry mode".into() });
            return None;
        }
    };
    let exists = |path: &str| project.on_target(target, path);

    let review = exists("docs/reviews/stories.md").and_then(|text| {
        let line = text.lines().filter(|line| line.starts_with("Stories ready:")).last()?;
        let word = line["Stories ready:".len()..].split_whitespace().next()?.to_lowercase();
        Some(word.starts_with("yes"))
    });
    let architecture = exists("docs/architecture.md").is_some();
    let design_system = exists("docs/design-system.md").is_some()
        || (stories.present && stories.no_story_has_a_screen());

    let scope_pending = scope.filter(|(file, _)| {
        exists(file).and_then(|text| frontmatter_status(&text)).as_deref() != Some("approved")
    });

    let (stage, next) = if let Some((_, command)) = scope_pending {
        ("scope", Some(command))
    } else if !stories.present {
        ("stories", Some("/po-stories"))
    } else if review != Some(true) {
        ("stories-review", Some("/po-stories-review"))
    } else if !architecture {
        ("architecture", Some("/po-architect"))
    } else if !design_system {
        ("design-system", Some("/po-design-system"))
    } else {
        ("done", None)
    };
    Some(Framing { stage: stage.into(), next: next.map(str::to_string) })
}

/// The first `## M…` section of the stories holding a story not shipped yet.
pub fn milestone(stories: &Stories, shipped: &Shipped) -> Option<Milestone> {
    stories.milestones.iter().find_map(|section| {
        let done = section.stories.iter().filter(|id| shipped.contains(id)).count();
        (done < section.stories.len()).then(|| Milestone {
            id: section.id.clone(),
            stories: section.stories.len(),
            shipped: done,
        })
    })
}

