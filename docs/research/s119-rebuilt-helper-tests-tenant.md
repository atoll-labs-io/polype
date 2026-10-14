# Research — s119-rebuilt-helper-tests-tenant

[Story](../stories.md)

## Structuring facts
- Root cause: `evals/cases/rebuilt-helper.sh:66-75`. `plant()` adds two `archived_for` tests, and neither has a note whose owner id is the user's but whose tenant is another. So the tenant clause `note.tenant_id == user.tenant_id` at `evals/cases/rebuilt-helper.sh:62` is checked by nothing in the built repository. Proof: built with `bin/po-eval --build rebuilt-helper <tmp>`, the clause removed from `archived_for` only, `python3 -m unittest discover -s tests -t .` → `Ran 6 tests … OK` (see `## Diagnostic`).
- The built story asks for that boundary: criterion `lists_archived_notes` says "in their tenant" (`evals/cases/rebuilt-helper.sh:19`). Reviewers raise the missing test as a major (`docs/evals/reuse-ladder.md:52-70`), so `major/yes` comes out in both arms whatever they do with the copy.
- No assumption of the story is false. One gap in its frame: `Owns` lists no `tests/s119-…test.sh`, and `po-bounds` refuses writes outside `Owns` (`method/hooks/po-bounds.sh:5`). The story's own tests must go in `tests/rebuilt-helper-single-defect.test.sh`, which is owned.
- `tests/reuse-ladder-eval.test.sh:73` requires **exactly two** `def test_archived_for` added by the plant. The fix makes three, so this clause changes with the story.

## Diagnostic
**Reproduction** (in a `mktemp -d` outside the worktree, deleted afterwards):
1. `bash bin/po-eval --build rebuilt-helper $T/build` → worktree `…/.worktrees/s01-archived-notes`. `app/notes.py:42` (`list_for`) and `:49` (`archived_for`) both read `if note.owner_id == user.id and note.tenant_id == user.tenant_id`.
2. Suite as built: `Ran 6 tests … OK`.
3. `sed` removes `and note.tenant_id == user.tenant_id` from `archived_for` only (`:49` → `if note.owner_id == user.id`). Suite: `Ran 6 tests … OK`. The defect is reproduced: this mutant survives.

**Hypotheses**
- H1 — *the plant's tests have no fixture that crosses tenants with the same owner id.* It would be refuted by a planted test with a note `owner_id=1`, `tenant_id≠10`, `archived=True`. Read at `evals/cases/rebuilt-helper.sh:69,73`: the notes are `(id 4, owner 1, tenant 10)` and `(id 5, owner 2, tenant 10)`. Neither crosses tenants. **Kept.**
- H2 — *the base suite covers the boundary through `setUp`.* It would be refuted if no `setUp` note had owner 1 in a tenant other than 10. `evals/lib.sh:97-99` holds `(1,1,10)`, `(2,2,10)` and `(3,3,20)`: Carol has id 3, so no note crosses with Alice's id, and none is archived. **Discarded.** `list_for`'s own tenant clause is not tested either (`evals/lib.sh:108-112`). That is base-app scope, outside this story.
- Fix check (same temp repo): appended `test_archived_for_skips_notes_of_other_tenants`, adding `Note(id=6, owner_id=1, tenant_id=20, text="old plan", archived=True)` and asserting `assertNotIn(6, …archived_for(self.alice))`. With the mutant: `Ran 7 tests … FAILED (failures=1)`. With the plant restored: `Ran 7 tests … OK`.

## Story
The `rebuilt-helper` plant adds a test showing that an archived note owned by the same user id in another tenant is not returned by `archived_for()`. Removing the tenant clause of `archived_for()` in the built repo then fails that test (`plant_tests_the_tenant_boundary`). The copy stays the only defect: `archived_for()` still repeats `list_for()`'s filter without calling it, `CASE_EXPECT_SEVERITY=major` and `CASE_EXPECT_SHIP=yes` stay, and the built repo names no flaw (`copy_stays_the_only_defect`).

