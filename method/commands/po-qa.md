---
description: Hands one story's screens to the qa subagent, which walks them in a browser and reports with captures, then commits that evidence alone. This command cannot edit files; its shell serves that one commit.
argument-hint: <story id or name>
allowed-tools:
  - Read
  - Glob
  - Grep
  - Agent
  - Bash
---
# /po-qa

Reads settings: `Worktree root`, `Dev`, `Model strong`

Story: $ARGUMENTS

This command has no Write or Edit tool. Bash serves exactly one use, the evidence commit below; any other shell command is out of bounds. The `qa` subagent walks the story's screens and writes its report; it fixes nothing, and neither does this command. Never describe a walk the subagent did not report.

No Agent tool available → say so and stop.

## Preconditions, checked by reading files
1. `AGENTS.local.md` exists; if not, point to `/po-setup` and stop.
2. $ARGUMENTS matches exactly one id of `docs/stories.md`; otherwise list the ids and stop.
3. The worktree is registered, checked as `/po-execute` checks it: `<shared>/worktrees/<id>/gitdir` contains `<repository root>/<Worktree root><id>/.git`, and `<shared>/worktrees/<id>/HEAD` contains `ref: refs/heads/story/<id>`, `<shared>` being `<repository root>/.git` or, when that is a file, the `<common>` its `gitdir:` line names. Any difference → point to `/po-research <id>` and stop.
4. `docs/verif/<id>.md` missing in the worktree → there is no built code to walk yet: point to `/po-execute <id>` and stop.
5. `Dev` is `—` → stop: the project has no command to start it; ask for `Dev` in `AGENTS.local.md`.
6. The story shows no screen → stop and say so: there is nothing to walk.
7. `Model strong` missing → stop and name it.

## Delegation
Call the Agent tool with `subagent_type: qa`, `model:` set to `Model strong` whatever the story's complexity, description "QA <id>", and this prompt, filled in:

> Story <id>. Worktree: <absolute path>. How to work is settled by your agent file. Start every shell command with `cd <absolute path> &&` or use `git -C <absolute path>`. Settings and project commands are in AGENTS.local.md; run `Dev` exactly as written.

Wait for the subagent to finish.

`Model strong` at `—` passes no `model` at all: the qa subagent runs on the session's model. If the Agent tool rejects the model name, stop and report the setting and its value: no `docs/qa/<id>/report.md`, no evidence commit, and never a retry with another model or with none, because the setting is at fault, not the story.

## The evidence commit
The review finds the walk only on the story branch, so the report and its captures are committed there, alone. Do this only when `docs/qa/<id>/report.md` exists in the worktree and holds a `QA status:` line, `complete` or `blocked` alike: a blocked walk is evidence too.
1. `git -C <path> rev-parse --abbrev-ref HEAD` must print `story/<id>`; anything else → stop without committing and say so.
2. `git -C <path> add -- docs/qa/<id>/`
3. `git -C <path> commit -m "<id>: QA evidence" -- docs/qa/<id>/`

The pathspec keeps every other staged or modified file out of this commit. Never pass `--no-verify`: the pre-commit hook's secret scan applies here too. A refused commit is reported with git's message, never worked around. No report → there is nothing to commit; say so.

## Report
Relay the subagent's answer: what was walked, findings by severity and status, what was not seen, the tree and the report path. This command never writes a report: when the agent stops, there is none.
End with the hash of the evidence commit, or the reason there is none.
