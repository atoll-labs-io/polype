---
validated: yes
---
# Plan — s135-update-keeps-init-mode

[Story](../stories.md) · [Research](../research/s135-update-keeps-init-mode.md)

Branch `story/s135-update-keeps-init-mode`. Read `docs/research/s135-update-keeps-init-mode.md` first; this plan builds on it without repeating it.

## Story
Fixes #73. `polype update <project>` keeps an init-activated project at its 23 project files. The activation mode is recorded in `.polype/mode`, inferred from the manifest when that file is missing; `init` on a full install shrinks it and records `init`; the po-session hint, the installer hints, `/po-setup` step 3, `README.md` and `docs/installation.md` name the right command; ADR-0091 records the choice. Criteria: `init_then_update_stays_init`, `mode_is_recorded`, `mode_inferred_without_state`, `init_shrinks_a_full_install`, `hints_say_init`, `adr_records_the_mode`.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Writing `.polype/mode` | Repository: same shape as `stamp_version` (`bin/polype:506`), called at the same two sites (`:599`, `:648`) | — |
| Reading the mode in `parse_target` | New code (~8 lines) in `parse_target`, project branch, before `target_is_a_project` | Nothing in the repo reads project state before `PAIRS` are built (`bin/polype:63-117`); no stdlib/platform answer |
| Manifest inference | `grep -q '^\.claude/commands/'` on the manifest (platform) | — |
| po-session command choice | New code (~6 lines) in `method/hooks/po-session.sh`, same rule as the installer | po-session cannot source `bin/polype` (hooks run standalone, `po-session.sh:9-12`) |
| Tests | `tests/lib.sh` helpers (`scratch_repo`, `fail`, `contains`) and the `run_polype` / throwaway-home pattern of `tests/claude-md-setting.test.sh:8-25` | — |

## Tasks
1. [x] **Record the mode.** In `bin/polype`, add `mode_file="$state_dir/mode"` in `parse_target` next to `version_file` (`:87`), and `stamp_mode() { [ "$mode" = global ] || printf '%s\n' "$mode" > "$mode_file"; }`, called right after each `stamp_version` (`:599`, `:648`). `cmd_remove` deletes it with the other state (`:729`). Test: `test_mode_is_recorded` — `.polype/mode` reads `init` after `init`, `project` after `install <proj>`, absent after `remove`; no `mode` file under the global payload.
2. [x] **Read the mode on update.** In `parse_target`, project branch, before `target_is_a_project`: when the command is `update` (pass it in — `main` calls `parse_target yes "$@"` for update; add a global `command` set in `main`), set `mode` from `<project>/.polype/mode` when it reads `init` or `project`; otherwise, when `<project>/.polype/manifest` exists, `init` if it has no `^\.claude/commands/` line, else `project`. `install <proj>` never reads it (an explicit full install stays possible). Tests: `test_init_then_update_stays_init` (init → update: manifest 23 lines, no file under `.claude/commands|agents|skills`; install → update: still the full count) and `test_mode_inferred_without_state` (init, delete `.polype/mode`, update → 23 files and `.polype/mode` = `init`; same on a full install → `project`).
3. [x] **Installer hints follow the recorded mode.** No new code: `absorb_agents_md` (`:257-258`) and `handle_claude_md` (`:415-416`) already switch on `$mode`. Test, inside `test_mode_inferred_without_state`: an init project with a hand-written `CLAUDE.md` and no `AGENTS.local.md`, `update` → the hint says `then polype init .`.
4. [x] **Repair path.** `init` on a project whose manifest lists a full install already drops the extra copies (`cmd_install` ghost loop, `:582-586`); task 1 makes it record `init`. Test: `test_init_shrinks_a_full_install` — install → init: manifest 23, no `.claude/commands/` file on disk, `.polype/mode` = `init`. In `docs/installation.md`, near the update section (`:121`), one short paragraph (lines ≤ 100 chars): a project that went through #73 (commands laid by `update` on an init project) is repaired by `polype init .`.
5. [x] **po-session hint.** In `method/hooks/po-session.sh:244`, compute `again`: `.polype/mode` = `init`, or no mode file and a `.polype/manifest` without `^\.claude/commands/` → `polype init .`; else `polype update .`. The `absorbed` line becomes `… → $again moves it into AGENTS.local.md`. The full-install wording stays byte-identical, so `tests/no-claude-md.test.sh:98` and the negative grep of `tests/claude-md-setting.test.sh:113` keep passing unchanged; add an `init` case: `test_hints_say_init` asserts the line reads `polype init . moves it into AGENTS.local.md` on an init project.
6. [x] **`/po-setup` step 3 and docs.** `method/commands/po-setup.md:59`: "Rerun the installer if it is available — `polype init .` on a project activated by `init`, `polype update .` after an `install <project>` — so `AGENTS.md` …". `README.md:114-115` and `docs/installation.md:210-212`: drop "qui y poserait les commandes" / "sur un tel projet, `update` y poserait aussi…"; say `update` keeps the project's activation mode and `polype init .` stays the advised command and the repair. Keep the phrases pinned by `tests/installer.test.sh:179`, `tests/docs-and-eval-cleanup.test.sh`, `tests/readme-onboarding.test.sh:94,163`. Test: `test_hints_say_init` also checks `po-setup.md` names `polype init .` in step 3 and that neither doc still says `poserait`.
7. [x] **ADR-0091.** `docs/decisions/ADR-0091-la-mise-a-jour-garde-le-mode-d-activation.md` from `templates/adr.md`, `status: accepted` (owner decision, 2026-10-14): the mode lives in `.polype/mode`, committed, read by `update` and po-session, inferred from the manifest when absent; options turned down: inference alone (an inflated project reads as a full install), an `update --init` flag (forgotten, defect comes back), a second line in `version` (couples readers of the version stamp). Links ADR-0087 (state files). Test: `test_adr_records_the_mode` — the file exists, says `.polype/mode`, and names both rejected options (`--init`, inference).
8. [x] Full suite `bash tests/run.sh` green; record the checks with `po-run` in `docs/verif/s135-update-keeps-init-mode.md`.

