#!/usr/bin/env bash
# s52 — the QA report bound to the code: the qa-current gate, /po-qa's evidence commit, and the
# rules, reviewer and implementer that wire the QA stage into the story cycle.

GATE="$METHOD/hooks/po-gate.sh"
PO_QA="$METHOD/commands/po-qa.md"

sandbox() {
  scratch_repo
  cd "$SCRATCH"
  mkdir -p docs/qa/s01-a src
  echo 'x' > src/app.txt
  git add -A && git commit -qm init
}

passes() { bash "$GATE" "$@" 2>/dev/null; }

# A report bound to the tree HEAD has now; its body lines are given, its Tree: comes before them.
qa_report() {
  { echo '# QA — s01-a'; echo "Tree: $(git rev-parse 'HEAD^{tree}')"; printf '%b' "$1"; } > docs/qa/s01-a/report.md
  git add -A && git commit -qm qa
}

test_po_gate_qa_current() {
  sandbox
  ! passes qa-current s01-a || fail "missing report accepted"
  qa_report 'QA status: blocked\n'
  ! passes qa-current s01-a || fail "blocked report accepted"
  qa_report 'QA status: complete\n'
  passes qa-current s01-a || fail "complete report on the walked code refused"
  echo 'png' > docs/qa/s01-a/capture-1.png && git add -A && git commit -qm capture
  passes qa-current s01-a || fail "a docs-only commit after the walk invalidated the report"
  echo 'y' > src/app.txt && git commit -qam change
  local err; err="$(bash "$GATE" qa-current s01-a 2>&1)" && fail "report accepted after the code moved"
  grep -qF '/po-qa s01-a' <<< "$err" || fail "the refusal does not name /po-qa s01-a: $err"
}

test_qa_current_reads_the_last_status() {
  sandbox
  qa_report 'QA status: complete\nQuoted above; the walk then failed.\nQA status: blocked\n'
  ! passes qa-current s01-a || fail "an earlier complete status outweighed the final blocked one"
  qa_report 'QA status: complete, mostly\n'
  ! passes qa-current s01-a || fail "a qualified status accepted"
}

test_qa_current_needs_a_full_tree_hash() {
  sandbox
  local tree; tree="$(git rev-parse 'HEAD^{tree}')"
  printf 'QA status: complete\n' > docs/qa/s01-a/report.md && git add -A && git commit -qm qa
  ! passes qa-current s01-a || fail "report without Tree: accepted"
  printf 'Tree: %s\nQA status: complete\n' "${tree:0:12}" > docs/qa/s01-a/report.md && git add -A && git commit -qm qa
  ! passes qa-current s01-a || fail "abbreviated tree accepted"
  printf 'Tree: %s\nQA status: complete\n' "$(printf 'f%.0s' {1..40})" > docs/qa/s01-a/report.md && git add -A && git commit -qm qa
  ! passes qa-current s01-a || fail "unknown tree accepted"
}

# s60 — a current report counts only once docs/qa/<id>/ is in HEAD, captures included (ADR-0037).
test_qa_current_requires_a_committed_report() {
  sandbox
  local err
  { echo '# QA — s01-a'; echo "Tree: $(git rev-parse 'HEAD^{tree}')"; echo 'QA status: complete'; } > docs/qa/s01-a/report.md
  err="$(bash "$GATE" qa-current s01-a 2>&1)" && fail "an untracked report was accepted"
  grep -qF 'not committed' <<< "$err" || fail "the refusal does not say 'not committed': $err"
  git add -A
  ! passes qa-current s01-a || fail "a staged but uncommitted report was accepted"
  git commit -qm qa
  passes qa-current s01-a || fail "a committed current report was refused"
  echo 'png' > docs/qa/s01-a/capture-2.png
  ! passes qa-current s01-a || fail "an uncommitted capture beside the report was accepted"
}

# s67 — ignored files do not count (ADR-0044); an ignored, never-committed report is still refused.
test_qa_current_ignores_ignored_files() {
  sandbox
  local err
  echo '*.log' > .gitignore && git add -A && git commit -qm ignore
  qa_report 'QA status: complete\n'
  echo 'noise' > docs/qa/s01-a/walk.log
  passes qa-current s01-a || fail "an ignored file beside a committed report was refused"
  git rm -q --cached docs/qa/s01-a/report.md && git commit -qm unqa
  echo 'docs/qa/s01-a/report.md' >> .gitignore
  err="$(bash "$GATE" qa-current s01-a 2>&1)" && fail "an ignored, uncommitted report was accepted"
  grep -qF 'is ignored by git' <<< "$err" && grep -qF 'not committed' <<< "$err" \
    || fail "the refusal does not say the report is ignored and not committed: $err"
}

test_po_qa_commits_its_evidence() {
  needs_tool "$PO_QA" Bash
  lacks_tool "$PO_QA" Write
  lacks_tool "$PO_QA" Edit
  ! frontmatter "$PO_QA" | grep -qF 'run a shell' || fail "po-qa.md still says it cannot run a shell"
  contains "$PO_QA" 'commit -m "<id>: QA evidence" -- docs/qa/<id>/'
}
