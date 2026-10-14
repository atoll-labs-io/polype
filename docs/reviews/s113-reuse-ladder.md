# Review — s113-reuse-ladder

[Story](../stories.md) · [Plan](../plans/s113-reuse-ladder.md) · [Verification](../verif/s113-reuse-ladder.md)

Diff reviewed: `git diff main...story/s113-reuse-ladder`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: cfd1d02b9da383beab783d12b25476b74d9b5cb4

## When blocked
Not blocked.

## Ownership
I listed the diff with `git diff --name-status main...story/s113-reuse-ladder` and held each path against the story's `Owns` line (`docs/stories.md:1752`).
- [x] Every path is inside `Owns`. The six `method/` files and `tests/reuse-ladder.test.sh` are listed there.
- [x] Pipeline evidence is in scope by construction: `docs/research/`, `docs/plans/` and `docs/verif/` for s113.
- [x] `docs/decisions/ADR-0085-l-echelle-de-reutilisation-se-tient-au-plan-mesuree-contre-un-temoin.md` is added (status A) and the plan names it (ADR-0085, `## Files touched`), so it is in scope by construction.
- [x] No path sits inside another running story's `Owns`. `git worktree list` shows only main and this worktree.

## Evidence reused
- [x] `po-gate verif-current s113-reuse-ladder`: exit 0, record reused (`Verification mode: record`). The `Unit suite` row ran `bash tests/run.sh` with exit 0, on a tree whose code outside `docs/` equals `Tree:`. The project has no type check (`Typecheck: —`), so none was run. I read the record's "Not proven here" section.
- [x] `po-gate qa-current`: not required. The story's `Surface` is `—` and `QA stage` is `—`.

## Plan
- [x] Tasks 1–6 are all present and match the plan's exact texts:
  - the templates' `## Reuse` block is word for word the same and sits between `## Story` and `## Tasks`;
  - the planner's Plan and Short track clauses are in place;
  - the `po-plan` bullet sits after **The pivot**;
  - the `po-flow` sentence is in place;
  - step 3 has one sentence on its own line;
  - the new test file is there.

  Nothing in the diff falls outside the plan.
- [x] I checked each run interdict:
  - These files have an empty diff: `implementer.md`, `review-lenses/SKILL.md`, `reviewer.md`, `templates/review.md`, `bin/po-eval`, `evals/` and `templates/agents-local.md`.
  - `.claude/`, `.polype/`, `AGENTS.md` and `AGENTS.local.md` are untouched.
  - No existing test file changed.
  - The `**1.`–`**6.` lines of `review-antihallu` keep their text; only one line plus a blank line were added in step 3.
  - Every `Reads settings:` line is unchanged.
  - ADR-0085 is the only ADR added, with `status: accepted`.

## References
- [x] I opened every helper the tests use:
  - `section_of` and `holds` match `tests/scene-and-simulation-drivers.test.sh:15-17`;
  - `contains`, `require_file`, `fail`, `ROOT` and `METHOD` are at `tests/lib.sh:5-6,11,41,43`.
- [x] `review-lenses/SKILL.md:54` (the Dependencies lens) is unchanged, and the new step-3 sentence says nothing about dependencies, as the research required.
- [x] No value only looks right. The traps the research named hold:
  - no new "lines at most" in `planner.md`;
  - the `po-flow` headings are unchanged;
  - there are still exactly six `^\*\*[1-6]\. ` lines;
  - the order `## Tasks` < `## Scene viewpoints` holds.

## Rules
- [x] The `AGENTS.md` conventions are respected: method text in English, one bash test file per story, test names equal to the criterion names.
- [x] No accepted ADR is contradicted. ADR-0085's own internal inconsistency is listed under Findings.

## Tests
- [x] Floor: `po-gate floor-guard s113-reuse-ladder main` exited 0, so nothing was lowered.
- [x] The assertions pin down the four criteria: each phrase is checked inside the section that owns it, and the two templates' sections must be byte-identical. None of the six empty test shapes appears; these are phrase tests on prose, the only layer this repository has.
- [x] Budget: 4 tests, within the `Test budget` of 25.
- [x] Bite. After each mutation I ran only `reuse-ladder.test.sh`, undid it with `git checkout --`, and confirmed with `git diff --exit-code` that the file was back to its committed state.
  - Deleting the step-3 sentence in `review-antihallu/SKILL.md` made 1 test fail (`review_flags_rebuilt_helpers`).
  - Deleting the never-cut sentence from `plan-flow.md` made 2 tests fail (`never_cut_list_is_explicit`, plus `plans_carry_a_reuse_section` on the identical-sections check).
  - Deleting the `## Reuse` clause from the planner's Short track bullet made 1 test fail (`planner_requires_the_ladder`).
  - The worktree was clean afterwards (`git status --porcelain` printed nothing).
- [x] The story makes no existing test useless.

## Neighbours
- [x] I found no other reader of the plan's section headings in `method/` or `bin/`. The only other list of required plan sections is the one in `po-plan.md` and `planner.md`, which this diff updates.
- [x] `evals/lib.sh:184,271` and `evals/cases/missing-tenant-filter.sh:30-33` build plans that have no `## Reuse` section. The new step-3 rule could change how the reviewer grades those eval cases. That code belongs to s114 and this diff does not touch it, so I list it under Not verified rather than as a finding.

## Lenses
Lenses run: none. No changed path matches a trigger, and the content is method prose: no auth or HTTP, no migration, no lockfile or dependency entry, no server-side code.
- [x] There are no lens findings to grade.

## Findings
- minor — `docs/decisions/ADR-0085-l-echelle-de-reutilisation-se-tient-au-plan-mesuree-contre-un-temoin.md:27` — The frontmatter says `status: accepted`, but `## Decision Outcome` still reads "Option proposée : **A**, en attente du porteur (ADR-0077)". A reader cannot tell from the ADR body whether the owner decided. The plan says the owner chose A on 2026-10-13. The sentence should state the decision before the ADR lands on `main`, because an accepted ADR's body can never be edited after that. `docs/research/s113-reuse-ladder.md` (Structuring facts, 4th bullet) also still describes the plan as `validated: no` with the waiting line. That is historical, but it shows the same drift.

## Not verified
- **The owner's acceptance of ADR-0085, option A.** The only evidence is the plan's sentence and the ADR frontmatter, and `docs/decisions-log.md` has no entry for s113 or 0085. No agent message counts as consent, so a person should confirm that the owner chose option A on 2026-10-13 before the ship.
- **Behaviour.** I did not check whether a planner fills `## Reuse` honestly, or whether a reviewer actually catches a rebuilt helper. Phrase tests cannot show either. s114's measurement against a "Follow YAGNI." control is the planned cover.
- **Overlap with Ponytail's text** (`DietrichGebert/ponytail`). `tests/overlap.test.sh` only guards Killer SaaS, and I did not open Ponytail's sources. A person should compare the `## Reuse` paragraph and ADR-0085 with Ponytail's wording.
- **Effect on the current eval cases.** Their generated plans carry no `## Reuse` section, and I did not run whether the new step-3 rule shifts their expected severities. That needs paid calls, which the owner launches (s114). Also, `drift_check` (`bin/po-eval:55-80`) will refuse paid evals until `~/.claude/` is refreshed after landing.
- **The type check, the end-to-end suite and the build.** The project has none (`Typecheck`, `E2E` and `Build` are `—`).

Max severity: minor
Ship allowed: yes
