# Review — s114-reuse-ladder-eval

[Story](../stories.md) · [Plan](../plans/s114-reuse-ladder-eval.md) · [Verification](../verif/s114-reuse-ladder-eval.md)

I reviewed `git diff main...story/s114-reuse-ladder-eval` in a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: df009cee119bdd61e5e9d34a93ac84993076f1f3

## When blocked
Not blocked. I took the tree again just before answering and it had not changed.

## Ownership
I listed the diff with `git diff --name-only main...story/s114-reuse-ladder-eval`. Changed paths: `bin/po-eval`, `evals/cases/rebuilt-helper.sh`, `tests/evals.test.sh`, `tests/reuse-ladder-eval.test.sh`, plus the story's own `docs/research/`, `docs/plans/` and `docs/verif/` files.
- [x] Every path is inside `Owns` (`evals/`, `bin/po-eval`, `tests/evals.test.sh`, `tests/reuse-ladder-eval.test.sh`).
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`: `git worktree list` shows only main and this worktree.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s114-reuse-ladder-eval`: exit 0. I reused the record: Unit suite `bash tests/run.sh` exited 0 on code equal to the reviewed tree. The project has no type check command (`Typecheck: —`). The record's "Not proven here" section says no real `claude -p` ran; that is carried to Not verified.
- [x] `po-gate qa-current`: not required, because the story does not go to QA (`QA stage: —`, `Surface: —`).

## Plan
- [x] All six tasks are present, and nothing is outside the plan.
- [x] Run interdicts, checked one by one:
  - The diff is empty for `method/`, `.claude/`, `.polype/`, `tests/run.sh`, `evals/lib.sh` and every existing case.
  - `grade()` keeps its top-level shape (extracted by `tests/review-tree-gate.test.sh:63`).
  - Every test puts the fake `claude` first on `PATH`.
  - `grep -n credentials bin/po-eval` finds nothing.
  - No `docs/evals/reuse-ladder.md` was added.

## References
- [x] Every reference was opened and confirmed:
  - the plant copies `get` line for line (`evals/lib.sh:71-75`);
  - `eval_archive_story` and `eval_archive_plan` (`evals/lib.sh:250-294`);
  - `polype install` from `$POLYPE_ROOT` (`evals/lib.sh:149`), so the control copy's `--build` installs the control method into the project as well;
  - the swapped sentence is the only line starting with the prefix (`method/skills/review-antihallu/SKILL.md:38`);
  - `drift_check` and `launch_message` are unchanged.
- [x] I checked the control flow. `run_arm` runs inside `$(…)` and turns `set -e` back on. A build failure exits 2, which ends the main script through the failing assignment, and the `EXIT` trap then removes `$ctl`. The `EXIT` trap does not fire in the `$(…)` subshells; otherwise the control arm would find `$ctl` deleted, and the test shows it does not.

## Rules
- [x] `AGENTS.md` conventions respected: bash tests, one file per story, an acceptance criterion's name equals its test function's name, and the existing test was changed because the story changes the clause it checks (stated in the plan).
- [x] No accepted ADR is contradicted. ADR-0085 keeps the sentence on its own line, and that is what the swap relies on.

## Tests
- [x] Floor: `po-gate floor-guard s114-reuse-ladder-eval main` exited 0, so nothing was lowered.
- [x] The assertions pin down the criteria, and none of the six empty test shapes applies. The fake `claude` counts the sentence in both reachable copies rather than reproducing the condition. The drift check and the real `bin/polype` run for real.
- [x] Within `Test budget`: 3 new tests plus 1 amended, against a budget of 25.
- [x] Bite 1: I replaced the awk swap in `control_setup` by a plain `{print}`, so the copy keeps the s113 sentence. 1 test failed (`eval_has_a_yagni_control_arm`). Undone; `git diff --exit-code bin/po-eval` is clean.
- [x] Bite 2: I dropped `trap 'rm -rf "$ctl"' EXIT`. 1 test failed (`control_arm_never_touches_the_global_install`). Undone; `git diff --exit-code bin/po-eval` is clean.
- [x] No test is made useless by this story.

## Neighbours
- [x] I read the other callers:
  - `tests/evals.test.sh` greps the unchanged lines `<case>: P/R passed` and `N cases × R repetitions = T runs`;
  - `tests/review-tree-gate.test.sh:63` extracts `grade`;
  - `tests/run-ledger.test.sh:172` relies on `--build`.

  All are covered by the reused passing suite.

## Lenses
Lenses run: none. No security, migration, dependency or server-side paths or content are in the diff.

## Findings
- **major** — `bin/po-eval`, `run_arm` (the `claude -p` launch) and `control_setup`: the two arms differ in more than the step-3 sentence. The rule arm runs on the user's real config. On this machine `~/.claude/` holds a global `CLAUDE.md`, `settings.json` and `settings.local.json`, `plugins/`, and other agents and skills. The control arm runs on a fresh config dir that has none of these and logs in from an environment token. Global instructions, settings (including any default model when `--model` is not given), plugins and hooks therefore reach one arm only. The story's comparison ("the same cases with a reviewer whose sentence is replaced") is meant to isolate that sentence, and the result is what decides whether s113's rule is withdrawn. The plan's `## The pivot` names three risks but not this one. A fix would run both arms on a temporary config, each installed from its own payload with the same login, or at least warn when `--model` is missing and say in the output that the arms differ in environment. Nothing is damaged silently, since no rates exist yet, so the ship may go ahead.
- **minor** — `bin/po-eval`, option parser: `--control` combined with `--list` or `--build` is accepted and ignored without a word.

## Not verified
- **Real `claude -p` behaviour.** I did not check whether it starts from an empty `CLAUDE_CONFIG_DIR` with only `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN` (onboarding, trust prompt, settings). That needs a paid call, which the story leaves to the person. When running `bin/po-eval --control --repeat 3`, they should first check that no result reads `claude exit N` and read `<n>.control.err`.
- **Which reviewer copy wins at run time.** I did not check whether the user-level or the project-level copy wins. The tool puts `Follow YAGNI.` in both copies of the control arm, so the result should not depend on it, but only a real run proves what the model loaded.
- **The rates and the verdict expectations.** I did not check whether a real reviewer grades the rebuilt helper `major/yes` under either arm, or whether the existing cases' expectations still hold under s113. Only the paid run measures this.
- **Other s113 text in the control arm.** It stays loaded there, such as the `## Reuse` clause of the plan templates, by the story's own scope (the plan's pivot). A person reading the rates should keep in mind that the control arm drops only the step-3 sentence.

Max severity: major
Ship allowed: yes
