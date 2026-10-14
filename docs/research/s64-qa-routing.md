# Research — s64-qa-routing

[Story](../stories.md)

## Structuring facts
- **Gap the story leaves out**: a review blocked on a report that is current but not committed carries a `Next action:` that is the evidence commit and "does not name `/po-qa`" (`method/skills/review-antihallu/SKILL.md:28`, s63). Every command then reads it as "any other `Ship allowed: no`" → a fix run (`method/commands/po-review.md:42`, `po-drive.md:57`, `po-orchestrator.md:72`). Fixing criterion 4 alone would commit the evidence, then still send the lane to a fix run. The plan must route this second QA case too.
- QA-blocked is recognised today by `Next action:` alone, in four places: `po-review.md:26,41`, `po-orchestrator.md:57,70`, `po-drive.md:56,125` — and `po-status.md:39`. `templates/review.md:13` puts a `Next action:` line in every review, so a complete review can match (s57 major).
- The evidence-commit row `po-drive.md:53` is dead since s60: it needs `qa-current` to pass, and `qa-current` now refuses an uncommitted report (`method/hooks/po-gate.sh:141-144`, ADR-0037). The row above it (`:52`, "qa-current fails → the QA stage") catches the case first, so the lane walks again. `po-drive.md:62` still says "a current report left uncommitted passes it" — false.
- The gate tells the uncommitted case apart by its message alone: freshness is checked first, the commit last, and only that refusal says `is current but docs/qa/$1/ is not committed` (`po-gate.sh:144`, ADR-0037 "Le contrôle passe en dernier"). There is no other gate subcommand for it, and `po-gate.sh` is outside `Owns`.
- `/po-flow` (`po-flow.md:78`) and `/po-execute` (`po-execute.md:26`) treat every `Ship allowed: no` as a fix run; ADR-0034 (Neutral) leaves this to "une story qui les possède" — this one.

## Story
Make "blocked on QA" mean `Review status: blocked` **and** a `Next action:` naming `/po-qa`, and route it the same way in every command. Criteria:
- `qa_blocked_needs_a_blocked_status` — a review is blocked on QA only with `Review status: blocked` and `/po-qa` in `Next action:`.
- `flow_and_execute_send_qa_blocks_to_qa` — `/po-flow` and `/po-execute` run by hand send such a review to `/po-qa`, not to a fix run.
- `status_agrees_with_the_fleet_on_a_blocked_report` — for a `blocked` QA report, `/po-status` says a human decides, like `/po-drive`.
- `drive_resumes_on_an_uncommitted_report` — the drive resume table recognises a current but uncommitted report and makes the evidence commit without a new walk; the sentence claiming such a report passes `qa-current` is corrected.

## Current code
- `method/commands/po-review.md` (Read, Glob, Grep, Agent, Write — no Bash). `:26` loop rule: previous review whose `Next action:` names `/po-qa` → same `Fix loop:`; QA-blocked reviews do not count toward the three blocked in a row. `:41` outcome for `/po-qa`; `:42` "Any other `Ship allowed: no`" → fix run.
- `method/commands/po-orchestrator.md` (has Bash, Agent). Stage 5 `:57` "a review blocked on QA never triggers the fix run". Stage 6 `:62-65`: always applies `/po-qa` (a walk), then the evidence commit; `QA status: blocked` → commit, stop for a human. Stage 7 `:70`: "Blocked on QA — the review's `Next action:` names `/po-qa` → back to stage 6 … same `Fix loop:`"; two `<id>: QA evidence` commits since the last implementer commit → human. `:72` any other blocked review → fix run.
- `method/commands/po-drive.md` (Bash, Agent; no Write/Edit). Resume table `:45-60`, first matching row wins (`:43`). QA rows `:51` (report `blocked` → human), `:52` (`qa-current` fails → QA stage), `:53` (dead evidence-commit row). Review rows `:54-59`; `:56` QA return at same `Fix loop:`; `:57` fix run. `:62` the false sentence. `:64` QA evidence commits never counted as implementer commits. Wave step 4 `:94` makes the evidence commit after each `qa`. Verdict `:125` QA return; `:127` other `no` → fix run. Report `:145` lists "a QA report `blocked`, with its cause" among human waits.
- `method/commands/po-execute.md` (Read, Glob, Grep, Agent only). Precondition `:26`: last verdict `Ship allowed: no` → fix run. Fix-run sentence `:46`.
- `method/commands/po-flow.md` (Bash, Write, Agent). `:77` review as `/po-review` does, `Fix loop:` counted the same way; `:78` "`Ship allowed: no` → a fix run". Flow runs no QA (`po-orchestrator.md:41`).
- `method/commands/po-status.md` (has Bash). `:29` QA column: report presence, last `QA status:`, `qa-current` result. `:36` blocked-stories list has no QA-report entry. `:39` Next: "QA (`/po-qa <id>`, … whose `po-gate qa-current <id>` fails)" — so a `blocked` report or an uncommitted current one both get `/po-qa`; "review (blocked → `/po-execute` fix run, or `/po-qa <id>` when its `Next action:` names `/po-qa`)".

