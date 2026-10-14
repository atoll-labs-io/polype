# Review: s90-diagnostic-skill

[Story](../stories.md) · [Plan](../plans/s90-diagnostic-skill.md) · [Verification](../verif/s90-diagnostic-skill.md)

I reviewed the diff `git diff main...story/s90-diagnostic-skill` in a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 759ba4717a223073f268368188a322a4dbe8d420

## When blocked
Does not apply.

## Ownership
I listed the diff with `git diff --name-status main...story/s90-diagnostic-skill` and held each path against the story's `Owns` line.
- [x] **Every path is inside `Owns`.**
  - Owned files: `method/skills/diagnostic/SKILL.md`, `method/agents/planner.md`, `method/commands/po-flow.md`, `method/templates/plan-flow.md`, `method/templates/stories.md`, `method/skills/agentic-stories/SKILL.md`, `tests/diagnostic-skill.test.sh`.
  - In scope by construction: `docs/plans/s90-diagnostic-skill.md` and `docs/verif/s90-diagnostic-skill.md`.
  - `docs/decisions/ADR-0068-…md` is in scope too: status `A`, and the plan names it. Number 0068 is not taken on `main` or on `story/s91-accessibility`.
- [x] **No path is outside `Owns`.**
- [x] **No overlap with another running story.** The only other worktree is s91-accessibility, which owns `method/skills/design-doctrine/` and `tests/accessibility.test.sh`. Neither overlaps this story.
- [x] **The story has an `Owns` line.**

## Evidence reused
- [x] `po-gate verif-current s90-diagnostic-skill` exits 0, so I reused the record and did not rerun the suite (`Verification mode: record`).
  - The record has one Unit suite row (`bash tests/run.sh`) with exit 0.
  - The project has no Typecheck command (`—`), so no type check was run or required.
  - The record's "Not proven here" says the skill is checked as text only, with no live planner run.
- [x] `po-gate qa-current` is not required: `Surface: —`, so the story does not go to QA.

## Plan
- [x] All six tasks are present, and nothing in the diff falls outside the plan.
- [x] **Run interdicts, checked one by one:**
  - Nothing outside `Owns` is touched apart from the plan, verif and ADR-0068. That holds for `method/templates/research.md`, `po-research.md`, `po-orchestrator.md`, `method/AGENTS.md`, `docs/parite-killer-saas.md`, `.claude/`, `.polype/` and every existing test file.
  - In `planner.md`, the "lines at most" phrases (200, then 250) and the Limits and Checks lines are unchanged.
  - In `po-flow.md`, the five original signal phrases, the QA paragraph and the order of the sections are kept.
  - I reused the overlap check from the green recorded suite.
  - ADR-0068 is new in this diff, not a rewrite of an existing ADR.

## References
- [x] Every reference resolves:
  - `## Structuring facts` exists in `method/templates/research.md:3`.
  - ADR-0012 exists.
  - The test helpers `frontmatter`, `$METHOD` and `$ROOT` exist (`tests/lib.sh:5-13`).
  - Skills are installed by directory glob, so the new `diagnostic` skill needs no registry entry.
- [x] The skill tells the planner to add a `## Diagnostic` section that the research template lacks. This is intended: the plan records it, and `research.md` is outside `Owns`.

## Rules
- [x] The `AGENTS.md` conventions are respected: method files in English, a test file named after the story, an ADR from the template.
- [x] **ADR-0068 is respected, but parts of the change contradict it** (findings 1 and 3).

## Tests
- [x] **Floor:** `po-gate floor-guard s90-diagnostic-skill main` exits 0, so nothing was lowered.
- [x] **Assertions:** three tests, one per criterion, none of the six empty test shapes. The heading order is checked by line number.
- [x] **Budget:** 3 tests, well within `Test budget` (25).
- [x] **Bite 1:** I removed `  - diagnostic` from the planner's `skills:`.
  - Result: 1 failing test (`defect_stories_get_the_diagnostic`, "planner does not preload diagnostic").
  - Undone with `git checkout --`; `git diff --exit-code` is clean.
