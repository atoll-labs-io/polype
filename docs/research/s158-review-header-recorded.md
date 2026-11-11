# Research — s158-review-header-recorded

[Story](../stories.md)

## Structuring facts
- Root cause: the review file's header is whatever the reviewer wrote. `/po-review` writes "the subagent's answer, whole" (`method/commands/po-review.md:37`), `/po-drive` records it "**verbatim**" (`method/commands/po-drive.md:136`), the reviewer is only told "Structured like `templates/review.md`" (`method/agents/reviewer.md:53`); no stage writes the link line and none checks it. Input: s147's reviewer answered `# Review — s147-…`, a blank line, then a prose summary (`git show f71ba00:docs/reviews/s147-strict-checks-by-default.md:1-3`). Proof: that file, extracted with `git archive f71ba00`, fails `existing_artifacts_backfilled` and `links_resolve_everywhere` of `tests/artifact-links-backfill.test.sh` (see `## Diagnostic`).
- No story assumption turned out false. The story's line refs hold: `po-review.md:41` is the blocked report the command composes; `po-gate findings-shape` reads only the last verdict block (`method/hooks/po-gate.sh:108-110`), never the header.
- The change is text in four method files plus one ADR: no hook, gate or script moves. `bin/po-link-artifacts` takes the link line as the first non-blank line after the title (`bin/po-link-artifacts:15`), so the template note must come **after** the link line.

