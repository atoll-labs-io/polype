---
validated: yes
---
# Plan — s29-resume

Branch `story/s29-resume`. Read `docs/research/s29-resume.md` first; this plan builds on it without repeating it.

## Story
`/po-drive` must resume a fleet instead of restarting it: a stop, a crash or a closed session must not send a story back to stage one.

- `drive_resumes_from_what_exists` — per story, the stage reached is deduced from the worktree files (research, plan validated or not, record, review) and from git; the lane restarts at the next stage.
- `drive_status_reports_lanes` — `/po-drive status` lists the lanes in flight, the attempts, the blocked stories and what they wait for, launching nothing.
- `drive_detects_an_orphan_worktree` — a worktree whose branch or path does not match is reported and never silently repaired.

## Tasks

1. [x] **Add a `## Resuming` section to `method/commands/po-drive.md`, placed between `## The ready set` and `## A wave`.** It states that the stage reached by a story is derived, before any dispatch, from the files of `<Worktree root><id>` and from git — extending the derivation `/po-status` already defines (`method/commands/po-status.md:22-31`) rather than restating it — and it carries a table mapping the state found to the stage the lane starts at:

   | Found | Lane starts at |
   | --- | --- |
   | no worktree, or no `docs/research/<id>.md` | the research and plan stage |
   | research present, plan absent or without `validated: yes` | the same stage, at the plan |
   | `po-gate plan-validated <id>` passes, no record or `po-gate verif-current <id>` fails | the code stage |
   | record current, no `docs/reviews/<id>.md` | the review stage |
   | review whose last `Ship allowed:` is `no` | a fix run, at loop `Fix loop:` + 1 |
   | review whose last `Ship allowed:` is `yes` | the ship |
   | a commit whose subject starts with `<id>:` on `Target branch` | nothing — the story is done |

   The section also fixes the two rules that make resuming safe: the attempts already spent are read from the `Fix loop:` line of `docs/reviews/<id>.md`, the way `/po-review` reads it (`method/commands/po-review.md:25`), never from what the session remembers, so a driver that restarts inherits them and `Max attempts` counts the loops of every session together; and a stage already recorded is resumed, never replayed to produce a tidier file — no research, plan, record or review is overwritten to make a lane start from a clean slate.

   *Test able to fail*: `test_drive_resumes_from_what_exists` in `tests/resume.test.sh`.

2. [x] **Widen the orphan check in `### Preparing the lanes` of `method/commands/po-drive.md` to the path axis.** Today only the branch is confirmed (`method/commands/po-drive.md:44`). Add that `git worktree list --porcelain` must show `story/<id>` checked out at `<Worktree root><id>` and at no other path, and that the reverse also holds — `<Worktree root><id>` carrying another branch, a detached HEAD, or a `story/<id>` registered somewhere else is an orphan. An orphan is named in the report with the path and the branch actually found, drops its lane from the wave, and is never repaired: no `git worktree add --force`, `worktree remove`, `worktree prune`, `switch`, `checkout` or `stash` is run to make it fit; a human decides. Keep the phrases `tests/drive.test.sh` pins (`You prepare each lane's worktree yourself`, `git worktree add -b story/<id>`) exactly as they are.

   *Test able to fail*: `test_drive_detects_an_orphan_worktree`.

3. [x] **Extend `## Report` of `method/commands/po-drive.md` so `status` answers the three questions the story asks.** The `status` report names, per lane in flight, the story, the stage it resumes at, its worktree path and the loops already spent against `Max attempts`; then the stories a human must decide on, each with the reason — a dependency not shipped and which one, an `Owns` collision and the path that collided with the lane holding it, `Max attempts` reached with the open findings, or an orphan worktree as it was found. Strengthen the existing side-effect clause (`method/commands/po-drive.md:72`) so it also says that `status` writes no `docs/reviews/<id>.md` and runs no gate that could change a file.

   *Test able to fail*: `test_drive_status_reports_lanes`.

4. [x] **Write `tests/resume.test.sh`** — three functions, one per acceptance criterion, named exactly `test_drive_resumes_from_what_exists`, `test_drive_status_reports_lanes`, `test_drive_detects_an_orphan_worktree`. Shape them like `tests/drive.test.sh`: a local `section_of` to pull one `## <heading>` body out of `po-drive.md`, a local `holds` that fails with the missing phrase, `require_file` from `tests/lib.sh`. Each assertion quotes a short exact phrase of the clause it guards, so that deleting the rule turns the test red — a test that would survive the deletion of its own clause does not go in.

