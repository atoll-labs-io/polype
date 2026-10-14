---
validated: yes
---
# Plan — s27-drive

[Story](../stories.md) · [Research](../research/s27-drive.md)

Branch `story/s27-drive`. Read `docs/research/s27-drive.md` first; this plan builds on it without repeating it.

## Story
`/po-drive` advances every ready story in parallel: it computes a conflict-free ready set, dispatches one lane per story (`planner` → `implementer` → `reviewer`), keeps ships serial, and reports. Five acceptance criteria, each a `test_<name>` of `tests/drive.test.sh` (`docs/stories.md:414-420`).

Two decisions the research left open are settled here:

| Question | Decision | Why |
| --- | --- | --- |
| Who records `docs/reviews/<id>.md` in a lane? | The driver, through a Bash heredoc, writing the reviewer's answer **verbatim**. | `reviewer` has `Edit` but not `Write` (`method/agents/reviewer.md:4`) and Edit cannot create a missing file; its agent file belongs to s28. Transcribing is not authoring: the driver still never decides a severity, except the blocked fallback `/po-review` already mandates (`method/commands/po-review.md:35`). |
| Does s27 touch `method/commands/po-help.md`? | Yes — exactly one `/po-drive` line. | Otherwise `test_every_command_listed_in_help` (`tests/pilot.test.sh:38`) is red the moment the command file exists, and `Full suite: execute-end` makes the implementer stop on it. s31 keeps `help_lists_po_drive` as the regression check. |

Out of scope and left as they are: ADR-0016's `proposed` status (no story owns it), the stale D02/D04 matrix cells s26 skipped, `Tracker: github` behaviour.

## Tasks
1. [x] **Declare the fleet settings** in `method/templates/agents-local.md`: inside the Pipeline fence add `Parallel:          3`, `Max attempts:      2`, `Tracker:           none`; under the table add one row each — `Parallel` = lanes running at once, `Max attempts` = fix runs before a story is handed to a human, `Tracker` = `none` · `github` when the repository has a remote. Test able to fail: `settings_template_declares_fleet_settings`, and the existing `structure.test.sh:test_settings_template_one_value_per_line` on the line shape.
2. [x] **Create `method/commands/po-drive.md`** with its frontmatter — `description`, `argument-hint: [status]`, `allowed-tools: Read, Glob, Grep, Bash, Agent, AskUserQuestion` — and the body's first line `Reads settings:` listing in backticks every setting the file uses. No Write, no Edit; do not copy `po-execute.md`'s sentence "cannot edit files or run a shell", which `bin/po-lint:131` would turn against the Bash this command needs. Test able to fail: `drive_never_writes_code_or_verdicts`, plus `lint.test.sh:test_lint_is_part_of_the_suite` and `structure.test.sh:test_every_setting_read_by_a_command_exists_in_template`.
3. [x] **Write the `## Checks` section**: no `AGENTS.local.md` → stop and point to `/po-setup`; no Agent tool → stop; a setting missing → stop; `docs/stories.md` missing → stop. Every arrow whose left side names an absence must say stop or ask (`bin/po-lint:153-171` scans this heading). Test able to fail: `lint.test.sh:test_lint_is_part_of_the_suite`.
4. [x] **Write the ready-set section**: state read from the worktrees and git the way `/po-status` does (`method/commands/po-status.md:22-32`) — never from memory; ready = not shipped, every dependency shipped, and `Owns` paths disjoint both from the lanes already running and from the rest of the chosen batch; the batch is capped at `Parallel`; a story dropped for a conflict is named with the path that collided. Test able to fail: `drive_picks_a_ready_set_without_conflicts`.
5. [x] **Write the wave section**: per lane the driver prepares the worktree itself as `/po-research` does (`method/commands/po-research.md:22-30`) — fetch when a remote exists, `git worktree add -b story/<id>`, copy the ignored `.env*`, run `Install` — because `planner` is forbidden to (`method/agents/planner.md:24`). Then the wave's subagents go out **in a single message**, `planner` for every lane at once, and once a lane's plan carries `validated: yes` its `implementer`, then its `reviewer`, each with the prompt its own command already fixes (`po-execute.md:32-40`, `po-review.md:30`). Test able to fail: `drive_dispatches_lanes_in_one_message`.
6. [x] **Write the verdict and fix-run section**: the reviewer's answer is recorded verbatim into `docs/reviews/<id>.md` through Bash; an answer without both verdict lines is recorded as `Max severity: critical` / `Ship allowed: no`; `Ship allowed: no` sends the lane back to `implementer` in fix mode, findings first, at most `Max attempts` times, after which the story is listed for a human and its lane freed. Test able to fail: `drive_never_writes_code_or_verdicts` and `drive_ships_serially_after_each_review`.
7. [x] **Write the ship section**: ships run **one at a time** in the order the reviews passed, each through `/po-ship`'s gate (`po-gate ship-allowed <id>`), expensive checks, squash and cleanup-on-proof; say that `Merge mode: local` needs the repository root clean and on `Target branch` (`method/commands/po-ship.md:43`), which is why they cannot overlap; honour `Ship confirmation`. Test able to fail: `drive_ships_serially_after_each_review`.
8. [x] **Add the `/po-drive` line to `method/commands/po-help.md`**, in the `## Outils` section, in French, next to `/po-orchestrator`. One line, nothing else in that file. Test able to fail: the existing `pilot.test.sh:test_every_command_listed_in_help`.
9. [x] **Write `tests/drive.test.sh`** with the five `test_<name>` functions of the acceptance criteria, using `tests/lib.sh` helpers and quoting short exact phrases of the files under test. Redefine any `section_of`-style helper locally; `tests/lib.sh` exports none (`docs/research/s27-drive.md`, Verified interfaces).
10. [x] **Update `docs/parite-killer-saas.md`** — only D05 (`:54`) and D16 (`:65`): D05 → `fait — method/commands/po-execute.md, method/commands/po-drive.md`; D16 → `partiel — method/commands/po-orchestrator.md, method/commands/po-drive.md ; validation groupée par vague en s30`. No other line. Test able to fail: none — this is documentation; the reviewer checks it against the story's `Matrice` field.

