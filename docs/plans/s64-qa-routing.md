---
validated: yes
---
# Plan — s64-qa-routing

Branch `story/s64-qa-routing`. Read `docs/research/s64-qa-routing.md` first; this plan builds on it without repeating it. The decision it rests on is ADR-0041 (`docs/decisions/ADR-0041-le-retour-en-qa-exige-une-revue-bloquee-et-reconnait-la-preuve-non-committee.md`, written by the planner, committed with the story).

## Story
A review counts as blocked on QA only when it carries `Review status: blocked` and a `Next action:` naming `/po-qa`, and every command routes it the same way: `/po-review`, `/po-orchestrator`, `/po-drive`, and now `/po-flow` and `/po-execute` run by hand. `/po-status` sends a `blocked` QA report to a human, as `/po-drive` does. The drive's resume table makes the evidence commit for a report that is current but not committed, instead of walking again, and the false sentence at `po-drive.md:62` is corrected. Criteria: `qa_blocked_needs_a_blocked_status`, `flow_and_execute_send_qa_blocks_to_qa`, `status_agrees_with_the_fleet_on_a_blocked_report`, `drive_resumes_on_an_uncommitted_report`.

Added by research (structuring fact 1): the review blocked on that uncommitted report (`Next action:` = the evidence commit, `review-antihallu/SKILL.md:28`) is a second QA return, **blocked on QA evidence**, routed to the commit without a walk and without a fix run. Without it, criterion 4 commits the evidence and the lane then falls into the fix-run row.

## Fixed phrases
The tests look for these exact strings, so the implementer uses them verbatim wherever a command recognises the state (one per line, backticks included):
```
P1  `Review status: blocked` and a `Next action:` naming `/po-qa`
P2  `Review status: blocked` and a `Next action:` naming the `<id>: QA evidence` commit
M1  Review blocked on QA for <id>. Run /po-qa <id>, then /po-review <id> again; no fix run is spent.
M2  Review blocked on uncommitted QA evidence for <id>. Commit it alone: git commit -m "<id>: QA evidence" -- docs/qa/<id>/, then /po-review <id> again; no fix run is spent.
G   is current but
```
P1 is blocked on QA, P2 blocked on QA evidence; M1 already stands in `po-review.md:41`; G is the gate's refusal (`po-gate.sh:144`).

## Tasks
1. [x] **`method/commands/po-review.md`** — Preconditions `:26`: define the two returns with P1 and P2; the next review keeps the same `Fix loop:` after either, and neither counts toward the three blocked reviews in a row (cite ADR-0034, ADR-0041). Outcome `:41`: the QA line becomes "`Ship allowed: no` with P1 → "M1"". Add a line after it: "`Ship allowed: no` with P2 → "M2"". Keep the line `- Any other \`Ship allowed: no\` → "Ship blocked for <id>. Run /po-execute <id> (fix run)` unchanged. No tool added to the frontmatter.
   Fails if wrong: `qa_blocked_needs_a_blocked_status` (P1 in the definition and the outcome; no line of the six commands pairs `Next action:` and `/po-qa` without `Review status: blocked`); existing `qa_blocked_review_goes_back_to_qa` (`tests/qa-fleet.test.sh:110-112`).
2. [x] **`method/commands/po-orchestrator.md`** — Stage 5 `:57`: keep "a review blocked on QA never triggers the fix run" and add "nor does one blocked on QA evidence". Stage 6 `:65`: when `po-gate qa-current <id>` refuses with G, make only the evidence commit, no walk. Stage 7 `:70`: "Blocked on QA — P1 → back to stage 6, then stage 7 again at the same `Fix loop:` …" (keep "spends none of the two" and "two `<id>: QA evidence` commits since the last implementer commit → stop for a human", now applied to either return); add "Blocked on QA evidence — P2 → that evidence commit as stage 6 makes it, without a walk, then stage 7 again at the same `Fix loop:`". `:72` "Any other blocked review" unchanged.
   Fails if wrong: `qa_blocked_needs_a_blocked_status` (P1 and P2 in Stage 7, negative scan); existing `qa_blocked_review_goes_back_to_qa` (`:115-118`).
