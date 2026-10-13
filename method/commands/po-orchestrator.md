---
description: Walks one story through its cycle — picks the full or short track, adds design for a screen, then plan, execute, review and ship — pausing only where the settings ask for a human
argument-hint: <story id or name>
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Bash
  - AskUserQuestion
  - Agent
---
# /po-orchestrator

Reads settings: `Target branch`, `Worktree root`, `Plan validation`, `Ship confirmation`, `Merge mode`, `Test budget`, `Story track`, `Flow threshold`, `Entry mode`, `Design source`, `QA stage`, `Model strong`, `Model light`, `Light up to`

Story: $ARGUMENTS

You sequence the stages; each one keeps the contract written in its own command file (`/po-research`, `/po-design`, `/po-plan`, `/po-execute`, `/po-qa`, `/po-review`, `/po-ship`, `/po-flow`) — read those files and follow them. You write no code and do not take over work that belongs to a subagent. Where a human must decide, you call AskUserQuestion; a question in your text output is not a checkpoint.

The research, design and plan this command writes in its own context run on the session's model, which no command can choose (ADR-0036); start the session on `Model strong` for them. Only the subagents this command launches get a model passed to them.

## Stage 0 — Can this start?
`AGENTS.local.md` and `docs/stories.md` exist, and $ARGUMENTS matches one id. Otherwise stop and name what is missing; never create a story to keep going. `Model strong`, `Model light` or `Light up to` absent from `AGENTS.local.md`: a model setting missing → stop and name it.

Then check the framing on `Target branch`, following `Entry mode`:
- `replace` or `adapt` → `docs/prd.md` with `status: approved` in its frontmatter; missing or not approved → stop and point to `/po-prd`.
- `new` → `docs/brief.md` with `status: approved`; missing or not approved → stop and point to `/po-brief`.
- `—` → the project writes its stories by hand; there is no scope to check.

`docs/reviews/stories.md` missing, or ending with `Stories ready: no` → warn, name `/po-stories-review`, and carry on: that verdict informs, it does not block.

A story with a screen (`AGENTS.md`, Law 1) also needs, before any worktree exists, `docs/design-system.md` on `Target branch` and a `Design source` other than `—`: the design stage stops without them. Either missing → stop now and point to `/po-design-system`, or ask the person to set `Design source`, rather than run research and stop at stage 3.

Every stop for a human in the stages below — a research without a root cause at stage 2, a plan holding the line `Technical choice: waiting for a human` that the person did not settle at stage 4, a QA report `blocked` at stage 6, the fix runs spent at stage 7 — ends this run at once and reports that stop alone, with its reason. The lanes `/po-drive` runs are not this command's, and nothing here pauses them.

## Stage 1 — Track
Read `Story track`; a missing setting is a stop, never a guess.
- `full` → the full track.
- `flow` → the short track.
- `auto` → the short track when the story's complexity in `docs/stories.md` is at most `Flow threshold`; above it, or with no complexity written, the full track.

A story with a screen takes the full track whatever the settings say when that screen is new: `/po-flow` would escalate on it, and the screen needs the design stage. Any story that goes to QA takes the full track too, because `/po-flow` runs no QA; `QA stage` missing for a story that has a screen or a `Surface` other than `—` → stop and name the setting.

On the short track, apply `/po-flow` as written and stop sequencing stages here: it runs its own execute, review and ship. If `/po-flow` escalates, continue on the full track at stage 2, reusing the worktree it left.

## Stage 2 — Research
Create or confirm the worktree as `/po-research` describes. Write `docs/research/<id>.md` under that contract if it does not exist yet; reuse it if it does. A story carrying a `Fixes` line (`Corrige` in a French stories file) is researched under the `diagnostic` skill, the escalated `/po-flow` path included. A research that opens with `Root cause: not found` ends the run here: report it and hand the story to a human, with no plan.

