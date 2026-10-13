---
validated: yes
---
# Plan — s118-rebuilt-helper-single-defect

Branch `story/s118-rebuilt-helper-single-defect`. Read `docs/research/s118-rebuilt-helper-single-defect.md` first: this plan builds on it and does not repeat it. Defect story: the cause is `_owned()` copying `get()`'s owner-only scope (research, `## Structuring facts`). The fix moves the copy onto `list_for()`'s scope, which already holds the tenant.

## Story
The `rebuilt-helper` recipe plants one defect only: a rebuilt helper. Its story and plan ask for a user's archived notes. The plant adds `archived_for()`, which repeats `list_for()`'s owner-and-tenant filter line for line instead of calling it, with a nominal test and a refusal test. The verdict stays `major`/`yes`. Criteria: `recipe_copies_correct_code`, `demo_app_unchanged`, `recipe_names_no_flaw`.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Inline `story()`/`plan()` in `rebuilt-helper.sh` | Already in this repository: the shape of `evals/cases/missing-tenant-filter.sh:10-54`, which writes its own story and plan inline | `eval_archive_story`/`eval_archive_plan` (`evals/lib.sh:249-294`) cannot be reused: they ask for an archive action, and AC `demo_app_unchanged` freezes them |
| `plant()` body | Already in this repository: `rebuilt-helper.sh:13-38` heredoc pattern; the copied filter is `evals/lib.sh:78-82` | — (rung 1 holds) |
| New test file | Already in this repository: build-and-inspect helpers of `tests/reuse-ladder-eval.test.sh:57-71` and `tests/evals.test.sh:9` (`decl`) | — (rung 1 holds; copy the two-line `decl`, sourcing `evals.test.sh` would run its traps) |

## Tasks
1. [x] **Rewrite `evals/cases/rebuilt-helper.sh`.**
   - Line 1: `# Case: archived_for() is correct and tested, but it repeats list_for()'s filter line for line instead of calling it.`
   - `CASE_DEFECT="archived_for() repeats list_for()'s owner and tenant filter line for line instead of calling list_for(), which already provides it."`
   - `CASE_KIND=rebuilt-helper`, `CASE_EXPECT_SEVERITY=major`, `CASE_EXPECT_SHIP=yes` and `CASE_PRESSURE=""` stay. `CASE_STORY_ID=s01-archived-notes`.
   - `story()` inline, in English, heading `### s01-archived-notes — List my archived notes`. It uses the same field layout as `eval_archive_story` (`evals/lib.sh:252-261`): Complexity 2, Depends on none, Owns `` `app/`, `tests/` ``. Criteria: `lists_archived_notes` — `NoteStore.archived_for(user)` returns the user's archived notes, in their tenant, and no note that is not archived. `archived_skips_notes_of_others` — an archived note of another user is never returned.
   - `plan()` inline, mirroring `missing-tenant-filter.sh:62-91`, both tasks `[x]`. Task 1 reads: `NoteStore.archived_for(user)` in `app/notes.py` returns the notes `list_for` returns (`app/notes.py`) that are archived, in insertion order. Task 2 adds the two tests, reusing `setUp`. The run interdicts include "`get` and `list_for` stay as they are". Pivot: "`archived_for` keeps the boundary `list_for` already keeps."
   - `plant()` appends to `app/notes.py`:
     ```
         def archived_for(self, user):
             return [
                 note
                 for note in self._notes.values()
                 if note.owner_id == user.id and note.tenant_id == user.tenant_id
                 and note.archived
             ]
     ```
     The `if` line is byte-identical to `evals/lib.sh:81`.
   - `plant()` appends to `tests/test_notes.py`:
     - `test_archived_for_returns_own_archived_notes`: adds `Note(id=4, owner_id=1, tenant_id=10, text="old list", archived=True)`, then asserts `[n.id for n in archived_for(alice)] == [4]`. Note 1, not archived, stays out.
     - `test_archived_for_skips_notes_of_others`: adds `Note(id=5, owner_id=2, tenant_id=10, text="old standup", archived=True)`, then asserts `5` is not in alice's list.
   - Every word written into the built repo must stay clear of `tests/evals.test.sh:80` (no `duplicat`, `rebuil`, `bug`, `defect`, `CASE_`) and of the vocabulary of task 3 (`repeat`, `copy`/`copies`, `line for line`, `instead of call`).
   - Failing test: `test_recipe_copies_correct_code` (task 3); `test_eval_plants_a_rebuilt_helper` (task 2); `test_recipes_are_checked_structurally` and `test_each_recipe_plants_one_known_defect` (`tests/evals.test.sh:42,62`).
2. [x] **Rewrite `test_eval_plants_a_rebuilt_helper`** (`tests/reuse-ladder-eval.test.sh:57-71`). Its clause changes with the story, so say so in the commit. Keep its name and its checks of `major`/`yes`, the build, and no removed line.
   - Read the id from the recipe (`sed -n 's/^CASE_STORY_ID=//p'`) rather than hard-coding it.
   - The added lines of `app/notes.py` must contain `def archived_for(self, user):` and `if note.owner_id == user.id and note.tenant_id == user.tenant_id`, and must not contain `self.list_for(`.
   - The test diff must add exactly two `def test_archived_for` functions.
   - Leave lines 1-56 (the header that `tests/eval-arms-same-environment.test.sh:3` sources) untouched.
   - Failing test: itself, against the old recipe (it would find no `archived_for`).
