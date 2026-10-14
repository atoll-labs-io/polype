---
track: flow
validated: yes
---
# Plan (short track) — s39-distribution-wiring

[Story](../stories.md)

Written by `/po-flow`. On the short track this one file stands in for both the research and the plan: there is no `docs/research/s39-distribution-wiring.md`.

## Verified facts

| Fact | Where |
| --- | --- |
| The installer is `bin/polype`; it handles `install`, `update`, `check`, `remove` and `init`, for `--global` or one project. | `bin/polype:38-48`, `bin/polype:400-410` |
| A global install lays commands, agents and skills in `~/.claude/` (or `$CLAUDE_CONFIG_DIR`) and the payload — `bin/` and `method/` — under `~/.claude/polype/`. | `bin/polype:79-92` |
| A project install lays `.claude/{commands,agents,skills}` plus `.polype/{templates,hooks}`; `init` lays only `.polype/` — it activates a project served by a global install. | `bin/polype:94-106` |
| A project install also assembles `AGENTS.md` (method rules + `AGENTS.local.md`), appends `@AGENTS.md` to `CLAUDE.md` and fills `.gitignore`. A hand-written `AGENTS.md` is kept as `AGENTS.md.before-polype`. | `bin/polype:161-190` |
| `update` refreshes what has not drifted, leaves a modified file in place and names it on stderr, removes ghosts, and stamps the version. | `bin/polype:286-326` |
| `check` reports the version stamp, missing files and drifted files. | `bin/polype:329-355` |
| `bin/polype-dev-install <project>` is now only an alias of `polype install <project>`. | `docs/installation.md:29-30` |
| The full installation procedure is already written in French in `docs/installation.md`; nothing links to it from the `README.md`. | `docs/installation.md:1-60`, `README.md:1-27` |
| `README.md` still announces `install.sh` and a `boilerplates/` directory, neither of which exists; it says "Statut : conception" and never mentions the story cycle, the fleet or `bin/polype`. | `README.md:20-24`, root listing |
| `method/AGENTS.md` "Installed files" names `.claude/`, `.polype/` and `po-gate`, but no installer and no global/project distinction. | `method/AGENTS.md:111-115` |
| `method/commands/po-help.md` is the French cheat sheet; it has "Mise en place (une fois)", "Le cycle d'une story", "Outils", "Repères" and says nothing about installing Polype itself. | `method/commands/po-help.md:1-40` |
| Parity matrix, section H: H01 `à faire`, H02 `fait — bin/polype-dev-install`, H03 `à faire`, H04 `à faire`. Done cells read ``fait — `path` ``, partial ones ``partiel — `path` ; <what remains>``. | `docs/parite-killer-saas.md:103-106`, `:14-23` |
| `method/agents/implementer.md:5` is `model: opus`; `designer`, `planner`, `reviewer` and `stories-reviewer` are `model: inherit`. No per-story model setting exists. | `method/agents/*.md:5` |
| ADR-0005 defers the Codex emission; a single source emitting per tool does not exist yet. | `docs/decisions/ADR-0005-codex-differe.md` |
| The suite runs every `test_*` of `tests/*.test.sh`; a new file needs no registration. `contains` is exact `grep -qF`. | `tests/run.sh:5-8`, `tests/lib.sh:57` |
| `README.md` is checked by no test today. | `grep -rn README tests/ bin/` returns nothing |
| No story commit regenerates the installed copies: `git log -- method/AGENTS.md` shows four commits, none touching the root `AGENTS.md`. | `git log --format=%h -4 -- method/AGENTS.md` |

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — the story text moves no data; `docs/migration.md` already exists from s38 | absent — no state file, schema or format is rewritten |
| New screen | absent — the story names four documents, no interface | absent — `Owns` is three markdown files and one bash test |
| Authorization or tenant scope | absent — nothing in the story text | absent — no code path touches permissions |
| API contract | absent — nothing in the story text | absent — `bin/polype`'s CLI is only described, never changed |
| New dependency | absent — nothing in the story text | absent — tests stay on `bash`, `grep`, `awk` |

## Story

Make the rules, the help and the documentation tell the same installation story, so nobody has to read `bin/polype` to learn how Polype is laid down.

