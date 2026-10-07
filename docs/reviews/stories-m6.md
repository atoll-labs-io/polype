# Stories review — Polype, milestone M6 "La preuve" (s47–s56)

> One-off review run outside `/po-stories-review` (Polype has no PRD or brief, `Entry mode: —`), by the `stories-reviewer` subagent in a fresh context, on 2026-10-07. Second pass, after the first review (previous version of this file in git) led to the revision `da9235a`. Scope source: `docs/references/gstack-agent-skills.md` § "Idées retenues", defect n° 32, ADR-0022; "Plus tard" and "Idées écartées" as scope kept out. Not a Polype verdict: `/po-research` does not read this file.

Review status: complete

## Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| Review tied to the tree it judged | Trous de gate | s47 | yes |
| Defect n° 32 | `docs/defauts.md` | s47 | yes |
| Floor guard | Trous de gate | s48 | yes |
| Implementer bounds held by a PreToolUse hook | Trous de gate | s50 | yes |
| Secret scan at commit | Trous de gate | s49 | yes |
| Browser QA stage, read-only, required by the review | Vérifier ce que l'utilisateur verra | s51, s52 | yes |
| Browser driving contract | Vérifier ce que l'utilisateur verra | s51 | yes |
| Path-triggered review lenses | Une revue plus large | s53 | yes |
| Tool output is data | Une revue plus large | s54 | yes |
| Behavioural evals of the reviewer | Tester la méthode | s55 | yes |
| Evidence register written by a wrapper | Tester la méthode | s56 | yes |
| ADR-0022 (QA read-only, fail-closed hooks per agent) | ADR-0022 | s50, s51, s52 | yes |

## Exclusions
No story revives an item from "Idées écartées" or "Plus tard" (TDD red-first, fixing reviewer or QA, growing scope, state outside the repo, one commit per task, routing evals, cross-model review, gstack infrastructure, code markers, CWV/error budgets, retro, learnings, diagnostic, post-deploy, accessibility, taste decisions, test audit).

## Checks
- [x] Exclusions
- [x] No technical layer dressed as a story
- [ ] Every criterion checkable by one test — s56 `verif_current_requires_runs_at_the_tree`, s52 `qa_evidence_travels_with_the_story`
- [x] Dependency order
- [ ] Complexity — s52 breaks the ten-task split rule
- [x] Ids
- [x] Owns — every shared pair linked by a dependency chain; some needed paths missing (below)

## Findings
- major — s56 — `verif_current_requires_runs_at_the_tree`: "contrôle déclaré" undefined, and `git add -A` + `write-tree` includes `docs/verif/`, so two runs on the same code record different trees; compare code outside `docs/` like `verif_current`.
- major — s56 — Owns misses `tests/gate.test.sh` (records without `po-run` rows) and `tests/execute.test.sh` (pins `write-tree` and the record template).
- major — s52 — `qa_evidence_travels_with_the_story` names nobody who commits `docs/qa/<id>/`: the QA agent's bounds refuse git writes, `/po-qa` belongs to s51, Law 6 says the implementer commits once.
- major — s52 — Breaks the ten-task split rule (16 paths, gate + orchestrator + drive + status + help + README + review + four laws + two pinned tests); split the gate and review requirement from the fleet wiring.
- minor — s52 — `/po-review` has no Bash (`tests/review.test.sh:38`); the gate must run in the reviewer, step 1 of `review-antihallu`.
- minor — s52 — No criterion on what becomes of `implementer.md:31` ("open it in a browser").
- minor — s51 — `tests/setup-modes.test.sh:33-36` pins five numbered questions; say where `Dev` and `QA stage` are asked.
- minor — s51 — ADR-0022's launch-failure → exit 2 rule has no criterion for the QA hook.
- minor — s50 — No upgrade path: a project activated before s50 lacks `po-bounds.sh` and the fail-closed hook refuses every write.
- minor — s49 — Fake keys written in clear would trip this repo's pre-commit and GitHub push protection; build them at runtime. Law 6 should keep the manual `git status` check for projects without hooks.
- minor — s48 — tsconfig has no numeric thresholds (strict flags turned off are the weakening); define an assertion per language.
- minor — s55/s56 — s56 changes the record format that s55's recipes build; order them or fold the update into s56.
- minor — s54 — `tests/distribution-wiring.test.sh:24,33` pins two phrases of "Installed files"; keep them.
- minor — milestone — ADR-0022 is `proposed`; no story or step accepts it.

## Not verified
- Claude Code's handling of `hooks:` in subagent frontmatter and of non-2 exit codes (s50 notes require checking first).
- `bin/ks-overlap` against the source repositories.
- Frontmatter parsers in `bin/po-lint` and `tests/fleet-design.test.sh` against a nested `hooks:` block: run `bin/po-lint` and the suite in s50.
- Behaviour criteria (s51) can only be checked as prompt text (defect pattern n° 5).
- Tests not read in full beyond those named; the suite was not run.

Max severity: major
Stories ready: yes

## Applied after this review (2026-10-07)
- s52 split: s52 keeps the gate (`po-gate qa-current`), the commit of `docs/qa/<id>/` by `/po-qa`, the review requirement run in the reviewer, and the implementer's browser line; the orchestrator, drive, status, help and README wiring moves to the new **s57-qa-in-the-fleet**.
- s56: declared checks defined, comparison on code outside `docs/`, `tests/gate.test.sh`, `tests/execute.test.sh` and `evals/` owned, depends on s55.
- Every minor addressed in the stories' criteria or notes; ADR-0022 left `proposed` for the user to accept.
