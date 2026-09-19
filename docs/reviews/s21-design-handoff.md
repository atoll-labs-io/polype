# Review — s21-design-handoff

Diff reviewed: `git diff m2-cadrage...story/s21-design-handoff` (one commit, 435d0d2), in a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0

## When blocked
Not applicable.

## Evidence reused
- [x] I ran `bash .polype/hooks/po-gate.sh verif-current s21-design-handoff` and it exited 0. As a second check, `git diff --quiet e7696285… HEAD -- . ':(exclude)docs'` also exited 0. So the record `docs/verif/s21-design-handoff.md` is current (`Verification status: complete`, `bash tests/run.sh` exited 0 with 128 passed and 0 skipped), and I reused it with `Verification mode: record`. The project has no type check (`Typecheck: —`), no E2E and no build. Its "Not proven here" section says that agents actually obeying the new wording is proven only by an end-to-end story with a screen. I agree.

## Plan
- [x] Every task is present:
  - Task 1: `method/agents/implementer.md`. Lines 18, 20 and 38 cover the expected-files list, reading design.md before the screen tasks, and committing the folder with the story.
  - Task 2: `method/commands/po-execute.md`. Precondition 7 globs the design folder, and a conditional sentence is appended to the prompt. The tools are still Read, Glob, Grep and Agent.
  - Task 3: `method/commands/po-plan.md`. The design file is added to Inputs and to "Writing the plan".
  - Task 4: `method/commands/po-setup.md`. Question 4 now asks only for the source, followed by a separate conditional AskUserQuestion call that is skipped when the source is undecided. "In the same call" is gone, and there are still exactly 5 numbered lines and a "Nothing else is asked" sentence.
  - Task 5: `docs/defauts.md`. Rows 1–3 are now `corrigé par s21`; rows 4–11 are unchanged.
  - Task 6: the new test file.
  - Nothing outside the plan was changed. All changed files are within the story's Owns list, plus the plan and the record.
- [x] Run interdicts, one by one:
  - `.claude/` and `.polype/`: empty diff.
  - `po-orchestrator.md`, `method/AGENTS.md`, `method/agents/reviewer.md`: empty diff.
  - `po-execute` tools: still exactly Read, Glob, Grep and Agent, and the test asserts this.
  - Existing tests: none edited. `tests/setup-modes.test.sh` did not need to change, because the new wording keeps what it quotes.
  - Killer SaaS text: none copied. `overlap.test.sh` is green (it is part of the 128 tests in the record).
  - `docs/parite-killer-saas.md`: untouched.

## References
- [x] Every reference opened:
  - Helpers `contains`, `lacks_tool`, `tools_of` and `fail`, and the variables `ROOT` and `METHOD`, exist in `tests/lib.sh` (lines 5–43).
  - The Verified facts match the files. `po-orchestrator.md:57-58` has exactly the wording that `po-execute` now also carries, and `method/AGENTS.md:71` already lists `docs/designs/<id>/`.
- [x] No value that only looks right:
  - The glob `docs/designs/<id>/*` matches the folder that `/po-design` writes (design.md, brief.md or the artefact).
  - Under the short track's escalation rule, only a new screen escalates, so a story with a derived screen can still reach execute on the short track. `po-flow.md:73` reuses the preconditions and prompt of `/po-execute`, so it now inherits the design sentence.

## Rules
- [x] `AGENTS.md` conventions respected:
  - Method files are in English, and `po-execute` gains no Write, Edit or Bash.
  - The test file is named after the story slug, each acceptance criterion's name is its test function's name, and the tests use `tests/lib.sh` helpers.
- [x] No accepted ADR contradicted: ADR-0006 (no Killer SaaS text) and ADR-0012 (no red-first) are respected.

## Tests
- [x] The assertions pin down the five acceptance criteria. Each one also checks the opposite case: "in the same call" must be absent, question 4 must not ask for the skill or tool, rows 4–11 must still read `ouvert`, and the tool list must be exact. None of the six empty test shapes appears. There are no fixtures, mocks or catches, and every test reads the real method file.
- [x] 5 tests, well within the `Test budget` of 25.
- [x] Bite (after each change, only the test files that read the mutated file were run):
  - Removed `docs/designs/<id>/` from the implementer's expected-files line, then ran `design-handoff` and `execute`: 1 failing test (`implementer_expects_the_design_folder`). Undone; `git diff --exit-code method/agents/implementer.md` is clean.
  - Deleted po-execute's "When the story has a design, append" block, then ran `design-handoff`, `execute` and `install`: 1 failing test (`execute_mentions_the_design_when_present`). Undone; `git diff --exit-code` is clean.
  - Put back "In the same call, ask for the `Design skill` or the `Design tool`" in question 4 and removed the follow-up paragraph from po-setup, then ran `design-handoff`, `setup-modes` and `structure`: 1 failing test (`setup_asks_design_details_after_the_source`). Undone; `git diff --exit-code` is clean.
  - `git status --porcelain` is empty at the end.
- [x] No existing test was made useless.

## Neighbours
- [x] Callers read:
  - `po-orchestrator.md` stage 5 delegates "the way `/po-execute` does" and also appends the design sentence itself.
  - `po-flow.md:73` reuses the `/po-execute` prompt.
  - `reviewer.md:18-21` already reads `docs/designs/<id>/`.
  - `po-status.md:26` only checks whether the design exists.
  - Nothing is broken; see the minor finding below.

## Findings
- minor — `method/commands/po-orchestrator.md:57-58` together with `method/commands/po-execute.md:27,38-40`. The orchestrator's stage 5 applies `/po-execute`, whose precondition 7 now adds the design sentence, and then adds the same sentence again. With the orchestrator, the implementer's prompt therefore contains it twice. It does no harm, and the story notes chose to keep the orchestrator's wording. A later cycle could drop the orchestrator's own copy, since `po-execute` now carries it.

## Not verified
- Whether agents follow the new wording. These tests check the text of the method files, not how an agent behaves. Nobody has yet run a real story with a screen through the whole cycle to see four things:
  - a manual `/po-execute` actually globs the design folder and appends the sentence;
  - the implementer reads `design.md` and commits `docs/designs/<id>/` without stopping on it;
  - `/po-plan` cites the design in its screen tasks;
  - `/po-setup` makes its follow-up AskUserQuestion call only after the source answer, and skips it when the source is undecided.

  A person should run the first real story with a screen once without the orchestrator (`/po-design` → `/po-plan` → `/po-execute`) and run `/po-setup` in a scratch repository, then check each of those points.
- The installed copies under `.claude/` and `.polype/` still hold the old wording, as the plan intends. This repository's own pipeline keeps the old behaviour until the installer runs again (`bin/polype-dev-install .`).
- The full suite was not run here. I relied on the current record (128 passed); only the focused files were run during the mutations.
- Design conformity does not apply: this story has no screen and no `docs/designs/s21-design-handoff/`.

Max severity: minor
Ship allowed: yes
