#!/usr/bin/env bash
# s156 — the QA report comes back as text and the coordinator writes it.

QA_AGENT="$METHOD/agents/qa.md"
PO_QA="$METHOD/commands/po-qa.md"
DRIVE="$METHOD/commands/po-drive.md"
GATE="$METHOD/hooks/po-gate.sh"
ADR_NEW="$ROOT/docs/decisions/ADR-0102-le-rapport-de-qa-revient-en-texte.md"
ADR_OLD="$ROOT/docs/decisions/ADR-0029-po-qa-committe-les-preuves-qa.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

lacks() { ! grep -qF -- "$2" <<< "$1" || fail "$3 still holds: $2"; }

test_qa_returns_its_report() {
  require_file "$QA_AGENT"
  local report final
  report=$(section_of "$QA_AGENT" 'The report')
  final=$(section_of "$QA_AGENT" 'Your final message')
  holds "$final" 'Your final message is the report' 'qa.md, final message'
  holds "$report" 'return it whole as your final answer' 'qa.md, the report'
  holds "$report" 'Never write the report yourself' 'qa.md, the report'
  lacks "$report" 'into `docs/qa/<id>/report.md`.' 'qa.md, the report'
  lacks "$(cat "$QA_AGENT")" 'write the report with' 'qa.md'
  holds "$(section_of "$PO_QA" 'Report')" 'the path where it was written' 'po-qa.md, report'
}

test_po_qa_records_the_report() {
  require_file "$PO_QA"
  local commit
  commit=$(section_of "$PO_QA" 'The evidence commit')
  holds "$commit" 'word for word' 'po-qa.md, evidence commit'
  holds "$commit" 'you do not author it' 'po-qa.md, evidence commit'
  holds "$commit" 'No `QA status:` line → no report, no commit' 'po-qa.md, evidence commit'
  lacks_tool "$PO_QA" Write
  lacks_tool "$PO_QA" Edit
  contains "$PO_QA" 'Bash serves exactly two uses'
}

test_drive_records_the_report() {
  require_file "$DRIVE"
  local wave n item
  wave=$(section_of "$DRIVE" 'A wave')
  n=$(grep -cF 'subagent_type: qa' <<< "$wave")
  [ "$n" -eq 1 ] || fail "po-drive.md, a wave: expected one qa line, found $n"
  item=$(grep -F 'subagent_type: qa' <<< "$wave")
  holds "$item" 'no `QA status:` line' 'the QA item'
}

test_qa_report_path_stays() {
  require_file "$PO_QA"
  contains "$PO_QA" 'docs/qa/<id>/report.md'
  contains "$PO_QA" 'commit -m "<id>: QA evidence" -- docs/qa/<id>/'
  holds "$(section_of "$PO_QA" 'The evidence commit')" '`complete` or `blocked` alike' 'po-qa.md, evidence commit'
  holds "$(awk '/^qa_current\(\)/ {on=1} on && /^}/ {print; exit} on' "$GATE")" 'docs/qa/$1/report.md' 'qa_current of po-gate.sh'
}

test_adr_records_report_as_text() {
  require_file "$ADR_NEW"
  require_file "$ADR_OLD"
  local fm body
  fm=$(frontmatter "$ADR_NEW")
  holds "$fm" 'supersedes: [ADR-0029]' 'ADR-0102 frontmatter'
  holds "$fm" 'status: accepted' 'ADR-0102 frontmatter'
  body=$(awk 'n>=2; /^---$/ {n++}' "$ADR_NEW")
  holds "$body" 'ADR-0034' 'ADR-0102'
  holds "$body" "L'agent écrit le rapport par Bash" 'ADR-0102'
  holds "$body" 'Write pour `/po-qa`' 'ADR-0102'
  holds "$body" 'Renommer le rapport' 'ADR-0102'
  holds "$body" 'heredoc quoté' 'ADR-0102'
  fm=$(frontmatter "$ADR_OLD")
  holds "$fm" 'superseded-by: [ADR-0037, ADR-0102]' 'ADR-0029 frontmatter'
  holds "$fm" 'status: accepted' 'ADR-0029 frontmatter'
}
