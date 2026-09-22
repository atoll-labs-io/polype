---
validated: yes
---
# Plan — s32-fleet-consistency

Branch `story/s32-fleet-consistency`. Read `docs/research/s32-fleet-consistency.md` first; this plan builds on it without repeating it.

## Story
Close the three M3 defects the reviews left open (`docs/defauts.md:27-29`): a lane that skips the design stage, a linter that certifies a tree it never read, and documents that contradict each other on the fleet.

1. `drive_lane_includes_design_when_the_story_has_a_screen` — the lane inserts the design stage between the plan and the implementation, under `/po-design`'s conditions; without them it stops and says so, never skipping.
2. `lint_fails_when_it_reads_nothing` — non-zero exit and no favourable summary when the listing fails or yields nothing.
3. `lint_reports_how_many_files_it_read` — the summary carries the count, on an empty tree as on the real one.
4. `matrix_and_adr_index_agree_on_the_fleet` — one voice on where the fleet state lives; ADR-0017 living, ADR-0014 superseded.

## Tasks
1. [x] `bin/po-lint` — evaluate the method file list **once**, into `METHOD_FILES`, with `ls … 2>/dev/null` whose failure is caught, and derive `METHOD_FILE_COUNT` from it (0 on an empty list). Replace the three `< <(method_files)` at `:103`, `:144`, `:170` by `<<< "$METHOD_FILES"`. — test: `lint_fails_when_it_reads_nothing`.
2. [x] `bin/po-lint` — before the rules run, a count of 0 prints `po-lint: read 0 file(s) in <dir>/: nothing was checked` on stderr and exits 2, never reaching the breach summary. — test: `lint_fails_when_it_reads_nothing`.
3. [x] `bin/po-lint` — both summary lines carry the count: `po-lint: no breach in <n> file(s) of <dir>/` and `po-lint: <b> breach(es) in <n> file(s) of <dir>/`. No summary line may contain the substring `: [`, which `reports_one` counts (`tests/lint.test.sh:29`). — test: `lint_reports_how_many_files_it_read`.
4. [x] `tests/lint.test.sh` — add `test_lint_fails_when_it_reads_nothing`: build a method tree holding only `templates/agents-local.md` plus empty `commands/` and `agents/`, assert a non-zero status and that the output holds neither `no breach` nor `breach(es)`.
5. [x] `tests/lint.test.sh` — add `test_lint_reports_how_many_files_it_read`: on the real `method/`, the summary holds `<n> file(s)` for `n` counted by the test itself; on the empty tree of task 4, it holds `0 file(s)`.
6. [x] `method/commands/po-drive.md` — insert the design stage in `### Dispatching`, between the planner item and the implementer item, as a stage the lane **stops at** rather than dispatches: a story with a screen whose `docs/designs/<id>/design.md` is absent goes no further than its plan; the report names `/po-design <id>` to run in that worktree, and the next wave, finding the note, resumes at the code stage. `/po-design`'s own conditions are cited and checked first — `docs/design-system.md` missing in the worktree, or `Design source` at `—` → the lane stops naming what is missing (`/po-design-system`, or a human choosing `internal` or `external`), and in no case does the implementer start. Say plainly why the lane cannot do it itself: a command does not run inside a subagent (ADR-0016) and no design subagent exists. — test: `drive_lane_includes_design_when_the_story_has_a_screen`.
7. [x] `method/commands/po-drive.md` — a row in the Resuming table (`:42-50`) for a story with a screen, plan validated and `docs/designs/<id>/design.md` absent → the design stage; and `Design source` added to the `Reads settings:` line (`:14`). Keep the `subagent_type:` occurrences at three, in the order `planner implementer reviewer`, which `tests/drive.test.sh:45-47` asserts. — test: `drive_lane_includes_design_when_the_story_has_a_screen`.
8. [x] `tests/drive.test.sh` — add `test_drive_lane_includes_design_when_the_story_has_a_screen`: the wave section names the design stage between plan and implementation, names both of `/po-design`'s conditions, says the stage is never skipped; the Resuming section holds a `docs/designs/<id>/design.md` row; `settings_read_by` yields `Design source`.
9. [x] `docs/parite-killer-saas.md` — align B02 (`:28`), G06 (`:97`), T3 (`:115`) and the "Flotte parallèle" bullet (`:122`) on D17: the fleet state is derived from the worktrees and git (ADR-0016), the tracker of ADR-0003 being optional visibility. D17's row stays byte-for-byte as it is. — test: `matrix_and_adr_index_agree_on_the_fleet`.
10. [x] `docs/conception.md` — in the ADR index (`:96-109`), strike ADR-0014 as ADR-0013 already is and point it at ADR-0017; add a line for ADR-0016 (noting it is still `proposed`) and one for ADR-0017. — test: `matrix_and_adr_index_agree_on_the_fleet`.
11. [x] `docs/defauts.md` — 12, 13 and 14 become `corrigé par s32`; three rows added: ADR-0003 (`accepted`) still puts the state in the tracker where the matrix now cites ADR-0016; ADR-0016 is `status: proposed` though M3 implemented it; the fleet has no design subagent, so a story with a screen cannot run a lane end to end. — no test: this is the issue tracker (Law 7), not a rule.

