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

Reads settings: `Target branch`, `Worktree root`, `Install`, `Design source`, `Parallel`, `Max attempts`, `Tracker`, `Plan validation`, `Merge mode`, `Ship confirmation`, `ADR directory`, `QA stage`, `Model strong`, `Model light`, `Light up to`

Argument: $ARGUMENTS — `status` reports the fleet and changes nothing; empty runs a wave.

You drive the fleet: you prepare the lanes, dispatch the subagents, check what comes back and ship what passed. You have neither Write nor Edit, so you write no code and decide no verdict — `planner`, `implementer`, `qa` and `reviewer` each work in their own context under the contract their own file fixes (ADR-0016). Bash prepares worktrees, reads state, records what a subagent handed you and makes the QA evidence commit `/po-qa` describes; it never edits a source file.

## Checks
- No `AGENTS.local.md` → stop and point to `/po-setup`.
- No Agent tool available → stop: without subagents there is no lane, and this command will not do their work.
- `docs/stories.md` missing → stop and point to `/po-stories`; never invent a story to fill a lane.
- One of the settings above missing, `QA stage` excepted → stop and name it; a missing setting is never replaced by a guess.
- `QA stage` missing → only the lanes of stories that would need it stop, as `AGENTS.md` (Law 1) says, each named in the report; the other lanes carry on.
- `Tracker: github` → say that publishing to GitHub is not handled yet, read the state from the worktrees and git as below, and carry on.

## The ready set
State comes from the worktrees and from git, derived the way `/po-status` derives it (`method/commands/po-status.md`), never from what you remember of an earlier wave: since then a lane may have finished, failed or been interrupted.

Read, for each story of `docs/stories.md`: whether it is shipped — a commit whose subject starts with `<id>:` on `Target branch` — its dependencies, and the `Owns` paths the story declares.

A story is **ready** when the three hold together:
1. it is not shipped;
2. every story it depends on is shipped;
3. its `Owns` paths are disjoint from those of the lanes already running **and** from those of the other stories of the batch you are about to launch.

Overlap between two `Owns` entries is decided by one rule. Two `Owns` entries overlap when one path could match both: a folder `x/` covers every path beneath it, `*` matches within one path segment, `**` matches any number of segments; when in doubt, they overlap. See the examples of check 8 of the `stories-review` skill.

Take the ready stories in the order of `docs/stories.md` and stop at `Parallel` lanes, the lanes already running counted in. A story dropped for a conflict is named in the report with the path that collided and the lane holding it, plus the two entries that overlapped and one path matching both; it is the first candidate of the next wave. Nothing ready → report which dependency each story is waiting for and stop the wave.

## Resuming
A wave never sends a story back to stage one: a stop, a crash or a closed session leaves its work in place, and that work is what the lane starts from. For each story the ready set kept, and before any subagent is dispatched, derive the stage it reached from the files of `<Worktree root><id>` and from git — the derivation above, extended to say where the lane resumes:

The table is read top to bottom and **the first row that matches wins**: several rows can describe the same worktree, and that order is the only thing saying which one applies.

| Found | Lane starts at |
| --- | --- |
| no worktree, or no `docs/research/<id>.md` | the research and plan stage |
| research holding the line `Root cause: not found`, and no plan with `validated: yes` | a human — the diagnostic found no cause, and a plan built on that research would be a guessed fix (ADR-0070) |
| research present, plan absent or without `validated: yes` | the plan, built on the research already on disk — the lane keeps that file and never writes it again (`method/agents/planner.md`) |
| `po-gate plan-validated <id>` passes, the story has a screen and `docs/designs/<id>/design.md` is absent | the design stage |
| `po-gate plan-validated <id>` passes, no record or `po-gate verif-current <id>` fails | the code stage |
| record current, the story goes to QA, and the last `QA status:` of `docs/qa/<id>/report.md` is `blocked` | a human — a walk that could not happen fails the same way when replayed |
| record current, the story goes to QA, and `po-gate qa-current <id>` refuses a report that `is current but` not committed | the evidence commit of `/po-qa`, without a new walk |
| record current, the story goes to QA, and `po-gate qa-current <id>` fails | the QA stage — no `Max attempts` unit is spent |
| record current, no `docs/reviews/<id>.md` | the review stage |
| record current, review blocked, and its `Fix loop:` shows it judged an earlier commit | the review stage, at loop `Fix loop:` + 1 |
| `Review status: blocked` and a `Next action:` naming `/po-qa` or the `<id>: QA evidence` commit | the review stage, at the same `Fix loop:` — the QA it waited for is current, or a row above would have matched |
| review whose last `Ship allowed:` is `no` | a fix run, at loop `Fix loop:` + 1 |
| review whose last `Ship allowed:` is `yes` but `po-gate ship-allowed <id>` refuses its `Reviewed tree:` | the review stage, at loop `Fix loop:` + 1 |
| review whose last `Ship allowed:` is `yes` | the ship |
| a commit whose subject starts with `<id>:` on `Target branch` | nothing — the story is done |

