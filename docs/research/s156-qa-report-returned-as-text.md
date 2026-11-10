# Research — s156-qa-report-returned-as-text

[Story](../stories.md)

## Structuring facts
- Root cause: the Write tool of Claude Code 2.1.322 refuses, in a subagent only (`s.agentId`), any file whose basename matches `/^(REPORT|SUMMARY|FINDINGS|ANALYSIS).*\.md$/i`, with "Subagents should return findings as text, not write report files. Include this content in your final response instead." (`~/.local/share/claude/versions/2.1.322`, byte 294768292, `validateInput` of the Write tool). `method/agents/qa.md:52` sends the `qa` subagent to Write exactly `docs/qa/<id>/report.md`, a basename the guard matches.
- Nothing downstream can land a returned report: `/po-qa` commits only when `docs/qa/<id>/report.md` already exists (`method/commands/po-qa.md:40`) and "never writes a report" (`:48`); `/po-drive` stops the lane on "No report" (`method/commands/po-drive.md:107`). The walk's text is lost and its captures are orphaned (#148, lagon 2026-11-10).
- The story's assumptions hold. Its open question settles in its favour: the `.txt` transcripts (`method/skills/qa-drivers/scenarios.md:30`), `viewpoints.txt` (`scene.md:39`), `simulation.txt` (`simulation.md:39-41`) and PNG captures do not match the guard; no gap there.
- The transcription model exists: `/po-drive` already records a reviewer's answer verbatim through Bash (`method/commands/po-drive.md:136`); the guard aims at subagents only, so the coordinating context writing the file is the path the harness itself asks for.
- s149 has not landed (no `*.oracle.test.sh` in `tests/`, `method/templates/plan.md` has no `## Acceptance tests`): the criteria's functions go in `tests/qa-report-returned-as-text.test.sh`.

## Diagnostic
**Reproduction.** A `qa` subagent cannot be dispatched from this lane (no Agent tool), and creating files to reproduce is out of bounds. Reproduced instead at the guard itself: the predicate read in the installed binary, run through `node -e` on the paths a walk writes:

| Path | basename matches | full path matches |
| --- | --- | --- |
| `docs/qa/s01/report.md` | true | false |
| `docs/qa/s01/home.png`, `criterion-error.txt`, `viewpoints.txt`, `report.txt` | false | false |
| `docs/research/<id>.md`, `docs/plans/<id>.md`, `docs/reviews/<id>.md` | false | false |

