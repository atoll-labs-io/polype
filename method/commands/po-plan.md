---
description: Turns a researched story into an ordered list of small, testable tasks and gets it approved — no code
argument-hint: <story id or name>
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Bash
  - AskUserQuestion
---
# /po-plan

Reads settings: `Target branch`, `Worktree root`, `Plan validation`, `Test budget`

Story: $ARGUMENTS

You produce `docs/plans/<id>.md` and its approval; source files are out of reach for this command.

## Checks first
- No `AGENTS.local.md` → stop and point to `/po-setup`.
- Match $ARGUMENTS to one id of `docs/stories.md`; none or several → list the ids and stop.
- `<Worktree root><id>` must exist and `git -C <path> rev-parse --abbrev-ref HEAD` must print `story/<id>`. If not, stop and point to `/po-research <id>`. No branch creation or switching here.

Everything below reads and writes inside the worktree.

**A plan file already present?** Skip to "Approval" with a summary of it.

## Inputs
The story, `docs/research/<id>.md`, `docs/designs/<id>/design.md` when it exists, `AGENTS.md`, `docs/architecture.md` if present, and the accepted ADRs. The test strategy follows the `testing-doctrine` skill.

Without a research file, warn that the plan would rest on documents that may no longer match the code, and continue only on the user's go-ahead.

## Writing the plan
- Tasks in execution order, each one checkable on its own and grounded in the research: real files, real signatures, the traps it found.
- For behaviour, business rules, data contracts and interactions, each task names **the test that would fail if the task were wrong**. A purely visual task names the visual check plus lint and type check instead; do not invent a component test to fill the column.
- Stay within `Test budget`, or explain the excess in the test strategy. Access rules go in the policy's tests only; services test business rules; no pair-by-pair enum tests; each rule at one layer; adapters do not retest a 403.
- **Run interdicts**: what must stay untouched and what must not be done, each verifiable by the reviewer.
- **The pivot**: the decision everything hinges on and how it could be wrong.
- When `docs/designs/<id>/design.md` exists, the screen tasks build what it settles, cite it, and add nothing it leaves out.
- More than about ten tasks, or a story rated 5 → recommend splitting the story instead of writing a long plan.
- A structural choice with alternatives (library, pattern, data model) gets an ADR in `docs/decisions/` from `templates/adr.md`; it stays on the story branch.

Fill `templates/plan.md` into `docs/plans/<id>.md`, frontmatter `validated: no`, **250 lines at most**. Shorten prose, keep decision tables whole.

## Approval — per `Plan validation`
- `human`: AskUserQuestion "Approve the plan for <id>?" with the tasks, files and test strategy summarised; answers Approve / Change / Stop. Write `validated: yes` into the frontmatter on Approve and on nothing else.
- `autonomous`: check the plan against each acceptance criterion yourself, write `validated: yes`, and state that no human reviewed it.

`/po-execute` will not start on a plan whose frontmatter lacks `validated: yes`.

Finish with: "Plan approved. Next: /po-execute <id>" — or "Plan written, not approved yet. Run /po-plan <id> again to approve it."
