#!/usr/bin/env bash
# s19 — the plan-flow template.

TEMPLATE="$METHOD/templates/plan-flow.md"

test_plan_flow_template_carries_verified_facts() {
  require_file "$TEMPLATE"
  frontmatter "$TEMPLATE" | grep -qx 'track: flow' || fail "plan-flow frontmatter lacks track: flow"
  frontmatter "$TEMPLATE" | grep -qx 'validated: no' || fail "plan-flow frontmatter lacks validated: no"
}
