#!/usr/bin/env bash
# s57 — the fleet runs QA for a story that goes to QA (s80), and a review blocked on QA goes back to QA.
# s64 — blocked on QA needs `Review status: blocked`, every command routes it alike, and a current uncommitted report is committed, not walked.

DRIVE="$METHOD/commands/po-drive.md"
STATUS="$METHOD/commands/po-status.md"
REVIEW="$METHOD/commands/po-review.md"
HELP="$METHOD/commands/po-help.md"
README="$ROOT/README.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

# Line number of the only line holding the phrase; fails when it is absent or ambiguous.
only_line() {
  local hits; hits=$(grep -nF -- "$2" <<< "$1" | cut -d: -f1)
  [ -n "$hits" ] || fail "$3 lacks: $2"
  [ "$(wc -l <<< "$hits")" -eq 1 ] || fail "$3 holds more than one line with: $2"
  echo "$hits"
}

before() { [ "$1" -lt "$2" ] || fail "$3"; }

test_drive_wave_includes_qa() {
  require_file "$DRIVE"
  local wave; wave=$(section_of "$DRIVE" 'A wave')
  local i q r
  i=$(only_line "$wave" 'subagent_type: implementer' 'the wave section')
  q=$(only_line "$wave" 'subagent_type: qa' 'the wave section')
  r=$(only_line "$wave" 'subagent_type: reviewer' 'the wave section')
  before "$i" "$q" "the qa dispatch must follow the implementer"
  before "$q" "$r" "the qa dispatch must precede the reviewer"
  local item; item=$(sed -n "${q}p" <<< "$wave")
  holds "$item" 'the prompt `/po-qa` fixes' 'the QA item'
  holds "$item" 'QA evidence' 'the QA item'
  holds "$item" '-- docs/qa/<id>/' 'the QA item'
  holds "$item" 'every qa of a wave leaves before any of them is waited on' 'the QA item'
  holds "$wave" 'then every implementer, then every qa, then every reviewer' 'the wave section'
}

test_status_reports_qa() {
  require_file "$STATUS"
  contains "$STATUS" '· record · qa · review ·'
}

test_help_and_readme_show_qa() {
  require_file "$HELP"; require_file "$README"
  local e q r
  e=$(grep -n '^| Exécution | `/po-execute`' "$README" | cut -d: -f1)
  q=$(grep -n '^| QA (story que `QA stage` envoie en QA) | `/po-qa` |' "$README" | cut -d: -f1)
  r=$(grep -n '^| Revue | `/po-review`' "$README" | cut -d: -f1)
  [ -n "$e" ] && [ -n "$q" ] && [ -n "$r" ] || fail "README.md cycle table needs Exécution, QA and Revue rows"
  before "$e" "$q" "the README QA row must follow Exécution"
  before "$q" "$r" "the README QA row must precede Revue"
  contains "$README" 'une revue bloquée par la QA repart vers `/po-qa` sans consommer de fix run'
}

test_qa_blocked_review_goes_back_to_qa() {
  require_file "$REVIEW"; require_file "$DRIVE"
  contains "$REVIEW" 'this review keeps the same `Fix loop:` value instead, because a QA return is not a fix run'
  contains "$REVIEW" 'Run /po-qa <id>, then /po-review <id> again; no fix run is spent.'
  contains "$REVIEW" '- Any other `Ship allowed: no` → "Ship blocked for <id>. Run /po-execute <id> (fix run)'
}

P1='`Review status: blocked` and a `Next action:` naming `/po-qa`'
P2='`Review status: blocked` and a `Next action:` naming the `<id>: QA evidence` commit'
M1='Review blocked on QA for <id>. Run /po-qa <id>, then /po-review <id> again; no fix run is spent.'
M2='Review blocked on uncommitted QA evidence for <id>. Commit it alone: git commit -m "<id>: QA evidence" -- docs/qa/<id>/, then /po-review <id> again; no fix run is spent.'

test_qa_blocked_needs_a_blocked_status() {
  require_file "$REVIEW"; require_file "$DRIVE"
  holds "$(section_of "$REVIEW" 'Preconditions')" "$P1" 'po-review.md preconditions'
  holds "$(section_of "$REVIEW" 'Preconditions')" "$P2" 'po-review.md preconditions'
  holds "$(section_of "$REVIEW" 'Outcome')" "- \`Ship allowed: no\` with $P1 → \"$M1\"" 'po-review.md outcome'
  holds "$(section_of "$REVIEW" 'Outcome')" "- \`Ship allowed: no\` with $P2 → \"$M2\"" 'po-review.md outcome'
  local f line
  for f in po-review po-drive po-execute po-status; do
    require_file "$METHOD/commands/$f.md"
    while IFS= read -r line; do
      grep -qF -- '`Review status: blocked`' <<< "$line" || fail "$f.md pairs \`Next action:\` and \`/po-qa\` without \`Review status: blocked\`: $line"
    done < <(grep -F -- '`Next action:`' "$METHOD/commands/$f.md" | grep -F -- '`/po-qa`')
  done
}

test_drive_resumes_on_an_uncommitted_report() {
  contains "$METHOD/hooks/po-gate.sh" 'is current but docs/qa/$1/ is not committed'
}
