---
validated: yes
---
# Plan — s33-real-parallelism

Branch `story/s33-real-parallelism`. Read `docs/research/s33-real-parallelism.md` first; this plan builds on it without repeating it.

## Story
The fleet must keep its parallelism promise: a whole stage of a wave leaves in one message, the driver never drifts from its directory, and ADR numbers stop being a race between lanes. Criteria, verbatim from `docs/stories.md`:

1. `drive_dispatches_a_whole_stage_in_one_message`
2. `drive_reports_what_it_observed_not_what_it_intended`
3. `drive_uses_absolute_paths_only`
4. `shared_numbering_is_assigned_by_the_driver`

The research corrected one thing the story assumed: the numbers 22, 23, 24 name two different sets of defects (`docs/defauts.md:37-39` and `:45-47`). Task 1 renumbers the fleet-validation rows to 25, 26, 27; the story's `Corrige` line is then read as 25-27.

## Tasks

1. [x] **`docs/defauts.md` — give the fleet-validation defects their own numbers.** In the table under `## Relevés par la validation de la flotte (2026-09-22)` (`:41-47`), change the `#` cells `22`, `23`, `24` to `25`, `26`, `27`. Nothing else in the file changes in this task. *Check:* `grep -oE '^\| [0-9]+ \|' docs/defauts.md | sort | uniq -d` prints nothing, recorded in the verification note.

2. [x] **`method/commands/po-drive.md` — the driver never moves (criterion 3).** Add a paragraph directly under the `## A wave` heading (`:61`), before `### Preparing the lanes`, saying: the driver stays in the directory it was started in and never changes directory — no `cd`, at any stage; it resolves each lane's worktree once as the absolute path `<repository root>/<Worktree root><id>`; every git command is `git -C <absolute path>`; every subagent prompt carries that absolute path; and the reason — a driver whose working directory drifted addresses one lane with another lane's path, a mistake its own report cannot show. **Write no shell `cd` example anywhere in this file**: the test reads a backquoted `cd` followed by a space as a command the driver is allowed to run. *Test:* `test_drive_uses_absolute_paths_only`.

3. [x] **`method/commands/po-drive.md` — the driver hands out the ADR numbers (criterion 4).** At the end of `### Preparing the lanes` (`:63-68`), add the allocation rule: ADR numbers are a shared resource no `Owns` line can divide, two lanes reading `docs/decisions/` at the same time both find the same highest number; so the driver assigns them before the wave leaves, reading the highest `ADR-NNNN` on `Target branch` and handing each lane of the wave its own number, the following ones in sequence, in the order of `docs/stories.md`. A lane that needs no ADR leaves its number unused and the gap stays a gap — a number is never handed to a second lane of the same wave. A lane needing more than it was given says so in its answer and writes none beyond its reservation. *Test:* `test_shared_numbering_is_assigned_by_the_driver`.

4. [x] **`method/commands/po-drive.md` — a whole stage in one message (criterion 1).** Extend the dispatch paragraph (`:71`) **without touching its three existing sentences**: state that this holds stage by stage — every planner of a wave leaves together, then every implementer, then every reviewer, a stage being dispatched whole or not at all; that sending one call per message is forbidden; and why — the second call is only written once the first subagent has answered, so the lanes run one after the other and `Parallel` buys nothing. Name no `subagent_type:` in the added sentences (`tests/drive.test.sh:45-47` rebuilds the dispatch order from every occurrence in this section). *Test:* `test_drive_dispatches_a_whole_stage_in_one_message`.

5. [x] **`method/commands/po-drive.md` — the report counts what happened (criterion 2).** Add to `## Report` (`:114-121`), without rewording an existing sentence: the report states, per stage, how many subagents left together in the same message; a stage dispatched one call at a time is reported as sequential with the number of messages it took; and no line of the report claims lanes ran at the same time unless they were dispatched in one message. *Test:* `test_drive_reports_what_it_observed_not_what_it_intended`.

6. [x] **`method/agents/planner.md` — the planner never picks a number (criterion 4).** In `## Limits` (`:49-52`), leave `:50` byte for byte (`tests/planner.test.sh:46` asserts it) and extend the ADR item `:51`: the number is not the planner's to choose, it uses the one the driver reserved for this lane in the message it received; with no number in that message, or more ADRs needed than numbers reserved, it writes the decision in the plan, reports what is missing, and creates no file whose name it invented — two lanes both taking "the next free number" take the same one. *Test:* `test_shared_numbering_is_assigned_by_the_driver`.

7. [x] **`tests/drive.test.sh` — four tests, one per criterion.** Append them after the existing six, reusing `section_of` (`:8`) and `holds` (`:10`):
   - `test_drive_dispatches_a_whole_stage_in_one_message` — on the `A wave` section: the stage-wide scope, the ban on one call per message, and the stated consequence (the lanes run one after the other).
   - `test_drive_reports_what_it_observed_not_what_it_intended` — on the `Report` section: the per-stage count of subagents launched together, and the refusal to claim a parallelism that was not exercised.
   - `test_drive_uses_absolute_paths_only` — `grep -F '`cd ' "$DRIVE"` must find nothing, with a failure message naming the line found; plus the `A wave` section holding the no-drift rule and `git -C <absolute path>`.
   - `test_shared_numbering_is_assigned_by_the_driver` — on `$DRIVE`'s `A wave` section and on `$METHOD/agents/planner.md`: the driver allocates before dispatch, one number per lane, never twice in a wave; the planner takes the reserved number and invents none.

