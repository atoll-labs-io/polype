#!/usr/bin/env bash
# s20 — framing and short track wired into rules, status and reviewer.

AGENT="$METHOD/agents/reviewer.md"

test_reviewer_checks_design_conformity_without_measuring() {
  require_file "$AGENT"
  frontmatter "$AGENT" | grep -qx '  - design-doctrine' || fail "reviewer must preload design-doctrine"
}