5. [x] **Run `bash tests/run.sh` and `bash bin/po-lint`.** The whole suite, once, when the three tasks above are done: `tests/drive.test.sh` and `tests/lint.test.sh` both read `po-drive.md` and are the ones a careless edit breaks. Record both runs in `docs/verif/s29-resume.md`.

## Run interdicts
- `docs/parite-killer-saas.md` ends with an empty diff: line D17 belongs to s31-fleet-wiring's `Owns`.
- `method/AGENTS.md`, `method/commands/po-help.md` and `method/commands/po-status.md` end with an empty diff: s31 owns them.
- `method/templates/agents-local.md` ends with an empty diff: this story adds no setting, and the `Reads settings:` line of `po-drive.md` already declares every name the new text uses.
- `tests/drive.test.sh` ends with an empty diff: s29 changes no clause it checks.
- `.claude/` and `.polype/` are installed copies; never edited.
- No literal `subagent_type: <name>` is added anywhere inside the `## A wave` section — `tests/drive.test.sh:45-47` greps that section and demands exactly `planner implementer reviewer `.
- No source file outside `method/commands/po-drive.md` and `tests/resume.test.sh` is touched, the story's own `docs/` aside.

## The pivot
Everything rests on this: **the stage a lane resumes at is a pure function of files already in the worktree and of git, and the attempts already spent live in one line of one file** (`Fix loop:` in `docs/reviews/<id>.md`). Three ways it could be wrong, each with what to compare it against:

- **A stale record reads as a reached stage.** `docs/verif/<id>.md` can exist while the code moved under it; `po-gate verif-current` is what separates the two (`method/hooks/po-gate.sh:35-47`). Compare the table's third row against that script: if the plan says "record present" instead of "the gate passes", the lane skips the code stage on a record that proves nothing.
- **`Fix loop:` counts reviews, not implementer runs.** `/po-review` sets loop 0 for the first review (`method/commands/po-review.md:25`), so a story with one blocked review has spent one attempt, not zero. Compare the resume table against `## The verdict, and the fix runs` (`method/commands/po-drive.md:60`): both must count the same thing, or `Max attempts` fires a run early or a run late.
- **A review file outliving its story.** A story already shipped still carries its review on the branch; resuming it would re-ship it. Compare against `## The ready set` (`:28`), which excludes shipped stories first — the resume table must be read after that filter, never before.

## Files touched
- `method/commands/po-drive.md` — new `## Resuming` section, widened orphan clause in `### Preparing the lanes`, extended `## Report`.
- `tests/resume.test.sh` — new.
- `docs/research/s29-resume.md`, `docs/plans/s29-resume.md`, `docs/verif/s29-resume.md` — committed with the story.

## Test strategy
Three automated tests, well inside `Test budget: 25`, one per acceptance criterion, all in `tests/resume.test.sh`. The layer is the only one this repository has: a method file is prose, so the test asserts that the clause which carries the rule is present, word for word, in the section that owns it. The rule under test is the phrase quoted; delete it from `po-drive.md` and the test fails — that is the check the doctrine asks for.

No test is added for the resume table's individual rows beyond the phrases that carry them: a row-by-row assertion would be the enum-pair test the doctrine cuts. No existing test is modified.

Visual checks: none, this story has no screen.

Commands, from `AGENTS.local.md`: `bash tests/run.sh` for the suite, `bash tests/run.sh resume.test.sh drive.test.sh lint.test.sh` for a focused run. `Typecheck: —`, `Build: —`, `E2E: —` — the project has none, and none is substituted.

## Done when
- `method/commands/po-drive.md` carries the resume section, the widened orphan clause and the status report, and `tests/resume.test.sh` has its three tests green.
- `bash tests/run.sh` passes whole, and `bash bin/po-lint` reports no breach.
- `docs/verif/s29-resume.md` is complete, with a `Tree:` matching the committed code outside `docs/`.
- One commit on `story/s29-resume`, message in English, no co-author trailer.
- A review with no open critical finding.
