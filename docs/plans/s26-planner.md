---
validated: yes
---
# Plan — s26-planner

Branch `story/s26-planner`. Read `docs/research/s26-planner.md` first; this plan builds on it without repeating it.

## Story
A `planner` subagent that does the research and the plan of one story inside its worktree, so the driver of s27 can run several lanes at once — a subagent cannot run a slash command (ADR-0016).

Acceptance criteria, each the name of a `test_<name>` function in `tests/planner.test.sh`:
1. `planner_carries_the_research_and_plan_contracts`
2. `planner_preloads_testing_doctrine_and_codebase_analysis`
3. `planner_never_writes_code`
4. `planner_reports_the_track_it_used`

## Tasks

1. [x] **Frontmatter of `method/agents/planner.md`** — `name: planner`; a `description:` saying it explores and plans one story in its worktree and is called by the fleet driver; `tools: Read, Write, Bash, Grep, Glob` (no `Edit`, no `AskUserQuestion`, no `Agent`); `model: inherit`; `skills:` list holding `codebase-analysis` then `testing-doctrine`.
   *Test that would fail:* `planner_preloads_testing_doctrine_and_codebase_analysis` and the `lacks_tool … Edit` assertion of `planner_never_writes_code`.

2. [x] **`Reads settings:` line and the guard section** — first body line: ``Reads settings: `Story track`, `Flow threshold`, `Plan validation`, `Test budget` `` and nothing else (the four names exist in `method/templates/agents-local.md:9-28`; `Parallel`, `Max attempts` and `Tracker` arrive with s27 and must not be read here). Then a section titled `## Checks` holding, one arrow per line, each ending in a stop: the message names the worktree and the story id, and every shell command starts with `cd <path> &&` or uses `git -C <path>`; `git -C <path> rev-parse --abbrev-ref HEAD` not printing `story/<id>` → stop and report; `<path>` equal to the repository root, a detached HEAD, or an unexpected uncommitted change → stop and report; never `worktree add`, `switch`, `checkout` or `stash`.
   *Test that would fail:* `planner_never_writes_code`, plus `bin/po-lint` (rules *settings* and *fail-closed*, which scans `## Checks` sections — `bin/po-lint:160`) run by task 6.

3. [x] **The track section** — how the subagent chooses, taken from `method/commands/po-flow.md:27-32`: `Story track` `full` → a separate research then a plan; `flow` → the short track; `auto` → the short track only when the story's complexity in `docs/stories.md` is at most `Flow threshold`, and a story with no written complexity takes the full track. A missing setting is a stop, never a guess. The five escalation signals of `method/commands/po-flow.md:34-46` send a story back to the full track, and the subagent says so instead of writing a short-track plan.
   *Test that would fail:* `planner_reports_the_track_it_used`.

4. [x] **The contract section** — the subagent does not restate `/po-research` and `/po-plan`, it binds itself to them, the way `method/agents/reviewer.md:15` binds itself to its skill. Name the requirements it must honour and where they live: research → assumptions opened and checked against the code, every fact with its `path:line`, `templates/research.md`, **200 lines at most**; plan → tasks in execution order each naming the test that would fail if the task were wrong, `## Run interdicts`, `## The pivot`, within `Test budget`, `templates/plan.md` with frontmatter `validated: no`, **250 lines at most**; short track → `templates/plan-flow.md`, `track: flow`, about 150 lines. Both files are left uncommitted: the implementer commits them.
   *Test that would fail:* `planner_carries_the_research_and_plan_contracts`.

5. [x] **Validation and the final message** — per `Plan validation`: `autonomous` → check the plan against each acceptance criterion, write `validated: yes`, and state that no human reviewed it; `human` → leave `validated: no` and report that the plan awaits the human checkpoint, since a subagent asks no one anything. Then the shape of the answer: the track used and why, the two paths written, the wrong assumptions found, the re-scored complexity, and whether the plan is validated. Add the limits: writes only `docs/research/<id>.md` and `docs/plans/<id>.md`, touches no source file, no commit, and a structural choice the ADRs leave open is decided in the plan with an ADR under `docs/decisions/`, never left to the implementer.
   *Test that would fail:* `planner_reports_the_track_it_used` and `planner_never_writes_code`.

