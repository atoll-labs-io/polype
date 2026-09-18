#!/usr/bin/env bash
# s08 — orchestrator, status, help, ADR template.

ORCH="$METHOD/commands/po-orchestrator.md"
STATUS="$METHOD/commands/po-status.md"
HELP="$METHOD/commands/po-help.md"

test_orchestrator_has_two_real_checkpoints() {
  require_file "$ORCH"
  needs_tool "$ORCH" AskUserQuestion
  local checkpoints; checkpoints=$(grep -c '^## Stage .* — checkpoint$' "$ORCH" || true)
  [ "$checkpoints" -eq 2 ] || fail "expected 2 checkpoint stages, found $checkpoints"
  contains "$ORCH" 'a question in your text output is not a checkpoint'
}

test_orchestrator_never_codes() {
  lacks_tool "$ORCH" Edit
  contains "$ORCH" 'Delegate to `implementer` the way `/po-execute` does'
  contains "$ORCH" 'Delegate to `reviewer` the way `/po-review` does'
}

test_status_derives_from_files() {
  require_file "$STATUS"
  lacks_tool "$STATUS" Write
  lacks_tool "$STATUS" Edit
  contains "$STATUS" 'no commit, checkout, merge or file change'
}

test_status_detects_merged_pull_requests() {
  contains "$STATUS" 'on `Target branch` or `origin/<Target branch>`'
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
