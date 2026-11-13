#!/usr/bin/env bash
# s167 — the oracle of the story: `po record review|qa <id>`, run in the story worktree, reads the
# subagent's answer on stdin and writes the report itself: the template's header, the method version,
# the answer, the shape and oracle checks (issues #202, #172, #180, #181, #186, #191, #193).

ID=s01-a

need_po() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO (tests/run.sh builds it before the suite)"
}

# rec <dir> <answer file> <args...>: runs po there with the answer on stdin; sets OUT and STATUS.
rec() {
  local dir="$1" answer="$2"; shift 2
  STATUS=0
  OUT="$(cd "$dir" && "$PO" "$@" < "$answer" 2>/dev/null)" || STATUS=$?
}

one_object() {
  [ "$(jq -s 'length' <<< "$OUT" 2>/dev/null)" = 1 ] || fail "$1: stdout is not one JSON value: $OUT"
  jq -e 'type == "object" and .contract == 1' <<< "$OUT" >/dev/null \
    || fail "$1: not an object carrying \"contract\": 1: $OUT"
}

# The n-th non-empty line of a template, <id> replaced: 1 the title, 2 the link line.
header_line() { awk -v n="$2" 'NF && ++k == n {print; exit}' "$METHOD/templates/$1.md" | sed "s/<id>/$ID/g"; }

# Every line of <answer> appears in <file>, in the same order (po may add lines, never drop or change one).
in_order() {
  awk 'NR == FNR {want[++n] = $0; next} i < n && $0 == want[i + 1] {i++} END {exit i == n ? 0 : 1}' "$2" "$1" \
    || fail "$3: the answer is not in $1 word for word, in order"
}

# $F: a Polype project on main; $W: its worktree on story/$ID, holding a committed plan whose oracle
# file is intact, and a verification record. The gate and the templates are the method's own.
fixture() {
  SCRATCH="$(mktemp -d)"
  trap 'rm -rf "$SCRATCH"' EXIT
  SCRATCH="$(cd "$SCRATCH" && pwd -P)"
  F="$SCRATCH/project"; W="$F/.worktrees/$ID"
  mkdir -p "$F/.polype/hooks" "$F/.polype/templates" "$F/docs"
  git -C "$F" init -q -b main
  git -C "$F" config user.email test@example.com
  git -C "$F" config user.name test
  git -C "$F" config commit.gpgsign false
  cp "$METHOD/hooks/po-gate.sh" "$F/.polype/hooks/po-gate.sh"
  cp "$METHOD/templates/review.md" "$METHOD/templates/qa.md" "$F/.polype/templates/"
  printf '9.9.9-oracle\n' > "$F/.polype/version"
  printf '# fixture\n\n```\nTarget branch:     main\nWorktree root:     .worktrees/\n```\n' > "$F/AGENTS.local.md"
  printf '# Stories\n\n### %s — fixture\n- **Surface** : command\n' "$ID" > "$F/docs/stories.md"
  printf '.worktrees/\n' > "$F/.gitignore"
  git -C "$F" add -A && git -C "$F" commit -q -m init
  git -C "$F" worktree add -q -b "story/$ID" "$W" main
  mkdir -p "$W/docs/plans" "$W/docs/verif" "$W/tests"
  printf 'test_a() { :; }\n' > "$W/tests/a.oracle.test.sh"
  local sum; sum="$(cksum < "$W/tests/a.oracle.test.sh" | awk '{print $1 " " $2}')"
  printf -- '---\nvalidated: yes\n---\n# Plan — %s\n\n## Acceptance tests\n\n| Oracle file | cksum |\n| --- | --- |\n| `tests/a.oracle.test.sh` | `%s` |\n\n## Tasks\n1. [x] a\n' \
    "$ID" "$sum" > "$W/docs/plans/$ID.md"
  printf '# Verification — %s\n' "$ID" > "$W/docs/verif/$ID.md"
  git -C "$W" add -A && git -C "$W" commit -q -m "$ID: fixture"
}

