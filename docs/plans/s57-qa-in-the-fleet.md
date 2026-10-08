---
validated: yes
---
# Plan — s57-qa-in-the-fleet

Branch `story/s57-qa-in-the-fleet`. Read `docs/research/s57-qa-in-the-fleet.md` first; this plan builds on it without repeating it. Decision: ADR-0034 (`docs/decisions/ADR-0034-la-flotte-committe-la-preuve-qa-et-le-retour-en-qa-ne-coute-aucune-boucle.md`), written by the planner, committed with the story.

## Story
`/po-orchestrator` and `/po-drive` run `/po-qa` between execute and review for a story with a screen when `QA stage` is `screens`; `/po-status` reports each screen story's QA; help and README show the stage; a review blocked by `po-gate qa-current` goes back to `/po-qa`, not to a fix run, and spends no `Max attempts` unit.

Criteria = test functions of `tests/qa-fleet.test.sh`: `orchestrator_runs_qa_for_a_screen`, `drive_wave_includes_qa`, `drive_resumes_on_qa_current`, `status_reports_qa`, `help_and_readme_show_qa`, `qa_blocked_review_goes_back_to_qa`.

Vocabulary used below, to write the same way in every file: a **review blocked on QA** is a review whose last `Ship allowed:` is `no` and whose `Next action:` line names `/po-qa` (`review-antihallu/SKILL.md:27`). A **QA return** is the trip back to `/po-qa` then to the review it causes.

## Tasks
1. [x] **`method/commands/po-review.md` — loop number and outcome.**
   - Preconditions (:25): keep the sentence `its \`Fix loop:\` value plus one is this review's loop number` and add right after it: when that previous review was blocked on QA (its `Next action:` names `/po-qa`), this review keeps the same `Fix loop:` value, since a QA return is not a fix run (ADR-0034). The "third blocked review in a row" stop does not count reviews blocked on QA.
   - Outcome (:37-39): a new first bullet, `Ship allowed: no` with a `Next action:` naming `/po-qa` → "Review blocked on QA for <id>. Run /po-qa <id>, then /po-review <id> again; no fix run is spent." The existing fix-run bullet becomes "Any other `Ship allowed: no`" with its text unchanged after that.
   - Test: `test_qa_blocked_review_goes_back_to_qa` (the po-review part: the outcome sentence naming `/po-qa <id>` and "no fix run is spent", and the same-loop clause). `test_review_counts_fix_loops_across_sessions` keeps passing.
2. [x] **`method/commands/po-orchestrator.md` — a QA stage.**
   - `Reads settings` (:15): add `QA stage`. The command list (:19): add `/po-qa`.
   - Stage 1 (:39 area): with `QA stage: screens`, a story whose text shows a screen also takes the full track, because `/po-flow` runs no QA.
   - New `## Stage 6 — QA`, inserted after Stage 5: only for a story with a screen when `QA stage` is `screens`, skipped otherwise; `QA stage` missing for such a story → stop and name it. Apply `/po-qa` as written (its preconditions, the `qa` subagent, then the evidence commit this context makes). Runs after every execution, first run and fix run alike, since each one leaves a tree the last walk did not see. No report → stop with the subagent's reason. `QA status: blocked` → committed as evidence, then stop for a human with its cause: no review is requested on a walk that did not happen.
   - Renumber `## Stage 6 — Review` → `## Stage 7 — Review`, `## Stage 7 — Ship — checkpoint` → `## Stage 8 — Ship — checkpoint`. Keep `## Stage 5 — Execute` and `## Stage 4 — Plan — checkpoint` as they are.
   - Stage 7 blocked branch (:63): a review blocked on QA → back to stage 6, then stage 7 at the same `Fix loop:`; that return is not a fix run and spends none of the two. Any other blocked review → stage 5 as a fix run, as today. A second review blocked on QA while `story/<id>` already holds two `<id>: QA evidence` commits since the last implementer commit → stop for a human.
   - Stage 5 (:55): one clause, a review blocked on QA never triggers the fix run.
   - Test: `test_orchestrator_runs_qa_for_a_screen` (heading `## Stage 6 — QA` between `Stage 5 — Execute` and `Stage 7 — Review`, `QA stage` read, `` `screens` `` and `/po-qa` named in it) and the orchestrator part of `test_qa_blocked_review_goes_back_to_qa`. `tests/pilot.test.sh` (two checkpoints) and `tests/wiring.test.sh` stay green.
