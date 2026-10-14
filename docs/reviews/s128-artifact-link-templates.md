# Review — s128-artifact-link-templates

[Story](../stories.md) · [Plan](../plans/s128-artifact-link-templates.md) · [Verification](../verif/s128-artifact-link-templates.md)

Diff reviewed: `git diff main...story/s128-artifact-link-templates`, by a reviewer that did not write it. Each finding is rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 7a8949f91a72896ca3fec17ede3a63185f8f7222

## When blocked
- Not blocked. The tree was taken at the start and again before answering, and both reads gave 7a8949f91a72896ca3fec17ede3a63185f8f7222. The worktree was clean at both points.

## Ownership
`git diff --name-only main...story/s128-artifact-link-templates` lists nine paths:
- [x] Every path is inside `Owns`. The six `method/templates/{research,plan,plan-flow,review,verification-record,qa}.md` and `tests/artifact-link-templates.test.sh` are exact file entries. `docs/plans/s128-artifact-link-templates.md` and `docs/verif/s128-artifact-link-templates.md` are this story's own evidence.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`. `git worktree list` shows only the main checkout and this worktree.
- [x] The story has an `Owns` line (`docs/stories.md:1990`).

## Evidence reused
- [x] `po-gate verif-current s128-artifact-link-templates` exits 0, so the record is reused under `Verification mode: record`. The unit suite (`bash tests/run.sh`) exited 0 on this code. `Typecheck: —`: the project has no type check. The record's "Not proven here" says no real story cycle has used the templates yet; that item is carried to Not verified below.
- [x] `po-gate qa-current` is not required. The story does not go to QA (`QA stage: —`, `Surface: —`).

## Plan
- [x] Tasks 1–5 are all present. The link lines match the plan character for character. The record sentence is word for word as planned. The test file has the three planned tests, named after the criteria. There is nothing outside the plan.
- [x] Run interdicts, checked one by one:
  - No path under `method/hooks/`, `method/commands/`, `method/agents/`, `.claude/` or `.polype/` is touched.
  - No existing `tests/*.test.sh` is touched.
  - No existing artefact under `docs/` is touched; the backfill is left to s129.
  - Each template diff only adds lines: 2 per template, 4 in `verification-record.md`.
  - There is no wikilink, no `#anchor` and no absolute path.
  - `overlap.test.sh` is green, since it is part of the full suite the record passed.

## References
- [x] `po-gate.sh` subcommands `plan-validated`, `ship-allowed`, `verif-current` and `qa-current` exist and run inside the test. The `po-run.sh --story/--label --` interface is the one `run-ledger.test.sh` uses. The `tests/lib.sh` helpers `scratch_repo`, `require_file`, `contains` and `fail` exist and are used correctly. `$METHOD` points at `method/`.
- [x] The link depths are right:
  - `docs/{research,plans,reviews,verif}/<id>.md` use `../`.
  - `docs/qa/<id>/report.md` (`po-gate.sh:159`) uses `../../`.
  - Reviews always find a record, because the implementer always writes one.
  - Flow plans carry no research link, because the short track has no research file.

## Rules
- [x] `AGENTS.md` conventions are respected: method text in English, a bash test file named after the story, test functions named after the acceptance criteria.
- [x] No accepted ADR is contradicted, and no Law 3 gate changes.

## Tests
- [x] Floor: `po-gate floor-guard s128-artifact-link-templates main` exits 0, so nothing was lowered.
- [x] The assertions pin each criterion:
  - Exact line under the title, line 1 still `---`, no `[[` or `.md#`.
  - Real `po-gate` and `po-run` runs with and without the line, plus one refusing case.
  - Links resolved on disk for both tracks.
  - None of the six empty test shapes appears. The fixtures are throwaway repos and are not mocked.
- [x] Budget: 3 tests out of 25.
- [x] Bite, three mutations. Each was undone and confirmed clean with `git diff --exit-code <file>`, and `git status --porcelain` ended empty:
  1. QA link depth `../../` changed to `../` in `qa.md`: 2 tests failed (`links_resolve`, `templates_carry_links`).
  2. `Tree: ` prefixed to the link line of `verification-record.md`: 2 tests failed (`gates_still_read_artifacts`, at its label-pattern assertion, and `templates_carry_links`).
  3. A research link added to `plan-flow.md`: 2 tests failed (`links_resolve`, `templates_carry_links`).
