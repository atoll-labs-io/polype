# Research — s149-planner-writes-the-oracle

[Story](../stories.md)

## Structuring facts
- No assumption of the story is false. Every line it cites holds at `c4a8483`: Law 4's list of legitimate uncommitted work (`method/AGENTS.md:105`), the planner's state check (`method/agents/planner.md:22`), the implementer's list of expected changes (`method/agents/implementer.md:24`), the design sentence used as a model (`method/commands/po-execute.md:50`, `method/commands/po-orchestrator.md:62`), and `tests/run.sh:15` failing a file that has no `test_` function.
- **Frozen phrases contradict the new rule.** `method/agents/planner.md:55` says "No source file, no test file, no commit". `tests/planner.test.sh:46` and `tests/drive.test.sh:224-226` quote that sentence, and both tests are outside this story's `Owns`, so `po-bounds` refuses the implementer an edit to them (`method/hooks/po-bounds.sh:198`). The oracle therefore has to be added as an exception, in a sentence placed right after the frozen one, which stays word for word.
- Law 4 only lists work under `docs/` (`method/AGENTS.md:105`, with the phrase `legitimately holds uncommitted work under \`docs/\`` frozen by `tests/structure.test.sh:59`). Oracle files live under `tests/`, so the paragraph needs one more clause for work outside `docs/`.
- `cksum` is already the checksum of the repository: `sum_of() { cksum < "$1"; }` at `bin/polype:144` prints `<crc> <size>`, with no file name. s150 will parse the format this story fixes, so it is part of the contract.
- This story writes no oracle of its own. The mechanism arrives with it, and its `Owns` holds no `.oracle.test.sh` (`docs/stories.md:2367`). Its tests go in `tests/planner-writes-the-oracle.test.sh`, as before M17.

## Story
The planner writes the story's acceptance tests (the "oracle") from its criteria, before any code, in files that belong to it alone. The implementer changes them only with a logged reason, and that reason is judged by the reviewer. Seven criteria:
`plan_lists_its_oracle`, `oracle_lives_in_its_own_files`, `planner_writes_oracle_files`, `oracle_files_are_expected_work`, `implementer_keeps_the_oracle`, `oracle_runs_with_its_task`, `adr_records_the_oracle` (full text: `docs/stories.md:2361-2378`).

## Current code
- `method/templates/plan.md` (39 lines). Sections: Story `:10`, Reuse `:13-17`, Tasks `:19`, Scene viewpoints `:23`, Run interdicts `:26`, The pivot `:29`, Files touched, Test strategy `:35`, Done when. It has no oracle section.
- `method/templates/plan-flow.md` (55 lines). Sections: Verified facts `:11`, Escalation signals `:14`, Story `:27`, Reuse `:30-34`, Tasks `:36`, Scene viewpoints `:42`, Run interdicts `:45`, then the rest, with a cap of "about 150 lines" (`:9`).
- `method/agents/planner.md`:
  - `:22` is the state check (accepts only the research and the plan).
  - `:36-42` are the contracts. The plan bullet is at `:40` and the short track at `:41`.
  - `:54-57` are the Limits. The bullet at `:55` lists research, plan and reserved ADR, "and no other file. No source file, no test file, no commit".
  - The planner has Write and Bash and no `po-bounds` hook (frontmatter `:4`, no `hooks:`).
- `method/commands/po-plan.md`. `:18` says "source files are out of reach for this command". `## Writing the plan` runs `:37-49`, with the test budget bullet at `:40` and "More than about ten tasks" at `:45`. The plan is filled at `:48`.
- `method/commands/po-flow.md`. `## The plan` is at `:64-67`: it fills `templates/plan-flow.md` and says "Leave the plan uncommitted". `## Execute, review, ship` at `:87-88` appends the short-track sentence to the `/po-execute` prompt.
- `method/commands/po-execute.md`. Preconditions `:20-28` (`:27` detects the design by Glob). Delegation `:39-52`, with the design sentence at `:48-50`. The command has no Write, Edit or Bash tool (`:2-9`, frozen by `tests/execute.test.sh:8-12`).
- `method/commands/po-orchestrator.md`. Stage 4 writes the plan under the `/po-plan` contract (`:54`). Stage 5 appends the design sentence (`:61-62`).
- `method/agents/implementer.md`:
  - `:24` lists expected changes.
  - The loop is at `:32-35`, and step 1 says "run only that task's test files".
  - After the last task (`:39-48`), `:41` lets it "edit only your own lines (`Tree:`, `## Checks`, "Not proven here", the status line)", and `:46` describes the one commit with research, plan, design, record and code.
  - Limits are at `:50-55`.
