# Review — s39-distribution-wiring

[Story](../stories.md) · [Plan](../plans/s39-distribution-wiring.md) · [Verification](../verif/s39-distribution-wiring.md)

Diff reviewed: `git diff m5-distribution...story/s39-distribution-wiring`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0

## Scope (`Owns`)
`Owns` is `method/AGENTS.md`, `method/commands/po-help.md`, `README.md`, `docs/parite-killer-saas.md`, `tests/distribution-wiring.test.sh` (`docs/stories.md:584`). The diff touches exactly those five paths, plus `docs/plans/s39-distribution-wiring.md` and `docs/verif/s39-distribution-wiring.md`, which are the story's own pipeline evidence and in scope by construction. Nothing outside, nothing belonging to another running story.

## Evidence reused
- [x] `po-gate verif-current s39-distribution-wiring` → exit 0; `git diff --quiet 613aea31 HEAD -- . ':(exclude)docs'` also exit 0. `Verification mode: record`, so the record is evidence for this exact code: unit suite `bash tests/run.sh` exit 0, 208 passed. I re-ran the full suite once anyway (it is a 2-second bash suite): 208 passed, 0 failed — same number as the record.
- `Typecheck: —`, `E2E: —`, `Build: —` in `AGENTS.local.md`: the project has none of these commands, and I substituted nothing for them. The record's "Not proven here" says the same.

## Plan
- [x] Five tasks, all present. Task 1 rewrote the "Installed files" section and kept the four sentences the plan told it to keep (`templates/<name>.md`, `po-gate`, the `Target branch` commit, never editing an installed file). Task 2 added the French `## Installation` block ahead of "Mise en place" and kept `Reads settings: none`. Task 3 rewrote `README.md`. Task 4 moved H01–H04 only. Task 5 created the test file.
- [x] Nothing outside the plan: the diff carries no unrequested change.
- [x] Run interdicts, one by one: `git diff m5-distribution...HEAD -- .claude/ .polype/ AGENTS.md` is empty (installed copies untouched, as every previous commit touching `method/AGENTS.md` did); `docs/parite-killer-saas.md` moved 4 lines, all H01–H04 status cells, no other row; `bin/polype`, `bin/polype-dev-install` and `docs/installation.md` are untouched — the documents were made to match them; `bin/polype-dev-install` was not rerun (no drift in the installed copies); no existing test file was edited, `tests/distribution-wiring.test.sh` is the only creation.

## References
- [x] Every path and command the diff names was opened. `bin/polype` really handles `install|update|check|remove|init` (`bin/polype:37-48`); `--global` really lays `method/commands`, `method/agents`, `method/skills` into `~/.claude/` with the payload under `~/.claude/polype/` (`bin/polype:79-92`); `init` really lays `.polype/templates` and `.polype/hooks` only (`bin/polype:98-101`); the assembled `AGENTS.md` and the `AGENTS.md.before-polype` rescue are real (`bin/polype:161-180`). `bin/polype-dev-install` is indeed a three-line `exec polype install "$@"` alias. `docs/installation.md`, `docs/migration.md`, `docs/conception.md`, `docs/references/killer-saas.md`, `docs/decisions/ADR-0005-codex-differe.md`, `method/hooks/pre-commit` all exist; the pre-commit hook does `exec po-gate.sh pre-commit`, so the README's sentence about it is true. Every `/po-*` command the README names has a file in `method/commands/`. `docs/installation.md:80` does carry the chezmoi section the README promises.
- [ ] One value only looks right: `polype check` written with no target (finding 1).

## Rules
- [x] `AGENTS.md` conventions respected: method files in English except `po-help.md` (French, correct), `Reads settings:` line preserved, the parity-matrix cells use the `fait — <path>` / `partiel — …` shape of the header convention, tests are bash `test_<criterion>` functions using `tests/lib.sh` helpers, one file named after the story. Test budget 25, five tests used — four new plus nothing removed.
- [x] No accepted ADR contradicted. H03's new cell cites ADR-0005 to justify staying partial, which matches what ADR-0005 actually defers. `tests/overlap.test.sh` (ADR-0006) ran with the sources present, so the new `method/` prose was really checked for 8-word overlap, not skipped.

