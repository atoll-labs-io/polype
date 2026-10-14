# Review — s38-migration

[Story](../stories.md) · [Plan](../plans/s38-migration.md) · [Verification](../verif/s38-migration.md)

Diff reviewed: `git diff m5-distribution...story/s38-migration`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0

## Ownership
`git diff --name-only m5-distribution...story/s38-migration` → `docs/migration.md`, `tests/migration-doc.test.sh`, `docs/plans/s38-migration.md`, `docs/verif/s38-migration.md`.
- [x] Every path inside `Owns` — `docs/stories.md:570` lists `docs/migration.md`, `tests/migration-doc.test.sh`; the plan and the record are the story's own pipeline evidence, in scope by construction.
- [x] Outside `Owns` → none.
- [x] Inside another running story's `Owns` → none. `git worktree list` shows only this story's worktree; `git branch --no-merged m5-distribution` lists only `story/s38-migration`.
- One gap in `Owns` itself, reported as finding 6 below.

## Evidence reused
- [x] `po-gate verif-current s38-migration` → exit 0; `git diff --quiet 7afbf38 HEAD -- . ':(exclude)docs'` → exit 0. The record at `/home/lecrabe/dev/atoll/polype/.claude/worktrees/m1-cycle/.worktrees/s38-migration/docs/verif/s38-migration.md` is current and complete: unit suite `bash tests/run.sh` exit 0, 204 passed. I reused it for the suite and reran it once anyway while checking bite (204 passed, 0 failed — same number). `Typecheck`, `E2E` and `Build` are `—` in `AGENTS.local.md`: this project has none, and I substituted nothing. No lint or formatter exists in this repository.
- Its "Not proven here" section flags that the four functions were never seen red — that is exactly what step 4 below settles.

## Plan
- [x] Task 1 (correspondence table) — present, `docs/migration.md:20-52`, 19 rows; one factual row is wrong (finding 1).
- [x] Task 2 (step-by-step removal) — present, `docs/migration.md:54-97`: safe order, pre-checks, the four files, `rmdir`, the `polype remove --global` caveat, out-of-repo paths, chezmoi.
- [x] Task 3 (project in flight) — present, `docs/migration.md:99-138`, six ordered steps plus the starting state.
- [x] Task 4 (test) — present, four functions, one per acceptance criterion, with both counters.
- [x] Nothing outside the plan: the diff is exactly the "Files touched" list.
- Run interdicts, one by one: `docs/parite-killer-saas.md` untouched ✔ · `README.md`, `method/AGENTS.md`, `method/commands/po-help.md` untouched ✔ · nothing under `method/`, `bin/`, `.claude/` ✔ · nothing written under `~/.claude/` (I only read it) ✔ · no existing test modified ✔.

## References
Every claim the document makes about this repository and about the two old skills was opened:
- `polype install --global`, `polype init <projet>`, `polype install <projet>`, `polype check --global`, `polype remove --global` — all real subcommands (`bin/polype:402-407`, `docs/installation.md:12-21`). `polype check --global` does exit 0 and print the installed version when nothing drifted (`bin/polype:329-358`), so "sort 0 et nomme la version posée" holds.
- "la pose globale ne retire jamais un fichier qu'elle n'a pas posé" — `docs/installation.md` says exactly that; `spec`/`drive` are not in its manifest, so the manual removal is correct.
- The four files to delete exist on this machine: `~/.claude/skills/spec/{SKILL.md,interrogation.md,product-scaffold.md}`, `~/.claude/skills/drive/SKILL.md`; `octo` and `sensei` do live in `~/.claude/agents/`, so "les retirer ici casserait des usages" is right.
- Old-regime vocabulary checked against the real skills: packet `F03`, `owns`, `depends`, `milestone`/`model`/`kind`, `Verify`, `autonomy`, `parallel`, `max_attempts`, `docs/specs/<slug>.md`, branch `spec/<slug>`, worktree `.claude/worktrees/<slug>-F03` on `feat/<slug>/F03`, `git branch -d feat/<slug>/F03` after merge, tracker via `octo`/`sensei`, `dutch` plan — all accurate (`~/.claude/skills/spec/SKILL.md:44-59,88-91,95,115-119`, `~/.claude/skills/drive/SKILL.md:30-52,79-93`).
- Polype-side names: settings `Merge mode`, `Plan validation`, `Ship confirmation`, `Parallel`, `Max attempts`, `Entry mode`, `Story track`, `Flow threshold`, `Worktree root`, `Tracker` all exist in `method/templates/agents-local.md`; the `interrogation` skill exists and is read by `/po-brief` (`method/commands/po-brief.md:26`), and "une question par message" matches `method/skills/interrogation/SKILL.md:17`; ADR-0002, ADR-0012, ADR-0015 say what the document attributes to them.
- [x] No value that only looks right, except the ADR-status point in finding 4.

## Rules
- [x] `AGENTS.md`/`AGENTS.local.md` conventions respected: documentation in French under `docs/`, test is `tests/<slug>.test.sh` with `test_<criterion>` functions named after the acceptance criteria, helpers from `tests/lib.sh`, no Killer SaaS text (`tests/overlap.test.sh` green in the full run).
- [x] No accepted ADR contradicted — see finding 4 for the ADR-0003/ADR-0018 bookkeeping.

