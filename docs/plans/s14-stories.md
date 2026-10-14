---
validated: yes
---
# Plan — s14-stories

[Story](../stories.md) · [Research](../research/s14-stories.md)

Branch `story/s14-stories`. Read `docs/research/s14-stories.md` first; this plan builds on it without repeating it.

## Story
`/po-stories` turns an approved PRD or brief into `docs/stories.md`, in the format of `templates/stories.md`, committed on `Target branch`. Criteria (each is the name of one test in `tests/stories.test.sh`): `stories_reads_prd_or_brief_by_entry_mode`, `agentic_stories_skill_rejects_technical_layers`, `agentic_stories_skill_requires_owns_and_contracts_first`, `stories_split_complexity_five_and_order_dependencies`, `stories_never_revive_the_graveyard`.

## Decisions

| Question | Decision | Why |
| --- | --- | --- |
| Split command / skill | The skill `agentic-stories` holds how to cut and write a story (vertical slice + bad/good example, Owns, contracts first, complexity and splitting, dependency order, graveyard, target reference, agent notes, size); `po-stories.md` holds checks, source selection, the drafting sequence, the pre-write checks, finish and commit, and tells the agent to read the skill first | Same split as s13; s15's reviewer can reuse the skill's rules |
| Source must be approved | Both sources need `status: approved`; a PRD in `draft` → stop and point to `/po-prd`, a brief in `interviewing` → `/po-brief` | Same lifecycle in both templates; a draft scope makes stories on sand |
| Existing `docs/stories.md` | New stories are appended with the next free `s<n>` numbers; existing ids and stories are never renumbered or rewritten | Ids name branches and files (`AGENTS.md` Ids) |
| Human validation | The full list (ids, titles, complexity, dependencies, Owns) is shown and agreed before anything is written; then each story is written in full and the whole file shown once more before commit | Stories feed every stage; the user owns scope |
| Contract-first story | The one allowed exception to "never a technical layer": it must be observable (a test or a caller exercising the contract) and every story using the contract depends on it | Criterion 3 without reopening layered stories |
| Lines outside Owns | Only one French line in `po-help.md` after `/po-brief`; the "Next: write the stories…" lines of `po-prd`, `po-brief`, `po-setup` stay | `pilot.test.sh:38` forces the help line; nothing forces the others |

## Tasks
1. [x] `method/skills/agentic-stories/SKILL.md`: frontmatter `name: agentic-stories`, `description:` (…used by /po-stories). Sections, own wording (no Killer SaaS text, ADR-0006):
   - `## Vertical slices` — a story delivers something a user can do end to end; the exact sentence `Never a technical layer: "create the table", "add the endpoint" or "build the service" are not stories.`; a `Bad:` / `Good:` example pair (bad: a layer story like "Create the orders table"; good: a usable slice like "A customer places an order and sees it in their list").
   - `## Owns and contracts first` — exact sentence `Every story declares Owns:` followed by the paths it may change; two stories without a dependency never share a path; exact sentence `An interface shared by two stories becomes an earlier story of its own: the contract comes first.`; it is observable (test or caller) and the stories using it depend on it.
   - `## Complexity and splitting` — the scale of `templates/stories.md`; exact phrases `A 5 is split now` and `A 4 names its main risk`; more than about ten plan tasks → split.
   - `## Dependency order` — exact sentence `No story depends on a story placed after it.`; foundations first; ids numbered in file order.
   - `## Scope: core loop and graveyard` — every story traces to a core-loop line or the angle (PRD) or to the wedge / a premise (brief); exact sentence `Nothing from the graveyard becomes a story`, including under another name; in `replace`/`adapt`, the notes name `the equivalent screen of the target` when there is one.
   - `## Criteria and notes` — each criterion observable and turnable into one test; notes tell the agent files, constraints, pitfalls.
   — Tests: `agentic_stories_skill_rejects_technical_layers`, `agentic_stories_skill_requires_owns_and_contracts_first`, parts of criteria 4 and 5.
