# Research — s142-payload-refuses-foreign-files

[Story](../stories.md)

## Structuring facts
- **False assumption of the story — `Owns` is one test short.** `adr_records_the_payload_rule` makes the
  `superseded-by` of ADR-0088 change, but `tests/drop-keeps-modified.test.sh:184` pins it with
  `grep -qx 'superseded-by: \[ADR-0092\]'`. That file is outside the story's `Owns`, and `po-bounds`
  refuses the implementer any write outside `docs/` and `Owns` read at the fork point
  (`method/hooks/po-bounds.sh:5-8`, `:155-198`). The story must add `tests/drop-keeps-modified.test.sh`
  to its `Owns` on `main` before execution, and the lane must start from that commit.
- **Root cause (#118).** Polype keeps no list of what the payload legitimately holds: a run whose source
  is the payload ships every file `find -type f` sees under `polype/bin` and `polype/method`
  (`bin/polype:137-145` with `PAIRS` at `:112-113`), and `refuse_collisions` cannot see such a file since
  its source and its destination are the same file (`bin/polype:200-201`). It is laid as active
  method and enters the manifest (`:687`, `:740`), after which Polype treats it as its own.
- Ways a person's file gets into the payload: dropped there by hand, `--set-aside` under `polype/`
  (`bin/polype:230-233`), `drop_laid_file` putting a `.before-polype` back (`:301-303`, `:316-319`).
- A run from a repository does not protect the payload either: a foreign file at a path it does not
  ship is never looked at (`refuse_collisions` walks shipped destinations only, `:198`), and
  `remove --global` deletes it with `rm -rf "$state_dir"` (`:840`) while printing "The files you put
  there yourself were left alone" (`:854`).

## Diagnostic
Reproduced in throwaway `CLAUDE_CONFIG_DIR`s under `/tmp`, nothing written to the worktree.
1. `install --global` from the worktree; `echo mine > $H/polype/method/commands/mine.md`;
   `$H/polype/bin/polype update --global` → "116 files"; `$H/commands/mine.md` exists; the manifest
   lists `mine` twice (`commands/mine.md`, `polype/method/commands/mine.md`).
2. Same home, `echo x > $H/polype/method/skills/foreign.txt`, `update --global` from the worktree →
   "114 files, 2 removed": `mine.md` deleted from the payload as an unmodified laid file (the person's
   file is lost, `drop_laid_file` `:315`); `foreign.txt` silently left. `remove --global` → payload
   gone with `foreign.txt`, message "files you put there yourself were left alone".
3. Fresh home, person's `polype/method/commands/po-help.md`, `install --global --set-aside`, then
   `$H/polype/bin/polype update --global` → `commands/po-help.md.before-polype` laid as an active
   command and both `.before-polype` paths enter the manifest.

| Hypothesis | Refuting observation | Verdict |
| --- | --- | --- |
| H1 A run from the payload takes every file under it for a source | `commands/mine.md` not laid in step 1 | **kept** — laid, manifest lists it |
| H2 The defect is only `drop_laid_file`'s put-back (#118's framing) | a foreign file reaching active copies with no put-back involved | discarded — step 1 has no put-back |
| H3 A run from a repository at least protects a foreign payload file | a foreign file reported, or surviving `remove` | discarded — step 2: silent, then deleted |

## Story
The payload signs itself: an install or update `--global` run from a repository writes
`polype/payload.sums` (cksum + path per payload file, state files excluded); a file under `polype/` that
is not a state file, not in this machine's manifest and not shipped (repo run) / not in `payload.sums`
(payload run) is foreign and stops `install`, `update`, `init` before any write, with or without
`--set-aside`; a collision under `polype/` stops too (`--set-aside` no longer applies there). Manifest
files keep the s137/s139 drop rules. A synced newer payload with its `payload.sums` installs. A stale
`.before-polype` under `polype/` is foreign; `remove --global` keeps its `held` path. `remove --global`
stops on a payload file absent from manifest and `payload.sums`. An unsigned payload: runs from it stop
(install/update/init), `check`/`remove --global` say it is unsigned. ADR-0095 supersedes ADR-0088 on
set-aside under `polype/`; `docs/installation.md` says it, sync path included. Criteria:
`payload_signs_itself`, `foreign_payload_file_stops_install`, `synced_payload_still_installs`,
`old_set_aside_never_put_back_in_payload`, `remove_stops_on_foreign_payload_file`,
`unsigned_payload_says_so`, `adr_records_the_payload_rule`.

## Current code
- `bin/polype:31-38` resolves `$0` through links, `base` = parent of the script's dir (logical `pwd`),
  `home` = `CLAUDE_CONFIG_DIR` or `~/.claude`.
- `target_is_the_user_home` `:104-117`: `root` = home (logical `pwd`), `state_dir` = `$root/polype`.
- `target_is_a_project` `:119-132`: init/project PAIRS read `method/templates`, `method/hooks` from `base`.
- `collect_shipped` `:163-167` → `SHIPPED_LINES` "src<TAB>dest"; called by `cmd_install` `:665` and
  `cmd_update` `:708` (`cmd_init` `:701-704` calls `cmd_install`; `cmd_update` without manifest too `:707`).
- Check order today: `collect_shipped`, `load_checksums`, `refuse_taken_kept_copies dropped`,
  `refuse_collisions` (`:665-668`, `:708-711`); first write `mkdir -p` `:669` / drop loop `:720`.
