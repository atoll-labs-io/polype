# Review — s33-real-parallelism

Diff reviewed: `git diff m3-flotte...story/s33-real-parallelism`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0

## Evidence reused
- [x] `po-gate verif-current s33-real-parallelism` → passes (exit 0). `docs/verif/s33-real-parallelism.md` `Tree: 36068dd…` matches `HEAD` (`51f3d4d`) outside `docs/` — `git diff --quiet 36068dd HEAD -- . ':(exclude)docs'` exits 0. Under `Verification mode: record` I reused it: unit suite `bash tests/run.sh` exit 0, 168 passed / 0 failed; `bin/po-lint` exit 0 on 22 method files. I did not rerun them.
- Type check, E2E and Build: the project declares `Typecheck: —`, `E2E: —`, `E2E stage: —`, `Build: —`, `Build stage: —`. The project has none; I substituted nothing.
- Record's "Not proven here" read: it concedes that every check here reads a document, never an agent's behaviour, and that the ADR-gap policy has never been exercised. Both are true and both shape my findings.

## Plan
- [x] Task 1 — `docs/defauts.md` fleet rows renumbered 22/23/24 → 25/26/27. Done; `grep -oE '^\| [0-9]+ \|' docs/defauts.md | sort | uniq -d` prints nothing (re-run here).
- [x] Task 2 — no-drift paragraph at `method/commands/po-drive.md:63`, under `## A wave`, before `### Preparing the lanes`. Done, and no backquoted `` `cd `` example anywhere in the file.
- [x] Task 3 — ADR allocation rule at `:72`, end of `### Preparing the lanes`. Done.
- [x] Task 4 — dispatch paragraph `:75` extended, its three pinned sentences byte-identical, no `subagent_type:` in the added text (the order assertion `tests/drive.test.sh:45-47` still passes).
- [x] Task 5 — `## Report` gains `:123`; no existing sentence reworded.
- [x] Task 6 — `method/agents/planner.md:51` extended; `:50` byte for byte.
- [x] Task 7 — four tests appended to `tests/drive.test.sh`, names identical to the four acceptance criteria.
- [x] Task 8 — rows 25-27 `corrigé par s33`; new heading `## Relevés par la recherche de s33 (2026-09-22)` with rows 28 and 29, both `ouvert`. I verified both claims: `AGENTS.local.md` really declares no `Parallel`/`Max attempts`/`Tracker` (they exist only at `method/templates/agents-local.md:29-31`), and `planner.md:50` really says "and no other file" while `:51` has it write an ADR.
- [x] Task 9 — both runs recorded.
- Nothing outside the plan: the diff is 7 files, the four the plan owns plus its own research, plan and record.

