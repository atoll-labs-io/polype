---
description: Have a story implemented by the implementer subagent in its worktree. This context never writes code.
argument-hint: <story id or name>
allowed-tools:
  - Read
  - Glob
  - Grep
  - Agent
---
# /po-execute — Delegated implementation

Reads settings: `Worktree root`, `Test budget`, `Full suite`

Target story: $ARGUMENTS

## Contract
You complete this command by delegating to the `implementer` subagent. You have no Write, Edit or Bash tool, on purpose: this context **cannot** write code. You never:
- start without a validated plan;
- run a story outside its worktree, whatever its size;
- report work the implementer did not do.

If the Agent tool is unavailable, stop and say so. Never improvise.

## 1. Prerequisites (fail-closed), all by reading files
1. `AGENTS.local.md` missing → STOP: "No project settings. Run /po-setup."
2. Resolve $ARGUMENTS to an id in `docs/stories.md`; no unambiguous match → list the stories and stop.
3. The worktree `<repository root>/<Worktree root><id>` exists, and `<repository root>/.git/worktrees/<id>/HEAD` reads exactly `ref: refs/heads/story/<id>`. Otherwise → STOP: "Run /po-research <id> first."
4. `docs/plans/<id>.md` in the worktree exists → otherwise STOP: "Run /po-plan <id> first."
5. Its frontmatter contains `validated: yes` → otherwise STOP: "Plan not validated. Review it, then rerun /po-plan <id>."
6. `docs/reviews/<id>.md` exists and says `Ship allowed: no` → this is a **fix run**: the findings come first.

## 2. Delegate
Agent tool:
- subagent_type: `implementer`
- description: Implement story <id>
- working directory: the absolute worktree path
- prompt: "Implement story <id> from docs/plans/<id>.md in <absolute worktree path>. Your definition is your contract; this prompt only carries what is specific to this run. The worktree and branch are ready and verified: never create a worktree, switch branch, checkout or stash. Project commands, `Test budget` and the stages are in AGENTS.local.md — quote them verbatim; a command set to `—` does not exist in this project."
- on a fix run, add: "The last review blocked this story. docs/reviews/<id>.md is your fix list; your definition says how to work through it."

Wait for it to finish.

## 3. Report
Tasks done, files touched, tests added and removed, what `docs/verif/<id>.md` records (commands, exit codes, tree), every deviation from the plan and every blocker the implementer reported. No line-by-line detail.

End with: "Implementation done. Next: /po-review <id>"
