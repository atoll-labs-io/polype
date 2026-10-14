---
validated: yes
---
# Plan — s126-plan-and-defect-paths-cleanup

[Story](../stories.md) · [Research](../research/s126-plan-and-defect-paths-cleanup.md)

Branch `story/s126-plan-and-defect-paths-cleanup`. Read `docs/research/s126-plan-and-defect-paths-cleanup.md` first; this plan builds on it without repeating it.

## Story
The plan, the planner, the research and the orchestrator describe the same stops in the same words, held by tests. Closes the HOLDS rows of `docs/reviews/triage-2026-10-14.md` at lines 77, 89, 90 (po-plan and planner), 91 (po-orchestrator and po-research), 128, 166, 167, 168.

- `defect_stops_agree` — `/po-research` and `/po-orchestrator` place `Root cause: not found` where the `diagnostic` skill puts it; `/po-plan` and the planner read it as a whole line; the three untested stops fail when removed.
- `tech_choice_paths_agree` — `templates/plan-flow.md` no longer says a short plan with a signal must not exist; the planner's "No number there" fallback repeats the marker line; `/po-flow`'s "name that ADR in the plan" is held by a test.
- `plan_tests_bite` — the mutation guard of `tech-choice-backstop` and the planner's `Fixes` clause are held by tests that fail when the rule is removed.

Beyond the criteria, by lead decision (2026-10-14): the signal table of `templates/plan-flow.md` gains the missing technical-choice row, held by `test_tech_choice_paths_agree` and bitten in `test_plan_tests_bite`.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| `mutant`, `run_against`, `bites`, `holds`, `section_of` in the new test file | already in this repository: copy of `tests/ship-and-fleet-cleanup.test.sh:12-23,64-79` | — (first rung; each test file defines its own helpers, `tests/lib.sh` has no shared mutant helper, so they are copied, not imported) |

No other new code: the method edits rewrite existing sentences.

## Tasks
1. [x] **Where the marker sits.** In `method/commands/po-research.md:55` (`## The report`) replace "When the research opens with `Root cause: not found`," by a clause saying the research holds `Root cause: not found` as a whole line (`grep -x`, ADR-0070), the line the `diagnostic` skill writes first in its `## Structuring facts`. In `method/commands/po-orchestrator.md:48` (`## Stage 2 — Research`) rewrite the last sentence the same way: "A research holding `Root cause: not found` as a whole line (`grep -x`, ADR-0070), which the `diagnostic` skill writes first in its `## Structuring facts`, ends the run here: report it and hand the story to a human, with no plan." Keep the finish message "No root cause found for <id>: the story goes to a human, and no plan is written on this research." word for word. Test: `test_defect_stops_agree` (no "opens with `Root cause" left in either file; each stop line holds `as a whole line (\`grep -x\`` and `` `## Structuring facts` ``).
2. [x] **Whole line in the readers.** `method/commands/po-plan.md:26`: "`docs/research/<id>.md` holding `Root cause: not found` as a whole line (`grep -x`, ADR-0070) → stop: …" (rest unchanged). `method/agents/planner.md:39`: "A research holding `Root cause: not found` as a whole line (`grep -x`, ADR-0070), whether you wrote it or found it on disk, …" (rest unchanged, "write no plan" kept). Test: `test_defect_stops_agree` (the `Checks first` line of po-plan and the Defect bullet of the planner each hold `as a whole line (\`grep -x\``).
3. [x] **Tech-choice paths.** (a) `method/agents/planner.md:56`: the "No number there …" fallback also puts the line `Technical choice: waiting for a human` alone on its line in the plan, before "report what is missing"; "use the one the driver reserved for this lane in the message you received" stays (pinned by `tests/drive.test.sh:178`). (b) `method/templates/plan-flow.md:13`: replace "Any signal present means this file should not exist: the story belongs to the full track." by: a signal present sends the story to the full track and no short plan is written, except a technical choice, where this file stays on disk with the line `Technical choice: waiting for a human` and the story goes to `/po-research <id>`, as `## Approval` of `/po-flow` says. (c) `method/templates/plan-flow.md:15-22`: add a row `| Technical choice that deserves an ADR (library, pattern, data model) | absent — <where checked> | absent — <where checked> |` to the signal table, after `New dependency` and before `Defect to fix`, worded like `po-flow.md:43` and `planner.md:33`; it closes the gap noted in the research's open questions (lead decision). Test: `test_tech_choice_paths_agree` (planner `## Limits` line starting "- A structural choice" holds the marker after "No number there"; plan-flow no longer contains `should not exist` and its `## Escalation signals` holds the marker and `## Approval` of `/po-flow`; the signal table of plan-flow holds a row starting `| Technical choice that deserves an ADR`; po-flow `## Approval` holds the bullet `- name that ADR in the plan.`).
4. [x] **Planner `Fixes` clause pinned.** In `tests/diagnostic-skill.test.sh` `test_defect_stories_get_the_diagnostic`, keep the loop but add: the `## Which track` section of the planner holds `a defect to fix — a story carrying a \`Fixes\` line` and `Corrige`. Changes an existing test because this story changes the clause it checks (row s90). Test: `test_plan_tests_bite` (removing that clause from the planner makes `test_defect_stories_get_the_diagnostic` fail).
5. [x] **Mutation guard outside the sentence.** In `tests/tech-choice-backstop.test.sh:73` replace the guard `grep -qF 'Stories ready:'` by two checks on the review mutant: the text just before the removed sentence, ``as ` — owner: <answer>`.``, is still there; and `grep -c 'Stories ready:'` on the mutant equals the count on the real `po-stories-review.md` minus one. Fail messages keep saying "review mutant lost more than the sentence". Changes an existing test because its guard is the finding (row s111). Test: the test itself still passes on the real tree (full suite), and `test_plan_tests_bite` checks the old guard is gone and the new guard phrase sits on `po-stories-review.md`'s line outside the removed sentence.
6. [x] **New test file** `tests/plan-and-defect-paths-cleanup.test.sh`, header comment `# s126 — the plan and the defect paths say the same stops, and their tests bite.`, helpers copied per the Reuse table:
   - `test_defect_stops_agree` — the checks of tasks 1 and 2; plus po-research `## The report` holds `No root cause found for <id>`, po-orchestrator `## Stage 2 — Research` holds `ends the run here` and `with no plan`.
   - `test_tech_choice_paths_agree` — the checks of task 3.
   - `test_plan_tests_bite` — `bites` on: `method/commands/po-research.md` phrase `No root cause found for <id>` → `plan-and-defect-paths-cleanup.test.sh` `test_defect_stops_agree`; `method/commands/po-orchestrator.md` `ends the run here` → same; `method/commands/po-drive.md` `sends its lane to a human` → `defect-and-routing-paths.test.sh` `test_no_root_cause_goes_to_a_human` (the third stop of row s96, pinned by s125, read only); `method/commands/po-flow.md` `name that ADR in the plan.` → `test_tech_choice_paths_agree`; `method/agents/planner.md` `, a defect to fix — a story carrying a \`Fixes\` line (\`Corrige\` in a French stories file)` → `diagnostic-skill.test.sh` `test_defect_stories_get_the_diagnostic`; `method/templates/plan-flow.md` the new marker sentence of task 3 → `test_tech_choice_paths_agree`; `method/templates/plan-flow.md` the row `| Technical choice that deserves an ADR (library, pattern, data model) | absent — <where checked> | absent — <where checked> |` (with its newline) → `test_tech_choice_paths_agree`. Then the static guard check of task 5: `tests/tech-choice-backstop.test.sh` no longer holds `grep -qF 'Stories ready:'`, and the guard phrase is on `po-stories-review.md:49` but not inside "The `Max severity:` and `Stories ready:` lines are never changed: a verdict is the subagent's, not the owner's." Each phrase handed to `bites` must occur once in its file (all checked once in research, except the task-3 sentence and row the implementer writes). Run focused: `bash tests/run.sh plan-and-defect-paths-cleanup.test.sh diagnostic-skill.test.sh tech-choice-backstop.test.sh defect-and-routing-paths.test.sh escalation-contract.test.sh drive.test.sh flow.test.sh`, then the full suite once through `po-run`.

