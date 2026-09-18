---
description: Walks one story through research, plan, execute, review and ship, pausing only where the settings ask for a human
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

Reads settings: `Target branch`, `Worktree root`, `Plan validation`, `Ship confirmation`, `Merge mode`, `Test budget`

Story: $ARGUMENTS

You sequence the stages; each one keeps the contract written in its own command file (`/po-research`, `/po-plan`, `/po-execute`, `/po-review`, `/po-ship`) — read those files and follow them. You write no code and do not take over work that belongs to a subagent. Where a human must decide, you call AskUserQuestion; a question in your text output is not a checkpoint.

## Stage 0 — Can this start?
`AGENTS.local.md` and `docs/stories.md` exist, and $ARGUMENTS matches one id. Otherwise stop and name what is missing; never create a story to keep going.

## Stage 1 — Research
Create or confirm the worktree as `/po-research` describes. Write `docs/research/<id>.md` under that contract if it does not exist yet; reuse it if it does.

## Stage 2 — Plan — checkpoint
Write `docs/plans/<id>.md` under the `/po-plan` contract if it does not exist. If its frontmatter already has `validated: yes`, move on. Otherwise:
- `Plan validation: human` → AskUserQuestion "Approve the plan for <id>?" with tasks, files and test strategy; Approve / Change / Stop. Only Approve writes `validated: yes`; the other answers end the run.
- `autonomous` → check the plan against every acceptance criterion, write `validated: yes`, and state that no human reviewed it.

## Stage 3 — Execute
Delegate to `implementer` the way `/po-execute` does — as a fix run when the latest review blocks the story. Never implement in this context.

## Stage 4 — Review
Delegate to `reviewer` the way `/po-review` does and record `docs/reviews/<id>.md` with its `Fix loop:`. A missing or incomplete verdict is recorded as blocked: `Max severity: critical`, `Ship allowed: no`.

Blocked → back to stage 3 as a fix run, with the full latest report. After two fix runs still blocked → stop and list the open findings for a human. A verdict is never softened to reach the next stage.

## Stage 5 — Ship — checkpoint
Apply `/po-ship`: verdict gate, expensive checks, then the merge. The human checkpoint of this stage is the one `/po-ship` defines for `Ship confirmation` and `Merge mode` — an AskUserQuestion before a local merge, or the pull request itself in pr mode. Cleanup only after proof of the merge.

Finish with "<id> shipped.", "Pull request ready: <url>.", or the stage that stopped, what is missing, and the next command.
