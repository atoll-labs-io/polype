---
validated: yes
---
# Plan — s113-reuse-ladder

Branch `story/s113-reuse-ladder`. Read `docs/research/s113-reuse-ladder.md` first. This plan builds on it and does not repeat it.


The choice is drafted in `docs/decisions/ADR-0085-l-echelle-de-reutilisation-se-tient-au-plan-mesuree-contre-un-temoin.md` (ADR-0085). The owner chose option A on 2026-10-13; the ADR is `accepted`. Its options, ranked:
- A: ladder at plan time, judged in review, measured against a control (recommended);
- B: one "Follow YAGNI." line;
- C: review only;
- D: permanent hooks;
- E: ladder in the implementer.

The tasks below are written for option A.

## Story
Every plan says, for each piece of new code, what it could have reused and why it does not. The review flags new code that an existing helper already provided. Four criteria, restated under `## Story` of the research:
- `plans_carry_a_reuse_section`
- `never_cut_list_is_explicit`
- `planner_requires_the_ladder`
- `review_flags_rebuilt_helpers`

## Reuse
This plan writes one piece of new code, `tests/reuse-ladder.test.sh`. Everything else is prose.

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| `section_of`, `holds` in the new test | already in this repository: `tests/scene-and-simulation-drivers.test.sh:15-17`, copied as each test file does (no shared helper exists in `tests/lib.sh`) | — |
| `contains`, `require_file`, `fail` | already in this repository: `tests/lib.sh` | — |
| the new test file itself | new code | One test file per story is a rule of this repository (`AGENTS.md`, Conventions). |

## Tasks
"The section text" below means this exact block. Both templates carry it word for word, between `## Story` and `## Tasks`:

```
## Reuse
<For each piece of new code the tasks write, the first rung that holds and why each rung above it fails. The rungs, in this order: already in this repository, cited by `path:line`; the standard library or the platform; a dependency already installed; new code. Add no option, setting or abstraction the story does not ask for. The ladder never cuts validation at a trust boundary, security, or the error handling that keeps data from being lost. A plan that writes no new code says so in one line instead of leaving this section out.>

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
```

1. [x] **Templates.** Insert the section text into `method/templates/plan.md`, after the `## Story` placeholder (`:9`) and before `## Tasks` (`:11`). Insert it into `method/templates/plan-flow.md`, after the `## Story` placeholder (`:25`) and before `## Tasks` (`:27`). Keep one blank line around each block.
   - Change no other line of either template.
   - Test that fails if wrong: `test_plans_carry_a_reuse_section` and `test_never_cut_list_is_explicit` (task 5).
2. [x] **`method/agents/planner.md`.**
   - In the **Plan** bullet (`:40`), after "a `## The pivot` section naming the decision everything hinges on and how it could be wrong;", insert: `a `## Reuse` section filled in, one line when the plan writes no new code;`
   - In the **Short track** bullet (`:41`), after "each escalation signal marked absent with where you checked,", insert: `a `## Reuse` section filled in, one line when the plan writes no new code,`
   - Write the words "lines at most" nowhere new (trap: `tests/planner.test.sh:9`).
   - Test that fails if wrong: `test_planner_requires_the_ladder`.
3. [x] **`method/commands/po-plan.md` and `method/commands/po-flow.md`.**
   - In `## Writing the plan` of `po-plan.md`, add one bullet right after **The pivot** (`:42`): `- **Reuse**: a `## Reuse` section filled in — for each piece of new code, the first rung of the template's ladder that holds and why each rung above it fails; one line when the plan writes no new code, never a missing section.`
   - In `po-flow.md` `## The plan` (`:65`), after "six tasks at most, each naming the test that would fail if it were wrong.", add this sentence: `It carries a `## Reuse` section filled in, one line when the plan writes no new code.`
   - Keep both headings exactly as they are (trap: `tests/flow.test.sh:58-61`).
   - Test that fails if wrong: `test_planner_requires_the_ladder`.
4. [x] **`method/skills/review-antihallu/SKILL.md` step 3.** After the step-3 line (`:36`), add one blank line, then this single sentence on a line of its own. It must not start with a bold number (trap: `tests/review.test.sh:29`):
   `New code that an existing helper you can cite by `path:line`, or the standard library, already provided is a **major** finding, and a gap between the plan's `## Reuse` section and the diff is judged as a gap against a task.`
   - It stays one sentence on one line, so s114 can replace it exactly with "Follow YAGNI.".
   - Say nothing about dependencies: `review-lenses/SKILL.md:54` owns that.
   - Test that fails if wrong: `test_review_flags_rebuilt_helpers`.