- `method/templates/verification-record.md`:
  - `:7` names the implementer's lines.
  - Sections are `## Checks` `:13`, `## Not proven here` `:23`, the status line `:26` and `## Runs` `:28`.
  - `## Runs` must stay the last section (`tests/execute.test.sh:57`).
  - `po-gate` reads only `## Checks` and `## Runs` (`method/hooks/po-gate.sh:151`), and `po-run` only `## Runs` (`method/hooks/po-run.sh:57`). A new section is ignored by both.
- `method/skills/testing-doctrine/SKILL.md`. "How many tests?" `:9-15`. "No red-first while implementing" `:48-50` (frozen: `tests/plan.test.sh:44-45`). Row "Tests of the current task" at `:69`.
- `AGENTS.local.md:59`, convention: "one file `tests/<story-slug>.test.sh` per story", where "An acceptance criterion's name is its test function's name". The slug drops the `sNNN-` prefix (`tests/strict-checks-by-default.test.sh` for s147). s150 already owns `tests/oracle-intact-gate.oracle.test.sh` (`docs/stories.md:2386`).
- ADR model: `docs/decisions/ADR-0097-le-controle-strict-par-defaut.md`. It is French, `status: accepted`, `scope: story …`, `supersedes: []`, and lists its options as A to D with "Écartée".

## Attachment points
| Criterion | Where |
| --- | --- |
| `plan_lists_its_oracle` | new `## Acceptance tests` in both plan templates, between `## Reuse` and `## Tasks` |
| `oracle_lives_in_its_own_files` | `## Acceptance tests` text; `AGENTS.local.md:59` convention; planner Limits (out-of-`Owns` oracle → gap reported) |
| `planner_writes_oracle_files` | `planner.md` `## Limits` (`:54-57`); `po-plan.md` `## Writing the plan`; `po-flow.md` `## The plan` |
| `oracle_files_are_expected_work` | `method/AGENTS.md:105`; `planner.md:22`; `implementer.md:24` and `:46`; `po-execute.md` Delegation; `po-orchestrator.md` Stage 5 |
| `implementer_keeps_the_oracle` | `verification-record.md` (new `## Oracle changes`, line `:7`); `implementer.md` `:41` and Limits |
| `oracle_runs_with_its_task` | `testing-doctrine` "No red-first" (`:48-50`) and row `:69` |
| `adr_records_the_oracle` | `docs/decisions/ADR-0098-le-planner-ecrit-l-oracle-d-acceptation.md` |

## Verified interfaces
- `cksum < <file>` prints `<crc> <size>`, two decimal integers separated by one space (`bin/polype:144`, and also used at `tests/installer.test.sh:92`).
- `tests/run.sh`:
  - It runs `*.test.sh` (`:6`), so `tests/<slug>.oracle.test.sh` is picked up with no change.
  - A file with no `test_` function → `FAIL (no test found)` (`:15`).
  - Each file is sourced alone with `lib.sh` (`:11,17`), so helper names never clash between files.
- `po-bounds implementer`: Write and Edit are allowed under `docs/` or inside the story's `Owns` read at the fork point (`method/hooks/po-bounds.sh:5-8,198`).
- `review-antihallu` judges the diff against `Owns`: outside it → major (`method/skills/review-antihallu/SKILL.md:11-13`). The pipeline evidence in `docs/` is in scope by construction (`:18`), but `tests/` files are not.
- `tests/lib.sh` provides `contains`, `require_file`, `frontmatter` and `fail`. `section_of`, `holds` and `line_of` are defined per test file (e.g. `tests/reuse-ladder.test.sh:14-18`).

