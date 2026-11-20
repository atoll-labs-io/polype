#!/usr/bin/env bash
# s07 — ship.

CMD="$METHOD/commands/po-ship.md"

test_ship_gate_is_mechanical() {
  require_file "$CMD"
  local gate_line first_step
  gate_line=$(grep -n 'po-gate ship-allowed <id>' "$CMD" | head -n 1 | cut -d: -f1)
  first_step=$(grep -n '^## Step 1' "$CMD" | cut -d: -f1)
  [ -n "$gate_line" ] && [ -n "$first_step" ] && [ "$gate_line" -lt "$first_step" ] \
    || fail "the ship-allowed gate must come before any other step"
}

test_ship_cleans_up_only_on_proven_merge() {
  contains "$CMD" 'Cleanup, only after proof'
}

test_ship_can_ask_before_merging() {
  needs_tool "$CMD" AskUserQuestion
}

test_ship_runs_expensive_checks_once() {
  contains "$CMD" '**One failure and the ship stops**'
}

# s47 — the verdict is bound to the tree it judged.

test_rules_and_ship_describe_the_bound_verdict() {
  local row
  row=$(grep -F '| Ship allowed |' "$METHOD/AGENTS.md")
  grep -qF 'Reviewed tree:' <<< "$row" || fail "the Law 3 Ship allowed row does not mention 'Reviewed tree:'"
}
