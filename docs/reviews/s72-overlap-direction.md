# Review: s72-overlap-direction

Reviewed tree: 4d7e87d43fa65f6c61144926ca766ca2f3db9403
Fix loop: 0
Review status: complete
Scope: `git diff main...story/s72-overlap-direction`
Lenses run: none (the diff is markdown method text plus one bash text test, and no lens trigger appears in it)

## Ownership
I compared 11 changed paths against the Owns line in `docs/stories.md:1104`.
- 9 code paths: `method/AGENTS.md`, `method/commands/po-drive.md`, `po-status.md`, `po-stories.md`, `method/skills/review-antihallu/SKILL.md`, `method/skills/stories-review/SKILL.md`, `method/templates/stories.md`, `stories-review.md`, `tests/owns-overlap.test.sh`. Each one matches an Owns entry exactly, either as a file entry or under a folder entry.
- 2 pipeline evidence files: `docs/plans/s72-overlap-direction.md` and `docs/verif/s72-overlap-direction.md`. These are in scope by construction.
- The only other running lane is `story/s70-reviewer-bounds` (unmerged). Its Owns is `method/hooks/po-bounds.sh`, `method/agents/reviewer.md`, `tests/bounds.test.sh`. Neither its Owns nor its diff overlaps this story.

## Evidence relied on
- **Verification record:** `po-gate verif-current s72-overlap-direction` exited 0 (`Verification mode: record`). Its run of `bash tests/run.sh` exited 0, so the unit suite was not run again. The project has no type check, end-to-end or build command (all are `—`).
- **Floor guard:** `po-gate floor-guard s72-overlap-direction main` exited 0, so no check was lowered.
- **QA:** none required, because the story has no screen.

## Plan conformity
- **Tasks 1 to 4:** the wording matches the plan verbatim.
- **Task 5:** the 4 test functions were added, and the file's two existing function bodies are untouched.
- **Run interdicts:** all respected.
  - The listed tests, `method/hooks/`, `.claude/`, `.polype/`, `docs/decisions/` and the parity matrix have an empty diff.
  - `method/AGENTS.md` changes only on the "`Owns` bounds a lane" line.
  - In `po-drive.md` only `## Report` changed; the ready-set line 40 and the rule sentence are untouched.
  - Check 8's pinned "share an `Owns` path" sentence is unchanged.
- **Deviation from the story:** the plan records one, and it is justified. `method/AGENTS.md` keeps the clause pinned by `tests/fleet-wiring.test.sh`, which is outside Owns, and adds a sentence that defines "share" by the overlap rule.
- **Consistency with references:**
  - The new exact-match sentence in review-antihallu agrees with `entry_matches` in `method/hooks/po-bounds.sh:185-214`: a file entry must be equal, a folder `x/` covers `x` and everything beneath it, and a glob is matched segment by segment.
  - It is also consistent with ADR-0046.

## Tests
- **Count:** 4 new tests, 6 in the file, within `Test budget` 25.
- **Hollow-test check:** none of the six kinds of test that prove nothing applies. Each test reads the method file under test, and three of them also assert that the old wording is gone.
- **Mutation 1:** in review-antihallu I removed "exactly" from "A diff path is matched exactly against…". 1 failing test in `owns-overlap.test.sh`. Restored, and `git diff --exit-code` was clean.
- **Mutation 2:** in `po-drive.md` I dropped ", plus the two entries that overlapped and one path matching both" from the `status` paragraph. 1 failing test. Restored and clean.
- **Mutation 3:** in `templates/stories.md` I put back "stories sharing a path never run". 1 failing test. Restored and clean.
- The worktree was clean afterwards (`git status --porcelain` empty).

## Findings
- minor — s72-overlap-direction — `method/skills/agentic-stories/SKILL.md:21` still says "two stories with no dependency between them never share a path" and does not cite the overlap rule.
  - The story's goal ("tous les textes de la méthode citent la même règle") is therefore not fully met.
  - The file is outside this story's Owns and outside the five files criterion `every_overlap_text_cites_the_rule` names, so it is a gap for a later story, not an implementer breach.
- minor — s72-overlap-direction — the new `po-status.md:36` clause, "the two entries that overlapped by the overlap rule of check 8 of the `stories-review` skill with one path matching both", reads heavily. Moving the citation into a comma-set aside, as `po-stories.md` does, would read better.
- minor — s72-overlap-direction — "share" in `method/AGENTS.md:51` is now defined by the overlap rule. The plain-word "sharing" sentences in `stories-review` check 8 (line 25, pinned) and in agentic-stories carry no such definition. This is acceptable as recorded in the plan.

## Not verified
- **Whether a reviewer agent actually applies exact matching on real diff paths.** A text test cannot show this; the record's "Not proven here" says the same. To cover it, run one review on a story whose diff touches a path that is close to an Owns glob but outside it, and confirm the review reports it as outside Owns (major).
- **Whether `/po-drive` and `/po-status` actually print the two entries and a path matching both when a real conflict happens.** I checked only the wording. To cover it, run `/po-drive status` on a backlog that has two overlapping ready stories and read the output.
- **The installed copies (`.claude/`, `.polype/`).** They still carry the old text until the method is reinstalled after ship. Run the refresh install as usual.

Max severity: minor
Ship allowed: yes
