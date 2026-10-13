# Decisions log

What the project lead decided alone, one row per decision, appended and never rewritten: `Date` is `YYYY-MM-DD`, `Story` is a story id or `—` when the decision concerns no single story.
A decision the person took is not logged here: it is an ADR or a story.

| Date | Story | Decision | Reason |
| --- | --- | --- | --- |
| 2026-10-13 | — | Wave 1 of M9 bis left out s01–s10 by hand, although `/po-drive` reads them as ready | They were shipped under short `sNN:` subjects that the current shipped rule does not recognise; s112 fixes the rule |
| 2026-10-13 | s108-ship-resumes-cleanly | Launched in wave 1 | Ready, first in story order, no `Owns` overlap |
| 2026-10-13 | s109-drive-guards | Launched in wave 1 | Ready, second in story order, no `Owns` overlap with s108 |
| 2026-10-13 | s110-framing-second-landing | Held back for wave 2 | `Parallel: 2` was already filled by s108 and s109 |
| 2026-10-13 | s111-tech-choice-backstop | Held back for wave 2 | `Parallel: 2` was already filled by s108 and s109 |
| 2026-10-13 | s108-ship-resumes-cleanly | Plan approved without a human | `Plan validation: autonomous`; the planner checked it against the criteria |
| 2026-10-13 | s109-drive-guards | Plan approved without a human | `Plan validation: autonomous`; the planner checked it against the criteria |
| 2026-10-13 | s109-drive-guards | Shipped before s108 | Its review passed first; ships go in the order the reviews passed |
| 2026-10-13 | s108-ship-resumes-cleanly, s109-drive-guards | Merged by the agent (PRs #16, #17) | Effective `Ship confirmation: automatic`, solo repository; the owner allows the agent to merge here |
