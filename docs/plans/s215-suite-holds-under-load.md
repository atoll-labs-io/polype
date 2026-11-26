---
track: flow
validated: yes
---
# Plan (short track) — s215-suite-holds-under-load

[Story](../stories.md)

Written by the planner. On the short track this one file stands in for both the research and the plan: there is no `docs/research/s215-suite-holds-under-load.md`. Validated autonomously (`Plan validation: autonomous`): no human reviewed it.

## Verified facts
No assumption of the story proved false. The story reads "délai, course, attente": the journey failure is a race, the `po state` failure is a wait counted as work.

**Cause 1 — the journey run: a reader that stops early, under `pipefail`.**
- `grade_landing` (`evals/real/grade.sh:57-63`) pipes `git log --format='%H%x09%s' refs/remotes/origin/main` into `awk '$2 == s {print $1; exit}'` (`:62`). awk exits on the first match. If git still has a line to write once awk has gone, git dies of SIGPIPE (exit 141).
- `bin/po-eval:21` runs under `set -euo pipefail`, and the grading runs in that shell (`bin/po-eval:199-203` sources `evals/real/lib.sh`; `lib.sh:545-553` calls `real_grade` in a `set -e` subshell). The pipeline's status is therefore git's 141, not awk's 0.
- `grade_story_line` reads that status: `if sha="$(grade_landing "$id")" && [ -n "$sha" ]` (`grade.sh:149`). A 141 prints `story <id>: not landed — stage: none — waiting: none` (`:163`) although the sha was printed. `pred_landed` reads only the text, `[ -n "$(grade_landing "$id")" ]` (`:171`), so the same run grades `landed all` true.
- The double lands s01 then s02 (`tests/real-run-before-a-release.oracle.test.sh:61`). s02 is therefore the newest commit and the first line of the log, the one most exposed: git still has two lines to write after it. The journey's origin holds 3 commits at grading (seen through a logging git shim).
- **Proof from the CI log** (run 45719106741, attempt 1, 2026-11-25T23:21:30Z): `story s01-greeting: landed …`, `story s02-farewell: not landed — stage: none — waiting: none`, then `case journey run 1: pass`. Only an exit status can tell those two readers apart, so the grade passed while the story line said "not landed". `test_real_run_drives_the_journey_repository` requires two landed lines (`real-run-before-a-release.oracle.test.sh:151-152`), so it failed.
- **Reproduced.** `grade_landing` copied out of `grade.sh` and run on a 3-commit history outside the worktree, under `pipefail`: s02 got 95/1000 false "not landed" at idle and 70/500 with 16 CPU loops; s01 got 1/1000 and 3/500. `git log` exited 141 in each failure. The oracle below makes the same race deterministic with a git whose `log` writes one line every 50 ms. On the current code it prints both stories `not landed` alongside `case journey run 1: pass`, which is the CI signature exactly. The whole test passed 9 times out of 9 at idle and under load: the window is narrow, which explains "passes alone".
- Discarded: a time limit or a wait in po-eval or in the double. The double plays synchronously, `pred_landed` saw both commits, and the grade passed, so the work had landed and only the reading failed.

**Cause 2 — `po state`: a wall clock that counts waiting for the CPU.**
- `test_state_reads_only_files_and_git` (`tests/state-as-json.oracle.test.sh:157-194`) times `po state` on this repository with `date +%s%N` (`:189-191`) and fails at 1000 ms (`:193`). Wall time includes every moment the process and its git children spend waiting for a core.
- Measured here (16 cores), `po state` on this repository takes 28 ms wall and about 30 ms user+sys CPU at idle. With 16 CPU loops over 100 runs: up to 196 ms wall and 89 ms CPU. The failure seen (1009 ms) came at a load of 24 to 33, about 35 times the idle wall time. I did not load the machine beyond its core count, so 1009 ms was not reproduced; the oracle simulates the wait instead (a git that sleeps 1.1 s once). That gives 1152 ms on the current test.
- **Why a bound stays.** s164's criterion `state_reads_only_files_and_git` (`docs/stories.md:2601`) promises "sur ce dépôt il répond en moins d'une seconde". Dropping the bound would leave that promise unchecked. The bound moves from wall time to CPU time (user+sys of `po` and the git it waits for), which measures the work `po` does rather than the queue it waits in. 1 s keeps more than 10 times the worst value measured under load. The read-only clauses (stubs, snapshot, forbidden git verbs, `:164-187`) stay as they are.
- Bash's `time` keyword prints `TIMEFORMAT` with the locale's decimal separator (`0,029` here). Parse it by keeping only the digits of `%3U` and `%3S`, which gives milliseconds. Time `po_in` without a subshell, so `OUT` survives for `one_object`.

Same class, out of this story (reported to the lead, not fixed here): `pred_no_text_in_forge` (`grade.sh:336-339`) and `pred_clean_except` (`:245-246`) negate a `… | grep -q` pipeline under `pipefail`. Wall-clock bounds also sit in `tests/decision-inbox.oracle.test.sh:165-167` and `tests/driver-next-action.test.sh:82-84`, outside `Owns`.

