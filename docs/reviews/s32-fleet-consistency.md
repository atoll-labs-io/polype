# Review — s32-fleet-consistency

[Story](../stories.md) · [Plan](../plans/s32-fleet-consistency.md) · [Verification](../verif/s32-fleet-consistency.md)

Diff reviewed: `git diff m3-flotte...story/s32-fleet-consistency`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0

## Evidence reused
- [x] `po-gate verif-current s32-fleet-consistency` → passes (exit 0; `git diff --quiet 3af59eb HEAD -- . ':(exclude)docs'` also exits 0). `Verification mode: record`, so the record is evidence and I did not rerun the full suite: `bash tests/run.sh` exit 0 · 164 passed · 0 failed, and `bash bin/po-lint` exit 0 · `po-lint: no breach in 22 file(s) of method/` (2026-09-22T07:49Z).
- Commands that are `—` in `AGENTS.local.md` — `Typecheck`, `E2E`, `Build` — the project has none; I substituted nothing. `E2E stage` and `Build stage` are `—` too.
- The record's "Not proven here" section names deeper mutation, the runtime behaviour of the lane, the absence of an automated test for `matrix_and_adr_index_agree_on_the_fleet`, and the stale installed copies. I picked up the first and the third below.

## Plan
- [x] Tasks 1–11 all present in the diff. Task 1–3 in `bin/po-lint:72-83,186-192`; 4–5 in `tests/lint.test.sh:18-26,105-123`; 6–7 in `method/commands/po-drive.md:14,46,75,79`; 8 in `tests/drive.test.sh:113-147`; 9 in `docs/parite-killer-saas.md:28,97,114,122`; 10 in `docs/conception.md:109-112`; 11 in `docs/defauts.md:27-29,37-39`.
- [x] Nothing outside the plan: the diff touches exactly the 7 files of `## Files touched` plus the three evidence files.
- [x] Run interdicts checked one by one, each with `git diff --quiet m3-flotte...HEAD -- <path>`: `docs/decisions/` empty · `method/agents/` empty · `method/AGENTS.md` empty · `method/commands/po-status.md` empty · `method/commands/po-help.md` empty · `method/templates/agents-local.md` empty · `tests/fleet-wiring.test.sh` empty. The D17 row (`docs/parite-killer-saas.md:66`) is byte-for-byte unchanged. Defects 15, 17–21 still `ouvert`. No test function renamed or deleted (the 6 lint tests and 6 drive tests include the 3 new ones; 164 = 161 + 3). `bin/polype-dev-install` was not run — `.polype/`, `.claude/` and the root `AGENTS.md` still hold the previous text, as intended.

