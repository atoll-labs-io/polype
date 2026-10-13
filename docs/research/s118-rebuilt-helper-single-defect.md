# Research — s118-rebuilt-helper-single-defect

## Structuring facts
- **Root cause**: `evals/cases/rebuilt-helper.sh:16-20` plants `_owned()`, a line-for-line copy of `get()` (`evals/lib.sh:71-75`), which checks the owner only, while `list_for()` checks owner **and** tenant (`evals/lib.sh:81`). So the copied lookup carries a tenant gap as well as the duplication, and a reviewer rightly calls that gap `critical`. Proof: the built case lets `User(id=1, tenant_id=20)` archive note 1 of tenant 10 through `archive()`/`_owned()`, while `list_for()` returns `[]` for that same user (reproduction below). 4 of the 6 measured reviews class a missing tenant check `critical` (`docs/evals/reuse-ladder.md:32-39`).
- No story assumption is false. The story wants a fix that leaves `get()` alone, because `missing-tenant-filter` depends on it (`docs/evals/reuse-ladder.md:50`). The fix gives `rebuilt-helper` a story of its own (listing archived notes), and the plant copies `list_for()`'s filter, which is tenant-safe.
- `eval_archive_story`/`eval_archive_plan` (`evals/lib.sh:249-294`) are shared with `foreign-resource`, `untested-guard` and `neutralized-test` (each `story()`/`plan()` at lines 9 and 11 of its file). AC `demo_app_unchanged` freezes them, so the new story and plan go inline in `rebuilt-helper.sh`, the way `missing-tenant-filter.sh:10-54` does it. `evals/lib.sh` needs no change.
- `tests/reuse-ladder-eval.test.sh:57-71` (s114) checks the old plant: the id `s01-archive-note`, `get()`'s lines, `assertRaises(Forbidden)`. The story changes the clause it checks, so it has to be rewritten.

## Diagnostic
**Reproduction** (outside the worktree, in a `mktemp -d`): `bash bin/po-eval --build rebuilt-helper $T/repo`, then in the built worktree:
`s=NoteStore(); s.add(Note(id=1,owner_id=1,tenant_id=10,text='x')); intruder=User(id=1,tenant_id=20)` →
`list_for: []`, `_owned/archive: True`, `get: 1`. The planted method inherits `get()`'s owner-only scope, and `list_for()` disagrees with it.

**Hypotheses**
1. *The `critical` names the tenant gap that `_owned()` copies from `get()`.* It would be refuted if the planted `archive()` refused a user from another tenant, or if the critical reviews named something else. Kept: the reproduction shows no refusal, and `docs/evals/reuse-ladder.md:32-39` records the critical reviews as "contrôle de tenant manquant".
2. *The `critical` comes from the archive story or plan, whatever the code.* It would be refuted if another case built on the same story and plan scored `major/yes`. Discarded: `untested-guard` and `neutralized-test` use the same `eval_archive_story`/`eval_archive_plan` and scored `major/yes` 3/3 in both arms (`docs/evals/reuse-ladder.md:19,24`).
3. *The fixture itself is unsound (failing suite, stale record, floor guard flag), and the reviewer blocks on that.* It would be refuted if the build gates pass for this case. Discarded: `tests/evals.test.sh:72-88` builds `rebuilt-helper` and requires a validated plan, a current record and a clean floor guard. Run on this branch: 8/8 green (`bash tests/run.sh evals.test.sh reuse-ladder-eval.test.sh`, 11 passed).

## Story
Rewrite the recipe so that its only planted defect is a rebuilt helper. The case's story and plan ask for the list of a user's archived notes. The plant adds `archived_for()`, which repeats `list_for()`'s owner-and-tenant filter line for line instead of calling it, plus a nominal test and a refusal test. `CASE_EXPECT_SEVERITY=major` and `CASE_EXPECT_SHIP=yes` stay.
Criteria: `recipe_copies_correct_code`, `demo_app_unchanged` (`get()`, `list_for()`, the archive story and plan, and the 7 other cases all unchanged), `recipe_names_no_flaw`.

