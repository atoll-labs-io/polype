# Review — s22-brief-order

Diff reviewed: `git diff m3-flotte...story/s22-brief-order`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0

## Evidence reused
- [x] `po-gate verif-current s22-brief-order` → exit 0; `git diff --quiet d85b3db HEAD -- . ':(exclude)docs'` confirms the record's `Tree:` equals the committed code outside `docs/`. `Verification mode: record`, so the unit suite is **reused, not rerun**: `bash tests/run.sh` → exit 0, 131 passed, 0 failed (2026-09-21T16:50Z).
- Project commands `Typecheck`, `E2E` and `Build` are `—` in `AGENTS.local.md`: **the project has none**, and I substituted nothing. Nothing of that kind is covered here or at ship.
- The record's own "Not proven here" is accurate and I carried it into "Not verified" below.

## Plan
- [x] Task 1 — `## Finish` of `method/commands/po-brief.md:45-49` reordered: blocking checks are step 1, the interruption clause ("leaves `docs/brief.md` at `status: interviewing`") is there.
- [x] Task 2 — step 4 commits brief + ADR together, with "The approval and its ADR go in the same commit, or neither".
- [x] Task 3 — the refusal clause added to `## Checks` of `method/commands/po-stories.md:22`; the two per-mode lines are byte-identical to before.
- [x] Task 4 — two tests added, scoped via the existing `section_of`; the order test compares line positions, not presence.
- [x] Task 5 — new stories test added; the whole-file `contains "$STORIES" 'status: approved'` removed, the four other assertions of `test_stories_reads_prd_or_brief_by_entry_mode` untouched.
- [x] Task 6 — rows 4 and 5 of `docs/defauts.md` read `corrigé par s22`; no other row changed.
- One change outside the plan: `tests/design-handoff.test.sh` (finding 1).

Run interdicts, one by one:
- [x] `.claude/` and `.polype/` — empty diff (diffstat lists neither).
- [ ] "No file outside the story's Owns is modified" — **breached** by `tests/design-handoff.test.sh` (finding 1).
- [x] No ADR added, edited or renumbered; no row of `docs/parite-killer-saas.md` touched.
- [x] `Reads settings:` unchanged in both commands (`Entry mode`, `Target branch`); `Target branch` is still genuinely used, now in Finish step 1.
- [x] `tests/lib.sh` and the other test files not weakened — the only removal is the assertion task 5 names.

## References
- [x] `section_of`, `require_file`, `contains`, `fail` all resolved: `section_of` is defined locally in `tests/brief.test.sh:9` and `tests/stories.test.sh:8`; the rest in `tests/lib.sh:37-43`. `$BRIEF`, `$STORIES`, `$DEFECTS` all point at existing files.
- [x] `grep -c .` on an empty `sources` yields 0, so the `-ge 2` guard fails loudly rather than vacuously passing.
- [x] The order comparison cannot be fooled by its own neighbours: Finish step 1 contains neither the literal ``set `status: approved` `` nor a second `git status --porcelain`, so `grep -n -m1` picks the intended lines.

## Rules
- [x] `AGENTS.md` conventions: method prose in English, tests are bash `test_*` using `tests/lib.sh`, defect rows updated with the wording already in use. `tests/overlap.test.sh` (8+ shared words with Killer SaaS) is green in the reused record.
- [x] Law 7 respected: these are defects turned into stories by a person (commit 515272e), not agent-invented stories.
- [x] ADR-0012 honoured — no red-first during implementation; the mutations below were run here, in a context that did not write the code.
- [x] No accepted ADR contradicted.

## Tests
- [x] Three new tests for three acceptance criteria, plus one adjusted assertion — far within `Test budget: 25`.
- [x] None of the six empty shapes applies: this repository has one layer (bash assertions over prompt files), no DB, no fixtures, no mocks, no `catch`.
- [x] Bite, each mutation followed by a run of **only** the file exercising that rule:
  - Swapped Finish steps 1 and 2 in `po-brief.md` (the pre-s22 order) → **1 failing**: `brief_checks_before_writing_approved` — "po-brief.md writes status: approved before its blocking checks".
  - Deleted "The approval and its ADR go in the same commit, or neither…" → **1 failing**: `brief_commits_approval_and_adr_together`.
  - Dropped `status: approved` from the `docs/brief.md` source line of `po-stories.md` — this is defect n° 5 reintroduced verbatim → **1 failing**: `stories_requires_an_approved_source_with_a_biting_test`. Under the same mutation I confirmed the deleted whole-file `contains "$STORIES" 'status: approved'` would still have passed (the PRD line keeps the phrase): the hole was real and is now closed.
  - Deleted the new refusal clause → **1 failing**: same test, "po-stories does not refuse a source still being written".
  - Set row 4 of `docs/defauts.md` back to `ouvert` → **1 failing**: `defects_one_to_three_marked_fixed`.
  - All five undone; `git diff --exit-code` over the whole worktree is clean and `git status --porcelain` is empty. The tree still matches the record's `Tree:`.
