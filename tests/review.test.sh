#!/usr/bin/env bash
# s06 — anti-hallucination review.

CMD="$METHOD/commands/po-review.md"
AGENT="$METHOD/agents/reviewer.md"
SKILL="$METHOD/skills/review-antihallu/SKILL.md"
TPL="$METHOD/templates/review.md"

test_reviewer_cannot_write_files() {
  require_file "$AGENT"
  lacks_tool "$AGENT" Write
  needs_tool "$AGENT" Edit
  contains "$AGENT" 'git diff --exit-code'
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

test_review_antihallu_has_six_steps_and_bite_proof() {
  require_file "$SKILL"
  local steps; steps=$(grep -cE '^\*\*[1-6]\. ' "$SKILL")
  [ "$steps" -eq 6 ] || fail "expected 6 numbered steps, found $steps"
  contains "$SKILL" 'run **only the test files that exercise that rule**'
  contains "$SKILL" '**A disabled rule that fails no test is not tested**'
}

test_review_command_writes_blocked_report_on_failure() {
  require_file "$CMD"
  lacks_tool "$CMD" Edit
  lacks_tool "$CMD" Bash
  contains "$CMD" '`Review status: blocked`'
  contains "$CMD" '`Max severity: critical`'
  contains "$CMD" '`subagent_type: reviewer`'
}

test_review_counts_fix_loops_across_sessions() {
  contains "$TPL" 'Fix loop:'
  contains "$CMD" 'its `Fix loop:` value plus one is this review'"'"'s loop number'
}

test_only_critical_blocks() {
  contains "$AGENT" '`Ship allowed: no` means a critical finding or a blocked review, and nothing else.'
  contains "$METHOD/AGENTS.md" '**Critical** stops the ship.'
}
