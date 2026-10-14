# Review — s23-stories-review-nongoals

[Story](../stories.md) · [Plan](../plans/s23-stories-review-nongoals.md) · [Verification](../verif/s23-stories-review-nongoals.md)

Diff reviewed: `git diff m3-flotte...story/s23-stories-review-nongoals`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0

## Evidence reused
- [x] `po-gate verif-current s23-stories-review-nongoals` → passes (exit 0); `git diff --quiet eba83e5b HEAD -- . ':(exclude)docs'` confirms the record's `Tree:` equals the commit outside `docs/`. `Verification mode: record`, so I reused the record at `docs/verif/s23-stories-review-nongoals.md`: unit suite `bash tests/run.sh` exit 0 · 133 passed. I did not rerun it.
- Type check, end-to-end and build: this project declares none (`Typecheck: —`, `E2E: —`, `E2E stage: —`, `Build: —`, `Build stage: —`). Nothing was substituted. No lint or format command exists either, so the record has nothing to report there.
- The record's "Not proven here" section is accurate: it leaves the mutation experiment to this review (ADR-0012) and flags that no agent actually reviewed a brief-based `docs/stories.md`.

## Plan
- [x] Tasks 1–6 all present in the diff. Task 1 (coverage keeps the wedge + premises, non-goals handed to check 2), task 2 (check 2 renamed *Exclusions*, always runs, "not applicable" gone), task 3 (`description` frontmatter and the `critical` line of `## Severity`), task 4 (template: coverage source column, new `## Exclusions` table, checks line without "(PRD only)"), task 5 (two test functions), task 6 (defect n° 6 → `corrigé par s23`).
- [x] One change beyond the plan: `tests/design-handoff.test.sh` (see finding 1). Nothing else outside the plan.
- [x] Run interdicts, one by one:
  - `.polype/` empty diff — confirmed (`git diff --name-only` lists no path under it); `.claude/` does not exist in this worktree, so it cannot have drifted. The installed copies are still the old text (`.polype/templates/stories-review.md` still has "PRD only", last touched by `00ab0d7`), which is what the interdict wants.
  - `method/commands/po-stories-review.md`, `method/commands/po-stories.md`, `method/skills/agentic-stories/SKILL.md` — all absent from the diff.
  - `docs/defauts.md` — exactly one line changed, the `| 6 |` row.
  - `bin/polype-dev-install` not run (installed copies unchanged proves it).
  - No new test file — the two functions sit in `tests/stories-review.test.sh`.

## References
- [x] Every section name the new prose points at exists: `## Wedge & non-goals` at `method/templates/brief.md:21` with the wedge on line 22 ("The single capability that would be used daily if it were the only one shipped") and the non-goals list on 23-25 — the skill's new wording "the wedge, the single capability that opens `## Wedge & non-goals`" matches the template exactly; `## Premises` at `brief.md:32`; `## Graveyard` at `method/templates/prd.md:27`; `## Core loop` at `prd.md:20`; `## Angle` at `prd.md:34`. The cross-reference "Scope: core loop and graveyard" is a real heading (`method/skills/agentic-stories/SKILL.md:39`), and its body ("with a brief, it serves the wedge or one of the premises") now agrees with check 1 instead of contradicting it — the contradiction the plan named is genuinely resolved.
- [x] Test helpers exist and are used correctly: `section_of` (`tests/stories-review.test.sh:11`), `require_file` (`tests/lib.sh:41`), `fail` (`tests/lib.sh:11`), `$SKILL`/`$TEMPLATE` (lines 6-7). `section_of` is bounded by the next `## ` heading, so `section_of "$TEMPLATE" 'Coverage'` stops at the new `## Exclusions` — the negative grep on the coverage section is not silently reading the exclusions table.
- [x] No value that only looks right: no numbers, statuses or limits in this diff; the only "values" are heading names, all opened above.

