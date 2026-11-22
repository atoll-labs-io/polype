#!/usr/bin/env bash
# s06 — anti-hallucination review.

CMD="$METHOD/commands/po-review.md"
AGENT="$METHOD/agents/reviewer.md"
TPL="$METHOD/templates/review.md"

test_reviewer_cannot_write_files() {
  require_file "$AGENT"
  lacks_tool "$AGENT" Write
  needs_tool "$AGENT" Edit
}

test_reviewer_preloads_both_doctrines() {
  frontmatter "$AGENT" | grep -qx '  - review-antihallu' || fail "reviewer must preload review-antihallu"
  frontmatter "$AGENT" | grep -qx '  - testing-doctrine' || fail "reviewer must preload testing-doctrine"
}

test_review_template_ends_with_verdict_lines() {
  require_file "$TPL"
  local last2; last2=$(grep -v '^[[:space:]]*$' "$TPL" | tail -n 2 | sed 's/:.*//' | tr '\n' '|')
  [ "$last2" = "Max severity|Ship allowed|" ] || fail "template must end with Max severity then Ship allowed, got $last2"
}

test_review_command_writes_blocked_report_on_failure() {
  require_file "$CMD"
  lacks_tool "$CMD" Edit
  lacks_tool "$CMD" Bash
  contains "$CMD" '`Review status: blocked`'
  contains "$CMD" '`Max severity: critical`'
}

test_review_counts_fix_loops_across_sessions() {
  contains "$TPL" 'Fix loop:'
}

# s47 — a verdict counts only for the tree it judged.

test_review_template_records_the_reviewed_tree() {
  local tree_line verdict_line
  tree_line=$(grep -n '^Reviewed tree:' "$TPL" | head -n 1 | cut -d: -f1)
  verdict_line=$(grep -n '^Max severity:' "$TPL" | tail -n 1 | cut -d: -f1)
  [ -n "$tree_line" ] || fail "the review template has no 'Reviewed tree:' line"
  [ "$tree_line" -lt "$verdict_line" ] || fail "'Reviewed tree:' must sit in the header, before 'Max severity:'"
}
