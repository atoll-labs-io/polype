#!/usr/bin/env bash
# s26 — the planner subagent.

AGENT="$METHOD/agents/planner.md"

test_planner_preloads_testing_doctrine_and_codebase_analysis() {
  require_file "$AGENT"
  frontmatter "$AGENT" | grep -qx '  - codebase-analysis' || fail "planner must preload codebase-analysis"
  frontmatter "$AGENT" | grep -qx '  - testing-doctrine' || fail "planner must preload testing-doctrine"
}

test_planner_never_writes_code() {
  require_file "$AGENT"
  lacks_tool "$AGENT" Edit
  needs_tool "$AGENT" Write
  needs_tool "$AGENT" Bash
}
