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
| 2026-10-13 | s112-short-subject-shipped | Launched in wave 3 | Ready once s109 shipped; no `Owns` overlap with s113 |
| 2026-10-13 | s113-reuse-ladder | Launched in wave 3 | Ready once s111 shipped; no `Owns` overlap with s112 |
| 2026-10-13 | s112-short-subject-shipped | Plan approved without a human (short track) | `Plan validation: autonomous`; complexity 2 within `Flow threshold`, no escalation signal |
| 2026-10-13 | s113-reuse-ladder | Lane handed to the owner | Its plan holds `Technical choice: waiting for a human` for ADR-0085 (option A recommended); s114 waits on it |
| 2026-10-13 | s112-short-subject-shipped | Asked the reviewer to resend its answer with the missing `Review status:` line | `/po-review` requires the line; the lead does not author it |
| 2026-10-13 | s112-short-subject-shipped | Merged by the agent (PR #22) | Effective `Ship confirmation: automatic`, solo repository |
| 2026-10-13 | s113-reuse-ladder | Recorded the owner's choice of ADR-0085 option A in the plan and the ADR, then validated the plan | The owner answered "go pour A"; `Plan validation: autonomous` applies once the choice is settled |
| 2026-10-13 | s113-reuse-ladder | Fixed the ADR-0085 body ("Option proposée" → "Option choisie") on the story branch before the ship | The review's minor; an accepted ADR's body is never edited once on `main`; the change is under `docs/` and leaves the reviewed tree valid |
| 2026-10-13 | s114-reuse-ladder-eval | Kept the planner's choice: the control arm refuses to start without `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN` and never copies `~/.claude/.credentials.json` | The cautious way to handle a secret, and easy to undo |
| 2026-10-13 | s113-reuse-ladder, s114-reuse-ladder-eval | Merged by the agent (PRs #24, #25) | Effective `Ship confirmation: automatic`, solo repository |
| 2026-10-13 | — | Landed this log together with the refreshed installed copy in one framing PR | Both are framing-path files written after the milestone's last ship |
| 2026-10-13 | s115-no-claude-md, s116-eval-arms-same-environment | Launched together | Both approved by the owner, `Owns` disjoint |
| 2026-10-13 | s115-no-claude-md | Kept the planner's reading: with no `AGENTS.local.md`, the installer leaves a `CLAUDE.md` with notes untouched and says so, instead of creating the file | The installer never writes `AGENTS.local.md`, which `/po-setup` refuses to overwrite; the story notes allowed this branch |
| 2026-10-13 | s115-no-claude-md | Shipped with the review's minor 5 put to the owner afterwards (`CLAUDE.local.md`, usually private, moves into a tracked file) | Ship allowed; the owner approved absorbing both files; an update leaves the change uncommitted and visible |
| 2026-10-13 | s115-no-claude-md, s116-eval-arms-same-environment | Merged by the agent (PRs #28, #29) | Effective `Ship confirmation: automatic`, solo repository |
