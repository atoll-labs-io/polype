# Stories review — Polype, milestone M6 "La preuve" (s47–s55)

> One-off review run outside `/po-stories-review` (Polype has no PRD or brief, `Entry mode: —`), by the `stories-reviewer` subagent in a fresh context, on 2026-10-07. Scope source: `docs/references/gstack-agent-skills.md` ("Idées retenues" as scope, "Plus tard" as deferred, "Idées écartées" as graveyard) and defect n° 32 in `docs/defauts.md`. Not a Polype verdict: `/po-research` does not read this file.

Review status: complete

## Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| La revue liée à l'arbre qu'elle a jugé | Idées retenues / Trous de gate | s47 | yes |
| Défaut n° 32 | docs/defauts.md | s47 | yes |
| Le garde contre l'abaissement de la barre | Trous de gate | s48 | yes |
| Les bornes de l'implementer tenues par un hook | Trous de gate | s50 | yes |
| Le scan de secrets au commit | Trous de gate | s49 | yes |
| Une étape QA en navigateur qui produit des preuves | Vérifier ce que l'utilisateur verra | s51, s52 | yes |
| Le contrat de pilotage du navigateur | Vérifier ce que l'utilisateur verra | s51 | yes |
| Des lentilles déclenchées par les chemins touchés | Une revue plus large | s53 | yes (2 sub-items dropped, see minors) |
| La sortie d'erreur est une donnée | Une revue plus large | s54 | yes |
| Des evals comportementales du reviewer | Tester la méthode en action | s55 | yes |
| Un registre de preuves écrit par un wrapper | Tester la méthode en action | none | **no** |
| Une rétro tirée des fichiers | Apprendre d'une story à l'autre | none | **no** |
| Des leçons proposées par la revue | Apprendre d'une story à l'autre | none | **no** |
| Une procédure de diagnostic | Apprendre d'une story à l'autre | none | **no** |

## Exclusions
| Excluded item | Source section | Revived by | Revived |
| --- | --- | --- | --- |
| Rouge d'abord / TDD strict | Idées écartées | none | no |
| Un reviewer ou une QA qui corrige | Idées écartées | none (s51 notes forbid it) | no |
| « Boil the Ocean », périmètre qui grossit | Idées écartées | none | no |
| L'état hors du dépôt | Idées écartées | none (`docs/qa/` is in git) | no |
| Un commit par tâche | Idées écartées | none | no |
| Routage des skills et ses evals | Idées écartées | none | no |
| Revue croisée par un autre modèle | Idées écartées | none | no |
| L'infrastructure de gstack | Idées écartées | none | no |
| Marqueurs `// Regression:` | Idées écartées | none | no |
| Scorecards CWV, budgets d'erreur, déploiements progressifs | Idées écartées | none | no |
| Plus tard (post-déploiement, a11y, décisions de goût, audit des tests) | Plus tard | none | no |

## Checks
- [x] Exclusions: no story brings back an excluded or deferred item
- [x] No technical layer dressed as a story
- [ ] Every criterion can be checked by one test — no: s51 `qa_agent_cannot_edit_code`, s50 `bounds_fail_closed`
- [x] Dependency order: every `Dépend de` names an earlier id
- [x] Complexity: no 5; s51 and s55 name a risk; s50's stated risk misses its main one
- [x] Ids: s47–s55 follow s46, unique, in file order
- [x] Owns: no declared path shared without a dependency; several stories miss paths they will need (majors below)

## Findings
- critical — (no story) — Retained idea "Un registre de preuves écrit par un wrapper" (`po-run`) has no story, though it is the core of a milestone called "La preuve".
- critical — (no story) — Retained idea "Une rétro tirée des fichiers" has no story.
- critical — (no story) — Retained idea "Des leçons proposées par la revue" has no story; if it waits for Nautile, move it to "Plus tard" with that reason.
- critical — (no story) — Retained idea "Une procédure de diagnostic" has no story.
- major — s47 — Owns leaves out files that describe the old gate: `method/AGENTS.md:62` (Law 3), `method/commands/po-drive.md:53` and `:119` (a review made stale by a late commit sends the lane to a ship the gate refuses, with no route back to review: the lane is stuck), `method/commands/po-status.md:29`, `tests/drive.test.sh:84`, and `tests/ship.test.sh` for `ship_states_the_tree_check`. All are owned only downstream of s47, so adding them creates no unlinked overlap.
- major — s51 — Creates `po-qa.md` but does not own `method/commands/po-help.md`; `tests/pilot.test.sh:38-46` fails as soon as a command is missing from help.
- major — s51 — `qa_agent_cannot_edit_code` is not checkable: the QA agent needs Write and Bash, and nothing confines them to `docs/qa/<id>/`. Reword to what a test sees, or reuse `po-bounds` (depend on s50).
- major — s52 — `tests/drive.test.sh:45-47` and `tests/fleet-design.test.sh:52-53` pin the wave order `planner designer implementer reviewer`; s52 owns neither.
- major — s52 — Nobody commits `docs/qa/<id>/`: the implementer stops on it during a fix run (`implementer.md:18`), `po-ship.md:25` commits only the review, and `po-ship.md:47` then refuses to remove the worktree. s52 needs `po-ship.md` (in chain) and `implementer.md` (owned by s50, not in chain → add s50 to `Dépend de`). Law 4 line 79, Law 6 line 90 and `review-antihallu/SKILL.md:18` also need `docs/qa/<id>/`.
- major — s50 — `bounds_fail_closed` covers only failures inside the script; a hook command that cannot be resolved exits non-2, which Claude Code treats as non-blocking, so the hook fails open. State that limit or test it; complexity 3 looks low.
- minor — s48 — Assertion count must be per test file, not per test; name the config files for thresholds; say how the guard gets `Target branch`.
- minor — s50 — Give the exact git verb list (Law 4 names switch, checkout, stash only); `AGENTS.md` "Installed files" names only `po-gate.sh`, and adding po-bounds there puts s50 in the s49/s52/s54 chain.
- minor — s51 — `/po-setup` never asks for `Dev` or `QA stage`, and the profile template has no `Dev` (pinned by `tests/profile.test.sh:31`): QA would always stop on a new project.
- minor — s52 — "QA missing or stale" would be the only resume row decided by prose; add `po-gate qa-current <id>`. The review precondition belongs in `po-review.md`. A 10-file story with these pitfalls has no notes.
- minor — s53 — "rate limit partagé" and "changelog lu" dropped; `dependency_lens_runs_when_the_lockfile_changes` states content, not an observable result.
- minor — s55 — "dit le coût" needs a figure; criterion 1 and the notes disagree on where fixtures live (say `evals/` holds the recipes).
- minor — M6 header — A new cycle stage and an implementer hook are structural decisions with no ADR named.

## Not verified
- Claude Code hook semantics (frontmatter `hooks:` in subagents, non-2 exit codes): outside the reviewer's inputs.
- Whether the session's browser tools can save a screenshot the QA agent can cite.
- `bin/ks-overlap` against the two source repositories.
- Stories s01–s46 were read only for continuity and Owns, not re-reviewed; accepted ADRs scanned by title and grep.
- Test breakage beyond the test files named above: run `bash tests/run.sh` after s47 and s52.
- Plan-task count of s51 and s52 against the ten-task split rule.

Max severity: critical
Stories ready: no
