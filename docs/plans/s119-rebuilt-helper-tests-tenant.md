---
validated: yes
---
# Plan — s119-rebuilt-helper-tests-tenant

[Story](../stories.md) · [Research](../research/s119-rebuilt-helper-tests-tenant.md)

Branch `story/s119-rebuilt-helper-tests-tenant`. Read `docs/research/s119-rebuilt-helper-tests-tenant.md` first. This plan builds on it.

## Story
The `rebuilt-helper` plant tests the tenant clause of `archived_for()`, so that the case's expected score measures only the copy.
- `plant_tests_the_tenant_boundary`: the plant adds a test in which an archived note belongs to the same user id in another tenant, and that note is absent from `archived_for()`. Removing the tenant clause of `archived_for()` in the built repo fails that test.
- `copy_stays_the_only_defect`: `archived_for()` still repeats `list_for()`'s filter without calling it. `CASE_EXPECT_SEVERITY=major` and `CASE_EXPECT_SHIP=yes` stay, and the built repo still names no flaw.

Root cause (research): `evals/cases/rebuilt-helper.sh:66-75` plants no fixture with owner id 1 in a tenant other than 10, so a mutant without the tenant clause survives (`Ran 6 tests … OK`).

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Planted test `test_archived_for_skips_notes_of_other_tenants` | new code, in the existing heredoc `evals/cases/rebuilt-helper.sh:66-75` | No planted or base test builds a cross-tenant note with the same owner id (`evals/lib.sh:97-99`, `evals/cases/rebuilt-helper.sh:69,73`). It reuses `setUp`'s `self.alice` and the `Note` dataclass as they are. |
| Helper `rh_names_no_flaw` in `tests/rebuilt-helper-single-defect.test.sh` | already in this repository: the two greps of `test_recipe_names_no_flaw` (`tests/rebuilt-helper-single-defect.test.sh:51-56`), moved into a function and called by both tests | `test_recipe_names_no_flaw` cannot be called as it is from the new test: it runs `rh_build` again into the same `$RHTMP/build`. |
| `test_plant_tests_the_tenant_boundary`, `test_copy_stays_the_only_defect` | new code that reuses `rh_build` (`:6-10`) | No existing test mutates the built repo and runs its suite. |

## Tasks
1. [x] **Plant the cross-tenant test.** In `plant()`'s second heredoc (`evals/cases/rebuilt-helper.sh:66-75`), after `test_archived_for_skips_notes_of_others`, append at the same indent (4 spaces for `def`, 8 for the body):
   ```
   def test_archived_for_skips_notes_of_other_tenants(self):
       self.store.add(Note(id=6, owner_id=1, tenant_id=20, text="old plan", archived=True))
       self.assertNotIn(6, [note.id for note in self.store.archived_for(self.alice)])
   ```
   Note 6 is added inside the test, never in `setUp` (`evals/lib.sh` stays untouched). This exact test was checked in a temp build: it passes on the plant and fails on the mutant. Test that fails if this task is wrong: `test_plant_tests_the_tenant_boundary`.