## Run interdicts
- `method/agents/reviewer.md`, `method/skills/review-antihallu/SKILL.md` — empty diff: they belong to s28.
- `method/AGENTS.md`, `method/commands/po-status.md` — empty diff: they belong to s31.
- `method/commands/po-help.md` — exactly one added line, the `/po-drive` entry; no other change.
- `docs/parite-killer-saas.md` — exactly two changed cells, D05 and D16.
- `docs/decisions/` — empty diff: no ADR is written or edited here, ADR-0016 included.
- `.claude/` and `.polype/` — empty diff: installed copies, never edited (`AGENTS.local.md`, Conventions).
- Do not run `bin/polype-dev-install`: it would rewrite `AGENTS.md` and `.polype/` mid-story.
- Do not implement `Tracker: github`; the command says it will handle it when the repository has a remote.
- No test of an existing file is relaxed to make room; `bash tests/run.sh` must go from 144 passed to 149 passed, 0 failed.

## The pivot
**The driver records the verdict through Bash while declaring neither Write nor Edit.** Three ways that can be wrong:
- A reviewer of this story reads criterion 3 as "writes no file at all" and calls the heredoc a scope breach. Compare against `method/commands/po-review.md:33-35`, which already puts the recording — and the blocked fallback — on the coordinating context, not on the subagent.
- `bin/po-lint` grows a rule forbidding Bash next to Agent. Compare against `bin/po-lint:125-128`: only `Agent` + `Edit` is reported today, and `method/commands/po-flow.md:4-11` already ships `Agent` + `Bash`.
- s28 later gives `reviewer` a `Write` tool, making the heredoc redundant. That is an improvement to fold in then, not a reason to guess now.

## Files touched
- `method/templates/agents-local.md` (settings block + table)
- `method/commands/po-drive.md` (new)
- `method/commands/po-help.md` (one line)
- `tests/drive.test.sh` (new)
- `docs/parite-killer-saas.md` (two cells)
- `docs/research/s27-drive.md`, `docs/plans/s27-drive.md`, `docs/verif/s27-drive.md` (the story's own evidence)

## Test strategy
Automated, 5 tests, within `Test budget: 25` — one per acceptance criterion, all in `tests/drive.test.sh`:

| Test | What it asserts, and what makes it bite |
| --- | --- |
| `drive_picks_a_ready_set_without_conflicts` | the readiness clause, the `Owns` disjunction against running lanes *and* the chosen batch, and the `Parallel` cap; remove any one clause from the command and the test goes red |
| `drive_dispatches_lanes_in_one_message` | the single-message dispatch plus the three `subagent_type` names in order |
| `drive_never_writes_code_or_verdicts` | `lacks_tool Write`, `lacks_tool Edit`, `needs_tool Agent`, `needs_tool Bash`, and the sentence that the reviewer's answer is recorded verbatim |
| `drive_ships_serially_after_each_review` | ships one at a time, the `Ship allowed` gate, the fix run and the `Max attempts` cap |
| `settings_template_declares_fleet_settings` | the three names via `template_settings`, their default values, and one documented table row each |

No new visual check: this story ships markdown and a bash test file. The whole suite (`bash tests/run.sh`) and `bin/po-lint` run at the end of the implementation, per `Full suite: execute-end`.

## Done when
- `bash tests/run.sh` → 149 passed, 0 failed; `bash bin/po-lint` → no breach.
- The five acceptance criteria of `docs/stories.md:414-420` each have a test that fails when its clause is removed.
- `docs/verif/s27-drive.md` is complete with a `Tree:` matching the committed code.
- One commit on `story/s27-drive` carrying the code, the tests, the research, the plan and the record.
- A review with no open critical finding.