## Traps
Phrases frozen by tests outside `Owns` must stay word for word. Only additions are allowed around them.
- `planner.md`:
  - `'the ADR that number names — and no other file. No source file, no test file, no commit'` (`tests/planner.test.sh:46`).
  - `'and no other file'`, `'No source file, no test file, no commit'` and the list `` `docs/research/<id>.md`, `docs/plans/<id>.md` and, when the driver reserved a number for this lane, the ADR that number names `` (`tests/drive.test.sh:224-226`).
  - The sentence `` and `docs/plans/<id>.md`, and no other file `` must not reappear (`:230`).
  - Both caps, "200 lines at most" then "250 lines at most", come in this order (`tests/planner.test.sh:25-30`).
  - The `## Reuse` bullet (`tests/reuse-ladder.test.sh:58`).
- `implementer.md`:
  - `'on a fix run, \`docs/reviews/<id>.md\`: those are expected'` and `'Any other change you did not make → stop and report.'` (`tests/execute.test.sh:41-43`).
  - `'**one commit**'`, `'No commit at this point.'` and `'git write-tree'` (`:36-39`).
  - `tests/run-ledger.test.sh:141-160` quotes `:41` ("Fix run: the record already exists; keep it with every row under `## Runs`…").
- `po-execute.md` / `po-orchestrator.md`: the design sentence stays verbatim (`tests/design-handoff.test.sh:25`, `tests/wiring.test.sh:84`).
- Plan templates:
  - `## Reuse` must stay between `## Story` and `## Tasks`, and identical in both templates (`tests/reuse-ladder.test.sh:26-43`).
  - `## Tasks` < `## Scene viewpoints` < `## Run interdicts` (`tests/surface-routing.test.sh:68-72`).
  - plan-flow keeps `150 lines` and `path:line` (`tests/flow.test.sh:78-81`).
- `verification-record.md`:
  - `## Runs` stays last, and the unfilled status line stays exact (`tests/execute.test.sh:55-59`).
  - The fixtures of `tests/run-ledger.test.sh`, `tests/gate.test.sh:84` and `tests/review-tree-gate.test.sh:50` build records without `## Oracle changes`, so nothing may require that section.
- Doctrine: section headings and "Disabling guards on purpose is the reviewer's job" (`tests/plan.test.sh:31-45`), the s148 sections (`tests/tests-beyond-examples.test.sh`), and six numbered shapes only.
- `method/AGENTS.md` is the source of the assembled root `AGENTS.md`. The root copy and `.claude/` / `.polype/` are installed copies (`AGENTS.local.md:56`), so neither is edited here.
- `tests/overlap.test.sh` fails a `method/` line sharing 8+ consecutive words with Killer SaaS (`AGENTS.local.md:60`). All new text must be written in our own words.
- `designer.md:20` needs no change: the design stage runs before the plan, so no oracle file exists yet when it runs.
- No migration, dependency, screen, API or authorization change.

## Open questions
- Where to put `## Oracle changes` in the record: between `## Checks` and `## Not proven here`, or just before `## Runs`? Both keep `## Runs` last. The plan chooses after `## Checks`, so that the status line stays the last line before `## Runs`.
- On resume, the planner finds oracle files on disk while no plan names them yet (it stopped between the two writes). Should it stop or adopt them? The plan writes the oracle files first and the plan last, so such files are "a change you did not write", which means stop and report.
- s150 parses the `## Acceptance tests` tables. The exact column headers fixed here are part of its contract, but s150 is not written yet.
- `templates/stories.md` and the `stories-review` skill do not yet ask that a story's `Owns` list its oracle file. They are outside `Owns`; the planner's gap report covers it meanwhile. Candidate follow-up issue.

## Complexity
4 → 4. The text is spread over twelve method files, and most of them carry phrases frozen by tests outside `Owns`. Nine tasks fit under the ten-task limit, so no split is needed: the cut the story suggests (the oracle and how it is written, then the wiring of expected work) is kept as an ordering of tasks instead.

## Split
— (complexity 4).
