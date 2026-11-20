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

Reads settings: `Worktree root`, `Plan validation`, `Test budget`, `ADR directory`

Story: $ARGUMENTS

You produce `docs/plans/<id>.md` and its approval; source files are out of reach for this command.

## By hand
A subagent skips this paragraph. This plan is written on the session's model, which no command can choose (ADR-0036); start the session on `Model strong`. Run `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" next` and read the story's entry as `/po-drive <id>` does; `po` missing or exiting 2 → stop, naming `polype install`; no `AGENTS.local.md` → stop, naming `/po-setup`. Go on only on `plan` with reason `research, no plan` or `plan-validated refuses`, on `validate-plan`, or on the `ask` whose reason is `Technical choice: waiting for a human`. Any other entry, or a warning naming the story, is reported, an `ask` as a question for the person, and ends the command. At the end, report a new `po next` entry likewise.

Everything below reads and writes inside `<Worktree root><id>`.

**A plan file already present?** Skip to "Approval" with a summary of it. When it holds the line `Technical choice: waiting for a human`, that choice is the first thing "Approval" puts to the person.

## Inputs
The story, `docs/research/<id>.md`, `docs/designs/<id>/design.md` when it exists, `AGENTS.md`, `docs/architecture.md` if present, and the accepted ADRs. The test strategy follows the `testing-doctrine` skill.

## Writing the plan
- Tasks in execution order, each one checkable on its own and grounded in the research: real files, real signatures, the traps it found. Each names the test that would fail if it were wrong; a purely visual task names its visual check instead.
- **Acceptance tests**: before the plan, write the oracle files its `## Acceptance tests` names and no other test file, then record their sums. An oracle file outside the story's `Owns` is not written: report it as a gap of the story, in that criterion's row.
- When `docs/designs/<id>/design.md` exists, the screen tasks build what it settles, cite it, and add nothing it leaves out.
- More than about ten tasks, or a story rated 5 → recommend splitting the story instead of writing a long plan.
- A choice that deserves an ADR (library, pattern, data model) is not settled here. Draft it as an ADR in `<ADR directory>` from `templates/adr.md` with `status: proposed`, its options ranked by the owner's criteria as `## Ranking the options` of the `capability-bricks` skill says; it stays on the story branch. Write the tasks for the top-ranked option, name the ADR in the plan, and put the line `Technical choice: waiting for a human` alone on its line in the plan body. Such a plan never validates itself, whatever `Plan validation` says (ADR-0077).

Fill `templates/plan.md` into `docs/plans/<id>.md`, frontmatter `validated: no`, **250 lines at most**. Shorten prose, keep decision tables whole.

## Approval — per `Plan validation`
A plan holding the line `Technical choice: waiting for a human` is settled with the person first, whatever `Plan validation` says: AskUserQuestion with the ADR's options in their ranked order, the person free to answer something else. Then set the ADR to `status: accepted`, or rewrite it for the option chosen; rewrite the tasks the choice changes; remove the marker line. Only then do the two bullets below apply.

- `human`: AskUserQuestion "Approve the plan for <id>?" with the tasks, files and test strategy summarised; answers Approve / Change / Stop. Write `validated: yes` into the frontmatter on Approve and on nothing else.
- `autonomous`: check the plan against each acceptance criterion yourself, write `validated: yes`, and state that no human reviewed it.
