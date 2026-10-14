# Research — s130-install-refuses-collisions

[Story](../stories.md)

## Structuring facts
- No story assumption is false. `lay_down` is at `bin/polype:157` and overwrites with `mv -f` (`:162`) whatever sits at the destination; `declare -gA` is at `:359`.
- The only file that lays anything down is `lay_down`, called from two loops: `cmd_install` (`:437-442`, also reached by `init` `:454` and by `update` without a manifest `:458`) and `cmd_update` (`:476-490`). Both delete ghosts first (`:429-433`, `:469-471`), and `cmd_install` creates `$root` and `$state_dir` at `:422`: the collision check must run before those lines, right after `collect_shipped`.
- `AGENTS.md` and `.claude/settings.json` are never in `SHIPPED_LINES` (assembled `:166-181`, merged `:297-311`): a check over the shipped destinations exempts them by construction.
- Global `remove` deletes `$state_dir` (`~/.claude/polype/`) with `rm -rf` at `:566`, after the manifest loop `:562`. A set-aside file under `polype/` (payload paths `bin:polype/bin`, `method:polype/method`, `:89-90`) would be restored then destroyed unless it is held outside first.
- A hand-written `AGENTS.md` is copied (`cp`, `:168`) to `AGENTS.md.before-polype` on every run whose `AGENTS.md` lacks the marker; a second hand-written `AGENTS.md` would overwrite an earlier backup. `remove` restores the backup only when the assembled file is gone (`:548-550`).

## Story
The installer refuses to replace a file it did not lay down, and a hand-written `AGENTS.md` joins the settings. Criteria:
- `collision_stops_before_writing` — `install`, `init`, `update`, global and project: exit 1, nothing written or deleted (ghosts included) when a destination exists, is not in the manifest and differs from the shipped file; output lists each path and the option; an identical file is taken over silently; `AGENTS.md` is not a collision.
- `set_aside_is_explicit_and_undone` — `--set-aside` moves each collision to `<path>.before-polype`, goes on and says so; `remove`, global and project, puts each back before removing its state.
- `hand_written_agents_md_is_absorbed` — appended to `AGENTS.local.md` under `## Notes moved from AGENTS.md` before the assembled file replaces it; without `AGENTS.local.md`, kept as `AGENTS.md.before-polype` and said; the first `update` finding `AGENTS.local.md` absorbs it and deletes the copy; rerunning `update` changes nothing. Sentences in `method/AGENTS.md`, `/po-setup`, `bin/polype` header name `AGENTS.md` too.
- `adr_records_the_contract` — a new ADR (ADR-0088, reserved).

## Current code
- `bin/polype` (589 lines, `set -euo pipefail` `:19`). `parse_target` `:55-79` loops over args; options `--global`, `--hooks`, anything else `-*` → `die_usage` (`:63`). `usage` `:38-51`.
- `collect_shipped` `:140-144` fills `SHIPPED_LINES` (`<src>\t<dest>`), read-only. Destinations are relative to `$root` (`~/.claude` or the project).
- `cmd_install` `:420-450`: mkdir, ghosts deleted against the old manifest, every file laid down unconditionally, manifest/sums written, `wire_the_project` `:448`.
- `cmd_update` `:457-506`: no manifest → `cmd_install`. Else `load_checksums`, ghosts deleted `:469-471`, each file kept when hand-edited (`has_drifted` and differs from source, `:480`) else laid down. A destination that exists but is not in `RECORDED` has `has_drifted` false (`:396`) and is overwritten — the update-side collision.
- `wire_the_project` `:343-352`: `absorb_claude_md` `:251-280` then `assemble_agents_md` `:166-181`, then `.gitignore`, hooks path, session hook, missing settings. Project mode only.
- `absorb_claude_md` is the model to copy: skips symlinks `:254`, writes `AGENTS.local.md.polype-next` then `mv` (`:266-275`), adds a blank line when the file lacks a final newline (`:268`), heading `## Notes moved from CLAUDE.md` (`:269`), deletes sources only after the rename (`:276-279`), messages on stderr.
- `cmd_remove` `:559-575`: manifest loop `rm -f` each path `:562`, state files, global `rm -rf "$state_dir"` / project `unwire_session_hook` `:566`, `prune_empty_dirs`, `unwire_the_project` `:541-557` (restores `AGENTS.md.before-polype`).
- Header comment `:11-12`: "AGENTS.local.md, which is only read, except to append the notes moved out of a CLAUDE.md".
- `method/AGENTS.md:4` and `method/commands/po-setup.md:17` carry the same "only … `CLAUDE.md`" clause.

