#!/usr/bin/env bash
# s28 — the diff of a story stays inside what it owns.

SKILL="$METHOD/skills/review-antihallu/SKILL.md"

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

test_qa_current_failure_names_an_uncommitted_report() {
  local step1; step1=$(awk '/^\*\*1\. / {on=1} /^\*\*2\. / {exit} on' "$SKILL")
  holds "$step1" 'git commit -m "<id>: QA evidence" -- docs/qa/<id>/' 'step 1'
}
