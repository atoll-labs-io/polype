# Review — s66-eval-grading

[Story](../stories.md) · [Plan](../plans/s66-eval-grading.md) · [Verification](../verif/s66-eval-grading.md)

Diff reviewed: `git diff main...story/s66-eval-grading`, by a reviewer that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: ce62739653d61761e269c302f36833f60b99f303

## Ownership
The diff was listed with `git diff --name-only main...story/s66-eval-grading`. It touches `bin/po-eval` (M), `tests/evals.test.sh` (M), `docs/plans/s66-eval-grading.md` (A) and `docs/verif/s66-eval-grading.md` (A).
- [x] Every path is inside `Owns` (`bin/po-eval`, `tests/evals.test.sh`), or is this story's own evidence (plan, verif).
- [x] Nothing is outside `Owns`.
- [x] No path is inside another running story's `Owns`. The only other lane is s65-upgrade-path, and these paths are not in its `Owns`.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s66-eval-grading` exited 0. I reused the record: status complete, `Unit suite` `bash tests/run.sh` exit 0 on matching code. The project has no type check command (`Typecheck: —`). The record's "Not proven here" section says the real `claude` is never run.
- [x] `po-gate qa-current` was not required: there is no screen and the project has no `QA stage`.
- I also ran `TMPDIR=<fresh dir> bash tests/run.sh evals.test.sh` myself. Result: 8 passed, and the fresh dir was empty afterwards. That proves the plan's "Done when" claim about the temp dir.

## Plan
- [x] Task 1: `grade()` prints `blocked` on a strict `^Review status:[[:space:]]*blocked[[:space:]]*$` line, ahead of the verdict lines. The header and the comment were updated. The `claude exit` branch still comes first (`bin/po-eval:165`).
- [x] Task 2: a second loop in `drift_check()` reports files under `method/skills/<skill>/` that are missing from the user copy. The `[ -d … ] || continue` skip, the agent check and the exit path are kept.
- [x] Task 3: the `po_eval` helper sets `TMPDIR="$EVTMP/tmp"`. `bin/po-eval:143` still creates and prints the results dir and never deletes it.
- [x] Task 4: the three tests are named after the criteria and match the plan's scenarios, including the `complete` counterpart and the no-drift baseline.
- [x] Run interdicts, checked one by one:
  - The name list is limited to the allowed paths.
  - `evals/`, `method/`, `.claude/`, `.polype/`, `tests/run.sh` and `tests/lib.sh` have an empty diff.
  - The bodies of the five existing tests are unchanged; only the helper changed.
  - The results dir is not deleted.
  - Tests reach `claude` only through `fake_claude`, and `CLAUDE_CONFIG_DIR` always points under `EVTMP`.
  - No ADR was added.

## References
- [x] I opened every reference: `cmp`, `find`, `grep -qE`, `CLAUDE_CONFIG_DIR`, `$POLYPE_ROOT/method/skills/<skill>`, and the reviewer's `skills:` list parsed by the existing awk. The `results: ` output line the tmp test parses exists at `bin/po-eval:144`.
- [x] Values: the `Review status: <complete | blocked>` form matches `.polype/templates/review.md:5`. Exits 1 ("nothing run") and 2 (drift) match `bin/po-eval:140` and `:76`.

## Rules
- [x] `AGENTS.md` conventions are respected: bash tests named after the criteria, English, no Killer SaaS text added.
- [x] No accepted ADR is contradicted.

## Tests
- [x] Floor: `po-gate floor-guard s66-eval-grading main` exited 0, so nothing was lowered.
- [x] None of the six empty test shapes appear. The tests run the real `bin/po-eval` against a fake `claude`, and the fake only echoes a reply; it does not decide anything.
- [x] 8 eval tests, well within `Test budget: 25`.
- [x] Bite. I made five mutations and ran only `evals.test.sh` after each:

| Mutation | Tests that failed |
| --- | --- |
| Removed the blocked check in `grade()` | 1 (`a_blocked_report_is_graded_blocked`) |
| Changed the blocked check to match any `Review status:` line | 1 (`a_blocked_report_is_graded_blocked`) |
| Deleted the "missing from user copy" loop | 1 (`drift_check_is_tested_and_complete`) |
| Disabled the agent-file drift comparison | 1 (`drift_check_is_tested_and_complete`) |
| Dropped `TMPDIR` from the `po_eval` helper | 1 (`evals_leave_nothing_in_tmp`) |

  I restored the file after each mutation and confirmed it with `git diff --exit-code`. The worktree is clean.
- [x] No test became useless.

## Neighbours
- [x] `grade` and `drift_check` are used only inside `bin/po-eval`. The only outside caller, `tests/run-ledger.test.sh`, uses `--build`, which this diff does not change. No doc lists the grade labels.

## Lenses
Lenses run: none. There are no auth or route paths, no migration, no lockfile or manifest, and no server code.

## Findings
- minor — `bin/po-eval:98`: a complete report that quotes an earlier `Review status: blocked` on its own line is graded `blocked`. The plan's pivot accepts this explicitly, since the error can only lower the rate. I record it so the trade-off stays visible; no change is required.
- minor — `bin/po-eval:95`: the rewritten comment line is about 120 characters, much longer than the lines around it. Style only.

## Not verified
- **No live run against the real `claude`.** Grading and the drift check were exercised only through `fake_claude`, so I did not see how a real reviewer formats its `Review status:` line (bold, capitalised). A person should run `bin/po-eval --repeat 1 foreign-resource` once and confirm that a blocked run reads `got blocked`.
- **The drift check against a real `~/.claude`.** The tests use a synthetic config dir with only `review-antihallu` copied. A person can run `bin/po-eval` with `n` on a machine with a global install to confirm it exits 1 when nothing drifted.
- **Leftovers from my own mutation.** While `TMPDIR` was dropped from the helper (my mutation), that test run wrote results dirs into `/tmp`. I deleted nothing, because an `/tmp/tmp.*` dir holding `foreign-resource/` might also come from s65-upgrade-path running main's still-leaky `evals.test.sh`. A person can remove the recent `/tmp/tmp.*` dirs that contain a `foreign-resource/` subdirectory.

Max severity: minor
Ship allowed: yes
