---
validated: yes
---
# Plan — s116-eval-arms-same-environment

Branch `story/s116-eval-arms-same-environment`. Read `docs/research/s116-eval-arms-same-environment.md` first; this plan builds on it without repeating it. Full track: the story carries a `Corrige` line (major and minor of `docs/reviews/s114-reuse-ladder-eval.md`).

## Story
With `--control`, the rule arm and the control arm each run on a temporary `CLAUDE_CONFIG_DIR` installed from their own method, with the same token from the environment and the same model, so their rates differ only by the measured sentence.
- `both_arms_run_on_a_temporary_config` — both arms install into a temporary config from their own method copy, neither reads `~/.claude/`, both dirs are removed at exit.
- `control_needs_a_model` — `--control` without `--model` is refused before any call; the output names the model and the environment shared by both arms.
- `control_is_refused_with_list_or_build` — `--control` with `--list` or `--build` is refused with a message.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Rule-arm config install | Already in this repository: the global install line `bin/po-eval:126`, run with `$POLYPE_ROOT/bin/polype`, which honours `CLAUDE_CONFIG_DIR` (`bin/polype:30`) | — (top rung holds) |
| Removal of both dirs at exit | Already in this repository: the single `trap 'rm -rf "$ctl"' EXIT` (`bin/po-eval:203`), by putting the rule config under `$ctl` | — |
| Two option guards and one announcement line | New code (a few lines of bash) | Nothing in the repository or bash rejects a flag combination for this script; the parser `bin/po-eval:156-166` is the only place that knows the flags |
| Test helpers of the new test file | Already in this repository: the prelude of `tests/reuse-ladder-eval.test.sh:1-54`, sourced with `source <(sed '/^test_/,$d' …)`, the idiom of `tests/review-tree-gate.test.sh:63` | — |

No new option, setting or abstraction beyond what the criteria ask.

## Tasks
1. [x] **Option guards** in `bin/po-eval`, right after the parse loop (after `:166`, before `:168`): with `control=yes` and `list=yes` or `build=yes` → print `po-eval: --control cannot be combined with --list or --build` to stderr, exit 2. With `control=yes` and an empty `model` → print `po-eval: --control needs --model, so both arms run the same model` to stderr, exit 2. Both come before the list/build exits, the drift check and the token check. Update `usage()` (`:28-35`) and the header (`:6`, `:14-17`) to say `--control` needs `--model` and that both arms run on temporary configs. Test that fails if wrong: `control_is_refused_with_list_or_build`, `control_needs_a_model`.
2. [x] **Rule arm on its own temporary config**: in the `--control` block (`:201-205`), after `control_setup "$ctl"`, install the checkout's method into `$ctl/rule-config` with `CLAUDE_CONFIG_DIR="$ctl/rule-config" bash "$POLYPE_ROOT/bin/polype" install --global >/dev/null`. In the main loop (`:219`), pass `"$ctl/rule-config"` as the rule arm's config when `control=yes`, `""` otherwise, so non-control runs keep the inherited config. Test that fails if wrong: `both_arms_run_on_a_temporary_config`.
3. [x] **Announcement** under `--control`, printed right after the two-arm run-count line (`:188`), before `Continue?`: `both arms: model <M>, each on its own temporary CLAUDE_CONFIG_DIR installed from its own method, login from <names>`, where `<names>` lists which of `ANTHROPIC_API_KEY` and `CLAUDE_CODE_OAUTH_TOKEN` are set, joined by ` and `, never their values. Test that fails if wrong: `control_needs_a_model`.
4. [x] **Amend `tests/reuse-ladder-eval.test.sh`** (the story changes the clause it checks): the fake `claude` in `rl_setup` also logs `echo "args=$*"`; every `--control` call (`:74`, `:79`, `:95`, `:106`, `:114`) gets `--model test-model`; `:97` no longer expects the inherited config — the rule arm's `cfg` lies under `$RLTMP/tmp` and is gone after the run. The drift (`:104-109`) and no-token (`:111-117`) refusals stay as they are. Test: the file's three tests pass.
5. [x] **New `tests/eval-arms-same-environment.test.sh`**, sourcing the prelude with `source <(sed '/^test_/,$d' "$ROOT/tests/reuse-ladder-eval.test.sh")`, three tests named after the criteria:
   - `test_both_arms_run_on_a_temporary_config`: `rl_run y --control --model test-model --repeat 1 rebuilt-helper` → exit 0, 2 calls; `rl_field 1 cfg` and `rl_field 2 cfg` both under `$RLTMP/tmp`, distinct, neither equal to `$RLTMP/cfg`, neither existing afterwards; call 1 has `cfg_prefix=1 cfg_yagni=0`, call 2 `cfg_yagni=1 cfg_prefix=0`; `cfg_listing` unchanged; `$RLTMP/home/.claude` absent.
   - `test_control_needs_a_model`: `--control --repeat 1 rebuilt-helper` with no `--model` → exit 2, output holds `--control needs --model`, no `Continue?`, 0 calls. Then, with `RL_TOKEN=(ANTHROPIC_API_KEY=sk-fake-s116)` and `--model test-model`, answer `n` → output holds `both arms: model test-model, each on its own temporary CLAUDE_CONFIG_DIR` and `login from ANTHROPIC_API_KEY`, never `sk-fake-s116`; answer `y` → both calls' `args` hold `--model test-model`.
   - `test_control_is_refused_with_list_or_build`: `--control --list` and `--control --build rebuilt-helper "$RLTMP/b"` → each exit 2 with `--control cannot be combined`, no case name printed, `$RLTMP/b` absent, 0 calls.
