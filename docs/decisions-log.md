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
| 2026-10-13 | — | Wave 2 again left out s01–s10 by hand | Same reason as wave 1: shipped under short subjects, which s112 fixes |
| 2026-10-13 | s110-framing-second-landing | Launched in wave 2 | Ready, first in story order, no `Owns` overlap |
| 2026-10-13 | s111-tech-choice-backstop | Launched in wave 2 | Ready, second in story order, no `Owns` overlap with s110 |
| 2026-10-13 | s112-short-subject-shipped | Held back for wave 3 | `Parallel: 2` was already filled by s110 and s111 |
| 2026-10-13 | s110-framing-second-landing | Plan approved without a human | `Plan validation: autonomous`; the planner checked it against the criteria |
| 2026-10-13 | s111-tech-choice-backstop | Plan approved without a human | `Plan validation: autonomous`; the planner checked it against the criteria |
| 2026-10-13 | s110-framing-second-landing | Accepted the planner's implementation details: a PR closed without a merge counts as not merged, and on GitHub without a working `gh` the landing stops instead of falling back to ancestry | Both are the cautious reading, and the criterion asks for "qu'une pull request soit ouverte ou non" |
| 2026-10-13 | s110-framing-second-landing, s111-tech-choice-backstop | Asked both reviewers to resend their answers with the `Review status:` line they had left out | `/po-review` requires the line in the recorded file; the lead transcribes and does not author it |
| 2026-10-13 | s111-tech-choice-backstop | Shipped before s110 | Its review came back first |
| 2026-10-13 | s110-framing-second-landing, s111-tech-choice-backstop | Merged by the agent (PRs #19, #20) | Effective `Ship confirmation: automatic`, solo repository |