## Diagnostic
**Reproduction.** `git archive f71ba00 | tar -x -C <tmp>`, then `bash tests/run.sh artifact-links-backfill.test.sh` in it → `FAIL existing_artifacts_backfilled: artefacts without their link line: docs/reviews/s147-strict-checks-by-default.md` and `FAIL links_resolve_everywhere: … no link on the line under the title`. Repaired on main by hand in 2f98528 (#168).

**Hypotheses.**
1. The template lacked the link line when s147 was reviewed. Refuting observation: the template at f71ba00 holds it. `git show f71ba00:method/templates/review.md:3` and `f71ba00:.polype/templates/review.md:3` both carry `[Story](../stories.md) · [Plan](…) · [Verification](…)`. **Discarded.**
2. A later stage stripped the line (ship, link script). Refuting observation: a stage that rewrites `docs/reviews/<id>.md`. `/po-ship` only commits it (`method/commands/po-ship.md:51`) and reads it (`:85-91`); `bin/po-link-artifacts` only inserts (`:54`). **Discarded.**
3. The reviewer's answer lacked the line and was recorded as is. Refuting observation: a recording step that adds or checks the header. None exists (`po-review.md:36-41`, `po-drive.md:135-140`); the s147 file opens with a summary paragraph that is no part of `templates/review.md`, the reviewer's own shape. **Kept.**

## Story
The context that records a review writes the template's title and link line itself, then the body; the reviewer answers below them. Criteria: `recorder_writes_the_header` (`/po-review` `## Recording`), `drive_writes_the_header` (`/po-drive` verdict section), `reviewer_answers_below_the_header` (`reviewer.md` `## Your answer` and the `/po-review` prompt), `template_marks_the_header` (a note under the link line, link line unchanged), `adr_records_the_header_rule` (ADR-0104, two options turned down in order).

## Current code
- `method/commands/po-review.md:29-34` `## Delegation`: the prompt says "Shape your answer like templates/review.md with `Fix loop: <n>`" (`:32`).
- `method/commands/po-review.md:36-41` `## Recording`: `:37` write the answer whole; `:39` findings-shape check, re-ask appended "after the malformed block, which stays byte for byte: Write replaces the whole file, so everything already in it is written back unchanged before the new answer", blocked reports appended; `:41` the command writes the file itself on a subagent failure.
- `method/commands/po-drive.md:135-142` `## The verdict, and the fix runs`: `:136` verbatim through Bash, "You transcribe it, you do not author it: no severity is yours to choose, no finding yours to soften or drop."; `:138` shape stops appended; `:140` the single report it composes.
- `method/agents/reviewer.md:52-58` `## Your answer`: `:53` "Structured like `templates/review.md`, with the `Reviewed tree:` line in its header." — "header" here means the status lines, which will clash with the file header.
- `method/templates/review.md:1-3`: title `# Review — <id>`, blank, link line; `:5` `Diff reviewed:` opens the body.
- Fix-loop reviews are appended: `docs/reviews/s125-ship-and-fleet-cleanup.md:1,90` holds two `# Review` titles, the second copied by the reviewer again.

## Attachment points
- One paragraph at the top of `## Recording` (`po-review.md:37`), and a pointer to it in `:41`.
- The first sentence of `po-drive.md:136`.
- `## Your answer` (`reviewer.md:53`) and the prompt `po-review.md:32`.
- A note line after `method/templates/review.md:3`, before `:5`.
- New `docs/decisions/ADR-0104-celui-qui-consigne-une-revue-en-ecrit-l-en-tete.md` (number reserved by the driver).

## Verified interfaces
- `bin/po-link-artifacts`: `template_line` = first non-blank line after the first `# ` (`:15`); skips a file whose line under the title starts `[Story](` (`:46-48`); keeps only links whose target exists (`resolvable`, `:20-31`). Same rule the story asks of the recorder.
- `po-gate findings-shape <id>` (`method/hooks/po-gate.sh:96-127`): reads lines between the last two `Ship allowed:` lines only.
- `po-gate ship-allowed`: last `Ship allowed:`, paired `Reviewed tree:` and `Review status:` (`po-ship.md:18`); no title read.
- `/po-orchestrator` (`method/commands/po-orchestrator.md:73`) and `/po-flow` (`method/commands/po-flow.md:89`) record "as `/po-review` says": inherit the rule unchanged.
- `/po-review` tools: Read, Glob, Grep, Agent, Write, `Bash(.polype/hooks/po-gate.sh findings-shape:*)` (`po-review.md:4-10`): Write and Glob suffice to write the header and test link targets.

## Traps
- Frozen phrases outside `Owns` that must survive: `tests/drive.test.sh:64-69` (`recorded **verbatim** into \`docs/reviews/<id>.md\``, `You transcribe it, you do not author it`, `no severity is yours to choose, no finding yours to soften or drop`, `answers without both verdict lines is recorded as \`Review status: blocked\``, `` `Max severity: critical` and `Ship allowed: no` ``); `tests/review-findings-shape.test.sh:69,77-83,136-139` (Recording and Your answer phrases); `tests/review.test.sh:21-65` (template ends with the verdict lines, `Reviewed tree:` before `Max severity:`, po-review lacks Edit and plain Bash); `tests/artifact-link-templates.test.sh:24-35` (link line exact); `tests/qa-fleet.test.sh:120-142` (verdict section); `tests/hooks-installer-docs-cleanup.test.sh:57`. No test quotes `in its header` or `Structured like`.
- `tests/artifact-links-backfill.test.sh:73-85` runs over every review on the branch: this story's own review, recorded under the new rule, must pass it.
- `tests/overlap.test.sh`: no 8-word run shared with Killer SaaS.
- Installed copies `.claude/`, `.polype/` are not edited (AGENTS.local.md conventions).
- No migration. No lane in flight holds a review without header (story note, 2026-11-11).

## Open questions
- An appended fix-loop block will no longer start with its own `# Review` title: nothing reads it (`po-gate.sh:108`), but readers lose a visual separator. The story asks for the new block only; the plan follows it.
- A reviewer that still copies `# Review` and the link line out of habit gives a file with a doubled header; the verbatim rule keeps it, and the backfill test reads the first title only, so it passes. Accepted, not checked.
- `qa` returns its report whole, title and link line included (ADR-0102): the same defect class could hit `docs/qa/<id>/report.md`. Out of this story's `Owns`; for the lead to file.

## Complexity
Story 2 → 2: four method files and one ADR, text only; the only coupling is the frozen phrases listed above.

## Split
—
