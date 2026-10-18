---
validated: yes
---
# Plan — s146-kept-copy-edge-fixes

[Story](../stories.md) · [Research](../research/s146-kept-copy-edge-fixes.md)

Branch `story/s146-kept-copy-edge-fixes`. Read `docs/research/s146-kept-copy-edge-fixes.md` first; this plan builds on it without repeating it.

## Story
Fixes #119, #120, #121 so that `polype.kept/` always tells the truth.
- `update_sweeps_shipped_kept_copy` — `update --global` removes a kept copy identical to what the payload now ships; the test fails when the sweep call in `cmd_update` (`bin/polype:880`) is removed.
- `symlink_payload_path_not_refused` — a payload path that is a symlink does not stop the command over a kept copy it would never move: `refuse_taken_kept_copies` applies the `[ ! -L … ]` of `drop_laid_file`.
- `failed_move_is_not_reported_as_done` — a regular file as parent of `polype.kept/<path>` stops the command before any write, naming that parent; "moved out of the payload" is never printed for a file left in place.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| `[ ! -L "$root/$path" ]` at `bin/polype:394` | already in this repository: the same test at `bin/polype:428` and `:970` | — (first rung holds; the story asks for that exact test) |
| Parent check in `refuse_taken_kept_copies` | already in this repository for its shape: the `taken=yes` / `[ "$taken" = no ] \|\| exit 1` stop of `bin/polype:396-403`; the walk itself is new code, a few lines of `dirname` | no existing helper walks the parents of a kept path; `mkdir -p` (platform) is the very call that fails silently, so it cannot be the check |
| Checked `mkdir -p`/`mv` in `move_out_of_payload` | the platform: their own exit status | nothing to reuse above; this is error handling that keeps a false report from hiding a file left behind, which the ladder never cuts |
| Three tests | already in this repository: `home_in`, `ok`, `run`, `says`, `never_says`, `not_listed`, `snapshot`, `edited_payload_file_dropped` (`tests/payload-kept-outside.test.sh:8-63`) | — |

No new option, setting or message family: the new stop reuses the "…; nothing moved, nothing written" wording of `bin/polype:399`.

## Tasks
1. [x] **#120** — in `refuse_taken_kept_copies`, line `bin/polype:394`, add `[ ! -L "$root/$path" ]` after `[ -f "$root/$path" ]`. Nothing else in the function changes for this task.
   Test that fails if wrong: `test_symlink_payload_path_not_refused`.
2. [x] **#121, parent** — in `refuse_taken_kept_copies` (`bin/polype:386-404`), before the leaf test of `:397`, find the first ancestor of `$kept` from `dirname "$kept"` up to and including `$root/polype.kept` that exists or is a symlink but is not a directory (`{ [ -e "$d" ] || [ -L "$d" ]; } && [ ! -d "$d" ]`). When one is found: print `polype: <parent> is not a directory, so $root/$path cannot move to $kept; nothing moved, nothing written` to stderr, set `taken=yes`, skip the leaf test for that path. A small helper next to `kept_path` (`:366`) or an inline loop — implementer's choice; declare its variables `local`. The check sits inside the existing loop, so it concerns only payload paths that would really move (regular, not a symlink, drifted, and for `dropped` not shipped now).
   Test that fails if wrong: `test_failed_move_is_not_reported_as_done` (first home).
3. [x] **#121, the report** — in `move_out_of_payload` (`bin/polype:379-381`), print "moved out of the payload" only when `mkdir -p "$(dirname "$kept")"` and `mv "$root/$dest" "$kept"` both succeeded. On failure, print `polype: could not move $root/$dest to $kept; it stays in the payload, nothing more written` to stderr and `exit 1`. Use an `if … && …; then … else … fi`, since the function runs where `set -e` is off (`:805`, `:857`). The "already kept" branch (`:374-378`) stays as it is.
   Test that fails if wrong: `test_failed_move_is_not_reported_as_done` (read-only home).
