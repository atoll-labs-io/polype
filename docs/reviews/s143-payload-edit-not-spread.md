# Review — s143-payload-edit-not-spread

[Story](../stories.md) · [Plan](../plans/s143-payload-edit-not-spread.md) · [Verification](../verif/s143-payload-edit-not-spread.md)

Diff reviewed: `git diff main...story/s143-payload-edit-not-spread`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: a39397b6e265e756dc8c852840e6fc429e8f7395

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
I listed the diff with `git diff --name-only main...story/s143-payload-edit-not-spread`. It holds `bin/polype`, `docs/installation.md`, `tests/payload-edit-not-spread.test.sh` and the story's own research, plan and verif files.
- [x] Every path is inside `Owns` (`bin/polype`, `docs/installation.md`, `tests/payload-edit-not-spread.test.sh`). The pipeline evidence is in scope by construction.
- [x] No path is outside `Owns`.
- [x] No path is inside another running story's `Owns`.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s143-payload-edit-not-spread` → exit 0, so I reused the record. It has `Tree: 1c6e3f2a…`, and the unit suite `bash tests/run.sh` exited 0 on code equal to that tree outside `docs/`. The project has no type check (`Typecheck: —`), no E2E (`E2E: —`) and no build (`Build: —`). I read the record's "Not proven here" section, and its items are carried below.
- [x] `po-gate qa-current`: not required. `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1–6 are all present: `payload_edit`, `keep_payload_edit`, wiring into `cmd_install` and `cmd_update`, the skips in `refuse_collisions` and `drop_kept_copies_now_shipped`, the four tests, and the docs paragraph. Nothing in the diff falls outside the plan.
- [x] I checked each run interdict:
  - `docs/decisions/` diff is empty.
  - `.claude/` and `.polype/` diffs are empty.
  - `sign_payload`, `cmd_check`, `cmd_remove` and `refuse_foreign_payload_files` are untouched.
  - `recorded_mode` is not renamed.
  - The `cmd_update` modified branch and its message stay word for word.
  - No other test file was created or edited.
  - The stale comment is left alone.

## References
- [x] I opened every reference the new code uses and they all exist with the expected meaning:
  - Variables `from_payload` and `base` (`bin/polype:36-46`) and the arrays `PAYLOAD_SUMS` (`:278-285`, loaded in `collect_shipped` in every mode) and `RECORDED` (`load_checksums`).
  - Functions `sum_of`, `record_sum <sum> <dest>` and `$manifest.next`.
  - The caller-local `modified` / `reported` arrays, which keep the bash dynamic scope.
- [x] Values: the payload key `polype/${src#"$base"/}` matches the `payload.sums` key format used by `shipped_pairs` (`:153`). The message `polype: modified, left as it is:` is the existing `cmd_update` wording. The `${1:-0}` default only applies to callers that pass nothing, and there are none.

## Rules
- [x] `AGENTS.md` conventions are respected: comments in English, the test file is named after the story slug, and the test functions are named after the criteria.
- [x] No accepted ADR is contradicted. The code implements the last bullet of ADR-0095, "Retouche d'un fichier signé (#115)".

## Tests
- [x] Floor: `po-gate floor-guard s143-payload-edit-not-spread main` → 0, nothing lowered.
- [x] The assertions pin down each criterion:
  - The active copy's sum is unchanged.
  - `payload.sums` is byte-identical.
  - The `checksums` line equals the signed line.
  - The edit is reported exactly once.
  - The `left modified` count is checked on both the update and the install last line.
  - The missing project copy is not laid.
  - A project's own copy is left alone.
  - None of the six empty test shapes appears. The tests drive the real CLI from the real payload path (`$H/polype/bin/polype`).
- [x] 4 tests, within `Test budget` (25).
- [x] Bite: I ran only `payload-edit-not-spread.test.sh` after each change, and undid each change with `git checkout -- bin/polype`. After each undo, `git diff --exit-code bin/polype` was clean.
  - `keep_payload_edit` disabled in `cmd_update` (`:866`) → 2 failing (`payload_edit_reported_not_spread`, `check_lists_payload_edit`).
  - `keep_payload_edit` disabled in `cmd_install` (`:815`) → 2 failing (`payload_edit_reported_not_spread`, `init_does_not_take_payload_edit`).
  - `payload_edit` made to ignore `from_payload` (`:289`) → 1 failing (`fresh_source_still_updates`).
  - The collision skip in `refuse_collisions` removed (`:218`) → 1 failing (`init_does_not_take_payload_edit`).
- [x] No existing test was made useless by the story.

## Neighbours
- [x] Other callers read:
  - `cmd_init` → `cmd_install`, so it is covered by the init test.
  - The ghost-drop loops in install and update run before the new code, and the dests they act on are unaffected.
  - `refuse_taken_kept_copies` reads only on-disk dests, never `src`.
  - `drop_laid_file` and `move_out_of_payload` only see dests that are no longer shipped.
  - `grep 'sum_of "$src"\|lay_down'` confirms every other read of `src` content is guarded, or reached only after `keep_payload_edit` returned 1.
- [x] The changed global `done_message` text: no other test or doc quotes the old `(<n> files), payload in` form, and the full suite record is green.

## Lenses
Lenses run: none. The diff is a CLI installer: no auth, routes, migrations, lockfiles or server code.
- [x] No lens findings.

## Findings
- none

## Not verified
- **The active copy keeping its sum from `checksums`.** I did not test the branch where an active copy keeps that sum (`RECORDED[dest]`) instead of the signed sum, which is the post-sync case where the active copy is older than the payload. With a payload installed from a repository both values are equal, so no test can tell them apart. The plan argues this and leaves it untested. To cover it: on a second machine, sync a newer payload, edit one of its files, run `update --global` from the payload, then run `check --global` and confirm the active copy is not listed as hand-edited.
- **The `drop_kept_copies_now_shipped` skip for an edited source** is a one-line guard with no test of its own. I read it but did not exercise it.
- **`install|update <project>` from a payload carrying an edit** has no test of its own. It shares the `cmd_install`/`cmd_update` code path with `init` and `update --global`, which are tested.
- **An edited payload file whose active copy Polype never recorded.** One case is a fresh machine whose payload arrived by chezmoi before any install. The new code lays nothing there and does not add it to the manifest, so that command stays absent until the edit is reverted or a run from a repository happens. This follows the plan's "not claimed" rule, but I did not exercise it. A person should confirm on such a machine that this outcome is acceptable.
- **A real chezmoi sync between two machines**: not exercised, as the verif record also says.
- **Type check, E2E and build**: the project has none (`Typecheck: —`, `E2E: —`, `Build: —`).

Max severity: none
Ship allowed: yes
