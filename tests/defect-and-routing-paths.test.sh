#!/usr/bin/env bash
# s96 — the diagnostic and the routing hold on every path.

SKILL="$METHOD/skills/diagnostic/SKILL.md"
RESEARCH="$METHOD/commands/po-research.md"
ORCH="$METHOD/commands/po-orchestrator.md"
PLAN="$METHOD/commands/po-plan.md"
PLANNER="$METHOD/agents/planner.md"
DRIVE="$METHOD/commands/po-drive.md"
FLOW="$METHOD/commands/po-flow.md"
EXECUTE="$METHOD/commands/po-execute.md"
ADR68="$ROOT/docs/decisions/ADR-0068-une-story-de-defaut-porte-une-ligne-fixes-et-passe-par-le-diagnostic.md"
ADR70="$ROOT/docs/decisions/ADR-0070-une-recherche-sans-cause-racine-porte-une-ligne-et-va-a-un-humain.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

test_every_path_runs_the_diagnostic() {
  local f heading body
  for f in "$RESEARCH|The investigation" "$ORCH|Stage 2 — Research"; do
    heading=${f#*|}
    body=$(section_of "${f%%|*}" "$heading")
    grep -qF '`diagnostic` skill' <<< "$body" || fail "$heading does not name the diagnostic skill"
    grep -qF '`Fixes`' <<< "$body" || fail "$heading does not name the Fixes line"
    grep -qF 'Corrige' <<< "$body" || fail "$heading does not name the Corrige line"
  done
}

test_no_root_cause_goes_to_a_human() {
  section_of "$SKILL" 'Three hypotheses, then stop' | grep -qF '`Root cause: not found`' \
    || fail "the skill does not fix the marker line"
  section_of "$PLAN" 'Checks first' | grep -qF 'Root cause: not found' \
    || fail "/po-plan does not stop on the marker"
  local defect
  defect=$(section_of "$PLANNER" 'The contracts you carry' | grep '^- \*\*Defect story\*\*')
  grep -qF 'Root cause: not found' <<< "$defect" || fail "the planner defect bullet lacks the marker"
  grep -qF 'write no plan' <<< "$defect" || fail "the planner defect bullet does not forbid the plan"

  local rows marker_line plan_line
  rows=$(section_of "$DRIVE" 'Resuming' | grep -c 'Root cause: not found')
  [[ $rows == 1 ]] || fail "expected one resuming row with the marker, found $rows"
  section_of "$DRIVE" 'Resuming' | grep 'Root cause: not found' | awk -F'|' '{print $3}' \
    | grep -q '^ a human' || fail "the marker row does not send the lane to a human"
  grep -F 'Root cause: not found' "$DRIVE" | grep '^|' | grep -qF 'as a whole line' \
    || fail "the marker row does not say whole line"
  local step1
  step1=$(section_of "$DRIVE" 'A wave' | grep '^1\. `subagent_type: planner`')
  grep -qF 'sends its lane to a human' <<< "$step1" || fail "the planner step does not send the lane to a human"
  grep -qF 'no plan is approved or dispatched for it' <<< "$step1" || fail "the planner step does not stop the plan"
  marker_line=$(grep -n '^| .*Root cause: not found' "$DRIVE" | head -1 | cut -d: -f1)
  plan_line=$(grep -n '^| .*the lane keeps that file and never writes it again' "$DRIVE" | head -1 | cut -d: -f1)
  [[ -n $marker_line && -n $plan_line ]] || fail "a resuming row is missing"
  (( marker_line < plan_line )) || fail "the marker row comes after the plan row"

  frontmatter "$ADR70" | grep -qx 'supersedes: \[ADR-0068\]' || fail "ADR-0070 does not supersede ADR-0068"
  frontmatter "$ADR68" | grep -qx 'superseded-by: \[ADR-0070\]' || fail "ADR-0068 is not marked superseded by ADR-0070"
}

test_flow_names_the_qa_stage_exception() {
  local line
  line=$(grep -F 'A missing setting is a stop' "$FLOW")
  [[ -n $line ]] || fail "po-flow lost its missing-setting sentence"
  grep -qF '`QA stage` excepted' <<< "$line" || fail "po-flow does not except QA stage"
  grep -qF 'only a story that would go to QA' <<< "$line" || fail "po-flow does not say whom a missing QA stage stops"
}

test_implementer_may_explore_a_throwaway_clone() {
  local prompt
  prompt=$(grep '^> Story <id>\. Worktree:' "$EXECUTE")
  [[ -n $prompt ]] || fail "implementer prompt not found"
  grep -qF 'never checkout or stash in the story worktree' <<< "$prompt" \
    || fail "the checkout ban is not scoped to the story worktree"
  ! grep -qF 'never checkout or stash.' <<< "$prompt" || fail "the prompt still forbids checkout everywhere"
}
