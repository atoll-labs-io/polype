#!/usr/bin/env bash
# s90 — the diagnostic skill.

SKILL="$METHOD/skills/diagnostic/SKILL.md"
PLANNER="$METHOD/agents/planner.md"
FLOW="$METHOD/commands/po-flow.md"
PLAN_FLOW="$METHOD/templates/plan-flow.md"
STORIES_TEMPLATE="$METHOD/templates/stories.md"
AGENTIC="$METHOD/skills/agentic-stories/SKILL.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

line_of() { grep -nxF -- "$2" "$1" | head -1 | cut -d: -f1; }

test_no_fix_without_a_root_cause() {
  require_file "$SKILL"
  contains "$SKILL" 'name: diagnostic'
  local reproduce cause plan
  reproduce=$(line_of "$SKILL" '## Reproduce')
  cause=$(line_of "$SKILL" '## Root cause')
  plan=$(line_of "$SKILL" '## Only then, the plan')
  [[ -n $reproduce && -n $cause && -n $plan ]] || fail "a heading of the skill is missing"
  (( reproduce < cause && cause < plan )) || fail "the sections are not in the order reproduce, root cause, plan"
  section_of "$SKILL" 'Root cause' | grep -qF '`path:line`' || fail "root cause lacks path:line"
  section_of "$SKILL" 'Root cause' | grep -qF 'the proof' || fail "root cause lacks the proof"
  section_of "$SKILL" 'Only then, the plan' | grep -qF 'the test that would have caught the defect' \
    || fail "the plan section lacks the test that would have caught the defect"
}

test_stop_after_three_failed_hypotheses() {
  local body
  body=$(section_of "$SKILL" 'Three hypotheses, then stop')
  grep -qF 'After three discarded hypotheses, stop.' <<< "$body" || fail "stop rule missing"
  grep -qF 'write no plan' <<< "$body" || fail "no-plan clause missing"
  grep -qF 'report that no root cause was found' <<< "$body" || fail "report clause missing"
}

test_defect_stories_get_the_diagnostic() {
  frontmatter "$PLANNER" | grep -qx '  - diagnostic' || fail "planner does not preload diagnostic"
  local f
  for f in "$PLANNER" "$PLAN_FLOW" "$AGENTIC"; do
    contains "$f" '`Fixes`'
    contains "$f" 'Corrige'
  done
  section_of "$PLANNER" 'Which track' | grep -qF 'a defect to fix — a story carrying a `Fixes` line' || fail "planner Which track lacks the Fixes signal"
  section_of "$PLANNER" 'Which track' | grep -qF 'Corrige' || fail "planner Which track lacks Corrige"
  section_of "$FLOW" 'Escalation signals' | grep -qF '`Fixes`' || fail "po-flow signals lack Fixes"
  section_of "$FLOW" 'Escalation signals' | grep -qF 'Corrige' || fail "po-flow signals lack Corrige"
  grep -qE '^- \*\*Fixes\*\*:.*Corrige' "$STORIES_TEMPLATE" || fail "stories template lacks the Fixes line naming Corrige"
  for f in "$PLANNER" "$FLOW" "$PLAN_FLOW"; do
    ! grep -qi 'five signals\|of the five' "$f" || fail "${f#"$ROOT"/} still counts five signals"
  done
}
