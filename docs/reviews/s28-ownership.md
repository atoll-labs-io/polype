# Review — s28-ownership

Diff reviewed: `git diff m3-flotte...story/s28-ownership`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0

Files in the diff: `docs/plans/s28-ownership.md`, `docs/verif/s28-ownership.md`, `method/agents/reviewer.md`, `method/skills/review-antihallu/SKILL.md`, `tests/ownership.test.sh`.

## Scope (`Owns`) — the check this story introduces, applied to itself
`docs/stories.md:428` — **Owns** : `method/agents/reviewer.md`, `method/skills/review-antihallu/SKILL.md`, `tests/ownership.test.sh`. All three code paths of the diff are inside it; the two `docs/` files are this story's own pipeline evidence, in scope by construction. No path belongs to another story's `Owns`. One omission (the parity matrix) is reported as a minor below, using this story's own "gap in the `Owns`" rule.

## Evidence reused
- [x] `po-gate verif-current s28-ownership` → exit 0, record reused (`Tree: da30d9ac…` equals HEAD outside `docs/`). `Verification mode: record`, so the unit suite and lint results are taken from `docs/verif/s28-ownership.md` (151 passed / 0 failed, `bash bin/po-lint` exit 0). I re-ran both once while proving the tests bite and got the same numbers. `Typecheck: —`, `E2E: —`, `Build: —`: the project has no such commands, nothing substituted.
- Read the record's "Not proven here": no type check exists, and the suite proves clauses are present, not that a reviewer agent performs the check.

## Plan
- [x] Task 1 — scope section added before `## Six steps` (`method/skills/review-antihallu/SKILL.md:9-20`), with the `git diff --name-only` source and the "decides what the rest of the review reads" rationale.
- [x] Task 2 — the two severities present, including the running-story test (`git worktree list` + branch not merged into `Target branch`).
- [x] Task 3 — the two carve-outs and the missing-`Owns` case present.
- [x] Task 4 — `docs/stories.md` added to `## Inputs`, announcement line amended. Nothing renumbered: `method/agents/reviewer.md:24` "step 4 of the procedure" still points at the bite step, which is still `**4.`.
- [x] Task 5 — `tests/ownership.test.sh` with exactly the two criterion-named functions, `section_of` pinning assertions inside the new section.
- [x] Task 6 — both runs recorded.
- [x] Run interdicts checked one by one: `git diff --stat m3-flotte...story/s28-ownership -- tests/review.test.sh method/commands/po-review.md method/templates/review.md method/AGENTS.md method/commands/po-drive.md method/skills/stories-review/SKILL.md docs/parite-killer-saas.md .claude/ .polype/` is empty. No existing test modified; the 149 previously passing still pass (151 total).
- [x] Nothing outside the plan in the diff.

## References
- [x] `method/skills/stories-review/SKILL.md:25` really says "a directory owned by one story covers every path beneath it" — the new section quotes it verbatim, so the two definitions cannot drift apart silently.
- [x] `method/commands/po-drive.md:35` states the driver's a priori half ("`Owns` paths are disjoint from those of the lanes already running"); the reviewer's a posteriori wording agrees with it.
- [x] `method/agents/reviewer.md` frontmatter gives Bash, Read, Grep, Glob — `git diff --name-only`, `git worktree list` and the merged-branch test are all within its tools.
- [x] `tests/lib.sh` helpers used by the new test exist with the claimed behaviour: `require_file:41`, `contains:43` (`grep -qF`, exact), `fail:11`, `$METHOD:6`. `section_of`'s `/^## /` correctly leaves `###` subsections inside the section.
- [x] `bin/po-lint:139` only inspects tools of skill-preloading agents; `reviewer.md` keeps its tools and `Reads settings:` line, so no lint rule is touched (`bash bin/po-lint` exit 0).
- [x] Callers of the changed contract (`method/commands/po-review.md:30`, `po-drive.md:52`, `po-orchestrator.md:61`, `po-flow.md:75`) all reuse `/po-review`'s prompt word for word, so the amended agent file reaches every path that invokes a reviewer — no caller needed a change.

