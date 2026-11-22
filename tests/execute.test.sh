#!/usr/bin/env bash
# s05 — delegated execution.

CMD="$METHOD/commands/po-execute.md"
AGENT="$METHOD/agents/implementer.md"
REC="$METHOD/templates/verification-record.md"

test_execute_has_no_write_tools() {
  require_file "$CMD"
  local t
  for t in Write Edit Bash NotebookEdit; do lacks_tool "$CMD" "$t"; done
  needs_tool "$CMD" Agent
}

test_implementer_preloads_testing_doctrine() {
  require_file "$AGENT"
  frontmatter "$AGENT" | grep -qx '  - testing-doctrine' || fail "implementer must preload testing-doctrine"
}

test_verification_record_has_tree_and_unfilled_status() {
  require_file "$REC"
  grep -q '^Tree: ' "$REC" || fail "record template needs a Tree: line"
  grep -qx 'Verification status: <complete | incomplete>' "$REC" || fail "record template needs an unfilled status line"
  grep -qx '## Checks' "$REC" || fail "record template needs a Checks table"
  [ "$(grep '^## ' "$REC" | tail -n 1)" = '## Runs' ] || fail "## Runs must be the record template's last section"
  sed -n '/^## Runs$/,$p' "$REC" | grep -qxF '| Check | Command | Exit | Tree | Time (UTC) |' \
    || fail "the Runs section needs its table header"
}
