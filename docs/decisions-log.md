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
| 2026-10-13 | s117-eval-reuses-login | Set aside after its research; story removed from `docs/stories.md`, research kept | The planner found Claude Code may refuse a symlinked `.credentials.json` (`O_NOFOLLOW`) and a token refresh could leave the real login stale; the owner chose a `claude setup-token` token instead |
| 2026-10-13 | s113-reuse-ladder | Ran the paid eval on the owner's Max subscription and kept the s113 rule | The rule arm flagged the rebuilt helper 3/3, the control 0/3; the recipe's inherited tenant gap explains the critical verdicts (`docs/evals/reuse-ladder.md`) |
| 2026-10-13 | s118-rebuilt-helper-single-defect | Re-ran the rebuilt-helper eval after s118 and recorded it | Both arms now score 3/3 on the expected verdict because the plant leaves the tenant boundary untested; the rule still grades the copy major 3/3 vs control 0/3 |
| 2026-10-13 | s119-rebuilt-helper-tests-tenant | Re-ran the rebuilt-helper eval after s119 and recorded it | Clean measure: rule 3/3 vs control 0/3 on the expected verdict |
| 2026-10-13 | — | Merged pecten #11 and nautile #23, then nautile #24 (`Merge mode: pr`) after its `gate` CI passed | Owner asked to merge them and make the needed updates; `Merge mode: local` with a remote stops `/po-ship` since ADR-0080 |
| 2026-10-14 | s115-no-claude-md | The owner confirmed that `polype update` also absorbs a private `CLAUDE.local.md` into the committed `AGENTS.local.md` | Answer to the s115 review's minor 5; documented in `docs/installation.md` by s122 |
| 2026-10-14 | s120-session-and-gate-checks | Widened s120's `Owns` on `main` (PR #41) after its planner stopped, then fast-forwarded its lane | `tests/review-tree-gate.test.sh`, `method/AGENTS.md` and `po-ship.md` had to change with the stricter gate |
| 2026-10-14 | s121-framing-realign-and-orchestrator-log | Re-dispatched its implementer | The first one ran while the lead was inside a framing worktree and inherited its isolation; it changed nothing |
| 2026-10-14 | s121-framing-realign-and-orchestrator-log, s122-docs-and-eval-cleanup | Ran fix loops on reviews that allowed the ship (s121 once, s122 twice) | The owner asked to finish at 100 %: no major and no minor left open |
| 2026-10-14 | s122-docs-and-eval-cleanup | Gave s122 the s120 review's major and minors (PR #45) and the `/po-status` bullet its planner found | Same root cause; s122 had not started and the files were free once s120 shipped |
| 2026-10-14 | s120, s121, s122 | Merged by the agent (PRs #43, #44, #46) | Effective `Ship confirmation: automatic`, solo repository |
| 2026-10-14 | s123-local-copy-checksums | Ran one fix loop on a review that allowed the ship, then shipped with one style minor (long doc lines) left | The loop-0 major (read order untested) would let the original bug come back silently; a line-wrap nit does not warrant a third review |
| 2026-10-14 | s123-local-copy-checksums | Merged by the agent (PR #49) and migrated Polype, pecten and nautile with `polype update` | Effective `Ship confirmation: automatic`; the migration is the real check the review left to a person |
| 2026-10-14 | — | Stopped adding a Claude session link to commits and PR descriptions, and removed it from 58 existing PR descriptions in polype, pecten and nautile | The owner does not want it; rule added to the global `CLAUDE.md` |
| 2026-10-14 | — | Triaged the 147 findings left by the reviews of s66–s123 with four read-only subagents, and framed M9 quinquies on the 42 that hold and can be fixed | The owner asked to finish at 100 %; the 13 left out are listed in the milestone intro |
| 2026-10-14 | s127-hooks-installer-docs-cleanup | Gave s127 `po-setup.md` and `templates/brief.md` and made it depend on s124 (PR #52) | Triage row 142 spans `po-gate.sh` and `/po-setup`; `brief.md:8` repeated the `prd.md:9` wording the triage missed |
| 2026-10-14 | s125, s126 | Asked their planners to also close gaps found on the way (`/po-status` root-cause case; the plan-flow technical-choice row) | Same files, same root cause, and the owner wants nothing left open |
| 2026-10-14 | s124, s125, s127 | Ran fix loops on reviews that allowed the ship | The owner asked for 100 %: every minor and major closed before the ship |
| 2026-10-14 | s127-hooks-installer-docs-cleanup | Kept the gate's verdict bound within accepted ADR-0056 instead of narrowing it; the review template's warning closes triage row 80 | Narrowing it contradicted ADR-0056 and partly reopened an option it rejected; the owner then confirmed and the story criterion was reworded |
| 2026-10-14 | — | Framed M10 from another agent's draft, split into s128 (templates) and s129 (backfill), after M9 quinquies | The owner approved; it touches every story's evidence, so it runs alone |
| 2026-10-14 | — | Repointed the remotes of polype, pecten and nautile to the renamed org `atoll-labs-io` | The owner renamed the GitHub org |
| 2026-10-14 | s124, s125, s126, s127 | Merged by the agent (PRs #53, #55, #56, #57) | Effective `Ship confirmation: automatic`, solo repository |
