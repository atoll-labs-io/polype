# Review — s148-tests-beyond-examples

[Story](../stories.md) · [Plan](../plans/s148-tests-beyond-examples.md) · [Verification](../verif/s148-tests-beyond-examples.md)

Diff reviewed: `git diff main...story/s148-tests-beyond-examples`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 53da49fe29f89e7abf916335764d1d30c91f3fa7

## Ownership
I listed the diff with `git diff --name-only main...story/s148-tests-beyond-examples`: `docs/plans/s148-tests-beyond-examples.md` (A), `docs/verif/s148-tests-beyond-examples.md` (A), `method/skills/testing-doctrine/SKILL.md` (M), `tests/tests-beyond-examples.test.sh` (A).
- [x] Every path is inside `Owns`. The two docs are the story's own pipeline evidence, and the other two paths match the `Owns` line exactly.
- [x] No path is outside `Owns`.
- [x] No path is inside another running story's `Owns`. The only other running worktree is s147-strict-checks-by-default. Its `Owns` (profile templates, `bin/po-lint`, `po-architect.md`, architecture template, ADR-0097, its own test) has nothing in common with this diff. s149 also owns `testing-doctrine/SKILL.md`, but s149 has no worktree and depends on s148.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s148-tests-beyond-examples` gave exit 0, so I reused the record. It holds one `Unit suite` run of `bash tests/run.sh`, exit 0, on tree c6cd09d…, which is the committed code outside `docs/`. The project's `Typecheck` is `—`, so there is no type check. The record's "Not proven here" section says no text test can show an agent actually picking a property test.
- [x] `po-gate qa-current` was not required: the story does not go to QA (`Surface: —`, `QA stage: —`).

## Plan
- [x] Tasks 1–5 are all present, and nothing in the diff falls outside the plan.
  - Task 1: the `## Beyond examples` section is placed after the `## Which layer?` table and has three bold-led paragraphs with the planned phrases.
  - Task 2: `## Real services over hand-written mocks` is in place.
  - Task 3: one new table row, `Long fuzzing or simulation campaign`.
  - Task 4: the new test file with five functions named after the criteria.
  - Task 5: the record.
- [x] I checked each run interdict:
  - The existing sections of the skill only gain lines; none are removed.
  - `## Tests that prove nothing` is untouched and still has six numbered lines.
  - The table gains one row and loses none. Its intro and closing prose are unchanged.
  - No library name appears in the skill. FoundationDB is named as a system, as the plan allows.
  - The frontmatter is unchanged.
  - `review-antihallu`, `method/agents`, `method/templates`, `method/AGENTS.md`, `.claude/`, `.polype/` and `docs/stories.md` all have an empty diff.
  - No ADR-0098 file was added, and no existing test was edited.

## References
- [x] I opened every reference and confirmed it.
  - `tests/lib.sh`: `fail` exits the test's own process, and `METHOD` resolves to `$ROOT/method`.
  - `tests/run.sh`: each test runs in its own `bash -c "set -eu; ..."`, so the file-local helpers `section_of` and `holds` cannot clash with the same names in other test files.
  - `! grep … || fail` and `row=$(…) || fail` behave correctly under `set -e`.
  - The skill's text is consistent with `review-antihallu` ("six kinds of test that prove nothing").
- [x] No value only looks right. Shape 6 is the mock shape (`SKILL.md`, the sixth numbered line, "A **mock** reproduces the condition…"). The phrase "a sentence in the plan's test strategy" matches the existing budget mechanism in `## How many tests?`.

## Rules
- [x] `AGENTS.md` conventions are respected.
  - The method text is in English.
  - The bash test has one function per criterion, named after it.
  - The text is in the project's own words: `overlap.test.sh` is green in the recorded full suite.
- [x] No accepted ADR is contradicted. The new row cites Law 7 as a whole, which keeps the ADR-0090 security exception rather than overriding it.

## Tests
- [x] Floor: `po-gate floor-guard s148-tests-beyond-examples main` gave exit 0, so nothing was lowered.
- [x] The assertions pin down the five criteria, each scoped to its own section through `section_of`. None of the six empty test shapes appears: the tests read the real file under test, with no fixture or mock.
- [x] 5 tests, within `Test budget` 25.
- [x] Bite. I made three mutations and ran only `bash tests/run.sh tests-beyond-examples.test.sh` after each. After every one, `git checkout --` then `git diff --exit-code` came back clean.
  - Replaced "It counts as one test in `Test budget`…" with "Each drawn input counts as a test." → 1 failing test (`doctrine_says_when_property_tests`).
  - Deleted the `| Long fuzzing or simulation campaign |` row → 1 failing test (`long_campaigns_run_outside_stories`).
  - Replaced "the reviewer reports it under shape 6 of `## Tests that prove nothing`" with "it is fine" → 1 failing test (`real_service_over_handwritten_mock`).
- [x] No test became useless because of this story.

## Neighbours
- [x] Other users of the skill read; nothing broken.
  - `review-antihallu` step 4 points to the six shapes and is unchanged.
  - The phrases frozen in `plan.test.sh`, `leftovers.test.sh`, `run-ledger.test.sh` and `hooks-installer-docs-cleanup.test.sh` are unchanged, and the full suite passed in the record.

## Lenses
Lenses run: none. The diff is a markdown skill and a bash text test: no auth or routes, no migration, no lockfile or manifest, no server-side code.
- [x] There are no lens findings to grade.

## Findings
- minor — method/skills/testing-doctrine/SKILL.md:39 — The real-service rule refers to "shape 6" by position. Nothing ties that number to the mock shape.
  If `## Tests that prove nothing` is ever reordered or renumbered, the reference silently points at the wrong shape. `test_real_service_over_handwritten_mock` checks only the literal phrase "under shape 6 of …", not that the sixth line is still the mock one.
  The rule also widens shape 6 a little: an unargued hand-written mock is not necessarily "a mock that reproduces the condition it was supposed to evaluate".
  The story text asks for this wording, so this is a note for later, not a defect.
- minor — tests/tests-beyond-examples.test.sh:48 — `grep -F '| Long fuzzing or simulation campaign |'` matches that text anywhere in a line. The plan (task 4) asked for a line that *starts* with it.
  It makes no practical difference today, but the check is a little looser than the plan says.

## Not verified
- Whether a planner, implementer or reviewer actually acts on the new doctrine: picks a property test, fuzzing or simulation when it should, or flags an unargued hand-written mock under shape 6. This is agent behaviour, and no text test sees it; the record says the same. To cover it, a person should look at the plan and review of the next story that touches a parser, a decoder or a distributed behaviour once this doctrine is installed.
- I did not rerun the full suite. I relied on the current record (`po-gate verif-current` passed), as `Verification mode: record` allows.
- There is no type check, end-to-end test or build: the project has none (`Typecheck: —`, `E2E: —`, `Build: —`).
- The installed copies under `.claude/` and `.polype/` will only carry the new text after the next install. This story correctly leaves them alone, so I did not check them.

Max severity: minor
Ship allowed: yes
