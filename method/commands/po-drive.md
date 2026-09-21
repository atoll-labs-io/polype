---
description: Drives the fleet — advances every ready story in parallel, one lane per story, and ships the finished ones one at a time
argument-hint: [status]
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
---
# /po-drive

Reads settings: `Target branch`, `Worktree root`, `Install`, `Parallel`, `Max attempts`, `Tracker`, `Plan validation`, `Merge mode`, `Ship confirmation`

Argument: $ARGUMENTS — `status` reports the fleet and changes nothing; empty runs a wave.

You drive the fleet: you prepare the lanes, dispatch the subagents, check what comes back and ship what passed. You have neither Write nor Edit, so you write no code and decide no verdict — `planner`, `implementer` and `reviewer` each work in their own context under the contract their own file fixes (ADR-0016). Bash prepares worktrees, reads state and records what a subagent handed you; it never edits a source file.

## Checks
- No `AGENTS.local.md` → stop and point to `/po-setup`.
- No Agent tool available → stop: without subagents there is no lane, and this command will not do their work.
- `docs/stories.md` missing → stop and point to `/po-stories`; never invent a story to fill a lane.
- One of the settings above missing → stop and name it; a missing setting is never replaced by a guess.
- `Tracker: github` → say that publishing to GitHub is not handled yet, read the state from the worktrees and git as below, and carry on.

## The ready set
State comes from the worktrees and from git, derived the way `/po-status` derives it (`method/commands/po-status.md`), never from what you remember of an earlier wave: since then a lane may have finished, failed or been interrupted.

Read, for each story of `docs/stories.md`: whether it is shipped — a commit whose subject starts with `<id>:` on `Target branch` — its dependencies, and the `Owns` paths the story declares.

A story is **ready** when the three hold together:
1. it is not shipped;
2. every story it depends on is shipped;
3. its `Owns` paths are disjoint from those of the lanes already running **and** from those of the other stories of the batch you are about to launch.

Take the ready stories in the order of `docs/stories.md` and stop at `Parallel` lanes, the lanes already running counted in. A story dropped for a conflict is named in the report with the path that collided and the lane holding it; it is the first candidate of the next wave. Nothing ready → report which dependency each story is waiting for and stop the wave.

## A wave

### Preparing the lanes
You prepare each lane's worktree yourself, before any subagent starts, exactly as `/po-research` describes it (`method/commands/po-research.md`): fetch when the repository has a remote and start from `origin/<Target branch>` when that ref exists, `git worktree add -b story/<id> <Worktree root><id> <start point>`, copy in the `.env*` files git ignores, then run `Install`. `planner` is forbidden to run `git worktree add`, `switch`, `checkout` or `stash` (`method/agents/planner.md`), so a lane you did not prepare cannot exist.

An existing worktree is confirmed, never repaired: `git -C <path> rev-parse --abbrev-ref HEAD` must print `story/<id>`. Anything else — another branch, a detached HEAD, a path that is the repository root — drops that lane from the wave and is reported as it was found.

### Dispatching
The subagents of a wave go out **in a single message**: one Agent call per lane, all of them in that one message, which is what makes the lanes run at the same time. Never two calls for the same story at once.

Per lane, in this order, each stage dispatched as its own wave:
1. `subagent_type: planner` — the story id and the absolute worktree path; its research, its track and its plan are its own contract, which you do not restate. Under `Plan validation: autonomous` the plan comes back with `validated: yes`; under `human`, group the wave's plans into one AskUserQuestion before any implementer starts.
2. `subagent_type: implementer` — the prompt `/po-execute` fixes (`method/commands/po-execute.md`), word for word, for each lane whose `docs/plans/<id>.md` holds `validated: yes`. A plan without that line never reaches an implementer.
3. `subagent_type: reviewer` — the prompt `/po-review` fixes (`method/commands/po-review.md`), word for word, with this lane's `Fix loop: <n>`.

A lane that stops stays stopped and is reported; the other lanes of the wave carry on.

## The verdict, and the fix runs
A reviewer's answer is recorded **verbatim** into `docs/reviews/<id>.md` in that lane's worktree, through Bash. You transcribe it, you do not author it: no severity is yours to choose, no finding yours to soften or drop. `/po-review` already puts this recording on the coordinating context (`method/commands/po-review.md`), and the `reviewer` subagent has no Write tool to do it itself.

The single report you compose yourself is the failure `/po-review` mandates: a subagent that fails, times out, returns nothing, or answers without both verdict lines is recorded as `Review status: blocked` with the concrete cause, what is missing, the loop number, then `Max severity: critical` and `Ship allowed: no`. A failure is never turned into a passing verdict, and a severity is never guessed.

`Ship allowed: no` sends that lane back to `implementer` as a fix run, the review's findings before anything else, with the prompt `/po-execute` fixes plus its fix-run sentence; then back to `reviewer` with the loop number raised by one. A story gets at most `Max attempts` fix runs. Past that, it is listed for a human with its open findings, its lane is freed, and the paths it owns return to the pool.

## Ships, one at a time
Ships never overlap. `Merge mode: local` requires the repository root clean and on `Target branch` (`method/commands/po-ship.md`), and two merges into the same branch at once would race each other in any mode; so you ship one story, prove it, then ship the next, in the order their reviews passed.

Each ship is `/po-ship` applied as written: `po-gate ship-allowed <id>` first — the **last** `Ship allowed:` line of `docs/reviews/<id>.md` must be `yes`, and anything else stops that ship — then the expensive checks once, the squash merge titled `<id>: <story title>`, and cleanup only on proof of the merge. `Ship confirmation: human` means one AskUserQuestion per merge; `automatic` lets the gate decide alone.

A ship that fails sends its story back to a fix run under the same `Max attempts` cap and leaves the other lanes running. Once a story is shipped, its `Owns` paths are free again and the stories depending on it become ready for the next wave.

## Report
One table: story · stage reached · plan · verdict · shipped. Then the stories dropped for a conflict with the path that collided, the lanes handed to a human, and the dependencies still blocking. With `$ARGUMENTS` set to `status`, this report is the whole run: no worktree is prepared, no subagent is dispatched, nothing is shipped.

Finish with the candidates of the next wave, or "Fleet idle: nothing is ready."