- `rules_point_at_the_installer` — the installed-files section cites `bin/polype` and distinguishes a global install from activating a project.
- `help_mentions_installation_and_status` — the help says in one line how to install and how to check an install.
- `readme_describes_the_project_and_its_install` — `README.md` describes Polype, its cycle, its fleet and its installation, promising nothing that does not exist.
- `parity_matrix_reflects_the_distribution` — H01 to H04 become `fait — <path>` or say what remains.

## Tasks

1. [x] `method/AGENTS.md`, section "Installed files": name `bin/polype` as the installer, and separate the two poses — `polype install --global` puts commands, subagents and skills in `~/.claude/` for every project, `polype init <project>` activates one project with its templates, its gate and its assembled `AGENTS.md`; `polype install <project>` does both at once in a single repository. Keep the existing sentences on `templates/<name>.md`, `po-gate`, the target-branch commit and never editing an installed file. Point the reader at `docs/installation.md` for the detail. Fails `rules_point_at_the_installer`.
2. [x] `method/commands/po-help.md`: add, in French, a short "Installation" block before "Mise en place (une fois)" — one line for laying Polype down (`polype install --global` then `polype init <projet>`, or `polype install <projet>` alone) and one line for auditing it (`polype check`, which gives the stamped version and the files that drifted). Keep `Reads settings: none`. Fails `help_mentions_installation_and_status`.
3. [x] `README.md`: rewrite it around what exists — what Polype is, the three entry modes, the story cycle (research → plan → execute → review → ship with its gates), the fleet `/po-drive` with serial ships and `Owns`, and the installation, linking `docs/installation.md`. Drop `install.sh` and the `boilerplates/` promise; keep the Killer SaaS attribution and the `docs/references/killer-saas.md` link. Every repository path it writes must exist. Fails `readme_describes_the_project_and_its_install`.
4. [x] `docs/parite-killer-saas.md`, lines H01 to H04 only, status cell only: H01 → ``fait — `bin/polype`, `docs/installation.md` ``; H02 → ``fait — `bin/polype` `` (the assembly moved there, `bin/polype-dev-install` is only an alias); H03 → partial, naming `method/` as the single source and the Codex emission plus the degradation table as deferred by ADR-0005; H04 → partial, naming `method/agents/` and the per-story model setting as still missing. Fails `parity_matrix_reflects_the_distribution`.
5. [x] `tests/distribution-wiring.test.sh`: four `test_<criterion>` functions, one per acceptance criterion, using `require_file`/`contains`/`fail` from `tests/lib.sh`, quoting short exact phrases. The README test resolves every backticked repository path it finds (skipping placeholders) and fails on an absent one, the way `tests/migration-doc.test.sh` does, and asserts `install.sh` and `boilerplates/` are gone. The matrix test reads the H01–H04 rows and fails on a remaining `à faire`.

## Run interdicts

- `git diff -- .claude/ .polype/ AGENTS.md` must stay empty: the installed copies of the method are refreshed outside a story, as every previous commit touching `method/AGENTS.md` did.
- `git diff -- docs/parite-killer-saas.md` must touch only the four H01–H04 rows; no other status cell moves.
- `bin/polype`, `bin/polype-dev-install` and `docs/installation.md` are not this story's: the documentation is made to match them, never the other way round.
- Do not rerun `bin/polype-dev-install`.
- No existing test file is edited; `tests/distribution-wiring.test.sh` is the only one created.

## Files touched

`method/AGENTS.md`, `method/commands/po-help.md`, `README.md`, `docs/parite-killer-saas.md`, `tests/distribution-wiring.test.sh` — exactly the `Owns` line, plus `docs/plans/` and `docs/verif/` for the pipeline.

## Test strategy

One layer only: the documents are the unit, `bash` assertions on their text are the test — the same shape as `tests/migration-doc.test.sh` and `tests/wiring.test.sh`. Four tests for four criteria, well inside `Test budget: 25`. Each quotes a phrase that carries the meaning, so deleting the rule breaks the test; the README test also resolves its paths, which fails the day a document points at a file that no longer exists. Full run: `bash tests/run.sh`, which must stay green everywhere — `tests/overlap.test.sh` included, since task 1 writes new lines into `method/`.

## Done when

`bash tests/run.sh` is green, the four new tests pass, the diff stays inside `Owns`, and one commit on `story/s39-distribution-wiring` carries the code, the plan and the record.
