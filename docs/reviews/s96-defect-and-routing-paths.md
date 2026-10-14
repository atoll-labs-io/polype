# Review: s96-defect-and-routing-paths

[Story](../stories.md) · [Plan](../plans/s96-defect-and-routing-paths.md) · [Verification](../verif/s96-defect-and-routing-paths.md)

Reviewed tree: 903f7b2f4e47a40aaab5fe7283fb4bc218e7c41e
Fix loop: 0
Worktree: /home/lecrabe/dev/atoll/polype/.worktrees/s96-defect-and-routing-paths (branch `story/s96-defect-and-routing-paths`, one commit, aca0428)
Lenses run: none. No lens trigger appears among the paths or in the content: the diff touches only method markdown, a bash text test and ADRs.

## Scope (`Owns`)
`git diff --name-status main...story/s96-defect-and-routing-paths` lists 14 paths, and every one is in scope.
- **Covered by `Owns`:** `method/agents/planner.md`, `method/commands/po-{drive,execute,flow,orchestrator,plan,research}.md`, `method/skills/diagnostic/SKILL.md`, `tests/defect-and-routing-paths.test.sh` and `docs/decisions/ADR-0068-…md`. ADR-0068 is listed by name in `Owns`, and only its frontmatter `superseded-by:` changes. The repo has done this before: ADR-0034, ADR-0029, ADR-0052 and others carry the same frontmatter edit.
- **In scope by construction:**
  - The story's own pipeline evidence: research, plan and record.
  - `ADR-0070-…md`. Its status is `A` and the plan names it.
- **No conflict with other running stories:** the only other one is s95-profiles-hold, not merged into main. Its `Owns` (boilerplates, `bin/po-lint`, `tests/run.sh`, `tests/lib.sh`, profile tests, ADR-0062/0064) shares no path with this diff.

## What I relied on
- **Record:** `po-gate verif-current s96-defect-and-routing-paths` exited 0. `Verification status: complete`, and the Unit suite (`bash tests/run.sh`) has a `po-run` row with exit 0 on the code at `Tree:`. Under `Verification mode: record` I did not run the suite again. The project has no Typecheck, E2E or Build command (`—`), so none was run.
- **QA:** `Surface: —`, so the story does not go to QA and none is required.
- **Floor guard:** `po-gate floor-guard s96-defect-and-routing-paths main` exited 0, so nothing was lowered.

## Plan conformity
I checked tasks 1–8 against the diff, and each one is present with the wording the plan asked for.
- All run interdicts hold:
  - No change to `implementer.md`, `po-bounds.sh`, `docs/installation.md` or the templates.
  - No existing test file changed.
  - The body of ADR-0068 is untouched.
  - The resuming table gains exactly one row, placed just before the plan row.
  - `.claude/` and `.polype/` are untouched.
- No change the plan did not ask for.
- Everything the diff refers to exists:
  - the `## Structuring facts` section, the first section of `method/templates/research.md`;
  - the `## Escalation signals` QA clause at `po-flow.md:51`;
  - the `frontmatter` helper at `tests/lib.sh:13`;
  - `ADR-0070`.
- The neighbours agree with the change: `method/templates/stories.md:14`, `po-flow.md:43` and `agentic-stories/SKILL.md:53` already say a `Fixes` story is researched under `diagnostic`.

## Bite proof
Each mutation was run against `tests/defect-and-routing-paths.test.sh` only, then undone with `git checkout --`. `git diff --exit-code` confirmed every file was back to its committed state, and the worktree is clean.

| Mutation | Tests failed |
| --- | --- |
| `po-drive.md`: marker row moved below the plan row | 1 (`no_root_cause_goes_to_a_human`, "the marker row comes after the plan row") |
| `po-research.md`: the new `diagnostic` sentence removed | 1 (`every_path_runs_the_diagnostic`) |

Four tests, well within `Test budget` (25). None of them is one of the "tests that prove nothing" kinds: each assertion is limited to one section of the file it checks.

## Findings
1. **minor**: the research's marker position is worded two different ways.
   - `method/skills/diagnostic/SKILL.md` puts the marker at the top of `## Structuring facts`.
   - `method/commands/po-orchestrator.md:46` and `method/commands/po-research.md` (the new finish line) say "the research **opens with** `Root cause: not found`". Read literally, that is the file's first line, which is always `# Research — <id>`.
   - Because `## Structuring facts` is the template's first section, both wordings point to nearly the same place.
   - `/po-plan`'s check ("holding the line") still catches the marker on the orchestrator path, so nothing breaks silently. The wording should still be aligned.
2. **minor**: "holding the line" does not say the match must be the whole line.
   - ADR-0070 says the driver reads the marker with `grep -x`, and the plan's pivot rests on an exact match.
   - `po-drive.md:50`, `po-plan.md:26` and `planner.md:39` only say "holding the line `Root cause: not found`". A research that merely quotes the token inside a sentence (a story about this very mechanism, say) could be read as carrying it.
   - "a line that is exactly …", or naming `grep -x`, would close this.
3. **minor**: three of the new stop clauses have no test.
   - The stop sentence in `po-orchestrator.md` ("ends the run here … with no plan").
   - The dispatch sentence in `po-drive.md` (step 1).
   - The alternate finish line in `po-research.md`.
   - Deleting any of them fails no test, because `every_path_runs_the_diagnostic` only checks for `` `diagnostic` skill ``/`Fixes`/`Corrige` in the orchestrator section. The rules the story most depends on (the skill marker, the drive row and its order, the po-plan check, the planner bullet) are tested.

## Not verified
- **Whether naming the `diagnostic` skill in the prose of `/po-research` and `/po-orchestrator` makes the main context load and follow it.** Neither command lists a skill mechanism, and text tests cannot show it; the record's "Not proven here" says the same. To cover it, a person runs `/po-research` or `/po-orchestrator` on a throwaway `Corrige` story and checks that the research follows the skill (reproduction, hypotheses, stop after three).
- **Whether a model writes the marker exactly, alone on its line, at run time.** To cover it, run the diagnostic on a defect whose cause cannot be found and `grep -x` the research.
- **The end-to-end routing of a stopped lane.** I never saw `/po-drive` (or `/po-drive status`) route a real lane to a human from this row. To cover it, put the marker into a scratch worktree's research and run `/po-drive status`.
- **The s98 interplay.** `po-execute` now forbids checkout only in the story worktree, but `po-bounds` and `implementer.md` are unchanged here (they belong to s98), so the throwaway-clone permission is not yet enforced in agreement. That is for s98's review.

Max severity: minor
Ship allowed: yes
