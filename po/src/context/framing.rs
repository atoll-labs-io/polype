//! The framing stage, each framing item's state and the current milestone, read on the target
//! branch. These are `po`'s rules: po-session.sh prints the same words.

use serde::Serialize;

use super::lanes::Landed;
use super::stories::Stories;
use super::{Settings, Warning, Warnings};
use crate::project::Project;

#[derive(Serialize, Clone, Debug, PartialEq)]
pub struct Framing {
    pub stage: String,
    pub next: Option<String>,
    pub items: Vec<Item>,
}

/// One framing item and its state, in po-session's words.
#[derive(Serialize, Clone, Debug, PartialEq)]
pub struct Item {
    pub item: &'static str,
    pub state: &'static str,
}

impl Framing {
    pub fn setup() -> Framing {
        Framing { stage: "setup".into(), next: Some("/po-setup".into()), items: Vec::new() }
    }
}

#[derive(Serialize, Clone, Debug, PartialEq)]
pub struct Milestone {
    pub id: String,
    pub stories: usize,
    pub shipped: usize,
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

    let scope_state = match scope {
        None => "by hand",
        Some((file, _)) => match exists(file) {
            None => "missing",
            Some(text) if frontmatter_status(&text).as_deref() == Some("approved") => "approved",
            Some(_) => "in progress",
        },
    };
    let review = exists("docs/reviews/stories.md").and_then(|text| {
        let line = text.lines().filter(|line| line.starts_with("Stories ready:")).last()?;
        let word = line["Stories ready:".len()..].split_whitespace().next()?.to_lowercase();
        Some(word.starts_with("yes"))
    });
    let architecture = exists("docs/architecture.md").is_some();
    let design_system_state = if exists("docs/design-system.md").is_some() {
        "present"
    } else if stories.present && stories.no_story_has_a_screen() {
        "not needed"
    } else {
        "missing"
    };
    let design_system = design_system_state != "missing";

    let scope_pending = scope.filter(|_| scope_state != "approved");

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
    let present = |yes: bool| if yes { "present" } else { "missing" };
    let items = vec![
        Item { item: "scope", state: scope_state },
        Item { item: "stories", state: present(stories.present) },
        Item {
            item: "stories-review",
            state: match review {
                None => "none",
                Some(true) => "yes",
                Some(false) => "no",
            },
        },
        Item { item: "architecture", state: present(architecture) },
        Item { item: "design-system", state: design_system_state },
    ];
    Some(Framing { stage: stage.into(), next: next.map(str::to_string), items })
}

/// The first `## M…` section of the stories holding a story not shipped yet.
pub fn milestone(stories: &Stories, landed: &Landed) -> Option<Milestone> {
    stories.milestones.iter().find_map(|section| {
        let done = section.stories.iter().filter(|id| landed.contains(id)).count();
        (done < section.stories.len()).then(|| Milestone {
            id: section.id.clone(),
            stories: section.stories.len(),
            shipped: done,
        })
    })
}

