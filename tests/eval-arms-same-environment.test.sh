# s116 — under --control both arms run on the same kind of environment; fake claude, no paid call.

source <(sed '/^test_/,$d' "$ROOT/tests/reuse-ladder-eval.test.sh")

test_both_arms_run_on_a_temporary_config() {
  local before c1 c2
  rl_setup
  before="$(cfg_listing)"
  rl_run y --control --model test-model --repeat 1 rebuilt-helper
  [ "$RL_STATUS" -eq 0 ] || fail "po-eval --control failed: $RL_OUT"
  [ "$(rl_calls)" -eq 2 ] || fail "expected two calls, got $(rl_calls)"
  c1="$(rl_field 1 cfg)"; c2="$(rl_field 2 cfg)"
  case "$c1" in "$RLTMP/tmp"/*) ;; *) fail "the rule arm config is outside TMPDIR: $c1" ;; esac
  case "$c2" in "$RLTMP/tmp"/*) ;; *) fail "the control arm config is outside TMPDIR: $c2" ;; esac
  [ "$c1" != "$c2" ] && [ "$c1" != "$RLTMP/cfg" ] && [ "$c2" != "$RLTMP/cfg" ] || fail "the arms share a config: $c1 $c2"
  [ ! -e "$c1" ] && [ ! -e "$c2" ] || fail "a temporary config survived the run"
  [ "$(rl_field 1 cfg_prefix)" -eq 1 ] && [ "$(rl_field 1 cfg_yagni)" -eq 0 ] \
    || fail "the rule arm config lacks the reuse sentence: $(cat "$RLTMP/calls")"
  [ "$(rl_field 2 cfg_yagni)" -eq 1 ] && [ "$(rl_field 2 cfg_prefix)" -eq 0 ] \
    || fail "the control arm config lacks Follow YAGNI.: $(cat "$RLTMP/calls")"
  [ "$(cfg_listing)" = "$before" ] || fail "the real config dir was modified"
  [ ! -e "$RLTMP/home/.claude" ] || fail "something was written under HOME/.claude"
}

test_control_needs_a_model() {
  rl_setup
  rl_run y --control --repeat 1 rebuilt-helper
  [ "$RL_STATUS" -eq 2 ] && grep -qF -- '--control needs --model' <<< "$RL_OUT" || fail "no refusal (exit $RL_STATUS): $RL_OUT"
  ! grep -qF 'Continue?' <<< "$RL_OUT" || fail "the run asked for confirmation"
  [ "$(rl_calls)" -eq 0 ] || fail "claude was called"

  RL_TOKEN=(ANTHROPIC_API_KEY=sk-fake-s116)
  rl_run n --control --model test-model --repeat 1 rebuilt-helper
  grep -qF 'both arms: model test-model, each on its own temporary CLAUDE_CONFIG_DIR' <<< "$RL_OUT" \
    && grep -qF 'login from ANTHROPIC_API_KEY' <<< "$RL_OUT" || fail "no shared environment line: $RL_OUT"
  ! grep -qF 'sk-fake-s116' <<< "$RL_OUT" || fail "the token value was printed"

  rl_run y --control --model test-model --repeat 1 rebuilt-helper
  grep -qF -- '--model test-model' <<< "$(rl_field 1 args)" \
    && grep -qF -- '--model test-model' <<< "$(rl_field 2 args)" || fail "--model did not reach both arms: $(cat "$RLTMP/calls")"
  RL_TOKEN=(ANTHROPIC_API_KEY=test)
}

test_control_is_refused_with_list_or_build() {
  rl_setup
  rl_run y --control --list
  [ "$RL_STATUS" -eq 2 ] && grep -qF -- '--control cannot be combined' <<< "$RL_OUT" || fail "--list not refused (exit $RL_STATUS): $RL_OUT"
  ! grep -qF 'rebuilt-helper' <<< "$RL_OUT" || fail "the case list was printed"
  rl_run y --control --build rebuilt-helper "$RLTMP/b"
  [ "$RL_STATUS" -eq 2 ] && grep -qF -- '--control cannot be combined' <<< "$RL_OUT" || fail "--build not refused (exit $RL_STATUS): $RL_OUT"
  [ ! -e "$RLTMP/b" ] || fail "--build built despite --control"
  [ "$(rl_calls)" -eq 0 ] || fail "claude was called"
}
