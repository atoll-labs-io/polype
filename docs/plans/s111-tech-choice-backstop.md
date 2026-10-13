---
validated: yes
---
# Plan — s111-tech-choice-backstop

Branch `story/s111-tech-choice-backstop`. Read `docs/research/s111-tech-choice-backstop.md` first. This plan builds on it and does not repeat it.

"The marker" below means the exact string of `MARKER` in `tests/escalation-contract.test.sh:14`. Wherever this plan says "write the marker", the implementer copies that exact string.

## Story
A short-track plan sent back over a technical choice keeps the marker and the ranked options, so `/po-plan` always puts the choice to the person, even under `Plan validation: autonomous`.

The three criteria:
- `flow_plan_sent_back_keeps_the_marker`
- `approval_test_bites_in_its_section`
- `stories_review_rules_bite`

They are restated in the research, under `## Story`.

## Tasks
1. [x] **`method/commands/po-flow.md` `## Approval`.** Fixes root cause 1.
   - Move the tech-choice clause (`:74`) before the `human`/`autonomous` bullets, as `po-plan.md:50` does.
   - Rewrite it in fresh words. It must still say that such a plan is never validated here, `whatever \`Plan validation\` says`. Before pointing to `/po-research <id>`, it does four things:
     - (a) it keeps `docs/plans/<id>.md` on disk and writes the marker into it, alone on its line;
     - (b) it leaves the frontmatter at `validated: no`;
     - (c) it drafts the ADR in `<ADR directory>` from `templates/adr.md`, under the next free number, with `status: proposed` and its options ranked by the owner's criteria as `## Ranking the options` of the `capability-bricks` skill says;
     - (d) it names that ADR in the plan.
   - End the clause with one sentence: `/po-plan`, skipping to its Approval on the plan already present, finds the line and puts the choice to the person with the ADR's options in their ranked order.
   - Add `ADR directory` to the `Reads settings:` line (`:15`). Do not write the literal `docs/decisions/` anywhere.
   - Test that fails if wrong: `test_flow_plan_sent_back_keeps_the_marker` (task 4).
2. [x] **`tests/escalation-contract.test.sh` `test_plan_with_a_tech_choice_waits_for_a_human`.** Fixes root cause 2. The story changes this clause, so editing the existing test is allowed.
   - Replace the whole-file checks of `$PLAN_CMD` in the loops at `:46-50`.
   - In `section_of "$PLAN_CMD" 'Approval — per \`Plan validation\`'`, use `holds` to check four things:
     - `$MARKER`
     - `$WHATEVER`
     - `in their ranked order`
     - `remove the marker line`
   - In `section_of "$PLAN_CMD" 'Writing the plan'`, use `holds` to check `status: proposed` and `$MARKER`.
   - Keep the `contains` checks on `$FLOW` (`$WHATEVER`) and on `$PLANNER` (`$WHATEVER`, `$MARKER`, `status: proposed`) exactly as they are, and every line from `:51` on.
   - Test that fails if wrong: this test itself. Task 4's `test_approval_test_bites_in_its_section` proves it.
3. [x] **`tests/conversational-framing.test.sh` `test_stories_review_surfaces_criticals_only`.** Fixes root cause 3.
   - Add `contains "$review" "never changed: a verdict is the subagent's"`.
   - Add `contains "$stories" 'has already started'`.
   - Change nothing else in the file.
   - Test that fails if wrong: this test itself. Task 4's `test_stories_review_rules_bite` proves it.
4. [x] **New `tests/tech-choice-backstop.test.sh`**, with three tests named after the criteria.
   - Define `section_of` and `holds` locally, the same way `escalation-contract.test.sh:18-19` does.
   - For the mutants, copy the `mutant()` + `mktemp -d` + `trap … EXIT` pattern of `tests/lint.test.sh:6-16`.
   - `test_flow_plan_sent_back_keeps_the_marker`:
     - In `section_of "$METHOD/commands/po-flow.md" 'Approval'`, `holds` the marker, `validated: no`, `status: proposed`, `Ranking the options`, `templates/adr.md`, `/po-research <id>`, `whatever \`Plan validation\` says` and `in their ranked order`.
     - The marker occurs in that section *before* the line holding `- \`autonomous\``, so the choice comes first.
     - `settings_read_by` on po-flow lists `ADR directory`.
     - `section_of "$METHOD/commands/po-plan.md" 'Checks first'` still `holds` the marker, which is the skip-to-Approval clause at `po-plan.md:30`.
   - `test_approval_test_bites_in_its_section` uses a mutant of `method/`:
     - Remove the line of `commands/po-plan.md` that starts `A plan holding the line \`` and contains `is settled with the person first`.
     - Assert that the line count dropped by exactly 1, so the test can never pass without its mutation biting.
     - In a subshell, set `METHOD=<mutant>`, source `$ROOT/tests/escalation-contract.test.sh` and run `test_plan_with_a_tech_choice_waits_for_a_human`. It must fail.
     - The same call on the real `$METHOD` must pass.
   - `test_stories_review_rules_bite` uses two mutants, one rule each:
     - (a) In `commands/po-stories-review.md`, remove only the sentence holding "never changed: a verdict is the subagent's".
     - (b) In `commands/po-stories.md`, remove only the sentence "A story with a \`story/<id>\` branch … it is not reopened here.", keeping "Each story keeps its id." on that line.
     - Assert that each mutant no longer holds its phrase and still holds the other text of that line.
     - Then run `test_stories_review_surfaces_criticals_only` from `$ROOT/tests/conversational-framing.test.sh` against each mutant, as above. Each run must fail.
   - Test that fails if wrong: these three tests. Run `bash tests/run.sh tech-choice-backstop.test.sh escalation-contract.test.sh conversational-framing.test.sh`.
