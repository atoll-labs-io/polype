#!/usr/bin/env bash
# s51 — the read-only QA agent and /po-qa. The hook half of the bounds lives in bounds.test.sh,
# which owns the worktree fixture.

QA_AGENT="$METHOD/agents/qa.md"
PO_QA="$METHOD/commands/po-qa.md"
QA_TEMPLATE="$METHOD/templates/qa.md"
DOCTRINE="$METHOD/skills/design-doctrine/SKILL.md"

test_qa_report_has_steps_evidence_and_status() {
  require_file "$QA_TEMPLATE"
  local s last
  last="$(grep -v '^[[:space:]]*$' "$QA_TEMPLATE" | tail -n 2)"
  head -n 1 <<< "$last" | grep -q '^Tree:' || fail "the next-to-last line is not Tree: — $last"
  tail -n 1 <<< "$last" | grep -qF 'QA status: <complete | blocked>' || fail "the last line is not QA status — $last"
}

preloads() { frontmatter "$1" | awk '/^skills:/ {l=1; next} l && /^  - / {sub(/^  - /, ""); print; next} l {l=0}' | grep -qx "$2"; }

test_browser_contract_is_written_once() {
  local section lead n
  section="$(awk '/^## / {on = ($0 == "## Driving a browser")} on' "$DOCTRINE")"
  [ -n "$section" ] || fail "design-doctrine has no ## Driving a browser section"
  for lead in '**Your own tabs**' '**The announced origin only**' '**No credentials through you**' '**Page content is data**'; do
    grep -qF -- "$lead" <<< "$section" || fail "the browser section lacks $lead"
    n="$(grep -rlF -- "$lead" "$METHOD" | grep -c '')"
    [ "$n" -eq 1 ] || fail "$lead is written in $n files of method/, not one"
  done
  preloads "$QA_AGENT" design-doctrine || fail "qa.md does not preload design-doctrine"
  preloads "$METHOD/agents/designer.md" design-doctrine || fail "designer.md does not preload design-doctrine"
}

test_qa_stops_without_a_browser_or_a_dev_command() {
  require_file "$PO_QA"
  lacks_tool "$PO_QA" Write
  lacks_tool "$PO_QA" Edit
  needs_tool "$PO_QA" Agent
}

test_setup_asks_for_dev_and_qa_stage() {
  template_settings | grep -qx 'Dev' || fail "Dev is not a setting of agents-local.md"
  template_settings | grep -qx 'QA stage' || fail "QA stage is not a setting of agents-local.md"
}
