#!/usr/bin/env bash
# s52 — the QA report bound to the code: the qa-current gate, /po-qa's evidence commit, and the
# rules, reviewer and implementer that wire the QA stage into the story cycle.

GATE="$METHOD/hooks/po-gate.sh"
RULES="$METHOD/AGENTS.md"
PO_QA="$METHOD/commands/po-qa.md"
REVIEWER="$METHOD/agents/reviewer.md"
IMPLEMENTER="$METHOD/agents/implementer.md"
SKILL="$METHOD/skills/review-antihallu/SKILL.md"
REVIEW_TEMPLATE="$METHOD/templates/review.md"

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
  printf 'QA status: complete\n' > docs/qa/s01-a/report.md
  ! passes qa-current s01-a || fail "report without Tree: accepted"
  printf 'Tree: %s\nQA status: complete\n' "${tree:0:12}" > docs/qa/s01-a/report.md
  ! passes qa-current s01-a || fail "abbreviated tree accepted"
  printf 'Tree: %s\nQA status: complete\n' "$(printf 'f%.0s' {1..40})" > docs/qa/s01-a/report.md
  ! passes qa-current s01-a || fail "unknown tree accepted"
}

test_rules_list_qa_in_the_story_cycle() {
  local table execute qa review
  table="$(awk '/^### Per story/ {on=1; next} on && /^### / {exit} on && /^\|/' "$RULES")"
  execute="$(grep -n '`/po-execute`' <<< "$table" | cut -d: -f1)"
  qa="$(grep -n '`/po-qa`' <<< "$table" | cut -d: -f1)"
  review="$(grep -n '`/po-review`' <<< "$table" | cut -d: -f1)"
  [ -n "$qa" ] || fail "the per-story table has no /po-qa row"
  [ "$execute" -lt "$qa" ] && [ "$qa" -lt "$review" ] || fail "the /po-qa row is not between Execute and Review"
  grep '`/po-qa`' <<< "$table" | grep -qF '`QA stage` is `screens`' || fail "the /po-qa row does not name QA stage: screens"
}

test_po_qa_commits_its_evidence() {
  needs_tool "$PO_QA" Bash
  lacks_tool "$PO_QA" Write
  lacks_tool "$PO_QA" Edit
  ! frontmatter "$PO_QA" | grep -qF 'run a shell' || fail "po-qa.md still says it cannot run a shell"
  contains "$PO_QA" 'commit -m "<id>: QA evidence" -- docs/qa/<id>/'
  contains "$RULES" '`/po-qa` commits `docs/qa/<id>/` alone'
}

test_review_requires_a_current_qa_report() {
  settings_read_by "$REVIEWER" | grep -qx 'QA stage' || fail "reviewer.md does not declare it reads QA stage"
  awk '/^\*\*1\. / {on=1} /^\*\*2\. / {exit} on' "$SKILL" | grep -qF 'po-gate qa-current <id>' \
    || fail "po-gate qa-current is not in step 1 of review-antihallu"
  contains "$SKILL" '→ the review is blocked, the gate'"'"'s message as `Failure cause:`'
  contains "$SKILL" 'each **verified** finding of the report is still open and becomes a finding of this review'
  contains "$SKILL" '`docs/designs/<id>/`, `docs/qa/<id>/`. No `Owns`'
  awk '/^## Evidence reused/ {on=1; next} on && /^## / {exit} on' "$REVIEW_TEMPLATE" | grep -qF 'po-gate qa-current <id>' \
    || fail "review.md's Evidence reused section has no qa-current box"
}

test_implementer_hands_the_screen_to_qa() {
  settings_read_by "$IMPLEMENTER" | grep -qx 'QA stage' || fail "implementer.md does not declare it reads QA stage"
  contains "$IMPLEMENTER" '**If a task produces a screen, open it in a browser before you finish**'
  contains "$IMPLEMENTER" 'When `QA stage` is `screens`, the walk of the screen belongs to the QA stage: `/po-qa`'
}