5. [x] **Full suite, once, when tasks 1-4 are done.** Run `po-run --story s111-tech-choice-backstop --label full-suite -- 'bash tests/run.sh'`.
   - `tests/overlap.test.sh` and `tests/lint.test.sh` must stay green. They cover the new prose (Killer SaaS overlap) and the settings name (`bin/po-lint:98-112`).
   - The project has no type check (`Typecheck: —`).

## Scene viewpoints
—

## Run interdicts
- `method/commands/po-plan.md` ends with an empty diff. It is in `Owns`, but `:30` and `:50` already do what the story needs (research, Structuring facts).
- `method/templates/plan-flow.md`, `method/commands/po-orchestrator.md`, `method/commands/po-drive.md`, `method/agents/planner.md`, `method/commands/po-stories.md`, `method/commands/po-stories-review.md` and `tests/adr-directory.test.sh` end with an empty diff. They are all outside `Owns`.
- `.claude/`, `.polype/`, the root `AGENTS.md` and `AGENTS.local.md` are untouched.
- No ADR is written: this story makes no structural choice.
- `po-flow.md` keeps its second signal check (`:46-48`, "write no plan") word for word. The backstop adds to that check and does not replace it.
- In `escalation-contract.test.sh`, only the `$PLAN_CMD` loop lines of `test_plan_with_a_tech_choice_waits_for_a_human` change. In `conversational-framing.test.sh`, only the two added lines change. `git diff` shows nothing else in either file.
- No test mutates a file under the worktree's `method/`. Mutants live only under `mktemp -d`, removed by the `trap`.
- No new setting and no new gate. `ADR directory` already exists (`method/templates/agents-local.md:25`).

## The pivot
The fix keeps the flow plan and marks it, rather than deleting it. The story chose this, and it relies on `/po-plan` and `/po-orchestrator` already acting on a marked plan that is present (`po-plan.md:30`, `:50`; `po-orchestrator.md:54`). It can go wrong in three ways:
- **The ADR is not findable.** `po-plan.md:50` asks "with the ADR's options". If the flow clause drafts the ADR without naming it in the plan, `/po-plan` has no options to show. Compare: task 1 (d) and the clause's last sentence.
- **The clause still comes after the bullets.** Then a reader applying `autonomous` first validates the plan before reaching the clause. Compare: the ordering assertion in `test_flow_plan_sent_back_keeps_the_marker`.
- **The bite tests are vacuous.** If a mutation's pattern stops matching after a wording drift, the mutant equals the original and the "must fail" check would wrongly catch nothing. Compare: the line-count and phrase-absent assertions in task 4.

## Files touched
- `method/commands/po-flow.md`
- `tests/escalation-contract.test.sh`
- `tests/conversational-framing.test.sh`
- `tests/tech-choice-backstop.test.sh` (new)
- `docs/research/s111-tech-choice-backstop.md`, `docs/plans/s111-tech-choice-backstop.md`, `docs/verif/s111-tech-choice-backstop.md` (evidence)

## Test strategy
This repository has one test layer: bash phrase tests on method prose. Each rule is checked once, in its own section.
- New tests: 3 (`tech-choice-backstop.test.sh`). Two existing tests are tightened. The total is well within `Test budget` 25.
- The two bite tests make the reviewer's mutation (ADR-0012) permanent, for the two rules whose absence went unseen. They also assert that each mutation actually happened, which rules out the "test that proves nothing" shape.
- Visual checks: none (`Surface: —`, `QA stage: —`).
- Not proven: whether an agent running `/po-flow` actually writes the marker and the ADR at runtime. Phrase tests cannot show this. A person should send one flow plan back on a sample project and then run `/po-plan`.

## Done when
- The four files above are changed as the tasks say, and the full suite is green through `po-run`.
- The review has no open critical finding.
- The story lands as one commit `s111-tech-choice-backstop: Un plan court renvoyé garde sa question` through a pull request.

Checked autonomously against each criterion (`Plan validation: autonomous`); no human reviewed this plan.
- `flow_plan_sent_back_keeps_the_marker`: tasks 1 and 4.
- `approval_test_bites_in_its_section`: tasks 2 and 4.
- `stories_review_rules_bite`: tasks 3 and 4.
