---
validated: yes
---
# Plan — s149-planner-writes-the-oracle

[Story](../stories.md) · [Research](../research/s149-planner-writes-the-oracle.md)

Branch `story/s149-planner-writes-the-oracle`. Read `docs/research/s149-planner-writes-the-oracle.md` first; this plan builds on it without repeating it.

## Story
The planner writes a story's acceptance tests, called the oracle, from its criteria and before any code. They go in files of their own, listed with their `cksum` in the plan's `## Acceptance tests`. The implementer changes them only with a line under `## Oracle changes` of the verification record, which the reviewer judges.

The seven criteria are each a test function of `tests/planner-writes-the-oracle.test.sh`:
- `plan_lists_its_oracle`
- `oracle_lives_in_its_own_files`
- `planner_writes_oracle_files`
- `oracle_files_are_expected_work`
- `implementer_keeps_the_oracle`
- `oracle_runs_with_its_task`
- `adr_records_the_oracle`

The owner made the decision itself (M17 header of `docs/stories.md`, 2026-11-10), and the story lists the options it turned down. No technical choice is left open, so ADR-0098 is written `status: accepted`, as ADR-0097 was for s147. This story writes no oracle of its own: the mechanism lands with it, and its `Owns` holds no `.oracle.test.sh`.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Oracle checksum format | Already in this repository: `cksum < <file>` (`bin/polype:144`, `tests/installer.test.sh:92`) | — |
| `## Acceptance tests` section, `## Oracle changes` section, ADR | Templates already in the repository: `method/templates/plan.md`, `method/templates/verification-record.md`, `method/templates/adr.md`, the style of ADR-0097 | — |
| Expected-work sentence of `/po-execute` and `/po-orchestrator` | Already in this repository: the design sentence (`method/commands/po-execute.md:50`, `method/commands/po-orchestrator.md:62`), used as the model | — |
| Test helpers `section_of`, `holds`, `line_of` | Already in this repository: copied as defined in `tests/reuse-ladder.test.sh:14-18` | `tests/lib.sh` does not carry them, and it is outside `Owns` |

## Tasks
Wording may change, except for the phrases the tests quote, which are given here in backticks or quotes. Every frozen phrase listed in the research's `## Traps` stays word for word.

1. [x] **`## Acceptance tests` in both plan templates.**
   - **Where.** Insert the section in `method/templates/plan.md` and `method/templates/plan-flow.md`, right after the `## Reuse` table and before `## Tasks`. The section text is identical in both files.
   - **The instruction placeholder** says:
     - The oracle is the tests the plan's author wrote from the story's acceptance criteria, before any code, in files of their own that the story's `Owns` lists. Each test goes "through the interface the tasks below fix, never an internal detail".
     - "One test per acceptance criterion that a test can check, each counted in `Test budget`".
     - The implementer adds its own tests to other files, so no sum moves. It changes an oracle file only through `## Oracle changes` of the verification record.
     - "`—` with its reason" replaces both tables for a story where no criterion can be checked by a test (purely visual), or for an exploration story, which its measure judges.
   - **Two tables follow:**
     - `| Oracle file | cksum |`, with a row ``| `<path>` | `<crc> <size>` |``, the second cell being exactly what `cksum < <path>` prints, taken once the file is written.
     - `| Criterion | Test |`, with one row per criterion.
   - **Constraint.** plan-flow stays under 150 lines.
   - **Test:** `plan_lists_its_oracle`.
2. [x] **Polype's convention.**
   - **Where.** `AGENTS.local.md:59`. Keep the bullet's existing text and add, after "An acceptance criterion's name is its test function's name.", a sentence of this shape: "The functions of a story's criteria are its oracle: they go in `tests/<story-slug>.oracle.test.sh`, written by the planner, and the story's other tests in `tests/<story-slug>.test.sh`, which exists only when it holds at least one test (`tests/run.sh` fails a file with no `test_` function)."
   - **Constraint.** No settings block changes.
   - **Test:** `oracle_lives_in_its_own_files` (the convention part).