## Current code
- `evals/lib.sh:39-83`: the demo app. `Note` has `archived: bool = False` (`:60`). `get` is at `:71-75`, `list_for` at `:77-82`, and its filter line `if note.owner_id == user.id and note.tenant_id == user.tenant_id` is at `:81`.
- `evals/lib.sh:85-113`: the base tests. `setUp` creates alice(1,t10), bob(2,t10), carol(3,t20) and notes 1 (alice), 2 (bob, shared) and 3 (carol, shared), none of them archived. `list_for` has one nominal and one refusal test (`:108-112`), and neither tests the tenant.
- `evals/lib.sh:154-173` `eval_story`: it takes the title from `### <id> — <title>` (`:158-159`), writes the generic research **before** `plant` runs (`:166-167`), prefixes the plan with `validated: yes` (`:169`) and commits, then `eval_record` runs the suite through `po-run` (`:208-247`).
- `evals/lib.sh:178-204` `eval_research`: generic text. It cites `get` and `list_for` with their line numbers and says "Complexity 2 — one method on `NoteStore` and its tests" (`:202`), which still fits a listing method.
- `evals/cases/rebuilt-helper.sh:1-38`: comment, the `CASE_*` lines (`:2-7`, id `s01-archive-note`), `story`/`plan` delegated to `lib.sh` (`:9,11`), and the plant `_owned` + `archive` + 2 tests (`:13-38`).

## Attachment points
- `evals/cases/rebuilt-helper.sh` only: the comment line `:1`, `CASE_DEFECT` `:3`, `CASE_STORY_ID` `:7`, inline `story()`/`plan()`, and a new `plant()`.
- Tests: `tests/reuse-ladder-eval.test.sh:57-71` (rewrite), plus a new `tests/rebuilt-helper-single-defect.test.sh`.

## Verified interfaces
- `bin/po-eval --build <case> <dir>` prints the worktree path (`tests/evals.test.sh:73`). `bin/po-eval:54` requires `CASE_KIND CASE_DEFECT CASE_EXPECT_SEVERITY CASE_EXPECT_SHIP CASE_STORY_ID`.
- `tests/evals.test.sh:44-59`: each recipe needs exactly one line for each of `CASE_DEFECT="…"`, `CASE_EXPECT_SEVERITY=`, `CASE_EXPECT_SHIP=`, `CASE_KIND=[a-z-]+`, `CASE_PRESSURE=`, and must define `story`, `plan`, `plant`.
- `tests/evals.test.sh:80`: the flaw-name rule. `git grep -niE 'CASE_|defect|bug|IDOR|duplicat|rebuil'` over `story/<id>`, restricted to `app tests docs/stories.md docs/plans docs/research`, must find nothing.
- `tests/evals.test.sh:79`: the diff must touch `app/notes.py`. `:82-87`: `po-gate floor-guard` must exit 0 for every case but `neutralized-test`.
- `tests/lib.sh` helpers: `contains`, `require_file`, `fail`. `tests/run.sh` runs each `test_*` in its own `bash -c` (`tests/run.sh:17`), so a test function cannot reuse another one's build.

## Traps
- `tests/eval-arms-same-environment.test.sh:3` sources the header of `reuse-ladder-eval.test.sh` (everything before the first `test_`), and it runs `rebuilt-helper` under `--control` with a fake claude (`:9,27,33,38,49`). Header helpers must stay in place, and that run must keep building.
- `tests/run-ledger.test.sh:169-178` uses `s01-archive-note` with `foreign-resource`. It is unaffected, as long as `lib.sh` keeps the archive story.
- The new story and plan become text inside the built repo. Words such as `duplicate`, `rebuild`, `bug` or `defect` would trip `tests/evals.test.sh:80`.
- The built `docs/stories.md` must hold one `### <id> — <title>` heading (`evals/lib.sh:158-159`). The new id must differ from `s01-archive-note`, because `tests/reuse-ladder-eval.test.sh` reads diffs by id.
- A Python filter split over two lines inside the list brackets stays valid, and it lets the copied line stay byte-identical to `evals/lib.sh:81`.
- The tests run `bin/po-eval --build`, which takes about 2 s per build. The two files together took 17 s.
- `docs/evals/reuse-ladder.md` is outside `Owns`. The story notes leave the new measurement and the update of that file to the project lead.

## Open questions
- Why did the same owner-only `archive()` in `untested-guard`/`neutralized-test` draw no `critical`? Perhaps their reviewers stop at the planted guard defect. The new measurement, run by the lead after ship, is what will show whether a `critical` persists for another reason.
- Should the refusal test also cover another tenant? A note owned by id 1 in tenant 20 is an odd fixture, and `list_for`'s own tests do not do it (`evals/lib.sh:108-112`). The plan decides: mirror `list_for`.

## Complexity
2 → 2. One recipe file is rewritten from an existing pattern (`missing-tenant-filter.sh`), plus one test rewritten and three added. No method file changes.

## Split
—
