# Review — s219-suite-bounds-and-cleans

[Story](../stories.md) · [Plan](../plans/s219-suite-bounds-and-cleans.md) · [Verification](../verif/s219-suite-bounds-and-cleans.md)

Method version: 0.13.0
Recorded: 2026-11-28T12:32:44+01:00

Diff reviewed: `git diff main...story/s219-suite-bounds-and-cleans`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 471c66d299d7743c282d05f92cc9571afc3d036d

## When blocked
- Failure cause: —
- Missing: —
- Required adaptation: —
- Next action: —

## Ownership
I listed the diff with `git diff --name-only main...story/s219-suite-bounds-and-cleans` and held each path against the story's `Owns` using the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`. The four test files plus `tests/lib.sh` are each named in `Owns`. `docs/plans/s219-…md` and `docs/verif/s219-…md` are the story's own evidence, so they are in scope by construction.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. The only other running worktree is s218-next-sees-a-human-merge, which owns `po/`, `bin/polype`, `method/commands/po-drive.md`, its own test files and `tests/fixtures/driver-cases/`. None of these overlap this diff.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s219-suite-bounds-and-cleans` exited 0, so I reused the record: the unit suite `bash tests/run.sh` exited 0 on this code. The project has no type check (`Typecheck: —`). The record's "Not proven here" section says real load on a CI runner is only simulated by `po` doubles. I read it.
- [x] `po-gate qa-current`: not required. With `QA stage: —`, the story does not go to QA.

## Plan
- [x] Tasks 1–6 are all present, and nothing falls outside the plan. `tests/state-as-json.test.sh` is unchanged, as the plan announced.
- [x] I checked each run interdict:
  - `po/`, `method/`, `bin/` and `tests/run.sh` have an empty diff.
  - The oracle sum is still `3460862033 3918`; I recomputed it with `cksum`.
  - No retry, rerun loop or added `sleep` in tests or helpers. The only `sleep` is inside the oracle's `po` double, which the plan describes.
  - The thresholds stay at 1000 ms CPU and a 10 s cap, with no CI-only switch.
  - No test file outside `Owns` was edited.
  - `tests/suite-bounds-and-cleans.test.sh` was not created.

## References
- [x] I confirmed every helper the new code calls: `fail` (`tests/lib.sh:12`), `$PO` (`tests/lib.sh:7`, overridable through `PO="${PO:-…}"` in `state-as-json.oracle.test.sh:5` and `driver-next-action.oracle.test.sh:7`), `one_object`, `need_po`, `oracle_helpers` and `next_shape`. `po_bounded` sets `OUT` and `STATUS` the same way the three files' `po_in` does (stderr dropped, never runs in a subshell).
- [ ] One value only looks right: the scratch trap assumes `mktemp` paths never contain a blank (see Findings).

## Rules
- [x] `AGENTS.md` conventions are respected: comments in English, tests in bash, oracle in `*.oracle.test.sh`.
- [x] No accepted ADR is contradicted. The CPU-time method continues s215's.

## Tests
- Oracle: `po-gate oracle-intact s219-suite-bounds-and-cleans` → exit 0
- [x] Oracle: `po-gate oracle-intact` exited 0, and `## Oracle changes` is empty.
- [x] Floor: `po-gate floor-guard s219-suite-bounds-and-cleans main` exited 0, so nothing was lowered. The change to `state-as-json.oracle.test.sh` is a planned clause change (task 3), not an oracle file of this story.
- [x] The assertions pin the three criteria, and none of the six empty test shapes appears:
  - The load doubles really replace `$PO` inside the target tests, run in their own process the way `run.sh` runs them.
  - The scratch case runs the real `test_framing_next_follows_the_stage`.