## Tests
- [x] Assertions pin the acceptance criteria; none of the six empty shapes. The fourth function is the interesting one: it resolves every backticked repository path and every `/po-*` command against the tree, and refuses to pass with a zero counter.
- [x] 4 tests, `Test budget` is 25.
- [x] Bite — six mutations, each run against `tests/migration-doc.test.sh` only, each undone and confirmed with `git diff --exit-code`:
  1. deleted the `rm ~/.claude/skills/...` block (`docs/migration.md:79-84`) → 1 failing (`migration_gives_a_step_by_step_removal`) → undone, clean.
  2. `` `docs/installation.md` `` → `` `docs/install-guide.md` `` → 1 failing (`migration_doc_is_checked_by_a_test`: "points at a path that does not exist") → undone, clean.
  3. `/po-setup` → `/po-bootstrap` → 2 failing (`migration_covers_a_project_in_flight`, `migration_doc_is_checked_by_a_test`: "names an absent command") → undone, clean.
  4. rewrote every `` `docs/… `` token so none resolves → 1 failing, on the counter guard ("no repository path was resolved: the check proves nothing") → undone, clean.
  5. deleted the tracker row (`docs/migration.md:40`) → 1 failing (`migration_maps_every_old_concept`) → undone, clean.
  6. removed `git worktree prune` → 1 failing (`migration_covers_a_project_in_flight`) → undone, clean.
  Final state: `git diff --exit-code`, `git diff --cached --exit-code` and `git status --porcelain` all clean; the temporary backup was deleted.
- [x] No test made useless by the story; none removed.

## Neighbours
- [x] `docs/migration.md` is referenced by nothing outside its own test, plan and the `Owns` line — as the plan predicted; s39 wires the cross-references. No existing test enumerates `docs/*.md`, so adding a file breaks nothing. Full suite: 204 passed, 0 failed.

## Findings
- **major** — `docs/migration.md:35` — the row "Worker : écrit le code, ses tests, et se relit" misstates the old regime. `/drive` never had the worker grade itself: `~/.claude/skills/drive/SKILL.md:81` dispatches "a fresh read-only reviewer … A separate reviewer instance keeps the worker from grading its own homework", and this repository's own `docs/conception.md:18` records for `/spec` + `/drive`: "reviewer frais contrat + diff". Task 1 of the plan said to follow `docs/conception.md:11-24` for the facts, and this row departs from it. The effect on a reader is to present Law 2 as a novelty and to erase a safeguard they already had. The left cell should say the worker implements and the driver verifies with a fresh per-packet reviewer, with the third column keeping only "le rouge d'abord imposé au worker (ADR-0012)", which is correct (ADR-0012 confirms it).
- **minor** — `docs/migration.md:45` and `:131` — bare `docs/stories.md`, while the document's own reading convention (`:12-14`) says a bare path names a file of *this* repository and the same file is written `<projet>/docs/stories.md` at `:31`, `:43`, `:116`. The path check passes only because Polype happens to have a `docs/stories.md`, so the guard confirms a reference that points at the wrong repository.
- **minor** — `docs/migration.md:119` — "`depends` devient `Dépend de`" while the template it cites in the same sentence, `method/templates/stories.md:12`, names the field `Depends on` (the templates are English; only this project's own `docs/stories.md` is French). A reader following the template writes a different label than the one instructed.
- **minor** — `docs/migration.md:40,52` — ADR-0018 is cited as settled, but its status is `proposed`, and ADR-0003, which says the opposite ("L'état du travail vit dans GitHub Issues ou Taskwarrior"), is still `accepted` with an empty `superseded-by`. The document matches the method as shipped (`AGENTS.md` already derives state), so the text is right about the product; the bookkeeping lives in `docs/decisions/`, outside this story's `Owns`, and belongs to whoever accepts ADR-0018.
- **minor** — `tests/migration-doc.test.sh:108` — `grep -o '/po-[a-z-]*'` matches any path segment, not just a command. The moment the document mentions `.polype/hooks/po-gate.sh`, the test will demand `method/commands/po-gate.md` and fail for a reason that has nothing to do with the document being wrong. Anchoring on a backtick or a word boundary would keep the check honest.
- **minor** — `docs/parite-killer-saas.md:103` — line H01 still reads `à faire`, while `AGENTS.local.md` says "When a story implements lines of the parity matrix, it updates their status cell … touching only its own lines" and this story's `Matrice` names "H01 (volet migration)". The file is not in s38's `Owns` (s39 owns it, with `parity_matrix_reflects_the_distribution` covering H01–H04) and the plan's run interdict defers it on purpose, so this is a gap in the story's `Owns` rather than an implementer breach — no change asked for here, but H01's migration part must not be forgotten in s39.

## Not verified
- **The removal procedure was never executed.** No `rm` under `~/.claude/`, no `rmdir`, no `chezmoi forget`, and `polype check --global` was not run on this machine — the review reads and writes nothing outside the repository. A person should run the section-2 sequence on a machine (or a copy of `$CLAUDE_CONFIG_DIR`) and confirm that `/po-*` commands still answer afterwards and that `chezmoi apply` does not put `spec/` and `drive/` back.
- **The in-flight resumption was never rehearsed.** Section 3 describes solding an integration branch, emptying `/drive` worktrees and rewriting packets into stories; nothing here exercised it. A person should dry-run it on a throwaway clone of a project that still has a live `spec/<slug>` and open packet worktrees, and check in particular that step 2 (removing worktrees) before step 3 (merging the integration branch) leaves nothing unreachable.
- **The faithfulness of the mapping for a reader's own project** is judged from two skill files on this machine only. Someone with an older or customised `/spec` may have packet fields this table does not mention.
- **No screen, no flow, no third party** are involved: the story ships a markdown document and a bash assertion file, so there was nothing to open in a browser and no integration behind a mock.

Max severity: major
Ship allowed: yes