A record that exists proves nothing by itself: `po-gate verif-current <id>` is what tells a record from a stale one, and a record the gate refuses sends the lane back to the code stage. `po-gate qa-current <id>` plays the same part for a QA report, telling a current one from a missing or stale one. Since s60 it also requires `docs/qa/<id>/` committed (ADR-0037), so a current report left uncommitted fails it; only that refusal says `is current but`, because the gate checks freshness first and the commit last. The evidence-commit row reads that refusal before the QA-stage row, so such a report is committed instead of walked again (ADR-0041).

The row above the fix run is what a lane stopped between its fix run and its review looks like: the code of that fix run is recorded and current, and the review on disk is the blocked one that judged the commit before it. Reading it as a plain blocked review would send the lane through a second fix run with nothing to fix, and spend one `Max attempts` unit on it. A review at `Fix loop: <n>` judged the story's `<n>` + 1st implementer commit, since the first implementation is one commit and each fix run adds one of its own (`AGENTS.md`, Law 6). Commits whose subject is `<id>: QA evidence` are not implementer commits and are never counted; more implementer commits than that on `story/<id>` means the fix run landed after the review, and the code was never judged. A story whose migration took a commit of its own makes that count drift: there, compare the `Tree:` of `docs/verif/<id>.md` with the tree of the commit the review judged, and treat the review as stale when they differ.

A favourable review whose `Reviewed tree:` the gate refuses means code was committed after the verdict, so that code was never judged and goes back to review rather than to the ship; such a re-review spends one `Max attempts` unit. When the late commit also left the record stale, the code-stage row matches first, which is right: the checks run again before anyone judges the new code.

Two rules keep resuming honest.

**The attempts already spent are read from the `Fix loop:` line of `docs/reviews/<id>.md`**, the way `/po-review` reads it (`method/commands/po-review.md`), never from what you remember of this session: a driver that starts again inherits them, and `Max attempts` counts the loops of every session together instead of handing each new driver a fresh budget.

**A stage already recorded is resumed, never replayed.** No research, plan, record or review is overwritten to give a lane a clean slate, and no finished stage is run again to leave a tidier file behind: what is on disk is what the next stage reads.

## A wave

You never leave the directory you were started in: no `cd`, at any stage of a wave. Each lane's worktree is resolved once, as the absolute path `<repository root>/<Worktree root><id>`; every git command you run against a lane is `git -C <absolute path>`, and every subagent prompt carries that same absolute path. A driver whose working directory drifted addresses one lane with another lane's path, and its own report cannot show that mistake: it says what you meant to do, not where the command landed.

### Preparing the lanes
You prepare each lane's worktree yourself, before any subagent starts, exactly as `/po-research` describes it (`method/commands/po-research.md`): fetch when the repository has a remote and start from `origin/<Target branch>` when that ref exists, `git worktree add -b story/<id> <Worktree root><id> <start point>`, copy in the `.env*` files git ignores, then run `Install`. `planner` is forbidden to run `git worktree add`, `switch`, `checkout` or `stash` (`method/agents/planner.md`), so a lane you did not prepare cannot exist.

An existing worktree is confirmed on two axes, never repaired. The branch: `git -C <path> rev-parse --abbrev-ref HEAD` must print `story/<id>`. The path: `git worktree list --porcelain` must show `story/<id>` checked out at `<Worktree root><id>` and at no other path. Either axis off makes that worktree an **orphan**, and it holds both ways — another branch, a detached HEAD, a path that is the repository root, or a `story/<id>` registered somewhere else.

An orphan is named in the report with the path and the branch actually found, drops that lane from the wave, and waits for a human: you run no `git worktree add --force`, `worktree remove`, `worktree prune`, `switch`, `checkout` or `stash` to make it fit.

