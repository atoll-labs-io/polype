#!/usr/bin/env bash
# s03 — research.

CMD="$METHOD/commands/po-research.md"

test_research_bootstraps_worktree_and_branch() {
  require_file "$CMD" \
    && contains "$CMD" 'git worktree add -b story/<id>' \
    && contains "$CMD" '.env*' \
    && contains "$CMD" 'Never run the test suite' \
    && contains "$CMD" 'Never `git switch`, `checkout`, `stash`'
}

test_research_verifies_premise_and_caps_length() {
  contains "$CMD" "Check the story's premise" \
    && contains "$CMD" "behaviour on the story's own case" \
    && contains "$CMD" 'At most ~200 lines'
}

test_research_template_has_structuring_facts_and_complexity() {
  local t="$METHOD/templates/research.md"
  require_file "$t" || return 1
  [ "$(grep -m1 '^## ' "$t")" = "## Structuring facts" ] || fail "research template must open on the structuring facts"
  contains "$t" '## Complexity' && contains "$t" '## Split proposal'
}

test_research_writes_no_code() {
  ! has_tool "$CMD" Edit || fail "po-research must not have Edit"
  contains "$CMD" 'not a plan and not code'
}

test_stories_template_declares_owns_and_scale() {
  local t="$METHOD/templates/stories.md"
  require_file "$t" && contains "$t" '**Owns**' && contains "$t" 'Complexity scale' && contains "$t" 's<number>-<short-slug>'
}

test_codebase_analysis_reports_rules_not_rewrites() {
  local s="$METHOD/skills/codebase-analysis/SKILL.md"
  require_file "$s" && contains "$s" 'Report as rules' && contains "$s" 'never propose a rewrite'
}