3. [x] **The planner writes the oracle.** `method/agents/planner.md`.
   - **Limits.** In `## Limits`, the bullet at `:55` stays word for word. Right after "No source file, no test file, no commit: writing the code is the implementer's job and judging it is the reviewer's.", add a new bullet:
     - It opens with "**The oracle is the one exception.**" Before the plan, you write the acceptance tests that `## Acceptance tests` of the plan names, and no other test file. You compute each file's sum with `cksum < <file>` once it is final.
     - "each test goes through the interface the plan's tasks fix", never an internal detail.
     - An oracle file the story's `Owns` does not list is not written. You report it as a gap in the story, and that criterion's row says so.
   - **State check.** At `:22`, the state check also accepts "the oracle files that `## Acceptance tests` of the plan on disk names". The existing words "other than `docs/research/<id>.md` and `docs/plans/<id>.md`" stay; append the clause after them.
   - **Plan contract.** In `## The contracts you carry`, the **Plan** bullet (`:40`) and the **Short track** bullet (`:41`) each gain "an `## Acceptance tests` section". The `## Reuse` wording quoted by `tests/reuse-ladder.test.sh:58` stays.
   - **Tests:** `planner_writes_oracle_files`, `oracle_files_are_expected_work` (the planner part), `oracle_lives_in_its_own_files` (the gap part).
4. [x] **`/po-plan` and `/po-flow` write it in their own context.**
   - **`/po-plan`.** In `method/commands/po-plan.md` `## Writing the plan`, add a bullet after the `Test budget` bullet (`:40`). It says the oracle, as `## Acceptance tests` of the template describes: write the oracle files and "no other test file", each test through the interface the tasks fix; an oracle file outside the story's `Owns` is reported as a gap of the story instead of being written; record each sum with `cksum < <file>`.
   - **`/po-flow`.** In `method/commands/po-flow.md` `## The plan` (`:65`), the same sentence, shortened, with `templates/plan-flow.md`. Also turn "Leave the plan uncommitted" (`:67`) into "Leave the plan and its oracle files uncommitted".
   - **Tests:** `planner_writes_oracle_files` (both commands).
5. [x] **Law 4 counts the oracle as expected work.** In `method/AGENTS.md:105`, keep "legitimately holds uncommitted work under `docs/`" and the list as they are. Before "Anything else uncommitted", add: "and, outside `docs/`, the oracle files that `## Acceptance tests` of the plan names, until the implementer commits them with the story." — Test: `oracle_files_are_expected_work` (Law 4 part).
6. [x] **`## Oracle changes` in the verification record.**
   - **Where.** In `method/templates/verification-record.md`, put a new section `## Oracle changes` between the `## Checks` explanation (`:21`) and `## Not proven here`.
   - **Content.** A table `| Oracle file | What changes | Why |`, then one sentence: each change the implementer makes to a file `## Acceptance tests` names gets one row here, and the reviewer judges it; no row means no oracle file changed.
   - **Paragraph `:7`.** It names `## Oracle changes` among the implementer's lines. `## Runs` stays the last section.
   - **Constraint.** No other line changes.
   - **Test:** `implementer_keeps_the_oracle` (template part).
7. [x] **The implementer keeps the oracle.** `method/agents/implementer.md`.
   - **`:24`.** The list gains "the oracle files that `## Acceptance tests` of the plan names". The words "on a fix run, `docs/reviews/<id>.md`: those are expected" and "Any other change you did not make → stop and report." stay.
   - **`:41`.** The list of own lines adds `## Oracle changes`.
   - **`:46`.** The first-run commit lists "the oracle files".
   - **New `## Limits` bullet:**
     - You change an oracle file only by adding its row under `## Oracle changes` of the record, naming the file, what changes and why. Your own tests go in other files.
     - An oracle that looks wrong to you, with no reason you can write down, stops the task, and you report it.
     - "You never rewrite an oracle to make it pass."
   - **Test:** `implementer_keeps_the_oracle` (agent part), `oracle_files_are_expected_work` (implementer part).
8. [x] **`/po-execute` and `/po-orchestrator` announce the oracle.**
   - **`/po-execute`.** In `method/commands/po-execute.md`, add precondition 9, read without a shell: the story **has an oracle** when the `## Acceptance tests` section of `docs/plans/<id>.md` names at least one file. In Delegation, after the design sentence (`:48-50`, unchanged), add: "When the story has an oracle, append:" followed by a quoted sentence. That sentence is the same in both files. It is a single line starting with `> This story has an oracle:` and holds "is expected uncommitted work, like the research and the plan", "change one only through `## Oracle changes` of docs/verif/<id>.md" and "commit them with the story".
   - **`/po-orchestrator`.** In `method/commands/po-orchestrator.md` Stage 5, add the same condition and the same sentence after `:61-62`.
   - **Tests:** `oracle_files_are_expected_work` (both commands, the sentence equal in both).