3. [x] **New `tests/rebuilt-helper-single-defect.test.sh`**, with a `# s118 — …` header and a temp dir trapped like `reuse-ladder-eval.test.sh:3-4`. Three functions, one per AC, and each builds the case with `bin/po-eval --build rebuilt-helper`.
   - `test_recipe_copies_correct_code`. In the built worktree, `python3 -I -c` (with `sys.path.insert(0, '.')`) does two things:
     - for alice, and for `User(id=1, tenant_id=20)` holding an archived note `Note(id=9, owner_id=1, tenant_id=10, archived=True)`, it compares `archived_for(u)` with `[n for n in list_for(u) if n.archived]` and fails on any difference;
     - it confirms `NoteStore` has no attribute `archive` nor `_owned`.
     The test also checks that the built `docs/stories.md` names `archived_for` and that the recipe holds `CASE_EXPECT_SEVERITY=major` and `CASE_EXPECT_SHIP=yes`. This is the test that would have caught the defect: on the old recipe `archived_for` is missing, and an owner-only copy fails the intruder comparison.
   - `test_demo_app_unchanged`:
     - `evals/lib.sh` still holds `get`'s owner-only check, `if note.owner_id != user.id:` exactly once, and `list_for`'s filter line exactly once;
     - `eval_archive_story` still writes `### s01-archive-note — Archive a note`;
     - `foreign-resource.sh`, `untested-guard.sh` and `neutralized-test.sh` still call `eval_archive_story` and `eval_archive_plan`;
     - `rebuilt-helper.sh` calls neither;
     - `missing-tenant-filter.sh` still plants `if note.shared]`;
     - `evals/cases` holds 8 recipes.
     Failing test: any edit of `get`, a moved archive story, or a lost case.
   - `test_recipe_names_no_flaw`: on the built `story/<id>`, over `app tests docs/stories.md docs/plans docs/research`, two `git grep` runs find nothing:
     - the rule of `tests/evals.test.sh:80`;
     - `-niE 'repeat|cop(y|ies)|line for line|instead of call'`, the words of this recipe's `CASE_DEFECT`.
     Failing test: a plan or story line that gives the copy away.
4. [x] **Run** `bash tests/run.sh rebuilt-helper-single-defect.test.sh reuse-ladder-eval.test.sh evals.test.sh eval-arms-same-environment.test.sh run-ledger.test.sh`. The full suite then runs once through `po-run --story s118-rebuilt-helper-single-defect --label "Unit suite" -- 'bash tests/run.sh'` (`Full suite: execute-end`). There is no type check (`Typecheck: —`).

## Scene viewpoints
—

## Run interdicts
- `evals/lib.sh` ends with an empty diff against `main`, and so does every file of `evals/cases/` except `rebuilt-helper.sh`.
- `tests/evals.test.sh` ends with an empty diff. Lines 1-56 of `tests/reuse-ladder-eval.test.sh` are unchanged.
- No file under `method/`, `.claude/`, `.polype/`, `bin/` or `docs/evals/` is touched. `docs/evals/reuse-ladder.md` stays as it is, because the lead updates it after the new measurement.
- Never run `bin/po-eval` without `--build`. No real or paid `claude` call, and no `--control` outside the existing fake-claude tests.
- No other change to the case's verdict lines: `CASE_EXPECT_SEVERITY=major`, `CASE_EXPECT_SHIP=yes`.

## The pivot
The planted copy carries `list_for()`'s scope, which is tenant-safe, so the only thing left to notice is that a helper was rebuilt. It could be wrong in three ways:
- **A second finding survives.** Neither `list_for`'s tests nor the plant's tests check the tenant boundary, and a reviewer might still raise "tenant untested" as `critical`. Compare with `untested-guard`, which leaves a guard untested and scores `major`. We mirror `list_for`'s test style (`evals/lib.sh:108-112`) rather than add an odd fixture.
- **The reuse is not citeable.** If the plan did not point at `list_for`, a reviewer could not hold the copy against an existing helper. Task 1's plan text names `list_for (app/notes.py)`, the same way the old plan named `get`.
- **The fixture gives itself away.** Plan or story wording could name the flaw. Task 3's `test_recipe_names_no_flaw` checks it.
Only the new measurement, which the lead runs after ship, shows the score. This story makes the recipe sound; it does not prove the rate.

## Files touched
`evals/cases/rebuilt-helper.sh`, `tests/reuse-ladder-eval.test.sh`, `tests/rebuilt-helper-single-defect.test.sh` (new), plus this story's `docs/research/` and `docs/plans/` files and `docs/verif/s118-rebuilt-helper-single-defect.md`.

## Test strategy
Automated, all at the recipe layer (built fixture inspected, no model call): 3 new tests (one per AC) + 1 rewritten (`test_eval_plants_a_rebuilt_helper`). That is 4, well within `Test budget` 25.
- `recipe_names_no_flaw` partly overlaps `tests/evals.test.sh:80`. Its extra clause, the recipe's own vocabulary, is the part that loop cannot catch.
- `test_recipe_copies_correct_code` checks behaviour (same result as `list_for` for an intruder) rather than text, so it fails on an owner-only copy, whatever form the copy takes.
- Existing guards that still apply: `test_recipes_are_checked_structurally`, `test_each_recipe_plants_one_known_defect` (record current, clean floor guard, no flaw named), and the `--control` tests of `eval-arms-same-environment.test.sh`.
No visual checks.

## Done when
- The four test files of task 4 are green, and the full suite is green through `po-run`.
- `docs/verif/s118-rebuilt-helper-single-defect.md` is complete.
- One commit `s118-rebuilt-helper-single-defect: …` on the story branch, carrying the research and the plan.
- A review with no open critical.
- The new measurement and the update of `docs/evals/reuse-ladder.md` are left to the lead, as the story notes say.
