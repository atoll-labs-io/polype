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
  for s in 'Steps to reproduce:' 'Capture:' 'Severity:' 'verified' 'probable' 'unverified'; do
    contains "$QA_TEMPLATE" "$s"
  done
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

test_qa_scope_comes_from_the_diff_and_the_criteria() {
  require_file "$QA_AGENT"
  contains "$QA_AGENT" 'git diff <Target branch>...story/<id>'
  contains "$QA_AGENT" 'each acceptance criterion'
  contains "$QA_AGENT" 'Nothing else is walked.'
  settings_read_by "$QA_AGENT" | grep -qx 'Target branch' || fail "qa.md does not declare it reads Target branch"
}

test_qa_stops_without_a_browser_or_a_dev_command() {
  require_file "$PO_QA"
  contains "$PO_QA" 'The story'\''s surface is `screen` and `Dev` is `—` → stop: the project has no command to start it'
  contains "$PO_QA" 'This command never writes a report: when the agent stops, there is none.'
  lacks_tool "$PO_QA" Write
  lacks_tool "$PO_QA" Edit
  needs_tool "$PO_QA" Agent
  contains "$QA_AGENT" 'The surface is `screen` and no tool in your session can open a page and capture it → stop and report it'
  contains "$QA_AGENT" 'write no report'
}

test_setup_asks_for_dev_and_qa_stage() {
  local template="$METHOD/templates/agents-local.md" setup="$METHOD/commands/po-setup.md" row step
  template_settings | grep -qx 'Dev' || fail "Dev is not a setting of agents-local.md"
  template_settings | grep -qx 'QA stage' || fail "QA stage is not a setting of agents-local.md"
  row="$(grep -m1 '^| QA stage |' "$template")"
  grep -qF '`screens`' <<< "$row" || fail "the QA stage row lacks \`screens\`: $row"
  grep -qF '`—`' <<< "$row" || fail "the QA stage row lacks \`—\`: $row"
  contains "$template" '`Dev` starts the development server'
  step="$(awk '/^## Step 2/ {on=1; next} /^## / {on=0} on' "$setup")"
  grep -qE '^[0-9]+\. .*`Dev`' <<< "$step" || fail "no numbered question of step 2 sets \`Dev\`"
  grep -vE '^[0-9]+\. ' <<< "$step" | grep -qF '`QA stage`' || fail "no follow-up of step 2 asks for \`QA stage\`"
  [ "$(grep -cE '^[0-9]+\. ' <<< "$step")" -eq 5 ] || fail "step 2 no longer has five numbered questions"
}

test_help_lists_po_qa() {
  contains "$METHOD/commands/po-help.md" '/po-qa'
}
