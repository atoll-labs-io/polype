---
validated: yes
---
# Plan — s104-escalation-contract

[Story](../stories.md) · [Research](../research/s104-escalation-contract.md)

Branch `story/s104-escalation-contract`. Read `docs/research/s104-escalation-contract.md` first; this plan builds on it without repeating it.

## Story
The project lead gets a written contract: three motives that go to the person, no technical choice settled alone, every existing stop raised at once while the fleet carries on, and a dated log of what it decides alone, landed as framing after each wave (ADR-0077, ADR-0080). Criteria: `rules_list_the_three_escalation_motives`, `tech_choices_are_never_settled_alone`, `plan_with_a_tech_choice_waits_for_a_human`, `human_stops_do_not_halt_the_fleet`, `lead_logs_what_it_decides_alone`, `options_ranked_by_owner_criteria` (full text in the research).

## Fixed wording
Tests quote these phrases; write them exactly, in English, in your own sentences around them.

| Where | Exact phrase |
| --- | --- |
| marker (plan body, alone on its line) | `Technical choice: waiting for a human` |
| owner criteria, in this order | `open source or self-hostable, frugal in hardware, scalable, easy for an AI to handle` |
| AGENTS.md section heading | `## What goes to the person` |
| motives | `an incoherence`, `the code, an accepted ADR and a story contradict each other`, `a new idea outside the approved scope`, `a strategic decision`, `vision, scope, recurring cost, security, personal data, or anything hard to undo` |
| tech rule | `Every technical or technology choice that deserves an ADR is discussed with the person before it is made`, `An implementation detail inside a validated plan stays with the lead`, `In doubt, the lead asks.` |
| stops | `goes to the person at once, one at a time, and the fleet carries on with its other lanes`, `No gate opens any other way than before`, `the stops of ADR-0070 stay stops` |
| no self-validation | `whatever \`Plan validation\` says` |
| log | `docs/decisions-log.md`, `templates/decisions-log.md`, `one dated line with its reason`, slug `framing/decisions-log` |
| log template header | `\| Date \| Story \| Decision \| Reason \|` |
| skill section | `## Ranking the options` |

