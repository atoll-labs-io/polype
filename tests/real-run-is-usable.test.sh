# s207 — task test: tokens come from the last result of a session, not summed over events.

source <(sed '/^test_/,$d' "$ROOT/tests/real-run-is-usable.oracle.test.sh")

test_tokens_come_from_the_last_result() {
  local res="$RTMP/results" line
  mkdir -p "$res"
  POLYPE_ROOT="$ROOT" source "$ROOT/evals/real/lib.sh"
  first_run_stream > "$res/journey.1.session1.jsonl"
  line="$(real_spent "$res")"
  grep -qF 'tokens in 74, out 20685' <<< "$line" || fail "tokens are not the session's cumulative ones: $line"

  rm -f "$res"/*
  printf '%s\n' \
    '{"type":"result","total_cost_usd":0.01,"usage":{"input_tokens":3,"output_tokens":4}}' \
    '{"type":"result","total_cost_usd":0.02,"usage":{"input_tokens":30,"output_tokens":40}}' > "$res/case.1.session1.jsonl"
  line="$(real_spent "$res")"
  grep -qF 'cost: 0.02 USD over 1 sessions; tokens in 30, out 40' <<< "$line" || fail "the last usage is not taken: $line"
}