## Attachment points
- Definition of the two QA returns: `po-review.md` Preconditions `:26` (it is the file ADR-0034 and `po-drive.md:125` cite).
- Routing sites: `po-review.md:41-42`, `po-orchestrator.md:57,65,70-72`, `po-drive.md:51-57,62,125`, `po-execute.md:26`, `po-flow.md:78`, `po-status.md:36,39`.
- Tests: `tests/qa-fleet.test.sh` (s57), helpers `section_of`, `holds`, `only_line`, `before` defined in the file (`:11-25`); `contains`, `require_file`, `fail` from `tests/lib.sh`.

## Verified interfaces
- `qa_current()` `method/hooks/po-gate.sh:129-145`: order — no report (`:131`), status not `complete` (`:133-134`), no/unknown `Tree:` (`:136-138`), code moved (`:139-140`), then not committed (`:141-144`). Uncommitted refusal text: `the QA report of $1 is current but docs/qa/$1/ is not committed — commit it alone: git commit -m "$1: QA evidence" -- docs/qa/$1/ (/po-qa $1)`. Installed copy identical (`.polype/hooks/po-gate.sh:144`). `tests/qa-gate.test.sh:67-68` pins `not committed`.
- Review shape: `templates/review.md:5` `Review status: <complete | blocked>`, `:9-13` `## When blocked` with `Next action:`; `method/agents/reviewer.md:32-36` writes `Review status: blocked` + `Next action:` when it cannot finish.
- `review-antihallu/SKILL.md:28`: `qa-current` fails → review blocked, gate message as `Failure cause:`, `/po-qa <id>` as `Next action:`; exception: current but not committed → `Next action:` is `git commit -m "<id>: QA evidence" -- docs/qa/<id>/`, "not a new walk", not naming `/po-qa`. Pinned by `tests/ownership.test.sh:104-109`.
- `/po-qa` (`method/commands/po-qa.md:39-45`) always dispatches a walk; it has no commit-only mode, and is outside `Owns`.
- ADR-0034 (`docs/decisions/ADR-0034-…md`) chose `Next action:` naming `/po-qa` as the signature, and turned down reading the gate message in `Failure cause:`. ADR-0037 makes `qa-current` require a committed report and names `po-drive.md:53,62` as left to s64.

## Traps
- Existing assertions that quote clauses this story changes (allowed: the story changes them): `tests/qa-fleet.test.sh:74` (row `| a blocked review whose \`Next action:\` names \`/po-qa\` |…`), `:81` (`lists the report | the evidence commit of \`/po-qa\`, without a new walk`), `:115` (orchestrator stage 7 phrase, kept if wording kept), `:121` (drive verdict sentence, kept if wording kept), `:110-112` (po-review phrases).
- Other tests on the same files that must stay green: `tests/drive.test.sh:195-214` (every resume row names a stage; stale-review row before fix-run row), `tests/resume.test.sh:11-38` (code-stage row text, `a fix run, at loop \`Fix loop:\` + 1`), `tests/drive.test.sh:89` (`\`Ship allowed: no\` sends that lane back to \`implementer\` as a fix run`), `tests/qa-fleet.test.sh:91` (`→ QA (\`/po-qa <id>\``), `tests/model-routing.test.sh:58,63`, `tests/execute.test.sh`, `tests/flow.test.sh`, `tests/overlap.test.sh` (no 8-word overlap with Killer SaaS), `bin/po-lint`.
- `po-drive.md` is also owned by s69 (depends on s64): it waits; no collision now.
- `po-execute.md` has no Bash: it can only stop and point, never commit.
- `README.md:37` and `method/commands/po-help.md` describe the QA return in general terms and stay true; both are outside `Owns`.
- No migration, no new dependency, no screen, no API contract, no authorization change.

## Open questions
- How the drive recognises "current but not committed": the gate's refusal text (precise, already relied on by `review-antihallu`) or a derivation from `git status` plus `QA status: complete` (no text coupling, but may commit a stale report). The plan decides (ADR-0041).
- Whether the review blocked on the uncommitted report should be folded into "blocked on QA" or named separately. Criterion 1 says "only if … names `/po-qa`", so folding would contradict it; the plan names it separately.

## Complexity
3 → 3. Prose in six command files plus one test file and one ADR, no code; the difficulty is the first-match order of the resume table and keeping six commands saying the same thing.

## Split
Not needed.
