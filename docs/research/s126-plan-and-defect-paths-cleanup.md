# Research — s126-plan-and-defect-paths-cleanup

[Story](../stories.md)

## Structuring facts
- Root cause: each HOLDS row is wording that s96, s104 and s111 left behind when they moved the rule elsewhere — the `diagnostic` skill puts the marker at the top of `## Structuring facts` (`method/skills/diagnostic/SKILL.md:25`) and s125 made po-drive read it as a whole line (`method/commands/po-drive.md:52`, `:103`), but `method/commands/po-research.md:55` and `method/commands/po-orchestrator.md:48` still say "opens with", and `method/commands/po-plan.md:26` and `method/agents/planner.md:39` still say "holding the line" without `grep -x`.
- The tests that should hold these rules check the whole file or a phrase that survives the deletion: `tests/diagnostic-skill.test.sh:42` passes on the planner's Defect bullet (`planner.md:39`) even with the escalation clause of `planner.md:33` gone; `tests/tech-choice-backstop.test.sh:73` uses `Stories ready:` as the "only the sentence went" guard, but that phrase is inside the removed sentence (`method/commands/po-stories-review.md:49`) and also appears 6 other times in that file.
- `method/templates/plan-flow.md:13` says "Any signal present means this file should not exist", while `method/commands/po-flow.md:70-74` keeps the plan on disk with the marker line when the signal is a technical choice.
- `method/agents/planner.md:56` fallback ("No number there … write the ranked options in the plan, report what is missing") does not repeat the marker line; `method/commands/po-flow.md:74` "name that ADR in the plan." has no test (no hit for "name that ADR" under `tests/`).
- No assumption of the story is false. Of the row s96 "three stop clauses", the po-drive one is already pinned by s125 (`tests/defect-and-routing-paths.test.sh:47`); the other two (po-orchestrator, po-research) remain.

## Diagnostic
Reproduction, on `story/s126-plan-and-defect-paths-cleanup` at 258e693 (read only, no file created):
- `grep -rnF 'opens with' method/commands/po-research.md method/commands/po-orchestrator.md` → `po-research.md:55`, `po-orchestrator.md:48`.
- `grep -nF 'Root cause: not found' method/commands/po-plan.md method/agents/planner.md` → `po-plan.md:26`, `planner.md:39`, neither with "whole line"; po-drive `:52` and `:103` do say "as a whole line (`grep -x`".
- `grep -rnF -e 'No root cause found' -e 'ends the run here' -e 'name that ADR' tests/` → no hit.
- `grep -c 'Stories ready:' method/commands/po-stories-review.md` → 7; the sentence the mutation deletes holds one of them.
- `bash tests/run.sh` → 550 passed, 0 failed (baseline).

Hypotheses:
1. The method files contradict each other in meaning (a real behaviour fork) — refuted: every file stops the lane on the marker; only the words for where it sits and how it is matched differ. Discarded.
2. The rows are wording drift plus tests that pin whole files or phrases surviving their deletion — kept: each row's line was read and matches the triage evidence (`docs/reviews/triage-2026-10-14.md:77,89-91,128,166-168`).

## Story
Rows closed (triage file lines): 77 (s90), 89, 90 (po-plan and planner part; po-drive done by s125), 91 (po-orchestrator and po-research part), 128 (s104), 166, 167, 168 (s111). Rows 126 and 129 (escalation-contract, po-status) belong to s125's `Owns`, not this one.

Criteria:
- `defect_stops_agree` — po-research and po-orchestrator place the marker where the skill does; po-plan and planner read it as a whole line; the untested stops fail when removed.
- `tech_choice_paths_agree` — plan-flow no longer says a short plan with a signal must not exist; planner's "No number there" repeats the marker; po-flow's "name that ADR in the plan" is held by a test.
- `plan_tests_bite` — the tech-choice-backstop mutation guard and the planner's `Fixes` clause are held by tests that fail when the rule is removed.

