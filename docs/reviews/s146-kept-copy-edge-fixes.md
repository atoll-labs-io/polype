# Review — s146-kept-copy-edge-fixes

[Story](../stories.md) · [Plan](../plans/s146-kept-copy-edge-fixes.md) · [Verification](../verif/s146-kept-copy-edge-fixes.md)

Diff reviewed: `git diff main...story/s146-kept-copy-edge-fixes`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 568ccc4f618478e6d37d74943c01f121eb18529a

## Ownership
I listed the diff with `git diff --name-status main...story/s146-kept-copy-edge-fixes`: `M bin/polype`, `M tests/payload-kept-outside.test.sh`, plus `A` for `docs/plans/`, `docs/research/` and `docs/verif/s146-kept-copy-edge-fixes.md`.
- [x] Every path is inside `Owns` (`bin/polype`, `tests/payload-kept-outside.test.sh`). The three docs files are this story's own pipeline evidence.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s146-kept-copy-edge-fixes` exits 0, so I reused the record. Its `Unit suite` row (`bash tests/run.sh`) exited 0 on code equal to the record `Tree:`. The project has no `Typecheck`, E2E or Build command (all `—`). The record's "Not proven here" only says that no E2E or build exists.
- [x] `po-gate qa-current`: not required. With `QA stage: —`, no story goes to QA.

## Plan
- [x] All five tasks are present, and nothing in the diff falls outside the plan:
  - Task 1: `[ ! -L ]` added in `refuse_taken_kept_copies`.
  - Task 2: new `kept_blocking_parent` helper, plus a parent stop with `taken=yes`.
  - Task 3: `mkdir -p`/`mv` checked in `move_out_of_payload`, with `exit 1` on failure.
  - Task 4: three tests.
  - Task 5: the full suite run through `po-run`.
- [x] I checked each run interdict:
  - The stat lists only the five planned files.
  - `docs/installation.md`, `.claude/` and `.polype/` have no diff.
  - The existing tests in `payload-kept-outside.test.sh` are untouched (the diff only adds lines). The leaf message of `refuse_taken_kept_copies` is unchanged byte for byte.
  - The bodies of `drop_laid_file`, `drop_kept_copies_now_shipped`, `refuse_foreign_payload_files` and `cmd_remove` are unchanged.
  - Nothing touches `.before-polype` or #115. No ADR was added.
  - Every test run goes through `guard_home`.

## References
- [x] I opened every reference and confirmed each one:
  - `kept_path` (`bin/polype:366`) and `sum_of`, `has_drifted`, `is_payload_path` (`:267`).
  - The callers of `move_out_of_payload`: `drop_laid_file` at `:448` (reached under `|| true` at `:824` and as an `&&` condition at `:876`, so `set -e` is off there and the explicit `exit 1` is what stops the run), and `cmd_remove` at `:990`.
  - `drop_kept_copies_now_shipped` (`:839`, `:899`).
  - The test helpers `home_in`, `run`, `ok`, `says`, `never_says`, `snapshot`, `edited_payload_file_dropped`.
- [x] No value only looks right:
  - The `kept_blocking_parent` walk always reaches `$root/polype.kept` textually, because `kept_path` prefixes it, and it stops there. I checked root values with a trailing slash or `//`.
  - The degenerate path `polype/`, which could make the walk climb forever, is filtered out earlier by `[ -f "$root/$path" ]`.
  - `{ -e || -L } && ! -d` covers a dangling symlink, as the research's trap asked.
  - Exit code 1 matches the other stops.

## Rules
- [x] `AGENTS.md` and `AGENTS.local.md` conventions are respected: bash tests, one `test_<AC name>` per criterion, English comments, and no installed copy edited.
- [x] No accepted ADR is contradicted. ADR-0093 (moving payload edits to `polype.kept/`) is upheld more strictly.

## Tests
- [x] Floor: `po-gate floor-guard s146-kept-copy-edge-fixes main` exits 0, so nothing was lowered.
- [x] The assertions pin down each acceptance criterion: exit status, an unchanged home snapshot, the parent named, the false "moved out" line never printed, the payload file and its manifest line still in place. None of the six empty test shapes appears: the tests are black-box runs of `bin/polype` in a throwaway home, with no mocks.
- [x] 3 tests added, within `Test budget` 25.
- [x] Bite — I disabled four rules one at a time and ran only `bash tests/run.sh payload-kept-outside.test.sh`. Each change was undone with `git checkout -- bin/polype`, and `git diff --exit-code bin/polype` came back clean:
  - Removing the `drop_kept_copies_now_shipped` call in `cmd_update` (`bin/polype:899`): 1 failing test (`update_sweeps_shipped_kept_copy`).
  - Removing `[ ! -L "$root/$path" ]` in `refuse_taken_kept_copies`: 1 failing test (`symlink_payload_path_not_refused`).
  - Turning off the `kept_blocking_parent` stop (`if false && …`): 1 failing test (`failed_move_is_not_reported_as_done`).
  - Making the `mkdir`/`mv` check in `move_out_of_payload` always succeed (`|| true`): 1 failing test (`failed_move_is_not_reported_as_done`, the read-only case).
- [x] No test is made useless by the story.

## Neighbours
- [x] I read the other callers. `kept_blocking_parent` has one caller. Both call sites of `move_out_of_payload` are fine:
  - In install and update, the new `exit 1` fires during the drop phase, before `$manifest.next`, the sums or `payload.sums` are written. The old manifest therefore still lists the file left in place, and test (c) asserts this.
  - In remove, the old code already ended the run there: `set -e` is active at `:990`. Only the message is new.

## Lenses
Lenses run: none. `bin/polype` is a local installer script, not a route, handler, migration or lockfile, and the diff has no lens content trigger.
- [x] No lens finding.

## Findings
- none

## Not verified
- **Running as root**: the read-only-parent branch of `test_failed_move_is_not_reported_as_done` is skipped when `id -u` is 0, because `chmod` does not deny writes to root. A person running the suite as root should know the backstop of task 3 goes unexercised there.
- **Old problem in `cmd_remove`, outside this diff**: if `move_out_of_payload` fails after an earlier payload path had its `.before-polype` moved into `$root/.polype-restore.$$`, the run exits and leaves that file stranded in the restore directory, with no message. This was already true before the story (`set -e` ended the run at the same point). The new message says "nothing more written", which is accurate. Neither the plan nor the tests check this. Suggest filing an issue in `Issue tracker`.
- **Symlink parents**: a parent of `polype.kept/<path>` that is a symlink to a directory passes the parent check (`-d` follows it). The research leaves this accepted on purpose, and I did not test it.
- **Documentation**: `docs/installation.md` does not describe the new stops ("<parent> is not a directory …" and "could not move …"). It is outside `Owns` and frozen by other tests, so I did not judge it. A later story owning that file should document them.
- **Other platforms**: no E2E or build exists in this project, and I did not run the installer on any platform other than this Linux host.

Max severity: none
Ship allowed: yes
