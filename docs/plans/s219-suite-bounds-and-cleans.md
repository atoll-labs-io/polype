---
track: flow
validated: yes
---
# Plan (short track) — s219-suite-bounds-and-cleans

[Story](../stories.md)

Written by the planner. On the short track this one file stands in for both the research and the plan: there is no `docs/research/s219-suite-bounds-and-cleans.md`. Validated autonomously (`Plan validation: autonomous`): no human reviewed it.

## Verified facts
No assumption of the story proved false. One line number drifted: the inbox bound fails at `tests/decision-inbox.oracle.test.sh:174`, not `:176`.

**The two wall-clock bounds left.**
- `test_list_prints_pending_oldest_first` (`tests/decision-inbox.oracle.test.sh:156`) times `po inbox` with `date +%s%N` (`:165-167`), once in `$F` and once in `$W`, and fails at 1000 ms (`:174`). It runs `po` through the file's own `po_in` (`:14`), and `$PO` comes from `tests/lib.sh:7`.
- `test_next_on_this_repository_is_fast_and_writes_nothing` (`tests/driver-next-action.test.sh:77`) times `po next` on `$ROOT` the same way (`:82-84`) and fails at 1000 ms (`:94`). It loads the oracle's helpers inside the test (`:6`). That file sets `PO="${PO:-…}"` (`tests/driver-next-action.oracle.test.sh:7`), so a `PO` set beforehand survives.
- The same test makes `marker="$(mktemp)"` (`:80`) and removes it only at `:97`. A failure before that point, a bound included, leaves that file behind. It was seen: with a double that burns CPU, the run leaves one empty `tmp.*` file.

