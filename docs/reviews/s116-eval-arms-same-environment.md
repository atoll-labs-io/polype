# Review — s116-eval-arms-same-environment

[Story](../stories.md) · [Plan](../plans/s116-eval-arms-same-environment.md) · [Verification](../verif/s116-eval-arms-same-environment.md)

Review status: complete
Fix loop: 0
Reviewed tree: b5a9cedc733020f8edb43bc0d186d98f689599d7
Lenses run: none (the diff touches only `bin/po-eval` and bash tests. No auth, migration, lockfile or server-side path, and none of the trigger content.)

I reviewed `git diff main...story/s116-eval-arms-same-environment` (one commit, d67d143) in a context that did not write it. I took the tree before reading and again before answering. It was the same both times, and the worktree is clean.

## Scope (Owns)
The story's `Owns` line is `bin/po-eval`, `tests/reuse-ladder-eval.test.sh`, `tests/eval-arms-same-environment.test.sh`. Every path in the diff is either on that line or is the story's own pipeline evidence (`docs/research/`, `docs/plans/`, `docs/verif/` for s116). Nothing falls outside `Owns`. No ADR was added.

## Evidence relied on
- **Verification record:** `po-gate verif-current s116-eval-arms-same-environment` exits 0. With `Verification mode: record`, the record shows `Verification status: complete` and one Unit suite row (`bash tests/run.sh`) that exited 0 on matching code. I did not rerun the full suite.
- **Type check:** the project has none (`Typecheck: —`).
- **QA:** `QA stage: —` and `Surface: —`, so there is no QA stage and no design to check.
- **Floor guard:** `po-gate floor-guard s116-eval-arms-same-environment main` exits 0, so nothing was lowered.
- **Focused run:** I ran `bash tests/run.sh reuse-ladder-eval.test.sh eval-arms-same-environment.test.sh evals.test.sh` as a baseline for the bite proofs: 14 passed.

## Plan conformity
- **Task 1, option guards:** done. The guards sit right after the parse loop (`bin/po-eval:170-177`), ahead of `--list`/`--build`, `drift_check` and the token check, which is the order the plan's pivot asks for. Usage and header are updated.
- **Task 2, rule arm config:** done. `$ctl/rule-config` is installed from `$POLYPE_ROOT` (`:220`), passed to `run_arm` (`:225-226`, `:237`), and removed by the existing `trap 'rm -rf "$ctl"'`. Non-control runs still pass `""`.
- **Task 3, announcement line:** done (`:200-203`). It prints variable names only, never their values. `${logins[0]}` is safe under `set -u` because the token check above guarantees at least one entry.
- **Task 4, amended old tests:** done, as declared. Every `--control` call gets `--model test-model`, and the inherited-config expectation is replaced by "under TMPDIR and gone".
- **Task 5, new test file:** done. Three tests named after the criteria, reusing the prelude through `source <(sed '/^test_/,$d' …)`.
- **`## Reuse` table:** matches the diff. The install line and the trap are reused, and only the guards are new code.
- **Run interdicts:** all hold.
  - The diff of `method/ .claude/ .polype/ evals/ tests/run.sh tests/lib.sh tests/evals.test.sh` against `main` is empty.
  - `drift_check`, `grade`, `launch_message`, `load_case` and `control_setup` are unchanged.
  - `grep credentials bin/po-eval` finds nothing.
  - The non-control output lines are unchanged.
- **References checked:** `bin/polype` honours `CLAUDE_CONFIG_DIR` (`bin/polype:30`). `run_arm` exports the config it is given (`:142`). `model_args` reaches both arms.
- **The two installs differ by one line only.** I ran a probe under the temp dir: a `polype install --global` from the checkout and one from a `bin/method/evals` copy with the sentence swapped. A recursive diff of the two installs shows only that line of `review-antihallu/SKILL.md`, its payload copy and their checksums. Nothing was written under `$HOME`. This confirms the second risk the plan's pivot names. The probe dir is removed.

## Bite proofs
Each mutation was undone with `git checkout -- bin/po-eval`, and `git diff --exit-code bin/po-eval` confirmed the file was back to its committed state before I went on.

| Rule disabled | Tests run | Failed |
| --- | --- | --- |
| Rule arm config forced back to `""` (`:226` → `true`) | reuse-ladder-eval, eval-arms-same-environment | 2 (`both_arms_run_on_a_temporary_config`, `control_arm_never_touches_the_global_install`) |
| `--control` without `--model` guard (`:174` → `if false`) | eval-arms-same-environment | 1 (`control_needs_a_model`) |
| `--control` + `--list`/`--build` guard (`:170` → `if false`) | eval-arms-same-environment | 1 (`control_is_refused_with_list_or_build`) |

Every rule the story depends on is bitten by at least one test. The story has 3 new and 2 amended tests, within `Test budget` 25. I found none of the six kinds of test that prove nothing. The fake `claude` reports what it really sees (`CLAUDE_CONFIG_DIR`, the skill copies it can reach, `args`), and no mock reproduces the condition under test.

## Neighbours
Nothing else in the repository calls `bin/po-eval --control`. The only other mention is a past record line in `docs/verif/s114-reuse-ladder-eval.md:14` (`bin/po-eval --control --repeat 3`), which is not executed.

## Findings
- **minor** — `bin/po-eval:190`, `drift_check` under `--control`. Both arms now run on temporary configs, yet the real `${CLAUDE_CONFIG_DIR:-~/.claude}` is still checked. On drift, the run is refused with "a user-level copy would shadow the method under test", which is no longer true for a control run: neither arm reads that config. Keeping the check is what the story's agent note asks for, so this is about the wording only. A later story could skip the check under `--control`, or say in the message that it guards the non-control path.

## Not verified
- **A real `claude -p` on an empty `CLAUDE_CONFIG_DIR`.** I did not check whether it starts with only a token from the environment (onboarding, trust prompt, settings), or whether it still reads something under `$HOME` (`~/.claude.json`, a user `CLAUDE.md`). That needs a paid call, which the plan and the record leave to the person. Both arms now share any such leak, so it no longer separates them, but it could make both fail. When running `bin/po-eval --control --model <M> --repeat 3`, the person should first check that no result reads `claude exit N`, and compare `<n>.err` with `<n>.control.err`.
- **Which reviewer copy wins at run time.** I did not check whether the user-level copy or the project-level copy wins. Both arms carry the same sentence in both copies, so the result should not depend on it, but only a real run shows what the model loaded.
- **The `CLAUDE_CODE_OAUTH_TOKEN`-only and both-tokens branches of the announcement line.** I checked them by reading the code; no test runs them.

Max severity: minor
Ship allowed: yes