## Escalation signals
Before reading the code: story text, `docs/stories.md:3494-3507`. After: the files cited above.

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — no data, story text | absent — bash files only |
| New screen | absent — `Surface: command` | absent — no UI |
| Authorization or tenant scope | absent — story text | absent — grading and a test |
| API contract | absent — story text | absent — `po state` JSON untouched; `po/` not touched |
| New dependency | absent — story text | absent — bash `time`, awk, already used |
| Technical choice that deserves an ADR | absent — story text | absent — a test's measure and an awk flag, no library, pattern or data model |
| Defect to fix (`Fixes` or `Corrige` line) | absent — no `Fixes` line, `docs/stories.md:3494-3507` | absent — the causes were still diagnosed, as `cause_is_named` asks |

## Story
As the owner, I want the suite to give the same verdict on a loaded machine as on an idle one, so that a CI failure means a defect and not a fifteen-minute rerun (#504).
- `journey_run_holds_under_load`: `test_real_run_drives_the_journey_repository` passes under a simulated load that used to make it fail, and still fails when a story really does not land.
- `state_time_bound_holds_under_load`: `test_state_reads_only_files_and_git` keeps what it proves, that `po state` only reads files and git, without depending on machine load. If a time bound remains, the plan says why (see Cause 2).
- `cause_is_named`: the plan names each cause, read in the code and reproduced. The fix targets that cause, with no automatic rerun of a failed test.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| awk keeps reading after its match (`!f && … {…; f = 1}`) | already in this repository: awk already does the matching | — no new code, one condition changed |
| CPU time of `po state` | the platform: bash's `time` keyword with `TIMEFORMAT` | not in the repository: every other bound uses `date +%s%N` (wall time) |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/suite-holds-under-load.oracle.test.sh` | `3088038066 4626` |

| Criterion | Test |
| --- | --- |
| `journey_run_holds_under_load` | `test_journey_run_holds_under_load`. Puts a git whose piped `log` writes one line every 50 ms first on PATH, then runs the journey with `land-all`: two landed lines and `case journey run 1: pass`. Then `land-first` with `FAKE_ONCE=1`: s02 `not landed`, one landed line, `case journey run 1: fail`. Checks the slow writer was really met. Fails on the current code (both stories `not landed`). |
| `state_time_bound_holds_under_load` | `test_state_time_bound_holds_under_load`. Runs s164's test in its own process, as `tests/run.sh` does. With a git that waits 1.1 s once from `$ROOT`, it must pass (fails today: 1152 ms). With a fake `po` that runs `git ls-remote`, it must still fail on the forbidden verb. With a fake `po` that burns 1.2 s of CPU, it must still fail with `not under a second`. |
| `cause_is_named` | — a rule about this plan's content, judged by the reviewer by reading `## Verified facts`. No phrase test (direction of 2026-11-13). |

## Tasks
1. [x] `evals/real/grade.sh:62`: make the awk of `grade_landing` read its whole input and print only the first match, `'!f && $2 == s {print $1; f = 1}'`, so `git log` never writes into a closed pipe. Leave `pipefail` and every caller as they are.
   Tests: `test_journey_run_holds_under_load`; `test_real_run_drives_the_journey_repository` and the rest of `real-run-before-a-release.oracle.test.sh` stay green.
2. [x] `tests/state-as-json.oracle.test.sh:189-193`: replace the wall-clock measure with the CPU time of `po_in "$ROOT" state`. Use `local TIMEFORMAT='%3U %3S'`, then `{ time po_in "$ROOT" state; } 2> "$SCRATCH/cpu"`, then read user and sys and keep only their digits (ms). Fail on `-ge 1000`. Keep the words `not under a second` in the message (the oracle reads them), e.g. `po state took ${elapsed} ms of CPU on this repository, not under a second`. This changes the clause the test checks, wall time to CPU time; say so in the commit.
   Tests: `test_state_time_bound_holds_under_load`; the 6 tests of `state-as-json.oracle.test.sh`.
3. [x] Full suite through `po-run --story s215-suite-holds-under-load --label suite -- 'bash tests/run.sh'`.

Both edits were tried on a copy outside the worktree. All 8 targeted tests passed, at idle and under 16 CPU loops.

## Scene viewpoints
—

## Run interdicts
- `po/`, `method/`, `bin/` end with an empty diff (story note). That includes `bin/po-eval` and its `set -euo pipefail`.
- `tests/suite-holds-under-load.oracle.test.sh` keeps the sum above.
- No retry anywhere: no loop that reruns a test, a `po-eval` run, a grade or `po state` after a failure. No `sleep` added to `evals/real/` or to the two existing tests.
- The time bound of `test_state_reads_only_files_and_git` stays at 1000 ms and stays in that test, not moved behind a CI-only switch.
- `grade.sh` changes only at `:62`. The same-class sites listed above are out of scope.
- `tests/suite-holds-under-load.test.sh` is not created (no extra test planned; `tests/run.sh` fails a file with no test).

## Files touched
`evals/real/grade.sh`, `tests/state-as-json.oracle.test.sh`, `tests/suite-holds-under-load.oracle.test.sh` (oracle, written), `docs/plans/s215-suite-holds-under-load.md`, `docs/verif/s215-suite-holds-under-load.md`.

## Test strategy
Two oracle tests, nothing else (budget 25). Load is simulated deterministically, never generated: a slow writer for the race, a single wait for the clock. Each fails on the current code and replays on every machine. Each also keeps its bite: an unlanded story still grades `fail`; a forbidden git verb and real CPU work still fail the state test. A test that relaunches on failure is forbidden. `cause_is_named` is read by the reviewer.

## Done when
One commit on `story/s215-suite-holds-under-load`, full suite green through `po-run`, a review with no open critical finding, landed through a pull request; #504 closed by the landing.
