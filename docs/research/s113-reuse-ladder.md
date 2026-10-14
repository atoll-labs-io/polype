# Research — s113-reuse-ladder

[Story](../stories.md)

## Structuring facts
- No story assumption is false. Every file of `Owns` exists, and none of them holds a reuse ladder or a `## Reuse` section today (`grep -n Reuse method/templates/*.md method/agents/*.md`: no hit).
- The change is prose in six method files plus one new test file. There is no code, no setting, no gate and no hook. `method/agents/implementer.md:51` ("Do what the plan says and nothing else") stays as it is, so the plan carries the ladder, as the story notes want.
- The review side already covers dependencies: `method/skills/review-lenses/SKILL.md:54` says "A dependency that duplicates one already present, or what the standard library does, needs its reason too". So the new step-3 rule of `review-antihallu` covers rebuilt **code**, never dependencies. Otherwise the lens is duplicated, which the story forbids.
- The story asks for an ADR on "ladder at plan time, measured against a control, no permanent hook", submitted to the owner. ADR-0085 is reserved for this lane. The plan is therefore marked `Technical choice: waiting for a human` and stays `validated: no`, whatever `Plan validation: autonomous` says (`method/commands/po-plan.md:45`, `method/agents/planner.md:50`).
- s114 will swap "the phrase of s113 at step 3" for "Follow YAGNI.", so the step-3 addition must be one sentence on its own line, which a script can replace exactly.

## Story
Every plan says, for each piece of new code, what it could have reused and why it does not. The review flags new code that an existing helper already provided. The story has four criteria:
- `plans_carry_a_reuse_section` — `plan.md` and `plan-flow.md` carry `## Reuse`. For each piece of new code, it asks for the first rung that holds, in this order:
  1. already in this repository (`path:line`);
  2. the standard library or the platform;
  3. a dependency already installed;
  4. new code.
  It also asks why each rung above fails, and forbids any option, configuration or abstraction the story does not ask for.
- `never_cut_list_is_explicit` — the same section says the ladder never removes validation at trust boundaries, security, or the error handling that prevents data loss.
- `planner_requires_the_ladder` — four places require a filled `## Reuse`:
  - the planner's **Plan** bullet;
  - the planner's **Short track** bullet;
  - `/po-plan`;
  - `/po-flow`.
  A plan with no new code writes it in one line rather than omitting it.
- `review_flags_rebuilt_helpers` — step 3 of `review-antihallu` grades new code that a cited existing helper, or the standard library, already provided as **major**. A gap between `## Reuse` and the diff is judged like a gap against a task.

## Current code
- `method/templates/plan.md` (31 lines) has these sections, in order:
  - frontmatter `validated: no` (`:1-3`);
  - `## Story` (`:8`);
  - `## Tasks` (`:11`);
  - `## Scene viewpoints` (`:15`);
  - `## Run interdicts` (`:18`);
  - `## The pivot` (`:21`);
  - `## Files touched` (`:24`);
  - `## Test strategy` (`:27`);
  - `## Done when` (`:30`).
  Each section body is one `<placeholder>` paragraph.
- `method/templates/plan-flow.md` (46 lines) has these sections, in order:
  - frontmatter `track: flow`, `validated: no` (`:1-4`);
  - `## Verified facts` (`:9`);
  - `## Escalation signals` with its table (`:12-22`);
  - `## Story` (`:24`);
  - `## Tasks` (`:27`);
  - `## Scene viewpoints` (`:33`);
  - `## Run interdicts` (`:36`);
  - `## Files touched` (`:39`);
  - `## Test strategy` (`:42`);
  - `## Done when` (`:45`).
- `method/agents/planner.md` carries one bullet per contract. The **Plan** bullet is at `:40` and lists tasks, `## Run interdicts`, `## The pivot`, the test budget and the 250-line cap. The **Short track** bullet is at `:41`.
- `method/commands/po-plan.md` `## Writing the plan` (`:37-47`) has these bullets: tasks `:38`, test per task `:39`, budget `:40`, **Run interdicts** `:41`, **The pivot** `:42`, design `:43`, split `:44`, ADR and marker `:45`. The fill instruction with "**250 lines at most**" is at `:47`.
- `method/commands/po-flow.md` `## The plan` (`:64-67`). Its sentence at `:65` lists what the flow plan holds: frontmatter, facts, signals, six tasks, test per task, budget, about 150 lines.
- `method/skills/review-antihallu/SKILL.md` has six bold-numbered steps (`:25-46`). Step 3 is one line (`:36`). It says: "Hold the diff against the plan. Go task by task. A missing task and an unrequested change are both findings…". The severity scale is at `:52-56`, and **major** means "a genuine defect or rule breach, contained".