## Stage 3 — Design
Only for a story with a screen; skip it otherwise. Apply `/po-design` in the story worktree, reusing `docs/designs/<id>/design.md` if it already exists. The approval here is the one `/po-design` defines.

## Stage 4 — Plan — checkpoint
Write `docs/plans/<id>.md` under the `/po-plan` contract if it does not exist. When `docs/designs/<id>/design.md` exists, read it with the research: the screen tasks build what it settles, cite it, and add nothing it leaves out. If the plan's frontmatter already has `validated: yes`, move on. A plan holding the line `Technical choice: waiting for a human` first has its choice put to the person, as `## Approval` of `/po-plan` says, before either bullet below and whatever `Plan validation` says. Then, for a plan still without `validated: yes`:
- `Plan validation: human` → AskUserQuestion "Approve the plan for <id>?" with tasks, files and test strategy; Approve / Change / Stop. Only Approve writes `validated: yes`; the other answers end the run.
- `autonomous` → check the plan against every acceptance criterion, write `validated: yes`, and state that no human reviewed it.

## Stage 5 — Execute
Delegate to `implementer` the way `/po-execute` does, its model chosen by `/po-execute`'s `## Model`: `Model light` up to `Light up to`, `Model strong` above, fix runs included — as a fix run when the latest review blocks the story on findings; a review blocked on QA never triggers the fix run, nor does one blocked on QA evidence. Never implement in this context.

When `docs/designs/<id>/` exists, append this sentence to the prompt of `/po-execute`:
> This story has a design: docs/designs/<id>/ is expected uncommitted work, like the research and the plan. Read design.md before the screen tasks, build the screen it settles, and commit the folder with the story.

## Stage 6 — QA
Only for a story that goes to QA (`AGENTS.md`, Law 1); skip it otherwise. `QA stage` missing for a story that has a screen or a `Surface` other than `—` → stop and name the setting.

Apply `/po-qa` as written: its preconditions, the `qa` subagent with `model:` set to `Model strong`, then the evidence commit that this context makes. Run it after every execution, first run and fix run alike, since each one leaves a tree the previous walk never saw. No report → stop with the reason the subagent gave. `QA status: blocked` → commit the report as evidence, then stop for a human with its cause: no review is requested on a walk that did not happen. When `po-gate qa-current <id>` refuses with `is current but`, the report on disk is current and only uncommitted: make the evidence commit alone, no walk (ADR-0041).

## Stage 7 — Review
Delegate to `reviewer` the way `/po-review` does, `model:` set to `Model strong`, and record `docs/reviews/<id>.md` with its `Fix loop:`. A missing or incomplete verdict is recorded as blocked: `Max severity: critical`, `Ship allowed: no`.

Blocked on QA — `Review status: blocked` and a `Next action:` naming `/po-qa` → back to stage 6, then stage 7 again at the same `Fix loop:`; that return is not a fix run and spends none of the two (ADR-0034, ADR-0041).

Blocked on QA evidence — `Review status: blocked` and a `Next action:` naming the `<id>: QA evidence` commit → that evidence commit as stage 6 makes it, without a walk, then stage 7 again at the same `Fix loop:`; it spends none of the two either.

A second review blocked on QA or on QA evidence while `story/<id>` already holds two `<id>: QA evidence` commits since the last implementer commit → stop for a human.

Any other blocked review → back to stage 5 as a fix run, with the full latest report. After two fix runs still blocked → stop and list the open findings for a human. A verdict is never softened to reach the next stage.

## Stage 8 — Ship — checkpoint
Apply `/po-ship`: verdict gate, expensive checks, then the one-commit landing through its pull request. The human checkpoint of this stage is the one `/po-ship` defines for `Ship confirmation` and `Merge mode`, the ship following the effective `Ship confirmation` that `/po-ship` settles from the forge (`## The forge's review rule`) — an AskUserQuestion before a local merge, or the pull request itself in pr mode. Cleanup only after proof of the merge.

Finish with "<id> shipped.", "Pull request ready: <url>.", or the stage that stopped, what is missing, and the next command.