ADR numbers are a shared resource no `Owns` line can divide: two lanes reading the `ADR directory` folder at the same time both find the same highest number, and both write over the other. So you assign them before the wave leaves — read the highest `ADR-NNNN` on `Target branch`, then hand each lane of the wave its own number, the following ones in sequence, in the order of `docs/stories.md`. A lane that needs no ADR leaves its number unused and the gap stays a gap: a number is never handed to a second lane of the same wave. A lane that needs more numbers than it was given says so in its answer and writes none beyond its reservation.

### Dispatching
The lanes of a wave must **overlap in time**: every subagent of a stage is started before any of them is waited on, so their work spans cross instead of following one another. No dispatch shape is imposed — whether the Agent calls travel in one message or in several is not what makes a wave parallel, and counting messages proves nothing, since a subagent starts in the background and hands the call back at once: a message count records how the driver typed, not whether two lanes ever ran together. What shows the overlap is each lane's **activity window**, the moment its subagent started and the moment it answered, which `## Report` states. Never two calls for the same story at once. This holds stage by stage: every planner of a wave is started before any plan is read, then every implementer, then every qa, then every reviewer — a stage is started whole. A lane whose subagent leaves only once the previous lane has answered overlaps nothing, and `Parallel` buys nothing there.

Per lane, in this order, each stage dispatched as its own wave:
1. `subagent_type: planner`, `model:` set to `Model strong` — the story id and the absolute worktree path; its research, its track and its plan are its own contract, which you do not restate. The plans that come back are approved as `## Validating a wave's plans` settles it, before any implementer starts. A planner that answers with a research holding `Root cause: not found` sends its lane to a human, as the resuming table says; no plan is approved or dispatched for it.
2. **The design stage**, for a story with a screen (`AGENTS.md`, Law 1): `subagent_type: designer`, `model:` set to `Model strong` — the story id and the absolute worktree path, its screen note and its artefact being its own contract (`method/agents/designer.md`), which you do not restate. Check `/po-design`'s own conditions first, in that worktree (`method/commands/po-design.md`): `docs/design-system.md` missing there → the lane stops and the report names `/po-design-system`; `Design source` at `—` → the lane stops and the report asks a human to choose `internal` or `external` in `AGENTS.local.md`, which you never choose for them. Conditions met and `docs/designs/<id>/design.md` already on disk → that note is this lane's design, and no designer is dispatched: `## Resuming` forbids replaying a recorded stage. The stage is never skipped to keep a lane moving: on a story with a screen whose design is missing, the implementer does not start. Like the others, this stage is started whole — every designer of a wave leaves before any of them is waited on — and no design it produces was approved by a human (ADR-0019).
3. `subagent_type: implementer`, its model following `/po-execute`'s `## Model`: `Model light` up to `Light up to`, `Model strong` above — the prompt `/po-execute` fixes (`method/commands/po-execute.md`), word for word, for each lane whose `docs/plans/<id>.md` holds `validated: yes`. A plan without that line never reaches an implementer.
4. **The QA stage**, for a story that goes to QA (`AGENTS.md`, Law 1): `subagent_type: qa`, `model:` set to `Model strong` — the prompt `/po-qa` fixes (`method/commands/po-qa.md`), word for word, once the lane's record passes `po-gate verif-current <id>`. Its walk and its report are its own contract (`method/agents/qa.md`). When it answers, you make the evidence commit exactly as `/po-qa` writes it (ADR-0029, ADR-0034): the branch confirmed as `story/<id>`, then `git -C <absolute path> add -- docs/qa/<id>/` and `git -C <absolute path> commit -m "<id>: QA evidence" -- docs/qa/<id>/`, never with `--no-verify`. No report → the lane stops with the reason the subagent gave. `QA status: blocked` → the report is committed all the same, the lane goes to a human, and no reviewer is dispatched for it. Like the others, this stage is started whole: every qa of a wave leaves before any of them is waited on. A story that does not go to QA dispatches no qa.
5. `subagent_type: reviewer`, `model:` set to `Model strong` — the prompt `/po-review` fixes (`method/commands/po-review.md`), word for word, with this lane's `Fix loop: <n>`.

A lane designs after it has planned. The planner is not run again once the note exists — `## Resuming` forbids replaying a recorded stage — so the screen tasks of the plan were written without it, and the implementer is the one that reads `docs/designs/<id>/design.md` before those tasks, the screen it builds being the one the note settles (`method/agents/implementer.md`). A story whose plan must be built on its design is driven through `/po-orchestrator`, the single-story path, which designs before it plans.

