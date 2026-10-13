# Research — s123-local-copy-checksums

## Structuring facts
- **Root cause.** `update` and `check` call `has_drifted` (`bin/polype:341-345`), which compares a copy against `RECORDED`, loaded from `$checksums` = `.polype/checksums` (`bin/polype:75`, `:334-339`). That file is committed, `.claude/` is not in Polype, pecten or nautile. A commit that refreshes `.polype/` therefore brings the sums of the *new* version while each checkout's `.claude/` still holds the *old* copies, so every changed copy reads as hand-modified. `update` then keeps it and writes the recorded (new) sum back (`bin/polype:422-426`), so the copy stays stuck at the old version for good. Reproduced below.
- **False assumption: `.claude/` is ignored by git.** Not by the projects. Polype's `.gitignore:1-6` ignores only `.claude/worktrees/`. `.claude/` is ignored on this machine by the user's global excludes (`~/.config/git/ignore:7`, shown by `git check-ignore -v`). The installer even tells `install <project>` users to **commit** `.claude/` (`bin/polype:363`, `docs/installation.md:209`). So the fix must work both ways: an ignored `.claude/` (Polype, pecten, nautile: 0 tracked `.claude/` files, 42 manifest entries each) and a committed one. The story should say "`.claude/` is not committed in these checkouts", not "ignored by git".
- **Partly false: `init` writes local sums.** `init` lays no copy under `.claude/` (`bin/polype:97-98`; `tests/global-install.test.sh:60-62` checks that). With `init`, the local file has nothing to hold: it is absent.
- **Partly false: `.polype/checksums` keeps `AGENTS.md`.** `AGENTS.md` is assembled (`bin/polype:162-177`) and never laid down, so it never had a manifest entry or a checksum (`bin/polype:384-389`). After the story `.polype/checksums` holds only `.polype/` paths. Adding `AGENTS.md` is out of scope.
- Global install is unaffected: its paths are `commands/…`, `polype/…` under `~/.claude` (`bin/polype:86-87`), with no `.claude/` prefix, and no repository.

## Diagnostic
**Reproduction** (throwaway repos under `/tmp/s123-repro.QFj3`, none in the worktree). Bare origin, clones A and B with `.claude/` in `.gitignore`. A: install the old method and push. B: clone, `update`, which reports 0 modified. A: `update` with a method copy whose `po-plan.md` gained a line, commit and push `.polype/` and `AGENTS.md`. B: `git pull`. Then:
- `polype check .` → `modified: .claude/commands/po-plan.md`
- `polype update .` → `polype: modified, left as it is: .claude/commands/po-plan.md … 1 left modified`
- `check` again → still modified, and the copy still lacks the new line (`grep -c` = 0). `git status` in B stays clean, so the stuck state is invisible to git.

**Hypotheses**
1. *Stale copy versus committed sums of the newer version.* Refuted if B's `check` after the pull says none modified. It said modified: **kept**.
2. *`update` itself corrupts the sums.* Refuted if B's `update` before the pull already reports drift. It reported `0 left modified`: **discarded**.
3. *`cksum` differs between checkouts (line endings, attributes).* Refuted if an untouched copy reads as intact in a clone. B's first `update` and every unchanged file after the pull read as intact: **discarded**.

## Story
The sums of the copies under `.claude/` move to `.claude/.polype-checksums`, which is never committed, so a refresh delivered by a PR no longer makes each checkout's copies look hand-edited. Owner's option A (2026-10-14); option B (recognising every published version) rejected.
- `local_copies_have_local_sums`: `init`, `install <project>`, `update` write the `.claude/` sums into `.claude/.polype-checksums`; `.polype/checksums` keeps only what git tracks.
- `update_after_a_pr_refresh_replaces_stale_copies`: after `.polype/` and `AGENTS.md` come in by a commit from elsewhere, `update` replaces the stale copies without calling them modified; a hand-edited copy stays and is named.
- `local_sums_file_stays_out_of_git`: the installer appends the line to `.gitignore` when git does not already ignore the file; `check` reads both files.
- `first_update_migrates`: without a local file, copies matching `.polype/checksums` count as intact, the local file is written, and the installer says so.