- [x] No test is made useless by the story.

## Neighbours
- [x] A search for positional readers (`sed -n|head -n|NR==|first line`) across `method/hooks`, `method/commands`, `method/agents` and `bin` finds only two kinds:
  - Frontmatter-on-line-1 readers (`po-gate.sh:29`, `po-session.sh:48`, `bin/po-lint`). The frontmatter stays on line 1.
  - The section-relative "first line of `## Complexity`" (`po-execute.md:34`), which a line under the title does not shift.
- [x] `reviewer.md:51` still points the reviewer's answer at `templates/review.md`, so the review link line reaches new reviews.
- Nothing is broken.

## Lenses
Lenses run: none. The diff holds only markdown templates and a bash test: no security, migration, dependency or server-side path or content.

## Findings
- minor — tests/artifact-link-templates.test.sh:65-75 — The with/without-the-line gate comparison would not catch a link line that looks like a label. With the mutation `Tree: [Story]…`, the gates kept their exit codes, because `verif-current` reads the last `Tree:`. Only the label-pattern assertion at the end of the test (`:89-94`) catches it. The coverage holds; this is just which assertion carries the weight.
- minor — method/templates/verification-record.md:5 — "copied with it, never edited" sits oddly with the `<id>` placeholder, which has to be replaced when the template is copied. "Never edited after the copy" would say it exactly.
- minor — docs/plans/s128-artifact-link-templates.md (Verified facts, last bullet) — "No relative Markdown link exists in `method/` today" is not quite true. `method/templates/architecture.md:10,29` hold placeholder ADR links. This has no effect on the work.
- minor — tests/artifact-link-templates.test.sh:100 — Two small tidy-ups:
  - `docs/qa/s02-b` is created but never rendered or checked.
  - `d` is a global variable with its own `trap … EXIT`, where the other tests use `local` and `scratch_repo`.

## Not verified
- **No real story cycle has used the new templates.** No planner, implementer, qa agent or reviewer has produced an artefact from them yet, so nobody has seen the `<id>` substitution and the links resolving in a live artefact. To cover it, the next story should open its research, plan, record and review on GitHub and click each link, and the full-track plan → research link should be checked in particular.
- **The link line in a QA report has never been seen in an actual QA report.** This project has `QA stage: —`, so only a rendered template was checked. To cover it, check the first QA report in a project with QA enabled.
- **The markdown-driven commands were checked only by the patterns their labels match.** `/po-review`, `/po-ship` and `/po-status` were never run on a linked artefact. The test only shows that the link lines match none of the labels those commands read. To cover it, run `/po-status` once on a repository holding linked artefacts.
- **The links were not viewed on GitHub or in Obsidian.** Only file existence on disk was checked. To cover it, open one linked artefact in each viewer after s129 or the next ship.

Max severity: minor
Ship allowed: yes

---

# Review — s128-artifact-link-templates

[Story](../stories.md) · [Plan](../plans/s128-artifact-link-templates.md) · [Verification](../verif/s128-artifact-link-templates.md)

Diff reviewed: `git diff main...story/s128-artifact-link-templates`, by a reviewer that did not write it. Each finding is rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: ddf28d9a775689bef55907f60a3c7f3b573f2941

## When blocked
- Not blocked. I took the tree at the start and again just before answering. Both reads gave ddf28d9a775689bef55907f60a3c7f3b573f2941, and the worktree was clean both times.

## Ownership
`git diff --name-only main...story/s128-artifact-link-templates` lists ten paths:
- [x] Every path is inside `Owns` (`docs/stories.md`, s128 `Owns` line):
  - The six `method/templates/{research,plan,plan-flow,review,verification-record,qa}.md` and `tests/artifact-link-templates.test.sh` are exact file entries.
  - `docs/plans/`, `docs/verif/` and `docs/reviews/s128-artifact-link-templates.md` are this story's own evidence.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`. `git worktree list` shows only the main checkout and this worktree. s129, which owns `docs/plans/` and the other artefact folders, has no worktree.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s128-artifact-link-templates` exits 0, so the record is reused under `Verification mode: record`. Its last `Unit suite` run (`bash tests/run.sh`) exited 0 on the fixed code (the 09:10:32Z row). `Typecheck: —`, so the project has no type check. The record's "Not proven here" says no real story cycle has used the templates yet; that item is carried to Not verified.