5. [x] **New `tests/reuse-ladder.test.sh`**: four tests, named after the criteria.
   - Define `section_of` and `holds` locally, copied from `tests/scene-and-simulation-drivers.test.sh:15-17`.
   - `test_plans_carry_a_reuse_section`:
     - For each of `plan.md` and `plan-flow.md`, `## Reuse` is a heading line, and its line number is between `## Story` and `## Tasks`.
     - Its section `holds`:
       - `the first rung that holds`
       - `why each rung above it fails`
       - `no option, setting or abstraction the story does not ask for`
     - The four rungs appear in order in the section, by `awk index` on the flattened text:
       - `already in this repository, cited by \`path:line\``
       - `the standard library or the platform`
       - `a dependency already installed`
       - `; new code`
     - The two sections are byte-identical (`[ "$(section_of plan.md Reuse)" = "$(section_of plan-flow.md Reuse)" ]`).
   - `test_never_cut_list_is_explicit`: each template's `## Reuse` section `holds` `never cuts validation at a trust boundary, security, or the error handling that keeps data from being lost`.
   - `test_planner_requires_the_ladder`:
     - The line of `planner.md` starting `- **Plan** —` and the one starting `- **Short track** —` each hold `` `## Reuse` section filled in, one line when the plan writes no new code ``.
     - `section_of po-plan.md 'Writing the plan'` holds `` `## Reuse` section filled in `` and `one line when the plan writes no new code`.
     - `section_of po-flow.md 'The plan'` holds the same two phrases.
     - Each template holds `says so in one line instead of leaving this section out`.
   - `test_review_flags_rebuilt_helpers`:
     - The block of `review-antihallu/SKILL.md` from the line matching `^\*\*3\. ` up to the line before `^\*\*4\. ` holds:
       - `an existing helper you can cite by \`path:line\`, or the standard library, already provided is a **major** finding`
       - ``a gap between the plan's `## Reuse` section and the diff is judged as a gap against a task``
     - Exactly one line of that block holds `**major**`.
   - Run `bash tests/run.sh reuse-ladder.test.sh planner.test.sh plan.test.sh flow.test.sh review.test.sh surface-routing.test.sh scene-and-simulation-drivers.test.sh`.
6. [x] **Full suite, once, when tasks 1-5 are done.** Run `po-run --story s113-reuse-ladder --label full-suite -- 'bash tests/run.sh'`. The project has no type check (`Typecheck: —`).

## Scene viewpoints
—

## Run interdicts
- These files end with an empty diff:
  - `method/agents/implementer.md`
  - `method/skills/review-lenses/SKILL.md`
  - `method/agents/reviewer.md`
  - `method/templates/review.md`
  - `bin/po-eval`
  - `evals/`
  - `method/templates/agents-local.md`
- `.claude/`, `.polype/`, the root `AGENTS.md` and `AGENTS.local.md` are untouched. The `Reads settings:` line of every owned file keeps the same names.
- No existing test file changes. The new rules are tested only in `tests/reuse-ladder.test.sh`.
- In `review-antihallu`, the `**1.`–`**6.` lines keep their text, and only one line (plus its blank line) is added inside step 3.
- No text is copied from Ponytail or Killer SaaS. `tests/overlap.test.sh` stays green.
- The only ADR added is ADR-0085, and it is `accepted`: the owner chose option A on 2026-10-13.

## The pivot
Everything hinges on one choice: the ladder lives in the plan, the reviewer holds the diff against it, and no hook enforces it (ADR-0085, option A). It can go wrong in three ways:
- **The section gets filled with boilerplate.** A planner writes "new code — nothing fits" for every row, and the review has nothing to contest. Compare: the step-3 sentence grades the code itself as **major** when a citable helper existed, whatever `## Reuse` says.
- **The step-3 sentence blurs with the Dependencies lens.** Then a rebuilt dependency is graded twice. Compare: task 4 says nothing about dependencies; check `review-lenses/SKILL.md:54` is unchanged.
- **s114 cannot isolate the sentence.** If task 4 merges it into the step-3 paragraph or splits it in two, the control arm swaps the wrong text. Compare: `test_review_flags_rebuilt_helpers` requires a single line holding `**major**` in step 3.

## Files touched
- `method/templates/plan.md`
- `method/templates/plan-flow.md`
- `method/agents/planner.md`
- `method/commands/po-plan.md`
- `method/commands/po-flow.md`
- `method/skills/review-antihallu/SKILL.md`
- `tests/reuse-ladder.test.sh` (new)
- `docs/decisions/ADR-0085-l-echelle-de-reutilisation-se-tient-au-plan-mesuree-contre-un-temoin.md` (new, named here)
- `docs/research/s113-reuse-ladder.md`, `docs/plans/s113-reuse-ladder.md`, `docs/verif/s113-reuse-ladder.md` (evidence)

## Test strategy
This repository has one layer: bash phrase tests on method prose. Each rule is checked once, inside the section that holds it, so deleting the sentence fails its test.
- New tests: 4, well within `Test budget` 25. No existing test changes.
- Visual checks: none (`Surface: —`, `QA stage: —`).
- Not proven: whether a planner actually fills the ladder honestly, and whether a reviewer catches a rebuilt helper. Phrase tests cannot show either. s114 measures the second against a "Follow YAGNI." control.

## Done when
- The seven files above are changed as the tasks say, and the full suite is green through `po-run`.
- The owner has settled ADR-0085 through `/po-plan`.
- The review has no open critical finding.
- The story lands as one commit `s113-reuse-ladder: Le plan dit ce qu'il réutilise avant d'écrire du neuf` through a pull request.

Checked against each criterion (`Plan validation: autonomous`); the technical choice was settled by the owner (option A, 2026-10-13), then validated under `Plan validation: autonomous`. No human reviewed this plan.
- `plans_carry_a_reuse_section`: tasks 1 and 5.
- `never_cut_list_is_explicit`: tasks 1 and 5.
- `planner_requires_the_ladder`: tasks 2, 3 and 5 (the one-line rule is in the template, task 1, as well as in the three contracts).
- `review_flags_rebuilt_helpers`: tasks 4 and 5.
