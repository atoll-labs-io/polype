# Research — s57-qa-in-the-fleet

## Structuring facts
- No assumption of the story is false. Two are already half true: `/po-help` already lists `/po-qa` (`method/commands/po-help.md:31`), only `README.md` lacks the stage (`README.md:111-118`).
- "Ce retour ne consomme aucune unité de `Max attempts`" is impossible under today's loop rule: each review takes the previous `Fix loop:` + 1 (`method/commands/po-review.md:25`), and `Max attempts` is read from that line (`method/commands/po-drive.md:65`). `po-review.md` must change its counting, not only its conclusion.
- The fleet has no one to make the QA evidence commit: ADR-0029 gives it to the `/po-qa` command (`method/commands/po-qa.md:36-42`), the `qa` agent may not commit (`method/agents/qa.md:52`), and a driver dispatches subagents, not commands. The driver (Bash, `po-drive.md:7-8`) has to make that commit itself → ADR-0034.
- Polype's own `AGENTS.local.md` has no `QA stage` line (pipeline block, lines 9-33), and `/po-drive` stops the whole run on any missing setting it reads (`po-drive.md:24`). Adding `QA stage` to that list unconditionally stops the next `/po-drive` on this repository.
- `/po-qa` adds a commit `<id>: QA evidence` to `story/<id>` (`po-qa.md:40`); the stale-review row of the resume table counts implementer commits (`po-drive.md:59`) and would miscount it.

## Story
`/po-orchestrator` and `/po-drive` run `/po-qa` for a story with a screen when `QA stage` is `screens`, between execute and review; `/po-status` reports the QA of each screen story; help and README show the stage; a review blocked because `po-gate qa-current` fails goes back to `/po-qa`, not to a fix run, without spending `Max attempts`.

Criteria (test names, in `tests/qa-fleet.test.sh`): `orchestrator_runs_qa_for_a_screen`, `drive_wave_includes_qa`, `drive_resumes_on_qa_current`, `status_reports_qa`, `help_and_readme_show_qa`, `qa_blocked_review_goes_back_to_qa`. Owns: `po-orchestrator.md`, `po-drive.md`, `po-status.md`, `po-help.md`, `po-review.md`, `README.md`, `tests/drive.test.sh`, `tests/fleet-design.test.sh`, `tests/review.test.sh`, `tests/qa-fleet.test.sh`.

## Current code
- `method/commands/po-orchestrator.md` (68 lines). Reads settings at :15, no `QA stage`. Commands it follows listed at :19 (no `/po-qa`). Stage 1 track rule :33-41, a *new* screen forces the full track (:39). Stages: 5 Execute :54, 6 Review :60, 7 Ship — checkpoint :65. Every blocked review → stage 5 fix run (:63), two fix runs then a human.
- `method/commands/po-drive.md` (137 lines). Reads settings :14 (no `QA stage`). Missing setting → stop the run (:24). Resume table :44-55, first match wins (:42); stale-review explanation :59, counting implementer commits. Wave dispatch list :85-89: planner, designer, implementer, reviewer, each as `subagent_type: <name>`. "every planner ... then every implementer, then every reviewer" :83. Verdict section :112-117: `Ship allowed: no` → fix run, at most `Max attempts`. Report :126-137.
- `method/commands/po-status.md` (41 lines). Reads settings :11 (no `QA stage`). Per-story bullets :23-31 (design :26, record :28, review :29). Output table and "Next" chain :38. Read-only Bash :13.
- `method/commands/po-review.md` (39 lines). No Bash (frozen by `tests/review.test.sh:178`). Loop number :25. Outcome :37-39: any `Ship allowed: no` → "/po-execute <id> (fix run)".
- `method/commands/po-help.md`: `/po-qa` under step 3 (:31); orchestrator line :36; drive line :37 (frozen word for word by `tests/fleet-wiring.test.sh:49`).
- `README.md`: story cycle table :111-118 without QA; flotte paragraph :126.

## Attachment points
- Orchestrator: insert `## Stage 6 — QA` after Stage 5; renumber Review to 7 and Ship to 8 (`## Stage 8 — Ship — checkpoint`). Stage 7 splits the blocked branch.
- Drive: `## Checks` (:21-25), `## Resuming` table (:44-55) and its paragraphs, `### Dispatching` list (:85-89) and stage sentence (:83), `## The verdict, and the fix runs` (:117), `## Report` (:135).
- Status: step 3 bullets, step 5 table and "Next".
- Review: Preconditions :25, Outcome :37-39.

