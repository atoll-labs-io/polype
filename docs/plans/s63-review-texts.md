---
track: flow
validated: yes
---
# Plan (short track) — s63-review-texts

[Story](../stories.md)

Written by the planner on the short track (`Story track: auto`, complexity 2 ≤ `Flow threshold` 2). This one file stands in for both the research and the plan: there is no `docs/research/s63-review-texts.md`. Validated autonomously (`Plan validation: autonomous`); no human reviewed it.

## Verified facts
**Story assumptions that proved wrong or incomplete — read these first.**
- Criterion 4 speaks of "la liste des causes d'échec de `qa-current`". The list at `method/skills/review-antihallu/SKILL.md:27` names three causes (no report, `QA status: blocked`, moved `Tree:`) while the gate has six refusals (`method/hooks/po-gate.sh:131-144`: also no usable `Tree:`, unknown tree, uncommitted `docs/qa/<id>/`). The same sentence sends **every** failure to `/po-qa <id>` as `Next action:`. Adding the uncommitted report to the list is not enough: that one cause must get its own `Next action:` (the evidence commit), or the review still routes the lane to a new walk. Task 4 does both. The other two missing causes stay out of scope (they really do need `/po-qa`).
- Criterion 1 says "que le plan de la story annonce". No template has a slot for this: `templates/plan.md` and `templates/plan-flow.md` have no ADR section, and `method/commands/po-plan.md:42` only says the ADR "stays on the story branch". Plans name their ADR in free text (`docs/plans/s56-evidence-runner.md:6` names `docs/decisions/ADR-0035-…md`). So "announces" means: the plan's text names the ADR, by file name or by its `ADR-NNNN` number. ADR files are named `ADR-NNNN-<slug>.md` (`docs/decisions/ADR-0038-…md`).

**The scope check** (`method/skills/review-antihallu/SKILL.md:9-20`)
- `:11` the paths come from `git diff --name-only <Target branch>...story/<id>` and are held against the story's `Owns`.
- `:13` outside `Owns` → major; `:14` inside another running story's `Owns` → critical.
- `:16` "Three cases the bare comparison gets wrong:", then `:18` the story's pipeline evidence is in scope by construction, `:19` a path a rule of `AGENTS.md` requires → minor, `:20` no `Owns` → unverifiable scope.
- The recurring finding: an ADR added by the planner is outside `Owns`, reported minor via `:19` (`docs/reviews/s53-review-lenses.md:68`, `docs/reviews/s56-evidence-runner.md:42-43`, and six other M6 reviews).
- The reviewer already reads `ADR directory` (`method/agents/reviewer.md:14`), so the skill may say `<ADR directory>`.

**The lenses** (`method/skills/review-lenses/SKILL.md`)
- `:21` "A lens looks at the diff only, never at the rest of the repository." This contradicts step 2 and step 6 of `review-antihallu` (`SKILL.md:33`, `:45`), the security lens's critical rule (`review-lenses/SKILL.md:30`, `:38`), which often needs a policy that the diff only calls, and the changelog bullet (`:52`). This is the major of `docs/reviews/s53-review-lenses.md:63-66`, whose suggested wording the story adopts.

**The record check without the hook** (`method/skills/review-antihallu/SKILL.md:24`)
- It says the `git diff --quiet <Tree> HEAD -- . ':(exclude)docs'` "does the same comparison". Since s56 the gate does more: `verif_current` (`po-gate.sh:54-67`) also requires a `## Checks` table and calls `runs_cover_checks` (`:107-127`). For each `## Checks` row, there must be a `## Runs` row with the same label and command, on a tree whose code outside `docs/` equals the record's `Tree:`, and the last such row must exit 0. This is m2 of `docs/reviews/s56-evidence-runner.md:45-47`.

**qa-current** (`method/hooks/po-gate.sh:129-145`)
- `:140-144` refuses a current report when `HEAD` lacks `docs/qa/<id>/report.md` or `git status --porcelain --untracked-files=all --ignored -- docs/qa/<id>/` is not empty. Its message names the fix: `commit it alone: git commit -m "<id>: QA evidence" -- docs/qa/<id>/`. ADR-0037 settles that check, and says the next step is the evidence commit, not a new walk.

