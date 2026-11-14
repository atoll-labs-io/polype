//! The start point a lane opens from: `origin/<target>` when that ref exists, `<target>` otherwise,
//! and the story ids its `docs/stories.md` names. Read locally, no remote asked.

use std::collections::HashSet;

use super::stories::Stories;
use crate::project::Project;

pub struct StartPoint {
    pub reference: String,
    ids: HashSet<String>,
}

impl StartPoint {
    pub fn read(project: &Project, target: &str, stories_on_target: &Stories) -> StartPoint {
        let origin = format!("refs/remotes/origin/{target}");
        if project.git(&["rev-parse", "--verify", "-q", &origin]).is_some() {
            let reference = format!("origin/{target}");
            let ids = project
                .on_target(&reference, "docs/stories.md")
                .map(|text| Stories::parse(&text).list.into_iter().map(|story| story.id).collect())
                .unwrap_or_default();
            return StartPoint { reference, ids };
        }
        let ids = stories_on_target.list.iter().map(|story| story.id.clone()).collect();
        StartPoint { reference: target.to_string(), ids }
    }

    pub fn holds(&self, id: &str) -> bool {
        self.ids.contains(id)
    }
}
