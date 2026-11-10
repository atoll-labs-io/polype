---
validated: yes
---
# Plan — s156-qa-report-returned-as-text

[Story](../stories.md) · [Research](../research/s156-qa-report-returned-as-text.md)

Branch `story/s156-qa-report-returned-as-text`. Read `docs/research/s156-qa-report-returned-as-text.md` first; this plan builds on it without repeating it.

## Story
Defect (#148, #88): Claude Code's Write guard refuses a subagent's `report*.md`, so `qa` cannot write `docs/qa/<id>/report.md` and the walk ends with no report to commit. Fix at the cause: `qa` returns the report as its answer; `/po-qa` and `/po-drive` transcribe it verbatim through a quoted heredoc before the evidence commit. Criteria: `qa_returns_its_report`, `po_qa_records_the_report`, `drive_records_the_report`, `qa_report_path_stays`, `adr_records_report_as_text`.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Transcription of a subagent's answer through Bash | already in this repository: `method/commands/po-drive.md:136` (review recorded verbatim through Bash) | — the first rung holds; `/po-qa` and `/po-drive` reuse that rule and wording, no new mechanism |
| Test file | already in this repository: `tests/lib.sh` helpers, `section_of`/`holds` as in `tests/drive.test.sh:8-10` | — first rung holds |

No hook, gate or script code is written: the change is text in three method files, one ADR and tests.

## Tasks
1. [x] **`method/agents/qa.md` returns the report.**
   - Description `:3`: "…and returns its report as its answer, leaving its evidence under docs/qa/<id>/, without fixing anything."
   - `## The report`: replace "Fill `templates/qa.md` into `docs/qa/<id>/report.md`." with: "Fill `templates/qa.md` and return it whole as your final answer; the context that called you writes it to `docs/qa/<id>/report.md` word for word. Never write the report yourself, by Write, Bash or any inherited tool: the harness refuses a subagent's report file, and reaching it by another route would get around a refusal." Keep the `blocked`/`complete` sentences.
   - Step 2: both "write the report with `QA status: blocked`" become "return the report with `QA status: blocked`" (rest of each sentence unchanged).
   - Checks `:30-32`: "write nothing" stays (no evidence); "write no report" → "return no report: your answer carries no `QA status:` line".
   - `## Limits` `:56`: "No commit: your evidence stays uncommitted on the story's branch, and the report travels in your answer."
   - `## Your final message`: "Your final message is the report, filled on `templates/qa.md`, from its title to its `QA status:` line, and nothing before or after it — or, when you stopped before the walk, the reason, with no `QA status:` line."
   - Test that fails if wrong: `test_qa_returns_its_report` (task 6).
2. [x] **`method/commands/po-qa.md` transcribes, then commits.**
   - Description `:2`: "…which checks it with the driver of that surface and returns its report; this command writes that report word for word, then commits the evidence alone. This command cannot edit files; its shell serves that transcription and that commit." (never the words `run a shell`).
   - Intro `:17`: "Bash serves exactly two uses, the transcription and the evidence commit below; any other shell command is out of bounds. The `qa` subagent checks the story's surface with its driver and returns its report; it fixes nothing, and neither does this command."
   - `## The evidence commit`: condition becomes "only when the subagent's answer holds a `QA status:` line, `complete` or `blocked` alike". New step before `add`: branch check stays first, then write the answer whole, word for word, into `<path>/docs/qa/<id>/report.md` through one Bash call: `mkdir -p <path>/docs/qa/<id>` then `cat > <path>/docs/qa/<id>/report.md <<'<DELIM>'`, the answer, `<DELIM>`; the delimiter is quoted so nothing expands, and chosen so that no line of the answer equals it; the text never goes into a shell argument (Law 7), since a report quotes command output. Add: "You transcribe it, you do not author it: no finding added, softened or dropped, no severity or status changed." "No `QA status:` line → no report, no commit; relay the reason the subagent gave."
   - `## Report`: replace the "never writes a report" sentence with "This command never authors a report: it writes the one the subagent returned, word for word, and when the subagent stops without one, there is none." Relay what the report says (walked, findings by severity and status, not seen, tree) and the path where it was written; end with the commit hash or the reason there is none.
   - Tools unchanged (no Write, no Edit). Test: `test_po_qa_records_the_report`, `test_qa_report_path_stays`.
3. [x] **`method/commands/po-drive.md` transcribes the same way.** In the QA item of `## A wave` (`:107`), **on that same single line**: "When it answers with a `QA status:` line, you write its answer word for word into `docs/qa/<id>/report.md` of the lane's worktree through the quoted heredoc `/po-qa` describes, transcribing it as you do a review (`## The verdict, and the fix runs`), then make the evidence commit exactly as `/po-qa` writes it (ADR-0029, ADR-0034, ADR-0102): …". "No report" becomes "An answer with no `QA status:` line → no report, and the lane stops with the reason the subagent gave." Keep `the prompt \`/po-qa\` fixes`, `QA evidence`, `-- docs/qa/<id>/`, the blocked sentence and `every qa of a wave leaves before any of them is waited on`. Line `:18` already says Bash "records what a subagent handed you": leave it. Test: `test_drive_records_the_report`; `tests/qa-fleet.test.sh:46-62` must stay green.
4. [x] **ADR-0102** `docs/decisions/ADR-0102-le-rapport-de-qa-revient-en-texte.md`, in French, from `templates/adr.md`: `status: accepted`, `date: 2026-11-10`, `scope: story s156-qa-report-returned-as-text`, `supersedes: [ADR-0029]`, `superseded-by: []`. Context: the guard (subagent, basename `report*.md`, Claude Code 2.1.322) and the three projects of #148/#88. Decision: `qa` returns the report; the coordinating context (`/po-qa`, `/po-drive`; `/po-orchestrator` through `/po-qa` as written) transcribes it verbatim through a quoted heredoc before the evidence commit; `qa` keeps writing its evidence. Replaces ADR-0029 on one point only: `/po-qa`'s Bash goes from one use (the commit) to two (transcription and commit); completes ADR-0034 without replacing it. Say why a quoted heredoc is allowed here while `/po-ship` keeps finding text out of heredocs (a file write with no expansion versus text bound for the tracker; the delimiter chosen absent from the report). Options turned down: the agent writes the report through Bash (gets around a harness refusal; two different routes were already taken, #148); Write for `/po-qa` like `/po-review` (a command without Write or Edit edits no repository file, and `/po-drive` already transcribes reviews through Bash); renaming the report so its name escapes the guard (dodges a rule whose intent is explicit, and moves a path that `po-gate qa-current`, the review, `/po-status` and `/po-retro` read). Test: `test_adr_records_report_as_text`.
5. [x] **ADR-0029 frontmatter only**: `superseded-by: [ADR-0037]` → `superseded-by: [ADR-0037, ADR-0102]`; status and body unchanged. Test: `test_adr_records_report_as_text`.
6. [x] **`tests/qa-report-returned-as-text.test.sh`** (header `# s156 — the QA report comes back as text and the coordinator writes it.`), five functions named after the criteria, each quoting short exact phrases of tasks 1-5 inside the right section (`section_of` per file, as `tests/drive.test.sh:8`):
   - `test_qa_returns_its_report`: `## Your final message` of `qa.md` holds `Your final message is the report`; `## The report` holds `return it whole as your final answer` and `Never write the report yourself`; `qa.md` no longer holds `write the report with` nor `into \`docs/qa/<id>/report.md\`.` in `## The report`; `## Report` of `po-qa.md` holds `the path where it was written`.
   - `test_po_qa_records_the_report`: `## The evidence commit` holds `<<'`, `word for word`, `no line of the answer equals it`, `you do not author it`, `No \`QA status:\` line → no report, no commit`; and the transcription step comes before `git -C <path> add -- docs/qa/<id>/` (line order); `lacks_tool` Write and Edit; `Bash serves exactly two uses`.
   - `test_drive_records_the_report`: the single `subagent_type: qa` line of `## A wave` holds `word for word into \`docs/qa/<id>/report.md\``, `quoted heredoc`, `no \`QA status:\` line`, and the transcription phrase comes before `git -C <absolute path> add` on that line.
   - `test_qa_report_path_stays`: `po-qa.md` holds `docs/qa/<id>/report.md` and `commit -m "<id>: QA evidence" -- docs/qa/<id>/`, and `## The evidence commit` holds `` `complete` or `blocked` alike ``; `qa_current` of `method/hooks/po-gate.sh` still reads `docs/qa/$1/report.md`.
   - `test_adr_records_report_as_text`: ADR-0102 exists, frontmatter `supersedes: [ADR-0029]`, body names `ADR-0034` and the three turned-down options by a short phrase each; ADR-0029 frontmatter holds `superseded-by: [ADR-0037, ADR-0102]` and `status: accepted`.
   Run: `bash tests/run.sh qa-report-returned-as-text.test.sh`.
7. [x] **Frozen phrases the story changes** (in `Owns`; the clause they check changes): `tests/qa.test.sh:47` → `This command never authors a report`; `tests/qa.test.sh:52` → `return no report`; `tests/qa-drivers.test.sh:34` and `tests/qa-evidence-set-aside.test.sh:22` → `return the report with \`QA status: blocked\``. Run those four files, then `tests/qa-fleet.test.sh`, `tests/qa-gate.test.sh`, `tests/drive.test.sh`, `tests/model-routing.test.sh`, `tests/ownership.test.sh`, `tests/lint.test.sh`, `tests/overlap.test.sh`.
8. [x] Full suite once, through `po-run --story s156-qa-report-returned-as-text --label test -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- `method/commands/po-orchestrator.md`, `method/hooks/po-bounds.sh`, `method/hooks/po-gate.sh`, `method/templates/qa.md`, `method/skills/qa-drivers/` (all files), `method/AGENTS.md`, `.claude/`, `.polype/`: empty diff. `qa-drivers` says nothing about who writes the report (research), so it stays untouched although in `Owns`.
- `docs/decisions/ADR-0029-…md`: the diff is the `superseded-by:` line alone (`git diff main -- docs/decisions/ADR-0029*` shows one changed line). ADR-0034 and ADR-0026: empty diff.
- `po-qa.md` frontmatter `allowed-tools` unchanged: no Write, no Edit.
- The report path `docs/qa/<id>/report.md` and the commit message `<id>: QA evidence` appear unchanged in `po-qa.md` and `po-drive.md`.
- No reformulation of `/po-orchestrator`'s step list (owned by s149); the follow-up is an issue the lead files.
- No ADR other than ADR-0102. No test outside `Owns` edited.

## The pivot
The fix rests on **the coordinating context writing the subagent's answer, byte for byte, through a quoted heredoc**. Ways it could be wrong:
- A report line equal to the delimiter ends the heredoc early, and the rest runs as shell. Compare against the rule written in task 2 (delimiter absent from the answer) and ADR-0102's justification against `method/commands/po-ship.md:89`.
- `qa` may prefix its answer with chatter; verbatim transcription carries it into `report.md`. `po-gate qa-current` reads only the last `^QA status:` and its paired `Tree:` (`method/hooks/po-gate.sh:205-208`), so the gate holds, but check that `qa.md` asks for the report alone.
- `/po-drive`'s QA item must stay one line (`tests/qa-fleet.test.sh:52`); a line break there fails an existing test, not the new ones.

## Files touched
`method/agents/qa.md`, `method/commands/po-qa.md`, `method/commands/po-drive.md`, `docs/decisions/ADR-0102-le-rapport-de-qa-revient-en-texte.md` (new), `docs/decisions/ADR-0029-po-qa-committe-les-preuves-qa.md` (frontmatter), `tests/qa-report-returned-as-text.test.sh` (new), `tests/qa.test.sh`, `tests/qa-drivers.test.sh`, `tests/qa-evidence-set-aside.test.sh`, plus `docs/research/` and `docs/plans/` of this story.

## Test strategy
Automated: five new text-contract tests, one per criterion, in `tests/qa-report-returned-as-text.test.sh` (s149 has not landed, so no oracle file); four frozen phrases updated in existing tests. 5 new tests, within `Test budget` 25. Each quotes a phrase only the new rule carries, so deleting the rule (restoring "Fill … into `docs/qa/<id>/report.md`", dropping the heredoc step, or the ADR line) turns it red. No test runs the harness guard: it lives in Claude Code, not in this repository. Visual checks: none.

## Done when
One commit on `story/s156-qa-report-returned-as-text` with the code, research and plan; full suite green through `po-run`; a review with no open critical finding; at ship, #88 closed as a duplicate of #148 (see the research's open question on #148's state).
