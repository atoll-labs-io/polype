# Research — s139-payload-kept-outside

[Story](../stories.md)

## Structuring facts
- Root cause (#111): `shipped_pairs` (`bin/polype:137-145`) lists every file found by `find` under `$base/method`; run from the payload, `$base` is `~/.claude/polype` (`bin/polype:36`), so a modified copy that `drop_laid_file` keeps in place (`bin/polype:240-246`) is a source again and is re-laid, active copy included. Proof below (`## Diagnostic`).
- `refuse_collisions` cannot catch it: the payload destination is its own source (same sum, `bin/polype:201`) and the active copy was deleted by the previous run, so nothing collides.
- #110: `test_update_ghost_keeps_a_modified_copy` (`tests/drop-keeps-modified.test.sh:93-110`) checks the manifest and `.claude/.polype-checksums` but not `.polype/checksums`; `out_of_the_state` (`:62-67`) checks all three.
- With `--set-aside`, `refuse_collisions` writes (`bin/polype:230-233`): a "kept copy already taken" check must run **before** it, not after, hence `load_checksums` moving ahead of it (`bin/polype:599-600`, `:640-641`).
- No story assumption is false. The decision (move to `polype.kept/`, delete once shipped) is the owner's (stories, M15 header, 2026-10-15/16): ADR-0093 records it as accepted, no technical choice waits.

## Diagnostic
Reproduction, in `/tmp` with a copy of `bin/` and `method/`, `CLAUDE_CONFIG_DIR` in it:
1. `install --global` from the copy; `echo "# mine" >> $H/polype/method/commands/po-help.md`; delete `method/commands/po-help.md` from the copy.
2. `install --global` from the copy → `polype: modified, kept: …/polype/method/commands/po-help.md`; `commands/po-help.md` gone; manifest lists no `po-help` (0 lines).
3. `$H/polype/bin/polype update --global` → `114 files, 0 removed`; `$H/commands/po-help.md` exists again, manifest lists `commands/po-help.md` and `polype/method/commands/po-help.md`. Defect reproduced.

Hypotheses:
- H1 — `shipped_pairs` enumerates the payload's own tree, so a kept file becomes shipped. Refuted if the manifest after step 3 did not list it. It lists both paths: **kept**.
- H2 — `refuse_collisions` should have stopped step 3. Refuted by reading `bin/polype:200-203`: the destination is its own source (equal sums) and `commands/po-help.md` was absent. **Discarded**: no collision exists to detect.
- H3 — step 2 left the kept file in the manifest, so step 3 treated it as known. Refuted by `grep -c po-help manifest` = 0 after step 2. **Discarded**.

Fix direction (story-imposed): the modified payload file leaves `polype/`, so `find` can no longer see it.

## Story
A modified file of `~/.claude/polype/` that Polype no longer ships moves to `<root>/polype.kept/<path under polype/>`; a kept copy disappears once the payload ships the same content at that path; `remove --global` moves every modified payload file out before deleting the payload. ACs: `payload_copy_moves_out`, `moved_copy_is_not_shipped`, `kept_copy_removed_once_shipped`, `existing_kept_copy_never_overwritten`, `remove_leaves_kept_copies`, `update_test_checks_all_state`, `adr_records_the_kept_payload`. Active copies (`commands/`, `agents/`, `skills/`) and projects keep ADR-0092.

## Current code
- `target_is_the_user_home` (`bin/polype:104-117`): `mode=global`, `root=$home`, `state_dir=$root/polype`, payload pairs `bin:polype/bin`, `method:polype/method`; `PRUNE_DIRS` = commands/agents/skills, `prune_mindepth=1`.
- `cmd_install` (`:597-630`): `collect_shipped`, `refuse_collisions`, `load_checksums`, `mkdir`; drops each manifest path not shipped via `drop_laid_file … || true` (`:608-612`); lays every shipped file, rewrites manifest and sums; `prune_empty_dirs`.
- `cmd_update` (`:637-688`): same order; ghosts counted when `drop_laid_file` returns 0 (`:650-652`); a still-shipped modified file is left with its old sum (`:661-665`); final line `… N removed, M left modified`.
- `drop_laid_file` (`:238-254`): modified (`has_drifted`) → `modified, kept:` line, return 1, `.before-polype` left; else `rm`, put back `.before-polype`, return 0. Needs `RECORDED`.
- `cmd_remove` (`:741-779`): global `polype/*` path with a `.before-polype` → `rm` + move the set-aside file to `$root/.polype-restore.$$` (`held`, `:748-753`); other global `polype/*` → `rm -f` (`:754-756`); then `rm -rf "$state_dir"` (`:764`), put `held` back (`:765-770`), prune; final line `:775`.
- `has_drifted` (`:571-575`): recorded sum exists and differs. `sum_of` = `cksum` (`:134`).
- `refuse_collisions` (`:192-234`): "already exists" check of `.before-polype` before any `mv` (`:221-229`), wording `polype: <t> already exists; nothing set aside, nothing written`.

## Attachment points
- New helpers next to `drop_laid_file` (`bin/polype:236`): payload test (`mode=global` and `polype/*`), kept path, move-out, the pre-write "taken" check, the "now shipped" sweep.
- `drop_laid_file` top branch for a modified payload path (`:240`).
- `cmd_install` `:598-600` and `cmd_update` `:639-641`: reorder to `collect_shipped; load_checksums; <taken check>; refuse_collisions`; sweep after the lay-down loops (`:621`, `:671`).
- `cmd_remove` `:744-760`: taken check after `load_checksums`; merge the two global `polype/*` branches; `kept copies left in` line after the payload goes (`:764`).
- `docs/installation.md` `### Une copie modifiée que Polype ne pose plus` (`:306-324`), `## Ce que remove garde` (`:375-399`).
- `docs/decisions/ADR-0092-…md` frontmatter `superseded-by: []` (line 8).

## Verified interfaces
- `drop_laid_file <dest>` → 0 removed / 1 kept (`bin/polype:238`). Callers: `cmd_install:610` (`|| true`), `cmd_update:651` (counts 0), `cmd_remove:758` (`|| true`).
- `load_checksums` fills global `RECORDED` from `$checksums` (+ local sums, empty in global) (`:535-542`); reads only state files, so moving it before `refuse_collisions` changes nothing else.
- `SHIPPED_LINES` = `<src>\t<dest>` (`:136`, `:165`), filled before any write.
- Tests helpers: `scratch_repo`, `fail`, `contains`, `frontmatter`, `require_file` (`tests/lib.sh:11-46`); in `drop-keeps-modified.test.sh`: `sandbox`, `guard_home`, `run`, `ok`, `snapshot`, `copy_of_the_method`, `says`, `never_says`, `not_listed`, `out_of_the_state` (`:7-67`).
- Meta-test precedent for an AC about a test: `test_absorbed_settings_helper` reads a test body with `awk` (`tests/update-keeps-mode.test.sh:160-168`).

## Traps
- `install-collisions.test.sh:165-176`: a person's file set aside at `polype/bin/polype` must come back after `remove --global`, hold dir gone; unmodified payload, so today's `held` path must stay intact.
- `global-install.test.sh:80-100`: payload drift reported by `check`; `remove --global` leaves no `$H/polype`. Separate homes per test, unaffected by a `polype.kept/`.
- `drop-keeps-modified.test.sh:124-128`: edits `polype/method/AGENTS.md`, then `remove --global`, asserts no `$H/polype` and no `modified, kept: $H/polype/` — still true with the new line (it says `moved out of the payload`), but it now leaves `$H/polype.kept`.
- `test_adr_records_the_choice` (`drop-keeps-modified.test.sh:165-182`) requires ADR-0092 `status: accepted` and `installation.md` keeping `modified, kept:` and `ADR-0092`: ADR-0092 is superseded only in part, stays accepted.
- Docs frozen phrases (story notes): `~/.claude/polype/`, `chezmoi`, `ADR-0087/88/89/92`, sections `## Après une mise à jour`, `## Les fichiers d'état`, `## Activer un projet`; no prose line over 100 characters (`hooks-installer-docs-cleanup.test.sh:108-109`).
- Running from the payload: `bin/polype` may move its own script; a rename keeps the open inode, as the `rm -rf` of `:764` already relies on.
- No migration (no data store). `.claude/`, `.polype/` are installed copies: not touched.

## Open questions
- Does a moved-out ghost count in update's `removed`? ADR-0092 does not count a kept ghost; the plan keeps that (return 1).
- What `<chemin>` does `modified, already kept:` name? The plan names the kept copy (where the edit lives).
- Does `polype.kept/` itself go when emptied? The plan removes it too (Polype created it).
- Out of scope, seen while reading: run from the payload, a modified payload file **still shipped** is its own source, so `update` (`:661`) sees no difference and re-records it as intact, spreading the edit to the active copy (verified in `/tmp`: `0 left modified`, `commands/po-plan.md` ends with the edit, `check --global` says none modified). To file as an issue.

## Complexity
Story 3 → 3: one file of code, four small helpers, one doc section, one ADR; the pre-write ordering is the only delicate point.

## Split
—