**Tests that quote these files** (must stay green; none is owned by this story except the first two)
- `tests/ownership.test.sh:14-61` quotes the scope section, including `pipeline evidence is in scope by construction` (`:31`).
- `tests/review-lenses.test.sh` quotes the lens sections and defines `ANTIHALLU` (`:6`).
- `tests/qa-gate.test.sh:99-103` (owned by s67) quotes `→ the review is blocked, the gate's message as \`Failure cause:\``, `each **verified** finding of the report is still open and becomes a finding of this review`, ``\`docs/designs/<id>/\`, \`docs/qa/<id>/\`. No \`Owns\``. It also requires `po-gate qa-current <id>` to sit inside step 1.
- `tests/review.test.sh:29-32` counts six `**N. ` steps and quotes two bite phrases. `tests/floor-guard.test.sh:192-196` quotes the floor bullet.
- Before the change, `bash tests/run.sh ownership.test.sh review-lenses.test.sh qa-gate.test.sh review.test.sh` → 25 passed, 0 failed.
- Where the new tests go: `Owns` lists only `tests/ownership.test.sh` and `tests/review-lenses.test.sh`. A new `tests/s63-…test.sh` would fall outside `Owns`, so the tests for criteria 1, 3 and 4 (all on `review-antihallu`) go in `ownership.test.sh`, and the test for criterion 2 goes in `review-lenses.test.sh`.

**Complexity after reading:** 2. These are four sentence edits in two skill files, plus four string tests.

## Escalation signals
| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text, `Owns` lists two skills and two tests | absent — no data, no schema in this repository's diff |
| New screen | absent — story text | absent — method text only |
| Authorization or tenant scope | absent — story text | absent — the security lens is edited in wording only (`review-lenses/SKILL.md:21`), no rule changes |
| API contract | absent — story text | absent — `po-gate` output and subcommands untouched (`po-gate.sh:129-145` read, not changed) |
| New dependency | absent — story text | absent — bash `grep`/`awk` tests using `tests/lib.sh` only |

## Story
As a developer, I want the review to treat the story's own ADRs as within its scope, and I want its texts not to contradict each other. Then no review keeps raising the same false gap, and a lens can open what it needs.
- `story_adrs_are_in_scope_by_construction`: the ownership check counts as in scope an ADR that the diff adds under `<ADR directory>` and that the story's plan announces.
- `a_lens_opens_what_the_diff_calls`: a lens judges what the diff changes, and opens what that code calls to confirm a finding.
- `the_manual_record_check_names_the_runs`: the sentence describing the record check without the hook cites the `## Runs` rows, not only the tree comparison.
- `qa_current_failure_names_an_uncommitted_report`: the list of `qa-current` failure causes in `review-antihallu` names the current but uncommitted report, whose next step is the evidence commit, not a new walk.

## Tasks
1. [x] **Story ADRs in scope** (`method/skills/review-antihallu/SKILL.md:16-20`). Change "Three cases" to "Four cases". After the pipeline-evidence bullet (`:18`), add one bullet:
   - Its opening clause, verbatim: `**An ADR the diff adds under \`<ADR directory>\` and the story's plan names** is in scope by construction too`.
   - "adds" means status `A` in `git diff --name-status <Target branch>...story/<id>`. "names" means the plan's text gives its file name or its `ADR-NNNN` number.
   - Two fallbacks: an ADR the plan does not name falls back to the cases above, and an existing ADR the diff modifies is never covered.

   Test: `test_story_adrs_are_in_scope_by_construction` in `tests/ownership.test.sh`. It quotes the opening clause, `--name-status` and `ADR-NNNN` inside `section_of "$SKILL" "$SCOPE"`. It fails if the bullet is removed or moved out of the scope section.
