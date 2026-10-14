# Review: s80-surface-routing

[Story](../stories.md) · [Plan](../plans/s80-surface-routing.md) · [Verification](../verif/s80-surface-routing.md)

Reviewed tree: 2c80c8fcc6643ed164e294de6de5fd7d75e246d1
Fix loop: 0
Worktree: /home/lecrabe/dev/atoll/polype/.worktrees/s80-surface-routing (branch `story/s80-surface-routing`, one commit 506eadd)

**Result:** the story can ship. I found no critical or major problems, only two minor wording issues.

## Scope (`Owns`)
I listed the diff with `git diff --name-only main...story/s80-surface-routing`, which gives 21 paths.
- **Inside `Owns`:** all 16 code and test paths are listed on the story's `Owns` line in `docs/stories.md:1235`.
  - The 12 method and README files: `README.md`, `method/AGENTS.md`, `method/agents/implementer.md`, `method/agents/reviewer.md`, `method/commands/po-drive.md`, `po-flow.md`, `po-help.md`, `po-orchestrator.md`, `po-status.md`, `method/skills/review-antihallu/SKILL.md`, `method/templates/plan.md`, `plan-flow.md`, `review.md`.
  - The 4 test files: `tests/fleet-design.test.sh`, `tests/qa-fleet.test.sh`, `tests/qa-gate.test.sh`, `tests/surface-routing.test.sh`.
- **This story's own pipeline files:** `docs/research/`, `docs/plans/` and `docs/verif/` for s80. They are in scope by construction.
- **The new ADR:** `docs/decisions/ADR-0058-...md` is added (status A) and the plan names it, so it is in scope by construction.
- **Other running stories:** the only other open worktree is `s81-scenario-driver`. It owns `method/skills/qa-drivers/scenarios.md` and `tests/scenario-driver.test.sh`, so nothing overlaps.

## Evidence reused
- [x] `po-gate verif-current s80-surface-routing` passes (exit 0).
  - The record is complete. It has one `po-run` row for `bash tests/run.sh` with exit 0. `Verification mode: record`, so I did not rerun the suite.
  - The project has no type-check command (`Typecheck: —`), nor any E2E or build command.
  - The record's "Not proven here" section says no real drive, orchestrator, flow or review run was made against this tree.
- [x] `po-gate qa-current`: not required, because the story's `Surface` line is `—`, so it does not go to QA. It also has no screen, so no design check applies.

## Plan
- [x] Each task is present and nothing falls outside the plan.
  - I checked all the plan's required sentences (D1, R1–R2, G1–G4, O1–O3, S1–S2, F1–F2, A1, V1–V3, I1, T1–T2, P1, H1–H3, M1–M2) against the diff. Each one is present as the plan wrote it.
- [x] Every rule the plan sets for this run holds.
  - `po-review.md`, `po-qa.md`, `qa.md`, `qa-drivers/`, `po-design.md`, `po-execute.md`, `planner.md`, `method/hooks/`, the root `AGENTS.md`, `.claude/` and `.polype/` are all untouched.
  - `flow.test.sh`, `plan.test.sh`, `planner.test.sh`, `wiring.test.sh` and `design-handoff.test.sh` are unchanged.
  - The phrase "`QA stage` is `surfaces`" appears only in `method/AGENTS.md`.
  - The po-flow "Five signals" bullets and the po-status table header are unchanged.
- [x] The plan's three ways the design could fail:
  - The grep for old wording ("text shows a", "`QA stage` is `screens`", "screen story", "`QA stage: screens`") across the routing files finds nothing outside `method/AGENTS.md`.
  - The new rule in `method/AGENTS.md` agrees with ADR-0054 ("Surface d'une story", "QA") and with `method/skills/qa-drivers/SKILL.md:19`: a `Surface` line decides, and the story text is read only when the line is missing.