The anchored `^` on an absolute path can only match a basename, so the guard reads the file name. Three field reproductions agree: lophelia 2026-10-14 (#88), nacre 2026-10-22/23 and clione 2026-10-24/25 (#148, its comments), lagon 2026-11-10 (#148, last comment): Write of `report.md` refused, PNGs and transcripts written.

**Hypotheses.**
1. *`po-bounds` (Polype's own hook) refuses the write.* Refuted if the message is absent from `method/hooks/`: `grep -rn "Subagents should return" method/` finds nothing, and `po-bounds` mode qa allows Write under `docs/qa/<id>/` (`method/agents/qa.md:20`). **Discarded.**
2. *The harness refuses every subagent write of a `.md` file, or everything under `docs/`.* Refuted if a subagent writes another `.md` there: planners write `docs/research/<id>.md` and `docs/plans/<id>.md` in every lane, and the predicate above returns false for them. **Discarded.**
3. *The harness's Write guard refuses a subagent's file named `report*.md`, and `qa.md` asks for that very name.* Refuted if the predicate did not match `report.md` or applied to the main context too: it matches, and it is conditioned on `s.agentId`. **Kept** (binary byte 294768292; the PNGs of lagon passed, as the predicate predicts).

## Story
`qa` returns its whole report, filled on `templates/qa.md`, as its final answer instead of writing it; it keeps writing its evidence under `docs/qa/<id>/`. `/po-qa` and `/po-drive` transcribe that answer verbatim into `docs/qa/<id>/report.md` through a quoted heredoc, before the `<id>: QA evidence` commit, only when it holds a `QA status:` line. Report path and commit stay. ADR-0102 records it, supersedes ADR-0029 on one point (scope of `/po-qa`'s Bash), completes ADR-0034.
Criteria: `qa_returns_its_report`, `po_qa_records_the_report`, `drive_records_the_report`, `qa_report_path_stays`, `adr_records_report_as_text`.

## Current code
- `method/agents/qa.md` — `:3` description "leaves a report with its evidence under docs/qa/<id>/"; `:30-32` Checks that stop with "write nothing" / "write no report"; `:44` step 2 "write the report with `QA status: blocked`" twice (missing driver file; no row / `Platform` unset); `:49` step 7 "the report ends in `QA status: blocked`"; `:51-52` `## The report` "Fill `templates/qa.md` into `docs/qa/<id>/report.md`"; `:56` "No commit: the report and its evidence stay uncommitted"; `:58` a po-bounds refusal is a stop, never reached by another route; `:60-61` `## Your final message` is a summary ending with "the path of the report".
- `method/commands/po-qa.md` — `:2` description "its shell serves that one commit"; `:4-9` tools Read, Glob, Grep, Agent, Bash; `:17` "Bash serves exactly one use, the evidence commit below"; "The `qa` subagent ... writes its report"; `:39-45` `## The evidence commit`, conditioned on the file existing (`:40`), steps branch check / `git add -- docs/qa/<id>/` / `git commit -m "<id>: QA evidence" -- docs/qa/<id>/`; `:47-49` `## Report` "This command never writes a report: when the agent stops, there is none."
- `method/commands/po-drive.md` — `:18` Bash "records what a subagent handed you and makes the QA evidence commit"; `:107` the QA stage item, one line: evidence commit "exactly as `/po-qa` writes it (ADR-0029, ADR-0034)", "No report → the lane stops with the reason the subagent gave", blocked committed then human; `:136` review recorded **verbatim** through Bash, "You transcribe it, you do not author it".
- `method/templates/qa.md:32-33` ends with `Tree:` then `QA status:`; unchanged.
- `method/skills/qa-drivers/SKILL.md:23,26` say "the report names …" without saying who writes it; `:36` "the Write tool reaches only `docs/qa/<id>/`". Nothing to change (the story's note).
- `method/commands/po-orchestrator.md:67` applies `/po-qa` "as written", "No report → stop with the reason"; owned by s149, not touched.
- `method/hooks/po-gate.sh:202-221` `qa_current`: reads the last `^QA status:` line and the `Tree:` paired with it, then requires `docs/qa/<id>/` committed. Text after the status line does not break it.
- `docs/decisions/ADR-0029-po-qa-committe-les-preuves-qa.md:8-9` `supersedes: []`, `superseded-by: [ADR-0037]`, status accepted; ADR-0034 `superseded-by: [ADR-0041]`.

## Attachment points
- `qa.md`: `## The report` (where the report goes), step 2 of `## The walk` (the two blocked cases), `## Limits` (no Bash route for the report), `## Your final message`, the description line `:3`.
- `po-qa.md`: the intro `:17`, `## The evidence commit` (transcription before commit, new condition), `## Report`, the description `:2`.
- `po-drive.md:107`: the QA item, same line (see Traps).
- New `docs/decisions/ADR-0102-le-rapport-de-qa-revient-en-texte.md`; ADR-0029 frontmatter line `:9`.
- New `tests/qa-report-returned-as-text.test.sh`.

## Verified interfaces
- Test helpers: `contains`, `lacks_tool`, `needs_tool`, `require_file`, `frontmatter`, `fail` (`tests/lib.sh:11-43`); `section_of` and `holds` are redefined per file (`tests/drive.test.sh:8-10`).
- `po-lint` flags a frontmatter saying `cannot edit files or run a shell` with Bash declared (`bin/po-lint:142-145`); `tests/qa-gate.test.sh:107` refuses `run a shell` in `po-qa.md`'s frontmatter.
- ADR template `method/templates/adr.md`; ADRs are in French; frontmatter lists `[ADR-…]`.

## Traps
- Tests freezing phrases that the story changes, all in `Owns`: `tests/qa.test.sh:47` ("This command never writes a report: when the agent stops, there is none."), `tests/qa.test.sh:52` ("write no report"), `tests/qa-drivers.test.sh:34` and `tests/qa-evidence-set-aside.test.sh:22` ("→ write the report with `QA status: blocked`, …").
- Tests that must keep passing: `tests/qa-fleet.test.sh:46-62` wants the QA item of `## A wave` on **one line** (`only_line`) holding `the prompt \`/po-qa\` fixes`, `QA evidence`, `-- docs/qa/<id>/`, `every qa of a wave leaves before any of them is waited on`; `tests/qa-gate.test.sh:103-109` (Bash yes, Write/Edit no, `commit -m "<id>: QA evidence" -- docs/qa/<id>/`); `tests/drive.test.sh:64-65`; `tests/model-routing.test.sh:51-54,102-106` (`## Delegation` of `po-qa`); `tests/ownership.test.sh:105-110`; `tests/qa-evidence-set-aside.test.sh` (`SET_ASIDE_PARENT` in `qa.md` step 7).
- A walk blocked at step 2 may have written no evidence: `docs/qa/<id>/` may not exist when the coordinator transcribes, so the write needs `mkdir -p` first.
- `method/commands/po-ship.md:89` forbids review text in "a shell argument, a heredoc or an `echo`" for tracker filing. The story chooses a quoted heredoc for a file write; with `<<'DELIM'` nothing expands, and the only remaining hazard is a report line equal to the delimiter. ADR-0102 must say why it differs from po-ship's rule.
- Overlap check (`tests/overlap.test.sh`): no 8-word run copied from Killer SaaS.
- s157 runs in parallel on `po-bounds.sh` and ADR-0026/0103: no shared path.
- No migration, no dependency, no new setting.

## Open questions
- #148 shows `CLOSED` (2026-11-10T18:05Z, `completed`) while #88 is open; the story expects #88 closed as a duplicate of #148 at ship. Who reopens or leaves #148 is for the lead at ship, not for this plan.
- The final answer of `qa` may carry text before the report; transcribed verbatim, it lands in `report.md`. The plan asks `qa` for the report alone; whether the coordinator strips a preamble is decided as "no" (verbatim).

## Complexity
Story 3 → 3. Three method files, one ADR, one frontmatter line, one new test file and four frozen phrases; no hook or gate code changes.

## Split
—
