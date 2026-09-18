---
description: Break a story into small, ordered, verifiable tasks and get the plan validated before any code
argument-hint: <story id or name>
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Bash
  - AskUserQuestion
---
# /po-plan — A plan the implementer has nothing left to decide in

Reads settings: `Target branch`, `Worktree root`, `Plan validation`, `Test budget`

Target story: $ARGUMENTS

You write a plan, never code.

## 0. Settings, story, workspace (fail-closed)
- `AGENTS.local.md` missing → STOP: "No project settings. Run /po-setup."
- Resolve $ARGUMENTS to an id in `docs/stories.md`; no unambiguous match → list the stories and stop.
- The worktree `<Worktree root><id>` must exist on exactly `story/<id>`. Missing, wrong branch, detached, or the repository root → STOP: "Run /po-research <id> first." Never create or switch branches here.

Every read and write happens in that worktree.

## 1. Inputs
Read the story in `docs/stories.md`, `docs/research/<id>.md`, `docs/architecture.md` if present, `AGENTS.md`, and the accepted ADRs in `docs/decisions/`. Apply the `testing-doctrine` skill to the test strategy.

No research file → say that planning without it rests on documents that may be stale, and continue only if the user confirms.

**If `docs/plans/<id>.md` already exists, go straight to step 4**: show its summary and run the checkpoint.

## 2. Break it down
- Ordered tasks, each small enough to verify on its own, built on the research's verified facts: real files, real signatures, known traps.
- A behaviour, business rule, data contract or interaction **names the test that can fail**. A purely presentational task names its visual check plus lint and type check instead — never a component test manufactured so every task owns one.
- **`Test budget`** tests at most; beyond it, the test strategy says why. The permission matrix is written once, in the policy test; the service test covers the business rule; no enum exhaustiveness; one rule at one layer; no adapter re-asserting a 403.
- **Run interdicts**: what must not change and what must not be done, each checkable by the reviewer.
- **The pivot**: the decision everything rests on and where it could be wrong.
- Past roughly ten tasks, or a story scored 5, the story is too big: say so and propose a split rather than a bloated plan.
- A structural choice with rejected alternatives (library, pattern, data model) becomes an ADR in `docs/decisions/` (`templates/adr.md`); it travels with the story branch.

## 3. Write
`docs/plans/<id>.md`, shaped by `templates/plan.md`, frontmatter `validated: no`. **At most ~250 lines**: cut prose, keep the decision table whole.

## 4. Validation — per `Plan validation`
- `human` → checkpoint with AskUserQuestion, "Validate this plan?": Validate / Change / Stop. Only Validate writes `validated: yes` into the frontmatter.
- `autonomous` → re-read the plan against every acceptance criterion, then write `validated: yes` yourself and say plainly that nobody else read it.

`/po-execute` refuses any plan without `validated: yes` in its frontmatter.

End with: "Plan validated. Next: /po-execute <id>" — or "Plan awaiting validation. Rerun /po-plan <id> to validate."
