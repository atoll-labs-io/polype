//! The framing stage and the current milestone, by the rules of po-session.sh, read on the
//! target branch.

use serde::Serialize;

use super::lanes::Landed;
use super::stories::Stories;
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