- [x] `po-gate qa-current` is not required. The story does not go to QA (`QA stage: —`, `Surface: —`).

## Plan
- [x] Tasks 1–5 are present, as in loop 0. Fix commit 5d193c1 touches only what the loop-0 minors named:
  - The record sentence now reads "never edited after the copy", in both the template and the test assertion.
  - The plan's last Verified-facts bullet is corrected.
  - `test_links_resolve` uses `local d`, and the unused `docs/qa/s02-b` folder is gone.
  - The record's `Tree:` is updated and a new `po-run` row was added.
- [x] Run interdicts still hold:
  - Nothing is touched under `method/hooks|commands|agents`, `.claude/` or `.polype/`.
  - No existing test is touched, and no existing artefact.
  - Each template diff only adds lines.
  - There is no wikilink, no anchor and no absolute path.
- [x] Loop-0 minor 1 (which assertion carries the label-pattern weight) was rightly left alone. It was an observation, not a defect.

## References
- [x] `po-gate.sh` subcommands, the `po-run.sh` interface and the `tests/lib.sh` helpers (`scratch_repo`, `require_file`, `contains`, `fail`) all exist and are used correctly.
- [x] Link depths: `../` for `docs/{research,plans,reviews,verif}/<id>.md`, and `../../` for `docs/qa/<id>/report.md`.
- [x] `trap "rm -rf '$d'" EXIT` with `local d` is safe. The path is expanded when the trap is set. Each test runs in its own `bash -c` (`tests/run.sh:17`). The same idiom is used in `tests/bricks.test.sh:82` and `tests/expo-profile.test.sh:51`.

## Rules
- [x] The `AGENTS.md` conventions are respected: English method text, one test file per story, tests named after the criteria.
- [x] No accepted ADR is contradicted, and no Law 3 gate changes.

## Tests
- [x] Floor: `po-gate floor-guard s128-artifact-link-templates main` exits 0, so nothing was lowered.
- [x] No empty test shape. The fixtures are real throwaway repos running the real `po-gate` and `po-run`, with no mock.
- [x] Budget: 3 tests out of 25.
- [x] Bite: in `method/templates/qa.md`, I changed the Plan link `../../plans/` to `../plans/`. Running `artifact-link-templates.test.sh` alone, 2 tests failed (`links_resolve`: "link '../plans/s01-a.md' points to a missing file"; `templates_carry_links`). I undid it with `git checkout --`, `git diff --exit-code` confirmed the file was back, and `git status --porcelain` was empty. The loop-0 bites (QA story depth, `Tree:`-prefixed record line, research link in plan-flow) are not affected by the fix commit, which does not touch that logic.
- [x] Unmutated, the file runs 3 passed, 0 failed.

## Neighbours
- [x] The positional readers found in loop 0 are unchanged: frontmatter on line 1 (`po-gate.sh:29`, `po-session.sh:48`, `bin/po-lint`) and the section-relative `## Complexity` (`po-execute.md:34`). The fix commit touches no reader.
- [x] `reviewer.md:51` still points at `templates/review.md`. This review carries the template's link line.

## Lenses
Lenses run: none. The diff holds only markdown templates and a bash test: no security, migration, dependency or server-side path or content.

## Findings
- None. Loop-0 minors 2–4 are fixed. Minor 1 needed no change.

## Not verified
- **No real story cycle has used the new templates.** No planner, implementer, qa agent or reviewer has produced an artefact from them, apart from this review, which was written by hand to the template. To cover it, open the next story's research, plan, record and review on GitHub and click each link, especially the full-track plan → research link.
- **The link line in a QA report has never been seen in a real QA report.** This project has `QA stage: —`, so only a rendered template was checked. To cover it, check the first QA report of a project with QA enabled.
- **`/po-review`, `/po-ship` and `/po-status` were never run on a linked artefact.** They are markdown-driven, and the test shows only that the link lines match none of the labels they read. To cover it, run `/po-status` once on a repository holding linked artefacts.
- **The links were not viewed on GitHub or in Obsidian.** Only file existence on disk was checked. To cover it, open one linked artefact in each viewer after s129 or the next ship.

Max severity: none
Ship allowed: yes
