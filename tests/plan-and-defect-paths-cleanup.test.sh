#!/usr/bin/env bash
# s126 — the plan and the defect paths say the same stops, and their tests bite.

RESEARCH="$METHOD/commands/po-research.md"
ORCH="$METHOD/commands/po-orchestrator.md"
PLAN="$METHOD/commands/po-plan.md"
PLANNER="$METHOD/agents/planner.md"
PLAN_FLOW="$METHOD/templates/plan-flow.md"
FLOWCMD="$METHOD/commands/po-flow.md"
MUTANTS="$(mktemp -d)"
trap 'rm -rf "$MUTANTS"' EXIT

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }
holds() { grep -qF -- "$2" <<< "$1" || fail "${3:-text} lacks: $2"; }

mutant() {
  local dir
  dir="$(mktemp -d "$MUTANTS/XXXXXX")"
  cp -r "$METHOD" "$dir/method"
  echo "$dir/method"
}

run_against() {
  ( METHOD="$1"; CMDS="$1/commands"; source "$2"; "$3" ) >/dev/null 2>&1
}

bites() {
  local file="$1" phrase="$2" t="$ROOT/tests/$3" name="$4" m
  run_against "$METHOD" "$t" "$name" || fail "$name fails on the real tree"
  m="$(mutant)"
  python3 -I - "$m/$file" "$phrase" <<'PY' || fail "mutation did not apply to $file"
import sys
p, a = sys.argv[1:]
s = open(p).read()
assert s.count(a) == 1
open(p, "w").write(s.replace(a, ""))
PY
  ! grep -qF -- "$phrase" "$m/$file" || fail "mutant keeps its phrase in $file"
  if run_against "$m" "$t" "$name"; then fail "$name still passes without the rule in $file"; fi
}

test_defect_stops_agree() {
  local report stage2 checks defect
  report="$(section_of "$RESEARCH" 'The report')"
  stage2="$(section_of "$ORCH" 'Stage 2 — Research')"
  checks="$(section_of "$PLAN" 'Checks first')"
  defect="$(grep -F -- '**Defect story**' "$PLANNER")"
  ! grep -qF 'opens with `Root cause' "$RESEARCH" "$ORCH" || fail "a stop still says the research opens with the marker"
  holds "$report" 'as a whole line (`grep -x`' 'po-research The report'
  holds "$report" '`## Structuring facts`' 'po-research The report'
  holds "$report" 'No root cause found for <id>' 'po-research The report'
  holds "$stage2" 'as a whole line (`grep -x`' 'po-orchestrator Stage 2'
  holds "$stage2" '`## Structuring facts`' 'po-orchestrator Stage 2'
  holds "$stage2" 'ends the run here' 'po-orchestrator Stage 2'
  holds "$stage2" 'with no plan' 'po-orchestrator Stage 2'
  holds "$(grep -F 'Root cause: not found' <<< "$checks")" 'as a whole line (`grep -x`' 'po-plan Checks first'
  holds "$defect" 'as a whole line (`grep -x`' 'planner Defect bullet'
  holds "$defect" 'you write no plan' 'planner Defect bullet'
}

test_tech_choice_paths_agree() {
  local limits signals approval
  limits="$(section_of "$PLANNER" 'Limits' | grep -F -- '- A structural choice')"
  holds "${limits#*No number there}" 'Technical choice: waiting for a human' 'planner fallback'
  ! grep -qF 'should not exist' "$PLAN_FLOW" || fail "plan-flow still says the file should not exist"
  signals="$(section_of "$PLAN_FLOW" 'Escalation signals')"
  holds "$signals" 'Technical choice: waiting for a human' 'plan-flow Escalation signals'
  holds "$signals" '## Approval' 'plan-flow Escalation signals'
  grep -q '^| Technical choice that deserves an ADR' <<< "$signals" || fail "plan-flow signal table lacks the technical choice row"
  approval="$(section_of "$FLOWCMD" 'Approval')"
  holds "$approval" '- name that ADR in the plan.' 'po-flow Approval'
}

test_plan_tests_bite() {
  local self=plan-and-defect-paths-cleanup.test.sh
  bites commands/po-research.md 'No root cause found for <id>' $self test_defect_stops_agree
  bites commands/po-orchestrator.md 'ends the run here' $self test_defect_stops_agree
  bites commands/po-drive.md 'sends its lane to a human' defect-and-routing-paths.test.sh test_no_root_cause_goes_to_a_human
  bites commands/po-flow.md 'name that ADR in the plan.' $self test_tech_choice_paths_agree
  bites agents/planner.md ', a defect to fix — a story carrying a `Fixes` line (`Corrige` in a French stories file)' diagnostic-skill.test.sh test_defect_stories_get_the_diagnostic
  bites templates/plan-flow.md 'A signal present sends the story to the full track and no short plan is written, except a technical choice, where this file stays on disk with the line `Technical choice: waiting for a human` and the story goes to `/po-research <id>`, as `## Approval` of `/po-flow` says.' $self test_tech_choice_paths_agree
  bites templates/plan-flow.md '| Technical choice that deserves an ADR (library, pattern, data model) | absent — <where checked> | absent — <where checked> |' $self test_tech_choice_paths_agree

  local bt="$ROOT/tests/tech-choice-backstop.test.sh" review="$METHOD/commands/po-stories-review.md"
  ! grep -qF "grep -qF 'Stories ready:'" "$bt" || fail "the old mutation guard is still there"
  grep -F 'as ` — owner: <answer>`.' "$review" | grep -qF 'The `Max severity:` and `Stories ready:` lines are never changed' || fail "guard phrase is not on the review line"
  grep -F 'as ` — owner: <answer>`.' "$bt" >/dev/null || fail "backstop test lacks the new guard phrase"
}
