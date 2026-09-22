---
track: flow
validated: yes
---
# Plan (short track) — s40-profile-format

Written by `/po-flow`. On the short track this one file stands in for both the research and the plan: there is no `docs/research/s40-profile-format.md`.

## Verified facts
- No story assumption proved wrong. `boilerplates/` does not exist yet (checked with `ls` at the repository root); s42 creates the first profile. The lint must therefore pass with zero profiles.
- `bin/po-lint:11` takes the method directory as its only argument (default `bin/../method`); `boilerplates/` is its sibling at the repository root (ADR-0001, `docs/decisions/ADR-0001-un-seul-repo-methode-et-boilerplates.md:18`). The profile directory is therefore `$METHOD/../boilerplates`, which keeps the mutant pattern of `tests/lint.test.sh:11-16` usable: a copy at `<tmp>/method` gets its profiles at `<tmp>/boilerplates`.
- `bin/po-lint:16-19` reports breaches as `<file>:<line>: [<rule>] <message>`; files are relative to `$METHOD`. `bin/po-lint:188-193` prints the summary `in N file(s) of method/`, which `tests/lint.test.sh:113-118` asserts — the summary line must keep that wording.
- `bin/po-lint:90-96` already reads names from a template's fenced block (`agents-local.md`) and reports a missing template at line 1. The profile rule follows the same pattern: the template `method/templates/profile.md` is the source of the required sections, command names and capability names; nothing is hard-coded in the script.
- `tests/lint.test.sh:35-43` (`reports_one`) requires exactly one breach per mutant. Its mutants have no `boilerplates/` beside them, so a profile rule that stays silent when the directory is absent keeps them green.
- `method/templates/agents-local.md` `## Commands` block holds `Package manager`, `Install`, `Test`, `Typecheck`, `E2E`, `Build`. The story asks for exactly the last five in a profile; `Package manager` is left out on purpose (it is not a command to run).
- ADR-0020 (`docs/decisions/ADR-0020-briques-par-defaut-des-capacites.md:26-39`) lists twelve capabilities, in French: Base de données, Auth, Autorisation, Multi-tenant, Fichiers, Jobs, Email, Paiement, Cache et limitation de débit, Observabilité, i18n, Déploiement. Method files are English (AGENTS.local.md conventions), so the template names them in English, one row each, in ADR order: Database, Auth, Authorization, Multi-tenancy, Files, Jobs, Email, Payment, Cache and rate limiting, Observability, i18n, Deployment. s41 must reuse these exact names.
- ADR-0008 (`…/ADR-0008-catalogue-de-profils-gratuits-dabord.md:19`) names the profile's content (commands, code map, ownership granularity, rules, UI inventory, origin and licence); ADR-0007:28 says a third-party profile declares its ownership granularity; ADR-0009:28 says it declares capabilities and bricks.
- `method/commands/po-architect.md:26` already reads `boilerplates/<name>/profile.md`; it is not in this story's `Owns` and stays untouched (s41 owns it).
- `tests/overlap.test.sh` checks every line of `method/` against Killer SaaS text: the template is written in fresh words.
- Parity lines B03 (`docs/parite-killer-saas.md:29`) and C07 (`:42`) mention "profil en M4": their status cells are updated, nothing else in that file.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text, no data | absent — bash/markdown only, no persistence |
| New screen | absent — story text | absent — no UI in this repository |
| Authorization or tenant scope | absent — story text | absent — `bin/po-lint` reads files, no access rules |
| API contract | absent — story text | absent — the profile is a document format for agents, not a service interface |
| New dependency | absent — story text | absent — `bin/po-lint` stays bash + awk, as today |

## Story
A profile format that every agent reads the same way, so a boilerplate is described once. Acceptance criteria:
- `profile_template_declares_every_section` — the template imposes: identity and licence, project commands, code map, ownership granularity, where each rule lives, capabilities provided with their bricks, UI inventory, known traps.
- `profile_commands_map_to_settings` — the commands section gives exactly the setting names `Install`, `Test`, `Typecheck`, `E2E`, `Build`.
- `lint_checks_profiles` — `bin/po-lint` checks every `boilerplates/*/profile.md`: sections present, commands named as the settings, capabilities from the ADR-0020 list; it fails and names the file otherwise.
- `catalogue_doc_explains_the_three_levels` — `docs/catalogue.md` explains the three levels (house, profiled third party, none) and what each costs in parallelism.

