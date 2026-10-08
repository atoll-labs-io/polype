#!/usr/bin/env bash
# s93 — qa never concludes without proof, and never blocks on its own proof.

QA_AGENT="$METHOD/agents/qa.md"
DRIVERS="$METHOD/skills/qa-drivers/SKILL.md"
SCENARIOS="$METHOD/skills/qa-drivers/scenarios.md"

section() { awk -v h="## $2" '/^## / {on = (index($0, h) == 1); next} on' "$1"; }

# Succeeds when one line of the file holds every phrase given.
line_holds() {
  local file="$1" lines; shift
  lines="$(cat "$file")"
  for phrase in "$@"; do lines="$(grep -F -- "$phrase" <<< "$lines" || true)"; done
  [ -n "$lines" ]
}

test_no_driver_row_blocks() {
  local f
  for f in "$QA_AGENT" "$DRIVERS"; do
    line_holds "$f" 'No row matches' '`Platform` is missing' 'QA status: blocked' \
      || fail "${f##*/} does not block when no driver row matches"
  done
  contains "$QA_AGENT" 'A walk that followed no driver file is never `complete`'
}

test_own_evidence_never_blocks() {
  require_file "$SCENARIOS"
  line_holds "$SCENARIOS" 'the first output did not list' 'outside `docs/qa/<id>/`' \
    || fail "scenarios.md does not set docs/qa/<id>/ aside in its before/after comparison"
  line_holds "$SCENARIOS" 'calling the public interface' 'through Bash' \
    || fail "scenarios.md does not write the lib script through Bash"
  line_holds "$SCENARIOS" 'within 60 seconds' 'QA status: blocked' \
    || fail "scenarios.md does not bound the wait for a service"
}

test_qa_declares_what_it_reads() {
  local read; read="$(settings_read_by "$QA_AGENT")"
  grep -qx Install <<< "$read" || fail "qa.md does not declare Install"
  grep -qx Build <<< "$read" || fail "qa.md does not declare Build"
  contains "$QA_AGENT" 'status --porcelain` as it stands before the walk'
  section "$QA_AGENT" Scope | grep -qF 'docs/plans/<id>.md' || fail "qa.md Scope does not name the story's plan"
}

test_scenario_rules_bite() {
  require_file "$SCENARIOS"
  line_holds "$SCENARIOS" 'the first output did not list' '→ `QA status: blocked`, naming that path' \
    || fail "scenarios.md does not block on a new path"
  contains "$SCENARIOS" 'Each scenario then works from a scratch folder under the same directory'
  line_holds "$SCENARIOS" 'is a finding' 'a success code on bad input' \
    || fail "scenarios.md does not call a success code on bad input a finding"
}
