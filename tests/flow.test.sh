#!/usr/bin/env bash
# s19 — /po-flow and the plan-flow template.

COMMAND="$METHOD/commands/po-flow.md"
TEMPLATE="$METHOD/templates/plan-flow.md"

# The body of one `## <heading>` section of a file, heading excluded.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

# Fails unless every phrase is found in the named section of the command.
section_holds() {
  local heading="$1" body phrase
  shift
  body=$(section_of "$COMMAND" "$heading")
  for phrase in "$@"; do
    grep -qF -- "$phrase" <<< "$body" || fail "section '$heading' lacks: $phrase"
  done
}

test_flow_keeps_every_gate() {
  require_file "$COMMAND"
  needs_tool "$COMMAND" Agent
  section_holds 'Nothing is relaxed' \
    'Only the number of contexts goes down.' \
    'story/<id>' \
    'validated: yes' \
    'Ship allowed: yes' \
    '`Test budget`'
  section_holds 'Execute, review, ship' \
    'subagent_type: implementer' \
    'subagent_type: reviewer' \
    '/po-ship'
}

test_flow_checks_escalation_signals_twice() {
  require_file "$COMMAND"
  section_holds 'Escalation signals' \
    'a migration' \
    'a new screen' \
    'authorization or tenant scope' \
    'an API contract' \
    'a new dependency' \
    'before reading the code' \
    'after reading the code' \
    'A single signal'
}

test_flow_respects_story_track() {
  require_file "$COMMAND"
  settings_read_by "$COMMAND" | grep -qx 'Story track' || fail "po-flow.md does not read Story track"
  settings_read_by "$COMMAND" | grep -qx 'Flow threshold' || fail "po-flow.md does not read Flow threshold"
  section_holds 'Which track' \
    '`Story track` is `full`' \
    '`auto`' \
    '`Flow threshold`'
}

test_plan_flow_template_carries_verified_facts() {
  require_file "$TEMPLATE"
  frontmatter "$TEMPLATE" | grep -qx 'track: flow' || fail "plan-flow frontmatter lacks track: flow"
  frontmatter "$TEMPLATE" | grep -qx 'validated: no' || fail "plan-flow frontmatter lacks validated: no"
  grep -qxF '## Verified facts' "$TEMPLATE" || fail "plan-flow template lacks ## Verified facts"
  grep -qxF '## Escalation signals' "$TEMPLATE" || fail "plan-flow template lacks ## Escalation signals"
  contains "$TEMPLATE" 'path:line'
  contains "$TEMPLATE" '150 lines'
}
