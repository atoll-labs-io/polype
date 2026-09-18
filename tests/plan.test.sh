#!/usr/bin/env bash
# s04 — plan and testing doctrine.

CMD="$METHOD/commands/po-plan.md"
TPL="$METHOD/templates/plan.md"
DOC="$METHOD/skills/testing-doctrine/SKILL.md"

test_plan_template_starts_unvalidated() {
  require_file "$TPL" || return 1
  frontmatter "$TPL" | grep -qx 'validated: no' || fail "plan template must start with validated: no"
}

test_plan_template_has_interdicts_and_pivot() {
  contains "$TPL" '## Run interdicts' && contains "$TPL" '## The pivot' && contains "$TPL" '## Test strategy'
}

test_plan_checkpoint_follows_setting() {
  require_file "$CMD" \
    && settings_read_by "$CMD" | grep -qx 'Plan validation' \
    && contains "$CMD" 'Only Validate writes `validated: yes`' \
    && contains "$CMD" 'nobody else read it'
}

test_plan_writes_no_code() {
  { ! has_tool "$CMD" Edit || fail "po-plan must not have Edit"; } && contains "$CMD" 'never code'
}

test_testing_doctrine_covers_budget_layers_cuts_shapes_stages() {
  require_file "$DOC" || return 1
  contains "$DOC" '## Budget' \
    && contains "$DOC" '## Where each test belongs' \
    && contains "$DOC" '## Four cuts' \
    && contains "$DOC" '## Six ways a test names a rule' \
    && contains "$DOC" '## When each check runs' \
    && contains "$DOC" 'worse than no test' || return 1
  local shapes; shapes=$(awk '/^## Six ways/ {on=1; next} /^## / {on=0} on && /^[0-9]\. /' "$DOC" | wc -l)
  [ "$shapes" -eq 6 ] || fail "expected 6 shapes, found $shapes"
}

test_testing_doctrine_forbids_red_first() {
  contains "$DOC" 'No red-first during implementation' && contains "$DOC" 'Neutralization belongs to the review'
}
