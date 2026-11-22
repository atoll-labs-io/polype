#!/usr/bin/env bash
# s122 — the docs and the eval say what Polype does.

source <(sed '/^test_/,$d' "$ROOT/tests/reuse-ladder-eval.test.sh")

test_drift_message_fits_the_mode() {
  rl_setup
  echo "# drift" >> "$RLTMP/cfg/agents/reviewer.md"
  rl_run y --control --model test-model --repeat 1 rebuilt-helper
  [ "$RL_STATUS" -eq 2 ] || fail "a --control drift run exited $RL_STATUS: $RL_OUT"
  grep -qF 'guards that install' <<< "$RL_OUT" || fail "the --control drift message does not say what it guards: $RL_OUT"
  ! grep -qF 'would shadow the method under test' <<< "$RL_OUT" || fail "the --control drift message claims a shadowing"
  rl_run y --repeat 1 rebuilt-helper
  [ "$RL_STATUS" -eq 2 ] || fail "a drift run exited $RL_STATUS: $RL_OUT"
  grep -qF 'would shadow the method under test' <<< "$RL_OUT" || fail "the plain drift message changed: $RL_OUT"
  ! grep -qF 'guards that install' <<< "$RL_OUT" || fail "the plain drift message took the --control wording"
  [ "$(rl_calls)" -eq 0 ] || fail "claude was called despite drift"
}
