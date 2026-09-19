---
validated: yes
---
# Plan — s16-architect

Branch `story/s16-architect`. Read `docs/research/s16-architect.md` first; this plan builds on it without repeating it.

## Story
`/po-architect` settles the project's base (an existing boilerplate, a scaffolded default or an assumed empty repository), reads it with `codebase-analysis`, writes its habits as rules in the « Conventions » section of `AGENTS.local.md`, records each structural choice as an ADR, and commits `docs/architecture.md` with them on `Target branch`. It never proposes to rewrite the base. Criteria (each the name of one test in `tests/architect.test.sh`): `architect_asks_for_the_base`, `architect_analyses_code_before_deciding`, `architect_records_structural_decisions_as_adrs`, `architect_never_rewrites_the_base`.

## Decisions

| Question | Decision | Why |
| --- | --- | --- |
| Does the command scaffold code? | No. A scaffolded default is chosen and recorded as an ADR with the generator's exact command; the person runs it and commits the result, then runs `/po-architect` again, which now finds a base | Law 1: code only enters through a story or a person; keeps the command out of source files |
| "A base is detected" | The repository holds a package manifest or source files outside Polype's own (`AGENTS*.md`, `CLAUDE.md`, `docs/`, `.claude/`, `.polype/`, `.gitignore`) | Concrete, checkable signal; research open question 1 |
| Profile vs analysis | Look for `boilerplates/<name>/profile.md` in Polype's repository when it is at hand; a profile is the starting point, the analysis of the project's code confirms and completes it; no profile → analysis alone. When no catalogue is reachable, say so and let the user name the boilerplate | Profile format is M4; the catalogue is not installed into projects (research) |
| Human checkpoints | AskUserQuestion: (1) the base, only when none is detected; (2) one grouped approval of the drafted ADRs, conventions and `docs/architecture.md` before anything is written | Decisions belong to a person; one grouped checkpoint, not one per ADR |
| ADR format | `docs/decisions/NNNN-<slug>.md`, next free number, from `templates/adr.md`, `scope: framing`, `status: accepted` once approved; an accepted ADR is superseded, never edited | Rules `method/AGENTS.md:68` |
| Structural choices | The stack; one brick per capability the project needs (database, auth, authorization, multi-tenancy, files, jobs, email, payment, cache, observability, i18n, deployment), default and alternatives; each third-party integration | Polype's capability model (ADR-0009), written in the method's own words, no reference to Polype's ADR numbers |
| Conventions | Replace only the placeholder or body of `## Conventions` in `AGENTS.local.md`, via Edit; settings blocks untouched. Rules, each with `path:line`. Rerun the installer when available so `AGENTS.md` catches up, as `/po-setup` does | Criterion 2; settings are never decided by an agent |
| Project commands | Quoted from settings into `docs/architecture.md`; when the base defines different ones, report it and ask the user to edit the settings — never written by the command | Rules: agents read settings, never decide them |
| Empty repository | Allowed, with the warning that auth, tenancy and billing become sequential foundation stories before any parallel work; recorded as an ADR | Criterion 1; `docs/conception.md:70` |
| Re-run | `docs/architecture.md` present → amend it; decisions changed → new ADR superseding the old one | Accepted ADRs are never edited |
| Tools | Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion | Writes docs and one section of `AGENTS.local.md`, commits; no source file |
| Lines outside Owns | One French line in `po-help.md` after `/po-stories-review`; `po-setup.md:17` clause admits `/po-architect` writing the Conventions section; C07 and B04 status cells | `pilot.test.sh:38`; the `po-setup` sentence would otherwise contradict criterion 2; B04 (conventions filled at architecture) is delivered here |

## Tasks
1. [x] `method/templates/architecture.md` — `# Architecture — <project>`, sections: `## Base` (name, origin, licence, profile used or "analysis only", ADR link); `## Map` (where routes, domains, shared core, migrations, policies, UI components live, with paths); `## Capabilities` as a table `| Capability | Brick | Alternatives | ADR |`; `## Ownership` (which path a story may own alone); `## Attachment points`; `## Commands` (quoted from `AGENTS.local.md`); `## Conventions` (pointer: rules live in `AGENTS.local.md`). — Test: `architect_analyses_code_before_deciding` (template part).
2. [x] `method/commands/po-architect.md` — frontmatter `description`, `allowed-tools` as decided. `# /po-architect`, `Reads settings: \`Target branch\`, \`Package manager\`, \`Install\`, \`Test\`, \`Typecheck\`, \`E2E\`, \`Build\``. Sections in this order:
   - `## Checks`: no `AGENTS.local.md` → "Run /po-setup first."; repository root on `Target branch`, else stop, no switch.
   - `## Step 1 — The base`: detection rule; profile lookup; with no base detected, one AskUserQuestion offering exactly three answers, each phrase exact: `a boilerplate from the catalogue or one the user owns`, `a scaffolded default, recorded as an ADR`, `an empty repository, assumed`; the last carries the sentence `Warn that parallelism will suffer:` followed by the foundations reason. Scaffolding rule: `This command never runs a generator or writes source code:` the person scaffolds and commits, then reruns `/po-architect`.
   - `## Step 2 — Read the code before deciding`: apply the `codebase-analysis` skill to the base (profile first when there is one); exact phrase `No decision is drafted before this analysis is done.`
   - `## Step 3 — Structural decisions`: exact phrase `Each structural choice becomes one ADR in \`docs/decisions/\` from \`templates/adr.md\``, listing the stack, one brick per capability (default and alternatives) and each integration; numbering, `scope: framing`, supersede rule.
   - `## Step 4 — Conventions as rules`: exact phrase `Write the conventions as rules in the \`## Conventions\` section of \`AGENTS.local.md\``; only that section; settings untouched; rules with `path:line`; commands mismatch reported, not fixed.
   - `## Never rewrite the base`: exact sentence `Never propose rewriting, replacing or restructuring the base: stories adapt to it.` A brick that must change is added behind its capability by a later story.
   - `## Approval and commit`: one grouped AskUserQuestion on ADRs, conventions and `docs/architecture.md` from `templates/architecture.md`; installer rerun; `git status --porcelain` lists an environment file → stop; commit `docs/architecture.md`, the new ADRs, `AGENTS.local.md` (and `AGENTS.md` if regenerated) on `Target branch` as `docs: architecture`.
   - Finish line: "Architecture recorded. Next: /po-research <first story id>".
   — Tests: all four.