## Current code
- `method/commands/po-research.md:55` (`## The report`): "When the research opens with `Root cause: not found`, finish instead with: "No root cause found for <id>: …"".
- `method/commands/po-orchestrator.md:48` (`## Stage 2 — Research`): "A research that opens with `Root cause: not found` ends the run here: report it and hand the story to a human, with no plan."
- `method/commands/po-plan.md:26` (`## Checks first`): "`docs/research/<id>.md` holding the line `Root cause: not found` → stop: …".
- `method/agents/planner.md:33` (`## Which track`): signal list ending "a defect to fix — a story carrying a `Fixes` line (`Corrige` in a French stories file)".
- `method/agents/planner.md:39` (`## The contracts you carry`, Defect bullet): "A research holding the line `Root cause: not found`, whether you wrote it or found it on disk, ends your run …".
- `method/agents/planner.md:56` (`## Limits`): the "No number there" fallback.
- `method/templates/plan-flow.md:13`: guidance of `## Escalation signals`.
- `method/commands/po-flow.md:69-76` (`## Approval`): four bullets, the last "name that ADR in the plan."
- `tests/tech-choice-backstop.test.sh:53-83` `test_stories_review_rules_bite`: python removes the sentence of `po-stories-review.md:49`, then guards at :72-75.
- `tests/diagnostic-skill.test.sh:38-51` `test_defect_stories_get_the_diagnostic`: `contains "$f" '`Fixes`'` on planner, plan-flow, agentic-stories.

## Attachment points
- The six method files above, one sentence each.
- A new `tests/plan-and-defect-paths-cleanup.test.sh` with `test_defect_stops_agree`, `test_tech_choice_paths_agree`, `test_plan_tests_bite` (criterion name = function name, `AGENTS.local.md` conventions).
- Mutation helpers to copy, not import: `mutant`, `run_against`, `bites` of `tests/ship-and-fleet-cleanup.test.sh:14-23,64-79` (each test file defines its own; `tests/tech-choice-backstop.test.sh:12-22` does the same).

## Verified interfaces
- `section_of <file> <heading>` (`awk` on `## <heading>`), defined per file, e.g. `tests/defect-and-routing-paths.test.sh:15`.
- `holds "$text" "$phrase" "$where"` (`tests/ship-and-fleet-cleanup.test.sh:12`), `contains`, `fail`, `frontmatter` from `tests/lib.sh`.
- `run_against <method dir> <test file> <test name>` re-sources a test file with `METHOD`/`CMDS` pointing at a mutant (`tests/ship-and-fleet-cleanup.test.sh:21-23`).
- `bites <file under method> <phrase> <test file> <test name>` removes the phrase once (asserts count 1) and expects the test to fail (`tests/ship-and-fleet-cleanup.test.sh:64-79`).

## Traps
- Existing pins on the lines changed: `tests/defect-and-routing-paths.test.sh:31,35-36` (po-plan Checks first and planner Defect bullet must keep `Root cause: not found` and "write no plan"), `:19-25` (po-research `The investigation` and orchestrator Stage 2 keep `` `diagnostic` skill ``, `` `Fixes` ``, `Corrige`); `tests/escalation-contract.test.sh:47` (planner holds the marker anywhere); `tests/drive.test.sh:178` (planner keeps "use the one the driver reserved for this lane in the message you received"); `tests/flow.test.sh:76-79` (plan-flow headings); `tests/tech-choice-backstop.test.sh:24-39` (po-flow Approval phrases and order).
- `bites` asserts the phrase occurs exactly once in its file: pick phrases unique in their file.
- `tests/overlap.test.sh`: no 8-word run shared with Killer SaaS; write new sentences in own words.
- The test file reads `method/commands/po-stories-review.md`, outside `Owns`; only the test changes, never that file.
- Full suite takes several minutes (550 tests).

## Open questions
- `method/templates/plan-flow.md:15-22` lists six signals; the "technical choice" signal of `po-flow.md:43` and `planner.md:33` has no row. Not in any criterion; the lead decided (2026-10-14) that this story adds it, task 3 of the plan.
- `method/commands/po-flow.md:73` drafts the ADR "under the next free number", which the planner forbids for fleet lanes (`planner.md:56`); `/po-flow` runs alone in its context, so it is not a conflict here. Left out.

## Complexity
2 → 2. Six one-sentence edits and one new test file; no behaviour change, no new mechanism.

## Split
—
