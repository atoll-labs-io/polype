---
validated: yes
---
# Plan — s35-fleet-design

[Story](../stories.md) · [Research](../research/s35-fleet-design.md)

Branch `story/s35-fleet-design`. Read `docs/research/s35-fleet-design.md` first; this plan builds on it without repeating it.

## Story
A story with a screen must cross its lane without a human in the middle of a wave (defect 24). Criteria:
1. `designer_agent_carries_the_design_contract` — a `designer` subagent carries `/po-design`'s requirements and preloads `design-doctrine`.
2. `drive_inserts_design_between_plan_and_execute` — the lane dispatches the designer after the plan, before the implementer.
3. `drive_stops_a_screen_lane_without_a_design_system` — no `docs/design-system.md`, or `Design source: —` → the lane stops, says so, never skips the stage.
4. `designer_writes_only_in_the_story_design_folder` — it writes only under `docs/designs/<id>/`.

Two gaps the research opened are settled here, in `## The pivot`: nobody approves a design a lane produced, and an unclear derived/new call is taken as new.

## Tasks

1. [x] **`docs/decisions/ADR-0019-design-en-lane-sans-approbation.md`** — from `templates/adr.md`, `status: proposed`, numbered after ADR-0018 with the repository's `ADR-NNNN-<slug>.md` filename. Records that a design produced inside a lane is not approved by a human, against the two options turned down: a `Design validation` setting of its own, and folding the design into the wave's plan question (ADR-0017). States the consequence: `/po-design` keeps its approval for the single-story path, and the wave report names every story whose design nobody read.
   *Test able to fail*: none automated — an ADR is prose. The reviewer checks it against `templates/adr.md` and against the behaviour tasks 2 and 3 describe.

2. [x] **`method/agents/designer.md`** — new subagent, modelled on `method/agents/planner.md`.
   - Frontmatter: `name: designer`, a description naming the fleet, `tools: Read, Write, Edit, Bash, Grep, Glob`, `model: inherit`, `skills:` holding `design-doctrine` only.
   - `Reads settings: \`Design source\`, \`Design skill\`, \`Design tool\`` — those three names and no other; `Worktree root` is not read, the driver hands the absolute path.
   - `## Checks`: branch must print `story/<id>`, path not the repository root, no unexpected dirty file beyond `docs/research/<id>.md`, `docs/plans/<id>.md` and `docs/designs/<id>/`, a missing setting stops. Never `git worktree add`, `switch`, `checkout`, `stash`. Every shell command starts with `cd <path> &&` or uses `git -C <path>`.
   - The contract carried, not restated: it reads `method/commands/po-design.md` and is bound by it — derived versus new, the note from `templates/design-screen.md` with its `## Gaps`, at most one artefact chosen by `Design source`, the mockup served over local HTTP and looked at in light and dark at two widths, nothing measured, no component or token invented.
   - `Design source: internal` → it follows the skill `Design skill` names, read from `.claude/skills/<name>/SKILL.md`; that file absent, or `Design skill` at `—` → it stops before drawing and reports, it never draws from taste.
   - `## Limits`: it writes under `docs/designs/<id>/` and nowhere else — no source file, no test, no commit; the files stay uncommitted for the implementer.
   - It asks no one anything: the two places `/po-design` puts a question are replaced by the rules of `## The pivot`, and its final message carries the doubt instead.
   *Test able to fail*: `test_designer_agent_carries_the_design_contract`, `test_designer_writes_only_in_the_story_design_folder`, `test_designer_asks_no_one` in `tests/fleet-design.test.sh`; plus `tests/structure.test.sh` and `tests/lint.test.sh`, which glob `method/agents/*.md`.

3. [x] **`method/commands/po-drive.md`** — stage 2 of `### Dispatching` turns from a stop into a dispatch.
   - Keep the stage between `subagent_type: planner` and `subagent_type: implementer`, keep the literal `**The design stage**`, keep both conditions checked first and worded as stops: `` `docs/design-system.md` missing there → the lane stops `` and `` `Design source` at `—` → the lane stops ``, keep `The stage is never skipped` and `the implementer does not start`.
   - Replace the three clauses that say no such subagent exists — `a command does not run inside a subagent (ADR-0016)`, `no design subagent exists`, `` `/po-design <id>` to run in `<Worktree root><id>` `` — with `subagent_type: designer`, dispatched like the others: the story id and the absolute worktree path, its contract being its own file. Conditions met and `docs/designs/<id>/design.md` already present → the note on disk is this lane's design and no designer is dispatched (`## Resuming` forbids replaying a recorded stage).
   - The design stage is started whole, like the others: every designer of a wave leaves before any of them is waited on.
   - Rewrite the paragraph that followed (the one contrasting the fleet with `/po-orchestrator`): the plan of a screen story is still written before its design, so the implementer is still the one reading `docs/designs/<id>/design.md` before the screen tasks; `/po-orchestrator` stays the path when the plan must be built on the design.
   - `## Report`: add that it names every story whose design no human approved, the way it already does for plans approved without a human.
   - `## Resuming` is unchanged — its row already sends a screen lane without a note to the design stage.
   *Test able to fail*: `test_drive_inserts_design_between_plan_and_execute`, `test_drive_stops_a_screen_lane_without_a_design_system`.

4. [x] **`tests/fleet-design.test.sh`** — the story's test file, five functions, using `section_of`/`holds` as `tests/drive.test.sh` defines them locally.
   *Test able to fail*: itself — each function must fail on the tree as it stands before tasks 2 and 3.

