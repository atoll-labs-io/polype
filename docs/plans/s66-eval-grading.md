---
track: flow
validated: yes
---
# Plan (short track) — s66-eval-grading

[Story](../stories.md)

Written by the planner on the short track (`Story track: auto`, complexity 2 ≤ `Flow threshold: 2`, no escalation signal). This one file stands in for both research and plan. Validated autonomously (`Plan validation: autonomous`): no human reviewed it.

## Verified facts
No assumption of the story proved false. The three findings of `docs/reviews/s55-reviewer-evals.md:69-76` were each reproduced in the code.

- **Grading ignores `Review status:`.** `grade()` (`bin/po-eval:91-98`) reads only the last `Max severity:` and `Ship allowed:` lines, strictly (`:95-96`), and prints `<sev>/<ship>` or `no verdict`. A run passes when that label equals `$CASE_EXPECT_SEVERITY/$CASE_EXPECT_SHIP` (`:160`). A non-zero `claude` exit is graded `claude exit <n>` before `grade` (`:159`).
- A blocked report ends `Max severity: critical` / `Ship allowed: no` (`method/commands/po-review.md:38`), which is exactly the expectation of `foreign-resource` and the pressure cases, so today it counts as a pass. The template line reads `Review status: <complete | blocked>` (`method/templates/review.md:5`, `method/agents/reviewer.md:32`).
- `CASE_EXPECT_SEVERITY` can only be `critical|major|minor|none` (`tests/evals.test.sh:45`). A `blocked` label therefore never equals an expectation, and the per-case summary (`bin/po-eval:163-165`) shows it as `got blocked ×n` with no other change.
- **Drift check.** `drift_check()` (`bin/po-eval:54-72`) compares `$cfg/agents/reviewer.md` with `method/agents/reviewer.md` when the user copy exists (`:56-58`). For each skill in the reviewer's `skills:` list (`method/agents/reviewer.md:6-10`: review-antihallu, review-lenses, testing-doctrine, design-doctrine), it skips the skill when `$cfg/skills/<skill>` is absent (`:63`). Otherwise it walks **only the files of the user copy** (`:64-67`), so a file present in `method/skills/<skill>/` but missing from the user copy is never reported: the gap named in the review. On drift it prints the `bin/polype update --global` hint and exits 2 (`:69-71`). `cfg` is `${CLAUDE_CONFIG_DIR:-$HOME/.claude}` (`:55`).
- The drift check runs before the confirmation prompt (`bin/po-eval:124` then `:126-135`). Answering `n` therefore exits **2** on drift and **1** ("nothing run", `:134`) without drift. This tells the two cases apart without any model call.
- Every test passes an empty `CLAUDE_CONFIG_DIR="$EVTMP/cfg"` (`tests/evals.test.sh:28`, created at `:13`), so no test reaches either branch of the drift check (review bite 3, `docs/reviews/s55-reviewer-evals.md:57`).
- **Temp leak.** `results="$(mktemp -d)"` (`bin/po-eval:137`) is deliberately kept for the user (`:138`, `:168`). The per-run `repo` dir is removed (`:151`, `:158`). `po_eval` (`tests/evals.test.sh:25-30`) does not set `TMPDIR`. Measured: `TMPDIR=<fresh dir> bash tests/run.sh evals.test.sh` left **5** `tmp.*` dirs there, one per confirmed po-eval run (pressure 1, grading 3, on-demand 1).
- No other temp leaks were found on this path. `EVTMP` is trap-cleaned (`tests/evals.test.sh:3-4`), and each test is its own process (`tests/run.sh:17`). `po-run.sh` cleans its scratch (`method/hooks/po-run.sh:42-43`). `eval_build` → `bin/polype install` (`evals/lib.sh:149`) uses no `mktemp`.
- Other users of `po-eval`: `tests/run-ledger.test.sh:152` calls `--build` only, which is unaffected. ADR-0033 says nothing about grading or drift. No doc describes the grade labels.
- Baseline: `bash tests/run.sh evals.test.sh` → 5 passed.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text: bash tool and its test | absent — no data store in `bin/po-eval` |
| New screen | absent — story text | absent — CLI output only (`bin/po-eval:165`) |
| Authorization or tenant scope | absent — story text | absent — tenant flaws exist only inside fixtures (`evals/cases/`), out of scope |
| API contract | absent — story text | absent — the only consumer of the run output is the person reading it. `--build` (`tests/run-ledger.test.sh:152`) is unchanged |
| New dependency | absent — story text | absent — `cmp`/`find` are already used (`bin/po-eval:56,67`). Any `diff -rq` comes from the same diffutils package as `cmp` |

## Story
Make `po-eval`'s rate measure what the reviewer found. A blocked report is graded `blocked` and never passes. The drift check gets a test that can make it fail, and it also reports a file that is in `method/` but missing from the installed copy. The eval tests leave nothing in the system temp dir.

- `a_blocked_report_is_graded_blocked`
- `drift_check_is_tested_and_complete`
- `evals_leave_nothing_in_tmp`

## Tasks

1. [x] **Grade blocked reports.** In `grade()` (`bin/po-eval:91-98`), when the report holds a line matching `^Review status:[[:space:]]*blocked[[:space:]]*$`, print `blocked`, whatever its verdict lines say. Otherwise keep the current logic. Update the comment at `:90` and the header at `:10-11` so they name `blocked`. The `claude exit` branch (`:159`) stays first.
   Test: `test_a_blocked_report_is_graded_blocked` fails if the check is removed. Under it, a blocked report ending `critical`/`no` would read `1/1 passed` on `foreign-resource`.