6. [x] **`tests/planner.test.sh`** — header `#!/usr/bin/env bash`, comment `# s26 — the planner subagent.`, `AGENT="$METHOD/agents/planner.md"`, then exactly the four `test_` functions named above, using `require_file`, `contains`, `needs_tool`, `lacks_tool`, `settings_read_by`, `frontmatter` and `fail` from `tests/lib.sh`:
   - `planner_carries_the_research_and_plan_contracts` — `contains` on the research cap, the plan cap, `path:line`, `## Run interdicts`, `## The pivot`, `templates/research.md`, `templates/plan.md`; **and** it re-reads `method/commands/po-research.md` and `method/commands/po-plan.md` and fails if a cap quoted by the subagent no longer appears in its command, so the two cannot drift apart.
   - `planner_preloads_testing_doctrine_and_codebase_analysis` — both names appear in the `skills:` list of the frontmatter, not merely in the body.
   - `planner_never_writes_code` — `lacks_tool Edit`, `needs_tool Write`, `needs_tool Bash`, and `contains` on the branch check and on the sentence forbidding `worktree add`, `switch`, `checkout` and `stash`.
   - `planner_reports_the_track_it_used` — `settings_read_by` holds `Story track` and `Flow threshold`, and `contains` on the clause making the subagent report the track it used.
   Then run `bash tests/run.sh planner.test.sh`, `bash bin/po-lint` and the full `bash tests/run.sh`; all green before the record.

## Run interdicts
- `method/AGENTS.md`, `method/commands/po-help.md`, `method/commands/po-status.md` and `docs/parite-killer-saas.md` end with an empty diff: they belong to **s31** (`docs/stories.md:459`), which wires the fleet into the rules, the help and the status. Do not declare the new subagent there and do not tick D02/D04.
- `method/templates/agents-local.md` ends with an empty diff: it belongs to **s27**. No new setting is added by this story.
- `method/commands/po-research.md`, `method/commands/po-plan.md` and `method/commands/po-flow.md` end with an empty diff: the subagent points at their requirements, it does not change them.
- `.claude/` and `.polype/` end with an empty diff: they are installed copies (`AGENTS.local.md`, Conventions).
- No existing test file is modified; `tests/run.sh` and `tests/lib.sh` are untouched.
- Write every line of `method/agents/planner.md` from the prose of the files cited here, never from any Killer SaaS source (ADR-0006; `tests/overlap.test.sh`).

## The pivot
**The planner honours `Plan validation` instead of always, or never, approving its own plan.** The two ways this could be wrong:
- *It should never validate, the driver should.* Compare with `docs/stories.md:440` (s30, grouped validation) — but s27 dispatches `planner` then `implementer` in one wave with nothing in between, and `/po-execute` refuses a plan without `validated: yes`. A planner that never validates would leave the fleet unable to execute anything until s30 lands.
- *It should always validate, since the fleet is autonomous.* Compare with `docs/parite-killer-saas.md:53` (D04): "en flotte, validation des plans groupée en une question par vague". Always validating would delete the very checkpoint s30 is meant to group.
Following the setting keeps both stories possible and matches `method/templates/agents-local.md:35`.

Second, smaller pivot: **the planner never creates a worktree** (ADR-0016 gives that to the driver), which is why it reads neither `Worktree root` nor `Install`. If s27 turns out to expect the lane to bootstrap itself, this section is where that shows.

## Files touched
- `method/agents/planner.md` — new.
- `tests/planner.test.sh` — new.
- `docs/research/s26-planner.md`, `docs/plans/s26-planner.md`, `docs/verif/s26-planner.md` — pipeline evidence, committed with the code.

## Test strategy
Automated, 4 tests — well within `Test budget: 25`. The layer is the only one this repository has: bash assertions over the method files (`tests/lib.sh`). One test per acceptance criterion, each quoting short exact clauses that carry a consequence, never a section title alone. The drift assertion of test 1 is the one that bites hardest: it fails if a cap in `planner.md` stops matching the command it claims to carry.

No visual check: this story produces no screen. `bin/po-lint` is not a test of this story but a guard it must satisfy; it runs as part of task 6 and again through `tests/lint.test.sh` in the full suite.

## Done when
- `method/agents/planner.md` and `tests/planner.test.sh` exist, and the four acceptance tests pass.
- `bash bin/po-lint` reports no breach, and `bash tests/run.sh` is fully green — `structure.test.sh`, `lint.test.sh` and `overlap.test.sh` included.
- The run interdicts hold: `git diff m3-flotte...story/s26-planner --name-only` lists only the files above.
- `docs/verif/s26-planner.md` is complete, and the story is one commit on `story/s26-planner`.
