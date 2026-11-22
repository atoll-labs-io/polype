#!/usr/bin/env bash
# s21 — design handoff to plan, execute and setup.

EXECUTE="$METHOD/commands/po-execute.md"

test_execute_mentions_the_design_when_present() {
  local tool
  for tool in Bash Write Edit; do lacks_tool "$EXECUTE" "$tool"; done
  [ "$(tools_of "$EXECUTE" | sort | tr '\n' ' ')" = "Agent Bash(\"\${CLAUDE_CONFIG_DIR:-\$HOME/.claude}/polype/po\" next) Glob Grep Read " ] \
    || fail "po-execute tools changed: $(tools_of "$EXECUTE" | tr '\n' ' ')"
}
