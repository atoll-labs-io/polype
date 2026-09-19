---
validated: yes
---
# Plan — s19-flow

Branch `story/s19-flow`. Read `docs/research/s19-flow.md` first; this plan builds on it without repeating it.

## Story
`/po-flow <story>` does research and plan in one pass for a simple story, then walks the same execute → review → ship cycle, so a small story costs three contexts (the flow context, `implementer`, `reviewer`) instead of six. Nothing is relaxed. Criteria (each the name of one test in `tests/flow.test.sh`): `flow_keeps_every_gate`, `flow_checks_escalation_signals_twice`, `flow_respects_story_track`, `plan_flow_template_carries_verified_facts`.

## Decisions

| Question | Decision | Why |
| --- | --- | --- |
| Scope of the command | Research + plan merged in this context, then execute, review and ship applied as their command files say, with `implementer` and `reviewer` delegated | D15 "same cycle in three contexts"; research open question 1 |
| Track check (first) | `Story track` is `full` → refuse, point to `/po-research <id>`. `flow` → accepted. `auto` → accepted only when the story's complexity is ≤ `Flow threshold`; no complexity in the story → refuse | Criterion 3; fail closed per « Reading settings » |
| Escalation signals | Five: a migration, a new screen, authorization or tenant scope, an API contract, a new dependency. Checked on the story text **before** the worktree is made, and on the code **after** reading it. A single one → stop and point to the full track | Criterion 2; D15 |
| Escalation after reading | Worktree kept; nothing written; `/po-research <id>` reuses the worktree | Research trap; Law 4 |
| Task ceiling | More than about six tasks → escalate to the full track | D15 "≤ ~6 tâches" |
| Worktree | Created or confirmed exactly as `/po-research` says (fresh `Target branch`, ignored `.env*` copied, `Install`, no tests) | Criterion 1 |
| Plan file | `docs/plans/<id>.md` from `templates/plan-flow.md`, frontmatter `track: flow` and `validated: no`, ~150 lines max, uncommitted | Criterion 4; gate reads only `validated:` |
| Approval | Exactly `/po-plan`'s rule per `Plan validation`; only then `validated: yes` | Criterion 1 |
| Missing research file | Delegation prompts to `implementer` and `reviewer` add: the story is on the short track, there is no research file, the plan's `## Verified facts` stands in for it | Research fact 1; agent files out of Owns |
| Review loop | As `/po-review`: `Fix loop:`, missing verdict → blocked, two fix runs then a human | Criterion 1 |
| Ship | `/po-ship` whole: `Ship allowed` gate, expensive checks, confirmation per settings, cleanup after proof | Criterion 1 |
| Settings read | `Target branch`, `Worktree root`, `Install`, `Story track`, `Flow threshold`, `Plan validation`, `Test budget`, `Verification mode`, `Full suite`, `Merge mode`, `Ship confirmation` (all in the template) | Structure test |
| Tools | Read, Glob, Grep, Write, Bash, Agent, AskUserQuestion — no Edit | Writes docs and worktree, never code |
| Outside Owns | One `/po-flow` line in `po-help.md`; D15 status cell | Help test; conventions; s18 precedent |

## Tasks
1. [x] `method/templates/plan-flow.md` — frontmatter `track: flow` and `validated: no`; `# Plan (short track) — <id>`; intro line: written by `/po-flow`, replaces both research and plan, **about 150 lines at most**. Sections in order: `## Verified facts` (each fact opened in the code, with its `path:line`; wrong assumptions of the story first), `## Escalation signals` (the five, each `absent` with where it was checked, before and after reading the code), `## Story`, `## Tasks` (six at most), `## Run interdicts`, `## Files touched`, `## Test strategy`, `## Done when`. — Test: `plan_flow_template_carries_verified_facts`.
2. [x] `method/commands/po-flow.md` — frontmatter (`description`, `argument-hint: <story id or name>`, tools as decided); `# /po-flow`; `Reads settings:` as decided; `Story: $ARGUMENTS`. Sections:
   - `## Checks`: no `AGENTS.local.md` → `/po-setup`; id match; no Agent tool → stop.
   - `## Which track`: exact phrases `` `Story track` is `full` ``, `` `auto` ``, `` `Flow threshold` ``, the missing-complexity refusal.
   - `## Escalation signals`: the five signals listed; exact phrases `before reading the code`, `after reading the code`, `A single signal`; escalation after reading keeps the worktree and points to `/po-research <id>`; more than about six tasks escalates too.
   - `## The worktree`: as `/po-research`; `story/<id>`.
   - `## Reading the code`: `codebase-analysis` skill, test the story's assumptions, then the second signal check.
   - `## The plan`: fill `templates/plan-flow.md` into `docs/plans/<id>.md`, `validated: no`, within `Test budget`, uncommitted.
   - `## Approval`: `/po-plan`'s rule per `Plan validation`, writes `validated: yes`.
   - `## Execute, review, ship`: delegate as `/po-execute` (`subagent_type: implementer`) and `/po-review` (`subagent_type: reviewer`), with the extra short-track sentence about `## Verified facts`; fix loops as `/po-review`; then `/po-ship` from its Step 0.
   - `## Nothing is relaxed`: exact sentence `Only the number of contexts goes down.`; lists same worktree, `validated: yes`, delegated implementer and reviewer, `Ship allowed: yes`, `Test budget`.
   - Finish lines: shipped / PR ready / escalated with next command.
   — Tests: `flow_keeps_every_gate`, `flow_checks_escalation_signals_twice`, `flow_respects_story_track`.
