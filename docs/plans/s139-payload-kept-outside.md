---
validated: yes
---
# Plan — s139-payload-kept-outside

[Story](../stories.md) · [Research](../research/s139-payload-kept-outside.md)

Branch `story/s139-payload-kept-outside`. Read `docs/research/s139-payload-kept-outside.md` first;
this plan builds on it without repeating it. ADR-0093 is already written (accepted, owner's
decision): the code follows it.

## Story
A modified file of `~/.claude/polype/` that Polype no longer ships moves to
`<root>/polype.kept/<path under polype/>` instead of staying in the payload, where the next run
from the payload re-ships it (#111, root cause `bin/polype:137-145`). A kept copy goes once the
payload ships identical content at that path. `remove --global` moves every modified payload file
out first. #110: the update ghost test checks all three state files. ACs:
`payload_copy_moves_out`, `moved_copy_is_not_shipped`, `kept_copy_removed_once_shipped`,
`existing_kept_copy_never_overwritten`, `remove_leaves_kept_copies`,
`update_test_checks_all_state`, `adr_records_the_kept_payload`.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| payload-path test, kept path | new code, two one-liners in `bin/polype` | the `polype/*` test is inlined in `cmd_remove:748,754`; factoring it is the reuse |
| pre-write "taken" check | new code, shaped on the `.before-polype` check (`bin/polype:221-229`) | that check walks collisions, not dropped payload files; extending it would mix two rules |
| move-out | `mv`, `mkdir -p`, `sum_of` (`:134`) | — |
| "now shipped" sweep | iterate `SHIPPED_LINES` (`:165`), `find -type d -empty -delete` as `prune_empty_dirs` (`:173-175`) | `prune_empty_dirs` keeps its dirs' roots (`prune_mindepth=1`), `polype.kept/` must go too |
| tests | helpers of `tests/drop-keeps-modified.test.sh:7-67` (copied into the new file: test files do not source each other) | — |

## Tasks
1. [x] **Helpers** in `bin/polype`, next to `drop_laid_file` (`:236`):
   - `is_payload_path <dest>`: `mode=global` and `dest` starts with `polype/`.
   - `kept_path <dest>`: `$root/polype.kept/${dest#polype/}`.
   - `move_out_of_payload <dest>`: if `kept_path` is a regular file (not a link) with the same
     `sum_of` → `rm -f "$root/$dest"`, stderr `polype: modified, already kept: <kept path>`;
     else `mkdir -p` its dir, `mv "$root/$dest" <kept path>`, stderr
     `polype: modified, moved out of the payload: $root/$dest -> <kept path>`.
   - `refuse_taken_kept_copies <all|dropped>`: global only, manifest present; for each manifest
     path that `is_payload_path`, is a regular file, `has_drifted`, and (with `dropped`) is not in
     `SHIPPED_LINES`: its kept path is a link, or exists with another sum → stderr
     `polype: <kept path> already exists and differs from $root/<path>; nothing moved, nothing written`.
     Any hit → `exit 1` after listing all.
   - `drop_kept_copies_now_shipped`: global and `$root/polype.kept` a directory; for each shipped
     `polype/*` dest whose kept path is a regular file with the source's sum → `rm`, stderr
     `polype: kept copy now shipped, removed: <kept path>`; then
     `find "$root/polype.kept" -type d -empty -delete` (the root of `polype.kept/` included).
   Test: tasks 5-6.
2. [x] **`drop_laid_file`** (`:238`): first branch — `is_payload_path`, regular file, `has_drifted`
   → `move_out_of_payload`; then, if a `.before-polype` exists, `mv` it back with `put back:`
   (the path is free now); `return 1` (not counted in update's `removed`, as a kept ghost under
   ADR-0092). Other paths keep ADR-0092 unchanged. Update the comment above it (ADR-0093).
   Test: `test_payload_copy_moves_out`, `test_moved_copy_is_not_shipped`.
3. [x] **`cmd_install` and `cmd_update`**: order becomes `collect_shipped; load_checksums;
   refuse_taken_kept_copies dropped; refuse_collisions` (`:598-600`, `:639-641`) — the check
   precedes `refuse_collisions`, whose `--set-aside` branch writes (`:230-233`). Call
   `drop_kept_copies_now_shipped` after each lay-down loop, before `prune_empty_dirs`.
   Test: `test_existing_kept_copy_never_overwritten`, `test_kept_copy_removed_once_shipped`.
4. [x] **`cmd_remove`** (`:741-779`): `refuse_taken_kept_copies all` right after `load_checksums`.
   Merge the two global `polype/*` branches: modified regular file → `move_out_of_payload`; then
   a `.before-polype` → today's `held` path (`rm -f`, hold, put back after `rm -rf`), else
   `rm -f`. After `rm -rf "$state_dir"`: if `$root/polype.kept` is a directory, stderr
   `polype: kept copies left in $root/polype.kept`. Project mode untouched.
   Test: `test_remove_leaves_kept_copies`.
5. [x] **`tests/payload-kept-outside.test.sh`** (new; header comment `# s139 — …`; sandbox HOME
   and `CLAUDE_CONFIG_DIR` under `$SCRATCH` with a guard, as `drop-keeps-modified.test.sh:7-20`).
   Scenario base: copy of the method (`copy_of_the_method`), `install --global` from it, edit
   `$H/polype/method/commands/po-help.md`, delete it from the copy.
   - `test_payload_copy_moves_out`: `install --global` from the copy → kept copy equals the edited
     bytes (`cmp`), no file at the payload path, path absent from `polype/manifest` and
     `polype/checksums`, the exact `moved out of the payload: <old> -> <new>` line. Same through
     `update --global` (ghost path), with `0 removed` on the last line.
   - `test_moved_copy_is_not_shipped`: then `$H/polype/bin/polype update --global` → no
     `$H/commands/po-help.md`, no payload file, manifest without `po-help`.
   - `test_kept_copy_removed_once_shipped`: before `install --global` (repo method), create in
     `$H/polype.kept/` one copy identical to a shipped file alone in a nested dir (e.g.
     `method/skills/<skill>/SKILL.md`) and one differing copy → first gone with its line, its dirs
     gone; second kept, no line for it. Second case: only an identical copy → no `polype.kept/`.
   - `test_existing_kept_copy_never_overwritten`: kept path pre-filled with other content;
     `snapshot "$H"`; `install --global` → exit 1, snapshot unchanged, output names both paths;
     same with `update --global`; same with `install --global --set-aside` while a collision is
     also pending (a new file added to the copy's `method/agents/` and a person's file at
     `$H/agents/<it>`), snapshot unchanged. Then kept path set to the edited bytes → run passes,
     payload file gone, `modified, already kept: <kept path>`.
   - `test_remove_leaves_kept_copies`: `install --global`, edit `polype/method/AGENTS.md` (still
     shipped), `remove --global` → no `$H/polype`, `polype.kept/method/AGENTS.md` equals the edit,
     `moved out of the payload` and `kept copies left in $H/polype.kept` lines. Taken case: kept
     path pre-filled differently → exit 1, snapshot unchanged. Set-aside case: person's file at
     `$H/polype/method/AGENTS.md`, `install --global --set-aside`, edit, `remove --global` → kept
     copy holds the edit, `$H/polype/method/AGENTS.md` holds the person's file, no
     `.polype-restore.*` left.
   - `test_adr_records_the_kept_payload`: exactly one `ADR-0093-*.md`, `status: accepted`,
     `supersedes: [ADR-0092]`, says `polype.kept`, `perdue pour de bon`, `rien n'en signale la fin`;
     ADR-0092 `superseded-by: [ADR-0093]` and still `status: accepted`; `installation.md` says
     `polype.kept`, `ADR-0093`, `moved out of the payload`, and no longer `emporte la charge utile`.
6. [x] **`tests/drop-keeps-modified.test.sh`**: `test_update_ghost_keeps_a_modified_copy` replaces
   its two `not_listed` lines (`:105-106`) by `out_of_the_state "$P" "$X"` (#110); add
   `test_update_test_checks_all_state` reading that test's body (`awk`, as
   `tests/update-keeps-mode.test.sh:160-168`): it calls `out_of_the_state`. Leave the other tests
   as they are (their global `remove` assertions still hold).
7. [x] **ADR-0092 frontmatter**: `superseded-by: [ADR-0093]` only; status and body unchanged.
   **`docs/installation.md`**: in `### Une copie modifiée que Polype ne pose plus`, add a paragraph
   for the payload (move to `~/.claude/polype.kept/`, the three lines, the stop on a taken copy,
   the sweep once shipped, ADR-0093) and delete the sentence of `:323-324`; keep the first limit.
   In `## Ce que remove garde` (`:377`), say `remove --global` first moves modified payload files
   to `polype.kept/`, which it leaves with its line. Prose lines ≤ 100 characters.
   Test: `test_adr_records_the_kept_payload`, `test_installer_and_docs_agree_installation_doc`.
8. [x] **Full suite** through `po-run --story s139-payload-kept-outside --label test -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- `.claude/`, `.polype/`, `method/` end with an empty diff; no file outside `Owns` plus the two
  story docs and `docs/verif/s139-payload-kept-outside.md`.
- `recorded_mode` keeps its name; `shipped_pairs` and `refuse_collisions` bodies unchanged.
- Project mode and global active copies (`commands/`, `agents/`, `skills/`): same lines and
  behaviour as before (`modified, kept:`); the existing tests of `drop-keeps-modified`,
  `install-collisions`, `global-install` pass unmodified except the #110 change.
- No write before `refuse_taken_kept_copies` returns: in install/update it runs before
  `refuse_collisions`; in remove before the manifest loop.
- A kept copy is never overwritten: no `mv -f`/`cp` onto an existing kept path.
- ADR-0092 body and status untouched; ADR-0093 not rewritten beyond wording fixes the code forces.
- `docs/installation.md` keeps every phrase the tests listed in the story notes.

## The pivot
The fix moves the file out of `$base/method` so `find` (`bin/polype:143`) can no longer see it,
instead of filtering `shipped_pairs`. Ways it could be wrong:
- A run from the payload still re-ships: check `test_moved_copy_is_not_shipped` runs
  `$H/polype/bin/polype`, not the repo script.
- The taken check runs after a write (`--set-aside` mv, `mkdir -p "$root"`, a move-out): compare
  its call site with `:599-601` and `:640`; the `--set-aside` snapshot case of task 5 bites.
- `drop_laid_file`'s new branch leaks to active copies or projects: `is_payload_path` must test
  `mode=global` too; `test_init_keeps_a_modified_copy` and `test_update_ghost_…` still say
  `modified, kept:`.

## Files touched
`bin/polype`, `tests/payload-kept-outside.test.sh` (new), `tests/drop-keeps-modified.test.sh`,
`docs/installation.md`, `docs/decisions/ADR-0092-…md` (frontmatter), ADR-0093 (already written),
plus `docs/research/`, `docs/plans/`, `docs/verif/` of the story.

## Test strategy
Integration tests of the installer in a throwaway home, the layer where these rules live (the
installer is the unit). Seven tests, within `Test budget: 25`: six in the new file, one meta test
in `drop-keeps-modified.test.sh`, plus one changed assertion there. Each names its rule: neutralize
the move-out → `payload_copy_moves_out` and `moved_copy_is_not_shipped` fail; the sweep →
`kept_copy_removed_once_shipped`; the taken check or its placement → `existing_kept_copy_…`; the
remove branch → `remove_leaves_kept_copies`. Task tests run per file
(`bash tests/run.sh payload-kept-outside.test.sh drop-keeps-modified.test.sh`); the full suite
once, at the end (task 8). No visual check.

## Done when
All ACs hold, the full suite is green through `po-run`, one commit on the story branch with this
plan, the research and ADR-0093, and a review with no open critical finding.
