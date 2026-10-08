---
description: Has docs/stories.md judged against the approved PRD or brief by a subagent that did not write it, and commits the verdict in docs/reviews/stories.md
allowed-tools:
  - Read
  - Glob
  - Grep
  - Agent
  - Write
  - Bash
---
# /po-stories-review

Reads settings: `Entry mode`, `Target branch`, `Model strong`, `Platform`

Whoever cut the stories is the worst placed to see what they left out. This command hands `docs/stories.md` and its scope source to the `stories-reviewer` subagent, in a fresh context, and writes `docs/reviews/stories.md` on `Target branch` from its answer. It never edits the stories.

## Checks
1. No Agent tool available → say so and stop.
2. No `AGENTS.local.md` → stop: "Run /po-setup first."
3. No `docs/stories.md` → stop: "No stories yet: run /po-stories first."
4. Read `Entry mode`.
   - `replace` or `adapt` → the scope source is `docs/prd.md`. Missing → stop: "No PRD yet: run /po-prd <target SaaS> first."
   - `new` → the scope source is `docs/brief.md`. Missing → stop: "No brief yet: run /po-brief first."
   - `—` → stop: "`Entry mode` is not set: run /po-setup or set it in AGENTS.local.md." Do not pick whichever file exists.
5. Run from the repository root, on `Target branch`. Another branch → stop and say so; do not switch.
6. `Model strong` missing → stop and name it.
7. `Platform` missing → stop and name it.

## Delegation
Agent tool, `subagent_type: stories-reviewer`, `model:` set to `Model strong`, description "Review stories", prompt filled in:

> Review `docs/stories.md` in <absolute repository root>, against the scope source `<docs/prd.md | docs/brief.md>` (Entry mode: <value>, Platform: <value>). How to review is settled by your agent file and the stories-review skill. Start with the coverage table. Shape your answer like templates/stories-review.md, report every finding now, and end with the lines `Max severity:` and `Stories ready:`.

`Model strong` at `—` passes no `model` at all: the stories-reviewer runs on the session's model. If the Agent tool rejects the model name, stop and report the setting and its value: write no `docs/reviews/stories.md`, make no commit, and never retry with another model or with none, because the setting is at fault, not the stories.

## Recording
Write the subagent's answer, whole, to `docs/reviews/stories.md`, replacing any earlier review: git keeps the previous ones. It must contain `Review status:` and end with `Max severity: …` then `Stories ready: yes|no`.

If the subagent fails, times out, returns nothing, or returns a report without both verdict lines, write the file yourself from `templates/stories-review.md`: `Review status: blocked`, the concrete cause, what is missing, what must change, then `Max severity: critical` and `Stories ready: no`. Never guess a verdict.

## Commit
Check `git status --porcelain` first: an environment file listed there → stop. Commit `docs/reviews/stories.md` alone on `Target branch` as `docs: stories review`.

## Outcome
- `Stories ready: yes` → "Stories reviewed. Next: /po-research <first story id>"
- `Stories ready: no` → list the critical findings, then: "Fix `docs/stories.md` by hand or with /po-stories, then run /po-stories-review again."

The verdict is a soft gate: `/po-research` warns when `docs/reviews/stories.md` is missing or says `Stories ready: no`, and carries on anyway.