## Verified interfaces
- `po-gate qa-current <id>` — `method/hooks/po-gate.sh:66-78`: refuses with no report, last `QA status:` not `complete`, no 40-hex `Tree:`, or code outside `docs/` changed since; reads no setting (ADR-0029). Reads the working tree, so an uncommitted current report passes (s52 review m2, `docs/reviews/s52-qa-wiring.md:71-74`).
- The reviewer blocks on a failing `qa-current` with `/po-qa <id>` as `Next action:` (`method/skills/review-antihallu/SKILL.md:27`); `Next action:` sits in `## When blocked` of `method/templates/review.md:13`.
- `/po-qa` prompt to `subagent_type: qa` (`po-qa.md:30-32`); preconditions (`po-qa.md:21-27`): registered worktree, `docs/verif/<id>.md` present, `Dev` not `—`, a screen. Evidence commit (`po-qa.md:36-42`): branch check, `git -C <path> add -- docs/qa/<id>/`, `git -C <path> commit -m "<id>: QA evidence" -- docs/qa/<id>/`, never `--no-verify`, also for a `blocked` report.
- `qa` agent stops itself on `Dev: —` and writes no report (`qa.md:29`); a walk that cannot start writes `QA status: blocked` (`qa.md:41`); no commit (`qa.md:52`).
- Pre-commit lets a `docs/`-only commit through on an unvalidated plan; checked by the s52 reviewer (`docs/reviews/s52-qa-wiring.md:44`).
- `QA stage` exists in the template (`method/templates/agents-local.md:21,49`), so `settings_read_by` checks pass.
- `/po-execute` treats any review whose last verdict is `no` as a fix run (`method/commands/po-execute.md:26`); fix-run commits are `<id>: address review findings` (`method/agents/implementer.md:45`).
- `bin/po-lint:164-181`: in `## Checks`/`## Preconditions`, an arrow line whose trigger names an absence must say stop, ask, carry on or never blocks.

## Traps
Frozen phrases (keep verbatim):
- `tests/drive.test.sh:45-47` and `tests/fleet-design.test.sh:51-53` require the wave's `subagent_type:` order to be exactly `planner designer implementer reviewer` → update both to `planner designer implementer qa reviewer` (story note). No other `subagent_type:` may appear in `## A wave`.
- `tests/drive.test.sh:202-208`: rows containing `record current, review blocked` and `review whose last \`Ship allowed:\` is \`no\`` must each match one line; new rows must not contain either substring. `:245-249`: rows with `Reviewed tree:` + `the review stage`; new rows must not contain `Reviewed tree:`.
- `tests/resume.test.sh:22,26-27`: the code-stage row, `a fix run, at loop \`Fix loop:\` + 1`, `nothing — the story is done`.
- `tests/drive.test.sh:89`: `` `Ship allowed: no` sends that lane back to `implementer` as a fix run `` must stay as a substring.
- `tests/review.test.sh:186`: `` its `Fix loop:` value plus one is this review's loop number `` must stay.
- `tests/pilot.test.sh:11-12`: exactly two `## Stage .* — checkpoint` headings. `tests/wiring.test.sh:62-65,83,85`: headings `Stage N — Design` before `Stage 4 — Plan — checkpoint`, and `Stage 5 — Execute` stays as is.
- `tests/fleet-wiring.test.sh:49`: the help's drive line; `tests/distribution-wiring.test.sh:86-107`: every backticked `docs/…` path in the README must exist unless it holds `<` — write `docs/qa/<id>/`.
- `tests/drive.test.sh:152`: no backquoted `` `cd `` in `po-drive.md`.
- `tests/overlap.test.sh`: no 8-word run shared with Killer SaaS; write fresh prose.
- Commits on `story/<id>`: the QA evidence commit is not an implementer commit; `po-drive.md:59`'s count must exclude it.
- `po-flow.md` (not owned) runs no QA: a screen story on the short track under `QA stage: screens` would block at review and enter a fix run.
- No migration, no code: method markdown and bash tests only.

## Open questions
- Where a QA return is bounded: one QA walk per implementer commit suffices when nothing else moves the code, but a reviewer that keeps answering "blocked on QA" on a current report would loop. The plan settles a bound.
- Should a `QA status: blocked` report trigger a new walk on resume, or a human? A walk that could not start (no server, no browser) usually fails the same way again.
- `/po-flow` and `/po-execute :26` keep routing a QA-blocked review to a fix run when run by hand; neither is owned. The orchestrator can avoid `/po-flow` for screen stories under `QA stage: screens`; the rest stays for a later story.

## Complexity
Story 3 → 3. Markdown and string tests only, but the resume table is a first-match-wins ordering where one misplaced row sends a lane to a fix run with nothing to fix, and the loop accounting crosses three files.

## Split
Not needed.