3. [x] **`method/commands/po-drive.md`, resume table** — Insert between `:51` (report `blocked` → a human) and `:52` (`qa-current` fails → the QA stage) the row below (the backslashes only escape backticks; the file holds plain backticks):
   `| record current, the story has a screen, \`QA stage\` is \`screens\`, and \`po-gate qa-current <id>\` refuses a report that \`is current but\` not committed | the evidence commit of \`/po-qa\`, without a new walk |`
   Delete the dead row `:53` (`… lists the report | the evidence commit …`). Rewrite `:56` so its first cell is P1 followed by ` or the `<id>: QA evidence` commit` and its second cell is unchanged (`the review stage, at the same `Fix loop:` — the QA it waited for is current, or a row above would have matched`). Every other row keeps its text and relative order.
   Fails if wrong: `drive_resumes_on_an_uncommitted_report` (row present once, below the human row, above the QA-stage row; old row gone); updated `drive_resumes_on_qa_current`; `tests/drive.test.sh:195-207`.
4. [x] **`method/commands/po-drive.md`, prose** — `:62`: replace "It reads the working tree, so a current report left uncommitted passes it; …" by: since s60 it also requires `docs/qa/<id>/` committed (ADR-0037), so a current report left uncommitted fails it; only that refusal says G, because the gate checks freshness first; the evidence-commit row reads that refusal before the QA-stage row, so such a report is committed instead of walked again (ADR-0041). Must contain `a current report left uncommitted fails it`. Verdict `:125`: keep its first sentence verbatim; append "Blocked on QA means P1, nothing less (ADR-0041)." and "A review blocked on QA evidence — P2 — gets that commit without a walk, then `reviewer` at the same `Fix loop:`; no `Max attempts` unit is spent either."; the two-commits bound covers either return. `:127` unchanged.
   Fails if wrong: `drive_resumes_on_an_uncommitted_report` (new sentence present, `passes it` sentence gone); existing `:121-123` assertions; `tests/drive.test.sh:89`.
5. [x] **`method/commands/po-execute.md` and `method/commands/po-flow.md`** — po-execute precondition 6 `:26`: after "this is a **fix run** …", add: except a review with P1 → stop with "M1", or with P2 → stop with "M2" (`/po-review`, ADR-0041). No tool added (it stays without Bash). po-flow step 3 `:78`: before the fix run, a review with P1 → stop with "M1"; with P2 → stop with "M2"; neither spends a fix run (`/po-flow` runs no QA itself). The rest of both files unchanged.
   Fails if wrong: `flow_and_execute_send_qa_blocks_to_qa`.
6. [x] **`method/commands/po-status.md`** — `:39` "Next": the QA step becomes: a screen story under `QA stage: screens` whose last `QA status:` is `blocked` → "a human decides", with the report's cause, as `/po-drive` resumes it; `qa-current` refusing with G → the evidence commit `git commit -m "<id>: QA evidence" -- docs/qa/<id>/`, not a new walk; any other `qa-current` failure → QA (`/po-qa <id>` …) — keep the substring `→ QA (\`/po-qa <id>\``. Review step: `/po-qa <id>` for P1, the evidence commit for P2, otherwise the `/po-execute` fix run. `:36` blocked stories: add "a QA report `blocked`, with its cause, which a human decides on, as in `/po-drive`".
   Fails if wrong: `status_agrees_with_the_fleet_on_a_blocked_report`; `qa_blocked_needs_a_blocked_status` (negative scan); existing `test_status_reports_qa`.
7. [x] **`tests/qa-fleet.test.sh`** — Header comment gains an s64 line. Update `drive_resumes_on_qa_current`: `:74` quotes the new row (`| \`Review status: blocked\` and a \`Next action:\` naming \`/po-qa\` or the \`<id>: QA evidence\` commit | the review stage, at the same \`Fix loop:\``), `:81` is replaced by the new evidence row (moved into the new test, not duplicated). Add the four criterion tests below. Run `bash tests/run.sh qa-fleet.test.sh drive.test.sh resume.test.sh` after this task.
8. [x] **Run** — the full suite and `bin/po-lint` once all tasks are done, through `po-run` as the implementer's file describes (`Full suite: execute-end`); `Typecheck: —`.