Run interdicts, one by one:
- [x] `.claude/` and `.polype/` — absent from the diff.
- [x] `docs/stories.md`, `docs/parite-killer-saas.md`, `docs/conception.md`, `method/AGENTS.md`, `method/templates/agents-local.md`, `docs/decisions/` — all absent from the diff; no new ADR file.
- [x] The five pinned strings present and unchanged (`in a single message`, `one Agent call per lane, all of them in that one message`, `Never two calls for the same story at once`, the `/po-design <id>` mention at `tests/drive.test.sh:130`, and the planner's "and no other file" sentence). Their tests are green.
- [x] No `## Report` sentence reworded — `grouped-validation.test.sh` and `resume.test.sh` green in the reused record.
- [x] No existing test deleted or weakened; the six original `drive.test.sh` tests keep their assertions and pass.
- [x] `tests/overlap.test.sh` green in the reused record.

## References
- [x] `docs/decisions/` holds `ADR-0001…ADR-0017`, named `ADR-NNNN-<slug>.md`, so the driver's `read the highest ADR-NNNN` names a real on-disk shape.
- [x] `section_of` (`tests/drive.test.sh:8`) and `holds` (`:10`) exist and behave as the new tests assume; `require_file` and `contains` exist in `tests/lib.sh:41-43`; `METHOD` is `$ROOT/method` (`:6`), so the tests read `method/`, not the installed copies.
- [x] `method/commands/po-research.md` is quoted for worktree preparation and does describe it.
- [x] `docs/defauts.md` numbering is unique across all four tables (1-29) and nothing outside `docs/stories.md` cross-references the renumbered rows (`docs/validation/` holds only `m1.md`, `m1-sandbox`, `m1-sandbox-v2`, `m2.md`).
- Value checked: `<repository root>/<Worktree root><id>` matches what `/po-research` creates, so "absolute" resolves to the path a lane actually has.

## Rules
- [x] `AGENTS.md` conventions: one test file per story slug reused rather than multiplied, test function names equal to criterion names, short exact phrases quoted, English method text, commit message English with no trailer.
- [x] No new setting introduced, so nothing to add to a `Reads settings:` line; `bin/po-lint` exit 0 confirms.
- [x] No parity-matrix line newly implemented — every fleet row of `docs/parite-killer-saas.md` was already `fait`, so leaving it untouched is correct.
- [x] No accepted ADR contradicted. ADR-0012 (no red-first while implementing) deserves a note: the plan's test strategy told the implementer to "write the test first for each of the four, see it red, then write the sentence", which is the practice ADR-0012 forbids. The record shows what was actually done — each of the 17 phrases checked absent with `grep -qF` before editing — which is a cheap absence check, not a red-first loop. The plan's wording is at odds with the ADR; the execution is not.

## Tests
- [x] Four new tests, 4 of the 25 `Test budget`; `tests/drive.test.sh` now holds ten. No excess, no duplicated assertion.
- [x] None of the six empty shapes. These are document tests — the only layer this repository has — and each greps the real file under test through `section_of`, with no fixture and no mock to subvert.
- [x] Bite, five mutations, each followed by `bash tests/run.sh drive.test.sh` only:
  - `Sending one call per message is forbidden` → `…is acceptable` → 1 failing test (`drive_dispatches_a_whole_stage_in_one_message`)
  - inserted `` You may run `cd <absolute path>` to enter a lane. `` → 1 failing test (`drive_uses_absolute_paths_only`, message naming line 74)
  - `So you assign them before the wave leaves` → `So each lane sorts it out itself` → 1 failing test (`shared_numbering_is_assigned_by_the_driver`)
  - report sentence replaced by `The report also says the wave ran in parallel.` → 1 failing test (`drive_reports_what_it_observed_not_what_it_intended`)
  - planner: `The number is not yours to choose…` replaced by a "take the next free number" sentence → 1 failing test (`shared_numbering_is_assigned_by_the_driver`)
  - Every mutation undone; `git diff --exit-code` exits 0 and `git status --porcelain` is empty. The worktree is back to its committed state.
- [x] No test made useless by the story; none removed.

## Neighbours
- [x] `subagent_type: planner` appears in `method/commands/po-drive.md` and nowhere else in `method/` — `/po-plan`, `/po-flow` and `/po-orchestrator` never dispatch that subagent. The new planner rule therefore changes the fleet path only and regresses no single-story path.
- [x] The `## A wave` additions do not disturb `tests/drive.test.sh:45-47`, which rebuilds the dispatch order from every `subagent_type:` string in that section.
- [x] `## Report` additions do not disturb `grouped-validation.test.sh:45-46` or `resume.test.sh:48-57`.

## Findings
- major — `method/commands/po-drive.md:72` — the allocation reads only `Target branch` ("read the highest `ADR-NNNN` on `Target branch`"), so a number already spent on an unshipped story branch is invisible. `## Resuming` (`:39-58`) makes unshipped lanes a normal, designed state: a lane stopped at the design stage, or one that hit `Max attempts`, keeps its branch across waves. Wave N hands `0018` to a lane that writes `ADR-0018-…` and does not ship; wave N+1 reads `0017` as the highest and hands `0018` again. The rule closes the collision inside one wave and leaves it open between waves — the same defect (n° 27) at a longer range, and this one merges two files numbered 0018 with nothing to detect it.
- major — `method/commands/po-drive.md:78` vs `method/agents/planner.md:51` — the handoff is unspecified where it is enumerated. `:72` says to "hand each lane of the wave its own number", but the dispatch bullet that lists what the planner prompt carries says only "the story id and the absolute worktree path". The planner is told to "use the one the driver reserved for this lane **in the message you received**", and with no number there it must "create no file whose name you invented". A driver reading bullet 1 as the prompt's contract dispatches without a number, and no fleet planner ever writes an ADR again. The degradation is fail-closed (the decision lands in the plan and is reported), which is why this is not critical, but criterion 4's mechanism has no wire between its two ends.
- major — `docs/stories.md:495` — the renumbering invalidated a live cross-reference. s33's entry still reads `**Corrige** : défauts n° 22, 23 et 24`, and those numbers now uniquely name three *open* M3-review defects (ADR-0003 undecided, ADR-0016 still `proposed`, no design subagent). Before the diff the reference was ambiguous; after it, it is unambiguously wrong, and a reader of `docs/stories.md` concludes s33 closed three defects that are still `ouvert`. The story opened tracker rows 28 and 29 for two findings it could not fix, but opened none for the one it created.
- minor — `method/commands/po-drive.md:63` vs `:66` and `:68` — "every git command you run against a lane is `git -C <absolute path>`" is contradicted two paragraphs later by `git worktree add -b story/<id> <Worktree root><id> <start point>` and by `git worktree list --porcelain` with no `-C`. Both resolve correctly as long as the driver never moves, so the rule is self-consistent in effect; the literal text is not, and `:66` is pinned by `tests/drive.test.sh:42`, so the fix is a clause, not a rewrite.
- minor — `method/commands/po-drive.md:72` vs the criterion — the criterion asks for "un par lane qui en a besoin"; the implementation reserves one per lane of the wave and lets unused numbers become permanent gaps in the ADR sequence. The trade-off is argued in the plan's pivot (the alternative serialises every ADR-bearing lane), and the plan explains why it is not an ADR (`docs/decisions/` is outside `Owns`). Recorded but unratified: a reader meeting a missing `ADR-0019` has nothing in `docs/decisions/` telling them the gap is intentional.

## Not verified
- **That any agent obeys these sentences.** Everything this story ships is prompt text, and every check — mine and the implementer's — proves a sentence exists in a file, not that a driver dispatches a whole stage in one message or keeps its working directory. This is the recurring pattern `docs/defauts.md:21` already names. A person should run the fleet in the sandbox with `Parallel: 2` and read the message log: count the Agent calls per message at each stage, and check that the wave report's new per-stage count matches what the log shows. Note that this cannot be run in this repository as it stands — defect n° 28, opened by this very story, says `/po-drive` stops here on a missing `Parallel`.
- **The cross-wave ADR collision (finding 1) was reasoned, not executed.** I derived it from `## Resuming` and the allocation text; no run has produced two `ADR-0018` files. A person should confirm it by leaving a lane unshipped with an ADR on its branch and starting a second wave.
- **The planner handoff (finding 2) was read, not exercised.** No planner was dispatched during this review.
- **The `cd` guard's reach.** `test_drive_uses_absolute_paths_only` greps for a backquoted `` `cd `` and would miss a driver that drifts using relative paths without ever writing that token; the plan names this limit. I checked the test's other half instead — the no-drift rule and `git -C <absolute path>` must both be present in `## A wave` — and mutation B confirms the grep half fires. The behavioural half stays unproven until a sandbox run.
- **No screen, no design artefacts.** `docs/designs/s33-real-parallelism/` does not exist and should not: the story changes four documents and no interface. `docs/design-system.md` is not engaged.
- **Type check, end-to-end and production build were not run** — the project declares no such commands (`Typecheck: —`, `E2E: —`, `Build: —`). Nothing was substituted. The diff touches no routing and no manifest, so the exemption holds.
- **Formatting and the pre-commit gate** run at commit time and were not re-examined here.

Max severity: major
Ship allowed: yes
