# Review — s215-suite-holds-under-load

[Story](../stories.md) · [Plan](../plans/s215-suite-holds-under-load.md) · [Verification](../verif/s215-suite-holds-under-load.md)

Method version: 0.13.0
Recorded: 2026-11-26T11:25:49+01:00

Diff reviewed: `git diff main...story/s215-suite-holds-under-load`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: f20a21cd3fdb07c5241109a9a4b32982c011835e

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
I listed the diff with `git diff --name-only main...story/s215-suite-holds-under-load` and checked each path against `Owns` (`docs/stories.md:3500`).
- [x] Every path is inside `Owns`:
  - `evals/real/grade.sh` falls under `evals/real/`.
  - `tests/state-as-json.oracle.test.sh` and `tests/suite-holds-under-load.oracle.test.sh` are listed by name.
  - `docs/plans/…` and `docs/verif/…` are the story's own evidence.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`. `git worktree list` shows only main and this story.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s215-suite-holds-under-load` exits 0, so I reused the record and did not rerun the suite.
  - Unit suite `bash tests/run.sh` exited 0 (855 s).
  - The project has no type check command (`Typecheck: —`).
  - The record's "Not proven here" says the 1009 ms failure under real load was not reproduced. Only CI will show it.
- [x] `po-gate qa-current` is not required: `QA stage: —`, so the story does not go to QA.

## Plan
- [x] All three tasks are present: the awk at `grade.sh:62`, the CPU-time bound in `state-as-json.oracle.test.sh`, and the full suite through `po-run`. Nothing is outside the plan.
- [x] Each run interdict holds:
  - `po/`, `method/` and `bin/` have an empty diff (checked with `git diff --stat`).
  - The oracle sum is intact (`oracle-intact` exits 0).
  - No retry loop and no `sleep` were added to `evals/real/` or to the two existing tests. The sleeps live only in the new oracle's slow-git simulation.
  - The bound stays at 1000 ms, in the same test, with no CI switch.
  - `grade.sh` changes only line 62.
  - No `tests/suite-holds-under-load.test.sh` was created.
- [x] `cause_is_named` (judged by reading `## Verified facts`):
  - Cause 1 is a race: SIGPIPE on `git log` once awk exits early. I confirmed `set -euo pipefail` at `bin/po-eval:21`, and I confirmed that `grade_story_line` (`grade.sh:149`) reads the exit status while `pred_landed` (`:171`) reads only the text. That is consistent with the CI signature quoted in the plan.
  - Cause 2 is a wall clock that counts time spent waiting for the CPU.
  - Both fixes target their cause, and neither adds a rerun.

## References
- [x] Every reference is confirmed:
  - `po_in` (`state-as-json.oracle.test.sh:18`) runs in the current shell and sends `po`'s stderr to `/dev/null`. So `OUT` survives for `one_object`, and the `2>` file holds only the output of `time`.
  - `$SCRATCH` is set by `fixture`.
  - `real_setup`, `real_run`, `RTMP`, `FAKE_PLAY=land-first` and `FAKE_ONCE` exist in `real-run-before-a-release.oracle.test.sh`, and the new oracle sources them.
- [x] Values: `${x//[!0-9]/}` turns `%3U`/`%3S` into milliseconds, whatever the locale's decimal separator. `10#` guards against leading zeros being read as octal.

## Rules
- [x] The `AGENTS.md` and `AGENTS.local.md` conventions are respected. The commit message says the clause of s164's test changed, as the plan asked.
- [x] No accepted ADR is contradicted. The plan flags no ADR-worthy choice.

## Tests
- Oracle: `po-gate oracle-intact s215-suite-holds-under-load` → exit 0
- [x] Floor: `po-gate floor-guard s215-suite-holds-under-load main` exits 0, so nothing was lowered.
- [x] The assertions pin the criteria, and both directions are covered:
  - The journey passes under a slow writer, and a story that never landed is still reported not landed and graded fail.
  - The time bound still catches a forbidden git verb and real CPU work.
  - Each case checks that its simulation was really met (the `slowed` file). None of the six empty test shapes appears.
- [x] Two tests, within `Test budget` 25.
- [x] Bite 1: I put back the early `exit` in `grade_landing`'s awk (`grade.sh:62`). 1 test failed (`journey_run_holds_under_load`), and it printed both stories as `not landed` next to `case journey run 1: pass`, the CI signature. I undid it and `git diff --exit-code` is clean.
- [x] Bite 2: I set `elapsed=0` in `test_state_reads_only_files_and_git` to neutralise the CPU bound. 1 test failed (`state_time_bound_holds_under_load`: "a po state that works more than a second passed the test"). I undid it and `git diff --exit-code` is clean.
- [x] No test became useless.

## Neighbours
- [x] The other callers of `grade_landing` (`grade.sh:171`, `:176`, `:372`) read only its text. That text is unchanged, because the first match is still the only line printed. Nothing is broken.

## Lenses
Lenses run: none (the diff is bash grading and test files: no auth, migration, lockfile or server-side code).
- [x] No lens findings.

## Findings
- minor — tests/state-as-json.oracle.test.sh:167 — Leftover locals in `test_state_reads_only_files_and_git`: `start` is still declared in `local … before start elapsed` but is no longer used, and `elapsed` is now declared `local` twice (`:167` and `:189`). This is tidying only.
- minor — tests/state-as-json.oracle.test.sh:189 — The bound now counts CPU time (user+sys), so it no longer checks how long `po state` takes to answer. s164 promised it "répond en moins d'une seconde" (`docs/stories.md:2601`). A `po state` that blocks without using CPU (waiting on a lock, a timeout on a call nobody stubbed) would now pass. The story allowed this trade and the plan explains it (Cause 2), so this is noted rather than a defect. If response time matters again, a much looser wall-clock ceiling could be added without bringing back the flakiness.

## Not verified
- Real machine load above the core count (1009 ms at load 24–33) was not reproduced, by me or by the implementer. Both oracles simulate the load deterministically. A person should watch the next CI runs of `real-run-before-a-release.oracle.test.sh` and `state-as-json.oracle.test.sh` to confirm #504 is gone.
- I did not reproduce the SIGPIPE race statistics the plan quotes (95/1000 at idle). I relied on bite 1, which shows the slow-writer oracle detects the early-exit awk.
- Out of scope, for the lead to file (Law 7) and not fix here: the plan lists more code with the same flaw.
  - `pred_no_text_in_forge` (`grade.sh:336-339`) and `pred_clean_except` (`:245-246`) negate `… | grep -q` under `pipefail`.
  - Wall-clock bounds remain in `tests/decision-inbox.oracle.test.sh:165-167` and `tests/driver-next-action.test.sh:82-84`.
  - I did not check whether these were filed.

Max severity: minor
Ship allowed: yes