- [x] 3 tests against a `Test budget` of 25.
- [x] Bite 1: I raised the CPU bound in `po_bounded` from 1000 to 1000000 ms. `test_bounds_hold_under_load` failed ("passed a po that works more than a second"). Undone; `git diff --exit-code tests/lib.sh` is clean.
- [x] Bite 2: I removed `timeout 10` from `po_bounded`. `test_blocking_state_is_caught` failed after about 60 s, the blocked double's full sleep ("was not caught by the 10 s cap"). Undone; `git diff --exit-code tests/lib.sh` is clean.
- [x] Bite 3: I made `scratch_repo` keep only the last folder (`SCRATCH_DIRS="$SCRATCH"`). `test_suite_leaves_no_scratch` failed and listed 4 folders left behind. Undone; `git diff --exit-code tests/lib.sh` is clean, and `git diff --exit-code` on the whole worktree is clean too.
- [x] The old wall-clock measures were removed rather than kept beside the new helper.

## Neighbours
- [x] I read the callers of `scratch_repo` and the fixtures that set their own `trap … EXIT`. The `fixture`/`project` helpers in `decision-inbox.oracle`, `state-as-json.oracle` and `driver-next-action.oracle` make their own folder and do not call `scratch_repo`, so their behaviour is unchanged.
- `project_at` reassigns `SCRATCH` to its `pwd -P` form after the call. The list still holds the original path, and `rm` resolves it to the same folder.
- The new `trap 'rm -f "$NEXT_MARKER"' EXIT` in `driver-next-action.test.sh` replaces any earlier trap. That test never calls `scratch_repo`, so nothing is lost.

## Lenses
Lenses run: none (the diff touches only bash test files and their helper: no auth or route paths, no migration, no lockfile or manifest, no server-side code).
- [x] No lens findings.

## Findings
- critical — tests/lib.sh:52 — `trap 'rm -rf $SCRATCH_DIRS' EXIT` expands the folder list without quotes, so every path is word-split and glob-expanded inside an `rm -rf`. The code it replaces, `rm -rf "$SCRATCH"`, was safe. This is a regression that silently destroys data outside the scratch area.
  Reproduced in a probe under the temp dir:
  - Setup: `TMPDIR="<probe>/my tmp"` and an unrelated sibling folder `<probe>/my` holding a file.
  - One `scratch_repo` call made `<probe>/my tmp/tmp.XXXX`.
  - On exit, the sibling folder `<probe>/my` and its file were deleted, and the scratch folder itself was left behind.
  - The trap also runs `rm -rf tmp/tmp.XXXX` relative to whatever the current directory is at exit.

  The plan's assumption that "`mktemp` paths hold no blanks" is false whenever `TMPDIR` contains one. A contributor with such a `TMPDIR` can lose an unrelated directory, for example `TMPDIR="/home/u/My Temp"` deletes `/home/u/My` if it exists.
  Keep the list in a bash array and expand it quoted in the trap, or loop over the entries quoting each.
- minor — tests/suite-bounds-and-cleans.oracle.test.sh:39 — Plan task 5 names `test_bounds_hold_under_load` "with no file left in its `TMPDIR`", but `own_test` sets no `TMPDIR` of its own and nothing checks that the `po next` marker is removed after the failing burn run. The `NEXT_MARKER` EXIT trap looks right when read; the oracle just does not test it.

## Not verified
- Real load on a CI runner: the review, like the record, relies on doubles of `po` that wait or burn CPU. To cover it, a person should watch the next few `ci.yml` runs on `ubuntu-latest` for these three tests.
- I did not rerun the full suite. I reused the `po-run` record. I did not repeat the fresh-`TMPDIR` before/after comparison of task 6 on the whole suite, only the oracle's three scratch cases (through bite 3 and its baseline).
- Whether `timeout`'s own process group could interfere with a `po` that reads from a terminal: I did not probe this. Today `po` reads no tty in these calls.
- Files outside `Owns` that re-arm `trap 'rm -rf "$SCRATCH"' EXIT` after more than one `scratch_repo` call would still leak earlier folders. The plan reports none do today, and I did not audit each one.

Max severity: critical
Ship allowed: no

Method version: 0.13.0
Recorded: 2026-11-28T12:52:11+01:00