## Run interdicts
- `docs/decisions/` ends with an empty diff — defect 16 is exactly that mistake, and no ADR is in this story's `Owns`.
- `method/agents/` ends with an empty diff: no `designer` subagent here; it is recorded as a defect instead.
- `method/AGENTS.md`, `method/commands/po-status.md`, `method/commands/po-help.md`, `method/templates/agents-local.md` end with an empty diff (s31's, and `Design source` already exists).
- The D17 row of `docs/parite-killer-saas.md` and the whole of `tests/fleet-wiring.test.sh` end with an empty diff.
- Defects 15, 17, 18, 19, 20 and 21 stay `ouvert`: they are not this story's.
- Do not run `bin/polype-dev-install`: it would rewrite the installed `.polype/` copy inside the worktree.
- No existing test function is renamed or deleted; the 161 that pass today keep passing.

## The pivot
**The design stage in a lane is a named stop, not a dispatch.** ADR-0016 says a command cannot run inside a subagent, and `/po-design` has no subagent, so the lane can only refuse to go past the plan and name the command a human runs in that worktree.

Three ways this could be wrong, and what to compare against:
- The story says the lane *inserts* the stage; if "insert" was meant as "perform", the right answer is a `designer` subagent — compare with `method/agents/planner.md`, born of the very same constraint (ADR-0016 consequences), and with this story's `Owns`, which holds no agent file.
- A stop at every story with a screen makes the fleet useless on a UI project — compare with `/po-orchestrator`, the single-story path, which stays available and does run `/po-design`.
- The design lands *after* the plan, so the plan's screen tasks cannot cite it, unlike `/po-orchestrator` stage 3 before stage 4 — compare with `po-drive.md:58`, "a stage already recorded is resumed, never replayed", which forbids re-running the planner. The consequence is written into the command rather than left implicit.

## Files touched
- `bin/po-lint`
- `method/commands/po-drive.md`
- `tests/lint.test.sh`, `tests/drive.test.sh`
- `docs/parite-killer-saas.md`, `docs/conception.md`, `docs/defauts.md`
- evidence: `docs/research/s32-fleet-consistency.md`, `docs/plans/s32-fleet-consistency.md`, `docs/verif/s32-fleet-consistency.md`

## Test strategy
One layer only: bash document tests over the method files and the tooling, the repository's single layer. Three new tests for three criteria, well inside `Test budget: 25`.

| Criterion | Test | File |
| --- | --- | --- |
| `drive_lane_includes_design_when_the_story_has_a_screen` | `test_drive_lane_includes_design_when_the_story_has_a_screen` | `tests/drive.test.sh` |
| `lint_fails_when_it_reads_nothing` | `test_lint_fails_when_it_reads_nothing` | `tests/lint.test.sh` |
| `lint_reports_how_many_files_it_read` | `test_lint_reports_how_many_files_it_read` | `tests/lint.test.sh` |

`matrix_and_adr_index_agree_on_the_fleet` gets no new test: `tests/fleet-wiring.test.sh:94-96` already pins the voice the other rows align on, and a test that greps a prose cell for the absence of the word "tracker" would break on any honest rewording. The proof is the diff and the review.

The two lint tests must bite where a green run proves nothing (`tests/lint.test.sh:2-4`): each builds a tree the current script certifies as clean, so both fail against today's `bin/po-lint`.

Both the full suite (`bash tests/run.sh`) and `bash bin/po-lint` run at the end of the execute stage.

## Done when
- One commit on `story/s32-fleet-consistency` carrying the code, the tests and the evidence.
- `bash tests/run.sh` green — 161 existing plus 3 new — and `bash bin/po-lint` exits 0 on the real `method/` while printing its file count.
- Defects 12, 13 and 14 closed in `docs/defauts.md`, the three new ones recorded.
- A review with no open critical finding.