## Rules
- [x] Method files in English; commands/subagents keep their `Reads settings:` line; `.claude/` and `.polype/` untouched.
- [x] No accepted ADR contradicted (ADR-0012 in particular: the bite proof stays the reviewer's job and remains step 4).
- [ ] The `Matrice` convention of `AGENTS.local.md` — see the minor finding below.

## Tests
- [x] Two tests for two criteria, names identical to the acceptance criteria; far inside `Test budget: 25`. None of the six empty shapes: each assertion is pinned inside the section it judges, not anywhere in the file.
- [x] Bite, mutation 1: removed the line `- **Outside \`Owns\` → major.** …` from `method/skills/review-antihallu/SKILL.md`, ran `bash tests/run.sh ownership.test.sh review.test.sh` → **1 red** (`reviewer_checks_the_diff_against_owns`), 8 green. Undone.
- [x] Bite, mutation 2: inserted a duplicate `## Six steps, all of them, in this order` heading above the scope section so the ordering reverses → **1 red** (`review_procedure_places_the_ownership_step_first`), 8 green. Undone.
- [x] Bite, mutation 3: removed `docs/stories.md` from `## Inputs` in `method/agents/reviewer.md`, ran `ownership.test.sh review.test.sh wiring.test.sh` → **1 red** (`reviewer_checks_the_diff_against_owns`), 14 green. Undone.
- [x] Tree restored: `git diff --exit-code` exit 0 and `git status --porcelain` empty after the three mutations.
- [x] No test made useless by the story; `tests/review.test.sh`'s six-step count stays valid because the scope check is a section, not a seventh numbered step.

## Neighbours
- [x] Every other reader of `reviewer.md` / the skill (`po-review`, `po-drive`, `po-orchestrator`, `po-flow`) read; nothing broken.
- [x] History check on what the new rule would do to past stories: `git show --stat` on the last five commits shows s23, s24 and s25 each touching `tests/design-handoff.test.sh` and s27 touching `method/commands/po-help.md` and `docs/parite-killer-saas.md`, none of them in their `Owns`. These land on the "a written rule of `AGENTS.md` requires it" carve-out (the "Keep existing tests green" and `Matrice` conventions), i.e. minor with the rule quoted, not major — the carve-out does absorb the repository's real habits, but only if the reviewer treats the `AGENTS.local.md` conventions appended to `AGENTS.md` as "written rules of `AGENTS.md`". Worth knowing before the first fleet run.

## Findings
- major — `method/templates/review.md` (unchanged, outside this story's `Owns`) — the procedure now has a step that comes before all six, and the report template has no slot for it: `## Evidence reused`, `## Plan`, `## References`, `## Rules`, `## Tests`, `## Neighbours` each get a checklist line, the scope check gets none. A reviewer that skips it leaves no hole in the artefact, which is exactly the "looks covered, isn't" failure the method fights elsewhere. The implementer was right not to touch the file (`docs/stories.md:89` gives it to the shipped review story, and the plan made it an interdict); closing this needs a later story — s31-fleet-wiring is the natural host since it already owns the rules and help wiring.
- minor — `docs/parite-killer-saas.md:13,58` (A02, D09) — the story line `docs/stories.md:429` declares "**Matrice** : A02 et D09 côté flotte" and the `Matrice` convention of `AGENTS.local.md` says a story implementing matrix lines updates their status cell; both cells still read "partiel — … ; contrôle d'ownership en M3", which this story just delivered. Not a breach by the implementer but a gap in the story's `Owns`: `docs/stories.md:466-473` gives the file and those two lines to s31, which will flip them. Flagged so it is not lost if s31 is dropped or resequenced.
- minor — `tests/ownership.test.sh:50-51` — `scope_line=$(grep -nxF … | cut -d: -f1)` keeps every match, so a duplicated heading feeds a two-line string to `[ … -lt … ]`; mutation 2 produced `[: 9\n24: integer expected` on stderr before the test failed for the right reason. The verdict is correct either way; `grep -nxF -m1` would make the failure message readable.
- minor — `tests/ownership.test.sh:22,32-33,57` — the plan's test strategy promises that "prose reworded without changing the rule must not turn red", yet several assertions quote whole sentences (`Name the path and the \`Owns\` line it missed`, `not a breach by the implementer but a gap in the story's \`Owns\``, `This comes first because it decides what the rest of the review reads`). The rules are pinned, but so is the phrasing; a future copy-edit of the skill turns them red for no substantive reason.

## Not verified
- **That a reviewer agent actually performs the scope check.** The diff is prompt text; the suite proves the clauses exist and are ordered, nothing more. The record says the same. Only a real `/po-review` on a story whose diff leaves its `Owns` would show it. A person should run the next fleet review against a deliberately out-of-scope edit (touch a file not in the story's `Owns`) and confirm the report carries the major, and the critical when the path belongs to a lane that is running.
- **The critical branch's mechanics were never exercised.** No second story worktree was running while I reviewed, so "worktree in `git worktree list` and branch not merged into `Target branch`" was read, not executed. First real occasion is the first `/po-drive` wave.
- **This review used the previous procedure.** The installed copies in `.claude/skills/review-antihallu/SKILL.md` and `.claude/agents/reviewer.md` are untouched by design, so the scope section I judged is not the one my own context preloaded; I applied it by hand from `method/`. It takes effect after `bin/polype-dev-install .`.
- **No type check, no end-to-end suite, no production build**: `Typecheck: —`, `E2E: —`, `Build: —` in `AGENTS.local.md` — the project has none of these commands and I substituted nothing. Nothing here is deferred to ship beyond the usual commit-time formatting.
- **No screen, no design artefacts**: the story renders nothing, so `docs/design-system.md` and `docs/designs/` were not opened and no design conformity judgement was made.

Max severity: major
Ship allowed: yes