8. [x] **`docs/defauts.md` — close what this story fixed, record what it found.** Set rows 25, 26, 27 to `corrigé par s33`. Add, under a new heading `## Relevés par la recherche de s33 (2026-09-22)` with the same four columns, two rows: n° 28 — `AGENTS.local.md` of this repository declares no `Parallel`, `Max attempts` or `Tracker` (they exist only in `method/templates/agents-local.md:29-31`), so `/po-drive` run here stops on a missing setting; n° 29 — `method/agents/planner.md:50` says the planner writes the research and the plan "and no other file" while `:51` has it write an ADR. Both `ouvert`. *Check:* the uniqueness grep of task 1, re-run.

9. [x] **Run the checks and record them.** `bash tests/run.sh` whole, and `bin/po-lint`, both recorded in `docs/verif/s33-real-parallelism.md` with their output.

## Run interdicts
- `.claude/` and `.polype/` end with an empty diff: they are installed copies of `method/`, refreshed by `bin/polype-dev-install .`, never edited by a story (`git show --stat 040ed47` is the precedent).
- `docs/stories.md`, `docs/parite-killer-saas.md`, `docs/conception.md`, `method/AGENTS.md`, `method/templates/agents-local.md` and everything under `docs/decisions/` end with an empty diff. No new ADR file: `docs/decisions/` is outside this story's `Owns`, and `docs/defauts.md:31` records a past review finding for exactly that overstep.
- These five strings are still present, unchanged, at the end of the run — four of them are asserted by tests that must stay green:
  - `in a single message`, `one Agent call per lane, all of them in that one message`, `Never two calls for the same story at once` (`tests/drive.test.sh:36-38`);
  - `` `/po-design <id>` to run in `<Worktree root><id>` `` (`:130`) — the absolute-path rule is stated once as a rule and rewrites no existing `<Worktree root><id>` mention;
  - `You write \`docs/research/<id>.md\` and \`docs/plans/<id>.md\`, and no other file.` (`tests/planner.test.sh:46`).
- No existing sentence of `## Report` is reworded (`tests/grouped-validation.test.sh:45-46`, `tests/resume.test.sh:48-57` assert six of them).
- No existing test is deleted or weakened; the six tests of `tests/drive.test.sh` keep their assertions.
- No sentence of `method/` is written from a Killer SaaS source (`tests/overlap.test.sh`).

## The pivot
Everything rests on this: **the only thing a story can change here is the text of a command file, and the only thing a test can prove is that the text says it.** The recurring pattern `docs/defauts.md:21` already names the limit — a test that finds a sentence in a prompt proves the sentence exists, not that the agent obeys it. Three ways that could be wrong:

- **The rule is honoured on paper and the fleet is still serial.** A driver can read the ban and still dispatch one call per message. The mitigation is criterion 2, which is why it belongs in the same story: the report can no longer claim a parallelism it did not exercise, so the next sandbox run shows the failure instead of hiding it. Compare against `docs/validation/` — the next fleet run is the real verdict, not this test file.
- **The `cd` assertion catches the wrong thing.** It reads a backquoted `cd` followed by a space as a permission. A driver could keep relative paths without ever writing that token. Compare with the second half of the same test: the `A wave` section must require `git -C <absolute path>` and the once-resolved absolute worktree path, which is what actually removes the drift.
- **Reserving one number per lane leaves holes in the ADR sequence.** A reader may read a missing `ADR-0019` as a lost decision. The alternative — the planner reports it needs one and the driver allocates afterwards — keeps the numbering dense but makes every ADR-bearing lane wait for a round trip, which is the serialisation this story exists to remove. The choice is recorded here rather than in an ADR because `docs/decisions/` is outside `Owns`; it is a human's call whether it deserves one.

## Files touched
- `method/commands/po-drive.md` (tasks 2-5)
- `method/agents/planner.md` (task 6)
- `tests/drive.test.sh` (task 7)
- `docs/defauts.md` (tasks 1, 8)
- committed with the story: `docs/research/s33-real-parallelism.md`, `docs/plans/s33-real-parallelism.md`, `docs/verif/s33-real-parallelism.md`

## Test strategy
Four automated tests, one per acceptance criterion, all in `tests/drive.test.sh`, each named exactly after its criterion. That is 4 of the 25 `Test budget`, bringing the file to ten.

Layer: these are document tests, the only layer this repository has — each asserts a clause of the file under test by quoting a short exact phrase of it, per the repository's conventions. Each clause is checked once, in one test; no test repeats an assertion the six existing ones already make.

Making them bite: every new assertion must fail on the file as it stands today before the corresponding task is done — the implementer writes the test first for each of the four, sees it red, then writes the sentence. `test_drive_uses_absolute_paths_only` bites by construction (a `` `cd `` usage added anywhere in the driver turns it red).

Tasks 1 and 8 carry no test: renumbering rows of the issue tracker is not behaviour. Their check is `grep -oE '^\| [0-9]+ \|' docs/defauts.md | sort | uniq -d` printing nothing, recorded in the verification note.

Visual checks: none, no screen.

Full run at the end of execute (`Full suite: execute-end`): `bash tests/run.sh` and `bin/po-lint`, both recorded.

## Done when
- one commit on `story/s33-real-parallelism` carrying the four method/test edits, the two `docs/defauts.md` edits, and the research, plan and verification notes;
- `bash tests/run.sh` green, the six existing tests of `tests/drive.test.sh` included, and `bin/po-lint` exiting 0;
- `git diff m3-flotte...story/s33-real-parallelism --stat` showing no file outside the story's `Owns` and its own `docs/` evidence;
- a review with no open critical finding;
- squash-merged onto `m3-flotte` as `s33-real-parallelism: <title>`.