## Attachment points
- Both templates: a new `## Reuse` between `## Story` and `## Tasks`, so the ladder is settled before the tasks are written.
- `planner.md:40` and `:41`: one clause added to each bullet.
- `po-plan.md` `## Writing the plan`: one new bullet, next to **Run interdicts** / **The pivot** (`:41-42`).
- `po-flow.md:65`: one clause in the list.
- `review-antihallu/SKILL.md`: one sentence on its own line inside step 3, between `:36` and `**4.` (`:38`).

## Verified interfaces
- `tests/lib.sh` provides:
  - `contains <file> <phrase>`: exact `grep -qF`;
  - `require_file`;
  - `fail`;
  - `frontmatter`;
  - `settings_read_by`.
- `section_of` and `holds` are defined locally per test file, for example `tests/scene-and-simulation-drivers.test.sh:15-17`: `section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }`.
- `tests/run.sh` runs every `test_*` of `tests/*.test.sh` in its own process. A focused run is `bash tests/run.sh reuse-ladder.test.sh`.
- `tests/overlap.test.sh` (ADR-0006) checks method text for overlap with Killer SaaS (8+ words). It skips itself when the sources are missing, so it is not a guard on Ponytail's text.

## Traps
- `tests/surface-routing.test.sh:66-72` requires `## Tasks` < `## Scene viewpoints` < `## Run interdicts` in both templates. `## Reuse` placed before `## Tasks` respects it.
- `tests/planner.test.sh:9,24-29` takes the **first** `N lines at most` of `planner.md` as the research cap and the **second** as the plan cap. A new phrase "lines at most" in `planner.md` before `:41` would break it, so the new clauses must not use those words.
- `tests/flow.test.sh:58-61` needs the exact headings `## Escalation signals` and then `## The plan` in `po-flow.md`. `tests/flow.test.sh:76-81` needs `## Verified facts`, `## Escalation signals`, `path:line` and `150 lines` in `plan-flow.md`.
- `tests/review.test.sh:27-32` counts exactly six lines matching `^\*\*[1-6]\. ` in `review-antihallu`. The new step-3 line must not start with a bold number.
- `tests/review-lenses.test.sh:81,92` reads the `## After the six steps: the lenses` section of `review-antihallu`. It is untouched.
- `tests/plan.test.sh:13-17` needs `## Run interdicts`, `## The pivot` and `## Test strategy` in `plan.md`. `tests/scene-and-simulation-drivers.test.sh:21-27` needs the `## Scene viewpoints` text unchanged in both templates.
- `bin/po-eval:55-80` (`drift_check`) compares `~/.claude/skills/review-antihallu/` with `method/`. Once s113 lands, paid evals refuse to run until the global install is refreshed. This is operational only, and no test reads the real `~/.claude/`.
- The story notes forbid copying Ponytail's text (`DietrichGebert/ponytail`), and no copy of it is in this repository to check against. The method has to be written in fresh words.
- No migration, no setting (the `Reads settings:` lines stay as they are), no new dependency.

## Open questions
- What counts as "new code" in a repository like this one, made of method prose and bash? The plan uses: any new function, script, file or helper the tasks write. Rewording prose is not new code.
- Should the `## Reuse` table be required, or is prose enough? The plan puts the table in the template under the placeholder. A one-line plan with no new code keeps the line and no table.
- Should `docs/` (the French user documentation) mention the new section? No file of `docs/` lists the plan sections (`grep -rln "Run interdicts" docs/*.md`: none), so there is nothing to update.

## Complexity
The story says 3, and after reading the code it is still 3. Each edit is small. But they span six method files that must say the same thing, the test sits in the right sections, and an ADR is put to the owner.

## Split
Not needed (score 3). The measurement is already split out into s114.