9. [x] **Doctrine, ADR-0098, test file, checks.**
   - **(a) Doctrine.** In `method/skills/testing-doctrine/SKILL.md`, add a sentence at the end of "No red-first while implementing": the acceptance tests the plan lists come from another context than the code, the planner's, so nobody runs them red first; "an oracle test runs with the task that makes it passable", like any task test. In `## How many tests?`, add: the oracle's tests count in `Test budget`, one per criterion a test can check. The existing text, headings and the six shapes stay.
   - **(b) ADR-0098.** Write `docs/decisions/ADR-0098-le-planner-ecrit-l-oracle-d-acceptation.md` in French, from `templates/adr.md`.
     - **Frontmatter:** `adr: 0098`, `status: accepted`, `date: 2026-11-10`, `scope: story s149-planner-writes-the-oracle`, `supersedes: []`, `superseded-by: []`.
     - **Context:** issue #152; tests written by the code's author (`method/agents/planner.md:55` at c4a8483); *Bite* (ADR-0012).
     - **Considered Options**, in this order:
       - **A.** The planner writes the acceptance oracle in its own files; the implementer changes it only with a logged reason the reviewer judges. Retained, by the owner, 2026-11-10.
       - **B.** A dedicated oracle agent. Écartée: one more stage and context for every story.
       - **C.** The reviewer as a black box. Écartée: a gap found only at review, at the price of a fix loop.
       - **D.** Change nothing. Écartée: *Bite* finds a poorly tested rule, not a criterion misread by whoever wrote the code and its tests.
     - **Decision Outcome:**
       - It says it "complète l'ADR-0012 sans la remplacer".
       - It says the sum check (s150) guards against error, not against an implementer who would also rewrite the sum, as ADR-0052 says of `po-bounds`.
     - **Constraint.** No other ADR is edited.
   - **(c) Test file.** Write `tests/planner-writes-the-oracle.test.sh` with the seven functions of `## Test strategy`.
   - **(d) Checks.** Run it alone (`bash tests/run.sh planner-writes-the-oracle.test.sh`), then the focused frozen-phrase files: `planner.test.sh drive.test.sh plan.test.sh flow.test.sh execute.test.sh reuse-ladder.test.sh surface-routing.test.sh run-ledger.test.sh structure.test.sh design-handoff.test.sh wiring.test.sh tests-beyond-examples.test.sh escalation-contract.test.sh overlap.test.sh`. Then the full unit suite once through `po-run`. `Typecheck` is `—`.
   - **Tests:** `oracle_runs_with_its_task`, `adr_records_the_oracle`.

## Scene viewpoints
—

## Run interdicts
- Empty diff:
  - `tests/` apart from the new `tests/planner-writes-the-oracle.test.sh`. No existing test is edited, and no `.oracle.test.sh` is created by this story.
  - `.claude/`, `.polype/` and the root `AGENTS.md`, which are installed copies.
  - `method/hooks/`, `method/skills/review-antihallu/` (s150).
  - `method/templates/stories.md`.
  - `docs/parite-killer-saas.md`.
  - `docs/decisions/` apart from ADR-0098.
- These sentences survive verbatim:
  - `planner.md`: "the ADR that number names — and no other file. No source file, no test file, no commit".
  - `method/AGENTS.md`: "legitimately holds uncommitted work under `docs/`".
  - `implementer.md`: "on a fix run, `docs/reviews/<id>.md`: those are expected".
  - The design sentence of `/po-execute` and `/po-orchestrator`.
  - "Disabling guards on purpose is the reviewer's job".
- `po-execute.md` gains no Write, Edit or Bash tool: the oracle is detected by reading the plan.
- No new setting and no `Reads settings:` change in any file.
- `## Runs` stays the last section of the record template, and nothing makes `## Oracle changes` mandatory for a record (`po-gate` and `po-run` are not touched).

