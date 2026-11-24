# Review — s210-lanes-run-git-with-dash-c

[Story](../stories.md) · [Plan](../plans/s210-lanes-run-git-with-dash-c.md) · [Verification](../verif/s210-lanes-run-git-with-dash-c.md)

Method version: 0.11.0
Recorded: 2026-11-24T10:43:26+01:00

Diff reviewed: `git diff main...story/s210-lanes-run-git-with-dash-c`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: a87a54f44e5af13ed8cce96e263701357a8866ec

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
Diff listed with `git diff --name-only main...story/s210-lanes-run-git-with-dash-c`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`. `bin/po-lint`, `method/AGENTS.md`, `method/agents/{designer,implementer,planner,qa,reviewer}.md`, `method/commands/{po-execute,po-qa,po-review,po-ship}.md`, `method/word-budget` and `tests/lanes-run-git-with-dash-c.oracle.test.sh` are all listed. The plan and verif files are the story's own evidence.
- [x] Outside `Owns`: none
- [x] Inside another running story's `Owns`: none. s209's paths (`evals/`, `docs/evals/`) are untouched.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s210-lanes-run-git-with-dash-c` exited 0, so I reused the record. `Verification mode: record` applies. The record shows the unit suite `bash tests/run.sh` with exit 0, and its code outside `docs/` matches. The project has no type check (`Typecheck: —`). I read the record's "Not proven here": the prose criteria are left to this review.
- [x] `po-gate qa-current` not required: `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1 to 5 are all present, and nothing falls outside the plan.
  - Task 1: Law 4 is reworded.
  - Task 2: `check_cd_git` uses the planned regex and runs after `check_budget`. `METHOD_FILES` and the summary count are untouched: po-lint still reports 25 files.
  - Tasks 3 and 4: all ten lines are reworded as specified.
  - Task 5: only the `AGENTS.md` ceiling fell (3732 to 3731), and the total fell by 1. The po-ship sentence keeps 13 words, so its ceiling correctly stays.
- [x] I checked each run interdict:
  - Empty diff under `.claude/`, `.polype/`, `po/`, `evals/`, `docs/evals/`, `docs/decisions/` and `method/hooks/`.
  - `po-qa.md:34` and `po-review.md:34` keep their `cd <…> && … po record` text.
  - No ceiling is raised (`bin/po-lint --base origin/main` is clean).
  - The oracle checksum is intact (`oracle-intact` exit 0).
  - No empty `tests/lanes-run-git-with-dash-c.test.sh` exists.

## References
- [x] Every reference checked out:
  - `report()` and the `find` walk exist in `bin/po-lint` as the plan cites.
  - `po-bounds.sh` already parses `git -C`: `step_dir` at line 737, and `tests/bounds.test.sh` has 79 `git -C` cases. Subagents told to use `git -C` stay inside their bounds.
  - "by Law 4" in `po-ship.md:16` points to the reworded Law 4 sentence, which no longer limits itself to subagents.
- [x] Values: the regex's left boundary `[^[:alnum:]_.-]` stops "abcd" or "-cd" from matching. The `[^\`]*` span keeps the match inside one code span. The negative controls in the oracle show that `git -C`, `cd … && po` and the new wording stay green.

## Rules
- [x] `AGENTS.md` conventions respected. Criterion `law4_names_git_dash_c`, which speaks to a model, is met: Law 4 now gives `git -C <absolute worktree path>` as the form of git, "never after a `cd`", and `cd <absolute worktree path> &&` for everything else. The prose half of `no_cd_before_git_in_method` is also met: a grep of `method/` outside the hooks finds no remaining instruction to put `cd` before every command. The only `cd` lines left are the ten new ones plus the two `po record` lines.
- [x] No accepted ADR is contradicted. The method stays under its word budget: the total went down by one.

## Tests
- Oracle: `po-gate oracle-intact s210-lanes-run-git-with-dash-c` → exit 0
- [x] Floor: `po-gate floor-guard s210-lanes-run-git-with-dash-c main` exited 0, so nothing was lowered.
- [x] The assertions pin the acceptance criteria, and none of the six empty test shapes appears. The oracle runs the real `bin/po-lint` on a copy of `method/`, checks one breach in each of four file kinds by file and line, checks the exact count, and has negative controls.
- [x] Within `Test budget` (2 of 25).
- [x] Bite: I disabled the `check_cd_git` call, which made 1 test fail (`no_cd_before_git_in_method`). Undone, and `git diff --exit-code bin/po-lint` is clean.
- [x] Bite: I dropped `;` from the separator group of the regex, which made 1 test fail (the `SKILL.md` breach went unnamed). Undone, and `git diff --exit-code bin/po-lint` is clean.
- [x] No test became useless. The plan's grep shows no existing test pinned the reworded phrases.

## Neighbours
- [x] I read the callers and neighbours:
  - `tests/lint.test.sh` is unaffected: the file count is unchanged, per the record's green suite.
  - `po-bounds.sh` already handles `git -C`.
  - `po-ship.md` has no other `cd`-based git step.
  - The oracle test file ran green on its own in 5 s.

## Lenses
Lenses run: none. The diff touches no auth, route, migration, lockfile, manifest or server-side code.
- [x] No lens findings.

## Findings
- minor — tests/lanes-run-git-with-dash-c.oracle.test.sh:62 — `test_method_does_not_grow` depends on an `origin/<Target branch>` remote. It fails with "no merge base" in a clone that has no `origin`. CI is safe because it checks out with `fetch-depth: 0`. Once the story lands on main, the merge base is HEAD itself, so the ceiling comparison always passes. That half of the test then only repeats the raise check that `po-lint --base` already makes.
- minor — bin/po-lint:16 — The `cd-git` rule matches one line at a time. A `cd` on one line and `git` on the next escapes it: a shell `\` continuation, or a fenced block with `cd X` then `git …`. No such line exists in `method/` today, so nothing is missed now.

## Not verified
- I did not run the full suite. I relied on the record's passing run with exit 0 on the same code.
- No live lane was run, so I have not seen Claude Code stop asking for approval before git commands under the new wording. That is the story's actual goal (#487). To cover it, a person should run one real lane after landing and confirm that its git calls are not prompted.
- `law4_names_git_dash_c` was judged by reading only. The plan lists it as a candidate for a `po-eval` control arm (#208).

Max severity: minor
Ship allowed: yes