## Scene viewpoints
—

## Run interdicts
- Empty diff on `method/commands/po-drive.md`, `method/commands/po-status.md`, `method/AGENTS.md`, `method/commands/po-stories-review.md`, `method/skills/diagnostic/SKILL.md`, `tests/defect-and-routing-paths.test.sh`, `tests/escalation-contract.test.sh`, `tests/ship-and-fleet-cleanup.test.sh` (s125's or outside `Owns`).
- Nothing changed outside the story's `Owns` plus `docs/research/`, `docs/plans/`, `docs/verif/` of this id; `.claude/` and `.polype/` untouched.
- The finish message of `po-research.md:55` and the `/po-plan` stop reason keep their wording; only how the marker is located changes.
- The signal table of `templates/plan-flow.md` gains exactly one row (technical choice); the six existing rows keep their wording.
- No ADR written: ADR-0090 stays unused.
- Detection stays whole-line anywhere in the research (`grep -x`), never "only at the top of `## Structuring facts`".

## The pivot
Where the marker is **written** (top of `## Structuring facts`, the skill's rule) and how it is **read** (a whole line anywhere, `grep -x`, po-drive's rule) are two separate clauses, and every file keeps both apart. Ways it could be wrong:
- A reader rewritten to match only at the top of `## Structuring facts` would let a misplaced marker through to a plan — compare po-plan and planner against `po-drive.md:52`: whole line, no position.
- "as a whole line" without `grep -x` drifts from s125's wording — compare with `tests/ship-and-fleet-cleanup.test.sh:41`.
- A `bites` phrase that is not unique, or a mutant that removes more than its rule, makes a bite test pass for the wrong reason — `bites` asserts count 1; check the task-3 sentence and row too.

## Files touched
- `method/commands/po-research.md`, `method/commands/po-orchestrator.md`, `method/commands/po-plan.md`, `method/agents/planner.md`, `method/templates/plan-flow.md`
- `tests/diagnostic-skill.test.sh`, `tests/tech-choice-backstop.test.sh`, `tests/plan-and-defect-paths-cleanup.test.sh` (new)
- `docs/research/s126-plan-and-defect-paths-cleanup.md`, `docs/plans/s126-plan-and-defect-paths-cleanup.md`

`method/commands/po-flow.md` is in `Owns` but not edited: only tested.

## Test strategy
Text-contract layer only (bash greps on method files, as every test of this repository). Three new test functions, one per criterion, plus two existing tests tightened (`test_defect_stories_get_the_diagnostic`, `test_stories_review_rules_bite`): five tests touched, within `Test budget: 25`. Each pinned clause is checked inside its own section, never on the whole file, and `test_plan_tests_bite` deletes each rule on a mutant copy and expects the holding test to fail — the bite proof the triage asked for. No visual check.

## Done when
- The eight rows above no longer hold when re-read against the branch.
- `bash tests/run.sh` green (baseline 550 passed), run once through `po-run --story s126-plan-and-defect-paths-cleanup --label full-suite -- 'bash tests/run.sh'`.
- One commit `s126-plan-and-defect-paths-cleanup: …` carrying research, plan and record; review with no open critical finding.