6. [x] **Run the checks**: focused `bash tests/run.sh reuse-ladder-eval.test.sh eval-arms-same-environment.test.sh evals.test.sh`, then the full suite once through `po-run --story s116-eval-arms-same-environment --label unit -- 'bash tests/run.sh'`. No type check (`Typecheck: —`).

## Scene viewpoints
—

## Run interdicts
- `git diff main -- method/ .claude/ .polype/ evals/ tests/run.sh tests/lib.sh tests/evals.test.sh tests/review-tree-gate.test.sh tests/run-ledger.test.sh` is empty.
- `drift_check`, `grade`, `launch_message`, `load_case` and the sentence swap of `control_setup` (`bin/po-eval:62-127`) keep their bodies; `drift_check` still reads `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`.
- The non-control path prints the same lines as before: `N cases × R repetitions = T runs` and `<case>: P/R passed`, and its arm gets `""` as config.
- `grep -n credentials bin/po-eval` finds nothing; no token value is ever echoed.
- No real `claude -p` is run; every test puts the fake `claude` first on `PATH`.
- No `docs/evals/` file and no ADR are added.

## The pivot
That a temporary `CLAUDE_CONFIG_DIR` installed by `polype install --global` is the whole environment `claude -p` reads, so two such dirs from methods differing by one line leave the sentence as the only difference. Ways it could be wrong:
- Claude Code may still read something under `$HOME` (`~/.claude.json`, a user `CLAUDE.md`) despite `CLAUDE_CONFIG_DIR`. After the fix both arms share that leak, so it no longer separates them; only a paid run shows it. Compare `<n>.err` and `<n>.control.err` of a real run.
- The rule arm installed from `$POLYPE_ROOT` and the control arm from the `$ctl/polype` copy: the reviewer checks that the copy is taken from the same checkout (`bin/po-eval:117`) and differs only by the swapped line, so the two installs differ by that line too.
- Guard order: a guard placed after `drift_check` or the token check would still be "before any call" but would hide the flag error behind another message; the reviewer checks the guards sit right after the parse loop.

## Files touched
- `bin/po-eval`
- `tests/reuse-ladder-eval.test.sh` (amended)
- `tests/eval-arms-same-environment.test.sh` (new)
- `docs/research/s116-eval-arms-same-environment.md`, `docs/plans/s116-eval-arms-same-environment.md`, `docs/verif/s116-eval-arms-same-environment.md`

## Test strategy
Layer: the script itself, driven end to end against a fake `claude` on `PATH`, the only layer where flags, configs and calls meet. Automated: 3 new tests (one per criterion) plus 2 amended in `tests/reuse-ladder-eval.test.sh` — within `Test budget` 25. Bite targets for the reviewer: reverting task 2's config to `""` must fail `both_arms_run_on_a_temporary_config`; dropping the model guard must fail `control_needs_a_model`; dropping the list/build guard must fail `control_is_refused_with_list_or_build`. Visual checks: none. Not proven here: a real `claude -p` on an empty config dir (onboarding, login), left to the person's paid run.

## Done when
One commit on `story/s116-eval-arms-same-environment` with the code, the two test files and these docs; `bash tests/run.sh` green through `po-run`; a review with no open critical finding; landed on `main` through a pull request.