3. [x] **`method/commands/po-drive.md` — the wave and the verdict.**
   - `Reads settings` (:14): add `QA stage`. `## Checks` (:24): add the line "`QA stage` missing → only the lanes of stories whose text shows a screen stop, each named in the report; the other lanes carry on." (must say *stop* / *carry on* for `bin/po-lint`). The general "one of the settings above missing" line names `QA stage` as its exception.
   - Intro (:18): `planner`, `implementer`, `qa` and `reviewer` work in their own contexts; Bash also "makes the QA evidence commit `/po-qa` describes", never editing a source file.
   - `### Dispatching` (:83): the stage sentence becomes "... then every implementer, then every qa, then every reviewer".
   - New item 4 between implementer (:88) and reviewer (:89), which becomes 5: "**The QA stage**, for a story whose text shows a screen when `QA stage` is `screens`: `subagent_type: qa` — the prompt `/po-qa` fixes (`method/commands/po-qa.md`), word for word, once the lane's record passes `po-gate verif-current <id>`." Then: its walk and report are its own contract (`method/agents/qa.md`); when it answers, you make the evidence commit as `/po-qa` writes it (branch confirmed, `git -C <absolute path> add -- docs/qa/<id>/`, `git -C <absolute path> commit -m "<id>: QA evidence" -- docs/qa/<id>/`, never `--no-verify`; ADR-0029, ADR-0034); no report → the lane stops with the subagent's reason; `QA status: blocked` → committed all the same, and the lane goes to a human, no reviewer dispatched; every qa of a wave leaves before any of them is waited on; a story without a screen, or `QA stage: —`, dispatches no qa. Write no other `subagent_type:` in this section.
   - `## The verdict, and the fix runs` (:117): before the fix-run sentence, "A review blocked on QA is not a fix run: the lane goes back to `qa`, then to `reviewer` at the same `Fix loop:`, and no `Max attempts` unit is spent (`method/commands/po-review.md`, ADR-0034). Still blocked on QA with two `<id>: QA evidence` commits since the last implementer commit → the lane goes to a human." Then "Any other `Ship allowed: no` sends that lane back to `implementer` as a fix run ..." (substring kept).
   - `## Report` `status` paragraph (:135): add "a QA report `blocked`, with its cause" to the reasons a human decides.
   - Test: `test_drive_wave_includes_qa` (the QA item sits between `subagent_type: implementer` and `subagent_type: reviewer`, names `` `QA stage` is `screens` ``, `the prompt \`/po-qa\` fixes`, `QA evidence`, `-- docs/qa/<id>/`, `every qa of a wave leaves before any of them is waited on`; `QA stage` read) and the drive part of `test_qa_blocked_review_goes_back_to_qa`. Update `tests/drive.test.sh:45-47` and `tests/fleet-design.test.sh:50-53` to `planner designer implementer qa reviewer` with their messages and comments ("five subagents").
4. [x] **`method/commands/po-drive.md` — the resume table.** Insert exactly these rows, in this place; the existing rows keep their text.
   - After the code-stage row (:49), in this order:
     - `| record current, the story has a screen, \`QA stage\` is \`screens\`, and the last \`QA status:\` of \`docs/qa/<id>/report.md\` is \`blocked\` | a human — a walk that could not happen fails the same way when replayed |`
     - `| record current, the story has a screen, \`QA stage\` is \`screens\`, and \`po-gate qa-current <id>\` fails | the QA stage — no \`Max attempts\` unit is spent |`
     - `| \`po-gate qa-current <id>\` passes and \`git -C <absolute path> status --porcelain -- docs/qa/<id>/\` lists the report | the evidence commit of \`/po-qa\`, without a new walk |`
   - After the stale-review row (:51), before the fix-run row (:52):
     - `| a blocked review whose \`Next action:\` names \`/po-qa\` | the review stage, at the same \`Fix loop:\` — the QA it waited for is current, or a row above would have matched |`
   - Paragraph after `:57`: `po-gate qa-current <id>` is what tells a QA report from a missing or stale one, as `verif-current` does for the record; it reads the working tree, so the third row commits a current report left uncommitted instead of walking again (s52 m2).
   - Paragraph `:59`: commits whose subject is `<id>: QA evidence` are not implementer commits and are never counted.
   - Test: `test_drive_resumes_on_qa_current` — row order checked by line number inside the table: code-stage row < `po-gate qa-current <id>\` fails` row < `no \`docs/reviews/<id>.md\`` row; `record current, review blocked` row < `` names `/po-qa` `` row < fix-run row; the `QA status:` `blocked` row before the `qa-current` fails row; the `<id>: QA evidence` exclusion present. `tests/drive.test.sh` and `tests/resume.test.sh` stay green unchanged apart from task 3's order line.
5. [x] **`method/commands/po-status.md`.** `Reads settings` (:11): add `QA stage`. Step 3, after the record bullet (:28): "QA: for a story with a screen when `QA stage` is `screens`, `docs/qa/<id>/report.md` present or not, its last `QA status:`, and whether `po-gate qa-current <id>` passes; `—` for any other story; `QA stage` unset → shown as unset for a screen story, never guessed." Step 5: the table gains a `qa` column after `record`; "Next" chain: execute → QA (`/po-qa <id>`, a screen story under `QA stage: screens` whose `qa-current` fails) → review (blocked → `/po-execute` fix run, or `/po-qa <id>` when its `Next action:` names it). Test: `test_status_reports_qa`. `tests/ship.test.sh:52`, `tests/fleet-wiring.test.sh`, `tests/wiring.test.sh` stay green.
6. [x] **Help and README.** `po-help.md` line :31: append that `/po-orchestrator` and `/po-drive` launch it themselves when `QA stage` vaut `screens`; orchestrator line :36: "ajoute le design et la QA pour une story avec écran". Do not touch the drive line :37. `README.md` cycle table: row `| QA (story avec écran, \`QA stage: screens\`) | \`/po-qa\` | les écrans parcourus en navigateur, preuves dans \`docs/qa/<id>/\` |` between Exécution and Revue; one sentence under it or in the flotte paragraph saying orchestrator and fleet launch it, and that a review blocked on QA goes back to `/po-qa` without spending a fix run. Test: `test_help_and_readme_show_qa`. `tests/distribution-wiring.test.sh` stays green.
7. [x] **Run.** Focused: `bash tests/run.sh qa-fleet.test.sh drive.test.sh fleet-design.test.sh resume.test.sh review.test.sh pilot.test.sh wiring.test.sh fleet-wiring.test.sh distribution-wiring.test.sh`; then the full suite `bash tests/run.sh` once, and `bin/po-lint`; record both in `docs/verif/s57-qa-in-the-fleet.md`. Then one commit with research, plan, ADR-0034, record, method and tests.