- `refuse_collisions` `:192-234`: set-aside branch `:214-233`, `.before-polype` taken check `:221-229`.
- `start_sums`/`record_sum`/`finish_sums` `:614-636`: checksums lines are `"<crc> <size> <dest>"`;
  `cmd_update` records the *recorded* sum for a modified file left in place (`:735`).
- `drop_laid_file` `:297-321`: payload branch `:299-306` moves an edit to `polype.kept/` then puts a
  `.before-polype` back into the payload (`:301-304`); generic put-back `:316-319`.
- `cmd_check` `:761-792`; `cmd_remove` `:812-858` (payload `held` path `:823-829`, `rm -rf` `:840`,
  put back `:844-849`).
- Usage `:57-58`: `--set-aside` "move each file Polype did not lay down … instead of stopping".

## Attachment points
- New check function called in `cmd_install` and `cmd_update` after `load_checksums`, before
  `refuse_taken_kept_copies`/`refuse_collisions` (story note: "avant `refuse_collisions`, les sommes
  chargées").
- `shipped_pairs` `:137-145`: from the payload, only `payload.sums` entries are sources.
- `refuse_collisions` `:213-220`: payload collisions stop before the set-aside branch.
- `finish_sums` `:627` or right after it in both commands: write `payload.sums` on repo runs, global.
- `cmd_remove` before `:817`; `cmd_check` near `:773`.

## Verified interfaces
- `is_payload_path <dest>` `:236` — true in global mode for `polype/…`; false in init/project mode
  (there `mode` is `init`/`project`), so a payload check for `init` cannot use it.
- `has_drifted <path>` `:638-642`, needs `RECORDED` (`load_checksums` `:602-609`).
- `sum_of` `:134` = `cksum < file` → `"<crc> <size>"`; checksums lines parse with `read -r crc size path`.
- `$manifest`/`$checksums` point at `$state_dir` (`:87-89`): the project's `.polype/` under `init`, so
  the global manifest must be read as `<home>/polype/manifest` explicitly.
- `recorded_mode` `:95-102` must keep its name (story note; `tests/drop-keeps-modified.test.sh:168`).

## Traps
- **Out-of-Owns test that turns red**: `tests/drop-keeps-modified.test.sh:184` (see first fact).
- Tests that change with the rule (story notes, confirmed): `tests/install-collisions.test.sh:165-177`
  (`echo mine > $H/polype/bin/polype` then `install --global --set-aside`) and
  `tests/payload-kept-outside.test.sh:165-176` (the "aside" home). The "aside" remove case must now build
  its `.before-polype` by hand after the install, as an older install would have left it.
- `tests/global-install.test.sh`: every payload run (`:141`, `:149`, `:172`, `:208`) follows a repo
  install that will now sign the payload, so they should stay green unchanged; `:73` and `:144` count
  files, and `payload.sums` must exist after both runs alike and never enter the manifest (`:143`).
- `tests/payload-kept-outside.test.sh` installs from a method copy (`$COPY`, outside the payload), so it
  signs; `test_moved_copy_is_not_shipped` `:85-93` then runs from the payload and must stay green.
- `tests/readme-onboarding.test.sh:57-59`: no `mkdir|cp|mv` line may precede the bash-version guard.
- Doc phrases pinned in `docs/installation.md`: `tests/readme-onboarding.test.sh:144-146`
  (`--set-aside`, `.before-polype`, `ADR-0088`…), `tests/local-copy-checksums.test.sh:156-160`
  (`## Les fichiers d'état` keeps `.claude/.polype-checksums`, `ADR-0087`, `ignoré par git`),
  `tests/global-install.test.sh:118-127`, `tests/installer.test.sh:173-180`,
  `tests/drop-keeps-modified.test.sh:186-187`, `tests/payload-kept-outside.test.sh:192-195`;
  `tests/hooks-installer-docs-cleanup.test.sh:108` (prose ≤ 100 chars).
- `method/AGENTS.md` says "unless `--set-aside` moves it (ADR-0088)", pinned by
  `tests/install-collisions.test.sh:238`; outside `Owns`, it stays and becomes incomplete for `polype/`.
- `bin/polype:36` and `:109` use logical `pwd`; a dotfiles `~/.claude` that is a symlink, or a PATH link
  pointing at the physical path, makes "base is `<root>/polype`" fail on a string compare.
- From the payload, an edited signed file is still laid onto itself and its edited sum recorded
  (`:731` compares the file with itself): that is #115, s143's, out of scope.
- No migration. One file of code.

## Open questions
- `payload.sums` path form: "chemin sous `polype/`" read here as the manifest's form
  (`polype/method/…`), which keys straight into the manifest and `RECORDED`; the plan decides.
- A stale `.before-polype` that a polluted manifest already lists (step 3 above): the AC's definition of
  foreign requires "absent from the manifest", yet `old_set_aside_never_put_back_in_payload` says it is
  never a source. The plan decides whether a `*.before-polype` under `polype/` is foreign regardless.
- `remove --global` on a signed payload holding `<p>.before-polype` for a manifest path `p`: the story
  wants it put back (held path), so the remove check must exempt it although it is in neither list.

## Complexity
4 → 4. One file of code, but five commands, two run origins (repository, payload), two modes of the
payload check (global, init from the payload) and four existing test files touched.

## Split
—