## Attachment points
- New preflight between `collect_shipped` and the first write, in `cmd_install` (before `:422`) and `cmd_update` (before `load_checksums`/ghosts `:460-471`). Membership of the old manifest: read `$manifest` into an assoc array when it exists.
- `--set-aside` in `parse_target` (`:57-66`), before the `-*)` arm, and a line in `usage`.
- Restore of set-aside files: the deletion in `cmd_remove` `:562`, the ghost deletions `:431` and `:470`.
- Global hold around `rm -rf "$state_dir"` `:566`.
- AGENTS.md absorption: new function called in `wire_the_project` between `absorb_claude_md` and `assemble_agents_md` (`:345-346`); `assemble_agents_md` loses its `cp` (`:167-170`).

## Verified interfaces
- `sum_of() { cksum < "$1"; }` `:111` → `"<crc> <size>"`. Story asks `cksum`, not `cmp`/`diff`: `tests/hooks-installer-docs-cleanup.test.sh:79-81` runs `remove` with a `PATH` of `bash env cat cp mv rm rmdir mkdir chmod find sed sort head tail grep awk git wc cksum dirname basename readlink touch tr` only (no `mktemp`, no `cmp`, no `jq`).
- `marker='<!-- Assembled by Polype.'` `:33`; `method/AGENTS.md:1` starts with it; hand-written = first line lacks it (`:167`).
- `PRUNE_DIRS` global `commands agents skills`, mindepth 1 (`:92-93`); project `.claude .polype`, mindepth 0 (`:107-108`).
- Messages convention: `polype: …` on stderr, final summary on stdout (`:503-505`).
- Test helpers: `tests/lib.sh` `scratch_repo`, `fail`, `contains`, `require_file`; global tests isolate `HOME` and `CLAUDE_CONFIG_DIR` and guard them (`tests/global-install.test.sh:9-28`); `copy_of_the_method` (`tests/installer.test.sh:11-16`) lets a test change what is shipped.

## Traps
- `mktemp` is absent from the reduced `PATH` (`hooks-installer-docs-cleanup.test.sh:79`), and that test runs project `remove`. The global hold dir must be built without `mktemp` (e.g. `$root/.polype-restore.$$`), or only be needed in global mode, which that test does not run.
- Existing tests that must stay green unchanged: `tests/install.test.sh:37-44` (no `AGENTS.local.md`: backup kept across two installs), `tests/installer.test.sh:103-113` (remove restores the backup, no `AGENTS.local.md`), `tests/installer.test.sh:58-66` (ghost removed, `my-own.md` not shipped so not a collision), `tests/local-copy-checksums.test.sh:39-63` (init straight over an install, then install again: init's run deletes the `.claude/` ghosts, so the next install sees no collision), clone scenarios `:65-152` (the clone's committed manifest exempts its copies), `tests/global-install.test.sh:133-157` (the payload installs itself; manifest exists).
- `tests/no-claude-md.test.sh:105-111` quotes the sentence of `method/AGENTS.md:149` and `/po-setup:56` exactly: the edited clauses are `:4` and `:17`, not those.
- `tests/adr-directory.test.sh:20,27`: `method/AGENTS.md` and method commands must not name `docs/decisions/`.
- `tests/overlap.test.sh`: no 8-word run shared with Killer SaaS in `method/`.
- `docs/installation.md:186,320-322` describe the old backup; not owned (s132 owns it), so it stays stale until s132.
- A destination that is a dangling symlink: `cksum <` fails; treat `-L` without `-e` as a collision.
- `set -e` and `[ … ]` loops: follow the existing `|| continue` / `|| return 0` style so an empty set does not abort.

## Open questions
- `.before-polype` already present at set-aside time: the plan stops before writing (ADR-0088 says so).
- Hand-written `AGENTS.md` plus an existing `AGENTS.md.before-polype` without `AGENTS.local.md`: today the backup is overwritten (`:168`). The plan stops in preflight rather than lose one.
- `install` over a manifest file the person edited still overwrites it (`:439`); out of this story (the story bounds collisions to paths outside the manifest).
- `--set-aside` passed to `check` or `remove`: accepted and ignored; the plan adds no refusal.

## Complexity
Story 3 → 3. One script, but five paths (install, init, update, global and project remove) and a new preflight; the global `rm -rf` hold is the delicate part.

## Split
—