## Tests
- [x] The four assertions pin the four acceptance criteria and quote phrases that carry meaning, not decoration. None of the six empty shapes: the README path check has a `resolved > 0` guard and the command check a `commands > 0` guard, so neither can pass by resolving nothing; no `catch` swallows anything; no fixture or mock is involved.
- [x] Within `Test budget: 25`.
- [x] Bite — five rules neutralized one at a time, each followed by `bash tests/run.sh distribution-wiring.test.sh`:
  - installer sentence removed from `method/AGENTS.md` → 1 failing test (`rules_point_at_the_installer`)
  - H01 status reverted to `à faire` → 1 failing test (`parity_matrix_reflects_the_distribution`)
  - `[docs/nexistepas.md]` link appended to `README.md` → 1 failing test (`readme_describes_the_project_and_its_install`) — the path resolver genuinely bites
  - "les ships restent sériels" flipped in `README.md` → 1 failing test (same)
  - `polype check` line removed from `po-help.md` → 1 failing test (`help_mentions_installation_and_status`)
  All five undone; `git diff --exit-code` exits 0 and `git status --porcelain` is empty. The worktree is back to the committed state.
- [x] No test is made useless by this story; none was removed.

## Neighbours
- [x] The other readers of these files are `tests/structure.test.sh`, `tests/wiring.test.sh`, `tests/install.test.sh`, `tests/installer.test.sh`, `tests/global-install.test.sh`, `tests/fleet-wiring.test.sh`; all green in the full run on this exact tree. `bin/polype`'s `cmd_update` (`bin/polype:286-326`) was read against H01's new `fait` cell: ghosts come from the manifest only, so a user's own `~/.claude/commands/` file survives, drifted files are left and named on stderr, the version is stamped — the claim holds.

## Findings
- major — `README.md:50` and `method/commands/po-help.md:13` — both documents print `polype check` as a runnable line, but the CLI requires a target: `bash bin/polype check` exits 2 and prints the usage block (`parse_target` dies when neither `--global` nor a project directory is given, `bin/polype:64`). `docs/installation.md:14,19` — the reference this story was written to match — writes `polype check --global` and `polype check <projet>`. A reader who copies either line gets a usage error from the very command meant to prove an install is healthy. `tests/distribution-wiring.test.sh:52` pins the defective form as the expected text, so the suite blesses it; the fix has to move the test string too.
- minor — `README.md:44,48` and `method/AGENTS.md:115` — three sentences understate what `init` writes into a repository. The README says the installer acts "sans jamais toucher aux réglages ni aux documents d'un projet" and summarises `polype init <projet>` as "templates, gate, `AGENTS.md` assemblé"; the rules say "after a global pose only `.polype/` and `AGENTS.md` are in the repository". `init` also `touch`es `CLAUDE.md` and appends `@AGENTS.md` to it (`bin/polype:181-183`) and appends the worktree root plus `.env*` to `.gitignore` (`bin/polype:186-195`) — which the installer's own usage text names explicitly. No damage, but a reader is surprised by two modified files the documentation did not announce.

## Not verified
- **The installer was never run for real.** I executed `bin/polype check` with no argument to confirm the usage failure, and read the rest of `bin/polype` instead of running `install --global`, `init` or `update` against a scratch directory: those are `tests/installer.test.sh` and `tests/global-install.test.sh`'s job, they are outside this story's diff, and they stayed green. A person wanting certainty that the documented procedure works end to end should run `polype install --global` then `polype init <dir>` on a throwaway repository and compare the result with `docs/installation.md`.
- **No screen, no design artefact.** This story has no interface: `docs/designs/s39-distribution-wiring/` does not exist and `docs/design-system.md` was not consulted. Nothing visual was opened, and the design-conformity part of the review is empty by construction, not by omission.
- **Whether the prose is understandable** is untested and untestable here. The four tests prove the sentences are present and that every repository path the README names resolves; they cannot prove a newcomer follows the installation without reading `bin/polype`, which is the story's actual goal. A person should read `README.md` and `method/commands/po-help.md` once, cold, and try to install Polype from them alone.
- **The installed copies still lag.** The repository's root `AGENTS.md`, `.claude/` and `.polype/` still carry the previous "Installed files" section, deliberately: the run interdict forbids refreshing them inside a story. Until someone runs `bin/polype install .` outside a story, the agents working in this repository read the old wording. That is the repository's established practice, not a defect of this diff, but it is a thing a person has to do.
- **No third party, no mock, no network** is involved anywhere in this diff.

Max severity: major
Ship allowed: yes
