#!/usr/bin/env bash
# s03 — research.

CMD="$METHOD/commands/po-research.md"

test_research_writes_no_code() {
  lacks_tool "$CMD" Edit
}

test_stories_template_declares_owns_and_scale() {
  local t="$METHOD/templates/stories.md"
  require_file "$t"
  contains "$t" '**Owns**'
}