2. [x] **Report files missing from the user copy.** In `drift_check()` (`bin/po-eval:63-67`), when `$cfg/skills/<skill>` exists, compare in **both** directions. Every file under `method/skills/<skill>/` that is absent from the user copy is reported as `po-eval: $cfg/skills/<skill>/<rel> is missing (method/skills/<skill>/<rel> exists)` and sets `drift=1`. The existing per-file comparison is kept. Keep the `[ -d … ] || continue` skip: without a user copy, nothing shadows the project copy. The agent check (`:56-58`) and the exit path (`:69-71`) stay as they are.
   Test: the "missing file" half of `test_drift_check_is_tested_and_complete` fails without this task.
3. [x] **Confine the eval tests' temp dirs.** In `po_eval` (`tests/evals.test.sh:25-30`), run `po-eval` with `TMPDIR="$EVTMP/tmp"` (create the dir first). Its `results` dir and per-run repos then land under the trap-cleaned `EVTMP`. `bin/po-eval:137` stays as it is: the user keeps their results.
   Test: `test_evals_leave_nothing_in_tmp` fails if the `TMPDIR` is dropped from the helper.
4. [x] **Write the three tests** in `tests/evals.test.sh`, each named after its criterion and run through the existing helpers `fake_claude`, `reply`, `po_eval` and `calls`:
   - `test_a_blocked_report_is_graded_blocked`:
     - Run `foreign-resource` (expects `critical/no`) with the reply `Review status: blocked` … `Max severity: critical` / `Ship allowed: no`. Assert `foreign-resource: 0/1 passed` and `got blocked`.
     - Run the same reply with `Review status: complete` instead. Assert `1/1 passed`. This guards against an implementation that grades any `Review status:` line as blocked.
   - `test_drift_check_is_tested_and_complete`:
     - (a) Fill `$EVTMP/cfg` with exact copies of `method/agents/reviewer.md` and `method/skills/review-antihallu/`, then run `po_eval n --repeat 1 foreign-resource`. Expect exit 1 (no false drift).
     - (b) Change one byte of the copied `reviewer.md`. Expect exit 2, output naming `agents/reviewer.md differs`, and `calls` = 0.
     - (c) Restore it and delete `SKILL.md` from the copied `review-antihallu/`. Expect exit 2, with output naming `review-antihallu/SKILL.md` and `missing`.
     - Each of (b) and (c) fails if `drift_check` returns 0 straight away. (c) alone fails without task 2.
   - `test_evals_leave_nothing_in_tmp`: run `po_eval y --repeat 1 foreign-resource`. Take the path from the `results: ` line of `PO_OUT`, and assert that it starts with `$EVTMP/` and that this directory exists.
5. [x] **Run.** First `bash tests/run.sh evals.test.sh` (8 tests). Then the full suite once through `po-run`, per `Full suite: execute-end`. `Typecheck: —`.

## Run interdicts
- `git diff main...story/s66-eval-grading --name-only` lists only `bin/po-eval`, `tests/evals.test.sh` and this story's `docs/` evidence (`docs/plans/`, `docs/verif/`).
- The bodies of the five existing tests in `tests/evals.test.sh` are unchanged; only the `po_eval` helper changes (task 3).
- `evals/`, `method/`, `.claude/`, `.polype/`, `tests/run.sh` and `tests/lib.sh`: empty diff.
- `bin/po-eval:137`: the results dir is still created and printed. It is never deleted by `po-eval`.
- The real `claude` is never invoked. Tests reach it only through `fake_claude` on `PATH`, and none touches `~/.claude` (`CLAUDE_CONFIG_DIR` always points under `EVTMP`).
- No ADR is written. ADR-0042 stays unused.

## The pivot
**What makes a report "blocked"?** A strict line `Review status: blocked` anywhere in the report, which overrides the verdict lines. How this could be wrong:
- **Too narrow.** A reviewer that writes `**Review status:** blocked` or `Review status: Blocked` escapes the label and falls back to its verdict lines. This mirrors the strictness already applied to verdict lines (`bin/po-eval:95-96`, po-gate), and the template fixes the exact form. A malformed blocked report still loses its pass if its verdict lines are also malformed, but not otherwise. Accepted: loosening one line's grammar but not the others' would be inconsistent.
- **Too broad.** "Anywhere" means a complete report that quotes an earlier blocked status on a line of its own is graded `blocked`. That error only ever lowers the rate, never inflates it, which is the direction the story asks for. Reading the last or first `Review status:` line instead was turned down: unlike the verdict lines, the status sits at the top (`templates/review.md:5`), so "last" would let a quote win, and "first" would let a preamble win.

## Files touched
`bin/po-eval`, `tests/evals.test.sh`, plus `docs/plans/s66-eval-grading.md` and `docs/verif/s66-eval-grading.md`.

## Test strategy
There are three tests, one per criterion, all at the adapter layer of this tool: `po-eval` is run end to end against a fake `claude` and a throwaway `CLAUDE_CONFIG_DIR`. The suite grows from 5 to 8, well within `Test budget: 25`.
- Each test names the rule it guards.
- The blocked test carries a `complete` counterpart, so a naive "any status line" grader fails it.
- The drift test carries a no-drift baseline, so an "always drift" check fails it.
- The tmp test checks where the results land, not a count of `/tmp`: with `Parallel: 2` lanes, `/tmp` changes under the test.

No test re-checks the existing verdict-line rules.

## Done when
- The three criteria tests pass, and so do the 5 existing eval tests.
- The full suite is green, recorded by `po-run` in `docs/verif/s66-eval-grading.md`.
- Running `TMPDIR=<fresh dir> bash tests/run.sh evals.test.sh` leaves that dir empty.
- There is one commit on `story/s66-eval-grading`, followed by a review with no open critical finding.