## Run interdicts
- Empty diff on: `method/hooks/po-gate.sh` (m2 stays open), `method/commands/po-qa.md`, `method/agents/qa.md`, `method/agents/reviewer.md`, `method/skills/review-antihallu/`, `method/templates/`, `method/commands/po-flow.md`, `method/commands/po-execute.md`, `method/AGENTS.md`, `AGENTS.md`, `AGENTS.local.md`, `.claude/`, `.polype/`, `tests/review.test.sh`, `docs/stories.md`.
- `po-drive.md`: no `subagent_type:` in `## A wave` other than the five listed; no backquoted `` `cd ``; no new row containing `record current, review blocked`, `review whose last \`Ship allowed:\` is \`no\`` or `Reviewed tree:`; existing row texts unchanged; frontmatter tools unchanged (no Write, no Edit).
- `po-orchestrator.md`: exactly two `— checkpoint` headings; `## Stage 5 — Execute` and `## Stage 4 — Plan — checkpoint` unchanged.
- `po-help.md` line `/po-drive` — la flotte … unchanged; `po-review.md` gets no Bash.
- No test removed; the only existing assertions changed are the two wave-order lines (and their comments).
- Diff paths outside `Owns`: only the pipeline evidence and `docs/decisions/ADR-0034-…md` (the reviewer may rate the ADR as an `Owns` gap, as for ADR-0029 in s52).

## The pivot
The QA return keeps `Fix loop:` unchanged, and the resume table tells a review blocked on QA from a review blocked on findings by the rows' order. Everything else is wording.

How it could be wrong:
- **A row in the wrong place.** The QA rows must come after the code row (no QA on a stale record, `po-qa.md:25`) and before every review row; the blocked-on-QA review row must come after the stale-review row and before the fix-run row. Check against `po-drive.md:44-55` and walk three worktrees on paper: (a) fix run committed, review blocked on findings at loop n, record current, QA stale → QA stage, then stale-review row → review at n+1; (b) review blocked on QA at loop n, QA now current and committed → no QA row matches, stale-review row does not (no new implementer commit) → blocked-on-QA row → review at n; (c) same as (b) but report uncommitted → evidence-commit row first.
- **The loop invariant.** `po-drive.md:59` says a review at `Fix loop: n` judged the n+1st implementer commit. Keeping n across a QA return holds it only if QA evidence commits are not counted; the exclusion sentence of task 4 is what makes it true. Compare with `implementer.md:44-45`.
- **The recognition.** A reviewer could block on findings and also name `/po-qa` in `Next action:`. Then the lane goes to QA first and the next review, at the same loop, finds the same findings and sends a fix run: one walk too many, no unit lost. Accepted.

## Files touched
`method/commands/po-review.md`, `method/commands/po-orchestrator.md`, `method/commands/po-drive.md`, `method/commands/po-status.md`, `method/commands/po-help.md`, `README.md`, `tests/qa-fleet.test.sh` (new), `tests/drive.test.sh`, `tests/fleet-design.test.sh`; evidence: `docs/research/`, `docs/plans/`, `docs/verif/`, `docs/decisions/ADR-0034-…md`.

## Test strategy
Layer: string assertions on the method files (the repository's only layer for prose contracts), quoting short exact phrases, with section scoping (`section_of`) and line-order checks where order is the rule.
- New, `tests/qa-fleet.test.sh`: the six criterion tests above. Each would fail if its clause were removed: the order checks in `drive_resumes_on_qa_current` and `drive_wave_includes_qa` fail on a misplaced row or item, not only on a missing one.
- Changed: the wave-order assertion in `tests/drive.test.sh` and `tests/fleet-design.test.sh` (the story note asks for it).
- Total: 6 new + 2 changed, within `Test budget` 25.
- Not tested, by nature: whether a real driver follows the table; the reviewer can only read it. No visual check: no screen in this story.

## Done when
All tasks ticked; the six criterion tests and the full suite green; `bin/po-lint` clean; record complete; one commit on `story/s57-qa-in-the-fleet`; review with no open critical finding; shipped as one squash `s57-qa-in-the-fleet: La QA lancée par l'orchestrateur et la flotte`.