## Scene viewpoints
—

## Run interdicts
- `drop_laid_file` (`bin/polype:223-230`) ends with an empty diff — protecting modified copies is #89.
- `method/` copies under `.claude/` and `.polype/` of this repository are not edited.
- No change to `cmd_check` or to the global install path (`target_is_the_user_home`).
- `tests/no-claude-md.test.sh`, `tests/claude-md-setting.test.sh`, `tests/readme-onboarding.test.sh`, `tests/installer.test.sh` keep every existing assertion; if one must change, the record says which and why.
- pecten and nautile are not touched (repair after the ship, separate PRs).

## The pivot
Where the mode is read: in `parse_target`, before `target_is_a_project` builds `PAIRS`, and only for `update`. Ways it could be wrong: (1) reading it for `install` too would forbid escalating an init project to a full install — compare with `test_init_then_update_stays_init`'s install branch; (2) reading it after `PAIRS` are built would leave the bug in place — the reproduction (23 → 65) is the check; (3) the inference could misfire on Polype's own repo, whose manifest is a full install — `bin/polype-dev-install .` must still record `project`.

## Files touched
`bin/polype`, `method/hooks/po-session.sh`, `method/commands/po-setup.md`, `README.md`, `docs/installation.md`, `docs/decisions/ADR-0091-la-mise-a-jour-garde-le-mode-d-activation.md`, `tests/update-keeps-mode.test.sh`, `docs/verif/s135-update-keeps-init-mode.md`.

## Test strategy
Automated, one file `tests/update-keeps-mode.test.sh`, six tests named after the criteria, all end-to-end on the real `bin/polype` and `po-session.sh` in a throwaway home (the installer's behaviour is the contract; no unit layer exists in this repo). `test_init_then_update_stays_init` is the regression test: it fails on `main` (65 files). Existing suites run unchanged. 6 tests, budget 25. No visual check.

## Done when
One commit on `story/s135-update-keeps-init-mode`, full suite green, review with no open critical, landed on `main` through a pull request; then #73 closes and pecten/nautile get their repair PRs.
