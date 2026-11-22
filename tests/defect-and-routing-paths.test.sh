#!/usr/bin/env bash
# s96 — the diagnostic and the routing hold on every path.

SKILL="$METHOD/skills/diagnostic/SKILL.md"
PLANNER="$METHOD/agents/planner.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

test_no_root_cause_goes_to_a_human() {
  section_of "$SKILL" 'Three hypotheses, then stop' | grep -qF '`Root cause: not found`' \
    || fail "the skill does not fix the marker line"
  local defect
  defect=$(section_of "$PLANNER" 'The contracts you carry' | grep '^- \*\*Defect story\*\*')
  grep -qF 'Root cause: not found' <<< "$defect" || fail "the planner defect bullet lacks the marker"
}