## Tasks
1. [x] **Rules — `method/AGENTS.md`.** Add `## What goes to the person` right after `## The project lead` (after `:67`). Content, short paragraphs: (a) the lead turns to the person for three motives — an incoherence (the code, an accepted ADR and a story contradict each other), a new idea outside the approved scope, a strategic decision (vision, scope, recurring cost, security, personal data, or anything hard to undo); (b) the tech rule with the three fixed phrases, examples "library, framework, data model, protocol, hosting", options ranked first by the owner criteria (fixed phrase), referring to `## Ranking the options` of the `capability-bricks` skill; (c) a plan needing such a choice carries the marker and is never validated by an agent, whatever `Plan validation` says (`/po-plan`); (d) every stop that goes to a human — `Root cause: not found`, `Max attempts` reached, QA `blocked`, an orphan worktree, a closed pull request, the marker — goes to the person at once, one at a time, and the fleet carries on with its other lanes; no gate opens any other way than before, and the stops of ADR-0070 stay stops; (e) the log: each decision the lead takes alone (wave content, fix runs, implementation details, an answer given without asking) adds one dated line with its reason to `docs/decisions-log.md`, following `templates/decisions-log.md`, landed after each wave as `/po-drive` says. Law 6 (`:104`): add `docs/decisions-log.md` to the framing files and say they reach `Target branch` through a framing pull request (`/po-setup`, `## Landing the framing`); keep the rest of the bullet. Fails if wrong: `test_rules_list_the_three_escalation_motives`, `test_tech_choices_are_never_settled_alone`, `test_lead_logs_what_it_decides_alone`.
2. [x] **Template — `method/templates/decisions-log.md`.** A title `# Decisions log`, two lines saying what goes in (decisions the lead took alone, one row each, appended, never rewritten; a decision the person took is not logged here — it is an ADR or a story), then the table header `| Date | Story | Decision | Reason |` and its separator row, no data row. `Date` is `YYYY-MM-DD`; `Story` is an id or `—`. No `#` comment lines inside. Fails if wrong: `test_lead_logs_what_it_decides_alone` (header present, template referenced by AGENTS.md and po-drive.md).
3. [x] **Ranking — `capability-bricks/SKILL.md` and `po-architect.md`.** In the skill, add `## Ranking the options` between the intro paragraph (`:6`) and `## Default bricks`: whenever options are compared (a capability's brick, a switch, a library, a pattern, a data model), they are ranked first by the owner criteria in this order, then by anything else (price, familiarity, popularity); a lower-ranked option is retained only with the criterion that justifies it written in the ADR. Change nothing in the three existing sections. In `po-architect.md` step 3 (`:41`), add one sentence: the options of each ADR are ranked by `## Ranking the options` of `capability-bricks` before one is retained; and in the approval summary (`:65`), the options turned down appear in that ranked order. Fails if wrong: `test_options_ranked_by_owner_criteria`.
4. [x] **Plans never self-validate on a tech choice — `planner.md`, `po-plan.md`, `po-flow.md`.**
   - `po-plan.md` `:45`: replace the bullet — a choice deserving an ADR (library, pattern, data model) is drafted as an ADR from `templates/adr.md` with `status: proposed`, its options ranked by the owner criteria; the plan writes its tasks for the top-ranked option, names the ADR, and holds the marker alone on its line; such a plan never validates itself, whatever `Plan validation` says. `:30`: a plan already present that holds the marker goes to the choice first. `## Approval`: before either bullet, a plan holding the marker → AskUserQuestion with the ranked options (the person may answer otherwise); then set the ADR `accepted` (or rewrite it for the chosen option), rewrite the tasks the choice changes, remove the marker line, and only then apply the bullets below. Keep both existing bullets word for word.
   - `planner.md`: in `## Limits` (`:135`), the structural choice is drafted, not decided: the reserved ADR with `status: proposed` and ranked options, the marker in the plan, no number → the options in the plan; `## Validation`: a plan holding the marker keeps `validated: no` whatever `Plan validation` says, and the final message names the choice and its ranked options. Do **not** write the word AskUserQuestion anywhere in `planner.md` (`bin/po-lint:131`). Add "a technical choice that deserves an ADR" to the signal list (`:114`).
   - `po-flow.md`: add "a technical choice that deserves an ADR (library, pattern, data model)" to `## Escalation signals`; in `## Approval`, say a plan needing such a choice is never validated here, whatever `Plan validation` says: it leaves the short track for `/po-research`, and `/po-plan` puts the choice to the person.
   Fails if wrong: `test_plan_with_a_tech_choice_waits_for_a_human`; `tests/plan.test.sh`, `tests/planner.test.sh`, `tests/flow.test.sh`, `tests/lint.test.sh` stay green.
5. [x] **The fleet — `po-drive.md`.**
   - Resume table: a new row right after the `Root cause: not found` row (`:52`): `| plan holding the line \`Technical choice: waiting for a human\`, without \`validated: yes\` | a human — the plan waits for a technical choice, sent with its options ranked; \`/po-plan <id>\` puts it to them and records the answer (ADR-0077) |`.
   - `## Validating a wave's plans`: one paragraph after the autonomous one — a plan coming back with the marker keeps `validated: no` under either value, is not offered in the grouped question, and its lane goes to a human while the others carry on. Keep every existing sentence of the section.
   - `:106`: keep the sentence, then add: a lane that goes to a human goes to the person at once, in a message of its own naming the story, the reason and what the person must decide — not held for the wave's report and not asked through AskUserQuestion, which would hold every other lane; the other lanes carry on.
   - New `## The decisions log` between `## Ships, one at a time` and `## Report`: after the wave's last ship, append through Bash one row per decision the wave took alone — the stories launched and those held back with why, each fix run started, each re-review of a late commit, each plan approved without a human, each lane handed to a human — to `docs/decisions-log.md` in the repository root, created from `templates/decisions-log.md` when absent; then land it as `## Landing the framing` of `/po-setup` says, slug `decisions-log`, path `docs/decisions-log.md`, message `docs: decisions log`. Its stops end the landing, never the wave's report; the log left uncommitted is landed by the next wave. Written after the ships because a local ship stops on a modified tracked file in the root (`po-ship.md:79`). `status` writes no row.
   - `## Report`: name the decisions-log pull request or local landing; `status` reasons (`:154`): add "a plan waiting for a technical choice, with the choice".
   Fails if wrong: `test_plan_with_a_tech_choice_waits_for_a_human`, `test_human_stops_do_not_halt_the_fleet`, `test_lead_logs_what_it_decides_alone`; `tests/drive.test.sh`, `tests/defect-and-routing-paths.test.sh`, `tests/grouped-validation.test.sh`, `tests/resume.test.sh`, `tests/ship-follows-forge.test.sh` stay green.
6. [x] **One story — `po-orchestrator.md`.** Stage 4: a plan holding the marker → the choice is put to the person as `/po-plan`'s `## Approval` says, before either validation bullet, whatever `Plan validation` says. After stage 0, one paragraph: every stop for a human (stages 2, 6, 7, the marker) ends this run at once and reports that stop alone with its reason; the lanes `/po-drive` runs are not this command's and nothing here pauses them. Fails if wrong: `test_plan_with_a_tech_choice_waits_for_a_human`, `test_human_stops_do_not_halt_the_fleet`.
7. [x] **Tests — `tests/escalation-contract.test.sh`**, six functions named after the criteria (see test strategy). Run `bash tests/run.sh escalation-contract.test.sh`, then the full suite through `po-run --story s104-escalation-contract --label full-suite -- 'bash tests/run.sh'` once, after the last edit.

## Scene viewpoints
—

## Run interdicts
- `.claude/`, `.polype/`, the root `AGENTS.md`, `AGENTS.local.md`: empty diff (installed copies and settings).
- `method/hooks/`, `method/commands/po-setup.md`, `po-ship.md`, `po-status.md`, `po-help.md`, `method/templates/plan.md`, `plan-flow.md`, `adr.md`: empty diff (outside `Owns`).
- No existing test file modified; no sentence asserted by `tests/plan.test.sh`, `planner.test.sh`, `flow.test.sh`, `grouped-validation.test.sh`, `defect-and-routing-paths.test.sh`, `drive.test.sh`, `resume.test.sh`, `capability-bricks.test.sh`, `architect.test.sh` removed or reworded.
- No new setting in any `Reads settings:` line; no new gate in `po-gate`; `validated: yes` still the only thing `plan-validated` reads.
- The three existing sections of `capability-bricks/SKILL.md` keep their tables byte for byte.
- No ADR file written (ADR-0082 stays unused); no `docs/decisions-log.md` created in this repository.
- `planner.md` never names AskUserQuestion.

## The pivot
The marker line `Technical choice: waiting for a human` in the plan body is what makes the wait derivable from disk, like `Root cause: not found` in the research. Ways it could be wrong:
- A row placed after the plan row never matches: compare row order in `po-drive.md` (first match wins, `:47`).
- Writers and readers drift: the same exact string must appear in `planner.md`, `po-plan.md`, `po-drive.md`, `po-orchestrator.md` and `AGENTS.md`; grep all five.
- Under `Merge mode: local` with an effective `human`, a "Not now" on the log landing leaves `docs/decisions-log.md` staged in the root, and the next local ship stops on it (`po-ship.md:79`). Accepted and said in `## The decisions log`; check the section names that consequence.

## Files touched
`method/AGENTS.md`, `method/templates/decisions-log.md` (new), `method/skills/capability-bricks/SKILL.md`, `method/commands/po-architect.md`, `method/commands/po-plan.md`, `method/commands/po-flow.md`, `method/agents/planner.md`, `method/commands/po-drive.md`, `method/commands/po-orchestrator.md`, `tests/escalation-contract.test.sh` (new), plus this plan and the research.

## Test strategy
Six bash tests, one per criterion, in `tests/escalation-contract.test.sh`, using `tests/lib.sh` helpers and a local `section_of`; each quotes the fixed phrases inside the section that must hold them, so deleting the clause turns it red. Budget 25: six used.
- `test_rules_list_the_three_escalation_motives` — section `What goes to the person` of `method/AGENTS.md` holds the motive phrases.
- `test_tech_choices_are_never_settled_alone` — same section holds the three tech-rule phrases and `Technical choice: waiting for a human`.
- `test_plan_with_a_tech_choice_waits_for_a_human` — `po-plan.md`, `po-flow.md`, `planner.md` each hold `whatever \`Plan validation\` says`; `po-plan.md` and `planner.md` hold the marker and `status: proposed`; `po-flow.md` `## Escalation signals` names `a technical choice that deserves an ADR`; `po-drive.md` `## Resuming` has exactly one row with the marker, its stage cell starts with ` a human`, and it comes before the row holding `the lane keeps that file and never writes it again`; `## Validating a wave's plans` holds the marker; `po-orchestrator.md` stage 4 holds the marker.
- `test_human_stops_do_not_halt_the_fleet` — `po-drive.md` `## A wave` holds `at once, in a message of its own` and `the other lanes carry on`; `po-orchestrator.md` holds `at once` and `nothing here pauses them`; AGENTS.md holds the stops phrases.
- `test_lead_logs_what_it_decides_alone` — template exists with the header row; AGENTS.md section holds `docs/decisions-log.md`, `templates/decisions-log.md`, `one dated line with its reason`; Law 6 section holds `docs/decisions-log.md`; `po-drive.md` `## The decisions log` holds `Landing the framing`, `decisions-log`, `after the wave's last ship`, and `## Report` names the log.
- `test_options_ranked_by_owner_criteria` — `## Ranking the options` of the skill holds the criteria phrase; `po-architect.md` step 3 names `Ranking the options`; AGENTS.md section holds the criteria phrase.
No visual check (no screen). Existing suites listed in the interdicts are the regression net, run once in the full suite; `tests/lint.test.sh` runs `bin/po-lint` on `method/`.

## Done when
Every task ticked; `bash tests/run.sh` green through `po-run`; `docs/verif/s104-escalation-contract.md` complete; one implementer commit carrying the code, this plan and the research; a review with no open critical finding; the story landed as one commit `s104-escalation-contract: Ce qui remonte à l'humain, ce que le chef tranche seul`.
