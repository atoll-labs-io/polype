# Review: s118-rebuilt-helper-single-defect

Diff reviewed: `git diff main...story/s118-rebuilt-helper-single-defect`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: da4ea954e7e6ba1d9363fdafbb58425ffe2f8563

## When blocked
Not applicable. The tree was taken again just before this answer and had not changed (da4ea954…). The worktree is clean.

## Ownership
I listed the diff with `git diff --name-only main...story/s118-rebuilt-helper-single-defect`.
- [x] Every path is inside `Owns`. `evals/cases/rebuilt-helper.sh`, `tests/reuse-ladder-eval.test.sh` and `tests/rebuilt-helper-single-defect.test.sh` are all listed there. The story's research, plan and verification record are pipeline evidence, so they count as in scope.
- [x] No path is outside `Owns`.
- [x] No path is inside another running story's `Owns`.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s118-rebuilt-helper-single-defect` passes (exit 0), and `Verification mode` is `record`. I reused the record instead of rerunning the suite: Unit suite `bash tests/run.sh` exited 0, status complete. The project has no type check (`Typecheck: —`). The record's "Not proven here" says no model call was made: the new measurement of the case is left to the lead after ship.
- [x] `po-gate qa-current` is not required, because the story does not go to QA (`QA stage: —`, `Surface: —`).

## Plan
- [x] Each task is present and nothing falls outside the plan.
  - Task 1: comment, `CASE_DEFECT` and `CASE_STORY_ID=s01-archived-notes` are as planned. The story and plan are inline, and the plan names `list_for` (`app/notes.py`). The plant's `if` line matches `list_for`'s filter in `evals/lib.sh` byte for byte. The two tests use notes 4 and 5.
  - Task 2: `test_eval_plants_a_rebuilt_helper` is rewritten, the commit message says so, and it reads the story id from the recipe.
  - Task 3: the new test file holds three functions, one per acceptance criterion.
  - Task 4: the record shows the full-suite run.
- [x] Each run interdict holds:
  - `evals/lib.sh`, `tests/evals.test.sh` and every case except `rebuilt-helper.sh` are unchanged against main.
  - Lines 1-56 of `tests/reuse-ladder-eval.test.sh` are unchanged; the first change is at line 58.
  - Nothing under `method/`, `.claude/`, `.polype/`, `bin/` or `docs/evals/` is touched.
  - No real `claude` call; tests use only `--build`.
  - The `CASE_EXPECT_SEVERITY=major` / `CASE_EXPECT_SHIP=yes` lines are unchanged.

## References
- [x] I opened and confirmed every reference:
  - The demo app in `evals/lib.sh`: `Note.archived` is a field, `User(id, tenant_id)` exists, and `list_for` is the last method of `NoteStore`, so the planted method lands inside the class at the right indent.
  - `eval_story`'s `### <id> — <title>` heading rule.
  - The `eval_archive_story`/`eval_archive_plan` users: foreign-resource, untested-guard and neutralized-test.
  - `missing-tenant-filter.sh` still plants `if note.shared]`.
  - `evals/cases` holds 8 recipes.
- [x] No value only looks right. Note ids 4 and 5 do not collide with the `setUp` notes 1 to 3. Alice (1, tenant 10) and Bob (2, tenant 10) are as `setUp` defines them.

## Rules
- [x] `AGENTS.md` conventions are respected: bash tests named after the acceptance criteria, an English commit message with no co-author trailer, and the rewritten existing test is declared in the commit.
- [x] No accepted ADR is contradicted.

## Tests
- [x] Floor: `po-gate floor-guard` exits 1 with one flag, `tests/reuse-ladder-eval.test.sh:67: assertions-dropped: 1 removed, 0 added`. Plan task 2 names this file and gives the reason (the clause it checks changes with the story), so I grade it minor.
- [x] Assertions pin down the acceptance criteria.
  - `recipe_copies_correct_code` checks behaviour: it compares `archived_for` against `list_for` for a cross-tenant user, not just text.
  - None of the six shapes of test that prove nothing appears. The new test's fixture is self-contained and does not rely on `setUp`.
- [x] 4 tests (3 new, 1 rewritten), within `Test budget` 25.
- [x] Bite. Each mutation was in `evals/cases/rebuilt-helper.sh`; after each I ran only the matching test files, undid it with `git checkout --`, and confirmed with `git diff --exit-code` that the file was clean.
  1. Plant made owner-only (tenant clause removed): **2 tests fail**, `recipe_copies_correct_code` and `eval_plants_a_rebuilt_helper`.
  2. Plan pivot reworded to "copies the boundary": **1 test fails**, `recipe_names_no_flaw`.
  3. Plant made to call `self.list_for(user)` instead of repeating the filter: **1 test fails**, `eval_plants_a_rebuilt_helper`.
- [x] The old `_owned`/`archive` assertions, which this story made useless, were removed by the rewrite.

## Neighbours
- [x] I read the other callers of the case.
  - `tests/eval-arms-same-environment.test.sh` and the `--control` tests in `tests/reuse-ladder-eval.test.sh` build `rebuilt-helper` without depending on its story id.
  - `tests/evals.test.sh:67,72` loops over the case structurally.
  - `tests/run-ledger.test.sh:169` keeps using `s01-archive-note` through `foreign-resource`, which is unchanged.
  - All of these are covered by the recorded green full suite.

## Lenses
Lenses run: security, triggered by content: the planted `archived_for` filter decides who may read a record. No finding: the planted filter checks both owner and tenant, and it is fixture code generated into a throwaway eval repo. Migration, dependencies and performance did not run (no trigger in the diff).
- [x] Every lens finding is graded and listed below (there are none).

## Findings
1. minor — `tests/reuse-ladder-eval.test.sh:67` — the floor guard flags one dropped assertion (`assertRaises(Forbidden)`). The plan's task 2 justifies it: the clause changed with the story.
2. minor — `tests/rebuilt-helper-single-defect.test.sh:36-47` — `test_demo_app_unchanged` is mostly a text inventory of files this diff does not touch, including a hard-coded "8 recipes". It turns the run interdicts into a permanent test, so any future story that adds a case or edits `get()` on purpose will break it. It guards against regressions the diff cannot cause, and it adds maintenance cost.

## Not verified
- **Whether the verdict is now really `major`/`yes`.** No model was called, by design. The lead must run `bin/po-eval --control --model claude-opus-5-5 --repeat 3 rebuilt-helper` after ship and update `docs/evals/reuse-ladder.md`, as the story notes say.
- **A possible second finding in the built case.** Its story says "in their tenant", but neither the plant's tests nor `list_for`'s tests check the tenant boundary. A real reviewer could still raise that as an untested-criterion finding; the plan's pivot names this risk. Only the measurement above will show whether it skews the score.
- **The full unit suite.** I did not rerun it. It is proven only by the `po-run` record on this code; only the focused test files were run during the bite.
- **Type check, end to end and build.** The project has none (`—`).

Max severity: minor
Ship allowed: yes