## Tasks
1. [x] Write `method/templates/profile.md` (English, own words): eight `## ` sections — `Identity and licence` (name, origin URL, licence, commit profiled), `Commands` (one fenced block, exactly `Install:`, `Test:`, `Typecheck:`, `E2E:`, `Build:`, `—` meaning none, copied verbatim into `AGENTS.local.md`), `Code map`, `Ownership granularity` (which paths a story can own alone), `Where each rule lives`, `Capabilities` (table `| Capability | Brick | Notes |`, one row per ADR-0020 capability with the English names above; a profile keeps only the rows it provides), `UI inventory`, `Known traps`. — fails: `test_profile_template_declares_every_section`, `test_profile_commands_map_to_settings`.
2. [x] Add a `profiles` rule to `bin/po-lint`: read from the template the `## ` headings, the command names of the `Commands` fence and the first column of the `Capabilities` table (header and separator rows excluded); for each `$METHOD/../boilerplates/*/profile.md` report `boilerplates/<name>/profile.md:<line>: [profile] …` for a missing section (line 1), a command name not in the template set or a template command missing from the fence, and a capability row not in the template list. No `boilerplates/` directory → no profile checked, no breach. A missing template → one breach at `templates/profile.md:1`, like `agents-local.md`. The summary line keeps its current wording. — fails: `test_lint_checks_profiles`.
3. [x] Write `tests/profile.test.sh` with the four acceptance tests. `test_lint_checks_profiles` copies `method/` to a temp dir, puts a profile built from the template in `<tmp>/boilerplates/demo/profile.md` and proves: the lint accepts it; removing `## Known traps` gives exactly one breach naming `boilerplates/demo/profile.md`; renaming `Test:` to `Tests:` gives a breach on that line; adding a row `| Blockchain |` gives a breach on that line. Each mutation is checked for having been applied.
4. [x] Write `docs/catalogue.md` (French): what a profile is and where it lives (`boilerplates/<nom>/profile.md`, `method/templates/profile.md`, `bin/po-lint`), then the three levels — **maison** (ADR-0007 vertical modules: one story owns one module, parallelism at its highest), **tiers profilé** (the profile's ownership granularity bounds it: coarse packages mean more stories wait on each other), **aucun** (default scaffold, analysed by `/po-architect`: ownership unknown until the code exists, first stories run mostly serially). — fails: `test_catalogue_doc_explains_the_three_levels`.
5. [x] Update the status cells of B03 and C07 in `docs/parite-killer-saas.md` to name `method/templates/profile.md` and `bin/po-lint` (B03 stays `partiel`: the pre-filling by `/po-setup` comes later). Run `bash tests/run.sh` in full (`Full suite: execute-end`) and record it in `docs/verif/s40-profile-format.md`.

## Run interdicts
- `method/commands/po-architect.md`, `.claude/`, `.polype/` and `AGENTS.md` end with an empty diff.
- No `boilerplates/` directory is committed (s42 creates the first profile).
- In `docs/parite-killer-saas.md`, only lines B03 and C07 change.
- `tests/lint.test.sh` is not modified.

## Files touched
`method/templates/profile.md`, `bin/po-lint`, `tests/profile.test.sh`, `docs/catalogue.md`, `docs/parite-killer-saas.md` (two cells), `docs/plans/s40-profile-format.md`, `docs/verif/s40-profile-format.md`.

## Test strategy
Four tests, one per acceptance criterion, all in `tests/profile.test.sh` (budget 25). The lint test is a mutation test: a lint that passes a valid profile proves nothing on its own, so each rule is shown to fire on one broken copy and to name the file. Template and doc tests quote short exact phrases (headings, setting names, the three level names). Existing `tests/lint.test.sh` must stay green unchanged, which proves the new rule is silent without `boilerplates/`.

## Done when
One commit on `story/s40-profile-format` holding code, tests, plan and record; `bash tests/run.sh` green; a review with no open critical finding; squashed onto `m4-catalogue`.
