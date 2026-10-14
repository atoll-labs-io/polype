---
validated: yes
---
# Plan — s109-drive-guards

[Story](../stories.md) · [Research](../research/s109-drive-guards.md)

Branch `story/s109-drive-guards`. Read `docs/research/s109-drive-guards.md` first. This plan builds on it without repeating it.

## Story
This story fixes three things:
- s106 major 1: a fleet lane does not check its start point.
- s102 major 2: the wait on an open PR does not test its "effective `human`" condition.
- The s104 minor at `method/AGENTS.md:79`: the drive's log list is too narrow, and the orchestrator keeps no log.

Criteria: `lane_checks_its_start_point`, `pr_wait_needs_effective_human`, `lone_decisions_are_all_logged`. The full text is in `docs/stories.md`, s109.

## Tasks
1. [x] **Lane start point**, `method/commands/po-drive.md` `### Preparing the lanes` (`:87`).
   - Keep the sentence as it is, and insert the start-point step between "start from `origin/<Target branch>` when that ref exists" and `git worktree add -b story/<id> …`, in this order: start point, check, add.
   - The check: `git show <start point>:docs/stories.md` must hold a heading naming `<id>` (`## <id>` or `### <id>`), as step 2 of `/po-research` says.
   - On a miss, add a short paragraph after `:87`, in the orphan's style (`:91`):
     - no worktree is created;
     - the lane drops from the wave and the others carry on;
     - the report names the story as waiting for its framing pull request to merge on `<start point>`;
     - nothing is pulled into the freed slot during this wave.
   - In `## Report` (`:156`), add "the stories waiting for their framing pull request to merge" to the list.
   - Test: `test_lane_checks_its_start_point` (task 5).
2. [x] **Automatic resumes at the ship**, `po-drive.md` `## Resuming`.
   - Row `:65` stays as it is.
   - Directly after the table (before `:70`), add one sentence. Under an effective `automatic`, an open pull request matches neither the waiting row nor the closed row. The lane resumes at the ship, and `/po-ship` reuses that pull request instead of opening a second one.
   - Test: `test_pr_wait_needs_effective_human` (task 5).
3. [x] **Drive log covers every lone decision**, `po-drive.md` `## The decisions log` (`:149`).
   - Append to the existing list: "each implementation detail you settled without the person; each answer you gave without asking".
   - Then add a sentence: the list follows each kind of lone decision that `AGENTS.md` (`## What goes to the person`) names, and none is left out.
   - Keep `after the wave's last ship`, `templates/decisions-log.md`, `Landing the framing` and `slug \`decisions-log\`` word for word.
   - Test: `test_lone_decisions_are_all_logged` (task 5).
4. [x] **Orchestrator log**, `method/commands/po-orchestrator.md`: a new `## The decisions log` section after `## Stage 8 — Ship — checkpoint`. The `Finish with …` line moves below it and stays the file's last line. The section says:
   - What it logs: each plan this run approved under `Plan validation: autonomous`, and each fix run it started. That covers both the full track (Stage 4 and Stage 7) and a `/po-flow` run it delegated to on the short track.
   - Format: rows go to `docs/decisions-log.md` in the repository root, created from `templates/decisions-log.md` when absent. Each row is dated `YYYY-MM-DD` and carries its reason. No existing row is rewritten.
   - When: rows are written once the story has shipped or the run stopped, never before its ship, because a local ship stops on a tracked file modified in the root (`/po-ship`).
   - How it lands: as `## Landing the framing` of `/po-setup` says, slug `decisions-log`, path `docs/decisions-log.md`, message `docs: decisions log`, like `/po-drive`. A stop of that landing is reported and never changes the story's own outcome.
   - What it never logs: a run with no lone decision writes no row.
   - Test: `test_lone_decisions_are_all_logged` (task 5).
