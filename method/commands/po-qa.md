---
description: Hands one story's screens to the qa subagent, which walks them in a browser and reports with captures. This command cannot edit files or run a shell, by construction.
argument-hint: <story id or name>
allowed-tools:
  - Read
  - Glob
  - Grep
  - Agent
---
# /po-qa

Reads settings: `Worktree root`, `Dev`

Story: $ARGUMENTS

This command has no Write, Edit or Bash tool. The `qa` subagent walks the story's screens and writes its report; it fixes nothing, and neither does this command. Never describe a walk the subagent did not report.

No Agent tool available → say so and stop.

## Preconditions, checked by reading files
1. `AGENTS.local.md` exists; if not, point to `/po-setup` and stop.
2. $ARGUMENTS matches exactly one id of `docs/stories.md`; otherwise list the ids and stop.
3. The worktree is registered, checked as `/po-execute` checks it: `<shared>/worktrees/<id>/gitdir` contains `<repository root>/<Worktree root><id>/.git`, and `<shared>/worktrees/<id>/HEAD` contains `ref: refs/heads/story/<id>`, `<shared>` being `<repository root>/.git` or, when that is a file, the `<common>` its `gitdir:` line names. Any difference → point to `/po-research <id>` and stop.
4. `docs/verif/<id>.md` missing in the worktree → there is no built code to walk yet: point to `/po-execute <id>` and stop.
5. `Dev` is `—` → stop: the project has no command to start it; ask for `Dev` in `AGENTS.local.md`.
6. The story shows no screen → stop and say so: there is nothing to walk.

## Delegation
Call the Agent tool with `subagent_type: qa`, description "QA <id>", and this prompt, filled in:

> Story <id>. Worktree: <absolute path>. How to work is settled by your agent file. Start every shell command with `cd <absolute path> &&` or use `git -C <absolute path>`. Settings and project commands are in AGENTS.local.md; run `Dev` exactly as written.

Wait for the subagent to finish.

## Report
Relay the subagent's answer: what was walked, findings by severity and status, what was not seen, the tree and the report path. This command never writes a report: when the agent stops, there is none.