## Rules
- [x] `AGENTS.md`/`AGENTS.local.md` conventions respected: method prose in English, no new test file, French kept only in `docs/`, commit message in English with no trailer, one commit. `tests/overlap.test.sh` is part of the green suite, so the new prose shares no 8-word run with Killer SaaS (ADR-0006). The convention "change an existing test only when the story changes the clause it checks, and say so" is met for `tests/design-handoff.test.sh`: this story does change the clause (defect 6's status), and the inline comment says so.
- [x] No accepted ADR contradicted. ADR-0012 (no red-first) respected — the implementer did not neutralise its own guards and said so in the record. `docs/parite-killer-saas.md` needed no edit: line C06 already reads `fait — …` for these four files, and the story implements no new matrix line.

## Tests
- [x] The two assertions pin down the two acceptance criteria, and they are consequence-shaped: each pairs a positive grep on the new wording with a negative grep that the old wording is gone. None of the six empty shapes applies — the tests grep the file under test, with no fixture, no mock, no swallowing `catch`.
- [x] 2 new functions plus one modified existing function, well within `Test budget: 25`.
- [x] Bite — seven mutations, each followed by only the test files that exercise the clause, each undone and confirmed with `git diff --exit-code`:
  - check 1 coverage sentence restored to the old "the `## Wedge & non-goals` and each entry of `## Premises`" → 1 failing test (`stories_review_treats_non_goals_as_the_graveyard`: "does not take the wedge alone as the brief's scope item")
  - check 2 restored to "**2. Graveyard.** … mark the check as not applicable" → 1 failing test ("check 2 does not read the non-goals of a brief")
  - `## Severity` critical line restored to "a graveyard feature revived" → 1 failing test ("the severity scale does not rate a revived non-goal")
  - frontmatter `description` restored to "then graveyard," → **0 failing tests** (finding 2)
  - template coverage source column restored to `## Wedge & non-goals` → 1 failing test ("still offers the non-goals as a coverage source")
  - template `## Exclusions` section deleted entirely → 1 failing test ("the template has no exclusions table")
  - template checks line restored to "Graveyard: … (PRD only)" → 1 failing test ("the template checks do not list the exclusions check")
  - `docs/defauts.md` defect 6 back to `ouvert` → 1 failing test in `design-handoff.test.sh` ("defect 6 is not marked fixed by s23")
  - After all eight: `git status --porcelain` empty and `git diff --exit-code` clean. No mutation left in place.
- [x] No test made useless by the story; the existing `stories_review_checks_coverage_first` still passes because it asserts the sentence the story kept ("An item of the scope that no story covers is critical.").

## Neighbours
- [x] `method/commands/po-stories-review.md` reads the skill and the template only by reference (delegation prompt, line 30) and names no section of either, so the renamed check and the new section break nothing. `method/agents/stories-reviewer.md` says "coverage table first" — still true. `method/commands/po-research.md` reads only the `Stories ready:` line, untouched. No `docs/reviews/stories.md` exists in this repository, so there is no stale artefact written against the old template.
- Upstream neighbour with a residual gap: `method/commands/po-stories.md:41` (finding 3).

## Findings
- major — `tests/design-handoff.test.sh:59-66` — the diff edits a file that is neither in the story's `Owns` (`docs/stories.md`: `SKILL.md`, `templates/stories-review.md`, `tests/stories-review.test.sh`, `docs/defauts.md`) nor in the plan's `## Files touched`. The edit itself is correct and minimal — moving defect 6 out of the `ouvert` loop was unavoidable to keep the suite green — but the coupling is undeclared, and `s24` and `s25` both own `docs/defauts.md` and will each have to edit the very same loop in this unowned file. A driver that groups lanes by `Owns` would judge s23/s24/s25 non-conflicting and let them collide there. The project's own intended rule is already written down as a future criterion (`docs/stories.md`, s28-ownership: "un fichier hors périmètre est un finding majeur, critique s'il appartient à une autre story en cours") — no other story is in progress owning it, hence major, not critical. A person should either add `tests/design-handoff.test.sh` to the `Owns` of s24/s25 or move the per-defect status assertions out of the shared loop.
- minor — `method/skills/stories-review/SKILL.md:3` — task 3's other half, the `description` frontmatter, is held by no test: restoring "then graveyard," left all 7 tests green. Nothing in the pipeline reads that line for behaviour (it is skill-selection metadata), so the exposure is small, but the clause the plan asked for is unproven and will silently rot back.
- minor — `method/skills/stories-review/SKILL.md:11` — "What that section rules out is scope kept away, not scope to deliver: check 2 reads it." The nearest section named before "that section" is `## Premises`, not `## Wedge & non-goals`. An agent reading fast could attach the sentence to the wrong antecedent; naming the section again removes the ambiguity in a file whose only function is to be read literally.
- minor — `method/commands/po-stories.md:41` — the same defect one stage upstream, explicitly out of this story's `Owns` and under a run interdict, so not a breach here: the writing checklist still restricts the no-revival check to "In `replace` or `adapt`". After this story a reviewer rates a revived non-goal critical while nothing warns the author at writing time. Worth a tracker entry rather than a fix inside this story.

## Not verified
- **The behaviour the story is actually about.** No agent was run against a brief-driven `docs/stories.md`: the whole suite asserts the text of a skill and a template, never that the `stories-reviewer` fills a `## Exclusions` table or rates a revived non-goal critical. This is the recurring pattern already recorded at the bottom of `docs/defauts.md`. A person should run `/po-stories-review` on a project with `Entry mode: new` and an approved brief whose non-goals one story quietly revives, and check the produced review contains a filled `## Exclusions` section and `Max severity: critical`.
- **Nothing takes effect in this repository yet.** `.polype/templates/stories-review.md` and the installed skill still carry the old wording (the interdict forbids running `bin/polype-dev-install`), so a `/po-stories-review` run here keeps the old behaviour until someone reinstalls from `m3-flotte` after the ship. That reinstall is unverified.
- **No screen.** The story touches no interface; `docs/design-system.md` and `docs/designs/s23-stories-review-nongoals/` were not consulted, and none exists for it. No design conformity judgement was possible or needed.
- **Type check, end-to-end suite, production build, lint, formatting.** This project declares no such command (`Typecheck: —`, `E2E: —`, `E2E stage: —`, `Build: —`, `Build stage: —`), so none ran and I substituted nothing. Nothing in the diff changes routing or a manifest, so no build check was owed.
- **The other defect rows.** I checked that only the `| 6 |` row changed, not that the wording of defects 7-11 still matches reality; that belongs to the stories that close them.

Max severity: major
Ship allowed: yes
