# Review — s63-review-texts

[Story](../stories.md) · [Plan](../plans/s63-review-texts.md) · [Verification](../verif/s63-review-texts.md)

Reviewed tree: 51ad33f5b55728cf4bed26e826b7a7006f2d8917
Fix loop: 0
Worktree: /home/lecrabe/dev/atoll/polype/.worktrees/s63-review-texts (branch `story/s63-review-texts`, commit 0766e22)
Lenses run: none. The diff touches only method markdown under `method/skills/` and bash string tests, so no lens trigger matched.

**Result: no critical finding, no major finding, two minor findings. Ship allowed: yes.**

## Ownership
The diff was listed with `git diff --name-only main...story/s63-review-texts`. Each path was held against the story's `Owns` line: `method/skills/review-antihallu/`, `method/skills/review-lenses/`, `tests/ownership.test.sh`, `tests/review-lenses.test.sh`.
- [x] Every path inside `Owns`. The two skill files and the two test files are owned. `docs/plans/s63-review-texts.md` and `docs/verif/s63-review-texts.md` are the story's own evidence, so they are in scope without being listed.
- [ ] Outside `Owns` → major: none
- [ ] Inside another running story's `Owns` → critical: none. The only other worktree running is s62-bounds-scan. It touches `method/hooks/po-bounds.sh`, `tests/bounds.test.sh`, its own docs and ADR-0039, none of which overlap with this story.
- [ ] No `Owns` line on this story: not the case, the line is present.

## Evidence reused
- [x] `po-gate verif-current s63-review-texts` exited 0, so I reused the record and did not rerun the suite.
  - Record `Tree:` is b1c16df…. Its single `## Runs` row is the Unit suite `bash tests/run.sh`, exit 0, on tree e19f54c…. The gate confirms that this tree's code outside `docs/` matches the record.
  - The project has no Typecheck, E2E or Build command (all `—`).
  - "Not proven here" says the behaviour of `po-gate` is unchanged and is covered by `tests/qa-gate.test.sh`. That is accurate: the diff does not touch `po-gate.sh`.
- [x] `po-gate qa-current`: not required, because the story has no screen.

## Plan
- [x] All five tasks are present, and nothing was changed outside the plan.
- [x] Every run interdict was respected:
  - no diff on `method/templates/review.md`, `po-gate.sh`, `tests/qa-gate.test.sh`, `po-drive.md`, `po-review.md`, `reviewer.md`, `parite-killer-saas.md`, `.claude/` or `.polype/`;
  - no ADR added;
  - existing tests only gained new functions;
  - the skill still has six `**N. ` steps.
- [x] The text matches the gate it describes:
  - Task 3: the manual record check now describes `runs_cover_checks` in `method/hooks/po-gate.sh:105-127` faithfully (same label and command, run tree equal to `<Tree>` outside `docs/`, the last matching row decides).
  - Task 4: the commit command quoted in the skill is the one in the gate's refusal message (`po-gate.sh:144`).
- [x] Neighbours are consistent:
  - The `templates/review.md` line "fails → review blocked" stays true, because the uncommitted-report case is still a blocked review.
  - s64's planned rule ("blocked by QA only when `Next action:` names `/po-qa`") agrees with the new exception, whose `Next action:` does not name `/po-qa`.
  - Nothing else in `method/` repeats the old "diff only" or "same comparison" sentences.

## Tests
- **Floor:** `po-gate floor-guard s63-review-texts main` exited 0, so nothing was lowered.
- **Budget:** four tests, one per criterion, well within 25. None of them proves nothing.
- **Bite.** Each change was undone, and `git diff --exit-code` came back clean after each.

| # | Change | Tests run | Failed |
| --- | --- | --- | --- |
| 1 | Deleted the ADR-in-scope bullet | `ownership.test.sh` | 1 (`story_adrs_are_in_scope_by_construction`) |
| 2 | Removed the uncommitted-QA-report exception sentence | `ownership.test.sh` | 1 |
| 3 | Put back the old line "A lens looks at the diff only, never at the rest of the repository." | `review-lenses.test.sh` | 1 |
| 4 | Removed only the "or a report that is current but not committed" cause from the failure list, keeping the exception sentence | `ownership.test.sh`, `qa-gate.test.sh` | 0 (see m1) |

## Findings
- **m1 (minor):** `test_qa_current_failure_names_an_uncommitted_report` (`tests/ownership.test.sh`) does not check that the new cause sits in the failure list.
  - It looks for `current but not committed` anywhere in step 1, and the exception sentence contains that phrase too.
  - Change 4 above removed the cause from the list and the test stayed green.
  - Checking for `, or a report that is current but not committed — →` would tie the test to the list itself.
- **m2 (minor):** in the new ADR bullet of `method/skills/review-antihallu/SKILL.md`, "names" counts any mention of the file name or the `ADR-NNNN` number in the plan's text.
  - A plan that mentions an ADR only to rule it out would still make that ADR count as in scope if the diff added it anyway. This plan does exactly that: "ADR-0040 stays unused".
  - The risk is small: only added ADRs are covered, and an unwanted ADR would still show up in step 3 (diff against the plan).
  - The wording could require the plan to say the story *writes* the ADR.

## Not verified
- I did not rerun the full suite or `tests/overlap.test.sh` (the check against shared Killer SaaS text). I relied on the passing record instead.
  - To cover it: run `bash tests/run.sh` in the worktree.
- No real review has yet applied the new ADR-in-scope rule or the uncommitted-QA-report routing. This review is the first, and its diff adds no ADR, so neither was exercised.
  - To cover it: on the next story that adds an ADR and has a screen with `QA stage: screens`, check that the review classifies the ADR as in scope and routes an uncommitted report to the evidence commit rather than `/po-qa`.
- Whether the reviewer actually behaves according to the new lens-reach sentence is a matter of model behaviour. The string tests cannot show it.

## Verdict
No critical finding, no major finding, two minor findings. The tree was taken again just before answering and still equals 51ad33f5b55728cf4bed26e826b7a7006f2d8917.

Max severity: minor
Ship allowed: yes
