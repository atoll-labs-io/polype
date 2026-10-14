---
track: flow
validated: yes
---
# Plan (short track) — s21-design-handoff

[Story](../stories.md)

Written by `/po-flow`. On the short track this one file stands in for both the research and the plan: there is no `docs/research/s21-design-handoff.md`.

## Verified facts
No assumption of the story proved wrong. Facts, opened in the code:

- `method/agents/implementer.md:18` — the expected uncommitted files are `docs/research/<id>.md`, `docs/plans/<id>.md` and, on a fix run, `docs/reviews/<id>.md`; "Any other change you did not make → stop and report." `docs/designs/<id>/` is absent: defect 2 is real.
- `method/agents/implementer.md:19` — the implementer reads the research before the first edit; nothing tells it to read `docs/designs/<id>/design.md`.
- `method/agents/implementer.md:37` — first-run commit lists "the research, the plan and its ticks, the record and all the code"; the design folder is not named.
- `method/commands/po-execute.md:4-8` — tools are Read, Glob, Grep, Agent only; checking whether `docs/designs/<id>/` exists must use Glob/Read, no Bash.
- `method/commands/po-execute.md:31-35` — the delegation prompt and the fix-run sentence; no design sentence. Only `method/commands/po-orchestrator.md:57-58` appends one ("This story has a design: docs/designs/<id>/ is expected uncommitted work, …"), so a manual `/po-execute` run never tells the implementer (defect 3).
- `method/commands/po-plan.md:29-32` — "## Inputs" lists the story, research, `AGENTS.md`, architecture and ADRs; no design file. The orchestrator's stage 4 (`po-orchestrator.md:50`) is the only place that reads `design.md` for the plan.
- `method/commands/po-setup.md:29` — heading "Step 2 — Five questions, one AskUserQuestion call each".
- `method/commands/po-setup.md:33` — question 4 says "In the same call, ask for the `Design skill` when the answer is `internal`, or the `Design tool` when it is `external`" — impossible, since one AskUserQuestion call asks all its questions at once (defect 1).
- `docs/defauts.md:9-11` — lines 1 to 3 have status `à corriger par s21`.
- `method/AGENTS.md:71` already lists `docs/designs/<id>/` as legitimate uncommitted work (s20); rules need no change.
- Existing tests quoting touched text: `tests/execute.test.sh:43-46` quotes 'on a fix run, `docs/reviews/<id>.md`: those are expected' and 'Any other change you did not make → stop and report.'; `tests/setup-modes.test.sh:29-37` counts exactly 5 numbered lines in step 2 and checks a numbered line sets `Design source`, plus 'Nothing else is asked'; `tests/wiring.test.sh:80-86` quotes the orchestrator only. None quotes the "In the same call" wording itself.
- Suite baseline on `m2-cadrage` (00ab0d7): `bash tests/run.sh` → 123 passed, 0 failed.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text (`docs/stories.md:313-328`) | absent — only markdown and bash tests touched |
| New screen | absent — story text: method files only | absent — Owns lists no UI file |
| Authorization or tenant scope | absent — story text | absent — no access rule in the touched files |
| API contract | absent — story text | absent — the implementer/po-execute prompt is internal wording, no external contract |
| New dependency | absent — story text | absent — `tests/lib.sh` helpers suffice |

## Story
As a developer, a story with a screen should pass from design to implementation without stopping, and setup should ask its design questions in the right order, so the first real story with a screen crosses the cycle, with or without the orchestrator. Complexity 2. Fixes defects 1, 2 and 3 of `docs/defauts.md`.

Acceptance criteria (each is the name of one test in `tests/design-handoff.test.sh`):
- `implementer_expects_the_design_folder` — the implementer's expected uncommitted changes include `docs/designs/<id>/`, which it reads before the screen tasks and commits with the story.
- `execute_mentions_the_design_when_present` — `po-execute` tells the subagent, when `docs/designs/<id>/` exists, that the design is part of the story (even without the orchestrator).
- `plan_reads_the_design_when_present` — `po-plan` reads `docs/designs/<id>/design.md` when it exists, and screen tasks stick to it.
- `setup_asks_design_details_after_the_source` — `po-setup` asks `Design skill` or `Design tool` in a separate `AskUserQuestion` call, after the answer on `Design source`, and only for the chosen value.
- `defects_one_to_three_marked_fixed` — in `docs/defauts.md`, lines 1 to 3 become `corrigé par s21`.

