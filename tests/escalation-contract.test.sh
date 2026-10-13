#!/usr/bin/env bash
# s104 — what goes to the person, what the lead settles alone, and the log of the latter.

RULES="$METHOD/AGENTS.md"
DRIVE="$METHOD/commands/po-drive.md"
PLAN_CMD="$METHOD/commands/po-plan.md"
FLOW="$METHOD/commands/po-flow.md"
ORCH="$METHOD/commands/po-orchestrator.md"
ARCHITECT="$METHOD/commands/po-architect.md"
PLANNER="$METHOD/agents/planner.md"
BRICKS="$METHOD/skills/capability-bricks/SKILL.md"
LOG_TEMPLATE="$METHOD/templates/decisions-log.md"

MARKER='Technical choice: waiting for a human'
CRITERIA='open source or self-hostable, frugal in hardware, scalable, easy for an AI to handle'
WHATEVER='whatever `Plan validation` says'

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }
holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

person_section() {
  local s; s="$(section_of "$RULES" 'What goes to the person')"
  [ -n "$s" ] || fail "method/AGENTS.md has no '## What goes to the person' section"
  printf '%s\n' "$s"
}

test_rules_list_the_three_escalation_motives() {
  local s; s="$(person_section)" || exit 1
  holds "$s" 'an incoherence' 'What goes to the person'
  holds "$s" 'the code, an accepted ADR and a story contradict each other' 'What goes to the person'
  holds "$s" 'a new idea outside the approved scope' 'What goes to the person'
  holds "$s" 'a strategic decision' 'What goes to the person'
  holds "$s" 'vision, scope, recurring cost, security, personal data, or anything hard to undo' 'What goes to the person'
}

test_tech_choices_are_never_settled_alone() {
  local s; s="$(person_section)" || exit 1
  holds "$s" 'Every technical or technology choice that deserves an ADR is discussed with the person before it is made' 'What goes to the person'
  holds "$s" 'An implementation detail inside a validated plan stays with the lead' 'What goes to the person'
  holds "$s" 'In doubt, the lead asks.' 'What goes to the person'
  holds "$s" "$MARKER" 'What goes to the person'
}

test_plan_with_a_tech_choice_waits_for_a_human() {
  local f
  for f in "$PLAN_CMD" "$FLOW" "$PLANNER"; do contains "$f" "$WHATEVER"; done
  for f in "$PLAN_CMD" "$PLANNER"; do
    contains "$f" "$MARKER"
    contains "$f" 'status: proposed'
  done
  holds "$(section_of "$FLOW" 'Escalation signals')" 'a technical choice that deserves an ADR' 'po-flow Escalation signals'

  # The waiting row must be read before the plain plan row, or the first match sends the lane to a planner.
  local rows marker_rows marker_at plan_at stage
  rows="$(section_of "$DRIVE" 'Resuming' | grep '^| ' | grep -v '^| --- ' | grep -v '^| Found ')"
  marker_rows="$(grep -cF -- "$MARKER" <<< "$rows")"
  [ "$marker_rows" = 1 ] || fail "po-drive resume table holds $marker_rows rows with the marker, expected 1"
  stage="$(grep -F -- "$MARKER" <<< "$rows" | cut -d'|' -f3)"
  [[ "$stage" == ' a human'* ]] || fail "the marker row does not send the lane to a human: $stage"
  marker_at="$(grep -nF -- "$MARKER" <<< "$rows" | cut -d: -f1)"
  plan_at="$(grep -nF 'the lane keeps that file and never writes it again' <<< "$rows" | cut -d: -f1)"
  [ -n "$plan_at" ] || fail "po-drive resume table lost its plan row"
  [ "$marker_at" -lt "$plan_at" ] || fail "the marker row (row $marker_at) must come before the plan row (row $plan_at)"

  holds "$(section_of "$DRIVE" "Validating a wave's plans")" "$MARKER" "po-drive Validating a wave's plans"
  holds "$(section_of "$ORCH" 'Stage 4 — Plan — checkpoint')" "$MARKER" 'po-orchestrator stage 4'
}

test_human_stops_do_not_halt_the_fleet() {
  local wave; wave="$(section_of "$DRIVE" 'A wave')"
  holds "$wave" 'at once, in a message of its own' 'po-drive A wave'
  holds "$wave" 'the other lanes carry on' 'po-drive A wave'
  contains "$ORCH" 'at once'
  contains "$ORCH" 'nothing here pauses them'
  local s; s="$(person_section)" || exit 1
  holds "$s" 'goes to the person at once, one at a time, and the fleet carries on with its other lanes' 'What goes to the person'
  holds "$s" 'No gate opens any other way than before' 'What goes to the person'
  holds "$s" 'the stops of ADR-0070 stay stops' 'What goes to the person'
}

test_lead_logs_what_it_decides_alone() {
  require_file "$LOG_TEMPLATE"
  grep -qxF '| Date | Story | Decision | Reason |' "$LOG_TEMPLATE" || fail "decisions-log template lacks its header row"
  local s; s="$(person_section)" || exit 1
  holds "$s" 'docs/decisions-log.md' 'What goes to the person'
  holds "$s" 'templates/decisions-log.md' 'What goes to the person'
  holds "$s" 'one dated line with its reason' 'What goes to the person'
  holds "$(section_of "$RULES" 'Law 6 — Evidence lives next to the code')" 'docs/decisions-log.md' 'Law 6'

  local log; log="$(section_of "$DRIVE" 'The decisions log')"
  [ -n "$log" ] || fail "po-drive.md has no '## The decisions log' section"
  holds "$log" 'templates/decisions-log.md' 'po-drive The decisions log'
  holds "$log" 'Landing the framing' 'po-drive The decisions log'
  holds "$log" 'slug `decisions-log`' 'po-drive The decisions log'
  holds "$log" "after the wave's last ship" 'po-drive The decisions log'
  holds "$(section_of "$DRIVE" 'Report')" 'decisions-log' 'po-drive Report'
}

test_options_ranked_by_owner_criteria() {
  holds "$(section_of "$BRICKS" 'Ranking the options')" "$CRITERIA" 'capability-bricks Ranking the options'
  holds "$(section_of "$ARCHITECT" 'Step 3 — Structural decisions')" 'Ranking the options' 'po-architect step 3'
  local s; s="$(person_section)" || exit 1
  holds "$s" "$CRITERIA" 'What goes to the person'
}