Diff reviewed: `git diff main...story/s219-suite-bounds-and-cleans`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: bbcc72ad48a62af9f6653a398a28ed98a3a504c0

## When blocked
- Failure cause: —
- Missing: —
- Required adaptation: —
- Next action: —

## Ownership
I listed the diff with `git diff --name-only main...story/s219-suite-bounds-and-cleans` and held each path against the story's `Owns` (`docs/stories.md:3563`) using the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`. `tests/lib.sh`, `tests/decision-inbox.oracle.test.sh`, `tests/driver-next-action.test.sh`, `tests/state-as-json.oracle.test.sh` and `tests/suite-bounds-and-cleans.oracle.test.sh` are each named in `Owns`. `docs/plans/`, `docs/verif/` and `docs/reviews/s219-suite-bounds-and-cleans.md` are the story's own evidence, so they are in scope by construction.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. The only other worktree is s220-po-dependencies-checked. It owns `deny.toml`, `.github/workflows/`, `docs/ci.md`, `docs/decisions/` and its own test files, and none of these overlap this diff.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s219-suite-bounds-and-cleans` → exit 0, so I reused the record. Its last `bash tests/run.sh` run exited 0 on code equal to `Tree:` outside `docs/`. The project has no type check (`Typecheck: —`). I read "Not proven here": the CI load is simulated by `po` doubles, and trap overrides outside `Owns` were not changed.
- [x] `po-gate qa-current`: not required, because the story does not go to QA (`QA stage: —`).

## Plan
- [x] Tasks 1–6 are all present. Fix commit 03d0a48 changes only the trap in `scratch_repo` (a quoted bash array), as the critical finding of fix loop 0 asked. Nothing falls outside the plan, and `tests/state-as-json.test.sh` is unchanged, as the plan announced.
- [x] Run interdicts, checked one by one:
  - `po/`, `method/`, `bin/` and `tests/run.sh` have an empty diff.
  - The oracle sum is still `3460862033 3918`; I recomputed it with `cksum`.
  - No retry, rerun loop or added `sleep` in tests or helpers. The only `sleep` calls are inside the oracle's `po` doubles.
  - Thresholds: 1000 ms of CPU and a 10 s cap, with no switch reserved for CI.
  - No test file outside `Owns` was edited.
  - `tests/suite-bounds-and-cleans.test.sh` was not created.
  - Departure: the plan's task 1 described a space-separated string. The array that replaces it is the fix the previous review asked for, so it is a justified change.

## References
- [x] Every call is confirmed:
  - `fail` (`tests/lib.sh:12`) and `$PO` (`tests/lib.sh:7`, overridable in the oracle helpers).
  - `one_object`, `next_shape`, `oracle_helpers` and `need_po` already exist.
  - `po_bounded` sets `OUT`/`STATUS` the way `po_in` does, outside any subshell.
  - `timeout` is coreutils, and its exit 124 is read as the cap being hit.
- [ ] One value only looks right: `SCRATCH_DIRS` is initialised only when unset, so a value inherited from the environment is kept and later removed (see Findings).

## Rules
- [x] `AGENTS.md` conventions are respected: bash tests, the oracle in `*.oracle.test.sh`, short English comments that say why.
- [x] No accepted ADR is contradicted. The CPU-time method continues s215's.

## Tests
- Oracle: `po-gate oracle-intact s219-suite-bounds-and-cleans` → exit 0
- [x] Oracle: `po-gate oracle-intact s219-suite-bounds-and-cleans` → exit 0, and `## Oracle changes` is empty.
- [x] Floor: `po-gate floor-guard s219-suite-bounds-and-cleans main` → exit 0, so nothing was lowered.
- [x] The assertions pin the three criteria, and none of the six empty shapes appears:
  - The doubles really replace `$PO` inside the target tests, which run in their own process the way `run.sh` runs them.
  - The scratch case runs the real `test_framing_next_follows_the_stage`.