## Tasks

1. [x] `method/agents/implementer.md` — line 18: add `docs/designs/<id>/` (story with a screen) to the expected files, keeping the exact phrases 'on a fix run, `docs/reviews/<id>.md`: those are expected' and 'Any other change you did not make → stop and report.'; "Before the first edit": read `docs/designs/<id>/design.md` before the screen tasks when it exists; line 37: the first-run commit includes the design folder. Test: `implementer_expects_the_design_folder` (fails if the folder is missing from the expected list, the read or the commit).
2. [x] `method/commands/po-execute.md` — a precondition noting (via Glob, no new tool) whether `docs/designs/<id>/` exists in the worktree, and a sentence appended to the prompt when it does, carrying the same information as `po-orchestrator.md:58` (expected uncommitted work, read `design.md` before the screen tasks, commit the folder with the story). Keep the tool list unchanged. Test: `execute_mentions_the_design_when_present` (fails if the conditional sentence is absent or if `po-execute` gains Bash/Write/Edit).
3. [x] `method/commands/po-plan.md` — "## Inputs": `docs/designs/<id>/design.md` when it exists; "## Writing the plan": screen tasks build what it settles, cite it, add nothing it leaves out. Test: `plan_reads_the_design_when_present`.
4. [x] `method/commands/po-setup.md` — step 2: question 4 asks only `Design source`; a separate AskUserQuestion call, made after that answer, asks `Design skill` for `internal` or `Design tool` for `external`, and nothing for "not decided" (both stay `—`). Remove "In the same call". Keep exactly 5 numbered lines and 'Nothing else is asked' (adapt its sentence so the follow-up call is not a contradiction); adjust the heading so it no longer claims one call per question with no exception. Test: `setup_asks_design_details_after_the_source` (fails if "In the same call" returns, if the follow-up is not a separate call after the source answer, or if it is not conditional on the chosen value).
5. [x] `docs/defauts.md` — status cells of lines 1, 2, 3 → `corrigé par s21`; lines 4-11 untouched. Test: `defects_one_to_three_marked_fixed` (fails if any of rows 1-3 keeps `à corriger`, or if a row 4-11 status changes from `ouvert`).
6. [x] `tests/design-handoff.test.sh` — the five tests above, header comment `# s21 — design handoff to plan, execute and setup.`, using `tests/lib.sh` helpers; then the full suite.

## Run interdicts
- `.claude/` and `.polype/` end with an empty diff (installed copies; the installer is not rerun in this story).
- `method/commands/po-orchestrator.md`, `method/AGENTS.md`, `method/agents/reviewer.md` end with an empty diff (outside Owns; the orchestrator wording stays valid per the story notes).
- `po-execute` keeps exactly Read, Glob, Grep, Agent.
- Existing tests are not edited unless a clause they check changes; if `tests/setup-modes.test.sh` has to change, the implementer says so in its report.
- No text copied from Killer SaaS; `tests/overlap.test.sh` stays green.
- `docs/parite-killer-saas.md` untouched: this story implements no new matrix line.

## Files touched
`method/agents/implementer.md`, `method/commands/po-execute.md`, `method/commands/po-plan.md`, `method/commands/po-setup.md`, `docs/defauts.md`, `tests/design-handoff.test.sh` (new), plus `docs/plans/s21-design-handoff.md` and `docs/verif/s21-design-handoff.md`.

## Test strategy
Five contract tests in one new file, one per acceptance criterion, all at the single layer this repository has (bash checks on method text), well within `Test budget` (25). Each test quotes short exact phrases and also asserts the negative that makes it bite (e.g. "In the same call" absent from `po-setup`; rows 4-11 of `defauts.md` still `ouvert`), so removing the rule turns it red. Full suite once at the end (`Full suite: execute-end`): `bash tests/run.sh`, expected 128 passed.

## Done when
One squash commit `s21-design-handoff: Raccorder le design à l'implémentation et au setup` on `m2-cadrage`; `bash tests/run.sh` green; review with no open critical finding. No deployment.