- [x] Every file name, setting and section the changes refer to exists:
  - The `## Not seen` section the review now carries over is real (`method/templates/qa.md:27`, `method/agents/qa.md:39,51`).
  - `QA stage` is in the `Reads settings` line of po-flow, po-orchestrator, po-drive, po-status, the reviewer and the implementer.
  - The `surfaces` value exists in `method/templates/agents-local.md:54`.

## Tests
- [x] Weakened checks: `po-gate floor-guard s80-surface-routing main` exit 0, nothing lowered.
- [x] Tests that only look like coverage: none found.
  - The new tests quote exact phrases and also check that the old wording is gone.
  - The 9 changed assertions each follow a sentence the story rewrote; the plan says "8" but lists 9.
- [x] Number of tests: 6 new test functions plus 9 changed assertions, within `Test budget` 25.
- [x] Tests catch a broken rule (each change was undone, then checked with `git diff --exit-code`):
  1. I removed the "`QA stage` is `surfaces`" clause from `method/AGENTS.md`, then ran `surface-routing`, `qa-gate` and `qa-fleet`. 1 test failed (`qa_follows_the_qa_stage`), 24 passed. The file is restored.
  2. I removed the new paragraph in `method/commands/po-flow.md` that sends a story going to QA to the full track, then ran `surface-routing` and `flow`. 1 test failed (`flow_escalates_a_surface_with_qa`). The file is restored.
  - The final `git diff --exit-code` on the worktree is clean, and the tree is unchanged.

## Values
- [x] The routing values `screen`, `—`, `screens`, `surfaces` and the fallback for a story with no `Surface` line all match ADR-0054 § Decision Outcome and the `QA stage` row of `templates/agents-local.md`.

## Neighbours
- [x] I read the other places that route stories.
  - `po-qa.md:27` and `qa-drivers/SKILL.md:19` keep their own wording, which agrees with ADR-0054. ADR-0058 records this under "Neutral", and both files are outside `Owns`.
  - `po-design.md:11` speaks of "a story with a screen", which matches the new term.

Lenses run: none (the diff changes method markdown and bash tests only: no auth, routes, migrations, lockfiles or server code).

## Findings
- minor — `method/commands/po-flow.md:34`: the general sentence "A missing setting is a stop, never a guess" now also covers `QA stage`, which this story added to the settings po-flow reads.
  - It can be read as stopping every story when `QA stage` is missing.
  - The new rule in `AGENTS.md` and the new po-flow paragraph say a story that would never go to QA carries on.
  - `po-drive.md:24` makes the exception explicit ("`QA stage` excepted"); po-flow does not.
- minor — `method/commands/po-help.md:31`: the help line restates the QA rule ("`screens` (les stories `screen`) ou `surfaces` (toute surface autre que `—`)") and leaves out the fallback for a story with no `Surface` line.
  - ADR-0058 says the rule is not to be restated outside `AGENTS.md`. This text was dictated by the plan (H2) and is a French cheat sheet, not a routing file.
  - So it is a small inaccuracy, not a second rule.

## Not verified
- **How routing behaves in practice.** The tests check only the wording, not whether `/po-drive`, `/po-orchestrator`, `/po-flow`, `/po-status` or a reviewer actually route a real story by its `Surface` line. I ran none of them.
  - What a person should do: once the method is installed, run `/po-drive status` and `/po-status` on a project with `QA stage: surfaces` and stories with `Surface: command`, `Surface: —`, and no `Surface` line. Check that the QA column and the next step match the rule in `AGENTS.md`.
- **Judging a `scene` story.** The new reviewer paragraph on `scene` stories and `## Scene viewpoints` was never tried. No scene story or scene QA report exists to try it on.
- **The installed copies** (root `AGENTS.md`, `.claude/`, `.polype/`) are refreshed after ship. Their content was not reviewed here.
- **The full suite and `tests/overlap.test.sh`** (the no-Killer-SaaS-text check, ADR-0006): I relied on the recorded run (exit 0) and did not rerun them.

Max severity: minor
Ship allowed: yes