- [x] Oracle run here: `bash tests/run.sh suite-bounds-and-cleans.oracle.test.sh` → 3 passed in 18 s.
- [x] 3 tests against a `Test budget` of 25.
- [x] Bite 1: I set the `scratch_repo` trap back to removing only `"$SCRATCH"`. `test_suite_leaves_no_scratch` failed (1 of 3 failed, 4 folders listed). Undone, and `git diff --exit-code` is clean.
- [x] Bite 2: in `po_bounded`, I replaced `[ "$STATUS" -ne 124 ] ||` with `true ||`. `test_blocking_state_is_caught` failed (1 of 3 failed, "stdout is not one JSON value"). Undone, and `git diff --exit-code` is clean.
- [x] Probe of the fix-loop-0 critical, under the temp dir:
  - Setup: `TMPDIR="<probe>/my tmp"`, a sibling `<probe>/my/keep`, two `scratch_repo` calls, a re-source of `lib.sh`, then a third call.
  - The array held 3 entries, all three scratch folders were removed, and the sibling survived. The critical is lifted.
- [x] Probe of the `NEXT_MARKER` trap: I ran `test_next_on_this_repository_is_fast_and_writes_nothing` with `PO=/bin/false` and its own `TMPDIR`. The test failed, and the `TMPDIR` was empty afterwards.
- [x] The old wall-clock measures were removed rather than kept beside the new helper.

## Neighbours
- [x] Callers of `scratch_repo` and `po_bounded`: `po_bounded` has the three planned callers only.
  - `run.sh` runs each test in its own `bash -c`, so the EXIT trap fires once per test and no array crosses between processes.
  - The new `trap 'rm -f "$NEXT_MARKER"' EXIT` replaces the earlier trap, but that test never calls `scratch_repo`.
  - Files outside `Owns` that re-arm `trap 'rm -rf "$SCRATCH"' EXIT` behave as before.

## Lenses
Lenses run: none (only bash test files and their helper: no auth/route paths, no migration, no lockfile or manifest, no server-side code).
- [x] No lens findings.

## Findings
- minor — tests/lib.sh:48 — `[ -n "${SCRATCH_DIRS+set}" ] || SCRATCH_DIRS=()` keeps a `SCRATCH_DIRS` value inherited from the environment, and `SCRATCH_DIRS+=(...)` then turns it into element 0, which the EXIT trap passes to `rm -rf`.
  Probe under the temp dir: `SCRATCH_DIRS=<probe>/victim bash -c 'source ./lib.sh; scratch_repo'` deleted `<probe>/victim` and its file. Nothing in the suite or CI sets that variable, and bash cannot export an array, so the trigger is only a stray environment variable of that name.
  The fix is to tell "already an array in this process" apart from "anything else": reset unless `declare -p SCRATCH_DIRS` shows `declare -a`.
- minor — tests/suite-bounds-and-cleans.oracle.test.sh:39 — Still open from fix loop 0. Plan task 5 asks for `test_bounds_hold_under_load` "with no file left in its `TMPDIR`", but `own_test` sets no `TMPDIR` of its own, and no assertion checks that the `po next` marker is removed after the failing burn run. The behaviour is right: my probe above saw the marker removed. The oracle just does not pin it.

## Not verified
- Real load on a CI runner: the record and this review rely on `po` doubles that wait or burn CPU. A person should watch the next `ci.yml` runs on `ubuntu-latest` for these three tests.
- I did not rerun the full suite, only the oracle file and the probes; I reused the `po-run` record. I did not repeat the before/after `TMPDIR` comparison of plan task 6 on the whole suite.
- Files outside `Owns` that re-arm `trap 'rm -rf "$SCRATCH"' EXIT` after calling `scratch_repo` several times would still leak the earlier folders. The plan reports that none do today; I did not audit each file.
- A `po` that ignores SIGTERM would outlive `timeout 10`, since there is no `-k`. Today's `po` does not trap TERM; not probed.

Max severity: minor
Ship allowed: yes
