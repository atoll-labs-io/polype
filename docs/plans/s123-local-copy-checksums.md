---
validated: yes
---
# Plan — s123-local-copy-checksums

Branch `story/s123-local-copy-checksums`. Read `docs/research/s123-local-copy-checksums.md` first; this plan builds on it without repeating it. Decision: ADR-0087 (accepted, option A chosen by the owner on 2026-10-14).

## Story
The sums of the copies under `.claude/` move to `.claude/.polype-checksums`, which is never committed. A refresh delivered by a PR then no longer makes each checkout's copies look hand-edited. Root cause: `has_drifted` compares the copies against the committed `.polype/checksums` (`bin/polype:75`, `:334-345`), and `update` writes the newer sum back (`:426`).
- `local_copies_have_local_sums`: `init`, `install <project>` and `update` write the `.claude/` sums to `.claude/.polype-checksums`. `.polype/checksums` keeps only `.polype/` paths: `AGENTS.md` never had a sum (research). `init` has no `.claude/` copy, so it has no local file.
- `update_after_a_pr_refresh_replaces_stale_copies`: after a commit from elsewhere has refreshed `.polype/` and `AGENTS.md`, `update` replaces the stale copies without naming them. A hand-edited copy stays and is named.
- `local_sums_file_stays_out_of_git`: the installer appends `.claude/.polype-checksums` to `.gitignore` when git does not already ignore it. `check` reads both files.
- `first_update_migrates`: without a local file, copies matching `.polype/checksums` count as intact, the local file is written, and the installer says so.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Routing a sum to one of two files | Already in this repository: the `"$(sum_of …)" "$dest" >> …next` lines (`bin/polype:388`, `:429`) and the `.next` then `mv` pattern (`:382-392`). Only the target file changes, chosen by a `case "$dest" in .claude/*)`. | — |
| Reading two sums files | Already here: `load_checksums` (`:334-339`), run on each file in turn. | — |
| Making sure the file is ignored | Already here: the `grep -qxF … || printf >> .gitignore` of `ignore_worktrees_and_env` (`:185-188`). It is gated by the platform's `git check-ignore -q`. | Repository: no existing "is it ignored" check. |
| "Copy equals what is shipped" | Already here: `sum_of` (`:107`) on the source and on the copy. | — |
| Test helper copying the method | Already here: `copy_of_the_method` (`tests/installer.test.sh:11-16`), repeated in the new file because each test file loads only `lib.sh` (`tests/run.sh:70`) and `lib.sh` is not owned. | Moving it to `lib.sh`: not in `Owns`. |