- [x] The one assertion the story made useless was removed, and the plan explains why.

## Neighbours
- [x] Every other reference to the two commands read: `method/commands/po-orchestrator.md:26` already demands `status: approved` (consistent), `po-prd.md:22`, `po-help.md:14-15`, `method/AGENTS.md:19-21`, `templates/brief.md:8`, `tests/prd.test.sh:13`, `tests/wiring.test.sh:27,75` — none reads the `## Finish` or `## Checks` bodies, none breaks.
- [x] `tests/design-handoff.test.sh:8` is the only reader of `docs/defauts.md`, and it was updated.
- [x] `.polype/hooks/po-gate.sh` `pre_commit` checked: it returns 0 immediately off a `story/*` branch and never inspects environment files, so the prompt text in `po-brief.md` is the only env guard for that commit — the basis for finding 4.

## Findings
- minor — `tests/design-handoff.test.sh:56-64` — modified although the file is outside the story's `Owns` and outside the plan's "Files touched", breaching the interdict "No file outside the story's Owns is modified". The edit was necessary (task 6 changes the very rows that test asserts), minimal, correct (rows 6-11 still pinned to `ouvert`), and declared in `docs/verif/s22-brief-order.md`; the `AGENTS.local.md` convention "change an existing test only when the story changes the clause it checks, and say so" authorizes it. Rated minor because the fault is a bookkeeping gap in the story's `Owns`, not a breach of intent — the file should have been listed. Fix: add it to `Owns` in `docs/stories.md` for the sibling stories s23-s25, which will hit the same row.
- minor — `tests/design-handoff.test.sh:52` — the function is still named `test_defects_one_to_three_marked_fixed` while it now asserts three distinct invariants (1-3 by s21, 4-5 by s22, 6-11 still `ouvert`). The name lies about its scope, and it is the failure label a future reader sees.
- minor — `docs/defauts.md:24` — the closing note "**Motif récurrent (n° 5, 7, 9, 10, 11)**" still enrols n° 5 among the pattern's members, while its row now reads `corrigé par s22`. The note stays defensible (the s22 fix is itself a prompt-phrase test, so n° 5's deeper cause survives), but a reader sees a closed defect listed with open ones. Either drop n° 5 from the list or say explicitly that the row is closed and the cause is not.
- minor — `method/commands/po-brief.md:45-49` — the `git status --porcelain` environment-file check now runs at step 1 instead of immediately before the commit at step 4, so nothing re-checks at commit time, and the gate does not cover it (see Neighbours). Law 6 reads "before any commit, check that `git status --porcelain` lists no environment file", which the new text still satisfies literally. Residual risk is small: the window between check and commit contains only writes to `docs/brief.md` and the ADR, and the commit is path-scoped to those two. This is the deliberate trade-off that buys the fix for defect n° 4, and the worse defect was the one removed. Cheap hardening: repeat the porcelain check in step 4 — `brief_checks_before_writing_approved` uses `grep -m1`, so a second mention later would not break it.

Observation, outside this diff and not a finding against this story: `method/commands/po-stories-review.md:23` accepts `docs/brief.md` on "Missing → stop" alone, with no `status: approved` requirement — the same shape as the defect s22 just closed one command over. A person should decide whether that becomes a new row in `docs/defauts.md`.

## Not verified
- **What the tests prove is the prompt text, not the behaviour.** Every assertion here checks that `po-brief.md` and `po-stories.md` *say* the right thing in the right order. That a real `/po-brief` session actually stops before writing `status: approved`, or that `/po-stories` actually refuses an `interviewing` brief, is not shown by any of this — it is exactly the recurring motif recorded at `docs/defauts.md:24`. A person should run an end-to-end pass of `/po-brief` interrupted mid-Finish, and `/po-stories` against a brief left at `status: interviewing`, and record both under `docs/validation/`.
- **No type check, no end-to-end run, no production build**: `Typecheck`, `E2E` and `Build` are `—` — the project has none, at this stage or at ship. Nothing of that kind is covered by anyone.
- **The unit suite was not rerun by me.** I reused the record for all 131 tests; I ran only the three focused files touched by my five mutations. If the record were forged the whole suite claim collapses, though its tree hash matches the commit.
- **No screen, no design artefacts.** `docs/designs/s22-brief-order/` does not exist and `docs/design-system.md` was not opened: the diff is markdown prompts and bash. No visual or contrast question arises, and none was assessed.
- **No research file to check the code against** — s22 came through the short track, so I held the diff against the plan's `## Verified facts`, and I re-derived the load-bearing one (the two-line `status: approved` hole) myself rather than trusting it.
- **The installed copies are deliberately stale.** `.claude/commands/po-brief.md` and `.polype/` still hold the pre-s22 text; per `AGENTS.local.md` that is correct until the next `bin/polype-dev-install .`, but it means the pipeline running in *this* worktree still executes the old ordering. A person should reinstall after ship and confirm the copies moved.

Max severity: minor
Ship allowed: yes
