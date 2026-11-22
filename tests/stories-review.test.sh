#!/usr/bin/env bash
# s15 — stories review: the subagent's tools and the template's verdict lines.

AGENT="$METHOD/agents/stories-reviewer.md"
TEMPLATE="$METHOD/templates/stories-review.md"

test_stories_reviewer_is_read_only_without_shell() {
  require_file "$AGENT"
  needs_tool "$AGENT" Read
  lacks_tool "$AGENT" Write
  lacks_tool "$AGENT" Edit
  lacks_tool "$AGENT" Bash
  frontmatter "$AGENT" | grep -qx '  - stories-review' || fail "stories-reviewer does not preload stories-review"
}

test_stories_review_template_ends_with_stories_ready() {
  local last_two
  require_file "$TEMPLATE"
  last_two=$(grep -v '^[[:space:]]*$' "$TEMPLATE" | tail -n 2)
  [ "$last_two" = $'Max severity: <critical | major | minor | none>\nStories ready: <yes | no>' ] \
    || fail "the template does not end with Max severity then Stories ready"
}
