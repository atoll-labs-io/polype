# Research — s26-planner

[Story](../stories.md)

## Structuring facts
- No assumption of the story proved wrong; every piece it relies on exists.
- `method/agents/` holds three subagents (`implementer.md`, `reviewer.md`, `stories-reviewer.md`); all share one shape: frontmatter `name/description/tools/model/skills`, then a body opening on `Reads settings:` — `method/agents/implementer.md:1-13`.
- Creating `method/agents/planner.md` immediately submits it to three mechanical rules that loop over `method/agents/*.md`: `bin/po-lint:72` (settings declared, settings known, tool contract, fail-closed arrows) and `tests/structure.test.sh:26`.
- The worktree is created by `/po-research` (`method/commands/po-research.md:22-30`), not by a subagent; ADR-0016 gives that job to the driver. The story's criterion only asks the planner to **stop** on a mismatch.
- Who writes `validated: yes` is unsettled: `method/templates/agents-local.md:35` says "the planner approves its own", while s29/s30 hand grouped plan validation to the driver. The plan must choose; see Open questions.

## Story
`s26-planner` (`docs/stories.md:392-404`, complexity 3, depends on nothing). A `planner` subagent that does the research and the plan of one story inside its worktree, so the driver of s27 can run several stories at once — a subagent cannot run a slash command.

Owns: `method/agents/planner.md`, `tests/planner.test.sh`. Nothing else.

Acceptance criteria (each is a `test_<name>` function of `tests/planner.test.sh`):
1. `planner_carries_the_research_and_plan_contracts` — carries the requirements of `/po-research` (assumptions tested, facts with `path:line`, length cap) and of `/po-plan` (checkable tasks, interdicts, pivot, test budget, cap), without rewriting them its own way.
2. `planner_preloads_testing_doctrine_and_codebase_analysis` — both skills preloaded.
3. `planner_never_writes_code` — writes only `docs/research/<id>.md` and `docs/plans/<id>.md`, and stops when the worktree or the branch does not match.
4. `planner_reports_the_track_it_used` — says whether it produced a separate research or a short-track plan, per `Story track` and `Flow threshold`.

## Current code
- `method/agents/implementer.md` — 49 lines. `tools: Read, Write, Edit, Bash, Grep, Glob`, `model: opus`, `skills: [testing-doctrine]`. Body: `Reads settings:` line, then "Before the first edit" (worktree and branch checks), fix runs, the loop, after the last task, limits, final message.
- `method/agents/reviewer.md` — 45 lines. `tools: Read, Grep, Glob, Bash, Edit`, `model: inherit`, three skills. Delegates its procedure to the preloaded skill: *"The procedure … is the preloaded `review-antihallu` skill. This file only sets your inputs, your limits and the shape of your answer."* (`method/agents/reviewer.md:15`). That is the house style for a subagent: point at the contract, do not restate it.
- `method/commands/po-research.md` — the contract to carry: assumptions tested against the code (`:39`), each fact with its `path:line` and **200 lines at most** (`:48`), report filled from `templates/research.md`, left uncommitted (`:50`).
- `method/commands/po-plan.md` — tasks in execution order each naming the test that would fail (`:33-34`), run interdicts (`:36`), the pivot (`:37`), `Test budget` (`:35`), `templates/plan.md` with `validated: no` and **250 lines at most** (`:42`).
- `method/commands/po-flow.md` — the short track: `Story track`/`Flow threshold` decision (`:27-32`), five escalation signals checked twice (`:34-46`), `templates/plan-flow.md` with `track: flow`, about 150 lines (`:59`).
- `tests/lib.sh` — helpers: `contains` (exact, `grep -qF`), `needs_tool`/`lacks_tool` over the frontmatter, `require_file`, `frontmatter`, `settings_read_by`, `fail`.

## Attachment points
- New file `method/agents/planner.md`; `bin/polype-dev-install:45` installs `method/agents` into `.claude/agents` with a tree copy, so no registry to update.
- New file `tests/planner.test.sh`; `tests/run.sh:6` globs `*.test.sh`, so no runner to update.
- No other method file needs to change: `method/AGENTS.md`, `method/commands/po-help.md` and `method/commands/po-status.md` belong to **s31** (`docs/stories.md:459`), and `method/templates/agents-local.md` belongs to **s27**.

## Verified interfaces
- Subagent frontmatter keys actually parsed by the tooling: `tools:` inline list (`tests/lib.sh:22`, `bin/po-lint:36`) and `skills:` YAML list (`bin/po-lint:52-61`).
- `bin/po-lint` rules that will apply to `planner.md`:
  - *settings* — a `^Reads settings:` line is mandatory, and each backticked name must appear in `method/templates/agents-local.md` (`bin/po-lint:87-104`).
  - *tools* — `Write` is forbidden only for a file whose `skills:` list holds `review-antihallu` or `stories-review` (`bin/po-lint:139-143`); `AskUserQuestion` in the body must be declared (`:120-123`); `Agent` and `Edit` together are forbidden (`:125-129`).
  - *fail-closed* — scanned **only** inside sections titled `## Checks`, `## Preconditions` or `## Step 0` (`bin/po-lint:160`): there, a line whose left side of `→` names an absence must contain `stop`, `ask`, `carry on` or `never blocks`.
- Settings available in `method/templates/agents-local.md:9-28`: `Story track`, `Flow threshold`, `Test budget`, `Target branch`, `Worktree root`, `Install`, `Plan validation`, … The fleet settings of s27 (`Parallel`, `Max attempts`, `Tracker`) do **not** exist yet: reading one would fail the lint and `structure.test.sh`.
- `templates/research.md`, `templates/plan.md` and `templates/plan-flow.md` all exist (`method/templates/`), so the planner can point at them by name.

## Traps
- `tests/overlap.test.sh` fails when a line of `method/` shares 8+ consecutive words with Killer SaaS: the new subagent must be written from the existing files' own prose.
- `tests/structure.test.sh:24` (`every_setting_read_by_a_command_exists_in_template`) and `tests/lint.test.sh` both break the moment `planner.md` lands without a clean `Reads settings:` line. Running the full suite is the cheap proof.
- Naming a section `## Checks` in `planner.md` puts every `→` line of that section under the fail-closed rule — desirable, but each arrow must then carry its stop.
- `contains` is exact and case-sensitive: a test quoting a sentence must quote it character for character, and the sentence must be worth quoting (a clause with a consequence, not a title).
- s25 landed `bin/po-lint` on the target branch one commit ago (`c5eac5c`): the branch is fresh, no rebase needed.
- No migration, no dependency, no screen.

## Open questions
- **Does the planner ever write `validated: yes`?** `templates/agents-local.md:35` describes `Plan validation: autonomous` as "the planner approves its own and says so", but `s30-grouped-validation` (`docs/stories.md:440`) gives the driver the job of validating a wave's plans in one go, and in `human` mode a subagent cannot ask the user anything. The plan decides; this is its pivot.
- **Does the planner ever create a worktree?** ADR-0016 says the driver prepares them, and criterion 3 only asks the planner to stop on a mismatch. If it never creates one, it reads neither `Worktree root` nor `Install` — which keeps its `Reads settings:` line honest.

## Complexity
Story: 3 → after reading the code: **2**. Two new files, no existing file to change, the house style already fixed by `reviewer.md`. What remains of the 3 is the contract-carrying discipline: the subagent must bind the planner to `/po-research` and `/po-plan` without paraphrasing them into a third, divergent version.

## Split
Not needed at 2.
