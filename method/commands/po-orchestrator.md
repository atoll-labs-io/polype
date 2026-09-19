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

Reads settings: `Target branch`, `Worktree root`, `Plan validation`, `Ship confirmation`, `Merge mode`, `Test budget`, `Story track`, `Flow threshold`, `Entry mode`, `Design source`

Story: $ARGUMENTS

You sequence the stages; each one keeps the contract written in its own command file (`/po-research`, `/po-design`, `/po-plan`, `/po-execute`, `/po-review`, `/po-ship`, `/po-flow`) — read those files and follow them. You write no code and do not take over work that belongs to a subagent. Where a human must decide, you call AskUserQuestion; a question in your text output is not a checkpoint.

## Stage 0 — Can this start?
`AGENTS.local.md` and `docs/stories.md` exist, and $ARGUMENTS matches one id. Otherwise stop and name what is missing; never create a story to keep going.

Then check the framing on `Target branch`, following `Entry mode`:
- `replace` or `adapt` → `docs/prd.md` with `status: approved` in its frontmatter; missing or not approved → stop and point to `/po-prd`.
- `new` → `docs/brief.md` with `status: approved`; missing or not approved → stop and point to `/po-brief`.
- `—` → the project writes its stories by hand; there is no scope to check.

`docs/reviews/stories.md` missing, or ending with `Stories ready: no` → warn, name `/po-stories-review`, and carry on: that verdict informs, it does not block.

A story whose text shows a screen also needs, before any worktree exists, `docs/design-system.md` on `Target branch` and a `Design source` other than `—`: the design stage stops without them. Either missing → stop now and point to `/po-design-system`, or ask the person to set `Design source`, rather than run research and stop at stage 3.

## Stage 1 — Track
Read `Story track`; a missing setting is a stop, never a guess.
- `full` → the full track.
- `flow` → the short track.
- `auto` → the short track when the story's complexity in `docs/stories.md` is at most `Flow threshold`; above it, or with no complexity written, the full track.

A story whose text shows a new screen takes the full track whatever the settings say: `/po-flow` would escalate on it, and the screen needs the design stage.

On the short track, apply `/po-flow` as written and stop sequencing stages here: it runs its own execute, review and ship. If `/po-flow` escalates, continue on the full track at stage 2, reusing the worktree it left.

## Stage 2 — Research
Create or confirm the worktree as `/po-research` describes. Write `docs/research/<id>.md` under that contract if it does not exist yet; reuse it if it does.

## Stage 3 — Design
Only for a story with a screen; skip it otherwise. Apply `/po-design` in the story worktree, reusing `docs/designs/<id>/design.md` if it already exists. The approval here is the one `/po-design` defines.

## Stage 4 — Plan — checkpoint
Write `docs/plans/<id>.md` under the `/po-plan` contract if it does not exist. When `docs/designs/<id>/design.md` exists, read it with the research: the screen tasks build what it settles, cite it, and add nothing it leaves out. If the plan's frontmatter already has `validated: yes`, move on. Otherwise:
- `Plan validation: human` → AskUserQuestion "Approve the plan for <id>?" with tasks, files and test strategy; Approve / Change / Stop. Only Approve writes `validated: yes`; the other answers end the run.
- `autonomous` → check the plan against every acceptance criterion, write `validated: yes`, and state that no human reviewed it.

## Stage 5 — Execute
Delegate to `implementer` the way `/po-execute` does — as a fix run when the latest review blocks the story. Never implement in this context.

When `docs/designs/<id>/` exists, append this sentence to the prompt of `/po-execute`:
> This story has a design: docs/designs/<id>/ is expected uncommitted work, like the research and the plan. Read design.md before the screen tasks, build the screen it settles, and commit the folder with the story.

## Stage 6 — Review
Delegate to `reviewer` the way `/po-review` does and record `docs/reviews/<id>.md` with its `Fix loop:`. A missing or incomplete verdict is recorded as blocked: `Max severity: critical`, `Ship allowed: no`.

Blocked → back to stage 5 as a fix run, with the full latest report. After two fix runs still blocked → stop and list the open findings for a human. A verdict is never softened to reach the next stage.

## Stage 7 — Ship — checkpoint
Apply `/po-ship`: verdict gate, expensive checks, then the merge. The human checkpoint of this stage is the one `/po-ship` defines for `Ship confirmation` and `Merge mode` — an AskUserQuestion before a local merge, or the pull request itself in pr mode. Cleanup only after proof of the merge.

Finish with "<id> shipped.", "Pull request ready: <url>.", or the stage that stopped, what is missing, and the next command.