2. [x] **Make the built plan name the third test.** In `plan()`:
   - Task 2 (`evals/cases/rebuilt-helper.sh:35`) adds `test_archived_for_skips_notes_of_other_tenants` (Alice's archived note 6 in tenant 20 is not in her list).
   - The test strategy (`:48`) reads three tests at the service layer: the nominal listing, the refusal for another user, and the refusal for another tenant.

   No word may match `repeat|cop(y|ies)|line for line|instead of call|CASE_|defect|bug|IDOR|duplicat|rebuil`. Tests that fail if this task is wrong: `test_copy_stays_the_only_defect` and `test_recipe_names_no_flaw` (the grep over `docs/plans`).
3. [x] **Update the count clause.** `tests/reuse-ladder-eval.test.sh:73-74`: `= 2` becomes `= 3`, and the message becomes "the plant must add exactly three archived_for tests". The clause changes with the story (AGENTS.local.md conventions allow this), and a raised count lowers no threshold for `floor-guard`. Test that fails if this task is wrong: `test_eval_plants_a_rebuilt_helper`.
4. [x] **Add the acceptance tests** in `tests/rebuilt-helper-single-defect.test.sh`. This file is owned. `Owns` names no new test file, and `po-bounds` would refuse one.
   - Add a line to the header comment for s119.
   - Extract `rh_names_no_flaw` (the two greps of `:53-56`, reading `$RH_WT` and `$RH_ID`). `test_recipe_names_no_flaw` becomes `rh_build; rh_names_no_flaw`, with the same behaviour.
   - `test_plant_tests_the_tenant_boundary`:
     - `rh_build`;
     - assert that the plant's diff to `tests/test_notes.py` (`git diff main...story/$RH_ID`) adds a `Note(` with `owner_id=1` and a `tenant_id=` other than `10`, with `archived=True`;
     - run the built suite (`python3 -m unittest discover -s tests -t .` in `$RH_WT`) and expect exit 0;
     - remove ` and note.tenant_id == user.tenant_id` from the filter of `archived_for` only (a `sed` range starting at `def archived_for`), then assert that line 42's `list_for` filter is still intact;
     - run the suite again and expect a non-zero exit, with `test_archived_for_skips_notes_of_other_tenants` named in the failure output.
   - `test_copy_stays_the_only_defect`:
     - `grep -qx` both `CASE_EXPECT_*` lines of the case file;
     - `rh_build`;
     - assert that the lines the plant adds to `app/notes.py` hold `def archived_for(self, user):` and `if note.owner_id == user.id and note.tenant_id == user.tenant_id`, and no `self.list_for(`;
     - call `rh_names_no_flaw`.

   Focused run: `bash tests/run.sh rebuilt-helper-single-defect.test.sh reuse-ladder-eval.test.sh evals.test.sh`.
5. [x] **Full suite** once all tasks are done: `po-run --story s119-rebuilt-helper-tests-tenant --label 'Unit suite' -- 'bash tests/run.sh'`. The project has no `Typecheck` (`—`).

## Scene viewpoints
—

## Run interdicts
- `evals/lib.sh` and the seven other `evals/cases/*.sh` end with an empty diff.
- In `evals/cases/rebuilt-helper.sh`, these keep an empty diff: lines 1-7 (comment and every `CASE_*` line), `story()` (`:9-22`), the planted `archived_for` (`:56-65`), and the text of the two existing planted tests (`:68-74`).
- `test_demo_app_unchanged` and `test_recipe_copies_correct_code` stay byte for byte (story note).
- `docs/evals/reuse-ladder.md` stays untouched. No `bin/po-eval` run without `--build` (the paid measurement is the lead's, after ship).
- No file is created outside `docs/`. The only source and test files changed are `evals/cases/rebuilt-helper.sh`, `tests/rebuilt-helper-single-defect.test.sh` and `tests/reuse-ladder-eval.test.sh`.

## The pivot
A single cross-tenant note with **the same owner id** (`owner_id=1`, `tenant_id=20`) is what makes the tenant clause observable. A note of another user in another tenant (Carol, id 3) is already filtered out by the owner clause, so it would leave the mutant alive. Ways it could be wrong:
- **The mutation in the acceptance test hits `list_for` too.** Then the suite fails for the wrong reason. Compare against the built `app/notes.py`: only the line after `def archived_for` loses its clause, and line 42 keeps it. Task 4 asserts this.
- **Reviewers still report a second major.** For example, `list_for`'s own tenant clause is untested in the base app (`evals/lib.sh:108-112`), or the story's criterion `archived_skips_notes_of_others` names only "another user". This story cannot settle it: the lead's re-measurement after ship will show it. The base app stays frozen (`test_demo_app_unchanged`).
- **The new wording names the flaw.** "other tenants" and "old plan" match none of the greps. `rh_names_no_flaw` and `tests/evals.test.sh:81` check it.

## Files touched
`evals/cases/rebuilt-helper.sh`, `tests/rebuilt-helper-single-defect.test.sh`, `tests/reuse-ladder-eval.test.sh`; `docs/research/s119-rebuilt-helper-tests-tenant.md`, `docs/plans/s119-rebuilt-helper-tests-tenant.md`, `docs/verif/s119-rebuilt-helper-tests-tenant.md`.

## Test strategy
Automated, bash, at the layer of the eval recipe:
- `test_plant_tests_the_tenant_boundary` is a behavioural mutation test on the built repo. Restoring the old plant (no note 6) leaves the mutant alive, and the test fails.
- `test_copy_stays_the_only_defect` holds the criterion's name. It overlaps on purpose with `test_eval_plants_a_rebuilt_helper` (a filter without `self.list_for(`) and `test_recipe_names_no_flaw` (shared helper). It adds nothing heavier than one build, and it names the criterion as the conventions require.
- One existing clause changes (`tests/reuse-ladder-eval.test.sh:73`, from two tests to three).

That makes 2 new tests and 1 changed clause, well within `Test budget: 25`. No visual check.

## Done when
- Each task is ticked.
- The focused files and then the full `bash tests/run.sh` are green through `po-run`, and `docs/verif/s119-rebuilt-helper-tests-tenant.md` is complete.
- One commit `s119-rebuilt-helper-tests-tenant: …` carries the code, the tests and the docs.
- The review has no open critical finding.
