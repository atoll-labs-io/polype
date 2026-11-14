---
validated: yes
---
# Plan — s173-drive-executes-next

[Story](../stories.md) · [Research](../research/s173-drive-executes-next.md)

Branch `story/s173-drive-executes-next`, rebased on `main` at 758c061. Read `docs/research/s173-drive-executes-next.md` first, then `## Research amendments` below. The research was written before the owner's answers of 2026-11-14. The planner contract forbids rewriting it, so this plan corrects it instead.

## Research amendments
The research said this; since 758c061 it is no longer true:
- "Stop before the plan: `Owns` too narrow." Since 5a2cca4, `Owns` holds every test file the research named, plus `bin/po-lint`, `tests/execute.test.sh`, `tests/design-handoff.test.sh` and `tests/lint.test.sh`.
- Q1 is settled: option (b), ADR-0120 (`accepted`). `/po-execute` may run `po next` and that verb only. Without `po`, or when `po` exits 2, it refuses the fix run and names the installer.
- Q2: a story missing from the start point is now held by `po next` with reason `framing` and `ref` the start point (s175; case `a_wave_04`, `tests/fixtures/driver-cases/a-wave.cases:38-53`). Two rules stay in `/po-drive`'s prose, as the reworded criterion `drive_executes_what_it_reads` asks: a closed pull request goes to a human (#286), and a failed ship goes back to a fix run.
- Q3: a `held` item of reason `owns` carries `entry`, `ref_entry` and `path` (`po/src/next/mod.rs:21-36`, `docs/interface-agent.md:86`). The report reads them and never recomputes the overlap.
- `tests/execute.test.sh:11` still passes with a narrowed `Bash(…)` line, because `lacks_tool` matches the exact name `Bash` (`tests/lib.sh:28-30`). It stays unchanged. `tests/design-handoff.test.sh:28` compares the whole tool list and does change.
- `bin/po-lint:142-147` never caught a narrowed `Bash(…)`: its `case` matches the exact word `Bash`. The test was run on a scratch copy: a mutant declaring `Bash("…/po" next:*)` passes the lint today.
- Complexity: the story is now rated 4, as the research scored it.

## Story
`/po-drive` runs `po next`, does the action of each line through the command or subagent it names, and starts again. It describes no routing rule except the two that `po` cannot see, and it fits in 2,500 words (5,356 now). Run on its own, `/po-execute` reads `po next` through a permission that names that verb only (ADR-0120). It refuses a fix run when the story's action is `ask` (#139), and also when `po` is missing or exits 2, naming the installer. `bin/po-lint` accepts that one line and refuses any other shell for `/po-execute`. Without `po`, or when `po` exits 2, `/po-drive` stops and names the installer. Tests in `Owns` lose the assertions that pinned a routing phrase now replaced by s168's cases, and the suite passes.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| The exception for `/po-execute` in `bin/po-lint` | already in this repository: the `tools` rule, `bin/po-lint:117-156`, gets one guard line and one more `case` arm | — |
| The `po next` permission line | already in this repository: the same shape as `method/commands/po-review.md:10-11` | — |
| Everything `/po-drive` routed | already in this repository: `po next` (`po/src/next/`), its cases in `tests/fixtures/driver-cases/` | — |
| Recording reports | already in this repository: `po record review\|qa` (s167), as `/po-review` `## Recording` and `/po-qa` say | — |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/drive-executes-next.oracle.test.sh` | `1028105667 2939` |

| Criterion | Test |
| --- | --- |
| `drive_holds_in_2500_words` | `test_drive_holds_in_2500_words`: `LC_ALL=C wc -w` of `po-drive.md` ≤ 2500 |
| `execute_refuses_a_shape_blocked_fix` | `test_execute_refuses_a_shape_blocked_fix` covers the part a script reads. `po-execute.md` declares exactly Read, Glob, Grep, Agent and `Bash("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" next)`, and keeps the description `po-lint` keys on. `po-lint` passes on the tree. On mutants it reports one `[tools]` breach at the line of `Bash`, `Write`, `po next:*`, `po record review:*`, or `po":*` swapped in for the allowed line. The refusal itself is read by a model: judged in review. |
| `drive_executes_what_it_reads` | — rule read by a model: judged in review; candidate for a `po-eval` control arm |
| `drive_stops_without_po` | — same: judged in review; candidate for a `po-eval` control arm |
| `phrase_tests_give_way_to_cases` | — the assertions removed are listed in task 6, and the proof is the full suite through `po-run` |

