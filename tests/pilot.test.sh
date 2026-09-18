#!/usr/bin/env bash
# s08 — orchestrator, status, help, ADR template.

ORCH="$METHOD/commands/po-orchestrator.md"
STATUS="$METHOD/commands/po-status.md"
HELP="$METHOD/commands/po-help.md"

test_orchestrator_has_two_real_checkpoints() {
  require_file "$ORCH" || return 1
  has_tool "$ORCH" AskUserQuestion || fail "orchestrator needs AskUserQuestion" || return 1
  local checkpoints; checkpoints=$(grep -c '^## .*— checkpoint$' "$ORCH")
  [ "$checkpoints" -eq 2 ] || fail "expected 2 checkpoint stages, found $checkpoints" || return 1
  contains "$ORCH" 'A checkpoint is a real AskUserQuestion call'
}

test_orchestrator_never_codes() {
  { ! has_tool "$ORCH" Edit || fail "orchestrator must not have Edit"; } \
    && contains "$ORCH" 'exactly as `/po-execute` does' \
    && contains "$ORCH" 'exactly as `/po-review` does'
}

test_status_derives_from_files() {
  require_file "$STATUS" || return 1
  { ! has_tool "$STATUS" Write || fail "status must not write"; } \
    && { ! has_tool "$STATUS" Edit || fail "status must not edit"; } \
    && contains "$STATUS" 'never modify, commit, check out or fetch'
}

test_help_is_user_invoked_only() {
  require_file "$HELP" || return 1
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
  require_file "$t" && contains "$t" '## Considered Options' && contains "$t" 'superseded-by'
}