# A reviewer's answer in the shape of templates/review.md: no title, no link line.
review_answer() {
  cat > "$1" <<EOF
Diff reviewed: \`git diff main...story/$ID\`, in a context that did not write it.

Review status: complete
Fix loop: ${2:-0}
Reviewed tree: $(git -C "$W" rev-parse "story/$ID^{tree}")

## Tests
- [x] Floor: \`po-gate floor-guard $ID main\` → 0 nothing lowered

## Findings
${3:-- minor — src/a.sh:1 — style}

## Not verified
none

Max severity: minor
Ship allowed: yes
EOF
}

# A qa answer as the subagent returns it: from the template's title down to its QA status line.
qa_answer() {
  { header_line qa 1; echo; header_line qa 2; echo; printf '%s' "${2:-}"
    printf 'Scope: the command.\n\n## Not seen\n- nothing\n\nTree: %s\n' "$(git -C "$W" rev-parse "story/$ID^{tree}")"
    [ "${3:-with-status}" = no-status ] || printf 'QA status: complete\n'
  } > "$1"
}

test_record_writes_header_then_answer() {
  need_po; fixture
  local answer="$SCRATCH/review.txt" file="$W/docs/reviews/$ID.md"
  review_answer "$answer"
  rec "$W" "$answer" record review "$ID"
  one_object "po record review"
  [ "$STATUS" -eq 0 ] || fail "po record review exited $STATUS on a well-shaped answer: $OUT"
  require_file "$file"
  [ "$(awk 'NF && ++k == 1 {print; exit}' "$file")" = "$(header_line review 1)" ] \
    || fail "the review does not open with the template's title: $(head -n 1 "$file")"
  [ "$(awk 'NF && ++k == 2 {print; exit}' "$file")" = "$(header_line review 2)" ] \
    || fail "the review's second line is not the template's link line: $(awk 'NF && ++k == 2 {print; exit}' "$file")"
  in_order "$file" "$answer" "the review"

  local qa="$SCRATCH/qa.txt" report="$W/docs/qa/$ID/report.md"
  qa_answer "$qa"
  rec "$W" "$qa" record qa "$ID"
  one_object "po record qa"
  [ "$STATUS" -eq 0 ] || fail "po record qa exited $STATUS: $OUT"
  require_file "$report"
  [ "$(grep -cxF -- "$(header_line qa 1)" "$report")" -eq 1 ] || fail "the QA title is not there exactly once"
  [ "$(grep -cxF -- "$(header_line qa 2)" "$report")" -eq 1 ] || fail "the QA link line is not there exactly once"
  [ "$(awk 'NF && ++k == 1 {print; exit}' "$report")" = "$(header_line qa 1)" ] || fail "the QA report does not open with its title"
  in_order "$report" <(awk 'NF && ++k > 2 || k > 2' "$qa") "the QA report"
}

test_record_stamps_the_method_version() {
  need_po; fixture
  local answer="$SCRATCH/review.txt" file="$W/docs/reviews/$ID.md"
  review_answer "$answer"
  rec "$W" "$answer" record review "$ID"
  [ "$STATUS" -eq 0 ] || fail "po record review exited $STATUS: $OUT"
  [ "$(grep -c '^Method version:' "$file")" -eq 1 ] || fail "the review holds $(grep -c '^Method version:' "$file") Method version lines, not 1"
  grep -qx 'Method version: 9.9.9-oracle' "$file" || fail "the stamp is not .polype/version: $(grep '^Method version:' "$file")"

  # A version the subagent writes into its header is not the stamp; re-recording the report onto
  # itself, as a resume path does, stamps it once again and doubles nothing.
  local qa="$SCRATCH/qa.txt" report="$W/docs/qa/$ID/report.md" again="$SCRATCH/again.txt"
  qa_answer "$qa" $'Method version: 0.0.0-forged\n\n'
  rec "$W" "$qa" record qa "$ID"
  [ "$STATUS" -eq 0 ] || fail "po record qa exited $STATUS: $OUT"
  cp "$report" "$again"
  rec "$W" "$again" record qa "$ID"
  [ "$STATUS" -eq 0 ] || fail "po record qa on its own report exited $STATUS: $OUT"
  [ "$(grep -c '^Method version:' "$report")" -eq 1 ] || fail "the QA report holds $(grep -c '^Method version:' "$report") Method version lines, not 1"
  grep -qx 'Method version: 9.9.9-oracle' "$report" || fail "the QA stamp is not .polype/version: $(grep '^Method version:' "$report")"
  [ "$(grep -cxF -- "$(header_line qa 1)" "$report")" -eq 1 ] || fail "re-recording doubled the QA title"
}

test_record_checks_the_shape() {
  need_po; fixture
  local answer="$SCRATCH/review.txt" file="$W/docs/reviews/$ID.md" gate=0
  review_answer "$answer" 0 '### F1: major. src/a.sh:1 is wrong'
  rec "$W" "$answer" record review "$ID"
  one_object "po record review on a heading finding"
  require_file "$file"
  (cd "$W" && bash .polype/hooks/po-gate.sh findings-shape "$ID" >/dev/null 2>&1) || gate=$?
  [ "$gate" -eq 1 ] || fail "the fixture is wrong: findings-shape exits $gate on a heading finding"
  [ "$STATUS" -eq "$gate" ] || fail "po record review exited $STATUS, findings-shape exits $gate"

  local qa="$SCRATCH/qa.txt"
  qa_answer "$qa" '' no-status
  rec "$W" "$qa" record qa "$ID"
  one_object "po record qa without QA status"
  [ "$STATUS" -eq 1 ] || fail "po record qa exited $STATUS on an answer without a QA status line"
  [ ! -e "$W/docs/qa/$ID/report.md" ] || fail "po record qa wrote a report from an answer without a QA status line"
}

test_record_refuses_the_wrong_branch() {
  need_po; fixture
  local answer="$SCRATCH/review.txt" qa="$SCRATCH/qa.txt"
  review_answer "$answer"; qa_answer "$qa"
  rec "$F" "$answer" record review "$ID"
  one_object "po record review on main"
  [ "$STATUS" -eq 2 ] || fail "po record review on main exited $STATUS"
  rec "$F" "$qa" record qa "$ID"
  [ "$STATUS" -eq 2 ] || fail "po record qa on main exited $STATUS"
  rec "$W" "$answer" record review s02-b
  one_object "po record review for another story"
  [ "$STATUS" -eq 2 ] || fail "po record review s02-b on story/$ID exited $STATUS"
  rec "$W" "$qa" record qa s02-b
  [ "$STATUS" -eq 2 ] || fail "po record qa s02-b on story/$ID exited $STATUS"
  [ -z "$(find "$F/docs" "$W/docs" \( -path '*/reviews/*' -o -path '*/qa/*' \) -type f 2>/dev/null)" ] \
    || fail "a refused record wrote under docs/reviews or docs/qa"
  [ -z "$(git -C "$W" status --porcelain)" ] || fail "a refused record left the worktree dirty: $(git -C "$W" status --porcelain)"
  rec "$F" "$answer" record review "$ID"
  jq -e '.error == "wrong-branch"' <<< "$OUT" >/dev/null || fail "the refusal is not wrong-branch: $OUT"
  rec "$W" "$answer" record review "$ID"
  [ "$STATUS" -eq 0 ] || fail "on story/$ID itself po record review exited $STATUS: $OUT"
}

# The ## Tests section of the last recorded block.
last_tests() { awk '/^## Tests[[:space:]]*$/ {on = 1; s = ""; next} /^## / {on = 0} on {s = s $0 "\n"} END {printf "%s", s}' "$1"; }

test_record_notes_the_oracle_gate() {
  need_po; fixture
  local answer="$SCRATCH/review.txt" file="$W/docs/reviews/$ID.md" gate=0
  (cd "$W" && bash .polype/hooks/po-gate.sh oracle-intact "$ID" >/dev/null 2>&1) || gate=$?
  [ "$gate" -eq 0 ] || fail "the fixture is wrong: oracle-intact exits $gate on an intact oracle"
  review_answer "$answer"
  rec "$W" "$answer" record review "$ID"
  [ "$STATUS" -eq 0 ] || fail "po record review exited $STATUS: $OUT"
  grep -qF -- "- Oracle: \`po-gate oracle-intact $ID\` → exit 0" <<< "$(last_tests "$file")" \
    || fail "## Tests lacks the oracle line with exit 0: $(last_tests "$file")"

  # The oracle file changes on the branch with no row in ## Oracle changes: the gate exits 1, and the
  # next recorded review says so under its own ## Tests.
  printf 'test_a() { true; }\n' > "$W/tests/a.oracle.test.sh"
  git -C "$W" commit -q -am "$ID: weaken the oracle"
  gate=0
  (cd "$W" && bash .polype/hooks/po-gate.sh oracle-intact "$ID" >/dev/null 2>&1) || gate=$?
  [ "$gate" -eq 1 ] || fail "the fixture is wrong: oracle-intact exits $gate on a changed oracle"
  review_answer "$answer" 1
  rec "$W" "$answer" record review "$ID"
  [ "$STATUS" -eq 0 ] || fail "po record review of fix loop 1 exited $STATUS: $OUT"
  grep -qF -- "- Oracle: \`po-gate oracle-intact $ID\` → exit 1" <<< "$(last_tests "$file")" \
    || fail "the last ## Tests lacks the oracle line with exit 1: $(last_tests "$file")"
}
