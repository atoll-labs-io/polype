#!/usr/bin/env bash
# s08 — status, help.

STATUS="$METHOD/commands/po-status.md"
HELP="$METHOD/commands/po-help.md"

test_status_derives_from_files() {
  require_file "$STATUS"
  lacks_tool "$STATUS" Write
  lacks_tool "$STATUS" Edit
}

test_help_is_user_invoked_only() {
  require_file "$HELP"
  frontmatter "$HELP" | grep -qx 'disable-model-invocation: true' || fail "po-help must not be model-invoked"
}