- [x] **Bite 2:** I removed the `Fixes` escalation bullet from `po-flow.md` `## Escalation signals`.
  - Result: 1 failing test ("po-flow signals lack Fixes").
  - Undone; `git diff --exit-code` is clean.
- [x] **Bite (by reading):** removing the `Fixes` clause from the planner's escalation sentence (`planner.md:33`) would fail no test. `Fixes` and `Corrige` also appear in the new "Defect story" bullet, so `contains "$PLANNER"` still passes (finding 4).
- [x] No existing test became useless.

## Neighbours
- [x] **I read the callers of the new trigger:**
  - `method/commands/po-orchestrator.md` (Stage 1 / Stage 2).
  - `method/commands/po-drive.md` (`## Resuming`, planner dispatch).
  - `method/commands/po-research.md`.
  - The D15 row of `docs/parite-killer-saas.md`.
- [x] **Results:** findings 1 to 3 below.

## Lenses
Lenses run: none. The diff is markdown method text plus one bash text test: no auth, migration, lockfile or server code.
- [x] There were no lens findings.

## Findings
1. **major** — `method/templates/stories.md:14` and `method/skills/agentic-stories/SKILL.md:53` claim unconditionally that a story with a `Fixes` line "is researched under the `diagnostic` skill". That is only true when the fleet's `planner` does the research.
   - On the single-story path, `/po-orchestrator` → `/po-flow` escalates, then "continue on the full track at stage 2" (`po-orchestrator.md:43-46`) and writes the research "as `/po-research` describes", in the main context.
   - Neither `po-orchestrator.md` nor `po-research.md` preloads or names `diagnostic`, so a defect story driven that way gets no reproduction, no root cause and no three-hypothesis stop.
   - ADR-0068 itself lists this as a Neutral consequence, but the two owned texts state the opposite.
   - Fix: qualify the sentences, or open a follow-up story that wires `diagnostic` into `/po-research` and `/po-orchestrator`.
2. **major** — `method/skills/diagnostic/SKILL.md:24-25` ("write no plan, and report…") has no matching state in the fleet driver.
   - After that stop, the worktree holds research and no plan. `po-drive.md:50` maps exactly that to "the plan, built on the research already on disk".
   - The planner contract adds "read it, build the plan on it" (`planner.md`, "Research already on disk").
   - On the next wave, a lane whose research says "no root cause found" is either re-dispatched forever, or a planner builds a plan on it — the guessed fix the story forbids.
   - Nothing routes such a lane to a human. `po-drive.md` is outside this story's `Owns`, so this needs a follow-up story: a `## Resuming` row, or a research marker that sends the lane to a human.
3. **minor** — `docs/parite-killer-saas.md:64` (D15) still says "cinq signaux d'escalade" and lists five. The plan and ADR-0068 knowingly left it, because the file is outside `Owns`. It is now stale documentation.
4. **minor** — `tests/diagnostic-skill.test.sh:42-45`: `contains "$PLANNER" '`Fixes`'` is satisfied by the "Defect story" bullet. The planner's escalation clause (`planner.md:33`, "a defect to fix — a story carrying a `Fixes` line") can be deleted without any test failing. Scoping the check to that sentence, as the test already does for `po-flow`'s section, would pin it.
5. **minor** — `method/skills/diagnostic/SKILL.md:13` says "the planner writes only research and plan". `planner.md` Limits also allow the reserved ADR. The wording is imprecise, with no effect on behaviour.

## Not verified
- **The planner was never run on a real defect story.** Whether a model actually reproduces, records hypotheses and stops at three is untested; the tests check text only, as the record admits. A person should drive one `Fixes` story (for example s92-review-tree-gate) through `/po-drive` and read the research it produces.
- **The `/po-flow` escalation on a `Fixes` line was checked by reading only, not by running `/po-flow`.**
- **French spacing was not exercised.** Polype's own stories write `**Corrige** :`, with a space before the colon. Matching that form is left to the agent reading the story text; no hook parses it, so I did not run anything on it.
- **The full suite was not rerun here.** I relied on the current record (exit 0 on the recorded tree, which `verif-current` accepts). Only `diagnostic-skill.test.sh` was run, during the bite proofs.

Max severity: major
Ship allowed: yes
