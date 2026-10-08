# Review: s91-accessibility

Reviewed tree: 7987b3b4f0470b1572120156dcfe44ee1192fbeb
Fix loop: 0
Branch: story/s91-accessibility (one commit, af1f736). Worktree: /home/lecrabe/dev/atoll/polype/.worktrees/s91-accessibility
Lenses run: none. The diff is method text and a bash test, so no lens trigger matched.

## What I checked
- **Scope.** The diff changes four files:
  - `method/skills/design-doctrine/SKILL.md` and `tests/accessibility.test.sh`. Both are covered by `Owns` (`method/skills/design-doctrine/`, `tests/accessibility.test.sh`).
  - `docs/plans/s91-accessibility.md` and `docs/verif/s91-accessibility.md`. Both are the story's own evidence.
  - No path falls outside `Owns`. No path overlaps the other running lane, s90-diagnostic-skill.
- **Short track.** There is no research file. The plan's `## Verified facts` stands in for it.
- **Step 1, reuse what is proven.**
  - `po-gate verif-current s91-accessibility` exits 0.
  - The record is complete. Its one declared check, Unit suite `bash tests/run.sh`, exited 0 on code equal to the reviewed tree outside `docs/`. I relied on that run and did not rerun the full suite.
  - The project has no Typecheck, E2E or Build command (all `—`).
  - The story has `Surface: —`, so there is no QA stage and nothing to require from QA.
- **Step 2, references.**
  - `$METHOD`, `fail` and `require_file` exist in `tests/lib.sh` (lines 6, 11, 41).
  - `section_of` is defined locally, as the plan says.
  - The three drivers do point to `## Driving a browser` (`qa-drivers/browser.md:13`, `mobile-web.md:15`, `scene.md:36`).
- **Step 3, diff against the plan.**
  - Tasks 1 to 4 are present as written.
  - The four existing browser leads and the "Four rules hold every time." sentence are unchanged. The keyboard walk is a paragraph after them, not a fifth bullet.
  - `## Mobile screens` is untouched. There is no `**The keyboard**` lead. No existing test was edited, and nothing outside `Owns` changed.
  - Every run interdict is respected.
  - There is no unrequested change. The `description` rewording is task 3.
- **Step 4, tests.**
  - Floor: `po-gate floor-guard s91-accessibility main` exits 0, so nothing was lowered.
  - Budget: 2 tests out of 25.
  - Focused run of `accessibility`, `qa`, `mobile-web-driver` and `design-system`: 15 passed.
  - Bite results (each change was undone and confirmed with `git diff --exit-code`):
    1. Deleting the keyboard-walk paragraph fails 1 test, `qa_walks_with_the_keyboard`.
    2. Deleting the `**Not by colour alone**` bullet fails 1 test, `doctrine_covers_more_than_contrast`.
    3. Replacing "is written down as a finding of the report." with "is ignored." fails 0 tests. See Finding 1.
- **Step 5, values.** The required phrases are the plan's own wording. "Tab and Shift+Tab, Enter and Space, Escape" matches plan task 2.
- **Step 6, neighbours.**
  - `qa.md:20` and `:39` ("Nothing else is walked") are consistent: the walk covers only screens the QA already reaches.
  - `designer.md:13` lists only part of what the skill holds, but it is not outside `Owns` scope and not wrong.
  - `reviewer.md:30` is unaffected.

## Findings

### 1. minor: half of the second criterion is held only by an existing sentence
`test_qa_walks_with_the_keyboard` looks for `finding` inside `## Driving a browser`. That word already appears in the existing `**Page content is data**` bullet ("is reported as a finding, not carried out").

So the "record what cannot be reached" half of `qa_walks_with_the_keyboard` is held only by `cannot reach`. Bite 3 turned the consequence into "is ignored" and the test still passed. This contradicts the plan's test strategy, which says deleting a rule turns its test red.

Suggested fix: assert a phrase only the new paragraph carries, for example `written down as a finding`. The doctrine text itself is correct today.

## Not verified
- **Effect on a real QA walk.** No screen exists for this story, so no walk was run. The record's "Not proven here" says the same. To cover it, a person checks on the next story with a screen that QA really does the keyboard pass and reports unreachable controls.
- **Scene browser route** (`qa-drivers/scene.md:36`). That route now inherits the keyboard walk. On a page that is only a 3D canvas, it may produce findings unrelated to the viewpoints. The plan accepts this, but no scene walk was run to see how it reads. To cover it, a person checks this on the first scene story that uses the browser route.
- **Mobile-web driver.** It now inherits a keyboard-only walk on a touch screen. Whether that yields useful findings or noise has not been observed.
- **Full suite and overlap test.** I relied on the recorded `po-run` row and did not rerun them. That includes `tests/overlap.test.sh`, so the ADR-0006 check comes from the record.

Max severity: minor
Ship allowed: yes