A lane that stops stays stopped and is reported; the other lanes of the wave carry on.

The deciding roles — planner, designer, qa, reviewer — get `Model strong` whatever the story's complexity; only the implementer's model follows the complexity, as `/po-execute` settles it. A model setting at `—` passes no `model` at all, and that subagent runs on the session's model. If the Agent tool rejects a model name, that lane stops, named in the report with the setting and its value; the other lanes carry on. The lane is never redispatched with another model or with none, and the refusal is never recorded as a review or a QA report: the setting is at fault, not the story.

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

A review blocked on QA is not a fix run: the lane goes back to `qa`, then to `reviewer` at the same `Fix loop:`, and no `Max attempts` unit is spent (`method/commands/po-review.md`, ADR-0034). Blocked on QA means `Review status: blocked` and a `Next action:` naming `/po-qa`, nothing less (ADR-0041). A review blocked on QA evidence — `Review status: blocked` and a `Next action:` naming the `<id>: QA evidence` commit — gets that commit without a walk, then `reviewer` at the same `Fix loop:`; no `Max attempts` unit is spent either. Still blocked on QA or on QA evidence with two `<id>: QA evidence` commits since the last implementer commit → the lane goes to a human.

Any other `Ship allowed: no` sends that lane back to `implementer` as a fix run, the review's findings before anything else, with the prompt `/po-execute` fixes plus its fix-run sentence, and the same model rule as the lane's first run: `Model light` up to `Light up to`, `Model strong` above; then back to `reviewer` with the loop number raised by one. A story gets at most `Max attempts` fix runs. Past that, it is listed for a human with its open findings, its lane is freed, and the paths it owns return to the pool.

## Ships, one at a time
Ships never overlap. `Merge mode: local` requires the repository root clean and on `Target branch` (`method/commands/po-ship.md`), and two merges into the same branch at once would race each other in any mode; so you ship one story, prove it, then ship the next, in the order their reviews passed.

Each ship is `/po-ship` applied as written: `po-gate ship-allowed <id>` first — the **last** `Ship allowed:` line of `docs/reviews/<id>.md` must be `yes` **and** its `Reviewed tree:` must still match the code outside `docs/`, and anything else stops that ship — then the expensive checks once, the one commit titled `<id>: <story title>`, landed through its pull request, and cleanup only on proof of the merge. `Ship confirmation: human` means one AskUserQuestion per merge; `automatic` lets the gate decide alone. On a resumed ship, `/po-ship` reads the pull request already open for `story/<id>` and never opens a second one.

A ship that fails sends its story back to a fix run under the same `Max attempts` cap and leaves the other lanes running. Once a story is shipped, its `Owns` paths are free again and the stories depending on it become ready for the next wave.

## Report
One table: story · stage reached · plan · verdict · shipped · models. The report states, per lane and per stage, the model the subagent ran on — the value passed, or `session` when `—` passed none. Then the stories dropped for a conflict, each with the path that collided and the lane holding it, plus the two entries that overlapped and one path matching both; the lanes handed to a human; and the dependencies still blocking. With `$ARGUMENTS` set to `status`, this report is the whole run: no worktree is prepared, no subagent is dispatched, nothing is shipped, no `docs/reviews/<id>.md` is written, and no gate that could change a file is run.

The plan column says who approved it. Under `Plan validation: autonomous`, the report states that the plans were approved without a human reading them and names the stories concerned; under `human`, it states which plans the wave approved and which ones are still waiting for the next wave.

The same holds for the screens: the report names every story whose design no human approved, a design produced inside a lane going to the implementer as its designer wrote it (ADR-0019).

The report also states, per stage, the activity window of each lane — when its subagent started and when it answered — and whether those windows overlap. A stage whose windows do not overlap is reported as sequential, naming the lanes that ran one after the other. No line of the report claims that lanes ran at the same time unless their activity windows show it; the number of messages the dispatch took is not evidence of anything and is not reported as such.

`status` answers three questions and launches nothing. Per lane in flight: the story, the stage it resumes at, its worktree path, and the loops already spent against `Max attempts`. Then, per story a human must decide on, the reason it waits — a dependency not shipped and which one, an `Owns` collision with the path that collided and the lane holding it, plus the two entries that overlapped and one path matching both, `Max attempts` reached with the open findings, a QA report `blocked`, with its cause, or an orphan worktree as it was found.

Finish with the candidates of the next wave, or "Fleet idle: nothing is ready."