**The s215 method and what it does not see.**
- s215 (a56a6d1) swapped wall time for CPU time in `test_state_reads_only_files_and_git` (`tests/state-as-json.oracle.test.sh:189-195`). It reads `time` with `TIMEFORMAT='%3U %3S'`, keeps only the digits (the locale prints `0,029`), and fails at 1000 ms with the words `not under a second` (`:195`). The s215 oracle greps those words (`tests/suite-holds-under-load.oracle.test.sh:102`), so they stay.
- A `po state` that sleeps spends no CPU, so this bound lets it through. It would hang the suite if it never returned. Hence criterion 2, a loose real-time cap of 10 s (owner's decision of 2026-11-26).
- `timeout` from coreutils is on this machine (`/usr/bin/timeout`) and on the CI runner. The suite runs only in `.github/workflows/ci.yml:13`, on `ubuntu-latest`; `release.yml` does not run `tests/`. When the limit is hit, `timeout` exits 124 and signals its whole process group. Checked: `o="$(timeout 2 bash -c 'sleep 30')"` returns after 2002 ms with status 124, so a grandchild that is still asleep does not hold the command substitution open.
- `time { … }` counts the CPU of children that were waited for, grandchildren included. s215 relies on this for the git that `po` runs, and it holds through `timeout`: the burn double below is caught that way.

**The leftover scratch folders (#397).**
- `scratch_repo` (`tests/lib.sh:47-54`) sets `SCRATCH="$(mktemp -d)"` and `trap 'rm -rf "$SCRATCH"' EXIT` (`:49`). The trap reads `$SCRATCH` at exit, so only the last folder is removed: a second call orphans the first.
- `test_framing_next_follows_the_stage` calls `project_at` twice (`tests/state-as-json.test.sh:60`, `:75`), and `project_at` calls `scratch_repo` (`:14`). That is the folder #397 traced, the one with commits `architecture`, `no-screen`, `ds`. Reproduced: three calls in one process leave two folders, and two calls followed by `fail` leave one.
- A file that re-arms `trap … EXIT` after `scratch_repo` overrides the trap of `lib.sh`. Those overrides are in files outside `Owns` (for example `tests/failing-check-files-an-issue.test.sh:12`, `tests/state-carries-session-lines.oracle.test.sh:18`), and each one still names `$SCRATCH`. A full-suite run with its own `TMPDIR` left only the `project_at` folder, so none of these overrides leaks today.
- Each test runs in its own `bash -c` process (`tests/run.sh:39`), so an EXIT trap fires once per test.

**All tasks were tried on a clone outside the worktree.** On that clone the oracle and the 27 tests of the six affected files passed: the three oracle tests, the 2 tests of `suite-holds-under-load`, and those of `state-as-json`, `decision-inbox` and `driver-next-action`. The run left nothing in its `TMPDIR`. On the current code the three oracle tests fail, each for its own reason: `po inbox took 1110 ms`; a blocked `po state` waited out its 60 s, then failed on `stdout is not one JSON value`; folders were left in all three scratch cases.

## Escalation signals
Before reading the code: story text, `docs/stories.md:3557-3572`. After: the files cited above.

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text | absent — bash test files only |
| New screen | absent — `Surface: command` | absent — no UI |
| Authorization or tenant scope | absent — story text | absent — test helpers |
| API contract | absent — "Ne touche ni `po/`, ni `method/`, ni `bin/`" | absent — `po`'s JSON is read, not changed |
| New dependency | absent — story text | absent — bash `time` and coreutils `timeout`, both already on the platform; nothing installed |
| Technical choice that deserves an ADR | absent — the owner set the 10 s cap; s215 set the CPU method | absent — one test helper, no library, pattern or data model |
| Defect to fix (`Fixes` or `Corrige` line) | absent — no `Fixes` line, `docs/stories.md:3557-3572` | absent — #397's cause read and reproduced above anyway |

## Story
As the owner, I want the last tests bounded in real time to hold under load, a block without computation to stay caught, and the suite to leave no folder behind, so that CI reports a defect and a `/tmp` held in memory does not fill up (#532, #536, #397).
- `bounds_hold_under_load`: the inbox and next tests pass under the simulated load of s215 and keep what they prove.
- `blocking_state_is_caught`: a `po state` that blocks without computing fails `test_state_reads_only_files_and_git`, through a loose real-time cap of about 10 s.
- `suite_leaves_no_scratch`: after the suite, no folder made by `scratch_repo` remains, even when a test makes several.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| `po_bounded` in `tests/lib.sh`: CPU under 1 s, wall cap 10 s | already in this repository: s215's CPU measure (`tests/state-as-json.oracle.test.sh:189-195`) moves there and is shared by three tests; the platform's `time` and `timeout` | — no rung above: three copies of the measure would drift |
| The list of scratch folders in `scratch_repo` | already in this repository: the trap at `tests/lib.sh:49`, extended | — |
| Removing the `po next` marker on exit | already in this repository: the `trap … EXIT` pattern of the suite | — |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/suite-bounds-and-cleans.oracle.test.sh` | `3460862033 3918` |

| Criterion | Test |
| --- | --- |
| `bounds_hold_under_load` | `test_bounds_hold_under_load`. Each of the two tests runs in its own process, as `tests/run.sh` does, with a `$PO` double. Where `po inbox` or `po next` wait 1.1 s before running, it must pass. Where every call burns 1.2 s of CPU, it must fail with `not under a second`. |
| `blocking_state_is_caught` | `test_blocking_state_is_caught`. A `po state` run from `$ROOT` does `exec sleep 60`. The test must fail with `did not answer within 10 s`, and the run must end in under 30 s. |
| `suite_leaves_no_scratch` | `test_suite_leaves_no_scratch`. Each case runs with its own `TMPDIR`: three `scratch_repo` calls; two calls, then `fail`; `test_framing_next_follows_the_stage` itself. Each case must leave nothing. |

## Tasks
1. [x] `tests/lib.sh:46-54`: `scratch_repo` adds each folder to a list kept per process, and the trap removes the whole list when the process exits. Two traps: a re-sourced `lib.sh` must not clear the list (`SCRATCH_DIRS="${SCRATCH_DIRS-}"`), and it must work under `set -u`. Keep `$SCRATCH` as the latest folder, since every caller reads it. Tried shape: a space-separated string, `trap 'rm -rf $SCRATCH_DIRS' EXIT` (`mktemp` paths hold no blanks).
   Test: `test_suite_leaves_no_scratch`.
2. [x] `tests/lib.sh`: add `po_bounded <what> <dir> <args...>`. It runs `timeout 10 "$PO" "$@"` in `<dir>`, stderr to `/dev/null`, and sets `OUT` and `STATUS` as `po_in` does. It never runs in a subshell, so `OUT` survives. STATUS 124 → `fail "<what> did not answer within 10 s"`. Then CPU user+sys (s215's `TIMEFORMAT='%3U %3S'`, digits only) of 1000 ms or more → `fail "<what> took N ms of CPU, not under a second"`. Any other non-zero `STATUS` is the caller's to judge. The `time` output goes to a `mktemp` file, removed before any `fail`. One short comment says why CPU time and why the cap.
   Tests: those of tasks 3-5.
3. [x] `tests/state-as-json.oracle.test.sh:189-195`: replace the measure with `po_bounded "po state on this repository" "$ROOT" state`, then the existing `one_object`. This changes the clause the test checks, adding the 10 s cap; say so in the commit.
   Tests: `test_blocking_state_is_caught`; `tests/suite-holds-under-load.oracle.test.sh` (both tests) and the 6 tests of the file stay green.
4. [x] `tests/decision-inbox.oracle.test.sh:165-167,174`: in the loop, `po_bounded "po inbox in $dir" "$dir" inbox` replaces `start`/`po_in`/`elapsed` and the 1000 ms line. The ordering and whole-decision checks stay; drop the now unused locals.
   Test: `test_bounds_hold_under_load`.
5. [x] `tests/driver-next-action.test.sh:80-97`: `po_bounded "po next on this repository" "$ROOT" next` replaces `:82-84` and `:94`. The detached-checkout branch and the writes-nothing checks stay. The marker is removed by an EXIT trap through a global (tried: `NEXT_MARKER`), so a failing run leaves no file.
   Test: `test_bounds_hold_under_load`, with no file left in its `TMPDIR`.
6. [x] Full suite through `po-run --story s219-suite-bounds-and-cleans --label suite -- 'bash tests/run.sh'`. Then compare a fresh `TMPDIR` before and after the run, or `/tmp` when `TMPDIR` is not set: no `tmp.*` folder holding a git repository may remain.

## Scene viewpoints
—

## Run interdicts
- `po/`, `method/`, `bin/`, `tests/run.sh` end with an empty diff (story note; `run.sh` is not in `Owns`).
- `tests/suite-bounds-and-cleans.oracle.test.sh` keeps the sum above.
- No retry, rerun loop or added `sleep` in any test or helper. Both thresholds stay where they are: 1000 ms of CPU and a 10 s cap, never a switch reserved for CI.
- No test file outside `Owns` is edited, even one that re-arms its own `trap … EXIT`; a leak found there is reported to the lead.
- `tests/suite-bounds-and-cleans.test.sh` is not created: no extra test is planned, and `tests/run.sh` fails a file that holds no test.

## Files touched
`tests/lib.sh`, `tests/state-as-json.oracle.test.sh`, `tests/decision-inbox.oracle.test.sh`, `tests/driver-next-action.test.sh`, `tests/suite-bounds-and-cleans.oracle.test.sh` (oracle, written), `docs/plans/s219-suite-bounds-and-cleans.md`, `docs/verif/s219-suite-bounds-and-cleans.md`. `tests/state-as-json.test.sh` is listed in `Owns` but needs no change: the fix lives in `scratch_repo`.

## Test strategy
Three oracle tests and nothing more, against a budget of 25. Load and blocking are simulated by a double of `$PO`, never generated, so each case replays the same way on every machine; s215 did the same with git. Each test bites in both directions. The wait double passes, while the burn and block doubles fail, which proves the two rules the helper owns: CPU under a second and a cap at 10 s. The 10 s cap is checked once, through `po state`. The two other tests get it from the same helper, where the rule lives, so it is not tested in two places. The scratch rule is checked in `scratch_repo` itself and through the folder that #397 traced.
Full-suite probe on the current code with its own `TMPDIR` (717 passed): exactly one folder was left, the `architecture`/`no-screen`/`ds` repository of `test_framing_next_follows_the_stage`. The trap overrides outside `Owns` leave nothing today.

## Done when
One commit on `story/s219-suite-bounds-and-cleans`, the full suite green through `po-run` and leaving no scratch folder, a review with no open critical finding, landed through a pull request; #532, #536 and #397 closed by the landing.
