---
track: flow
validated: yes
---
# Plan (short track) — s46-adr-directory

[Story](../stories.md)

Written by `/po-flow`. On the short track this one file stands in for both the research and the plan: there is no `docs/research/s46-adr-directory.md`.

## Verified facts
- **The story's `Owns` line is incomplete; task 6 corrects it in `docs/stories.md`.** Besides the files it lists, the method names `docs/decisions/` in five more files that read or write ADRs, and one test quotes a clause this story changes:
  - `method/commands/po-brief.md:48` writes the first ADR as `docs/decisions/0001-<slug>.md` — a command that writes an ADR (criterion 3);
  - `method/commands/po-drive.md:77` reserves ADR numbers by "reading `docs/decisions/`";
  - `method/commands/po-status.md:39` counts ADRs "With `docs/decisions/`";
  - `method/agents/designer.md:9` and `method/agents/stories-reviewer.md:17` read "the accepted ADRs in/under `docs/decisions/`" — subagents that read an ADR (criterion 3);
  - `method/templates/architecture.md:10,29` link ADRs as `decisions/<NNNN>-<slug>.md`, a path relative to `docs/` that is wrong for any other directory;
  - `tests/architect.test.sh:39` quotes 'Each structural choice becomes one ADR in `docs/decisions/` from `templates/adr.md`' — changed by task 3, said so here as the conventions require;
  - `AGENTS.local.md` (this repository's settings): once the template declares `ADR directory`, a command reading it here finds it missing, and a missing setting is a stop (`method/AGENTS.md`, "Reading settings"). This repository gets `ADR directory: docs/decisions/` — its folder is not renamed (story notes).
- `method/AGENTS.md:94` — Law 6: "Structural decisions are ADRs in `docs/decisions/NNNN-<slug>.md`".
- `method/commands/po-architect.md:14` reads `Target branch`, `Package manager`, `Install`, `Test`, `Typecheck`, `E2E`, `Build`; `:16`, `:41`, `:48` name `docs/decisions/`.
- `method/commands/po-plan.md:14` reads `Target branch`, `Worktree root`, `Plan validation`, `Test budget`; `:42` writes an ADR "in `docs/decisions/`".
- `method/agents/planner.md:12,10,52`, `implementer.md:11,9`, `reviewer.md:13,18`: `Reads settings:` lines, then the `docs/decisions/` mentions.
- `bin/po-lint:87-114` (rule `settings`): every name in backticks on a `Reads settings:` line must be a `Name:` inside a fenced block of `method/templates/agents-local.md`, else `reads unknown setting '<name>'`, exit 1. `tests/lint.test.sh:51-60` already proves the rule on an imaginary name.
- `method/templates/agents-local.md:11-34` Pipeline block, `:36-60` values table. `/po-setup` copies it (`method/commands/po-setup.md:46`), so new projects get the default.
- `method/skills/`, `method/hooks/`, `bin/`: no mention of `docs/decisions/`.
- `docs/parite-killer-saas.md:95` — G04 row, status `fait — method/AGENTS.md, method/templates/adr.md`.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text: no data | absent — markdown and bash only; existing ADRs not moved |
| New screen | absent — story text | absent — no UI in this repository |
| Authorization or tenant scope | absent — story text | absent — `method/`, `bin/po-lint` |
| API contract | absent — story text | absent — a setting line, no interface; `bin/po-lint` unchanged |
| New dependency | absent — story text | absent — no tool added |

## Story
A project chooses where its ADRs live, so a repository that already numbers its decisions elsewhere (nautile: `docs/adr/`) does not contradict the method. Criteria: `settings_template_declares_the_adr_directory`, `rules_read_the_adr_directory_instead_of_a_fixed_path`, `every_command_that_writes_an_adr_reads_the_setting`, `lint_accepts_the_new_setting`.

## Tasks
1. [x] Template: add `ADR directory:     docs/decisions/` to the Pipeline block of `method/templates/agents-local.md` (after `Worktree root`, same alignment) and a table row `| ADR directory | where the project's ADRs live, with its own numbering; ends with `/` |` — the value text contains "where the project's ADRs live, with its own numbering". Add `ADR directory:     docs/decisions/` to this repository's `AGENTS.local.md`. Test: `settings_template_declares_the_adr_directory` (template block holds `ADR directory` = `docs/decisions/`, table row holds the phrase).
2. [x] Law 6 of `method/AGENTS.md:94`: "Structural decisions are ADRs in `<ADR directory>NNNN-<slug>.md`, …". Test: `rules_read_the_adr_directory_instead_of_a_fixed_path` (the phrase is present, `docs/decisions/` absent from `method/AGENTS.md`).
3. [x] Commands `po-architect`, `po-plan`, `po-brief`, `po-drive`, `po-status`: append `` `ADR directory` `` to `Reads settings:` and replace every `docs/decisions/` by `` `<ADR directory>` `` (in prose: "the `ADR directory` folder" where a path reads badly). `method/templates/architecture.md`: links become `[ADR-<NNNN>](<ADR directory, relative to docs/><NNNN>-<slug>.md)`. Update `tests/architect.test.sh:39` to the new clause. Test: `every_command_that_writes_an_adr_reads_the_setting` (task 3 + 4 files).
4. [x] Subagents `planner`, `implementer`, `reviewer`, `designer`, `stories-reviewer`: same treatment. Same test, which loops over the ten files and fails on any that lacks `ADR directory` in `settings_read_by` or still contains `docs/decisions/`, and over `templates/architecture.md` for the literal path.
5. [x] `lint_accepts_the_new_setting`: `bin/po-lint "$METHOD"` exits 0 on the real tree; then on a copy of `method/` with the `ADR directory:` line removed from the template, it reports `reads unknown setting 'ADR directory'` and exits 1.
6. [x] Correct the `Owns` line of s46 in `docs/stories.md:686` to add every file of "Files touched" outside `docs/plans/` and `docs/verif/` (touch no other story). `docs/parite-killer-saas.md:95` status cell of G04 only → `fait — method/AGENTS.md, method/templates/adr.md, method/templates/agents-local.md (ADR directory)`.

## Run interdicts
- `docs/decisions/` and its ADRs: empty diff (not renamed, not moved, no ADR edited).
- `.claude/`, `.polype/`, root `AGENTS.md`: empty diff (installed copies).
- `bin/po-lint`: empty diff — the rule already covers the setting.
- `method/templates/adr.md`, `method/skills/`: empty diff.
- In `docs/parite-killer-saas.md`, only row G04 changes.

## Files touched
`method/templates/agents-local.md`, `method/templates/architecture.md`, `method/AGENTS.md`, `method/commands/{po-architect,po-plan,po-brief,po-drive,po-status}.md`, `method/agents/{planner,implementer,reviewer,designer,stories-reviewer}.md`, `AGENTS.local.md`, `tests/adr-directory.test.sh` (new), `tests/architect.test.sh`, `docs/stories.md` (Owns of s46), `docs/parite-killer-saas.md` (G04), `docs/plans/s46-adr-directory.md`, `docs/verif/s46-adr-directory.md`.

## Test strategy
Four tests in `tests/adr-directory.test.sh`, one per criterion, named after it; structural checks on the method files plus one behavioural mutation of `bin/po-lint` on a temporary copy (removing the setting must make lint fail — the test bites). Each would fail if its task were reverted. Four of a budget of 25. Full suite `bash tests/run.sh` at the end (`Full suite: execute-end`); `tests/overlap.test.sh` must stay green on the new wording.

## Done when
All four criteria's tests pass, the full suite and `bin/po-lint` are green, `docs/verif/s46-adr-directory.md` is complete, and the story lands as one squash commit on `m4-catalogue`.