## The pivot
The oracle enters as an **exception added beside frozen sentences** that still say "no test file", rather than by rewriting them, because the tests freezing them (`tests/planner.test.sh:46`, `tests/drive.test.sh:226`) are outside `Owns`. Three ways this could go wrong:
1. **The exception reads as contradicting the rule.** Compare the `## Limits` of `planner.md` after the change. A reader must find the oracle bullet directly after the frozen one, opening on "the one exception". If it is elsewhere, the planner may obey the first sentence and write no oracle.
2. **The checksum format does not fit s150.** s150 will compare `cksum < <file>` output to the second cell of `| Oracle file | cksum |`. Compare the template row with `bin/polype:144`. A `cksum <file>` form, which adds the path, or a different header would break the future gate silently.
3. **The expected-work lists drift apart.** Law 4, the planner state check, the implementer's list and the two prompts must all name the same thing: "the oracle files that `## Acceptance tests` of the plan names". Grep that phrase across the five files. Any file that phrases it as "`tests/`" or ".oracle.test.sh" instead binds every project to Polype's own naming.

## Files touched
- `method/templates/plan.md`
- `method/templates/plan-flow.md`
- `AGENTS.local.md`
- `method/agents/planner.md`
- `method/commands/po-plan.md`
- `method/commands/po-flow.md`
- `method/AGENTS.md`
- `method/templates/verification-record.md`
- `method/agents/implementer.md`
- `method/commands/po-execute.md`
- `method/commands/po-orchestrator.md`
- `method/skills/testing-doctrine/SKILL.md`
- `docs/decisions/ADR-0098-le-planner-ecrit-l-oracle-d-acceptation.md`
- `tests/planner-writes-the-oracle.test.sh`
- This story's `docs/research/`, `docs/plans/` and `docs/verif/` files.

## Test strategy
Seven bash tests, one per criterion, all in `tests/planner-writes-the-oracle.test.sh`, within `Test budget: 25`. Each quotes short exact phrases of the file under test, by the repository convention. Section-scoped checks use `section_of`/`holds`, so that a phrase moved out of its section fails.

- `plan_lists_its_oracle`:
  - Both templates have the line `## Acceptance tests`, with its line number between `## Reuse` and `## Tasks`, and the section text is identical in both.
  - The section holds `cksum < <path>`, `| Oracle file | cksum |`, `| Criterion | Test |`, "counted in `Test budget`" and "`—` with its reason".
- `oracle_lives_in_its_own_files`:
  - `AGENTS.local.md` holds `tests/<story-slug>.oracle.test.sh` and "which exists only when it holds at least one test".
  - The planner's `## Limits` holds the gap clause for an oracle outside `Owns`.
  - The template section says the implementer's own tests go in other files.
- `planner_writes_oracle_files`:
  - The planner's `## Limits` holds "**The oracle is the one exception.**", "no other test file" and "each test goes through the interface the plan's tasks fix".
  - The `## Writing the plan` section of `po-plan.md` and the `## The plan` section of `po-flow.md` each hold "no other test file" and `## Acceptance tests`.
- `oracle_files_are_expected_work`:
  - The phrase "the oracle files that `## Acceptance tests` of the plan names" appears in `method/AGENTS.md`, in `planner.md` on the line of its `git -C <path> status --porcelain` check, and in `implementer.md` on its `status --porcelain` line.
  - The `> This story has an oracle:` line is byte-identical in `po-execute.md` and `po-orchestrator.md`, and holds "is expected uncommitted work".
- `implementer_keeps_the_oracle`:
  - The record template has `## Oracle changes` before `## Runs`, holding `| Oracle file | What changes | Why |`.
  - The `## Limits` of `implementer.md` holds `## Oracle changes`, "stops the task" and "You never rewrite an oracle to make it pass."
- `oracle_runs_with_its_task`:
  - The doctrine's "No red-first while implementing" section still holds "Disabling guards on purpose is the reviewer's job".
  - It also holds "an oracle test runs with the task that makes it passable" and names the planner's context.
- `adr_records_the_oracle`:
  - The ADR file exists, with `status: accepted` and `supersedes: []`.
  - Its `## Considered Options` holds, in this order, the lines for the dedicated agent, the black-box reviewer and changing nothing, with exactly three "Écartée".
  - Its outcome holds "sans la remplacer" and "ADR-0052".

Bite targets for the reviewer: drop the oracle bullet from the planner's Limits, the Law 4 clause or the `## Oracle changes` section, and the matching test must fail. No visual checks: no screen.

## Done when
- The seven tests pass, and the full suite passes through `po-run` on the final tree.
- Every frozen phrase of the research's `## Traps` still holds.
- `docs/verif/s149-planner-writes-the-oracle.md` is complete.
- One commit `s149-planner-writes-the-oracle: Le planner écrit les tests d'acceptation de la story` carries the research, the plan, the record and the code.
- The review has no open critical finding, and the story lands through a pull request.
