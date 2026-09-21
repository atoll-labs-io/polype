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
1. Run the blocking checks first, before a single approved byte is written: the current branch is `Target branch`, another branch → stop and say so; `git status --porcelain` lists no environment file, one listed → stop. Stopping here, or anywhere before the last step, leaves `docs/brief.md` at `status: interviewing` — nothing is approved until the commit lands.
2. Show the whole brief and ask the user to read it end to end. On explicit agreement, set `status: approved`.
3. Write the first ADR from `templates/adr.md` as `docs/decisions/0001-<slug>.md`, or under the next free number when `docs/decisions/` already holds some: the approach chosen among the alternatives, with the ones turned down and why.
4. From the repository root, commit `docs/brief.md` and the ADR together in one commit, `docs: brief for <product>`. The approval and its ADR go in the same commit, or neither: an ADR that is not written yet is written before committing, and neither of the two is ever committed alone.

Finish with: "Brief approved. Next: write the stories in docs/stories.md."
