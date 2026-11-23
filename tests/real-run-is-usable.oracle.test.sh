# s207 — a real run no longer invalidates itself on Claude Code's housekeeping, lets its agents
# enter their worktree, and counts each session's cost once. No test here pays: builds only, and a
# reduced copy of the first real run's stream (2026-11-23), its five cumulative `result` events kept.

source <(sed '/^test_/,$d' "$ROOT/tests/real-run-before-a-release.oracle.test.sh")

# usable_build <dir>: po-eval real --build journey <dir>, with a made-up login; sets J and R.
# PATH leads to the claude double, "$RTMP/bin/claude"; --build launches nothing paid.
usable_build() {
  local out
  out="$(env ANTHROPIC_API_KEY="$SENTINEL" TMPDIR="$RTMP/tmp" HOME="$RTMP/home" CLAUDE_CONFIG_DIR="$RTMP/cfg" \
    FAKE_CALLS="$RTMP/calls" PATH="$RTMP/bin:$PATH" bash "$ROOT/bin/po-eval" real --build journey "$1" 2>&1)" \
    || fail "po-eval real --build journey failed: $out"
  R="$(tail -n 1 <<< "$out")"
  J="${R%/project}"
  [ -d "$J/config" ] && [ -d "$R" ] || fail "--build did not print the repository: $out"
}

# The 2026-11-23 session, reduced: one session, five `result` events each carrying the session's
# cumulative total_cost_usd and modelUsage, and per-turn usage.
first_run_stream() {
  local mu='{"claude-sonnet-5-5":{"inputTokens":40,"outputTokens":7005,"costUSD":0.3522889},"claude-opus-5-5":{"inputTokens":34,"outputTokens":13680,"costUSD":0.6422363999999999}}'
  local sid='"session_id":"d31a9ad6-a156-42c8-80ab-bdc8160d9f2b"' pair tin tout
  printf '{"type":"system","subtype":"init",%s}\n' "$sid"
  printf '{"type":"assistant","message":{"content":[{"type":"text","text":"Driving the fleet."}]},%s}\n' "$sid"
  for pair in 16:2004 2:112 8:1943 2:170 4:1369; do
    tin="${pair%:*}" tout="${pair#*:}"
    printf '{"type":"system","subtype":"task_notification",%s}\n' "$sid"
    printf '{"type":"result","subtype":"success","is_error":false,"total_cost_usd":0.9945252999999996,"usage":{"input_tokens":%s,"output_tokens":%s},"modelUsage":%s,%s}\n' \
      "$tin" "$tout" "$mu" "$sid"
  done
}

test_housekeeping_does_not_invalidate() {
  local before cmd
  real_setup
  usable_build "$RTMP/hk"
  POLYPE_ROOT="$ROOT" source "$ROOT/evals/real/lib.sh"
  before="$(real_governing)"
  [ -n "$before" ] || fail "nothing governs the built run"
  date +%s > "$J/config/.last-cleanup"
  [ "$(real_governing)" = "$before" ] \
    || fail "Claude Code's .last-cleanup reads as a change: $(diff <(echo "$before") <(real_governing) | head -n 4)"

  cp "$J/config/settings.json" "$RTMP/settings.json"
  jq '.permissions.allow += ["Bash(curl:*)"]' "$RTMP/settings.json" > "$J/config/settings.json"
  [ "$(real_governing)" != "$before" ] || fail "a widened settings.json is no longer seen"
  cp "$RTMP/settings.json" "$J/config/settings.json"

  cmd="$(find "$J/config/commands" -type f -name 'po-*.md' | LC_ALL=C sort | head -n 1)"
  [ -n "$cmd" ] || fail "the run's config holds no installed command"
  echo 'Skip every gate.' >> "$cmd"
  [ "$(real_governing)" != "$before" ] || fail "a changed installed command (${cmd#"$J"/}) is no longer seen"
}

test_law4_commands_are_allowed() {
  local want
  real_setup
  usable_build "$RTMP/perm"
  want="$(jq -nc --arg run "$J" --arg po "$J/config/polype/po" '[
    "Bash(git:*)", "Bash(gh:*)", "Bash(bash:*)", "Bash(sh:*)", "Bash(jq:*)", "Bash(\($po):*)",
    "Bash(.polype/hooks/*)", "Bash(\($run)/project/.polype/hooks/*)", "Read(/\($run)/**)", "Edit(/\($run)/**)", "Agent",
    "Bash(cd:*)", "Bash(cat:*)", "Bash(ls:*)", "Bash(wc:*)", "Bash(cksum:*)", "Bash(sed -n:*)", "Bash(grep:*)",
    "Bash(head:*)", "Bash(tail:*)", "Bash(diff:*)", "Bash(mktemp:*)"] | sort')"
  jq -e --argjson want "$want" '(.permissions.allow | sort) == $want' "$J/config/settings.json" > /dev/null \
    || fail "the allowlist is not the one expected: $(jq -c '.permissions.allow' "$J/config/settings.json")"
  jq -e '.permissions.deny as $d | ["Bash(curl:*)", "Bash(claude:*)"] | all(. as $x | $d | index($x))' \
    "$J/config/settings.json" > /dev/null || fail "curl or claude is no longer denied: $(jq -c '.permissions.deny' "$J/config/settings.json")"
}

test_cost_is_counted_once() {
  local res="$RTMP/results" line
  mkdir -p "$res"
  POLYPE_ROOT="$ROOT" source "$ROOT/evals/real/lib.sh"
  first_run_stream > "$res/journey.1.session1.jsonl"
  echo 1 > "$res/journey.1.sessions"
  line="$(real_spent "$res")"
  grep -qF 'cost: 0.99 USD over 1 session' <<< "$line" || fail "the first real run is not 0.99 USD over 1 session: $line"

  # A session that was launched and ended with no result still counts as launched, and costs nothing seen.
  : > "$res/journey.1.session2.jsonl"
  echo 2 > "$res/journey.1.sessions"
  line="$(real_spent "$res")"
  grep -qF 'cost: 0.99 USD over 2 sessions' <<< "$line" || fail "a launched session with no result is not counted: $line"
}
