#!/usr/bin/env bash
# s04 — plan and testing doctrine.

CMD="$METHOD/commands/po-plan.md"
TPL="$METHOD/templates/plan.md"
DOC="$METHOD/skills/testing-doctrine/SKILL.md"

test_plan_template_starts_unvalidated() {
  require_file "$TPL"
  frontmatter "$TPL" | grep -qx 'validated: no' || fail "plan template must start with validated: no"
}

test_plan_template_has_interdicts_and_pivot() {
  contains "$TPL" '## Run interdicts'
  contains "$TPL" '## The pivot'
  contains "$TPL" '## Test strategy'
}

test_plan_checkpoint_follows_setting() {
  require_file "$CMD"
  settings_read_by "$CMD" | grep -qx 'Plan validation' || fail "po-plan must read Plan validation"
  contains "$CMD" 'Write `validated: yes` into the frontmatter on Approve and on nothing else.'
  contains "$CMD" 'state that no human reviewed it'
}

test_plan_writes_no_code() {
  lacks_tool "$CMD" Edit
  contains "$CMD" 'source files are out of reach for this command'
}

test_testing_doctrine_covers_budget_layers_cuts_shapes_stages() {
  require_file "$DOC"
  contains "$DOC" '## How many tests?'
  contains "$DOC" '## Which layer?'
  contains "$DOC" '## Four things to cut'
  contains "$DOC" '## Tests that prove nothing'
  contains "$DOC" '## When does each check run?'
  contains "$DOC" 'is worse than no test'
  local shapes; shapes=$(awk '/^## Tests that prove nothing/ {on=1; next} /^## / {on=0} on && /^[0-9]\. /' "$DOC" | wc -l)
  [ "$shapes" -eq 6 ] || fail "expected 6 shapes, found $shapes"
}

test_testing_doctrine_forbids_red_first() {
  contains "$DOC" '## No red-first while implementing'
  contains "$DOC" "Disabling guards on purpose is the reviewer's job"
}
