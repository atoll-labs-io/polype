# Research — s32-fleet-consistency

## Structuring facts
- **Wrong assumption, criterion 1.** A lane cannot *perform* the design stage. ADR-0016 records that "une commande ne peut pas s'exécuter dans un subagent" (`docs/decisions/ADR-0016-flotte-un-driver-des-subagents.md:26`) — that is why `planner` exists at all — and `method/agents/` holds only `planner`, `implementer`, `reviewer`, `stories-reviewer`. `/po-drive` has no Write (`method/commands/po-drive.md:4-11`). So the lane can insert the design stage only as a named stop for a human `/po-design <id>`, unless the story buys a `designer` subagent, which lives outside its `Owns`.
- The lane's dispatch list is unconditional: "Per lane, in this order" sends `planner`, `implementer`, `reviewer` (`method/commands/po-drive.md:72-76`), and the Resuming table (`:42-50`) has no design row — a story with a screen goes straight from plan to code. That is defect 12.
- `bin/po-lint` fails open, reproduced: on a `method/` holding only `templates/agents-local.md`, `ls` errors three times, `breaches` stays 0 and the script prints `po-lint: no breach in method/` and exits 0. Cause: `method_files() { ls … ; }` (`bin/po-lint:72`) feeds three `while read` loops whose exit status nobody reads, then `:177-181` concludes from `breaches` alone. That is defect 13.
- The matrix contradicts itself in four places against D17: D17 says the state comes "des worktrees et de git (ADR-0016)", the tracker being optional visibility (`docs/parite-killer-saas.md:66`), while B02 (`:28`), G06 (`:97`), T3 (`:115`) and the "Flotte parallèle" bullet (`:122`) still put the state in the tracker. D17's wording is pinned by a test (`tests/fleet-wiring.test.sh:94-96`), so D17 is the voice the others align on. That is half of defect 14.
- `docs/conception.md:96-109` lists ADR-0001 to ADR-0015 and links ADR-0014 as live, while its own frontmatter says `status: superseded` / `superseded-by: [ADR-0017]` (`docs/decisions/ADR-0014-checkpoints-groupes.md:3,9`). ADR-0016 and ADR-0017 are absent from the index. That is the other half of defect 14.

## Story
s32 closes the three M3 defects the reviews left open (`docs/defauts.md:27-29`).
1. `drive_lane_includes_design_when_the_story_has_a_screen` — the lane inserts the design stage between the plan and the implementation, under `/po-design`'s own conditions (design system present, `Design source` decided); without them the lane stops and says so, it never skips the stage.
2. `lint_fails_when_it_reads_nothing` — `bin/po-lint` exits non-zero when listing the method files fails or returns none, and never prints a favourable summary then.
3. `lint_reports_how_many_files_it_read` — the summary states the count, checked on an empty directory and on the real tree.
4. `matrix_and_adr_index_agree_on_the_fleet` — the matrix speaks with one voice on where the fleet state lives, and `docs/conception.md` presents ADR-0017 as living, ADR-0014 as superseded.

## Current code
- `method/commands/po-drive.md` (117 lines) — checks, ready set, Resuming table, wave (preparing lanes, dispatching), grouped plan validation, verdict and fix runs, serial ships, report. `Reads settings:` at `:14` lists nine settings; `Design source` is not among them.
- `bin/po-lint` (182 lines) — `set -u`, no `set -e`, no `pipefail`. Shared parsers `:23-70`, `method_files` `:72`, three rules (`check_settings :87`, `check_tools :112`, `check_fail_closed :153`), each iterating `< <(method_files)` at `:103`, `:144`, `:170`. Summary `:177-181`, exit status from `[ "$breaches" -eq 0 ]`.
- `tests/lint.test.sh` (93 lines) — `mutant()` copies `$METHOD` into a temp dir (`:11-16`), `lint_on` captures status and output (`:18`), `reports_one` demands exactly one line matching `: \[` (`:25-33`). Four tests, one per rule plus the suite check.
- `tests/drive.test.sh` (111 lines) — five tests over `## <heading>` sections of `po-drive.md`.
- `docs/parite-killer-saas.md` (130 lines) — sections A to H, then "Tensions tranchées" and "Au-delà de Killer SaaS".
- `docs/conception.md` — the ADR index at `:96-109`.
- `docs/defauts.md` — M2 table `:8-23`, M3 table `:25-35`.