5. [x] **`tests/drive.test.sh`** — delete `test_drive_lane_includes_design_when_the_story_has_a_screen` (lines 113-143), whose clauses at 128-130 assert the behaviour task 3 removes. What stays true in it is re-asserted by task 4, updated; nothing else in the file is touched.
   *Test able to fail*: `bash tests/run.sh drive.test.sh` must stay green and must no longer hold the three obsolete clauses.

6. [x] **`docs/defauts.md`** — line 39, defect 24: `ouvert` → `corrigé par s35`. That line only.
   *Test able to fail*: none automated; the reviewer reads the diff.

7. [x] **Full run** — `bash tests/run.sh` green, `bin/po-lint` with no breach, recorded in `docs/verif/s35-fleet-design.md`.

## Run interdicts
- `method/commands/po-design.md` ends with an empty diff: the human command is not what this story changes.
- `method/agents/implementer.md`, `method/agents/reviewer.md`, `method/commands/po-orchestrator.md`, `method/commands/po-flow.md`, `method/AGENTS.md` (owned by s39) and `method/templates/*` all end with an empty diff.
- `bin/polype-dev-install` and `bin/po-lint` end with an empty diff: the installer globs `method/agents`, and the new file must satisfy the lint as it is, not a lint relaxed for it.
- `.claude/` and `.polype/` are installed copies — untouched.
- `tests/design.test.sh`, `tests/design-handoff.test.sh`, `tests/structure.test.sh`, `tests/lint.test.sh`, `tests/wiring.test.sh`, `tests/fleet-wiring.test.sh`: no test removed, no assertion weakened.
- In `tests/drive.test.sh`, only the one named test is removed.
- In `docs/defauts.md`, only the status cell of line 24 changes.
- No test is added to make a new clause pass by quoting a sentence nobody would write otherwise: each assertion quotes a clause a reader of `po-drive.md` would act on.

## The pivot
**The decision**: a design produced inside a lane is written, recorded and used without a human approving it; the wave report says so, story by story.

How it could be wrong, and what to compare it against:
- *A screen is not a plan.* A plan approved without a human is still judged by the review against the story's criteria; a screen nobody looked at ships as the product's face. Compare with ADR-0017: grouped validation exists because a per-story question serialises the lanes — the same argument applies, but the stakes differ. If the reviewer finds this too loose, the fallback is a `Design validation` setting, which widens the story and is the option ADR-0019 turns down.
- *The derived/new tie-break.* `/po-design:40` asks when it cannot tell; the designer instead takes the screen as **new**, produces the one artefact and records the doubt in the note's `## Gaps`. Wrong if a wave then fills the repository with artefacts for screens that were plainly derived. Compare with `design-doctrine`: a doubt resolved as derived leaves the implementer a note with no layout, which is the worse failure.
- *The skill the designer cannot carry.* `Design skill` is per project while a subagent's `skills:` list is fixed when the method is written, so the designer reads `.claude/skills/<name>/SKILL.md` instead of preloading it. Wrong if a project's drawing skill is not a file at that path — then the lane stops and says so, which is the behaviour this plan wants anyway.

**Trap for whoever writes `designer.md`**: `bin/po-lint:131` reports any body containing the literal `AskUserQuestion` when the frontmatter does not declare it. Say "it asks no one anything", as `method/agents/planner.md:46` does, and the lint stays green.

## Files touched
| File | Change |
| --- | --- |
| `docs/decisions/ADR-0019-design-en-lane-sans-approbation.md` | new |
| `method/agents/designer.md` | new |
| `method/commands/po-drive.md` | stage 2 of `### Dispatching`, the paragraph after it, `## Report` |
| `tests/fleet-design.test.sh` | new |
| `tests/drive.test.sh` | one test removed |
| `docs/defauts.md` | line 24 status |
| `docs/verif/s35-fleet-design.md` | the record |

`tests/drive.test.sh` and `docs/decisions/` are outside the story's `Owns`; the research says why they cannot stay out. No other lane is running, so nothing collides — but the reviewer is told to check that nothing else in those paths moved.

## Test strategy
Automated, five functions in `tests/fleet-design.test.sh`, one per acceptance criterion plus the autonomy clause — well inside `Test budget: 25`:

| Function | What it bites |
| --- | --- |
| `test_designer_agent_carries_the_design_contract` | `designer.md` exists, declares `design-doctrine` in `skills:`, reads `method/commands/po-design.md` rather than restating it, and names the four requirements: derived versus new, one artefact at most, served and looked at, nothing invented, gaps recorded |
| `test_drive_inserts_design_between_plan_and_execute` | in `## A wave`, `subagent_type: designer` sits between `subagent_type: planner` and `subagent_type: implementer`; the driver declares it reads `Design source` |
| `test_drive_stops_a_screen_lane_without_a_design_system` | both conditions still stop the lane, the stage is never skipped, the implementer does not start — and the three obsolete clauses are gone |
| `test_designer_writes_only_in_the_story_design_folder` | `designer.md` names `docs/designs/<id>/` as its only output and forbids source files, tests and commits |
| `test_designer_asks_no_one` | `designer.md` declares no `AskUserQuestion` tool, and settles both tie-breaks itself: the screen is taken as new when unclear, and it never waits for an approval |

The four suites that glob `method/agents/*.md` — `structure`, `lint`, and through them `po-lint` — cover the new file for free; no test is added to duplicate them.

Visual checks: none, this story has no screen.

## Done when
- `bash tests/run.sh` green, `bin/po-lint` with no breach, both in `docs/verif/s35-fleet-design.md` with their exit codes and the tree.
- The five functions each fail on the pre-story tree and pass after.
- One commit on `story/s35-fleet-design` carrying the research, this plan with its ticks, the record and the code.
- A review with no open critical finding, then one squash commit on `m5-distribution`.
