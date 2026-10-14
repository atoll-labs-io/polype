# Review: s119-rebuilt-helper-tests-tenant

[Story](../stories.md) · [Plan](../plans/s119-rebuilt-helper-tests-tenant.md) · [Verification](../verif/s119-rebuilt-helper-tests-tenant.md)

Review status: complete
Reviewed tree: a1ca48b4218ba3ec09894ea10f9bbf9de026c81e
Fix loop: 0
Lenses run: none (the diff has no auth, routes, migrations, lockfiles or server code. It only touches a bash eval recipe and bash tests.)

## Scope
I ran `git diff --name-only main...story/s119-rebuilt-helper-tests-tenant`. It lists:
- `evals/cases/rebuilt-helper.sh`, `tests/rebuilt-helper-single-defect.test.sh` and `tests/reuse-ladder-eval.test.sh`. These are exactly the three entries on the `Owns` line.
- `docs/research/`, `docs/plans/` and `docs/verif/` for s119. These are the story's own evidence, so they are in scope by construction.

Nothing is outside `Owns`. `git worktree list` shows no other story worktree running, so no other lane can collide with this one.

## Step 1: Reusing the recorded run
- `po-gate verif-current s119-rebuilt-helper-tests-tenant` exited 0. `Verification mode: record` is set, so I relied on the record's `Unit suite` row (`bash tests/run.sh`, exit 0) and did not rerun the full suite. The project has no `Typecheck` command (it is `—`).
- The record's "Not proven here" section names the paid `bin/po-eval` measurement. That run is the lead's job after ship and is outside this story.
- `QA stage` is `—`, so this story does not go to QA.

## Step 2: References
Every name the diff uses exists and matches:
- `rh_build`, `$ROOT`, `bin/po-eval --build`, `CASE_STORY_ID`.
- `Note(id, owner_id, tenant_id, text, archived=…)` and `self.alice = User(1,10)` in `evals/lib.sh`.
- Note id 6 is free: the base fixtures use 1–3 and the plant uses 4–5.

## Step 3: Against the plan
- All five tasks are in the diff as written.
- The plan's `## Reuse` section matches the diff: `rh_names_no_flaw` was extracted and `test_recipe_names_no_flaw` keeps its behaviour.
- Run interdicts all hold:
  - `evals/lib.sh` and `docs/evals/` have an empty diff.
  - Lines 1–7, `story()`, the planted `archived_for` and the two existing planted tests are unchanged.
  - `test_demo_app_unchanged` and `test_recipe_copies_correct_code` are unchanged byte for byte.
- One clause changes, from `= 2` to `= 3` in `tests/reuse-ladder-eval.test.sh`. The story changes what that clause checks and the plan says so, which the project conventions allow.

## Step 4: Do the tests prove anything?
- **Floor:** `po-gate floor-guard s119-rebuilt-helper-tests-tenant main` exited 0, so no check was made easier to pass.
- **Coverage that is only apparent:**
  - `test_plant_tests_the_tenant_boundary` is a real mutation test. It runs the built suite, removes the tenant clause from `archived_for` only, checks that `list_for` keeps its clause, then runs the suite again. It requires a failure that names the new test.
  - The fixture really crosses tenants with the same owner id.
- **Excess:** the story adds 2 tests, within `Test budget: 25`. `test_copy_stays_the_only_defect` deliberately overlaps existing checks, and the plan justifies it.
- **Bite:** I ran three mutations, each against only the relevant files. I restored the file after each one, and `git diff --exit-code evals/cases/rebuilt-helper.sh` came back clean every time. The worktree is clean at the end.

| Mutation in `evals/cases/rebuilt-helper.sh` | Tests run | Tests that failed |
| --- | --- | --- |
| Removed the new planted test (lines 75–78) | `rebuilt-helper-single-defect.test.sh` and `reuse-ladder-eval.test.sh` | 2 (`plant_tests_the_tenant_boundary`, `eval_plants_a_rebuilt_helper`) |
| Fixture `tenant_id=20` changed to `tenant_id=10` | `rebuilt-helper-single-defect.test.sh` | 1 (`plant_tests_the_tenant_boundary`, caught by the fixture check) |
| Planted assertion `assertNotIn(6,` changed to `assertNotIn(7,` (fixture still crosses tenants, but the planted test now proves nothing) | `rebuilt-helper-single-defect.test.sh` | 1 (`plant_tests_the_tenant_boundary`: "removing the tenant clause of archived_for leaves the suite green") |

Every mutation was caught. The third shows the behavioural check bites on its own, not just the text check.

## Step 5: Values
- `tenant_id=20` matches Carol's tenant in the base fixtures.
- The regex `tenant_id=10[,)]` correctly excludes the same-tenant notes.
- The new wording ("other tenants", "old plan", "refusal for another tenant") avoids both flaw-naming greps, and `rh_names_no_flaw` passed in the recorded run.

## Step 6: Neighbours
`tests/evals.test.sh` (the five-kind lists, `verif-current` and `floor-guard` on the built case) and `tests/eval-arms-same-environment.test.sh` also build this case. Both are part of the recorded green full suite. No `pressure-*` case is based on `rebuilt-helper`.

## Findings
1. **minor**: `evals/cases/rebuilt-helper.sh:51`. The built plan's `## Done when` still says "Both tests pass with the rest of the suite", while task 2 (`:35`) and the test strategy (`:48`) now name three tests. A reviewer in the eval could flag this inconsistency as a stray minor. It adds noise to a measurement this story exists to clean up, but it is unlikely to change the expected `major/yes` result. Suggested wording: "The three tests pass with the rest of the suite".

## Not verified
- **The paid measurement** (`bin/po-eval --control --model claude-opus-5-5 --repeat 3 rebuilt-helper`). I did not check whether reviewers stop raising the missing tenant test as a second major. The story leaves this run to the lead after ship, and it costs model calls. To cover it, the lead runs it and updates `docs/evals/reuse-ladder.md`.
- **The base app's tenant gap.** `list_for`'s own tenant clause is still untested in the base app (`evals/lib.sh:108-112`). The plan names this as base-app scope and frozen by `test_demo_app_unchanged`, so reviewers in the eval may still raise it. Only the re-measurement above will show whether they do.
- **The full suite.** I did not rerun it myself and relied on the record, as `Verification mode: record` allows. The `verif-current` gate checked it.
- **QA.** There is no QA report, because this story does not go to QA.

## Verdict
No critical and no major findings. The tree was the same at the start and the end of the review (a1ca48b4218ba3ec09894ea10f9bbf9de026c81e).

Relevant files:
- /home/lecrabe/dev/atoll/polype/.worktrees/s119-rebuilt-helper-tests-tenant/evals/cases/rebuilt-helper.sh
- /home/lecrabe/dev/atoll/polype/.worktrees/s119-rebuilt-helper-tests-tenant/tests/rebuilt-helper-single-defect.test.sh
- /home/lecrabe/dev/atoll/polype/.worktrees/s119-rebuilt-helper-tests-tenant/tests/reuse-ladder-eval.test.sh
- /home/lecrabe/dev/atoll/polype/.worktrees/s119-rebuilt-helper-tests-tenant/docs/verif/s119-rebuilt-helper-tests-tenant.md

Max severity: minor
Ship allowed: yes