## Attachment points
- Design stage: the `### Dispatching` numbered list (`method/commands/po-drive.md:72-76`) and the Resuming table (`:42-50`); `Reads settings:` (`:14`) gains `Design source`.
- Lint: `method_files` (`bin/po-lint:72`) becomes one evaluated list with its count, checked before the rules run; the summary (`:177-181`) carries the count.
- Matrix: cells B02, G06, T3 and the "Flotte parallèle" bullet; D17 is not touched.
- Index: `docs/conception.md:109` plus two new lines for ADR-0016 and ADR-0017.

## Verified interfaces
- `/po-design`'s conditions, to cite exactly: `docs/design-system.md` missing inside the worktree → stop and point to `/po-design-system`; `Design source` is `—` → stop and ask a human to choose `internal` or `external`; the story has no screen → say so and stop (`method/commands/po-design.md:23-28`). It writes `docs/designs/<id>/design.md`, uncommitted, committed by the implementer (`:33-35`).
- `/po-orchestrator` puts design at stage 3, **before** the plan, and requires `docs/design-system.md` and a `Design source` before any worktree exists (`method/commands/po-orchestrator.md:31,46-48`).
- `planner` escalates a story with a new screen to the full track (`method/agents/planner.md:31`) and may write only `docs/research/<id>.md` and `docs/plans/<id>.md` (`:21`) — it will not produce a design.
- `Design source` exists in the settings template, so `Reads settings:` may name it (`method/templates/agents-local.md`, fenced block).
- `template_settings` and `lacks_tool`/`needs_tool` live in `tests/lib.sh:18-34`; `contains` is exact and case-sensitive (`:43`).
- `po-lint` exit codes today: 2 when the method directory does not exist (`bin/po-lint:12`), 1 on breaches, 0 otherwise.

## Traps
- `tests/drive.test.sh:45-47` asserts the dispatch order is exactly `planner implementer reviewer ` by scraping `subagent_type: <name>`. Criterion 1 changes that clause, so this test changes with it — it is in `Owns`, and the change must be stated.
- `tests/fleet-wiring.test.sh:83-96` demands A02, D05, D09, D16, D17 keep a `fait — ` status and pins D17's Polype cell verbatim. Rewriting B02, G06 or T3 must not reformat those rows.
- `tests/lint.test.sh:28-32` counts lines matching `: \[` and requires exactly one on a mutant: a "read N files" summary must not contain `: [`.
- `tests/lint.test.sh:35-39` runs the lint on the real `method/` and demands exit 0 — the new count check must not fire there (22 files today).
- `mutant()` copies the whole `method/`, so a count assertion on a mutant sees the same number as the real tree; the empty-directory case needs a directory built by hand.
- `bin/po-lint` has no `set -e` and no `pipefail`: a failing `ls` inside a process substitution is invisible unless its status is captured explicitly.
- `docs/decisions/` is **not** in `Owns`. Defect 16 (`docs/defauts.md:31`) is precisely a story that edited an ADR outside its scope — s32 must not repeat it, so ADR-0003 and ADR-0016 stay untouched.
- The overlap test only scans `method/` (`tests/overlap.test.sh`), but the new prose in `po-drive.md` is inside its scope.
- The pre-commit hook refuses code on `story/<id>` without `validated: yes` in `docs/plans/<id>.md`.

## Open questions
- **Who performs the design in a lane?** Research's reading: the lane stops at a named checkpoint — "a story with a screen whose `docs/designs/<id>/design.md` is missing goes no further than the plan; run `/po-design <id>` in that worktree" — and the next wave, finding the file, resumes at the code stage. The alternative, a `designer` subagent, needs a new `method/agents/designer.md` and an ADR, both outside `Owns`. The plan decides; if it takes the checkpoint, a defect should be filed for the missing subagent.
- **Design after the plan.** The story places the stage between plan and implementation, while `/po-orchestrator` places it before the plan so the screen tasks can cite it. The planner is atomic (research + plan in one subagent), so the lane cannot interleave. Does the plan then get revisited once the design lands? `po-drive.md:58` says a recorded stage is resumed, never replayed — so probably not, and the consequence should be written down rather than left implicit.
- **Two ADR inconsistencies s32 cannot fix.** ADR-0003 is `accepted` and says the state lives in the tracker, which is what the matrix is being aligned *away* from; ADR-0016, which the matrix cites as the living decision, is still `status: proposed` though M3 implemented it. Both belong in `docs/defauts.md` (in `Owns`), not in an edit to `docs/decisions/`.
- Should `lint_reports_how_many_files_it_read` print the count on the failure path too? Criterion 3 says the summary states the count on an empty directory as well, which reads as: yes, even when the run fails for having read nothing.

## Complexity
Story: 3 → after reading the code: 3. Three independent edits, each small; the only real thinking is the design stage, and ADR-0016 already narrows it to one workable shape.

## Split
Not needed.
