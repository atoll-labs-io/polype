#!/usr/bin/env bash
# s149 — the planner writes the story's acceptance tests, the oracle, in files of their own;
# the implementer changes them only through a logged reason the reviewer judges (ADR-0098).

PLAN="$METHOD/templates/plan.md"
PLAN_FLOW="$METHOD/templates/plan-flow.md"
PLANNER="$METHOD/agents/planner.md"
IMPLEMENTER="$METHOD/agents/implementer.md"
PO_PLAN="$METHOD/commands/po-plan.md"
PO_FLOW="$METHOD/commands/po-flow.md"
PO_EXECUTE="$METHOD/commands/po-execute.md"
PO_ORCH="$METHOD/commands/po-orchestrator.md"
RECORD="$METHOD/templates/verification-record.md"
DOCTRINE="$METHOD/skills/testing-doctrine/SKILL.md"
ADR="$ROOT/docs/decisions/ADR-0098-le-planner-ecrit-l-oracle-d-acceptation.md"

NAMED_FILES='the oracle files that `## Acceptance tests` of the plan names'

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

line_of() { grep -nx -- "$2" "$1" | head -n1 | cut -d: -f1; }

test_plan_lists_its_oracle() {
  local f name reuse oracle tasks section first
  for f in "$PLAN" "$PLAN_FLOW"; do
    require_file "$f"
    name="${f#"$ROOT"/}"
    reuse="$(line_of "$f" '## Reuse')"
    oracle="$(line_of "$f" '## Acceptance tests')"
    tasks="$(line_of "$f" '## Tasks')"
    [ -n "$oracle" ] || fail "$name has no ## Acceptance tests heading"
    [ "$reuse" -lt "$oracle" ] && [ "$oracle" -lt "$tasks" ] || fail "$name: ## Acceptance tests is not between ## Reuse and ## Tasks"
    section="$(section_of "$f" 'Acceptance tests')"
    holds "$section" 'cksum < <path>' "$name ## Acceptance tests"
    holds "$section" '| Oracle file | cksum |' "$name ## Acceptance tests"
    holds "$section" '| Criterion | Test |' "$name ## Acceptance tests"
    holds "$section" 'counted in `Test budget`' "$name ## Acceptance tests"
    holds "$section" '`—` with its reason' "$name ## Acceptance tests"
  done
  first="$(section_of "$PLAN" 'Acceptance tests')"
  [ "$first" = "$(section_of "$PLAN_FLOW" 'Acceptance tests')" ] || fail "## Acceptance tests differs between the two plan templates"
}

test_oracle_lives_in_its_own_files() {
  contains "$ROOT/AGENTS.local.md" 'tests/<story-slug>.oracle.test.sh'
  contains "$ROOT/AGENTS.local.md" 'which exists only when it holds at least one test'
  local limits
  limits="$(section_of "$PLANNER" Limits)"
  holds "$limits" "An oracle file the story's \`Owns\` does not list is not written" "planner ## Limits"
  holds "$limits" 'report it as a gap in the story' "planner ## Limits"
  holds "$(section_of "$PLAN" 'Acceptance tests')" 'The implementer adds its own tests to other files' "plan ## Acceptance tests"
}

test_planner_writes_oracle_files() {
  local limits section
  limits="$(section_of "$PLANNER" Limits)"
  holds "$limits" '**The oracle is the one exception.**' "planner ## Limits"
  holds "$limits" 'no other test file' "planner ## Limits"
  holds "$limits" "each test goes through the interface the plan's tasks fix" "planner ## Limits"
  section="$(section_of "$PO_PLAN" 'Writing the plan')"
  holds "$section" 'no other test file' "po-plan ## Writing the plan"
  holds "$section" '## Acceptance tests' "po-plan ## Writing the plan"
  section="$(section_of "$PO_FLOW" 'The plan')"
  holds "$section" 'no other test file' "po-flow ## The plan"
  holds "$section" '## Acceptance tests' "po-flow ## The plan"
}

test_oracle_files_are_expected_work() {
  local exec_line orch_line
  contains "$METHOD/AGENTS.md" "$NAMED_FILES"
  grep -F -- 'status --porcelain' "$PLANNER" | grep -qF -- "$NAMED_FILES" \
    || fail "the planner's state check does not accept the oracle files"
  grep -F -- 'status --porcelain' "$IMPLEMENTER" | grep -qF -- "$NAMED_FILES" \
    || fail "the implementer does not expect the oracle files"
  exec_line="$(grep -m1 -F -- '> This story has an oracle:' "$PO_EXECUTE")" || fail "po-execute lacks the oracle sentence"
  orch_line="$(grep -m1 -F -- '> This story has an oracle:' "$PO_ORCH")" || fail "po-orchestrator lacks the oracle sentence"
  [ "$exec_line" = "$orch_line" ] || fail "the oracle sentence differs between po-execute and po-orchestrator"
  holds "$exec_line" 'is expected uncommitted work' "the oracle sentence"
  holds "$exec_line" 'commit them with the story' "the oracle sentence"
}

test_implementer_keeps_the_oracle() {
  local changes runs limits
  changes="$(line_of "$RECORD" '## Oracle changes')"
  runs="$(line_of "$RECORD" '## Runs')"
  [ -n "$changes" ] && [ "$changes" -lt "$runs" ] || fail "the record template lacks ## Oracle changes before ## Runs"
  holds "$(section_of "$RECORD" 'Oracle changes')" '| Oracle file | What changes | Why |' "record ## Oracle changes"
  limits="$(section_of "$IMPLEMENTER" Limits)"
  holds "$limits" '## Oracle changes' "implementer ## Limits"
  holds "$limits" 'stops the task' "implementer ## Limits"
  holds "$limits" 'You never rewrite an oracle to make it pass.' "implementer ## Limits"
}

test_oracle_runs_with_its_task() {
  local section
  section="$(section_of "$DOCTRINE" 'No red-first while implementing')"
  holds "$section" "Disabling guards on purpose is the reviewer's job" "doctrine No red-first"
  holds "$section" 'an oracle test runs with the task that makes it passable' "doctrine No red-first"
  holds "$section" "another context than the code, the planner's" "doctrine No red-first"
}

test_adr_records_the_oracle() {
  require_file "$ADR"
  frontmatter "$ADR" | grep -qx 'status: accepted' || fail "ADR-0098 is not accepted"
  frontmatter "$ADR" | grep -qx 'supersedes: \[\]' || fail "ADR-0098 must supersede nothing"
  local options agent blind nothing outcome
  options="$(section_of "$ADR" 'Considered Options')"
  agent="$(grep -n -F 'Un agent oracle dédié' <<< "$options" | cut -d: -f1)"
  blind="$(grep -n -F 'Le relecteur en boîte noire' <<< "$options" | cut -d: -f1)"
  nothing="$(grep -n -F 'Ne rien changer' <<< "$options" | cut -d: -f1)"
  [ -n "$agent" ] && [ -n "$blind" ] && [ -n "$nothing" ] || fail "ADR-0098 lacks one of the options turned down"
  [ "$agent" -lt "$blind" ] && [ "$blind" -lt "$nothing" ] || fail "ADR-0098 options are out of order"
  [ "$(grep -o 'Écartée' <<< "$options" | wc -l)" -eq 3 ] || fail "ADR-0098 must turn down exactly three options"
  outcome="$(section_of "$ADR" 'Decision Outcome')"
  holds "$outcome" 'sans la remplacer' "ADR-0098 outcome"
  holds "$outcome" 'ADR-0052' "ADR-0098 outcome"
}