5. [x] **`tests/drive-guards.test.sh`**: one header comment `# s109 — …`. It defines its own `section_of`/`holds` (`tests/drive.test.sh:7-10`) and a `subsection_of` for `### <heading>`, which stops at the next `##` or `###` heading. It holds three tests:
   - `test_lane_checks_its_start_point`, in `subsection_of "$DRIVE" 'Preparing the lanes'`:
     - it holds `git show <start point>:docs/stories.md`;
     - that phrase's line comes before the line holding `git worktree add -b story/<id>`. When both sit on one line, compare character offsets, for example with `grep -bo`;
     - it holds a phrase saying the framing pull request waits for its merge, and `## Report` holds the same waiting entry.
   - `test_pr_wait_needs_effective_human`:
     - the `## Resuming` table row holding `printing \`OPEN\`` also holds `an effective \`Ship confirmation\` of \`human\``, the row read alone;
     - the row `is \`yes\` | the ship` holds neither `Ship confirmation` nor `OPEN`, so it stays the fallthrough;
     - `## Resuming` holds the automatic sentence of task 2.
   - `test_lone_decisions_are_all_logged`:
     - drive `## The decisions log` holds `implementation detail` and `answer` + `without asking`;
     - orchestrator `## The decisions log` exists and holds `Plan validation: autonomous` (or the approval phrase chosen), `fix run`, `templates/decisions-log.md`, `Landing the framing`, `slug \`decisions-log\``, and the "never before its ship" phrase;
     - in the orchestrator, the section's heading line sits after `## Stage 8`.
   - Run: `bash tests/run.sh drive-guards.test.sh`.
6. [x] **Neighbours stay green**: `bash tests/run.sh drive.test.sh resume.test.sh ship-follows-forge.test.sh escalation-contract.test.sh pilot.test.sh qa-fleet.test.sh model-routing.test.sh fleet-wiring.test.sh wiring.test.sh overlap.test.sh structure.test.sh`, then the full suite once through `po-run --story s109-drive-guards --label test -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- Files whose diff must be empty:
  - `method/commands/po-research.md`, `method/commands/po-setup.md`, `method/commands/po-ship.md`, `method/commands/po-flow.md`, `method/commands/po-status.md`;
  - `method/AGENTS.md`, `method/hooks/`;
  - every existing `tests/*.test.sh`;
  - `.claude/`, `.polype/` (installed copies).
- These must keep their exact text:
  - `po-drive.md` table row `:65`, starting `| review whose last \`Ship allowed:\` is \`yes\`, \`Merge mode: pr\`, \`gh pr view story/<id> --json state --jq .state\` printing \`OPEN\``;
  - `po-drive.md` `## The ready set` `:31` (s112 owns that rule next);
  - the row order of the `## Resuming` table.
- `po-drive.md` `status` (`:164`) is unchanged: this story does not add the start-point reason to `status`.
- `pilot.test.sh:11` must keep counting two checkpoints, so the new orchestrator heading has no `— checkpoint`.
- No ADR file. No new setting on either `Reads settings:` line.
- No new prose may share 8+ consecutive words with Killer SaaS (`tests/overlap.test.sh`).

## The pivot
The decision this plan rests on: the drive treats a story missing from its start point like an orphan, dropping the lane and reporting it, rather than stopping the wave as `/po-research` stops the command. It could be wrong in three ways:
- **It stops the wave.** Copying `/po-research`'s "stop" wording into the drive would halt every lane. Compare with `po-drive.md:107` ("the other lanes of the wave carry on") and with `:91`.
- **The check reads the wrong file.** If the check read `docs/stories.md` in the root's working copy, where the ready set comes from, it would always pass. It must read `<start point>` through `git show`, after the fetch.
- **The automatic sentence contradicts the table.** If it implied a new row, or a condition on the ship row, the "first match wins" order (`:47`) would change. Compare with the ship row `:67`, which must stay unconditional.

## Files touched
- `method/commands/po-drive.md`
- `method/commands/po-orchestrator.md`
- `tests/drive-guards.test.sh` (new)
- `docs/research/s109-drive-guards.md`, `docs/plans/s109-drive-guards.md`, `docs/verif/s109-drive-guards.md`

## Test strategy
Three tests, well under `Test budget` (25), one per criterion, all in `tests/drive-guards.test.sh`. Each one reads only the section that owns its rule, so a guard moved elsewhere or removed fails it:
- removing the start-point step from `### Preparing the lanes`, or placing it after `git worktree add`, fails `test_lane_checks_its_start_point`;
- deleting the effective-human clause from the `OPEN` row fails `test_pr_wait_needs_effective_human`, which is exactly the reviewer's s102 bite;
- dropping the two new kinds from the drive list, or the orchestrator section, fails `test_lone_decisions_are_all_logged`.

The full suite runs once, at the end, through `po-run`. No type check exists (`Typecheck: —`). There are no visual checks.

## Done when
- The three criteria hold and `bash tests/run.sh` is green.
- The review has no open critical finding.
- The story is landed as one commit `s109-drive-guards: Les lanes de la flotte gardent les garde-fous du chemin seul` through its pull request.