## Tasks
1. [x] **State path.** Set `local_sums="$root/.claude/.polype-checksums"` in `target_is_a_project` (`bin/polype:93-105`), and `local_sums=""` in `target_is_the_user_home`. Rewrite the header comment (`:14-16`): three state files in `.polype/`, plus the local sums of `.claude/` copies, which belong to one checkout and are never committed. Test that fails if wrong: `test_installer_global_puts_commands_in_the_user_home` (`tests/global-install.test.sh:40`, no `$H/.claude`).
2. [x] **Read both files.** `load_checksums` loads `$checksums`, then `$local_sums` when it is set and exists; a later entry overrides an earlier one for the same path. Leave `has_drifted` unchanged. Fails if wrong: `test_installer_check_reports_drift` (`tests/installer.test.sh:42`) and `first_update_migrates`.
3. [x] **Write the two files.** Add a helper (for example `record_sum <sum-line> <dest>`). In project mode it appends a `.claude/*` dest to `$local_sums.next` and anything else to `$checksums.next`; in global mode everything goes to `$checksums.next`. Use it at `:388`, `:426` and `:429`. Add a helper that finishes the sums: it renames `$checksums.next`. When `$local_sums.next` is non-empty, it renames that one too (after `mkdir -p` of its directory). Otherwise it deletes both `$local_sums.next` and any old `$local_sums`, which is the `init` case and the case of a project going from `install` to `init`. Never create `.claude/` in global mode. Call it in `cmd_install` and `cmd_update` before `prune_empty_dirs`. Fails if wrong: `local_copies_have_local_sums`.
4. [x] **`update`: a copy equal to what is shipped is intact, plus migration.** In the `cmd_update` loop (`:420-432`), the copy is kept as modified only when `has_drifted` holds **and** `sum_of "$root/$dest"` differs from `sum_of "$src"`. Otherwise it is laid down and recorded as today. Before writing, note whether `$local_sums` existed. After writing, when it did not exist, `local_sums` is set and the file now exists, print to stderr `polype: .claude/.polype-checksums written: the sums of the .claude/ copies now live there, out of git`. The migration itself needs no other code: task 2 already reads the `.claude/` entries of an old `.polype/checksums` when there is no local file. Fails if wrong: `first_update_migrates` and `committed_copies_refreshed_by_a_pr_stay_intact`.
5. [x] **Keep it out of git; take it back on remove.** Add `ignore_local_sums`, called from `wire_the_project` (`:321-329`) after `ignore_worktrees_and_env`. It returns when `$local_sums` is missing. It also returns when `git -C "$project" check-ignore -q .claude/.polype-checksums` succeeds. Otherwise it appends `.claude/.polype-checksums` to `.gitignore`, unless `grep -qxF` already finds it. A project that is not a git repository gets the line. In `cmd_remove`, delete `$local_sums` together with the state files (`:502`), only when it is set and before `prune_empty_dirs`. Do not touch `.gitignore` on `remove`. Fails if wrong: `local_sums_file_stays_out_of_git`, and `test_installer_remove_leaves_the_project_intact` (`tests/installer.test.sh:85`).
6. [x] **Doc.** In `docs/installation.md`, `## Les trois fichiers d'état` (`:211-224`): add a paragraph or row for `.claude/.polype-checksums`. Say it holds the `cksum` of the `.claude/` copies, belongs to one checkout, is ignored by git (the installer adds the `.gitignore` line when needed), and is never in the manifest. `.polype/checksums` keeps only `.polype/` files. `init` has none. Cite ADR-0087. In `## install ou update` (`:235-239`), add three things. A copy identical to the shipped file is refreshed, so a PR that refreshed `.polype/` or committed copies leaves nothing stuck. The first `update` after this version migrates and says so. A checkout already stuck before migration is cleaned by `polype install <projet>`. Keep the words `manifest` and `checksums` (`tests/global-install.test.sh:125`). Fails if wrong: `installation_doc_names_the_local_sums`.
7. [x] **Tests.** Write `tests/local-copy-checksums.test.sh` with the header `# s123 — the sums of the .claude/ copies live next to them, out of git.` and the six functions of the test strategy. Extend `test_installer_state_files_are_not_their_own_ghosts` (`tests/installer.test.sh:142-149`) with one line: `.claude/.polype-checksums` is not in the manifest. Run `bash tests/run.sh local-copy-checksums.test.sh installer.test.sh install.test.sh global-install.test.sh`, then the full suite once: `po-run --story s123-local-copy-checksums --label full-suite -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- `method/`, `.claude/`, `.polype/` and `AGENTS.md` end with an empty diff: no method text changes, and the installed copies are never edited.
- `tests/lib.sh`, `tests/run.sh` and every test file outside `Owns` end with an empty diff. `tests/install.test.sh` and `tests/global-install.test.sh` stay unchanged unless a clause they check changes; none should.
- Global mode behaves exactly as before: no `.polype-checksums` file and no `.claude/` directory under `$CLAUDE_CONFIG_DIR`. Only `$checksums` is written.
- `remove` leaves `.gitignore` byte-identical.
- No test reads the developer's git excludes: every test that asserts on `.gitignore` exports `XDG_CONFIG_HOME` to an empty directory of the scratch area.
- Do not run `polype install`, `update` or `remove` on the worktree or on the repository root. Every run happens in a scratch directory.
- Option B (recognising older published versions, reading git history) is out of scope (ADR-0087).

## The pivot
The plan rests on this: **a copy is judged against the sum this checkout recorded, or against the file now being shipped, and never against a sum another checkout committed.** It could be wrong in three ways:
1. *A committed `.claude/`.* Without task 4's "equal to shipped" rule, a PR that refreshes the copies leaves the local file stale, and the bug comes back reversed. Check it with `committed_copies_refreshed_by_a_pr_stay_intact`, and by disabling that condition: the test must fail.
2. *The override order in `load_checksums`.* If `.polype/checksums` were read last, an old pre-s123 `.polype/checksums` pulled from elsewhere would beat the local sums. Compare against `update_after_a_pr_refresh_replaces_stale_copies` with an old-format `.polype/checksums`.
3. *`git check-ignore` depends on the machine.* On this machine `~/.config/git/ignore` ignores `.claude/`, which would hide a missing `.gitignore` line. Check that the test pins `XDG_CONFIG_HOME`.

## Files touched
`bin/polype`, `docs/installation.md`, `tests/local-copy-checksums.test.sh` (new), `tests/installer.test.sh` (one assertion). Also `docs/research/`, `docs/plans/` and `docs/decisions/ADR-0087-…` from this stage.

## Test strategy
Every test is a bash test at the installer's own layer, run in scratch repositories, as the existing installer tests are. Clones use `file://` URLs and set `user.email`/`user.name` per clone, because `GIT_CONFIG_GLOBAL=/dev/null`. The "new" method is a copy of `bin/` and `method/` with one line appended to a shipped command; the "old" one is `$ROOT`. Six new tests and one line added to an existing test, within `Test budget` 25:
1. `test_local_copies_have_local_sums`. `install` → `.claude/.polype-checksums` lists every `.claude/` path of the manifest, and `.polype/checksums` has no `.claude/` line. `update` → the same. `init` (with `CLAUDE_CONFIG_DIR` pointing to an empty scratch dir) on a fresh project → no local file. `remove` after `install` → no local file and no `.claude/commands`.
2. `test_update_after_a_pr_refresh_replaces_stale_copies`. P has `.claude/` in `.gitignore` and is installed with the old method, and one of its other copies is hand-edited. Clone Q from P, `update` Q with the new method, commit and pull into P. `update` P with the new method: the stale copy now holds the new line and is not named on stderr; the hand-edited copy keeps its edit and is named.
3. `test_local_sums_file_stays_out_of_git`. With `XDG_CONFIG_HOME` empty: `install` twice → `.gitignore` holds `.claude/.polype-checksums` exactly once, and `git status --porcelain` does not list it. A project whose `.gitignore` already holds `.claude/` → the line is not added. Then a hand edit to the copy plus `check` → it is named and the exit is non-zero, which shows `check` reads the local file.
4. `test_first_update_migrates`. After `install`, append the local file to `.polype/checksums`, delete the local file, and hand-edit one copy. `update`: untouched copies are not named, the hand-edited one is named, the local file exists with `.claude/` lines, `.polype/checksums` has none, and stderr contains `.claude/.polype-checksums written`.
5. `test_committed_copies_refreshed_by_a_pr_stay_intact`. P commits `.claude/`. Clone Q, `update` Q with the new method, commit the copies, pull into P. `update` P with the new method → no `modified, left as it is`. Then `check` → exit 0.
6. `test_installation_doc_names_the_local_sums`. In `## Les trois fichiers d'état`: `.claude/.polype-checksums`, `ADR-0087`, and a phrase saying it is ignored by git.

Each one fails when its rule goes: no routing (1, 4), comparison against the committed file (2), no `.gitignore` step or `check` reading one file only (3), no migration message or no local read (4), no "equal to shipped" rule (5). Visual checks: none.

## Done when
- The seven tasks are ticked, and the four targeted test files pass.
- The full suite passes through `po-run`, and its row is in `docs/verif/s123-local-copy-checksums.md`.
- One commit on `story/s123-local-copy-checksums` carries the code, the tests, the doc, the research, this plan and ADR-0087.
- The review finds no open critical finding. The story lands as `s123-local-copy-checksums: Les copies de .claude/ se comparent à ce que le checkout a installé`.
