#!/usr/bin/env bash
# s93 — qa never concludes without proof, and never blocks on its own proof.

QA_AGENT="$METHOD/agents/qa.md"
SCENARIOS="$METHOD/skills/qa-drivers/scenarios.md"

# Succeeds when one line of the file holds every phrase given.
line_holds() {
  local file="$1" lines; shift
  lines="$(cat "$file")"
  for phrase in "$@"; do lines="$(grep -F -- "$phrase" <<< "$lines" || true)"; done
  [ -n "$lines" ]
}

test_qa_declares_what_it_reads() {
  contains "$QA_AGENT" 'status --porcelain` as it stands before the walk'
}

test_scenario_rules_bite() {
  require_file "$SCENARIOS"
  line_holds "$SCENARIOS" 'the first output did not list' '→ `QA status: blocked`, naming that path' \
    || fail "scenarios.md does not block on a new path"
  contains "$SCENARIOS" 'Each scenario then works from a scratch folder under the same directory'
}
