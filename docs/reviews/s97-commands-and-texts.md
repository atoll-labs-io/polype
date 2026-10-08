# Review: s97-commands-and-texts

Reviewed tree: bbd6e06c258a8dbd33732f25991db5e7ee995a90
Fix loop: 0
Review status: complete
Lenses run: none. The diff is only method prose, docs and bash tests. It touches no auth, migration, lockfile or server code.

## Scope (`Owns`)
`git diff --name-only main...story/s97-commands-and-texts` lists 11 paths:
- **Covered by s97's `Owns`:** `method/commands/po-retro.md`, `po-setup.md`, `po-help.md`, `method/skills/stories-review/SKILL.md`, `docs/parite-killer-saas.md`, `docs/stories.md`, `tests/accessibility.test.sh` and `tests/commands-and-texts.test.sh` (new).
- **In scope as pipeline evidence:** `docs/plans/`, `docs/research/` and `docs/verif/` for s97.
- **No path outside `Owns`.**
- **No overlap with other running work.** The only other active worktree is s98-bounds-messages. Its `Owns` (po-bounds.sh, implementer.md, installation.md, tests/bounds*, ADR-0050, ADR-0052) shares no path with this diff.
- **Run interdicts hold:**
  - No ADR, template, agent, `AGENTS.md`, `po-flow.md`, `boilerplates/`, `.claude/` or `.polype/` file is touched.
  - `docs/stories.md` changes only on the s83 Expo criterion line.
  - `docs/parite-killer-saas.md` changes only on row D15, which keeps its `fait — …` cell.
  - `tests/accessibility.test.sh` changes only the phrase on line 23.
  - The body of step 2 in `po-setup.md` is unchanged.
  - `/po-retro` gains no tool and no `git log`.

## Evidence reused
- **Unit suite (`bash tests/run.sh`):** `po-gate verif-current s97-commands-and-texts` exits 0 (`Verification mode: record`). The record is complete and its only `## Runs` row, `Unit suite`, exited 0. I did not rerun the full suite.
- **No type check, end to end or build:** the project sets `Typecheck`, `E2E` and `Build` to `—`.
- **QA:** the story's `Surface` is `—`, so it does not go to QA and none was required.
- **Floor guard:** `po-gate floor-guard s97-commands-and-texts main` exits 0, so no check was lowered. The only change to an existing test makes it stricter: `'finding'` becomes `'written down as a finding'`.
- **Baseline:** before any mutation, the focused files (commands-and-texts, po-retro, accessibility, stories-review) gave 16 passed, 0 failed.

## Plan conformity
All six tasks are done as the plan wrote them.

**Retro milestone match (task 1).** The argument is matched in three steps: exact title, then label, then prefix. Against the real headings of `docs/stories.md` (lines 882, 917, 1066, 1191, 1390, 1408):
- `M8` resolves to line 1191 by its label.
- `M7` resolves to line 917 by its label.
- `Correctifs hors jalon` resolves to line 882 by exact title.

**Retro majors (task 2).** The `**majors still open**` row now reads the last review that is not blocked. It keeps the pinned phrase `open by the last review`. On ADR-0067:
- ADR-0067 says a major is open when it appears in « la dernière revue de sa story ». The new rule narrows that to a review that is not blocked.
- A blocked report is "a blocked report instead of a verdict" (reviewer.md), so the narrowing is a precision, not a contradiction.
- The plan argues this under "The pivot", as the story's notes asked.

**Check 10 of the stories review (task 3).** It is worded in the project's own terms, with no Polype path. It is listed as a major and added to the frontmatter description. Its exception for review files means s96, s97 and s98 are not flagged.

**Text fixes (task 4).** These match the method:
- The step 2 heading of `/po-setup` now matches the step's body (lines 37-43).
- The `/po-help` sentence matches `method/AGENTS.md:41`.
- D15 now has six signals and no number.
- The Expo criterion matches ADR-0062 and ADR-0069.

**Tests (tasks 5 and 6).** `tests/qa-fleet.test.sh` still passes, so its pinned `/po-help` phrases are intact.

## Bite proof
I disabled one rule at a time and ran only the test files that exercise it. After each run I restored the file with `git checkout -- <file>`; `git diff --exit-code` was clean every time.

| # | Rule disabled | Files run | Tests failed |
|---|---|---|---|
| 1 | Prefix step (c) moved before exact step (a) in `po-retro.md` Scope | commands-and-texts, po-retro | 1 (`retro_prefers_an_exact_milestone`) |
| 2 | Clause (ii), the superseded ADR, removed from check 10 | commands-and-texts, stories-review | 1 (`stories_review_checks_owned_records`) |
| 3 | In design-doctrine, the keyboard result changed from "written down as a finding" to "ignored" | accessibility, commands-and-texts | 2 (`qa_walks_with_the_keyboard`, `keyboard_walk_test_bites`) |
| 4 | Review-file exception removed from check 10 (i) | commands-and-texts, stories-review | 1 (it bites only because `Owns` appears nowhere else in check 10, see m3) |
| 5 | "All reviews blocked gives 'no review judged the findings', never zero" removed from the majors row | commands-and-texts, po-retro | **0** |

There are 4 new test functions and 1 changed phrase, well within the `Test budget` of 25.

## Findings

**m1 — minor — `method/commands/po-retro.md` majors row: one new clause has no test.** The clause `a file whose reviews are all blocked gives "no review judged the findings", never zero` can be deleted and every test still passes (bite 5). That clause is what stops a file whose reviews are all blocked from showing zero open majors, which is the s89 defect. `test_retro_prefers_an_exact_milestone` only asserts `not blocked`. The plan did not promise a test for this clause, which is why it is graded minor.

**m2 — minor — `docs/stories.md:1288` French punctuation.** The text reads `sert le rendu web de l'app; le gabarit…`. It lacks the space before `;` that French typography uses and that the rest of the file, including this story's own text, uses (` ; `).

**m3 — minor — `tests/commands-and-texts.test.sh` test hygiene:**
- In `test_retro_prefers_an_exact_milestone`, the locals `a`, `b` and `c` (line numbers) are computed but never compared; the order is checked through the `${line%%starts with it*}` case instead. The plan's test strategy says "the line of the first precedes the line of the last", which is not what the code does. The order check that is there does bite.
- In `test_stories_review_checks_owned_records`, the `Owns` assertion guards the review-file exception only by accident. Rewording that sentence without the token `Owns` would lose the guard.

## Not verified
- **Behaviour at run time:** whether a model running `/po-retro` applies the three matching steps and the not-blocked rule. The same applies to whether the stories-reviewer applies check 10. The tests only prove the rules are written, and in the right order. To cover it, a person runs `/po-retro M8`, `/po-retro M7` and `/po-retro "Correctifs hors jalon"` on `main` after ship. Each should pick one milestone, not list and stop. They also run `/po-stories-review` on a stories file with one story whose `Fixes` line names a defects file it does not own.
- **The report template does not list check 10.** `method/templates/stories-review.md` has no checkbox for it (nor for check 9). That file is outside `Owns` and the plan forbids touching it, so it is not a finding here. A later story could close the gap.
- **Installed copies not refreshed.** `.claude/` and `.polype/` still hold the pre-story text until a person runs `bin/polype-dev-install .` after ship, as the plan says.
- **Unit suite not rerun by me.** I relied on the `po-run` row of the record, whose tree `verif-current` accepts for this code.

Max severity: minor
Ship allowed: yes
