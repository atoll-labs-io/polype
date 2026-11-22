#!/usr/bin/env bash
# s04 — plan and testing doctrine.

CMD="$METHOD/commands/po-plan.md"
TPL="$METHOD/templates/plan.md"

test_plan_template_starts_unvalidated() {
  require_file "$TPL"
  frontmatter "$TPL" | grep -qx 'validated: no' || fail "plan template must start with validated: no"
}

test_plan_writes_no_code() {
  lacks_tool "$CMD" Edit
}