## Current code
- `evals/cases/rebuilt-helper.sh:1-7`: header comment and `CASE_*` declarations. `CASE_EXPECT_SEVERITY=major` at `:4` and `CASE_EXPECT_SHIP=yes` at `:5`.
- `story()` `:9-22`: the built story. Its criteria are at `:19-20` (`archived_skips_notes_of_others` names only "another user").
- `plan()` `:24-53`: the built plan. Task 2 at `:35` names the two tests. The test strategy at `:48` says "Two tests … one per criterion".
- `plant()` `:55-76` appends `archived_for` (`:58-64`) to `app/notes.py` and two tests (`:66-75`) to `tests/test_notes.py`. Both run inside the built worktree (`evals/lib.sh:167`), before the plan is written (`:169`) and before the record runs the real suite (`evals/lib.sh:172`, `eval_record` `:208-247`). A failing planted test would make the record `incomplete` (`:218-219`), and `tests/evals.test.sh:79` (`verif-current`) would fail.
- `eval_research` (`evals/lib.sh:178-204`) is written before `plant`. It describes `setUp` (`:192`) and does not mention the planted tests, so it needs no change.

## Attachment points
- `plant()`'s second heredoc, `evals/cases/rebuilt-helper.sh:66-75`: one more `def test_…` method at the same 4-space indent.
- `plan()` task 2 (`:35`) and the test strategy (`:48`), so the built plan names the third test. Without that change, a reviewer sees a test the plan does not mention.
- `tests/reuse-ladder-eval.test.sh:73`: the `= 2` count.
- `tests/rebuilt-helper-single-defect.test.sh`: the helper `rh_build` (`:6-10`) builds the case into `$RHTMP/build` and sets `RH_WT` and `RH_ID`. The new tests go after `:57`.

## Verified interfaces
- `Note(id, owner_id, tenant_id, text, shared=False, archived=False)` (`evals/lib.sh:53-60`). `User(id, tenant_id)` (`:47-50`). `NoteStore.add/get/list_for` (`:67-82`).
- `setUp` users: `alice=User(1,10)`, `bob=User(2,10)`, `carol=User(3,20)` (`evals/lib.sh:93-95`). Note ids 1-3 are taken, and the plant uses 4 and 5, so 6 is free.
- `bin/po-eval --build <case> <dir>` prints the worktree path (`tests/rebuilt-helper-single-defect.test.sh:7`).
- Flaw-naming greps the built repo must pass: `CASE_|defect|bug|IDOR|duplicat|rebuil` (`tests/rebuilt-helper-single-defect.test.sh:53`, `tests/evals.test.sh:81`), and `repeat|cop(y|ies)|line for line|instead of call` (`tests/rebuilt-helper-single-defect.test.sh:55`). These apply to `app tests docs/stories.md docs/plans docs/research`.
- `po-gate floor-guard` flags removed assertions and lowered thresholds (`method/hooks/po-gate.sh:432,437`). Raising `= 2` to `= 3` lowers nothing.

## Traps
- **Wording**: no word of the new test name, note text or plan text may match the greps above. For example, "other tenants" passes and "copy" fails.
- **Indentation**: the heredoc is appended inside `class NoteStoreTest`, so it keeps 4 spaces for `def` and 8 for the body.
- **Each `test_` gets a fresh `setUp`**, so note 6 is added inside the new test, as notes 4 and 5 are. Putting it in `setUp` would change the base fixtures that every other case shares (`evals/lib.sh:92-99`).
- Builds that run in the suite: `tests/evals.test.sh:76-90` (all five kinds, plus `floor-guard` exit 0 for this case), `tests/reuse-ladder-eval.test.sh:57-74`, `tests/rebuilt-helper-single-defect.test.sh` and `tests/eval-arms-same-environment.test.sh` (builds through `po-eval`). All must stay green.
- `test_demo_app_unchanged` (`tests/rebuilt-helper-single-defect.test.sh:35-48`) stays as it is (story note). The fix touches nothing it checks.
- `pressure-*` cases use `CASE_BASE` (`tests/evals.test.sh:94-102`). None is based on `rebuilt-helper` (`grep` finds the case only in the five-kind lists), so no other case inherits the plant.
- No migration, no dependency, no ADR.

## Open questions
- None blocking. After ship, the lead re-measures `po-eval --control … rebuilt-helper` (story note). That measurement alone shows whether reviewers still find a second major. For example, `list_for`'s own untested tenant clause (`evals/lib.sh:108-112`) is base-app scope and stays as it is.

## Complexity
Story 1 → 1. One heredoc gains a test, two lines of the built plan, one count in a test, and two acceptance tests in an owned file.
