#!/usr/bin/env bash
# s156 — the QA report comes back as text and the coordinator writes it.

QA_AGENT="$METHOD/agents/qa.md"
PO_QA="$METHOD/commands/po-qa.md"
GATE="$METHOD/hooks/po-gate.sh"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

test_qa_returns_its_report() {
  require_file "$QA_AGENT"
  local report
  report=$(section_of "$QA_AGENT" 'The report')
  holds "$report" 'Never write the report yourself' 'qa.md, the report'
}

test_qa_report_path_stays() {
  require_file "$PO_QA"
  contains "$PO_QA" 'docs/qa/<id>/report.md'
  contains "$PO_QA" 'commit -m "<id>: QA evidence" -- docs/qa/<id>/'
  holds "$(awk '/^qa_current\(\)/ {on=1} on && /^}/ {print; exit} on' "$GATE")" 'docs/qa/$1/report.md' 'qa_current of po-gate.sh'
}
