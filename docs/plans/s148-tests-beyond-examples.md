---
track: flow
validated: yes
---
# Plan (short track) — s148-tests-beyond-examples

[Story](../stories.md)

Written by the planner on the short track (`Story track: auto`, complexity 2 ≤ `Flow threshold` 2). This file stands in for both research and plan: there is no `docs/research/s148-tests-beyond-examples.md`. ADR-0098 was reserved for this lane and is left unused (it belongs to s149 by its `Owns`). Validated autonomously (`Plan validation: autonomous`); no human reviewed it.

## Verified facts
- No assumption of the story proved false. Complexity scored after reading: 2 (text added to one skill, one new test file).
- `method/skills/testing-doctrine/SKILL.md` (64 lines) has, in order: `## How many tests?` (:9), `## Which layer?` (:17, table :19-25), `## Four things to cut` (:27), `## No red-first while implementing` (:34), `## Tests that prove nothing` (:38, six numbered shapes :42-47, shape 6 is the **mock** one at :47), `## When does each check run?` (:49, table :53-60, prose :62-64). Nothing names property tests, fuzzing, simulation or a real service.
- **Trap — the six shapes are counted.** `tests/plan.test.sh:39-40` counts lines matching `^[0-9]\. ` between `## Tests that prove nothing` and the next `## ` heading and requires exactly 6. The real-service rule must not add a numbered line there, nor rewrite shape 6 (the story keeps that section's text).
- Other phrases frozen in the skill: section headings and `is worse than no test` (`tests/plan.test.sh:33-38`); `## No red-first while implementing` and `Disabling guards on purpose is the reviewer's job` (`tests/plan.test.sh:44-45`); `-- '<command>'` (`tests/leftovers.test.sh:5-7`, `tests/hooks-installer-docs-cleanup.test.sh:127`); `po-run --story` (`tests/run-ledger.test.sh:143`). `tests/planner.test.sh:36`, `tests/execute.test.sh:33`, `tests/review.test.sh:18` only check the agents preload the skill. These 27 tests pass on the worktree today (`bash tests/run.sh plan.test.sh leftovers.test.sh run-ledger.test.sh hooks-installer-docs-cleanup.test.sh`).
- The reviewer reaches shape 6 through `method/skills/review-antihallu/SKILL.md:42` ("Check for the six kinds of test that prove nothing, listed in the `testing-doctrine` skill"), so a rule phrased as "reported under shape 6" needs no change to the reviewer.
- The plan's test strategy is a section of both templates (`method/templates/plan.md:35`, `method/templates/plan-flow.md:51`), the place the real-service exception is argued; `## How many tests?` (:11) already uses "a sentence in the plan's test strategy" for the budget excess, the same mechanism.
- Law 7 (`method/AGENTS.md:123-127`) files defects in `Issue tracker` and keeps a security finding off the tracker, sent to the person (ADR-0090, `docs/decisions/ADR-0090-tout-ce-qui-est-a-traiter-devient-une-issue.md`). A fuzzing crash in a decoder can be a security finding, so the new table row cites Law 7 whole rather than only "goes to `Issue tracker`".
- `tests/run.sh:9-15` loads every `tests/*.test.sh` and fails a file without a `test_` function. Test conventions: `tests/lib.sh` helpers (`contains`, `require_file`, `fail`); a local `section_of` as in `tests/resume-shape-stop.test.sh:7`.
- `tests/overlap.test.sh` fails a `method/` line sharing 8+ consecutive words with Killer SaaS (ADR-0006): the new text is written in our own words.
- `docs/parite-killer-saas.md` has no line on property tests, fuzzing or simulation (grep): nothing to update.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text, `Surface: —` | absent — markdown skill and a bash test only |
| New screen | absent — `Surface: —` | absent — no UI in `Owns` |
| Authorization or tenant scope | absent — story text | absent — doctrine prose |
| API contract | absent — story text | absent — no command, hook or setting changes |
| New dependency | absent — story text names kinds, not libraries | absent — the doctrine names no library; the test uses bash/grep/awk |
| Technical choice that deserves an ADR (library, pattern, data model) | absent — choices settled by the owner on 2026-11-10 (`docs/stories.md:2324`) | absent — no new setting, the long-campaign row carries `Setting: —` |
| Defect to fix (`Fixes` or `Corrige` line) | absent — no such line in `docs/stories.md:2344-2359` | absent |

The story does not go to QA (`Surface: —`, `QA stage: —`).

## Story
The testing doctrine says when a story takes a property test, fuzzing or a deterministic simulation with faults, and prefers the real service to a hand-written mock. Criteria (each the name of one test function in `tests/tests-beyond-examples.test.sh`): `doctrine_says_when_property_tests`, `doctrine_says_when_fuzzing`, `doctrine_says_when_simulation`, `real_service_over_handwritten_mock`, `long_campaigns_run_outside_stories`.

## The pivot
Where the real-service rule lives without breaking the six-shape count. Chosen: a section of its own, `## Real services over hand-written mocks`, outside `## Tests that prove nothing`, that sends an unargued mock to "shape 6 of `## Tests that prove nothing`". Could be wrong if a reader expects shape 6 itself to carry it — but the story keeps that section's text and `tests/plan.test.sh:40` pins the count, so editing it would cost two frozen guarantees. Second risk: the long-campaign row saying only "goes to `Issue tracker`" would contradict Law 7's security exception; citing Law 7 whole keeps the two consistent until s154 revisits it.

## Reuse
No new code beyond prose and one test file; the test reuses `tests/lib.sh` helpers and the `section_of` pattern of `tests/resume-shape-stop.test.sh:7`.

## Tasks
1. [x] **`## Beyond examples`** in `method/skills/testing-doctrine/SKILL.md`, a new section placed right after the `## Which layer?` table (before `## Four things to cut`), no numbered list. Opening sentence: an example test checks the inputs someone thought of; three kinds look for the others, and the doctrine names the kind, never a library — the library comes from the project's profile or conventions. Then three bold-led paragraphs, carrying these exact phrases:
   - `**Property test**` — `a rule that holds for every input of a domain`: an encoding's `round trip`, an `invariant` of a computation, `idempotence`; for `pure logic, parsers and serialisers`; `It counts as one test in \`Test budget\``, however many inputs it draws.
   - `**Fuzzing**` — for `code that decodes input coming from outside`: a protocol, a file format, a request; `A story runs only a short campaign with a fixed seed`, so that it replays.
   - `**Deterministic simulation with fault injection**` — for `distributed, time-dependent or robotic behaviour`; faults: `packets lost`, `a node restarted`, `a clock skewed`, `a sensor gone silent`; `A seed makes each failure replayable`; `a failure that does not replay is not a result`. May cite FoundationDB's simulator as the model (a system, not a library).
   No library name anywhere in the skill (proptest, Hypothesis, fast-check, QuickCheck, libFuzzer, cargo-fuzz, AFL). — Fails: `test_doctrine_says_when_property_tests`, `test_doctrine_says_when_fuzzing`, `test_doctrine_says_when_simulation`.
2. [x] **`## Real services over hand-written mocks`**, right after `## Beyond examples`: `A persistence or adapter test talks to the real service` — `a container or a local instance` — `when the project can start it`. `A hand-written mock of a service the project owns needs a sentence in the plan's test strategy`; without it, `the reviewer reports it under shape 6 of \`## Tests that prove nothing\``. — Fails: `test_real_service_over_handwritten_mock`.
3. [x] **One row in the `## When does each check run?` table**, appended after `Formatting`: `| Long fuzzing or simulation campaign | outside any story's cycle, on a schedule; its failure goes to \`Issue tracker\` as Law 7 says — the story runs only the short version | — |`. The intro sentence (:51), the other six rows and the prose after the table stay unchanged. — Fails: `test_long_campaigns_run_outside_stories`.
4. [x] **`tests/tests-beyond-examples.test.sh`** (new), header `# s148 — the testing doctrine goes beyond examples.`, `DOC="$METHOD/skills/testing-doctrine/SKILL.md"`, a local `section_of` (as `tests/resume-shape-stop.test.sh:7`), five functions named after the criteria, each checking its phrases **inside its section** (not just anywhere in the file):
   - `test_doctrine_says_when_property_tests`: in `Beyond examples`, `**Property test**`, `a rule that holds for every input of a domain`, `round trip`, `idempotence`, `pure logic, parsers and serialisers`, `It counts as one test in \`Test budget\``; and the whole file matches none of `proptest|Hypothesis|fast-check|QuickCheck|libFuzzer|cargo-fuzz|AFL` (case-sensitive `grep -E`).
   - `test_doctrine_says_when_fuzzing`: in `Beyond examples`, `**Fuzzing**`, `code that decodes input coming from outside`, `A story runs only a short campaign with a fixed seed`.
   - `test_doctrine_says_when_simulation`: in `Beyond examples`, `**Deterministic simulation with fault injection**`, `distributed, time-dependent or robotic behaviour`, the four faults, `A seed makes each failure replayable`, `a failure that does not replay is not a result`.
   - `test_real_service_over_handwritten_mock`: in `Real services over hand-written mocks`, `A persistence or adapter test talks to the real service`, `when the project can start it`, `needs a sentence in the plan's test strategy`, `under shape 6 of \`## Tests that prove nothing\``.
   - `test_long_campaigns_run_outside_stories`: a line of the `When does each check run?` section starting with `| Long fuzzing or simulation campaign |` that holds `on a schedule`, `\`Issue tracker\``, `Law 7` and `the story runs only the short version`.
   Run alone with its neighbours: `bash tests/run.sh tests-beyond-examples.test.sh plan.test.sh leftovers.test.sh run-ledger.test.sh hooks-installer-docs-cleanup.test.sh planner.test.sh execute.test.sh review.test.sh overlap.test.sh`.
5. [x] **Record and suite.** Full suite once through `po-run --story s148-tests-beyond-examples --label 'Unit suite' -- 'bash tests/run.sh'` (`Full suite: execute-end`); `Typecheck: —`, said so in the record.

## Scene viewpoints
—

## Run interdicts
- In `method/skills/testing-doctrine/SKILL.md`, the existing text of `## How many tests?`, `## Which layer?`, `## Four things to cut`, `## No red-first while implementing` and `## Tests that prove nothing` is unchanged: `git diff` shows only added lines there, none removed. `## Tests that prove nothing` still holds exactly six numbered lines (`tests/plan.test.sh:40`).
- The `## When does each check run?` table gains one row and loses none; its intro and closing prose are unchanged.
- No new setting, no library name, no edit to the skill's frontmatter `name`.
- `method/skills/review-antihallu/SKILL.md`, `method/agents/*`, `method/templates/*`, `method/AGENTS.md`: empty diff (s149 owns several of them).
- `.claude/` and `.polype/`: empty diff (installed copies).
- No existing test file edited; `docs/stories.md` not edited; no `docs/decisions/ADR-0098-*` file created.

## Files touched
- `method/skills/testing-doctrine/SKILL.md`
- `tests/tests-beyond-examples.test.sh` (new)
- `docs/verif/s148-tests-beyond-examples.md`
- already written by the planner, committed with the code: this plan

## Test strategy
Five tests, one per criterion, at the only layer there is: the skill's text, read section by section (well within `Test budget` 25). Each bites: removing a paragraph, moving it out of its section, or dropping the row fails its test; a library name slipped into the doctrine fails the first. The six-shape count and the frozen phrases stay guarded by the existing `plan.test.sh`, `leftovers.test.sh`, `run-ledger.test.sh` and `hooks-installer-docs-cleanup.test.sh`, unmodified. Whether an agent actually picks a property test when it should is behaviour no text test sees; it is left to the reviewer's reading, not tested here.

## Done when
One commit on `story/s148-tests-beyond-examples` carrying the skill, the new test file, this plan and a complete record; `bash tests/run.sh` green through `po-run`; a review with no open critical finding; shipped as one squash `s148-tests-beyond-examples: La doctrine de tests va au-delà des exemples`.
