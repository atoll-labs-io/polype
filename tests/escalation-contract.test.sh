#!/usr/bin/env bash
# s104 — what goes to the person, what the lead settles alone, and the log of the latter.

PLAN_CMD="$METHOD/commands/po-plan.md"
PLANNER="$METHOD/agents/planner.md"

MARKER='Technical choice: waiting for a human'

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }
holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

test_plan_with_a_tech_choice_waits_for_a_human() {
  contains "$PLANNER" "$MARKER"
  local wr; wr="$(section_of "$PLAN_CMD" 'Writing the plan')"
  holds "$wr" "$MARKER" 'po-plan Writing the plan'
}
