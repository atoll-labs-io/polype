---
validated: yes
---
# Plan — s13-brief-new

Branch `story/s13-brief-new`. Read `docs/research/s13-brief-new.md` first; this plan builds on it without repeating it.

## Story
`/po-brief` challenges a new idea like a skeptical cofounder and leaves `docs/brief.md`, approved, on `Target branch`. Criteria (each is the name of one test in `tests/brief.test.sh`): `brief_runs_only_in_new_mode`, `interrogation_skill_has_stance_forcing_questions_gap_map_premortem`, `brief_persists_between_sessions`, `brief_has_exit_criteria`.

## Decisions

| Question | Decision | Why |
| --- | --- | --- |
| Source of the procedure | `method/skills/interrogation/SKILL.md` holds the whole procedure, written in English in our own words from `docs/references/spec-interrogation.md`; never refers to that path | `docs/references/` is not installed (research, fact 1) |
| Split command / skill | The skill holds stance, mechanics, sequence, gap map, pre-mortem, alternatives, exit criteria; `po-brief.md` holds checks, mode gate, persistence/resume, finish and commit, and tells the agent to read the skill first | Keeps the skill reusable (s12's adapt probes, later stories) and the command short |
| Web research on incumbents | `po-brief` gets `WebSearch`; the skill says to search before the incumbents theme and, when no search tool is available, to ask the user to name the tools instead | Reference asks to research, not ask; conditional keeps it portable |
| Pre-mortem subagent | "a fresh subagent, through the `Agent` tool, given only the brief draft" — no named built-in type | Criterion requires fresh context only; a Claude Code type name would tie the method to one harness version |
| Alternatives → ADR | The chosen approach and the rejected ones go into the brief's `## Alternatives considered`; at finish, `po-brief` writes the first ADR `docs/decisions/0001-<slug>.md` from `templates/adr.md` (next free number if some exist) and commits it with the brief | Law 6: structural decisions are ADRs listing options turned down |
| `po-help.md` outside Owns | Add one French line after `/po-prd` in « Mise en place »; nothing else | `tests/pilot.test.sh:38` requires every command in the help; same exception as s12 |

## Tasks
1. [x] `method/templates/brief.md`: frontmatter `product`, `status: interviewing` (comment-free; the body says the values are `interviewing` → `approved`), `date`; body `# Brief — <product>`, `**One-liner.**`, then sections `## Problem & evidence`, `## Consumer & job`, `## Status quo & incumbents`, `## Wedge & non-goals`, `## Success metric`, `## Premises`, `## Gap map` (table `| Dimension | Status | Evidence, default or risk |`), `## Pre-mortem findings` (table `| Finding | Outcome | Reasoning |`), `## Alternatives considered` (table `| Approach | Effort | Risk | What it gives up |`), `## Open risks & spikes`. Placeholders in the `<…>` style of `templates/prd.md`. — Test: `brief_persists_between_sessions` checks `status: interviewing` in the template frontmatter.
2. [x] `method/skills/interrogation/SKILL.md`: frontmatter `name: interrogation`, `description:`. Sections, own wording:
   - `## Stance` — must contain the exact phrase `skeptical cofounder`; take positions, specifics over categories, keep "don't build it" alive.
   - `## Mechanics` — one question per message; one-line recap before each question; persist after each theme; research incumbents before asking.
   - `## Forcing questions` — exactly seven numbered items, each starting with a bold name: `**Evidence of pain**`, `**Status quo**`, `**Exact consumer**`, `**Narrowest wedge**`, `**Success signal**`, `**Why now**`, `**Future-fit**`.
   - `## Premises`, then `## Gap map` — the dimension table with a `★` on the critical ones: Problem & evidence, Consumer & job, Wedge & non-goals, Success metrics, Incumbents & alternatives, Domain model, Interface contract, Security & abuse, Evaluation (9 ★), plus Product & distribution, Quality attributes, Operations, Technical unknowns; the four statuses `answered`, `defaulted`, `open risk`, `N/A`; the sentence `A critical dimension (★) never stays unmarked.`
   - `## Pre-mortem` — the draft goes to a subagent in a fresh context that receives only the draft (exact phrase `fresh context`); each finding ends `accepted`, `refuted` or `spike`.
   - `## Alternatives` — exact phrase `at least three approaches`, and `the cheapest` (extend what exists or do less); recommend one; the user chooses.
   - `## Exit criteria` — the list the command reuses.
   — Test: `interrogation_skill_has_stance_forcing_questions_gap_map_premortem`.
3. [x] `method/commands/po-brief.md`: frontmatter `description`, `argument-hint: [idea in one sentence]`, `allowed-tools` Read, Glob, Grep, Write, Bash, Agent, WebSearch, AskUserQuestion. Body `# /po-brief`, `Reads settings: \`Entry mode\`, \`Target branch\``.
   - `## Checks`: no `AGENTS.local.md` → "Run /po-setup first."; `Entry mode`: `new` → continue; `` `replace` or `adapt` → stop: "…run /po-prd <target SaaS> instead." ``; `` `—` → stop `` without guessing. Then read the `interrogation` skill before the first question.
   - `## Persistence`: `docs/brief.md` created from `templates/brief.md` after the first theme; exact sentence `After each theme, write what it settled into docs/brief.md and keep status: interviewing.`; resume: existing `docs/brief.md` with `status: interviewing` → recap and continue at the first theme not yet settled (empty section or unmarked gap-map line); `status: approved` → stop, the brief is approved.
   - `## Exit criteria`: exact sentence `status: approved is written only when all of these hold:` followed by: one-liner, wedge, success metric, at least three non-goals, every critical dimension handled, every pre-mortem finding settled, the user's explicit agreement after reading the whole brief.
   - `## Finish`: on `Target branch` at the repository root only; `git status --porcelain` lists an environment file → stop; ADR as decided above; commit `docs/brief.md` and the ADR as `docs: brief for <product>`. Final line "Brief approved. Next: write the stories in docs/stories.md."
   — Tests: `brief_runs_only_in_new_mode`, `brief_persists_between_sessions`, `brief_has_exit_criteria`.
4. [x] `method/commands/po-help.md`: one line after the `/po-prd` line: `` - `/po-brief` — met une idée neuve (`new`) à l'épreuve, une question à la fois, jusqu'à un brief approuvé. `` — Test: existing `every_command_listed_in_help` (`tests/pilot.test.sh:38`).
5. [x] `tests/brief.test.sh`, four tests, header `# s13 — brief command, interrogation skill and template.`:
   - `test_brief_runs_only_in_new_mode`: `settings_read_by` lists `Entry mode`; `contains` the `replace`/`adapt` stop naming `/po-prd`, and the `` `—` → stop ``.
   - `test_interrogation_skill_has_stance_forcing_questions_gap_map_premortem`: `skeptical cofounder`; within the `## Forcing questions` section exactly 7 lines matching `^[0-9]+\. \*\*` and each of the seven bold names; within `## Gap map` at least the 9 ★ dimension names each on a `★` line, and the unmarked sentence; `## Pre-mortem` section holds `fresh context`; `## Alternatives` holds `at least three approaches` and `the cheapest`.
   - `test_brief_persists_between_sessions`: command holds the after-each-theme sentence and the resume clause; template frontmatter (`frontmatter`) has line `status: interviewing`.
   - `test_brief_has_exit_criteria`: within the command's `## Exit criteria` section, the approval sentence and each of: `one-liner`, `wedge`, `success metric`, `three non-goals`, `critical dimension`, `pre-mortem finding`, `agreement`.
   Section scoping uses the awk idiom of `tests/prd.test.sh:8`.
6. [x] `docs/parite-killer-saas.md`: C04 status `à faire` → `fait — \`method/commands/po-brief.md\`, \`method/skills/interrogation/SKILL.md\``; no other line.
7. [x] Run `bash tests/run.sh` (full suite, `Full suite: execute-end`); record in `docs/verif/s13-brief-new.md`.

## Run interdicts
- Empty diff for `.claude/`, `.polype/`, `AGENTS.md`, `AGENTS.local.md`, `tests/lib.sh`, every existing test file, `method/AGENTS.md`, every existing `method/` file except the single added line of `po-help.md`.
- `docs/parite-killer-saas.md`: only the C04 line changes.
- No `method/` file mentions `docs/references/` or `~/dev/vault`.
- No sentence copied from Killer SaaS (`tests/overlap.test.sh` stays green); no literal copy of `spec-interrogation.md` either — rewrite.

## The pivot
The skill must be self-sufficient in a target project that has neither `docs/references/` nor `/spec`. Ways it could be wrong: (a) a clause still points to the reference file or the vault — grep `method/` for `references/` and `vault`; (b) the command duplicates the skill so the two drift — compare `po-brief.md` with `SKILL.md`: the command holds checks, persistence, exit gate and finish, not the question list; (c) tests pin wording rather than rules — delete the forcing-question list or the ★ markers and check the tests fail.

## Files touched
`method/commands/po-brief.md`, `method/skills/interrogation/SKILL.md`, `method/templates/brief.md`, `tests/brief.test.sh`, one line of `method/commands/po-help.md`, the C04 line of `docs/parite-killer-saas.md`, plus `docs/research/`, `docs/plans/`, `docs/verif/` for this story.

## Test strategy
Four structural tests in `tests/brief.test.sh`, one per criterion (budget 25). Each quotes the clause it guards, so removing the clause fails it. Existing `every_command_listed_in_help`, `every_setting_read_by_a_command_exists_in_template`, `install_copies_commands_agents_skills_templates` and `method_does_not_reuse_killer_saas_text` cover the rest. No visual checks.

## Done when
Full suite green, one commit `s13-brief-new: …` on `story/s13-brief-new` holding code, tests and docs, verification record complete, review with no open critical finding.
