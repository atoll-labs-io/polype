#!/usr/bin/env bash
# s90 — the diagnostic skill.

PLANNER="$METHOD/agents/planner.md"
STORIES_TEMPLATE="$METHOD/templates/stories.md"

test_defect_stories_get_the_diagnostic() {
  frontmatter "$PLANNER" | grep -qx '  - diagnostic' || fail "planner does not preload diagnostic"
  grep -qE '^- \*\*Fixes\*\*:.*Corrige' "$STORIES_TEMPLATE" || fail "stories template lacks the Fixes line naming Corrige"
}
