#!/usr/bin/env bash
# s06 — anti-hallucination review.

CMD="$METHOD/commands/po-review.md"
AGENT="$METHOD/agents/reviewer.md"
SKILL="$METHOD/skills/review-antihallu/SKILL.md"
TPL="$METHOD/templates/review.md"

test_reviewer_cannot_write_files() {
  require_file "$AGENT" || return 1
  { ! has_tool "$AGENT" Write || fail "reviewer must not have Write"; } \
    && { has_tool "$AGENT" Edit || fail "reviewer needs Edit for the temporary neutralization"; } \
    && contains "$AGENT" 'git diff --exit-code'
}

test_reviewer_preloads_both_doctrines() {
  frontmatter "$AGENT" | grep -qx '  - review-antihallu' || fail "reviewer must preload review-antihallu" || return 1
  frontmatter "$AGENT" | grep -qx '  - testing-doctrine' || fail "reviewer must preload testing-doctrine"
}

test_review_template_ends_with_verdict_lines() {
  require_file "$TPL" || return 1
  local last2; last2=$(grep -v '^[[:space:]]*$' "$TPL" | tail -2 | sed 's/:.*//' | tr '\n' '|')
  [ "$last2" = "Max severity|Ship allowed|" ] || fail "template must end with Max severity then Ship allowed, got $last2"
}

test_review_antihallu_has_six_steps_and_bite_proof() {
  require_file "$SKILL" || return 1
  local steps; steps=$(grep -cE '^\*\*[1-6]\. ' "$SKILL")
  [ "$steps" -eq 6 ] || fail "expected 6 numbered steps, found $steps" || return 1
  contains "$SKILL" 'Run only the test files that name that invariant' \
    && contains "$SKILL" 'Zero red means the invariant is untested'
}

test_review_command_writes_blocked_report_on_failure() {
  require_file "$CMD" || return 1
  { ! has_tool "$CMD" Edit || fail "po-review must not have Edit"; } \
    && contains "$CMD" 'Review status: blocked' \
    && contains "$CMD" 'Max severity: critical' \
    && contains "$CMD" 'subagent_type: `reviewer`'
}

test_only_critical_blocks() {
  contains "$AGENT" 'Only a critical, or a review you could not complete' \
    && contains "$METHOD/AGENTS.md" 'Only a critical finding blocks'
}
