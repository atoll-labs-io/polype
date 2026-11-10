# Review: s156-qa-report-returned-as-text

Reviewed tree: 0ca9bd9d3233fc77d78af4923e5d15b21e63f441
Fix loop: 0
Scope: `git diff origin/main...story/s156-qa-report-returned-as-text` (one commit, 2b4fa49)
Lenses run: none. No path or content in the diff matches the security, migration, dependencies or performance triggers. The change is method text, one ADR and bash tests.

## Scope check (Owns)
I checked the 13 changed paths against the story's `Owns` line in `docs/stories.md:2495`, which I read at the branch tip, after the fork point 7046061 that carries PR #177.
- In `Owns`: `method/agents/qa.md`, `method/commands/po-qa.md`, `method/commands/po-drive.md`, `docs/decisions/ADR-0102-le-rapport-de-qa-revient-en-texte.md`, `docs/decisions/ADR-0029-po-qa-committe-les-preuves-qa.md`, `tests/qa-report-returned-as-text.test.sh`, `tests/qa.test.sh`, `tests/qa-drivers.test.sh`, `tests/qa-evidence-set-aside.test.sh`, `tests/leftovers.test.sh`.
- The story's own evidence (research, plan, verif) is in scope by construction.
- No path lies outside `Owns`.
- `git worktree list` shows no other running story lane, so nothing overlaps another story.
- The plan's run interdicts hold:
  - `po-orchestrator.md`, `po-bounds.sh`, `po-gate.sh`, `templates/qa.md` and `qa-drivers/` are untouched.
  - The ADR-0029 diff is the single `superseded-by:` line.
  - The `allowed-tools` of `po-qa.md` are unchanged: no Write, no Edit.

## What I relied on
- **Step 1, record:** `po-gate verif-current` exits 0 (`Verification mode: record`). The unit suite is `bash tests/run.sh`; its last row exited 0 on code equal to `Tree:` outside `docs/`. I did not rerun it. I read the record's "Not proven here" section. The project has no `Typecheck`, `E2E` or `Build` command: all three are `—`.
- **QA:** the story's `Surface` is `—` and `QA stage` is `—`, so the story does not go to QA and there was no QA to require.
- **Step 4, floor:** `po-gate floor-guard s156-qa-report-returned-as-text origin/main` exits 0. Nothing was lowered.
  - The four frozen phrases the story changes (`qa.test.sh`, `qa-drivers.test.sh`, `qa-evidence-set-aside.test.sh`, `leftovers.test.sh`) are named in plan task 7 and in the record.
  - The ADR-0029 line in `leftovers.test.sh` is justified by PR #177.
- **Step 4, bite:**
  1. I deleted step 2 of `## The evidence commit` in `method/commands/po-qa.md` (the heredoc transcription) and ran `qa-report-returned-as-text`, `qa`, `qa-gate` and `qa-fleet`: 1 test failed (`po_qa_records_the_report`). I restored the file; `git diff --exit-code` was clean.
  2. I put back the old first sentence of `## The report` in `method/agents/qa.md` ("Fill `templates/qa.md` into `docs/qa/<id>/report.md`.") and ran `qa-report-returned-as-text`, `qa`, `qa-drivers` and `qa-evidence-set-aside`: 1 test failed (`qa_returns_its_report`). I restored the file; `git diff --exit-code` was clean.
  - Both rules are tested. The worktree is clean afterwards.
- **Test budget:** 5 new tests, within `Test budget` 25.
- **Steps 2 and 6, references and neighbours:**
  - Every reference exists: `## The verdict, and the fix runs` (`po-drive.md:135`), the `qa_current` function of `po-gate.sh`, `po-ship.md:89`, ADR-0034, and the `section_of`/`frontmatter` helpers.
  - Readers of `docs/qa/<id>/report.md` (`po-gate.sh:203-219`, `po-session.sh:222`, `po-status.md:29`, `po-retro.md:39`, `reviewer.md:25`) still read the same path.
  - `po-orchestrator.md:70` follows `/po-qa` as written, which the story's notes accept.
  - The `.txt` transcripts question from the story's notes is settled by the research (line 8): those files do not match the harness guard.
- **Oracle file:** the plan says "s149 has not landed, so no oracle file". That was true when the plan was written, at fork point 4a355fe. s149 shipped before the fast-forward to 7046061, so it is not a defect.

## Findings
- **major** — `method/commands/po-qa.md:40` (`## The evidence commit`), with `method/commands/po-drive.md:58` and `method/commands/po-orchestrator.md:70`. The evidence commit now runs "only when the subagent's answer holds a `QA status:` line" and opens with step 2, which writes "the answer" into `report.md`. But two existing paths send the coordinator to "the evidence commit of `/po-qa`, without a new walk": the resume row of `/po-drive` (`qa-current` refuses with `is current but`), and the "blocked on QA evidence" path of `/po-orchestrator`, `po-drive.md:141` and the reviewer. In those paths there is no answer, and the report is already on disk.
  - Read literally, the commit section now either never runs there, which loops the lane, or runs `cat > report.md <<'…'` with no answer, which empties a valid report.
  - The diff left those callers as they were and did not say how the commit-only path fits the new section.
  - Fix: say in `## The evidence commit` that when no walk ran and a current report is already on disk, step 2 is skipped and steps 1, 3 and 4 apply.
- **minor** — `method/commands/po-drive.md:107`. Here the transcription comes before "the branch confirmed as `story/<id>`". `/po-qa` does it the other way: branch check first, and "stop without writing or committing". The line also claims to do the commit "exactly as `/po-qa` writes it". Move the transcription after the branch check so the two match.
- **minor** — `docs/decisions/ADR-0102-le-rapport-de-qa-revient-en-texte.md`, Decision Outcome, third paragraph. It says `/po-ship` "envoie ce texte vers le tracker, à travers des arguments de commande". That is not what `po-ship.md:89` says: there the text goes from the review file to a file, then to the tracker, and the rule is that it never enters an argument, a heredoc or an `echo`. The contrast the ADR wants is "text bound for the tracker, carried only by files" against "a file write through a quoted heredoc". Fix this sentence before the ADR is accepted on `Target branch`, since an accepted ADR's body is never rewritten.

## Not verified
- **The harness guard itself.** I did not observe Claude Code's Write refusing a subagent's `report*.md`. It lives outside this repository; the evidence is the research and the field reports in #148 and #88. A person should run one real `/po-qa` on a project with a screen and confirm the report lands and is committed.
- **The heredoc transcription.** No test runs it on a real report: one holding a line equal to a likely delimiter, `$(…)` or backticks. The tests check only the text contract. A person or a later story could run one transcription by hand on a report that quotes command output.
- **The `/po-drive` and `/po-orchestrator` QA stages.** Neither was run end to end. Only their text was checked.
- **Issue tracking at ship.** Whether #88 gets closed as a duplicate and how #148's `CLOSED` state is handled is left to the lead at ship (research, open question).

Review status: complete
Max severity: major
Ship allowed: yes
