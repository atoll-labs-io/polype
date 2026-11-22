#!/usr/bin/env bash
# s27 — the fleet driver.

DRIVE="$METHOD/commands/po-drive.md"
TEMPLATE="$METHOD/templates/agents-local.md"

test_drive_never_writes_code_or_verdicts() {
  require_file "$DRIVE"
  lacks_tool "$DRIVE" Write
  lacks_tool "$DRIVE" Edit
  needs_tool "$DRIVE" Agent
  needs_tool "$DRIVE" Bash
}

test_settings_template_declares_fleet_settings() {
  require_file "$TEMPLATE"
  local name
  for name in Parallel 'Max attempts' Tracker; do
    template_settings | grep -qx "$name" || fail "missing from the settings template: $name"
  done

  # The defaults the story fixes.
  local fence; fence=$(awk '/^```/ {fence=!fence; next} fence' "$TEMPLATE")
  grep -qE '^Parallel:[[:space:]]+3$' <<< "$fence" || fail "Parallel must default to 3"
  grep -qE '^Max attempts:[[:space:]]+2$' <<< "$fence" || fail "Max attempts must default to 2"
  grep -qE '^Tracker:[[:space:]]+none$' <<< "$fence" || fail "Tracker must default to none"
}
