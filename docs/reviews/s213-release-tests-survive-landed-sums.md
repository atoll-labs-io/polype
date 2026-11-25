# Review — s213-release-tests-survive-landed-sums

[Story](../stories.md) · [Plan](../plans/s213-release-tests-survive-landed-sums.md) · [Verification](../verif/s213-release-tests-survive-landed-sums.md)

Method version: 0.11.0
Recorded: 2026-11-25T20:34:20+01:00

Diff reviewed: `git diff main...story/s213-release-tests-survive-landed-sums`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: f618f4a1f68848b4a0804648a8b16aac1b2b6ffc

## When blocked
- Failure cause: not blocked
- Missing: nothing
- Required adaptation: none
- Next action: /po-ship s213-release-tests-survive-landed-sums

## Ownership
Diff listed with `git diff --name-only main...story/s213-release-tests-survive-landed-sums`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`. The three changed test files and the new oracle `tests/release-tests-survive-landed-sums.oracle.test.sh` are each a file entry of `docs/stories.md:3471`. That line comes from the story branch, which sits on 7a28ef6, the current `main` (merge-base checked). `docs/plans/<id>.md` and `docs/verif/<id>.md` are the story's own evidence. The `Owns` entry `tests/release-tests-survive-landed-sums.test.sh` was never created, as the plan's run interdict requires.
- [x] Outside `Owns` → none
- [x] Inside another running story's `Owns` → none
- [x] The story has an `Owns` line

## Evidence reused
- [x] `po-gate verif-current s213-release-tests-survive-landed-sums` → exit 0. I reused the record: `bash tests/run.sh` exited 0 on code equal to `Tree:` outside `docs/`. The project has no type check (`Typecheck: —`).
- [x] `po-gate qa-current` → not required: `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1 to 3 are done: the same four lines (one comment, one `sed -i`, one emptiness check) come right after the `cp -R "$ROOT/bin" …` of each `copy_of_polype`. Task 4: the record's `## Oracle changes` has a row for s189's and s171's oracles. Task 5: the record says it checked 22 passed / 0 failed on af2c324. Nothing in the diff is outside the plan.
- [x] Run interdicts, one by one:
  - (1) The diff never touches `bin/`, `po/`, `method/`, `.github/`, `tests/lib.sh`, `tests/run.sh` or `tests/po-prebuilt-and-verified.test.sh`.
  - (2) Only the `copy_of_polype` functions change. No `test_` function is removed, renamed or edited.
  - (3) `oracle-intact` exits 0, and no `tests/release-tests-survive-landed-sums.test.sh` exists.
  - (4) Nothing was pushed to or checked out from the framing branch. The record's own checks used an archive.
  - (5) `docs/parite-killer-saas.md` is untouched.

## References
- [x] Every reference checked out:
  - `fail`, `scratch_repo` and `require_file` exist in `tests/lib.sh`, and `ROOT` resolves to the copy in the nested runs.
  - The `PO_SUMS='` / `'` block shape matches `bin/polype:34-35`.
  - The sums reader in `bin/po-release:50` is the same `awk` as the fixture's emptiness check.
  - `bin/po-release:29-57` is the `--tag` guard the oracle drives, and the `held the sums of` message is at :52.
- [x] Values: the `sed` range deletes only the lines strictly between the opener and the first closing `'`. On `main`, where the block is empty, it is a no-op, so the fixtures behave exactly as before there. The three platforms in `set_sums` match those PR #520 adds. `sed -i` is GNU, but CI runs on `ubuntu-latest` and these files already used it.

## Rules
- [x] `AGENTS.local.md` conventions are respected: tests copied, not sourced, as the files' headers say; one oracle file; the comment explains why; English.
- [x] No accepted ADR is contradicted. The story forbids touching `bin/po-release` (ADR-0121 guard kept), and the diff does not.

## Tests
- Oracle: `po-gate oracle-intact s213-release-tests-survive-landed-sums` → exit 0
- [x] Floor: `po-gate floor-guard s213-release-tests-survive-landed-sums main` → 0, nothing lowered.
- [x] Oracle: `po-gate oracle-intact` → 0. Both changes to earlier stories' oracles (s189, s171) are listed in `## Oracle changes`, and I judged them. They put back the "not yet summed" state the fixtures were written for: `first-release-holds.oracle.test.sh:87`, `first-release-holds.test.sh:53`. No criterion is weakened, because the tests that need sums still write their own.
- [x] The assertions pin both criteria, and none of the six empty test shapes appears. Test 1 runs every real `test_` function of the three files against a copy whose `PO_SUMS` holds the version's sums, and requires that the seven named tests still exist. Test 2 drives the real `bin/po-release`.
- [x] Budget: 2 new tests, within 25.
- [x] Bite 1: in `tests/first-release-holds.test.sh` I replaced the `sed` and its emptiness check with `true`. 1 test failed (`release_tests_hold_with_landed_sums`, with 4 nested failures named). Undone, and `git diff --exit-code` was clean.
- [x] Bite 2: I turned the `refuse` at `bin/po-release:52` into an `echo`. 4 tests failed: `release_still_refuses_a_summed_version`, `release_tests_hold_with_landed_sums`, `rerun_refused_after_later_sums_replace_them` and `rerun_refused_once_sums_landed`. Undone, and `git diff --exit-code` plus `git status --short` were clean.
- [x] No test became useless.

## Neighbours
- [x] Each file has its own `copy_of_polype`, and there are no outside callers. Several other suites copy `bin/`, so I ran the whole suite on PR #520's tree. In a throwaway clone (`file://`, under the temp dir), I checked out af2c324 and applied the story's diff: `bash tests/run.sh` gave 708 passed, 0 failed, 0 skipped. That proves the story unblocks PR #520.

## Lenses
Lenses run: none. Only `tests/` and `docs/` change, so no security, migration, dependency or performance trigger applies.
- [x] No lens findings

## Findings
- none

## Not verified
- CI on the forge: the suite ran locally on PR #520's tree (708/0) and on `main`'s tree through the record, but not on GitHub's `ubuntu-latest` runner. A person should check that PR #520's checks go green once this story lands.
- A po-bounds refusal: `git archive` from the story worktree was refused in reviewer mode, so I did not repeat the record's archive-based check that way. I used the throwaway `file://` clone under the temp dir that the reviewer contract prescribes, and reached a stronger result (the full suite rather than five files).
- Behaviour on macOS or BSD `sed`: not run. The project's CI is Linux only.

Max severity: none
Ship allowed: yes
