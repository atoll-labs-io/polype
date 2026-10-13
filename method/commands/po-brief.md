---
description: Put a new product idea to the test like a skeptical cofounder, one question at a time, and land an approved docs/brief.md on the target branch through a pull request
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

Reads settings: `Entry mode`, `Target branch`, `ADR directory`, `Merge mode`, `Ship confirmation`

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

## Approval
Before a theme is written, its section goes to the user alone, one section per question, with AskUserQuestion: a summary of what the section settles and why, which the user answers Approve / Change / Set aside.
The summary aims short and grows when the subject needs it: no fact needed to decide is cut to keep it short.
Each item is written only once approved, and the commit asks for no rereading.
- Approve → write the section and move on.
- Change → back to the questions of that theme, then ask about the section again.
- Set aside → drop the draft and leave that theme unsettled: the interview comes back to it.

The interrogation skill's last exit criterion, agreement after reading the whole brief, is met here by these one-section approvals: never ask for the file to be read.

## Exit criteria
status: approved is written only when all of these hold:
- the one-liner is written and a stranger would understand it;
- the wedge is named;
- the success metric is stated with how it is measured;
- at least three non-goals are listed;
- every critical dimension of the gap map is `answered`, `defaulted` or `open risk`;
- every pre-mortem finding is settled as `accepted`, `refuted` or `spike`;
- every section has the user's explicit agreement, given on its own question.

Until then, keep asking; a missing criterion is the next question.

## Finish
1. Run the blocking checks first, before a single approved byte is written: the current branch is `Target branch`, another branch → stop and say so; `git status --porcelain` lists no environment file, one listed → stop. Stopping here, or anywhere before the last step, leaves `docs/brief.md` at `status: interviewing` — nothing is approved until the commit lands.
2. Every section was approved on its own question during the interview; nothing is shown again for reading, so set `status: approved`.
3. Write the first ADR from `templates/adr.md` as `<ADR directory>0001-<slug>.md`, or under the next free number when the `ADR directory` folder already holds some: the approach chosen among the alternatives, with the ones turned down and why.
4. From the repository root, commit `docs/brief.md` and the ADR together in one commit, `docs: brief for <product>`, on the branch `framing/brief`, landed as `## Landing the framing` of `/po-setup` says (`method/commands/po-setup.md`). The approval and its ADR go in the same commit, or neither: an ADR that is not written yet is written before committing, and neither of the two is ever committed alone.

Finish with: "Brief approved. Next: write the stories in docs/stories.md."
