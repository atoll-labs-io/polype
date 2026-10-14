# Review — s126-plan-and-defect-paths-cleanup

[Story](../stories.md) · [Plan](../plans/s126-plan-and-defect-paths-cleanup.md) · [Verification](../verif/s126-plan-and-defect-paths-cleanup.md)

Diff reviewed: `git diff main...story/s126-plan-and-defect-paths-cleanup` (merge base 258e693), in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: e926d858cf37305d8adc2c9f2bee0266b205dbbb

## Ownership
I listed the diff with `git diff --name-only main...story/s126-plan-and-defect-paths-cleanup` and checked each path against the story's `Owns` line (`docs/stories.md:1950`).
- [x] Every path is inside `Owns`: `method/agents/planner.md`, `method/commands/po-orchestrator.md`, `method/commands/po-plan.md`, `method/commands/po-research.md`, `method/templates/plan-flow.md`, `tests/diagnostic-skill.test.sh`, `tests/tech-choice-backstop.test.sh`, `tests/plan-and-defect-paths-cleanup.test.sh` (new). The only other paths are this story's own pipeline evidence (research, plan, verif). `method/commands/po-flow.md` is in `Owns` but the diff does not change it; the tests only read it.
- [x] No path outside `Owns`.
- [x] No path inside another running story's `Owns`. The only other worktree is s127, and none of its `Owns` entries meets these paths.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s126-plan-and-defect-paths-cleanup` passed (exit 0), so I reused the record. It is complete, and the unit suite `bash tests/run.sh` exited 0 on code equal to `Tree: c149fb5…` outside `docs/`. The type check is `—`: the project has none. Its "Not proven here" says the project has no end-to-end tests, no build, and no lint or formatting check.
- [x] `po-gate qa-current`: not required. `QA stage` is `—`, so the story does not go to QA.
- Extra check, because `main` has moved: I cloned the repository under `/tmp/tmp.f72nPxO7e3/probe` and rebased the story onto `main` (553700b, with s124 and M10). This mattered because s124 edited `po-stories-review.md` and `po-stories.md`, and `tech-choice-backstop.test.sh` mutates those two files. The rebase applied cleanly and the full suite passed: 556 passed, 0 failed.

## Plan
- [x] Each task is present and nothing lies outside the plan:
  - Tasks 1–2: the four stop sentences now say "as a whole line (`grep -x`, ADR-0070)". po-research and po-orchestrator also point to `## Structuring facts`, which matches `method/skills/diagnostic/SKILL.md:19,25`.
  - Task 3: the planner's "No number there" fallback now repeats the waiting line. The "should not exist" sentence in plan-flow is replaced by the exception for a technical choice. The signal table gets one new row, the lead's decision.
  - Task 4: `test_defect_stories_get_the_diagnostic` now pins the `## Which track` Fixes clause, which is at `planner.md:33`.
  - Task 5: the backstop guard checks a phrase outside the removed sentence, plus a line count that must drop by exactly one. `po-stories-review.md:49` is the only line with `Stories ready:` that the mutant touches, so the count is right.
  - Task 6: the new test file has 3 functions, and its helpers are copied as the Reuse table says.
- [x] Each run interdict was checked:
  - The diff is empty on `po-drive.md`, `po-status.md`, `method/AGENTS.md`, `po-stories-review.md`, `method/skills/`, `defect-and-routing-paths.test.sh`, `escalation-contract.test.sh` and `ship-and-fleet-cleanup.test.sh`.
  - `.claude/` and `.polype/` are untouched, and no ADR was added.
  - The finish message of po-research and the stop reason of po-plan keep their wording word for word.
  - The signal table gains exactly one row, and the six existing rows are unchanged.
  - Detection stays "whole line, anywhere", with no position rule.

## References
- [x] I opened every target: `diagnostic/SKILL.md:19,25`; `po-drive.md:52,103` (s125's whole-line wording, which "sends its lane to a human" quotes); `po-flow.md` `## Approval` (keep the plan on disk, the marker line, `validated: no`, "name that ADR in the plan."); `po-flow.md` `## Escalation signals` (the technical-choice wording the new row repeats); `planner.md:33`. The new plan-flow sentence matches what `## Approval` of `/po-flow` says, including pointing to `/po-research <id>`.
- [x] I checked whether the triage rows the story claims to close are now fixed. Rows 77, 89, 90, 91, 128, 166, 167 and 168 of `docs/reviews/triage-2026-10-14.md` no longer hold on the branch. Row 90 also names po-drive, but s125 already fixed that part. Row 113 (`po-stories.md`) is not in this story's `Owns`.
- [x] No value only looks right: the tests quote the exact phrases each method file now contains.

## Rules
- [x] The `AGENTS.md` and `AGENTS.local.md` conventions hold: method text in English, one test file named after the story, existing tests changed only where the story changes the clause they check (stated in tasks 4 and 5).
- [x] No accepted ADR is contradicted; ADR-0070's whole-line reading is kept.

## Tests
- [x] Floor: `po-gate floor-guard s126-plan-and-defect-paths-cleanup main` → exit 0, nothing lowered.
- [x] The assertions pin each criterion inside its own section, not across the whole file. None of the six shapes of test that prove nothing appears. The mutants are copies of `method/` under a temporary directory, and `bites` checks that its phrase occurs exactly once before removing it.
- [x] Within `Test budget` (25): 3 new tests and 2 tightened ones.
- [x] Bite 1: I removed the waiting line from the "No number there" fallback in `method/agents/planner.md`. 2 tests failed (`tech_choice_paths_agree`, `plan_tests_bite`). I undid it with `git checkout`, and `git diff --exit-code` was clean.
- [x] Bite 2: I put the old wording "holding the line `Root cause: not found`" back in `method/commands/po-plan.md`. 2 tests failed (`defect_stops_agree`, `plan_tests_bite`). I undid it, and `git diff --exit-code` was clean.
- [x] No test is made useless by the story.

## Neighbours
- [x] I read the other places that use the marker and the template: `po-status.md:36,39`, `method/AGENTS.md:77`, `po-session.sh:208` (`grep -qx`), and the uses of plan-flow in `po-flow.md:65` and `planner.md:41`. They agree with the new wording and nothing breaks; the full suite passes on the branch rebased onto main.

## Lenses
Lenses run: none. The diff touches only markdown method files and bash tests, and has no trigger for security, migration, dependencies or performance.
- [x] Nothing to grade.

## Findings
none

## Not verified
- I did not re-run the full suite on the story branch itself. The record is current and reused under `Verification mode: record`. I did run it once on the branch rebased onto main, in the throwaway clone.
- I bit two rules. The other rules are held by the story's own `test_plan_tests_bite` mutations, and I did not re-check each of those by hand. A person can do so by deleting any one phrase that `test_plan_tests_bite` names and running `bash tests/run.sh plan-and-defect-paths-cleanup.test.sh`.
- Whether an agent actually follows the reworded sentences can only be seen in a real run. The tests check the text, not how a model behaves. To cover it, a person can watch a defect story whose research holds `Root cause: not found` go through `/po-orchestrator` and `/po-plan`.
- The project has no type check, end-to-end tests, build, lint or formatting command (all `—`), so none of these ran.

Max severity: none
Ship allowed: yes
