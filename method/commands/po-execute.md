---
description: Hands an approved plan to the implementer subagent. This command cannot edit files or run a shell, by construction.
argument-hint: <story id or name>
allowed-tools:
  - Read
  - Glob
  - Grep
  - Agent
---
# /po-execute

Reads settings: `Worktree root`, `Test budget`, `Full suite`

Story: $ARGUMENTS

This command has no Write, Edit or Bash tool. That is deliberate: the context that coordinates a story is unable to write its code. The `implementer` subagent does it. Do not start without an approved plan, do not work outside the story's worktree, and never describe work the implementer did not report.

No Agent tool available → say so and stop.

## Preconditions, checked by reading files
1. `AGENTS.local.md` exists; if not, point to `/po-setup`.
2. $ARGUMENTS matches exactly one id of `docs/stories.md`; otherwise list the ids and stop.
3. The worktree is registered. First find the shared git directory: if `<repository root>/.git` is a folder, that folder; if it is a file (the repository root is itself a linked worktree), it reads `gitdir: <common>/worktrees/<name>` and the shared directory is `<common>`. Then `<shared>/worktrees/<id>/gitdir` contains `<repository root>/<Worktree root><id>/.git`, and `<shared>/worktrees/<id>/HEAD` contains `ref: refs/heads/story/<id>`. Any difference (missing files, another path, another branch) → point to `/po-research <id>` and stop.
4. `docs/plans/<id>.md` exists in the worktree; otherwise point to `/po-plan <id>`.
5. Its frontmatter holds `validated: yes`; otherwise stop with "The plan for <id> is not approved yet. Review it, then run /po-plan <id>."
6. `docs/reviews/<id>.md` exists in the worktree with `Ship allowed: no` as its last verdict → this is a **fix run**; the review's findings come before anything else.
7. Glob `docs/designs/<id>/*` in the worktree: any match means the story **has a design**, even when no orchestrator runs it.

## Delegation
Call the Agent tool with `subagent_type: implementer`, description "Implement <id>", and this prompt, filled in:

> Story <id>. Worktree: <absolute path>. Plan: docs/plans/<id>.md. How to work is settled by your agent file; below are the details of this story. Worktree and branch already exist — create no worktree or branch, never checkout or stash. Start every shell command with `cd <absolute path> &&` or use `git -C <absolute path>`. Settings and project commands are in AGENTS.local.md; run the commands exactly as written, and treat `—` as "this project has none".

For a fix run, append:

> The last review blocked this story. Work from docs/reviews/<id>.md as your agent file describes for fix runs.

When the story has a design, append:

> This story has a design: docs/designs/<id>/ is expected uncommitted work, like the research and the plan. Read design.md before the screen tasks, build the screen it settles, and commit the folder with the story.

Wait for the subagent to finish.

## Report
From the subagent's answer: tasks completed, files changed, tests added or removed, the contents of `docs/verif/<id>.md` (commands, exit codes, tree), deviations from the plan and blockers. A summary, not a transcript.

Finish with: "Implementation finished. Next: /po-review <id>"