2. [x] `method/commands/po-stories.md`: frontmatter `description`, no `argument-hint` (the source comes from the settings), `allowed-tools` Read, Glob, Grep, Write, Bash, AskUserQuestion. Body `# /po-stories`, `Reads settings: \`Entry mode\`, \`Target branch\``.
   - `## Checks`: no `AGENTS.local.md` → "Run /po-setup first."; `Entry mode`: `` `replace` or `adapt` → the source is `docs/prd.md` ``, missing or not `status: approved` → stop naming `/po-prd`; `` `new` → the source is `docs/brief.md` ``, missing or not `status: approved` → stop naming `/po-brief`; `` `—` → stop `` without guessing. Then read the `agentic-stories` skill.
   - `## Sequence`: draft the list from the source; show it (ids, titles, complexity, dependencies, Owns) and get agreement; write each story from `templates/stories.md`; existing `docs/stories.md` → append with next free numbers, never renumber.
   - `## Before writing` — checklist the command runs on the draft: every 5 split, every 4 with its risk, dependency order, no graveyard feature (replace/adapt), Owns on every story, shared interfaces as earlier contract stories.
   - `## Finish`: show the whole file; commit from the repository root on `Target branch` only; `git status --porcelain` lists an environment file → stop; commit `docs/stories.md` alone as `docs: stories for <product>`. Final line "Stories written. Next: /po-research <first story id>".
   — Tests: `stories_reads_prd_or_brief_by_entry_mode`, parts of criteria 4 and 5.
3. [x] `method/commands/po-help.md`: one line after `/po-brief`: `` - `/po-stories` — découpe le PRD ou le brief approuvé en stories livrables par un agent, dans `docs/stories.md`. `` — Test: existing `every_command_listed_in_help`.
4. [x] `tests/stories.test.sh`, header `# s14 — stories command and agentic-stories skill.`, five tests, section scoping with a local `section_of` (copy of `tests/brief.test.sh:9`):
   - `test_stories_reads_prd_or_brief_by_entry_mode`: `settings_read_by` lists `Entry mode`; `contains` the `replace`/`adapt` → `docs/prd.md` clause and `/po-prd`, the `new` → `docs/brief.md` clause and `/po-brief`, `status: approved`, and `` `—` → stop ``.
   - `test_agentic_stories_skill_rejects_technical_layers`: in `## Vertical slices`, the never-a-layer sentence, a line starting `Bad:` and one starting `Good:`.
   - `test_agentic_stories_skill_requires_owns_and_contracts_first`: the Owns sentence and the contract-first sentence.
   - `test_stories_split_complexity_five_and_order_dependencies`: skill holds `A 5 is split now`, `A 4 names its main risk`, `No story depends on a story placed after it.`; the command's `## Before writing` section mentions `5`-splitting and dependency order (quotes).
   - `test_stories_never_revive_the_graveyard`: skill holds `Nothing from the graveyard becomes a story` and `the equivalent screen of the target`; command's `## Before writing` holds the graveyard check.
5. [x] `docs/parite-killer-saas.md`: C05 status → `fait — \`method/commands/po-stories.md\`, \`method/skills/agentic-stories/SKILL.md\`, \`method/templates/stories.md\``; no other line.
6. [x] Run `bash tests/run.sh` (full suite, `Full suite: execute-end`); record in `docs/verif/s14-stories.md`.

## Run interdicts
- Empty diff for `.claude/`, `.polype/`, `AGENTS.md`, `AGENTS.local.md`, `tests/lib.sh`, every existing test file, `method/AGENTS.md`, `method/templates/`, every existing `method/` file except the single added line of `po-help.md`.
- `docs/parite-killer-saas.md`: only the C05 line changes. `docs/stories.md` untouched.
- The new `method/` files do not mention `docs/references/`, `~/dev/vault` or `/spec`.
- No sentence from Killer SaaS (`tests/overlap.test.sh` green, with its sources present).

## The pivot
The skill must make "vertical slice" and "contract first" coexist: a contract story is the only non-user-facing story allowed. Ways it could be wrong: (a) the contract exception is worded so loosely that "create the table" slips back in — read `## Owns and contracts first` against the never-a-layer sentence; (b) the command repeats the skill's rules and they drift — the command's `## Before writing` is a checklist that names the rules, the skill explains them; (c) tests pin wording rather than rules — delete the Bad/Good pair or the graveyard sentence and check the tests fail.

## Files touched
`method/commands/po-stories.md`, `method/skills/agentic-stories/SKILL.md`, `tests/stories.test.sh`, one line of `method/commands/po-help.md`, the C05 line of `docs/parite-killer-saas.md`, plus `docs/research/`, `docs/plans/`, `docs/verif/` for this story.

## Test strategy
Five structural tests in `tests/stories.test.sh`, one per criterion (budget 25). Each quotes the clause it guards, so removing the clause fails it. Existing `every_command_listed_in_help`, `every_setting_read_by_a_command_exists_in_template`, `install_copies_commands_agents_skills_templates` and `method_does_not_reuse_killer_saas_text` cover the rest. No visual checks.

## Done when
Full suite green, one commit `s14-stories: …` on `story/s14-stories` holding code, tests and docs, verification record complete, review with no open critical finding.