## Run interdicts
- Empty diff on: `method/hooks/po-gate.sh`, `method/commands/po-qa.md`, `method/commands/po-help.md`, `method/skills/`, `method/agents/`, `method/templates/`, `method/AGENTS.md`, `AGENTS.md`, `AGENTS.local.md`, `.claude/`, `.polype/`, `README.md`, `docs/stories.md`, every ADR other than ADR-0041, every test file other than `tests/qa-fleet.test.sh`.
- Frontmatters of the six commands unchanged: no Bash for `po-review.md` or `po-execute.md`, no Write/Edit for `po-drive.md`.
- In `po-drive.md`'s resume table: only the inserted row, the removed `… lists the report …` row and the rewritten QA-return row differ; every other row is byte-identical and keeps its order.
- In `tests/qa-fleet.test.sh`: no test removed; the only changed existing assertions are `:74` and `:81`.
- No ADR number beyond 0041 is written.

## The pivot
The drive (and the orchestrator, and `/po-status`) recognise "current but not committed" by the gate's refusal containing `is current but` (ADR-0041), not by deriving it from `git status`. It could be wrong if:
- the gate's text changes — `drive_resumes_on_an_uncommitted_report` checks that `method/hooks/po-gate.sh` still holds `is current but docs/qa/$1/ is not committed`, so the drift turns red;
- the gate stops checking freshness before commitment — then a stale uncommitted report would be committed and not walked; compare against `po-gate.sh:139-144` and ADR-0037 ("Le contrôle passe en dernier");
- the reviewer's `Next action:` for that case drifts from the evidence commit — P2 then never matches and the review falls to the fix run; compare `review-antihallu/SKILL.md:28`, pinned by `tests/ownership.test.sh:108`.

Second hinge: P1 and P2 stay two named cases rather than one, because criterion 1 says "only if … names `/po-qa`". A reviewer should check no command folds P2 into P1's walk.

## Files touched
- `method/commands/po-review.md`, `po-orchestrator.md`, `po-drive.md`, `po-execute.md`, `po-flow.md`, `po-status.md`
- `tests/qa-fleet.test.sh`
- `docs/decisions/ADR-0041-le-retour-en-qa-exige-une-revue-bloquee-et-reconnait-la-preuve-non-committee.md` (planner-written; outside `Owns` but required by Law 6 and announced here)
- `docs/research/s64-qa-routing.md`, `docs/plans/s64-qa-routing.md`, `docs/verif/s64-qa-routing.md`

## Test strategy
Prose contracts, so bash string assertions in `tests/qa-fleet.test.sh` with the file's own helpers (`section_of`, `holds`, `only_line`, `before`) and `tests/lib.sh` (`contains`, `require_file`, `fail`). Four new tests, two changed assertions; total well within `Test budget: 25`.
- `test_qa_blocked_needs_a_blocked_status` — P1 present in `po-review.md` Preconditions and Outcome, in the orchestrator's `Stage 7 — Review` section, in the drive's `Resuming` and `The verdict, and the fix runs` sections; P2 present in `po-review.md` and the orchestrator Stage 7. Negative scan: for each of the six commands, no line holding both `` `Next action:` `` and `` `/po-qa` `` lacks `` `Review status: blocked` `` — removing the status clause anywhere turns it red.
- `test_flow_and_execute_send_qa_blocks_to_qa` — `po-execute.md` `## Preconditions, checked by reading files` holds P1, M1, P2, M2; `po-flow.md` `## Execute, review, ship` holds P1, M1, P2, M2 and `neither spends a fix run`.
- `test_status_agrees_with_the_fleet_on_a_blocked_report` — `po-status.md` holds `is \`blocked\` → "a human decides"` and `a QA report \`blocked\`, with its cause`; the drive's resume table still holds `` is `blocked` | a human ``.
- `test_drive_resumes_on_an_uncommitted_report` — `only_line` on `refuses a report that \`is current but\` not committed | the evidence commit of \`/po-qa\`, without a new walk`; it is below the human row and above the `` `po-gate qa-current <id>` fails | the QA stage `` row; `lists the report` absent from `Resuming`; `a current report left uncommitted fails it` present and `a current report left uncommitted passes it` absent; `method/hooks/po-gate.sh` holds `is current but docs/qa/$1/ is not committed`.
Visual checks: none (no screen).

## Done when
All eight boxes ticked; `bash tests/run.sh` green and `bin/po-lint` exit 0, recorded in `docs/verif/s64-qa-routing.md` with its `Tree:`; one commit on `story/s64-qa-routing` carrying the code, the tests, the research, the plan, the ADR and the record; a review with no open critical finding.
