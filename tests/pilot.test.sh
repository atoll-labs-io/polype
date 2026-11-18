#!/usr/bin/env bash
# s08 — status, help, ADR template.

STATUS="$METHOD/commands/po-status.md"
HELP="$METHOD/commands/po-help.md"

test_status_derives_from_files() {
  require_file "$STATUS"
  lacks_tool "$STATUS" Write
  lacks_tool "$STATUS" Edit
  contains "$STATUS" 'no commit, checkout, merge or file change'
}

test_help_is_user_invoked_only() {
  require_file "$HELP"
  frontmatter "$HELP" | grep -qx 'disable-model-invocation: true' || fail "po-help must not be model-invoked"
}

test_every_command_listed_in_help() {
  local f name missing=""
  for f in "$METHOD"/commands/po-*.md; do
    name=$(basename "$f" .md)
    [ "$name" = po-help ] && continue
    grep -qF "/$name" "$HELP" || missing+="$name "
  done
  [ -z "$missing" ] || fail "missing from po-help: $missing"
}

test_adr_template_records_rejected_options() {
  local t="$METHOD/templates/adr.md"
  require_file "$t"
  contains "$t" '## Considered Options'
  contains "$t" 'superseded-by'
}
