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

test_execute_fails_closed_on_unvalidated_plan() {
  contains "$CMD" 'Its frontmatter holds `validated: yes`'
  contains "$CMD" 'is not approved yet'
  contains "$CMD" '`subagent_type: implementer`'
}

test_execute_checks_worktree_registration_without_shell() {
  contains "$CMD" '`<shared>/worktrees/<id>/HEAD` contains `ref: refs/heads/story/<id>`'
  contains "$CMD" '`<shared>/worktrees/<id>/gitdir` contains `<repository root>/<Worktree root><id>/.git`'
}

test_execute_handles_a_repository_root_that_is_itself_a_worktree() {
  contains "$CMD" 'if it is a file (the repository root is itself a linked worktree)'
  contains "$METHOD/commands/po-review.md" 'checked the way `/po-execute` does it'
}

test_implementer_preloads_testing_doctrine() {
  require_file "$AGENT"
  frontmatter "$AGENT" | grep -qx '  - testing-doctrine' || fail "implementer must preload testing-doctrine"
}

test_implementer_makes_one_commit_after_record() {
  contains "$AGENT" '**one commit**'
  contains "$AGENT" 'No commit at this point.'
  contains "$AGENT" 'git write-tree'
}

test_implementer_accepts_pipeline_docs_but_nothing_else() {
  contains "$AGENT" 'on a fix run, `docs/reviews/<id>.md`: those are expected'
  contains "$AGENT" 'Any other change you did not make → stop and report.'
}

test_implementer_keeps_secrets_out_and_pins_its_directory() {
  contains "$AGENT" 'no `.env*` or other secret may be staged'
  contains "$AGENT" 'Start every shell command with `cd <that path> &&`'
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
