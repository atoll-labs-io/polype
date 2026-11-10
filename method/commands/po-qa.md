---
description: Hands one story's surface to the qa subagent, which checks it with the driver of that surface and returns its report; this command writes that report word for word, then commits the evidence alone. This command cannot edit files; its shell serves that transcription and that commit.
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

This command has no Write or Edit tool. Bash serves exactly two uses, the transcription and the evidence commit below; any other shell command is out of bounds. The `qa` subagent checks the story's surface with its driver and returns its report; it fixes nothing, and neither does this command. Never describe a walk the subagent did not report.

No Agent tool available → say so and stop.

## Preconditions, checked by reading files
1. `AGENTS.local.md` exists; if not, point to `/po-setup` and stop.
2. $ARGUMENTS matches exactly one id of `docs/stories.md`; otherwise list the ids and stop.
3. The worktree is registered, checked as `/po-execute` checks it: `<shared>/worktrees/<id>/gitdir` contains `<repository root>/<Worktree root><id>/.git`, and `<shared>/worktrees/<id>/HEAD` contains `ref: refs/heads/story/<id>`, `<shared>` being `<repository root>/.git` or, when that is a file, the `<common>` its `gitdir:` line names. Any difference → point to `/po-research <id>` and stop.
4. `docs/verif/<id>.md` missing in the worktree → there is no built code to walk yet: point to `/po-execute <id>` and stop.
5. The story's surface is `screen` and `Dev` is `—` → stop: the project has no command to start it; ask for `Dev` in `AGENTS.local.md`.
6. The story's surface is `—`, or it has no `Surface` line and its text shows no screen → stop and say so: there is nothing to check.
7. `Model strong` missing → stop and name it.

## Delegation
Call the Agent tool with `subagent_type: qa`, `model:` set to `Model strong` whatever the story's complexity, description "QA <id>", and this prompt, filled in:

> Story <id>. Worktree: <absolute path>. How to work is settled by your agent file. Start every shell command with `cd <absolute path> &&` or use `git -C <absolute path>`. Settings and project commands are in AGENTS.local.md; run `Dev` exactly as written.

Wait for the subagent to finish.

`Model strong` at `—` passes no `model` at all: the qa subagent runs on the session's model. If the Agent tool rejects the model name, stop and report the setting and its value: no `docs/qa/<id>/report.md`, no evidence commit, and never a retry with another model or with none, because the setting is at fault, not the story.

## The evidence commit
The review finds the walk only on the story branch, so the report and its captures are committed there, alone. Do this only when the subagent's answer holds a `QA status:` line, `complete` or `blocked` alike: a blocked walk is evidence too.
1. `git -C <path> rev-parse --abbrev-ref HEAD` must print `story/<id>`; anything else → stop without writing or committing and say so.
2. Write the answer whole, word for word, into `<path>/docs/qa/<id>/report.md` through one Bash call: `mkdir -p <path>/docs/qa/<id>`, then `cat > <path>/docs/qa/<id>/report.md <<'<DELIM>'`, the answer, and `<DELIM>` alone on the last line. The delimiter is quoted so nothing in the answer expands, and chosen so that no line of the answer equals it; the text never goes into a shell argument (Law 7), since a report quotes command output. You transcribe it, you do not author it: no finding added, softened or dropped, no severity or status changed.
3. `git -C <path> add -- docs/qa/<id>/`
4. `git -C <path> commit -m "<id>: QA evidence" -- docs/qa/<id>/`

The pathspec keeps every other staged or modified file out of this commit. Never pass `--no-verify`: the pre-commit hook's secret scan applies here too. A refused commit is reported with git's message, never worked around. No `QA status:` line → no report, no commit; relay the reason the subagent gave.

## Report
This command never authors a report: it writes the one the subagent returned, word for word, and when the subagent stops without one, there is none. Relay what the report says: what was walked, findings by severity and status, what was not seen, the tree, and the path where it was written.
End with the hash of the evidence commit, or the reason there is none.
