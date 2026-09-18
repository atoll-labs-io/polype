#!/usr/bin/env bash
# s05 — delegated execution.

CMD="$METHOD/commands/po-execute.md"
AGENT="$METHOD/agents/implementer.md"
REC="$METHOD/templates/verification-record.md"

test_execute_has_no_write_tools() {
  require_file "$CMD" || return 1
  local t
  for t in Write Edit Bash NotebookEdit; do
    ! has_tool "$CMD" "$t" || fail "po-execute must not have $t" || return 1
  done
  has_tool "$CMD" Agent || fail "po-execute needs the Agent tool to delegate"
}

test_execute_fails_closed_on_unvalidated_plan() {
  contains "$CMD" 'Its frontmatter contains `validated: yes`' \
    && contains "$CMD" 'Plan not validated' \
    && contains "$CMD" 'subagent_type: `implementer`'
}

test_execute_checks_branch_without_shell() {
  contains "$CMD" '.git/worktrees/<id>/HEAD' && contains "$CMD" 'ref: refs/heads/story/<id>'
}

test_implementer_preloads_testing_doctrine() {
  require_file "$AGENT" || return 1
  frontmatter "$AGENT" | grep -qx '  - testing-doctrine' || fail "implementer must preload testing-doctrine" || return 1
  frontmatter "$AGENT" | grep -qx 'model: opus' || fail "implementer is pinned to opus"
}

test_implementer_makes_one_commit_after_record() {
  contains "$AGENT" 'One commit for the whole story' \
    && contains "$AGENT" 'Do not commit.' \
    && contains "$AGENT" 'git write-tree'
}

test_verification_record_has_tree_and_status() {
  require_file "$REC" || return 1
  grep -q '^Tree: ' "$REC" || fail "record template needs a Tree: line" || return 1
  [ "$(grep -v '^[[:space:]]*$' "$REC" | tail -1)" = "Verification status: complete" ] \
    || fail "record template must end with 'Verification status: complete'"
}
