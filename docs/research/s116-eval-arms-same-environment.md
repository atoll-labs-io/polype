# Research — s116-eval-arms-same-environment

[Story](../stories.md)

## Structuring facts
- Root cause (major): under `--control` the rule arm is launched with an empty config argument (`bin/po-eval:219`), so `run_arm` exports no `CLAUDE_CONFIG_DIR` (`bin/po-eval:140`) and `claude -p` reads the user's real `~/.claude/` (global `CLAUDE.md`, settings, plugins, hooks), while the control arm reads a fresh `$ctl/config` (`bin/po-eval:223`, `:126`). Proof: `tests/reuse-ladder-eval.test.sh:97` asserts the rule arm's `CLAUDE_CONFIG_DIR` equals the inherited one, and it passes today.
- Root cause (major, model half): `--model` is optional (`bin/po-eval:159`, `:209-210`); without it the rule arm takes the default model of the user's `settings.json` and the control arm, on an empty config, Claude Code's default.
- Root cause (minor): the parser records `--control` (`bin/po-eval:161`), but `--list` and `--build` exit at `:168` and `:170-175` before it is read. Reproduced: `bash bin/po-eval --list --control` printed the case list, exit 0; `bash bin/po-eval --control --build rebuilt-helper <dir>` built, exit 0.
- No story assumption turned out false. `drift_check` (`bin/po-eval:62-84`) stays: the story's notes keep it comparing the real install to `method/`.
- No ADR is needed: the fix is the one the s114 review proposed and the story settles it; ADR-0085 is untouched.

## Story
With `--control`, both arms run `claude -p` on a temporary `CLAUDE_CONFIG_DIR` each, installed by `polype install --global` from its own method, both removed at exit, neither reading `~/.claude/`. `--control` without `--model` is refused before any call, and the output names the model and environment shared by both arms. `--control` with `--list` or `--build` is refused with a message. The token stays read from the environment, never copied from `.credentials.json`.

Criteria: `both_arms_run_on_a_temporary_config`, `control_needs_a_model`, `control_is_refused_with_list_or_build`.

## Diagnostic
Reproduction (no file created in the worktree; the probe build went to `/tmp`, removed after):
- `bash tests/run.sh reuse-ladder-eval.test.sh` → 3 passed, including `control_arm_never_touches_the_global_install`, whose line 97 pins the rule arm on the inherited config.
- `bash bin/po-eval --list --control` → case list, exit 0. `--control --build rebuilt-helper /tmp/...` → exit 0.

Hypotheses:
1. The rule arm runs on the inherited config. Refutation would be `run_arm` receiving a config dir for the rule arm. Read `bin/po-eval:219`: it passes `""`; `:140` exports nothing then. **Kept.**
2. The built repository's project `.claude/` differs between arms beyond the sentence. Refutation: each arm builds through its own `po-eval --build` (`bin/po-eval:136`), which runs `polype install "$repo"` from that arm's root (`evals/lib.sh:149`); the control root differs only by the swapped line (`bin/po-eval:117-125`). **Discarded**: the project layer differs by the measured sentence only.
3. The model differs between arms. Refutation would be `--model` being required or a model forced. `bin/po-eval:210` leaves `model_args` empty when `--model` is absent, and the two configs hold different `settings.json` (real vs none). **Kept** as the second half of the cause.

## Current code
- `bin/po-eval` (235 lines): header usage `:6-17`, `usage()` `:28-35`, `drift_check` `:62-84` (reads `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`), `grade` `:103-111`, `control_setup <dir>` `:114-127` (copies `bin method evals` into `<dir>/polype`, swaps the sentence, installs into `<dir>/config`), `run_arm <po-eval> <config|""> <out>` `:130-146`, option loop `:154-166`, list/build exits `:168-175`, token refusal for `--control` `:181-184`, run-count line and confirmation `:186-199`, `ctl=$(mktemp -d)` + `trap 'rm -rf "$ctl"' EXIT` + `control_setup` `:201-205` (after confirmation), main loop `:212-233`.
- `tests/reuse-ladder-eval.test.sh`: top-level prelude `:1-54` (`RLTMP`, `PREFIX`, `RL_TOKEN`, `rl_setup` with a fake `claude` that logs `cfg`, `cfg_yagni`, `cfg_prefix`, `proj_yagni`, `proj_prefix` per call, `rl_run`, `rl_calls`, `rl_field`, `cfg_listing`), then three tests `:56-118`. Every `--control` run there omits `--model` (`:74`, `:79`, `:95`, `:106`, `:114`).

## Attachment points
- Option checks: right after the parse loop (`bin/po-eval:166`), before `:168`, so refusals happen before list, build, drift check or any call.
- Environment announcement: next to the two-arm run-count line (`bin/po-eval:188`), before the confirmation, so a declined run shows it too.
- Config setup: `:201-205` and `control_setup` `:114-127`; the install line `:126` is the one to reuse for the rule arm with `$POLYPE_ROOT/bin/polype`.
- Rule-arm launch: `:219` passes `""` today.

## Verified interfaces
- `bin/polype` honours `CLAUDE_CONFIG_DIR` for `--global` (`bin/polype:30`, `home="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"`) and puts the payload under `<home>/polype` (`bin/polype:8-10`).
- `run_arm` exports `CLAUDE_CONFIG_DIR` only when its second argument is non-empty (`bin/po-eval:140`); non-control runs pass `""` and must keep doing so.
- `tests/run.sh:11-17` sources `lib.sh` and one test file per shell; `ROOT` comes from `tests/lib.sh:5`. A new test file sees nothing of another file unless it sources it.
- Precedent for reusing part of another script in a test: `source <(sed -n '/^grade() {/,/^}/p' "$ROOT/bin/po-eval")` (`tests/review-tree-gate.test.sh:63`).
- `sed '/^test_/,$d' tests/reuse-ladder-eval.test.sh` yields exactly the prelude (checked: it ends with `cfg_listing`).

## Traps
- `tests/reuse-ladder-eval.test.sh:97` checks the clause this story removes; it must change (the rule arm now on a temporary config). Every `--control` call in that file needs `--model`, or the new refusal ends them before the drift and token checks they target (`:106`, `:114`).
- `tests/evals.test.sh:28-31` runs po-eval without `--control` and greps `N cases × R repetitions = T runs`; the non-control path must not change. `tests/review-tree-gate.test.sh:63` extracts `grade()`: keep its shape. `tests/run-ledger.test.sh:172` relies on `--build` alone.
- `--build` is parsed only as the first remaining three arguments (`bin/po-eval:162`): `--build c d --control` already fails as usage; `--control --build c d` is the order that slips through today.
- The `EXIT` trap does not fire in `$(…)` subshells (s114 review); both config dirs must live where that single trap removes them.
- The fake `claude` does not record its arguments today, so no test can see `--model` reach both arms without a change to `rl_setup`.
- No migration, no dependency, no screen.

## Open questions
- Does a real `claude -p` with `CLAUDE_CONFIG_DIR` set still read anything under `$HOME/.claude/` or `$HOME/.claude.json` (user `CLAUDE.md`, onboarding state)? Not checkable without a paid call; same for both arms after the fix, so it no longer separates them.
- When both `ANTHROPIC_API_KEY` and `CLAUDE_CODE_OAUTH_TOKEN` are set, which one does Claude Code use? Both arms inherit the same environment, so the announcement names the variables that are set rather than guessing.

## Complexity
Story 2 → 2. One script, one option guard, one extra install, one test amended and one test file added.

## Split
—
