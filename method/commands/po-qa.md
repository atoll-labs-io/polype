---
description: Hands one story's surface to the qa subagent, records its report and commits the evidence alone
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

Bash serves exactly three uses, `po next` by hand, the record and the evidence commit below; any other shell command is out of bounds. Never describe a walk the subagent did not report.

## By hand
`/po-drive` skips this section. Run `po next` and route as `## By hand` of `/po-execute` says, going on only on `qa`, or on the `ask` `QA status: blocked` once the person has settled what blocked the walk. The story's surface is `screen` and `Dev` is `—` → stop: the project has no command to start it; ask for `Dev` in `AGENTS.local.md`.

## Delegation
Reason `QA evidence not committed` → no walk: go straight to `## The evidence commit`.

Call the Agent tool with `subagent_type: qa`, `model:` set to `Model strong` whatever the story's complexity, description "QA <id>", and this prompt, filled in:

> Story <id>. Worktree: <absolute path>. How to work is settled by your agent file. Run git as `git -C <absolute path>`, every other command after `cd <absolute path> &&`. Settings and project commands are in AGENTS.local.md; run `Dev` exactly as written.

`Model strong` at `—` passes no `model` at all. If the Agent tool rejects the model name, stop and report the setting and its value: no `docs/qa/<id>/report.md`, no evidence commit, and never a retry with another model or with none, because the setting is at fault, not the story.

## The evidence commit
The review finds the walk only on the story branch, so the report and its captures are committed there, alone. A blocked walk is evidence too: `complete` or `blocked` alike.
1. `git -C <path> rev-parse --abbrev-ref HEAD` must print `story/<id>`; anything else → stop without writing or committing and say so.
2. Pipe the answer, whole and word for word, into `cd <path> && "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" record qa <id>` through a quoted heredoc whose delimiter no line of the answer equals, never a shell argument (Law 7). `po` writes `docs/qa/<id>/report.md`, its header and its `Method version:` stamp; you do not author it. With no new walk and a report on disk (a resume path), pipe that report back: `< <path>/docs/qa/<id>/report.md`. Exit 1 → no report, no commit; `po` missing or another refusal → stop and name `polype install`.
3. `git -C <path> add -- docs/qa/<id>/`
4. `git -C <path> commit -m "<id>: QA evidence" -- docs/qa/<id>/`

The pathspec keeps every other staged or modified file out of this commit. Never pass `--no-verify`: the pre-commit hook's secret scan applies here too. A refused commit is reported with git's message, never worked around. No `QA status:` line → no report, no commit; relay the reason the subagent gave.

## Report
This command never authors a report: it records the one the subagent returned, word for word, and when the subagent stops without one, there is none. Relay what the report says: what was walked, findings by severity and status, what was not seen, the tree, and the path where it was written.
End with the hash of the evidence commit, or the reason there is none.