3. [x] `method/commands/po-setup.md:17`: replace "no other command and not the installer ever writes this file" by a clause saying no other command writes it except `/po-architect`, which fills only its « Conventions » section, and the installer never writes it. Keep `If \`AGENTS.local.md\` is already there, do not touch it.` verbatim. — Tests: existing `setup_never_overwrites_settings`.
4. [x] `method/commands/po-help.md`: after `/po-stories-review`, `` - `/po-architect` — part du boilerplate du projet, en tire les conventions (règles dans `AGENTS.local.md`) et une ADR par choix structurant ; écrit `docs/architecture.md`. `` — Test: existing `every_command_listed_in_help`.
5. [x] `tests/architect.test.sh`, header `# s16 — architecture on a boilerplate.`, local `section_of` (copy of `tests/stories-review.test.sh:11`):
   - `test_architect_asks_for_the_base`: `needs_tool` AskUserQuestion; the three option phrases; `Warn that parallelism will suffer:`; `This command never runs a generator or writes source code:`.
   - `test_architect_analyses_code_before_deciding`: contains `codebase-analysis` in `## Step 2 — Read the code before deciding`; `No decision is drafted before this analysis is done.`; the Step 2 heading comes before the Step 3 heading (line numbers); the Conventions phrase; template exists with `## Capabilities` table header `| Capability | Brick`.
   - `test_architect_records_structural_decisions_as_adrs`: the ADR phrase; Step 3 names `stack`, `capability` and `integration`.
   - `test_architect_never_rewrites_the_base`: the exact sentence.
6. [x] `docs/parite-killer-saas.md`: C07 → `fait — \`method/commands/po-architect.md\`, \`method/templates/architecture.md\` ; catalogue et format de profil en M4`; B04 → `fait — \`method/commands/po-architect.md\``. No other line.
7. [x] Full suite `bash tests/run.sh` (`Full suite: execute-end`); record in `docs/verif/s16-architect.md`.

## Run interdicts
- Empty diff for `.claude/`, `.polype/`, `AGENTS.md`, `AGENTS.local.md`, `docs/stories.md`, `docs/decisions/`, `tests/lib.sh`, every existing test, `method/AGENTS.md`, every existing `method/templates/`, `method/agents/`, `method/skills/` file, and every existing `method/commands/` file except the one line of `po-help.md` and the one clause of `po-setup.md:17`.
- `docs/parite-killer-saas.md`: only the C07 and B04 lines change.
- No new setting in `method/templates/agents-local.md`.
- The new files do not mention `docs/references/`, `~/dev/vault`, `/spec` or Polype's own ADR numbers.
- No sentence from Killer SaaS (`tests/overlap.test.sh` green with its sources present); never open `ks-architect.md` or Killer SaaS's `templates/architecture.md`.

## The pivot
The command decides and records; it never produces code — a scaffold is a person's act, recorded by an ADR. Ways it could be wrong: (a) a user expects `/po-architect` to leave a runnable base — check the scaffolding sentence and the rerun path read as a complete flow; (b) writing into `AGENTS.local.md` breaks the "never overwrite settings" promise — check that only `## Conventions` is edited and `po-setup.md` still holds its test phrase; (c) the capability list drifts from `docs/conception.md:86` — compare.

## Files touched
New: `method/commands/po-architect.md`, `method/templates/architecture.md`, `tests/architect.test.sh`. Edited: one clause of `method/commands/po-setup.md`, one line of `method/commands/po-help.md`, the C07 and B04 lines of `docs/parite-killer-saas.md`. Plus `docs/research/`, `docs/plans/`, `docs/verif/` for this story.

## Test strategy
Four structural tests in `tests/architect.test.sh`, one per criterion (budget 25). Each quotes the clause it guards, so deleting it fails the test. Existing `every_command_listed_in_help`, `every_setting_read_by_a_command_exists_in_template`, `setup_never_overwrites_settings`, the install tests and `method_does_not_reuse_killer_saas_text` cover the rest. No visual checks.

## Done when
Full suite green, one commit `s16-architect: …` on `story/s16-architect` holding code, tests and docs, verification record complete, review with no open critical finding.