4. [x] **Tests** — add to `tests/payload-kept-outside.test.sh`, after `test_kept_copy_removed_once_shipped`:
   - `test_update_sweeps_shipped_kept_copy`: `home_in home`; `ok install --global` (from `$ROOT`); then copy `$ROOT/method/skills/diagnostic/SKILL.md` to `$H/polype.kept/method/skills/diagnostic/SKILL.md`; `ok update --global`; the copy is gone, `$H/polype.kept` is gone, output says `polype: kept copy now shipped, removed: <path>`. The install must come first: `update` with no manifest runs `cmd_install` (`bin/polype:842`) and would test install again.
   - `test_symlink_payload_path_not_refused`: `home_in home`; `ok install --global`; replace `$H/polype/method/AGENTS.md` by a symlink to a scratch file holding the shipped content plus a line; write `another edit` to `$H/polype.kept/method/AGENTS.md`; `ok remove --global`; the kept copy still reads `another edit`; output never says `already exists and differs`. Then a second home through `edited_payload_file_dropped`, `$PAY` swapped for a symlink to a drifted scratch copy, a different `$KEPT` written: `ok install --global`, `$KEPT` unchanged.
   - `test_failed_move_is_not_reported_as_done`: (a) `edited_payload_file_dropped home`; `printf x > "$H/polype.kept"`; for each of `install --global`, `update --global`, `remove --global`: exit 1, `snapshot "$H"` unchanged, output says `$H/polype.kept is not a directory`, never says `moved out of the payload`. (b) a second home, `polype.kept/method` a regular file (`polype.kept` a directory): `install --global` exits 1 naming `$H/polype.kept/method`. (c) only when `[ "$(id -u)" -ne 0 ]`: a third home, `mkdir -p "$H/polype.kept/method"; chmod 555` it; `run install --global`; `chmod 755` it back if it still exists; status not 0, never says `moved out of the payload`, `$PAY` still holds `$EDITED`, the manifest still lists `polype/method/commands/po-help.md`.
   Run: `bash tests/run.sh payload-kept-outside.test.sh`.
5. [x] **Full suite and record** — `po-run --story s146-kept-copy-edge-fixes --label test -- 'bash tests/run.sh'`. No type check (`Typecheck: —`).

## Scene viewpoints
—

## Run interdicts
- `git diff main...story/s146-kept-copy-edge-fixes --stat` lists only `bin/polype`, `tests/payload-kept-outside.test.sh`, `docs/research/s146-kept-copy-edge-fixes.md`, `docs/plans/s146-kept-copy-edge-fixes.md`, `docs/verif/s146-kept-copy-edge-fixes.md`.
- `docs/installation.md` empty diff: it is frozen by tests outside `Owns`.
- `.claude/` and `.polype/` empty diff (installed copies).
- The existing tests of `tests/payload-kept-outside.test.sh` are not edited; `test_existing_kept_copy_never_overwritten` passes with the leaf message of `bin/polype:399` byte for byte.
- `drop_laid_file`, `drop_kept_copies_now_shipped`, `refuse_foreign_payload_files`, `cmd_remove` bodies unchanged except through the two functions edited above.
- No change to the `.before-polype` put-back (s139 major finding) nor to the payload-edit spreading (#115): out of scope.
- No new ADR; ADR-0097 stays unused.
- No test writes outside `$SCRATCH` (`guard_home` stays the gate of every run).

## The pivot
The parent check in `refuse_taken_kept_copies` is the fix of #121; the checked `mkdir`/`mv` is the backstop for what it cannot see. It could be wrong three ways:
- **It refuses too much.** A non-directory parent of a kept path whose payload file would never move (not drifted, a symlink, or still shipped under `dropped`) must not stop the run. Compare: the check lives after the `continue` of `:394-395`, inside the same loop.
- **It misses a parent.** The walk must include `$root/polype.kept` itself and stop there, never climbing to `$root`; a dangling symlink has `-e` false. Compare: test (a) uses `polype.kept` itself, test (b) an inner parent.
- **The backstop exits mid-run and loses something.** `exit 1` from the drop phase leaves the manifest, sums and `payload.sums` untouched; files dropped before it are relaid as missing by the next run, and the payload file stays where it was, still signed. Compare: test (c) asserts the payload file and its manifest line remain.

## Files touched
- `bin/polype`
- `tests/payload-kept-outside.test.sh`
- `docs/research/s146-kept-copy-edge-fixes.md`, `docs/plans/s146-kept-copy-edge-fixes.md`, `docs/verif/s146-kept-copy-edge-fixes.md`

## Test strategy
Three tests, budget 25. All at the installer's own layer (black-box runs of `bin/polype` in a throwaway home), the only layer this repository has for it.
- `test_update_sweeps_shipped_kept_copy` — bites when `bin/polype:880` is removed.
- `test_symlink_payload_path_not_refused` — bites when the `[ ! -L ]` of task 1 is removed (remove and install both stop).
- `test_failed_move_is_not_reported_as_done` — (a)/(b) bite when the parent check of task 2 is removed (the run goes on, writes, prints the false line); (c) bites when task 3's check is removed (the false line comes back). (c) skips as root, where `chmod` does not deny writes.
Visual checks: none (`Surface: command`).

## Done when
- The three tests pass, the full suite passes through `po-run`, the record is complete.
- One commit on `story/s146-kept-copy-edge-fixes` with the code, the tests, the research, the plan and the record.
- A review with no open critical finding; shipped as one commit on `main` through a pull request, closing #119, #120, #121.
