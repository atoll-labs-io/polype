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

Reads settings: `Target branch`, `Worktree root`, `Install`, `Design source`, `Parallel`, `Max attempts`, `Tracker`, `Plan validation`, `Merge mode`, `Ship confirmation`

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

## Resuming
A wave never sends a story back to stage one: a stop, a crash or a closed session leaves its work in place, and that work is what the lane starts from. For each story the ready set kept, and before any subagent is dispatched, derive the stage it reached from the files of `<Worktree root><id>` and from git — the derivation above, extended to say where the lane resumes:

| Found | Lane starts at |
| --- | --- |
| no worktree, or no `docs/research/<id>.md` | the research and plan stage |
| research present, plan absent or without `validated: yes` | the same stage, at the plan |
| `po-gate plan-validated <id>` passes, the story has a screen and `docs/designs/<id>/design.md` is absent | the design stage |
| `po-gate plan-validated <id>` passes, no record or `po-gate verif-current <id>` fails | the code stage |
| record current, no `docs/reviews/<id>.md` | the review stage |
| review whose last `Ship allowed:` is `no` | a fix run, at loop `Fix loop:` + 1 |
| review whose last `Ship allowed:` is `yes` | the ship |
| a commit whose subject starts with `<id>:` on `Target branch` | nothing — the story is done |

A record that exists proves nothing by itself: `po-gate verif-current <id>` is what tells a record from a stale one, and a record the gate refuses sends the lane back to the code stage.

Two rules keep resuming honest.

**The attempts already spent are read from the `Fix loop:` line of `docs/reviews/<id>.md`**, the way `/po-review` reads it (`method/commands/po-review.md`), never from what you remember of this session: a driver that starts again inherits them, and `Max attempts` counts the loops of every session together instead of handing each new driver a fresh budget.

**A stage already recorded is resumed, never replayed.** No research, plan, record or review is overwritten to give a lane a clean slate, and no finished stage is run again to leave a tidier file behind: what is on disk is what the next stage reads.

## A wave

### Preparing the lanes
You prepare each lane's worktree yourself, before any subagent starts, exactly as `/po-research` describes it (`method/commands/po-research.md`): fetch when the repository has a remote and start from `origin/<Target branch>` when that ref exists, `git worktree add -b story/<id> <Worktree root><id> <start point>`, copy in the `.env*` files git ignores, then run `Install`. `planner` is forbidden to run `git worktree add`, `switch`, `checkout` or `stash` (`method/agents/planner.md`), so a lane you did not prepare cannot exist.

An existing worktree is confirmed on two axes, never repaired. The branch: `git -C <path> rev-parse --abbrev-ref HEAD` must print `story/<id>`. The path: `git worktree list --porcelain` must show `story/<id>` checked out at `<Worktree root><id>` and at no other path. Either axis off makes that worktree an **orphan**, and it holds both ways — another branch, a detached HEAD, a path that is the repository root, or a `story/<id>` registered somewhere else.

An orphan is named in the report with the path and the branch actually found, drops that lane from the wave, and waits for a human: you run no `git worktree add --force`, `worktree remove`, `worktree prune`, `switch`, `checkout` or `stash` to make it fit.

### Dispatching
The subagents of a wave go out **in a single message**: one Agent call per lane, all of them in that one message, which is what makes the lanes run at the same time. Never two calls for the same story at once.

Per lane, in this order, each stage dispatched as its own wave:
1. `subagent_type: planner` — the story id and the absolute worktree path; its research, its track and its plan are its own contract, which you do not restate. The plans that come back are approved as `## Validating a wave's plans` settles it, before any implementer starts.
2. **The design stage**, for a story whose text shows a screen: a stage the lane **stops at**, never one it dispatches. `/po-design` is a command, and a command does not run inside a subagent (ADR-0016); no design subagent exists, so no lane can produce the design itself. Check `/po-design`'s own conditions first, in that worktree (`method/commands/po-design.md`): `docs/design-system.md` missing there → the lane stops and the report names `/po-design-system`; `Design source` at `—` → the lane stops and the report asks a human to choose `internal` or `external` in `AGENTS.local.md`, which you never choose for them. Conditions met and `docs/designs/<id>/design.md` absent → the lane goes no further than its plan and the report names `/po-design <id>` to run in `<Worktree root><id>`. The stage is never skipped to keep a lane moving: on a story with a screen whose design is missing, the implementer does not start. The next wave finds the note on disk and resumes that lane at the code stage.
3. `subagent_type: implementer` — the prompt `/po-execute` fixes (`method/commands/po-execute.md`), word for word, for each lane whose `docs/plans/<id>.md` holds `validated: yes`. A plan without that line never reaches an implementer.
4. `subagent_type: reviewer` — the prompt `/po-review` fixes (`method/commands/po-review.md`), word for word, with this lane's `Fix loop: <n>`.

