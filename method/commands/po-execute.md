---
description: Hands an approved plan to the implementer subagent. This command cannot edit files or run a shell, except po next (ADR-0120).
argument-hint: <story id or name>
allowed-tools:
  - Read
  - Glob
  - Grep
  - Agent
  - Bash("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" next)
---
# /po-execute

Reads settings: `Worktree root`, `Model strong`, `Model light`, `Light up to`

Story: $ARGUMENTS

## By hand
`/po-drive` skips this section. Run `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" next` exactly so, from your start directory, without `cd`, and read the story's entry as `/po-drive <id>` does; `po` missing or exiting 2 → stop, naming `polype install`; no `AGENTS.local.md` → stop, naming `/po-setup`; no Agent tool, or a setting this command reads missing → stop, naming it. Go on only on `execute` or `fix`, or on `ship` once `/po-ship` stopped on failing checks, which `po next` cannot see. On `validate-plan`, stop with "The plan for <id> is not approved yet. Review it, then run /po-plan <id>." Any other entry, or a warning naming the story, is reported and ends the command; on `ask`, stop; a person decides, given the reason. At the end, report a new `po next` entry likewise.

## Model
- **Rule.** The implementer gets `Model light` when the story's complexity is at most `Light up to`, `Model strong` above it.
- **Complexity read.** The score after `→` on the first line of `## Complexity` in `docs/research/<id>.md`. No research file → the `Complexité`/`Complexity` of the story in `docs/stories.md`. Neither gives a score → `Model strong`.
- **`—`.** A model setting at `—` passes no `model` at all: the subagent runs on the session's model. `Light up to: —` means the implementer never takes `Model light`.
- **Refusal.** If the Agent tool rejects the model name, stop and report the setting and its value. Never retry with another model or with none.

## Delegation
Call the Agent tool with `subagent_type: implementer`, `model` as `## Model` settles, description "Implement <id>", and this prompt, filled in:

> Story <id>. Worktree: <absolute path>. Plan: docs/plans/<id>.md. How to work is settled by your agent file; below are the details of this story. Worktree and branch already exist — create no worktree or branch, never checkout or stash in the story worktree. Run git as `git -C <absolute path>`, every other command after `cd <absolute path> &&`. Settings and project commands are in AGENTS.local.md; run the commands exactly as written, and treat `—` as "this project has none".

For a fix run — `po next` answered `fix`, or `execute` while the last `Ship allowed:` of `docs/reviews/<id>.md` is `no` — append:

> The last review blocked this story. Work from docs/reviews/<id>.md as your agent file describes for fix runs.

When `docs/designs/<id>/` holds a file, append:

> This story has a design: docs/designs/<id>/ is expected uncommitted work, like the research and the plan. Read design.md before the screen tasks, build the screen it settles, and commit the folder with the story.

When the plan's frontmatter holds `track: flow`, append:

> This story is on the short track: there is no docs/research/<id>.md. The `## Verified facts` section of the plan takes its place.

When `## Acceptance tests` of the plan names at least one file, append:

> This story has an oracle: each file that `## Acceptance tests` of docs/plans/<id>.md names is expected uncommitted work, like the research and the plan. Leave its tests as the planner wrote them, change one only through `## Oracle changes` of docs/verif/<id>.md, and commit them with the story.

## Report
From the subagent's answer: tasks completed, files changed, tests added or removed, the contents of `docs/verif/<id>.md` (commands, exit codes, tree), deviations from the plan and blockers, and the model passed to the implementer (or `session` when `—` passed none).
