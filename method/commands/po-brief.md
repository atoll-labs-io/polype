---
description: Put a new product idea to the test like a skeptical cofounder, one question at a time, and commit an approved docs/brief.md on the target branch
argument-hint: [idea in one sentence]
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Bash
  - Agent
  - WebSearch
  - AskUserQuestion
---
# /po-brief

Reads settings: `Entry mode`, `Target branch`

A project that starts from an idea starts from a brief that has survived objections. `$ARGUMENTS` may carry the idea in one sentence; without it, the interview opens by asking for the pitch.

## Checks
1. No `AGENTS.local.md` → stop: "Run /po-setup first."
2. Read `Entry mode`.
   - `new` → continue.
   - `replace` or `adapt` → stop: "This project starts from an existing SaaS, not from an idea: run /po-prd <target SaaS> instead."
   - `—` → stop: "`Entry mode` is not set: run /po-setup or set it in AGENTS.local.md." Do not guess it from the argument.
3. Read the `interrogation` skill before asking the first question. It holds the stance, the questions, the gap map, the pre-mortem and the alternatives; this command does not repeat them.

## Persistence
- `docs/brief.md` is created from `templates/brief.md` once the first theme is settled.
- After each theme, write what it settled into docs/brief.md and keep status: interviewing.
- Resume: when `docs/brief.md` already exists with `status: interviewing`, recap what it holds in a few lines and continue at the first theme not yet settled — an empty section or an unmarked line of the gap map. With `status: approved` → stop and say the brief is already approved; changing it is the user's call.

## Exit criteria
status: approved is written only when all of these hold:
- the one-liner is written and a stranger would understand it;
- the wedge is named;
- the success metric is stated with how it is measured;
- at least three non-goals are listed;
- every critical dimension of the gap map is `answered`, `defaulted` or `open risk`;
- every pre-mortem finding is settled as `accepted`, `refuted` or `spike`;
- the user has read the whole brief and given explicit agreement.

Until then, keep asking; a missing criterion is the next question.

## Finish
1. Show the whole brief and ask the user to read it end to end. On explicit agreement, set `status: approved`.
2. Write the first ADR from `templates/adr.md` as `docs/decisions/0001-<slug>.md`, or under the next free number when `docs/decisions/` already holds some: the approach chosen among the alternatives, with the ones turned down and why.
3. Commit from the repository root, on `Target branch` only; another branch → stop and say so. Check `git status --porcelain` first: an environment file listed there → stop. Commit `docs/brief.md` and the ADR as `docs: brief for <product>`.

Finish with: "Brief approved. Next: write the stories in docs/stories.md."
