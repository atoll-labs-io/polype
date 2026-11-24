# s209 — git, alone, runs outside a real run's sandbox; what Claude Code adds to git's global ignore
# no longer invalidates a run, and an invalid run keeps the governing file that changed. No test here
# pays: one build, and launches that meet a claude double of this file, first on PATH.

source <(sed '/^test_/,$d' "$ROOT/tests/real-run-is-usable.oracle.test.sh")

# The double plays one session in the run's environment, as $FAKE_GOVERN says:
# `ignore` — what Claude Code may do at start: an entry appended to git's global ignore, and the paths
#            the sandbox mounts at a repository root; it writes what git status shows to $FAKE_CALLS.status.
# `widen`  — a session that widens the next one in settings.json, its login written in it.
govern_double() {
  cat > "$RTMP/bin/claude" <<'SH'
#!/usr/bin/env bash
case "${FAKE_GOVERN:-}" in
  ignore)
    printf '%s\n' '**/.claude/settings.local.json' >> "${XDG_CONFIG_HOME:-$HOME/.config}/git/ignore"
    : > .zshrc; : > .profile; mkdir -p .idea; : > .idea/workspace.xml
    git status --porcelain > "$FAKE_CALLS.status" 2>&1 ;;
  widen)
    s="$CLAUDE_CONFIG_DIR/settings.json"
    jq --arg k "${ANTHROPIC_API_KEY:-}" '.permissions.allow += ["Bash(curl:*)"] | .env.LEAKED = $k' "$s" > "$s.new" && mv "$s.new" "$s" ;;
esac
{ printf 'cfg=%s\n' "$CLAUDE_CONFIG_DIR"; echo ---; } >> "$FAKE_CALLS"
echo '{"type":"result","subtype":"success","is_error":false,"total_cost_usd":0.01}'
SH
  chmod +x "$RTMP/bin/claude"
}

test_git_runs_outside_the_sandbox() {
  local s
  real_setup
  usable_build "$RTMP/git"
  s="$J/config/settings.json"
  jq -e '.sandbox.enabled == true and .sandbox.autoAllowBashIfSandboxed == true and .sandbox.failIfUnavailable == true' "$s" > /dev/null \
    || fail "the sandbox is no longer on, auto-allowed and required: $(jq -c '.sandbox' "$s")"
  jq -e '.sandbox.excludedCommands == ["git"]' "$s" > /dev/null \
    || fail "git, and git alone, is not excluded from the sandbox: $(jq -c '.sandbox.excludedCommands' "$s")"
  jq -e '(.sandbox | keys) == ["autoAllowBashIfSandboxed", "enabled", "excludedCommands", "failIfUnavailable", "filesystem"]' "$s" > /dev/null \
    || fail "the sandbox carries another key than git's exclusion: $(jq -c '.sandbox | keys' "$s")"
  jq -e '[.permissions.allow[]? | select(startswith("Bash"))] == ["Bash(git *)"]' "$s" > /dev/null \
    || fail "git is not allowed by Bash(git *) alone: $(jq -c '.permissions.allow' "$s")"
  # The four of ADR-0137, then the four that refuse git's command-line config, first or after another
  # argument (ADR-0138), nothing else.
  jq -e '.permissions.deny == ["WebFetch", "WebSearch", "Bash(curl:*)", "Bash(claude:*)",
      "Bash(git -c *)", "Bash(git * -c *)", "Bash(git --config-env*)", "Bash(git * --config-env*)"]' "$s" > /dev/null \
    || fail "the deny list is not ADR-0137's four and git's four command-line config refusals: $(jq -c '.permissions.deny' "$s")"
}

test_mask_list_is_not_governing() {
  local results kept
  real_setup
  govern_double

  FAKE_GOVERN=ignore real_run y --repeat 1 --sessions 1 journey
  [ "$RR_STATUS" -eq 0 ] || fail "the run failed (exit $RR_STATUS): $RR_OUT"
  [ -f "$RTMP/calls.status" ] || fail "the double did not play its session: $RR_OUT"
  ! grep -q 'invalid' <<< "$RR_OUT" || fail "an entry added to git's global ignore invalidated the run: $RR_OUT"
  grep -qE '^case journey run 1: (pass|fail)$' <<< "$RR_OUT" || fail "the run was not graded: $RR_OUT"
  ! grep -qE '\.zshrc|\.profile|\.idea' "$RTMP/calls.status" \
    || fail "the sandbox's masks show in git status once the ignore grew: $(cat "$RTMP/calls.status")"

  real_setup
  govern_double
  FAKE_GOVERN=widen real_run y --repeat 1 --sessions 1 --keep journey
  [ "$RR_STATUS" -eq 0 ] || fail "the run failed (exit $RR_STATUS): $RR_OUT"
  grep -qxF 'case journey run 1: invalid — session 1 changed what a session runs under (config/settings.json)' <<< "$RR_OUT" \
    || fail "a widened settings.json did not invalidate the run, naming it: $RR_OUT"
  results="$(sed -n 's/^results: //p' <<< "$RR_OUT" | head -n 1)"
  kept="$results/journey.1.changed"
  [ -f "$kept/before" ] && [ -f "$kept/after" ] \
    || fail "the invalid run did not keep the changed file before and after: $(find "$results" -type f | sort | tr '\n' ' ')"
  jq -e '.sandbox.enabled == true and ((.permissions.allow | index("Bash(curl:*)")) == null)' "$kept/before" > /dev/null \
    || fail "the kept before is not the settings the run was built with: $(cat "$kept/before")"
  grep -qF 'Bash(curl:*)' "$kept/after" || fail "the kept after is not the widened settings: $(cat "$kept/after")"
  grep -qF '[redacted]' "$kept/after" && ! grep -qF "$SENTINEL" "$kept/before" "$kept/after" \
    || fail "the kept files are not scrubbed as po-intake scrubs: $(cat "$kept/after")"
}
