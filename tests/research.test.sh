#!/usr/bin/env bash
# s03 — research.

CMD="$METHOD/commands/po-research.md"

test_research_bootstraps_worktree_and_branch() {
  require_file "$CMD"
  contains "$CMD" 'git worktree add -b story/<id> <path> <start point>'
  contains "$CMD" 'Do not run the tests.'
  contains "$CMD" 'Do not repair it with `switch`, `checkout` or `stash`.'
}

test_research_starts_from_fresh_target_branch() {
  contains "$CMD" 'start from `origin/<Target branch>` if that ref exists'
}

test_research_copies_only_ignored_env_files() {
  contains "$CMD" "git ls-files --others --ignored --exclude-standard -- '.env*'"
  contains "$CMD" 'that git does **not** ignore, stop'
}

test_research_verifies_premise_and_caps_length() {
  contains "$CMD" "**Test the story's assumptions against the code.**"
  contains "$CMD" "what it does with this story's inputs"
  contains "$CMD" '**200 lines at most**'
}

test_research_template_has_structuring_facts_and_complexity() {
  local t="$METHOD/templates/research.md"
  require_file "$t"
  [ "$(grep -m1 '^## ' "$t")" = "## Structuring facts" ] || fail "research template must open on the structuring facts"
  contains "$t" '## Complexity'
  contains "$t" '## Split'
}

test_research_writes_no_code() {
  lacks_tool "$CMD" Edit
  contains "$CMD" 'no source file is touched'
}

test_stories_template_declares_owns_and_scale() {
  local t="$METHOD/templates/stories.md"
  require_file "$t"
  contains "$t" '**Owns**'
  contains "$t" '**Complexity scale**'
  contains "$t" '`s<number>-<short-slug>`'
}

test_codebase_analysis_reports_rules_not_rewrites() {
  local s="$METHOD/skills/codebase-analysis/SKILL.md"
  require_file "$s"
  contains "$s" '**Write rules, not impressions.**'
  contains "$s" 'Suggesting a rewrite is out of scope'
}