## Current code
`bin/polype`, 527 lines, `set -euo pipefail`, bash associative arrays.
- State paths: `manifest`, `checksums`, `version_file` under `$state_dir` (`:74-76`); project `state_dir=$root/.polype` (`:96`), global `$root/polype` (`:85`).
- Line format of a sums file: `<crc> <size> <path>` (`sum_of` = `cksum <` at `:107`, written `:388`, `:426`, `:429`, read `:338`).
- `cmd_install` (`:367-397`): deletes ghosts, writes `$manifest.next` and `$checksums.next` for every shipped line, renames them, stamps, prunes empty dirs, `wire_the_project`. `cmd_init` = warning + `cmd_install` (`:399-402`).
- `cmd_update` (`:404-445`): `cmd_install` if no manifest; `load_checksums`; ghosts; per file, drifted → keep and re-record the old sum, else lay down and record; reports `modified, left as it is:` on stderr.
- `cmd_check` (`:447-478`): `load_checksums`, walks the manifest, `has_drifted`.
- `cmd_remove` (`:498-513`): `rm -f "$manifest" "$checksums" "$version_file"` (`:502`), then prune, then unwire.
- `ignore_worktrees_and_env` (`:179-189`): appends a pattern to `.gitignore` when `grep -qxF` does not find it. `wire_the_project` (`:321-329`) runs only in project mode.
- Header comment `:14-16` says "Three state files … in .polype/".

## Attachment points
- `target_is_a_project` (`:93-105`) / `parse_target` (`:74-76`): where the local file's path is defined (project mode only).
- `load_checksums` (`:334-339`): read the two files.
- The two writing loops (`:382-392`, `:417-435`): route each sum by its path's `.claude/` prefix.
- `wire_the_project` (`:321-329`): the `.gitignore` guarantee.
- `cmd_remove` (`:502`): delete the local file.
- `docs/installation.md` `## Les trois fichiers d'état` (`:211-224`) and `## install ou update` (`:235-239`).

## Verified interfaces
- `has_drifted <path>`: returns 1 (intact) when no sum is recorded, and 0 when the recorded sum differs from `sum_of "$root/$path"` (`:341-345`).
- `lay_down <src> <dest>` writes `$root/$dest` atomically (`:153-159`).
- `SHIPPED_LINES` entries are `<src>\t<dest>` (`:110-118`); in project mode dests start with `.claude/` or `.polype/` (`:100-101`).
- `prune_empty_dirs` prunes `.claude` and `.polype` with `-mindepth 0` (`:103-104`, `:146-148`).
- `scratch_repo` (`tests/lib.sh:46-53`) sets `GIT_CONFIG_GLOBAL=/dev/null` (`tests/lib.sh:9`), but **not** `XDG_CONFIG_HOME`.
- `copy_of_the_method` lives in `tests/installer.test.sh:11-16`, not in `lib.sh`.

## Traps
- **Machine-dependent ignore.** Git reads `$XDG_CONFIG_HOME/git/ignore` (default `~/.config/git/ignore`) even with `GIT_CONFIG_GLOBAL=/dev/null`. On this machine it ignores `.claude/`, so `git check-ignore` says ignored and the line would not be added, while CI adds it. Verified: with `XDG_CONFIG_HOME=/nonexistent HOME=<tmp>` `check-ignore` exits 1. Any test of the `.gitignore` line must pin `XDG_CONFIG_HOME` to an empty dir.
- **Committed `.claude/`** (the documented default, `bin/polype:363`). When a PR refreshes the copies themselves, the local file still holds the old sums: without care the bug comes back reversed (fresh copies read as modified). A copy byte-identical to the file being shipped is not a hand edit.
- **Already-stuck checkouts.** At migration, a checkout whose `.polype/checksums` is already newer than its copies still sees them as modified once. Option B was the cure for that and was rejected. Polype's root is clean today (`polype check .` → none modified).
- **Global mode** must never create `$root/.claude/`: `tests/global-install.test.sh:40` fails if it does.
- **`remove`** must delete the local file, or `.claude/` survives the prune.
- Existing tests that will run: `tests/installer.test.sh` (drift, preserve, refresh, state files not in the manifest at `:142-149`, remove intact incl. `.gitignore` unchanged by `remove` at `:99`), `tests/install.test.sh` (`.gitignore` lines at `:76-82`), `tests/global-install.test.sh` (doc names `manifest` and `checksums` at `:125`).
- Tests that clone need per-clone `user.email`/`user.name` (global config is `/dev/null`) and `file://` URLs.
- No migration of data in the database sense; the format of a sums line is unchanged.

## Open questions
- Should `check` also accept a copy identical to the shipped source (a committed `.claude/` refreshed by a PR, before any `update`)? The plan says no: `check` reports, `update` settles, and the doc says so.
- Should `remove` take the `.gitignore` line back? No: `remove` never touches `.gitignore` (`tests/installer.test.sh:99`).

## Complexity
Story: 3. After reading: **3**. One script with about 40 changed lines in five functions, plus one doc section. The committed-`.claude/` case adds a condition, not a component.

## Split
Not needed (score 3).
