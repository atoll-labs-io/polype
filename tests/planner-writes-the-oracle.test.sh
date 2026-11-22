#!/usr/bin/env bash
# s149 — the planner writes the story's acceptance tests, the oracle, in files of their own;
# the implementer changes them only through a logged reason the reviewer judges (ADR-0098).

PLAN="$METHOD/templates/plan.md"
PLAN_FLOW="$METHOD/templates/plan-flow.md"
RECORD="$METHOD/templates/verification-record.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

line_of() { grep -nx -- "$2" "$1" | head -n1 | cut -d: -f1; }

test_plan_lists_its_oracle() {
  local f name oracle section
  for f in "$PLAN" "$PLAN_FLOW"; do
    require_file "$f"
    name="${f#"$ROOT"/}"
    oracle="$(line_of "$f" '## Acceptance tests')"
    [ -n "$oracle" ] || fail "$name has no ## Acceptance tests heading"
    section="$(section_of "$f" 'Acceptance tests')"
    holds "$section" '| Oracle file | cksum |' "$name ## Acceptance tests"
  done
}

test_implementer_keeps_the_oracle() {
  local changes runs
  changes="$(line_of "$RECORD" '## Oracle changes')"
  runs="$(line_of "$RECORD" '## Runs')"
  [ -n "$changes" ] && [ "$changes" -lt "$runs" ] || fail "the record template lacks ## Oracle changes before ## Runs"
  holds "$(section_of "$RECORD" 'Oracle changes')" '| Oracle file | What changes | Why |' "record ## Oracle changes"
}
