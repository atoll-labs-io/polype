# Review — s158-review-header-recorded

[Story](../stories.md) · [Plan](../plans/s158-review-header-recorded.md) · [Verification](../verif/s158-review-header-recorded.md)

Diff reviewed: `git diff main...story/s158-review-header-recorded`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 3f18f0f62f9544cdb614f6d5d09afb3fbe5913b9

## Ownership
Diff listed with `git diff --name-only main...story/s158-review-header-recorded`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`: `method/agents/reviewer.md`, `method/commands/po-drive.md`, `method/commands/po-review.md`, `method/templates/review.md`, `tests/review-header-recorded.oracle.test.sh` and ADR-0104 are all listed in `Owns`. ADR-0104 is also added (status `A`) and named by the plan. `docs/research|plans|verif/s158-review-header-recorded.md` are the story's own evidence.
- [x] Outside `Owns`: none
- [x] Inside another running story's `Owns`: none. `git worktree list` shows no other `story/*` lane, only `main` and `.claude/worktrees/qa-report-and-bounds` (branch `worktree-qa-report-and-bounds`, not a story branch).
- [x] The story has an `Owns` line

## Evidence reused
- [x] `po-gate verif-current s158-review-header-recorded` exits 0, so I reused the record. The project has no type check (`Typecheck: —`). The record's `Tree: 7edd4f72…` has a passing `bash tests/run.sh` row (exit 0). Its "Not proven here" section says no test records a real review end to end.
- [x] `po-gate qa-current`: not required, because `QA stage: —` and `Surface: —`, so the story does not go to QA.

## Plan
- [x] Each task is present and nothing is outside the plan. Tasks 1–6 match the diff word for word: the `## Recording` paragraph, `:37` and `:41` rewritten, the Delegation prompt, the first two sentences of `po-drive.md:136`, the `reviewer.md` `## Your answer` sentences, the template note and ADR-0104 with its options in the required order.
- [x] I checked each run interdict:
  - The diff on `po-gate.sh`, `po-bounds.sh`, `bin/po-link-artifacts`, `po-orchestrator.md`, `po-flow.md`, `po-ship.md`, `po-qa.md`, `qa.md`, `templates/qa.md`, `method/AGENTS.md`, `.claude/` and `.polype/` is empty.
  - The oracle cksum is `2523056994 6685`, as the plan says, and `po-gate oracle-intact` exits 0.
  - No existing test changed, and `tests/review-header-recorded.test.sh` was not created.
  - The `allowed-tools` of `po-review.md` and its findings-shape paragraph are unchanged.
  - `templates/review.md` gains two lines and loses none.
  - No other review or ADR was touched.
  - No conditional insertion was added.

## References
- [x] I opened every referenced target and confirmed it:
  - `bin/po-link-artifacts:15` reads the link line as the first non-blank line after the title, and `:20-31` drops a missing target. The recorder rule restates this.
  - `po-gate findings-shape` reads only the last verdict block.
  - `/po-orchestrator:73` and `/po-flow:89` record "as `/po-review` says", so they inherit the rule.
  - `po-drive.md:108` dispatches the reviewer with the `/po-review` prompt word for word, so the new prompt clause reaches the fleet.
  - `/po-review` has Write and Glob, which is enough to write the header and check link targets.
- [x] No value that only looks right. The link line is byte-for-byte unchanged and the note sits after it.

## Rules
- [x] `AGENTS.md` conventions are respected: method text in English, ADR in French from `templates/adr.md`, installed copies untouched.
- [x] No accepted ADR is contradicted. ADR-0104 narrows the verbatim rule to everything below the header and states that explicitly.

## Tests
- [x] Floor: `po-gate floor-guard s158-review-header-recorded main` exits 0, so nothing was lowered.
- [x] The assertions pin down the five acceptance criteria. None of the six empty test shapes appear. `template_marks_the_header` builds a review the way the rule says and runs the real `bin/po-link-artifacts` on it.
- [x] 5 tests, within `Test budget` 25.
- [x] Bite:
  - I deleted the first paragraph of `## Recording` in `method/commands/po-review.md`. 1 test failed (`recorder_writes_the_header`). I undid it with `git checkout`, and `git diff --exit-code` was clean.
  - I moved the template note above the link line, which is the failure mode named in the plan's pivot section. 3 tests failed: `template_marks_the_header`, plus `links_resolve` and `templates_carry_links` in `artifact-link-templates.test.sh`. I undid it, and `git diff --exit-code` was clean.
- [x] No test is made useless by the story.

## Neighbours
- [x] I read the other callers. `/po-orchestrator`, `/po-flow`, `/po-execute` (fix run), `/po-status`, `/po-retro` and `/po-ship` read the verdict lines and `Fix loop:`, never the title, so nothing breaks. The one ambiguous cross-reference is `po-drive.md:107`, listed under Findings.

## Lenses
Lenses run: none (method text, an ADR and a bash text-contract test; no security, migration, dependency or server path or content).
- [x] No lens findings.

## Findings
- minor — method/commands/po-drive.md:107 — The QA stage tells the driver to transcribe the qa answer "as you do a review (`## The verdict, and the fix runs`)". That section's first sentence now also says to write the title and link line of `templates/review.md` first. A literal reading could put a review header on top of `docs/qa/<id>/report.md`, which already carries its own title and link line under ADR-0102. A later cycle should limit that cross-reference to the verbatim transcription.
- minor — method/commands/po-review.md:37 — "starts with the title line and the link line of `templates/review.md` … then one blank line" does not say whether the blank line between the title and the link line is kept. The template and the oracle keep it, and `bin/po-link-artifacts` accepts both forms, so it works either way. Saying "the template's first three lines" would leave no room for drift.

## Not verified
- **No real recording ran.** The recorder is a model following text, so no test runs a real `/po-review` or `/po-drive` recording. A person should check the next review recorded with the refreshed installed method: it should open with `# Review — <id>`, a blank line and the link line, and pass `bash tests/run.sh artifact-links-backfill.test.sh`.
- **This review ran under the old installed method.** It was dispatched with the old prompt and the installed `.claude/agents/reviewer.md`, both from before s158, and those still ask for the template shape. So this answer includes the title and link line itself. If the recorder also applies the new rule, the file gets a doubled header. ADR-0104 accepts this, and the backfill test reads only the first title. A person should check that `docs/reviews/s158-review-header-recorded.md` passes `tests/artifact-links-backfill.test.sh` before ship.
- **Full suite and the backfill test not re-run here.** The record covers them for this code. I ran only the oracle test and `artifact-link-templates.test.sh` during the bite checks.
- **No type check, end-to-end or build.** The project has no such commands (`—`).

Max severity: minor
Ship allowed: yes