2. [x] **Lens reach** (`method/skills/review-lenses/SKILL.md:21`). Replace the bullet with: `A lens judges only what the diff changes, and opens what that code calls to confirm a finding` — for example the policy an endpoint relies on, or the changelog of a bumped dependency. Then give the rule that bounds the opening: a finding is still about a line of the diff. Test: `test_a_lens_opens_what_the_diff_calls` in `tests/review-lenses.test.sh`. It quotes the sentence inside `section_of "$SKILL" 'Which lenses run'` and asserts that `never at the rest of the repository` no longer appears in the file. It fails if the old line returns or the new one goes.
3. [x] **Manual record check** (`review-antihallu/SKILL.md:24`). Replace "does the same comparison". Without the hook, do both checks of `verif-current` by hand from the worktree root:
   - the tree comparison;
   - for each row of `## Checks`, a `## Runs` row with the same label and command, on a tree whose code outside `docs/` equals `<Tree>`, the last such row exiting 0 (as in `po-gate.sh:107-127`).

   Test: `test_the_manual_record_check_names_the_runs` in `tests/ownership.test.sh`. It extracts step 1 with the awk range of `qa-gate.test.sh:99` and requires `## Runs`, `same label and command` and `the last such row`. It also asserts `does the same comparison` is gone.
4. [x] **Uncommitted QA report** (`review-antihallu/SKILL.md:27`). Add the cause `a report that is current but not committed` to the failure list (`po-gate.sh:140-144`). Keep `→ the review is blocked, the gate's message as \`Failure cause:\`` byte for byte. Then state the exception: for that cause, `Next action:` is the evidence commit the gate names, `git commit -m "<id>: QA evidence" -- docs/qa/<id>/`, not a new walk, and it does not name `/po-qa`. Every other cause keeps `/po-qa <id>`. Test: `test_qa_current_failure_names_an_uncommitted_report` in `tests/ownership.test.sh`. Inside step 1, it requires `current but not committed`, the commit command and `not a new walk`. It fails if the cause or its next action is dropped.
5. [x] **Run the related suites**: `bash tests/run.sh ownership.test.sh review-lenses.test.sh qa-gate.test.sh review.test.sh floor-guard.test.sh overlap.test.sh`. Then run the full suite once through `po-run` per `Full suite: execute-end`.

## Run interdicts
- Only these four files change, plus this plan and `docs/verif/s63-review-texts.md`: `method/skills/review-antihallu/SKILL.md`, `method/skills/review-lenses/SKILL.md`, `tests/ownership.test.sh` and `tests/review-lenses.test.sh`. No new test file: it would fall outside `Owns`.
- Empty diff on these files, each owned by a running or queued story:
  - `method/templates/review.md` (s69);
  - `method/hooks/po-gate.sh` and `tests/qa-gate.test.sh` (s67);
  - `method/commands/po-drive.md` and `method/commands/po-review.md` (s64);
  - `method/agents/reviewer.md`;
  - `docs/parite-killer-saas.md` (s68).
- No edit under `.claude/` or `.polype/` (installed copies). No ADR: the story itself settles the scope rule, so ADR-0040 stays unused.
- Existing assertions are unchanged. The test edits only add functions. These phrases survive verbatim:
  - `tests/ownership.test.sh:20-38`, `:60`;
  - `tests/qa-gate.test.sh:101-103`;
  - `tests/review.test.sh:31-32`;
  - `tests/floor-guard.test.sh:192-196`.
  Step 1 still holds `po-gate qa-current <id>`. The skill still has exactly six `**N. ` step lines.
- The `po-gate` behaviour is not changed. The skills describe it and do not redefine it.
- `tests/overlap.test.sh` stays green: write the new sentences in your own words (ADR-0006).

## Files touched
`method/skills/review-antihallu/SKILL.md`, `method/skills/review-lenses/SKILL.md`, `tests/ownership.test.sh`, `tests/review-lenses.test.sh`, `docs/plans/s63-review-texts.md`, `docs/verif/s63-review-texts.md`.

## Test strategy
Four tests, one per criterion, each named after its criterion; the budget is 25. The layer is the method text itself: each test quotes the clause the criterion adds, inside the section or step where it must live, so moving the clause elsewhere also fails. Criteria 2 and 3 replace a wrong sentence, so their tests also assert that the old phrase is gone. Without that, an implementer could add the new sentence beside the contradiction and the test would still pass. No behaviour test of `po-gate`: the gate is unchanged, and `tests/qa-gate.test.sh` already covers it.

## Done when
- The four new tests pass, and the related suites and the full suite are green, recorded through `po-run` in `docs/verif/s63-review-texts.md`.
- The diff stays inside `Owns` plus this story's evidence.
- There is one story commit, and a review with no open critical finding.
