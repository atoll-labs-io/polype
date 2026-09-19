# Review — s15-stories-review

Diff reviewed: `git diff m2-cadrage...story/s15-stories-review` (HEAD 0cca379). I did not write this code. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0

## Evidence reused
- [x] `po-gate verif-current s15-stories-review` exited 0, so I reused the record `docs/verif/s15-stories-review.md` (Tree ad83213…, status complete). It shows `bash tests/run.sh` with exit 0: 101 passed, 0 failed (96 before the story plus 5 new). The focused run also exited 0. I did not rerun the suite.
- The project has no type check (`Typecheck: —`), no E2E and no build. I did not substitute any other command.
- I read the record's "Not proven here" section. It says nobody has run the command or the subagent in Claude Code, and that `/po-research` issuing its warning has not been observed.

## Plan
- [x] All 9 tasks are present. Nothing outside the plan: 11 files changed, the same as "Files touched".
- [x] Each run interdict, checked:
  - Empty diff for `.claude/`, `.polype/`, `AGENTS*.md`, `docs/stories.md`, `tests/lib.sh`, the existing tests and the existing method files: confirmed.
  - `po-research.md` gains one bullet and `po-help.md` one line: confirmed.
  - `docs/parite-killer-saas.md` changes on the C06 line only: confirmed.
  - The `po-research` bullet never says "stop": confirmed.
  - The new files never mention `docs/references/`, `~/dev/vault` or `/spec`: confirmed by grep.
  - The overlap test passed according to the record.

## References
- [x] I checked every cited name against its source:
  - `agentic-stories` sections: Vertical slices, Owns and contracts first, Complexity and splitting, Criteria and notes, Scope: core loop and graveyard.
  - PRD sections `## Core loop`, `## Angle`, `## Graveyard`.
  - Brief sections `## Wedge & non-goals`, `## Premises`.
  - Settings `Entry mode` and `Target branch`, which exist in `method/templates/agents-local.md`.
  - The `frontmatter`, `needs_tool` and `lacks_tool` helpers in `tests/lib.sh`.
  - The `section_of` idiom.
  - The `subagent_type: stories-reviewer` name, which matches the agent's `name:`.
- [x] Values: the verdict lines match the template and the agent file. The mapping from `Entry mode` to the scope source matches `/po-stories`.

## Rules
- [x] AGENTS.md conventions are respected:
  - The new files are in English and `po-help` is in French.
  - The command and the agent each have a `Reads settings:` line.
  - The judging agent has no Write.
- [x] No accepted ADR is contradicted. ADR-0006 is covered by the overlap test.

## Tests
- [x] Five structural tests, one per criterion, each quoting the clause it guards. None of them has any of the six empty test shapes.
- [x] 5 tests against a budget of 25.
- [x] Bite: I ran only `bash tests/run.sh stories-review.test.sh`, restored each file with `git checkout -- <file>` and confirmed it with `git diff --exit-code <file>`. The final `git diff --exit-code` on the whole tree is clean.
  - M1, `Bash` added to the agent's `tools:` → 1 failing (`stories_reviewer_is_read_only_without_shell`) → undone, clean.
  - M2, the po-research bullet changed from "carry on: this check never blocks." to "and stop." → 1 failing (`stories_review_is_a_soft_gate`) → undone, clean.
  - M3, the skill's steps 1 (Coverage) and 2 (Graveyard) swapped → 1 failing (`stories_review_checks_coverage_first`) → undone, clean.
  - M4, the Owns overlap moved from critical to minor in the skill's `## Severity` list only → **0 failing** → undone, clean. See finding 2.
  - M5, the `- stories-review` preload removed → 1 failing → undone, clean.
- [x] The story makes no existing test useless.

## Neighbours
- [x] Other readers of `docs/reviews/`: `po-gate.sh:26`, `po-ship`, `po-review`, `po-execute`, `po-orchestrator` and `implementer.md`. All of them work on `docs/reviews/<id>.md` with an `s<n>-` id, so `stories.md` does not collide with them. The installer copies `method/templates` recursively (`bin/polype-dev-install:47`), so nothing needs registering.

## Findings
1. **Major** — `method/skills/stories-review/SKILL.md:11` and `method/templates/stories-review.md:16`. For a brief, the coverage list treats `## Wedge & non-goals` as one scope item to be covered, and step 2 marks the graveyard check "not applicable". Non-goals are the opposite of scope: the brief template lists them as "what this product will deliberately not do", and `/po-stories` keeps them at hand. Two things follow:
   - A reviewer following the template may record a non-goal as "Covered: yes".
   - No check flags a story that delivers a declared non-goal. In `new` mode, the equivalent of a graveyard leak goes through.
   The damage is contained, because the stories were already approved by a human. Suggested fix: cover only the wedge (and the premises), and add a "non-goal revived" check for briefs, rated like a graveyard revival.
2. **Minor** — `method/skills/stories-review/SKILL.md`, `## Severity`. The rating of the Owns overlap in the severity list is pinned by no test (M4 survived). Only the step-8 sentence is pinned, so the two can drift apart without a failure. The criterion only requires "flagged", so this is contained.
3. **Minor** — `method/commands/po-stories-review.md:17-24`. The Checks stop when the scope source is missing, but never check its frontmatter for `status: approved`, unlike `/po-stories`. The command and agent descriptions both say "approved PRD or brief". The plan's decision table did not ask for this, so it is only a consistency note.
4. **Minor** — `docs/parite-killer-saas.md`, line C06. The status says `fait`, but the C06 text includes "gate souple signalé par le statut". The `/po-status` part belongs to a later story (`status_reports_framing_and_track`), so `partiel — … ; statut en <story>` would be more accurate.

## Not verified
- I never ran `/po-stories-review` or `stories-reviewer` in Claude Code: I don't have a real `docs/stories.md` project, and my review stays inside the diff. Someone should run it once on a project that has a PRD, and once on one that has a brief. They should check that `docs/reviews/stories.md` is written, committed alone on `Target branch` as `docs: stories review`, and ends with the two verdict lines.
- I have not seen `/po-research` actually issue the warning and carry on; only its wording is checked. Someone should run `/po-research` once with no `docs/reviews/stories.md`, and once with `Stories ready: no`.
- The blocked path (subagent failure, then a report written by the command with `Max severity: critical`) was never exercised; someone should force a subagent failure once.
- Originality compared with Killer SaaS: I relied on `tests/overlap.test.sh` through the record, and did not compare the prose myself. The overlap test only rules out runs of 8 or more shared words.
- The project has no type check, E2E or build (`—`), so none was run.

Max severity: major
Ship allowed: yes