`po-eval` control-arm candidates (#208): `drive_executes_what_it_reads`, the refusal part of `execute_refuses_a_shape_blocked_fix`, and `drive_stops_without_po`.

## Tasks
1. [x] **`bin/po-lint`, the one shell of `/po-execute`.** Add `PO_NEXT_TOOL='Bash("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" next)'` above `check_tools`. In the `cannot edit files or run a shell` branch (`bin/po-lint:142-147`), make two changes: skip the tool when `rel` is `commands/po-execute.md` and the tool equals `PO_NEXT_TOOL`, and extend the `case` to `Write|Edit|Bash|Bash\(*)`. The message stays the same. Comment the guard in one line citing ADR-0120. Test: `test_execute_refuses_a_shape_blocked_fix` (it fails today, since a narrowed Bash passes), plus `tests/lint.test.sh` as it stands (its `:75-78` mutant still gets the same message).
2. [x] **`method/commands/po-execute.md`.**
   - Frontmatter: add `  - Bash("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" next)` after `  - Agent`.
   - `description`: keep the phrase `cannot edit files or run a shell`, ending with `, except po next (ADR-0120)`.
   - Line 16: say it has no Write or Edit tool, and that its one shell command is `po next`, which only reads.
   - Precondition 6: the last verdict of `docs/reviews/<id>.md` is `Ship allowed: no` → run `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" next` exactly so, from where the command was started (no `cd`), and read the entry whose `story` is `<id>`.
     - `fix` → a **fix run**, the review's findings first.
     - Any other action → no fix run: stop with the action and its reason, pointing to `/po-qa <id>` for `qa`, `/po-review <id>` for `review`, and a person for `ask` ("no fix run is spent").
     - `po` missing, exiting 2, or listing no entry for `<id>` → stop with no fix run and name `polype install`, never falling back to reading the review's `Next action:` yourself.
     - The two QA stops of today's precondition 6 go away: `po next` answers `qa` or `review` for those states (cases `resuming_11`, `resuming_15`, `verdict_01`).
   - The file does not grow: at most 854 words (`LC_ALL=C wc -w`).

   Tests: the oracle, `test_execute_does_not_grow` (task 7), and `tests/design-handoff.test.sh:27-29`, where the expected list becomes ``"Agent Bash(\"\${CLAUDE_CONFIG_DIR:-\$HOME/.claude}/polype/po\" next) Glob Grep Read "`` (the `lacks_tool` loop stays). Also `tests/qa-fleet.test.sh:152-157`: drop the two `po-execute.md` holds and keep the `po-flow` ones.
3. [x] **`method/commands/po-drive.md`, its frame and its loop.**
   - `Reads settings`: keep `Target branch`, `Worktree root`, `Install`, `Plan validation`, `Max attempts`, `Merge mode`, `Ship confirmation`, `ADR directory`, `Tracker`, `Model strong`, `Model light`, `Light up to`, `Issue tracker`. Drop `Design source`, `Parallel` and `QA stage`, which `po` reads now.
   - Keep the intro sentence `You have neither Write nor Edit, so you write no code and decide no verdict`.
   - `## Checks`: keep the existing bullets except the `QA stage` one. Add one: `po` missing, or `po next` exiting 2 → stop, name `polype install`, and route nothing yourself.
   - Replace `## The ready set` and `## Resuming` with one section, `## The next action`:
     - Run `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" next` from where you were started. Each entry of `actions` is one thing to do. Run `po next` again once a stage's answers are recorded, and stop when every entry is `wait` or `ask` and `ready` is empty.
     - A table, action → what you do:
       - `plan`: prepare the worktree first when the story has none (reason `ready`), then the planner.
       - `validate-plan`: `## Validating a wave's plans`.
       - `design`: the designer.
       - `execute` and `fix`: the implementer, the fix-run sentence for `fix`.
       - `qa`: the qa subagent. Reason `QA evidence not committed` → `po record qa <id>` on the report on disk, then the `<id>: QA evidence` commit, with no walk.
       - `review`: the reviewer with the `Fix loop:` `/po-review` computes.
       - `ship`: `/po-ship`. Reason `landed` → its cleanup, taking no slot and no place in the serial order.
       - `wait`: nothing, reported.
       - `ask`: the person at once, with the reason.
     - `held` and the `orphan-worktree` warnings go to the report as `po` gives them.
     - Then the two rules `po` does not see. First, under `Merge mode: pr`, a lane whose action is `ship`, or `wait` with reason `merge waiting`, and whose `gh pr view story/<id> --json state --jq .state` prints `CLOSED`, goes to a human (#286). Second, a ship that fails sends its story back to a fix run under the same `Max attempts` cap.
     - Keep `A stage already recorded is resumed, never replayed.` (`method/agents/designer.md:49` and `method/agents/planner.md:42` point here).
   - Test: `test_drive_holds_in_2500_words` once task 5 is done. The rest is judged in review.
4. [x] **`po-drive.md`, `## A wave`.**
   - `### Preparing the lanes`: worktree creation from `<start point>`. Drop the `git show` check and the "framing pull request" paragraph: `po` holds such a story with `framing`.
   - Orphans: reported from the `orphan-worktree` warning and never repaired; keep the sentence beginning `you run no \`git worktree add --force\``.
   - Keep the absolute-paths paragraph and the ADR-numbering paragraph as they are.
   - `### Dispatching`: keep the overlap paragraph, the dispatch lines (`subagent_type: <role>` and `` `Model strong` `` on the same line; the implementer line with `` `Model light` up to `Light up to`, `Model strong` above ``), the model-refusal sentence, and the human-stop paragraph (` Meanwhile the other lanes carry on.` must stay, once, for `tests/ship-and-fleet-cleanup.test.sh:82`).
   - Drop from the dispatch steps whatever routes: `Root cause` in step 1, design conditions and skipping in step 2, `goes to QA` in step 4.
   - Test: `tests/drive.test.sh`, `tests/model-routing.test.sh`, `tests/escalation-contract.test.sh` as task 6 leaves them.
5. [x] **`po-drive.md`, the rest.**
   - `## Validating a wave's plans`: unchanged, minus the `Technical choice` paragraph (`po` answers `ask`).
   - `## The verdict, and the fix runs`: recording only. The answer goes through `po record review <id>` as `/po-review` `## Recording` says, re-ask and stops included. Keep the verbatim and blocked-fallback sentences. Drop the QA return, the fix-run decision and `Max attempts`, which `po` computes.
   - `## Ships, one at a time`: keep the serial and gate sentences; drop the "order the reviews passed" sentence (`po` gives one `ship`).
   - `## The decisions log`: unchanged.
   - `## Report`: what `po next` returned; held stories with their `reason` and `ref`, plus `entry`, `ref_entry` and `path` for `owns`, and `framing` with its start point. Keep the activity-window, models, approval, design and pull-request lines. `status` runs `po state` and launches nothing.
   - Then cut until `wc -w` ≤ 2500. A kept sentence may be reworded only if task 6 then drops its assertion.
   - Test: `test_drive_holds_in_2500_words`.
6. [x] **Tests in `Owns` give way.** Delete these assertions on `po-drive.md`, which pin a routing rule a case of s168 now holds. A function left with nothing is deleted. A file left with no function is deleted (`tests/run.sh` fails a file with none).
   - `resume.test.sh`: `test_drive_resumes_from_what_exists` and `test_drive_status_reports_lanes`. In `test_drive_detects_an_orphan_worktree`, keep only the never-repaired holds that survive verbatim.
   - `drive.test.sh`: `test_drive_picks_a_ready_set_without_conflicts`, `test_drive_resume_table_is_complete_and_ordered`, `test_drive_sends_a_stale_review_back_to_review`, and in `test_drive_ships_serially_after_each_review` the `verdict` holds (`:88-91`).
   - `drive-guards.test.sh`: `test_pr_wait_needs_effective_human`. In `test_lane_checks_its_start_point`, drop the `git show` and `framing` holds and keep the report line if it survives.
   - `fleet-design.test.sh`: `:61` (`no designer is dispatched`), `:66-71`, `:89-95`.
   - `escalation-contract.test.sh`: `:59-71` (the resume rows and the `Validating` marker).
   - `defect-and-routing-paths.test.sh`: `:38-52`.
   - `qa-fleet.test.sh`:
     - `:48` and `:63`;
     - in `test_drive_wave_includes_qa`, the `for a story that goes to QA` hold;
     - `test_drive_resumes_on_qa_current`;
     - `:120-123`, `:140-142`, `:170`;
     - in `test_drive_resumes_on_an_uncommitted_report`, everything but its `po-gate.sh` line.
   - `review-findings-shape.test.sh`: `:86-92` and `:141-142`.
   - `ship-follows-forge.test.sh`: `:94-103`.
   - `surface-routing.test.sh`: `:33-35`.
   - `owns-overlap.test.sh`: the `po-drive` holds `:18` and `:36` (and `$DRIVE` from the `require_file` loop), and `test_drive_reports_name_the_entries`.
   - `docs-and-eval-cleanup.test.sh`: `$DRIVE` out of the `:52` loop, and `:67-73`.
   - `short-subject-shipped.test.sh`: `po-drive` out of the `:26` loop.
   - `ship-and-fleet-cleanup.test.sh`: `:42-43`, `:47`, and the dispatch mutation `:97-111`.
   - `plan-and-defect-paths-cleanup.test.sh`: `:78`.
   - `everything-in-issues.test.sh`: `:50`.

   Every other assertion on these files stays. A non-routing phrase that tasks 3-5 reworded loses its assertion, listed in the record, and no new phrase test is written (`AGENTS.local.md`, Direction). `grouped-validation`, `model-routing`, `qa-report-returned-as-text` and `fleet-wiring` should need no change. Test: each touched file passes alone (`bash tests/run.sh <file>`).
7. [x] **`tests/drive-executes-next.test.sh`**, holding one test, `test_execute_does_not_grow`: `LC_ALL=C wc -w` of `method/commands/po-execute.md` ≤ 854 (#241 m7; Direction: no words added without as many removed). Then the full suite through `po-run --story s173-drive-executes-next --label suite -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- Empty diff on: `po/` (the crate), `tests/fixtures/driver-cases/`, `tests/driver-next-action.oracle.test.sh`, `method/commands/po-orchestrator.md`, `po-flow.md`, `po-review.md`, `po-qa.md`, `po-status.md`, `po-retro.md`, `method/AGENTS.md`, `method/agents/`, `docs/interface-agent.md`, `.claude/`, `.polype/`.
- `tests/drive-executes-next.oracle.test.sh` keeps the sum above; any change goes through `## Oracle changes` of the record.
- No new assertion quoting a phrase of `po-drive.md` or `po-execute.md` (Direction). The only new tests are the oracle and `test_execute_does_not_grow`.
- No `Bash` permission other than the exact `po next` line in `po-execute.md`; no `cd` in that command; the bare word `Bash` must not appear in its tools.
- `docs/research/s173-drive-executes-next.md` is not rewritten.

## The pivot
That `po next`, plus the two prose rules, routes every lane exactly as the 19-row table did. How it could be wrong:
- **An action's reason carries a branch that the table loses.** `qa` with `QA evidence not committed` and `ship` with `landed` behave differently from the plain action. Compare the new table to cases `resuming_11`, `resuming_21` and `ships_04`.
- **The permission line does not match the command the model really types** (ADR-0120, "Bad"). Then `/po-execute` asks for confirmation instead of reading. Compare the frontmatter string with the command written in precondition 6, character for character; the first real run confirms it.
- **The word cap pushes out a non-routing rule.** Overlap, human stops, ADR numbering and absolute paths are all at risk. Compare the old and new `po-drive.md` section by section against `## What goes to the person` and Law 4 of `method/AGENTS.md`.

## Files touched
`bin/po-lint`, `method/commands/po-execute.md`, `method/commands/po-drive.md`, `tests/drive-executes-next.oracle.test.sh` (already written), `tests/drive-executes-next.test.sh` (new), and the tests of task 6 plus `tests/design-handoff.test.sh` and `tests/qa-fleet.test.sh`. Possibly deleted: `tests/resume.test.sh`.

## Test strategy
- Oracle: 2 tests (word cap; `/po-execute`'s one shell, through `bin/po-lint` on mutants, the layer that reads it).
- Story test: 1 (`po-execute.md` does not grow).
- Existing tests: assertions deleted per task 6, `design-handoff:28` updated; no new phrase test. Total new: 3, within `Test budget` 25.
- Routing is covered by s168's 56 cases (`tests/driver-next-action.oracle.test.sh`), which this story does not touch.
- Judged by reading: the three criteria above, candidates for `po-eval`.
- Full suite once at the end through `po-run`. No type check (`Typecheck: —`).

## Done when
One commit `s173-drive-executes-next: …` on `story/s173-drive-executes-next` with the plan, the research, the oracle and the code; full suite green in `docs/verif/s173-drive-executes-next.md`; review with no open critical; landed through a pull request.
