#!/usr/bin/env bash
# s07 — ship.

CMD="$METHOD/commands/po-ship.md"

test_ship_gate_is_mechanical() {
  require_file "$CMD" || return 1
  local gate_line first_step
  gate_line=$(grep -n 'po-gate ship-allowed <id>' "$CMD" | head -1 | cut -d: -f1)
  first_step=$(grep -n '^## 1\.' "$CMD" | cut -d: -f1)
  [ -n "$gate_line" ] && [ -n "$first_step" ] && [ "$gate_line" -lt "$first_step" ] \
    || fail "the ship-allowed gate must come before any other step"
}

test_ship_always_squashes() {
  contains "$CMD" 'always a squash' && contains "$CMD" 'git merge --squash story/<id>' && contains "$CMD" '--squash'
}

test_ship_cleans_up_only_on_proven_merge() {
  contains "$CMD" 'only on a proven merge' \
    && contains "$CMD" 'must print exactly `MERGED`' \
    && contains "$CMD" 'never `--force`' \
    && contains "$CMD" 'Never test the story branch'"'"'s own commits for ancestry'
}

test_ship_can_ask_before_merging() {
  has_tool "$CMD" AskUserQuestion || fail "po-ship asks for confirmation, so it needs AskUserQuestion"
}

test_ship_runs_expensive_checks_once() {
  contains "$CMD" "cycle's only end-to-end run" && contains "$CMD" 'Any red → stop'
}