The design of a lane therefore lands **after** its plan, where `/po-orchestrator` settles it before. The planner is not run again for it — `## Resuming` forbids replaying a recorded stage — so the plan's screen tasks were written without the note, and it is the implementer that reads `docs/designs/<id>/design.md` before those tasks, the screen it builds being the one the note settles (`method/agents/implementer.md`). A story whose plan must be built on its design is driven through `/po-orchestrator`, the single-story path, which designs before it plans.

A lane that stops stays stopped and is reported; the other lanes of the wave carry on.

## Validating a wave's plans
The plans a wave produced are approved together, per `Plan validation`.

Under `autonomous`, nothing is asked: each plan comes back from its lane already holding `validated: yes`, checked against its own acceptance criteria by the planner that wrote it, and the wave report says that no human read it (`## Report`).

Under `human`, the whole wave goes into **one AskUserQuestion**, never one per story: a question per story would serialise the very lanes you started in parallel. The question shows, for each plan, the story id, its tasks and its test strategy, and the path `docs/plans/<id>.md`, so any plan can be opened and read whole before answering. Three answers:

| Answer | What it does |
| --- | --- |
| Approve every plan | every plan of the wave is approved, and each lane moves on to its implementer |
| Choose which ones | only the plans the answer names are approved; the others stay as they are |
| Stop the wave | nothing is approved, and no implementer is dispatched at all |

`validated: yes` is written through Bash, into the frontmatter of the plans the answer approved and of no other: you have neither Write nor Edit, and a plan nobody named is never approved on your own initiative.

A plan left unapproved keeps `validated: no`. No implementer is dispatched for it, its lane waits for the next wave, where the plan is offered again; the gate refusing it is the same `po-gate plan-validated <id>` as everywhere else, never your memory of the answer. On `Stop`, the plans stay on disk as the planners wrote them, and the next run resumes at the plan with nothing to redo.

## The verdict, and the fix runs
A reviewer's answer is recorded **verbatim** into `docs/reviews/<id>.md` in that lane's worktree, through Bash. You transcribe it, you do not author it: no severity is yours to choose, no finding yours to soften or drop. `/po-review` already puts this recording on the coordinating context (`method/commands/po-review.md`), and the `reviewer` subagent has no Write tool to do it itself.

The single report you compose yourself is the failure `/po-review` mandates: a subagent that fails, times out, returns nothing, or answers without both verdict lines is recorded as `Review status: blocked` with the concrete cause, what is missing, the loop number, then `Max severity: critical` and `Ship allowed: no`. A failure is never turned into a passing verdict, and a severity is never guessed.

`Ship allowed: no` sends that lane back to `implementer` as a fix run, the review's findings before anything else, with the prompt `/po-execute` fixes plus its fix-run sentence; then back to `reviewer` with the loop number raised by one. A story gets at most `Max attempts` fix runs. Past that, it is listed for a human with its open findings, its lane is freed, and the paths it owns return to the pool.

## Ships, one at a time
Ships never overlap. `Merge mode: local` requires the repository root clean and on `Target branch` (`method/commands/po-ship.md`), and two merges into the same branch at once would race each other in any mode; so you ship one story, prove it, then ship the next, in the order their reviews passed.

Each ship is `/po-ship` applied as written: `po-gate ship-allowed <id>` first — the **last** `Ship allowed:` line of `docs/reviews/<id>.md` must be `yes`, and anything else stops that ship — then the expensive checks once, the squash merge titled `<id>: <story title>`, and cleanup only on proof of the merge. `Ship confirmation: human` means one AskUserQuestion per merge; `automatic` lets the gate decide alone.

A ship that fails sends its story back to a fix run under the same `Max attempts` cap and leaves the other lanes running. Once a story is shipped, its `Owns` paths are free again and the stories depending on it become ready for the next wave.

## Report
One table: story · stage reached · plan · verdict · shipped. Then the stories dropped for a conflict with the path that collided, the lanes handed to a human, and the dependencies still blocking. With `$ARGUMENTS` set to `status`, this report is the whole run: no worktree is prepared, no subagent is dispatched, nothing is shipped, no `docs/reviews/<id>.md` is written, and no gate that could change a file is run.

The plan column says who approved it. Under `Plan validation: autonomous`, the report states that the plans were approved without a human reading them and names the stories concerned; under `human`, it states which plans the wave approved and which ones are still waiting for the next wave.

`status` answers three questions and launches nothing. Per lane in flight: the story, the stage it resumes at, its worktree path, and the loops already spent against `Max attempts`. Then, per story a human must decide on, the reason it waits — a dependency not shipped and which one, an `Owns` collision with the path that collided and the lane holding it, `Max attempts` reached with the open findings, or an orphan worktree as it was found.

Finish with the candidates of the next wave, or "Fleet idle: nothing is ready."