## References
- [x] `method/commands/po-design.md:26-27` — checks 4 and 5 are exactly the two conditions the new drive prose cites (`docs/design-system.md` missing → `/po-design-system`; `Design source` at `—` → a human chooses `internal` or `external`). Confirmed.
- [x] `method/agents/implementer.md:20` — "When `docs/designs/<id>/design.md` exists, read it before the screen tasks" — the claim at `po-drive.md:79` holds.
- [x] `docs/decisions/ADR-0016…:28` — "une commande ne peut pas s'exécuter dans un subagent" — the cited constraint is real, and `method/agents/` holds only `implementer`, `planner`, `reviewer`, `stories-reviewer`, so "no design subagent exists" is true.
- [x] `method/commands/po-orchestrator.md:46-49` — stage 3 Design precedes stage 4 Plan; the claim "`/po-orchestrator` … designs before it plans" holds.
- [x] `po-gate plan-validated <id>` exists (`method/hooks/po-gate.sh:4,63`).
- [x] `Design source` exists in `method/templates/agents-local.md:24,50`, so the new `Reads settings:` name is not invented (and `bin/po-lint`'s settings rule passes on it).
- [x] Defect rows 22–24 verified against the files: ADR-0003 `status: accepted`, ADR-0016 `status: proposed`, ADR-0014 `status: superseded` / `superseded-by: [ADR-0017]`, ADR-0017 `status: accepted` / `supersedes: [ADR-0014]`.
- [ ] One value does not hold — see finding 1. Exit code 2 for "read nothing" matches the script's existing convention (`bin/po-lint:12` already exits 2 for a missing directory); breach exit stays 1. `grep -c ''` over `$METHOD_FILES` counts files correctly (herestring adds the trailing newline the command substitution stripped) — checked by mutation M3.

## Rules
- [x] `AGENTS.md` / `AGENTS.local.md` conventions respected: `method/` changed, not `.claude/` or `.polype/`; method text in English; the `Reads settings:` line lists a setting that exists in the template; bash tests with `tests/lib.sh` helpers, one test function per acceptance criterion name; `overlap.test.sh` green (the record documents the one collision found and fixed); parity-matrix lines updated to `fait —`/`partiel —` with only this story's lines touched.
- [x] Law 7 respected: the three new gaps went to `docs/defauts.md`, not to `docs/stories.md`.
- [x] No accepted ADR contradicted. ADR-0012 (no red-first while implementing) is respected: the record shows the bite runs were done after the code, against the pre-story files, and restored.

## Tests
- [x] The three new tests pin the three named criteria; none of the six empty shapes. `empty_method()` builds a real tree and the real script runs on it; no mock reproduces the condition it evaluates; no `catch` absorbs anything. `test_lint_reports_how_many_files_it_read` recomputes `n` with its own `ls … | grep -c ''` rather than reading the script's variable, so it diverges when the script's glob does — not a tautology (proved by M3).
- [x] Within `Test budget: 25` — 3 new tests.
- [x] Bite, all mutations undone and each restore proved with `git diff --exit-code <file>`:
  - `bin/po-lint` — removed the zero-file early exit (`:80-83`), ran `tests/run.sh lint.test.sh` → **1 failing** (`lint_fails_when_it_reads_nothing`). Worth noting what the mutant printed: `po-lint: 1 breach(es) in 0 file(s) of method/`, exit 1. A test asserting only a non-zero exit would have passed; the `no breach`/`breach(es)` assertions are what caught it.
  - `bin/po-lint` — dropped `$METHOD_FILE_COUNT file(s) of ` from both summary lines → **1 failing** (`lint_reports_how_many_files_it_read`).
  - `bin/po-lint` — skewed the count by one (`:78`) → **1 failing** (same test: "does not say it read 22 file(s) … said 23 file(s)"). The count tracks reality, it is not decoration.
  - `bin/po-lint` — removed `0 file(s)` from the zero-file message (`:81`) → **1 failing** (same test, second half). The empty-tree half of the assertion bites on its own.
  - `method/commands/po-drive.md` — deleted the design-stage item (`:75`) → **1 failing** (`drive_lane_includes_design_when_the_story_has_a_screen`).
  - `method/commands/po-drive.md` — deleted the Resuming row (`:46`) → **1 failing** (same test).
  - `method/commands/po-drive.md` — removed `` `Design source`, `` from the `Reads settings:` line (`:14`) → **1 failing** (same test).
  - Clause uniqueness (the gap the record left open): each of the 9 literals the drive test greps occurs **exactly once** in `po-drive.md`, so no assertion is answered by prose elsewhere in the file.
  - Final state: `git diff --exit-code`, `git diff --cached --exit-code` and `git status --porcelain` all clean — the worktree is back to the committed state.
- [x] No test made useless by the story; none removed.

## Neighbours
- [x] `bin/po-lint` has exactly one caller outside itself: `tests/lint.test.sh:28,46`. The deleted `method_files()` helper is referenced nowhere in live code (only in prose under `docs/`). No CI or hook invokes the lint.
- [x] `method/commands/po-status.md:38` already routes a screen story through "design (`/po-design <id>`, a story with a screen)" in its "next" column, so the new drive stage does not contradict the status command it defers to (`po-drive.md:28`).
- [x] `tests/fleet-wiring.test.sh:94-96` pins D17's wording; the four rewritten matrix cells align on it and that test stayed green.
- [x] `tests/grouped-validation.test.sh:53-66` pins ADR-0017 accepted / ADR-0014 superseded — consistent with the new `docs/conception.md` index, and it is what makes finding 2 a contradiction rather than an opinion.

## Findings
- major — `bin/po-lint:76` — a listing that fails *partially* still earns a clean bill of health. `METHOD_FILES="$(ls "$METHOD"/commands/*.md "$METHOD"/agents/*.md 2>/dev/null || true)"` discards both `ls`'s exit status and its diagnostic, so only a *totally* empty listing is caught by the count guard. Reproduced: a tree with one file in `commands/` and **no `agents/` directory at all** → `po-lint: no breach in 1 file(s) of method/`, exit 0 — four subagent files unread, including the `reviewer.md` the tools rule exists to police. The acceptance criterion is "sort non nul si le listage des fichiers de méthode **échoue** ou ne renvoie aucun fichier"; the "échoue" half is unmet. This is also a small regression in diagnostics: before this story the same tree at least printed `ls: cannot access …` on stderr, and `2>/dev/null` now silences it. No current caller hits it (the only caller passes the real `method/` or a full copy), which is what keeps it out of critical. No test covers the partial case.
- major — `docs/parite-killer-saas.md:115` — the T4 row still presents ADR-0014 as the live decision ("Réglage, regroupé par vague en flotte — [ADR-0014]") while `docs/conception.md:109`, rewritten in this very commit, strikes it as "remplacée par ADR-0017", and ADR-0014's own frontmatter says `status: superseded` / `superseded-by: [ADR-0017]`. The story is titled "des documents d'accord" and closes defect 14 ("`docs/conception.md` présente encore ADR-0014 comme vivante"); T4 is the mirror image of that defect, one line below the T3 row the story rewrote, in a file the story `Owns`. Defect 14 is marked `corrigé par s32` with this instance left standing. The plan's task 9 never named T4, so the plan under-delivers the criterion rather than the implementer deviating from the plan.
- minor — `method/commands/po-drive.md:46-47` — the new Resuming row overlaps the one under it with no declared priority: a story with a screen, plan validated, design absent and no record matches both "the design stage" and "the code stage". The Dispatching prose (`:75`, "the implementer does not start") resolves it, and row order implies first-match, but the table alone is ambiguous. This is a new instance of open defect 19, which records exactly this shape for a different pair of rows; the story widens it without declaring the priority rule that would close both.
- minor — `method/commands/po-drive.md:73` — "Per lane, in this order, each stage dispatched as its own wave" now introduces a list whose item 2 says "never one it dispatches". The sentence contradicts the item it governs; it needs a clause such as "each dispatched stage as its own wave".
- minor — `method/commands/po-drive.md:119` — the `status` enumeration of why a story waits for a human ("a dependency not shipped …, an `Owns` collision …, `Max attempts` reached …, or an orphan worktree") reads as closed and does not name a lane parked on the design stage, which is the one new state that requires a human command. The per-lane "the stage it resumes at" earlier in the same sentence, and the report table's "stage reached" column (`:115`), mean the information is not lost — hence minor rather than major.
- minor — `method/commands/po-drive.md:75` vs the story text — the criterion says the lane "**insère** l'étape de design entre le plan et l'implémentation"; what ships is a lane that always **stops** at that point, even when `/po-design`'s conditions are met, because no design subagent exists. The plan declares this pivot, argues it against ADR-0016, and the implementer recorded the consequence as defect 24, so it is handled honestly — but a human ticking criterion 1 should know it was satisfied by a stop, not by an insertion, and that `/po-drive` therefore cannot run any screen story end to end.

## Not verified
- **The lane's runtime behaviour.** `method/commands/po-drive.md` is a prose contract; nothing here proves a driver reading it actually halts a lane at the design stage, names `/po-design <id>`, or resumes at the code stage on the next wave. Only a real `/po-drive` wave on a story with a screen would show it, and per finding 6 that run needs a human in the middle. A person should run one wave against a screen story on a scratch branch and read the report.
- **The full unit suite and the lint on the real tree** were not rerun: `Verification mode: record`, the record is current, and I relied on its `164 passed` and `no breach in 22 file(s)`. I ran only the two focused files the mutations touched (`tests/run.sh lint.test.sh`, `tests/run.sh drive.test.sh`), plus the partial-listing probe.
- **`matrix_and_adr_index_agree_on_the_fleet` has no automated test.** I read the four rewritten cells, the D17 row and the ADR index by eye against the ADR frontmatters; finding 2 is what that reading turned up. Nothing mechanical will catch the next such drift — a person may want a test that pins each matrix ADR link against that ADR's `status:`.
- **No screen, no design artefact.** This story produces no UI, `docs/designs/s32-fleet-consistency/` does not exist and `docs/design-system.md` was not consulted; no browser check applies. Nothing about contrast was measured — that record belongs to `/po-design-system`.
- **Typecheck, E2E and build** — the project declares none (`Typecheck: —`, `E2E: —`, `Build: —`), so no type error in a test file can be caught here by anything but the test run itself.
- **The installed copies** under `.claude/` and `.polype/`, and the root `AGENTS.md`, still carry the pre-story text; the run interdicts forbade regenerating them. Whoever ships must run `bin/polype-dev-install .` on `m3-flotte` afterwards, or the pipeline running on this repository keeps the old `po-drive` contract.
- **Third parties**: none — the diff is bash, markdown and no dependency.

Max severity: major
Ship allowed: yes