3. [x] `method/commands/po-help.md`: under « Outils », `` - `/po-flow <story>` — voie courte pour une petite story : research et plan en une passe, puis le même cycle, sans rien alléger. `` — Test: existing `every_command_listed_in_help`.
4. [x] `tests/flow.test.sh`, header `# s19 — /po-flow and the plan-flow template.`, local `section_of` (as `tests/design.test.sh:9`):
   - `test_flow_keeps_every_gate`: `needs_tool` Agent; in `## Nothing is relaxed`: `Only the number of contexts goes down.`, `story/<id>`, `validated: yes`, `Ship allowed: yes`, `` `Test budget` ``; in `## Execute, review, ship`: `subagent_type: implementer`, `subagent_type: reviewer`, `/po-ship`.
   - `test_flow_checks_escalation_signals_twice`: in `## Escalation signals`: the five signal phrases, `before reading the code`, `after reading the code`, `A single signal`.
   - `test_flow_respects_story_track`: `Reads settings:` lists `Story track` and `Flow threshold`; in `## Which track`: `` `Story track` is `full` ``, `` `auto` ``, `` `Flow threshold` ``.
   - `test_plan_flow_template_carries_verified_facts`: frontmatter has lines `track: flow` and `validated: no`; `## Verified facts` and `## Escalation signals` headings; phrases `path:line` and `150 lines`.
5. [x] `docs/parite-killer-saas.md`: D15 → `fait — \`method/commands/po-flow.md\`, \`method/templates/plan-flow.md\``. No other line.
6. [x] Full suite `bash tests/run.sh` (`Full suite: execute-end`); record in `docs/verif/s19-flow.md`.

## Run interdicts
- Empty diff for `.claude/`, `.polype/`, `AGENTS.md`, `AGENTS.local.md`, `docs/stories.md`, `docs/decisions/`, `bin/`, `tests/lib.sh`, every existing test, `method/AGENTS.md`, `method/agents/`, `method/skills/`, `method/hooks/`, every existing `method/templates/` file, and every existing `method/commands/` file except the one line of `po-help.md`.
- `docs/parite-killer-saas.md`: only the D15 line changes.
- No new setting in `method/templates/agents-local.md`.
- No orchestrator, status or rules wiring of the track (s20).
- No sentence from Killer SaaS (`tests/overlap.test.sh` green); never open Killer SaaS's `ks-flow` or `plan-flow`.

## The pivot
`/po-flow` merges research and plan but hands everything after to the unchanged stages and their gates. Ways it could be wrong: (a) a gate quietly softened — compare `## Execute, review, ship` with `po-execute.md`, `po-review.md`, `po-ship.md`; (b) the second signal check missing its consequence once the worktree exists — read `## Escalation signals`; (c) agents told nothing about the missing research — look for the short-track sentence in both prompts; (d) `auto` accepting a story without a complexity.

## Files touched
New: `method/commands/po-flow.md`, `method/templates/plan-flow.md`, `tests/flow.test.sh`. Edited: one line of `method/commands/po-help.md`, the D15 line of `docs/parite-killer-saas.md`. Plus `docs/research/`, `docs/plans/`, `docs/verif/` for this story.

## Test strategy
Four structural tests in `tests/flow.test.sh`, one per criterion (budget 25), each pinning its clauses to the section that must hold them. Existing `every_command_listed_in_help`, `every_setting_read_by_a_command_exists_in_template`, install tests and `method_does_not_reuse_killer_saas_text` cover the rest. No visual checks: prose only.

## Done when
Full suite green, one commit `s19-flow: …` on `story/s19-flow` with code, tests and docs, verification record complete, review with no open critical finding.
