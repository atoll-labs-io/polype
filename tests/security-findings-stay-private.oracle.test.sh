#!/usr/bin/env bash
# s178 — the oracle of the story: `po record review` keeps the text of a security finding out of the
# repository. The review holds a count and a decision id; the text sits under `Private folder`, in
# the file the sensitive decision's context names. `fix_run_still_reads_them` speaks to a model: judged in review.

WITNESS="zq-witness-7f3k"

# The s167 fixture ($F project, $W worktree on story/$ID, rec, in_order), an inbox git ignores, a
# Private folder in the scratch dir (ADR-0123), and HOME there too so nothing reaches the developer's.
secure_fixture() {
  source "$ROOT/tests/record-writes-reports.oracle.test.sh"
  need_po; fixture
  export HOME="$SCRATCH/home"
  mkdir -p "$HOME" "$SCRATCH/in"
  printf 'Decision inbox: .polype/inbox/\nPrivate folder: %s/private/\n' "$SCRATCH" >> "$F/AGENTS.local.md"
  printf '.polype/inbox/\n' >> "$F/.gitignore"
  git -C "$F" add -A && git -C "$F" commit -q -m inbox
}

# answer <file> <findings> <max severity> <ship allowed> [fix loop]
answer() {
  cat > "$1" <<EOF
Review status: complete
Fix loop: ${5:-0}
Reviewed tree: $(git -C "$W" rev-parse "story/$ID^{tree}")

## Lenses
Lenses run: security — src/a.sh

## Findings
$2

## Not verified
none

Max severity: $3
Ship allowed: $4
EOF
}

SECURE_FINDINGS="- critical — [security] — src/a.sh:1 — $WITNESS one
  $WITNESS continued under the item
- minor — src/b.sh:2 — style
- major — [security] — src/c.sh:3 — $WITNESS two"

gate() { local rc=0; (cd "$W" && bash .polype/hooks/po-gate.sh "$1" "$ID" >/dev/null 2>&1) || rc=$?; echo "$rc"; }

decisions() { find "$F/.polype/inbox" -name 'd-*.json' 2>/dev/null | grep -c . || true; }

# The id the count line names; fails when the review holds no single count line.
count_line_id() {
  local lines; lines="$(grep -E '^Security findings: [0-9]+ — decision d-[0-9]+$' "$1")" \
    || fail "the review holds no 'Security findings: <n> — decision <id>' line"
  [ "$(grep -c . <<< "$lines")" -eq 1 ] || fail "the review holds several count lines: $lines"
  [ "$(sed -E 's/^Security findings: ([0-9]+) .*/\1/' <<< "$lines")" = "$2" ] || fail "the count line is not $2: $lines"
  sed -E 's/.* — decision (d-[0-9]+)$/\1/' <<< "$lines"
}

test_security_findings_are_marked() {
  secure_fixture
  local a="$SCRATCH/in/answer.txt" bad
  for bad in "- critical: [security] src/a.sh:1 $WITNESS" "- [security] — major — src/a.sh:1 — $WITNESS"; do
    answer "$a" "$bad
- minor — src/b.sh:2 — style" critical no
    rec "$W" "$a" record review "$ID"
    one_object "a misplaced [security] mark"
    [ "$STATUS" -eq 1 ] || fail "a misplaced [security] mark exited $STATUS, not 1: $OUT"
    jq -e '.error == "security-shape" and .written == false' <<< "$OUT" >/dev/null \
      || fail "a misplaced [security] mark is not refused as security-shape, written false: $OUT"
    ! grep -qF "$WITNESS" <<< "$OUT" || fail "the refusal repeats the finding's text"
    [ ! -e "$W/docs/reviews/$ID.md" ] || fail "a refused answer still wrote the review"
    [ "$(decisions)" -eq 0 ] || fail "a refused answer still posted a decision"
    ! grep -rlF --exclude-dir=in --exclude-dir=.git "$WITNESS" "$SCRATCH" >/dev/null \
      || fail "a refused answer left its text on disk: $(grep -rlF --exclude-dir=in --exclude-dir=.git "$WITNESS" "$SCRATCH")"
  done
}

test_recorded_review_holds_a_count_and_an_id() {
  secure_fixture
  local a="$SCRATCH/in/answer.txt" file="$W/docs/reviews/$ID.md" id decision context
  answer "$a" "$SECURE_FINDINGS" critical no
  rec "$W" "$a" record review "$ID"
  [ "$STATUS" -eq 0 ] || fail "po record review exited $STATUS on well-marked security findings: $OUT"
  require_file "$file"
  ! grep -qF "$WITNESS" "$file" || fail "the review holds the text of a security finding"
  ! grep -qF '[security]' "$file" || fail "the review still holds a marked item"
  grep -qxF -- '- minor — src/b.sh:2 — style' "$file" || fail "the ordinary finding left the review"
  id="$(count_line_id "$file" 2)"
  decision="$(cd "$W" && "$PO" inbox "$id")" || fail "po inbox $id does not show the decision the review names"
  jq -e '.sensitive == true and .motive == "security" and .status == "pending"' <<< "$decision" >/dev/null \
    || fail "the decision is not a pending sensitive one of motive security: $decision"
  ! grep -qF "$WITNESS" <<< "$decision" || fail "the decision itself carries the finding's text"
  context="$(jq -r '.context // empty' <<< "$decision")"
  case "$context" in /*) ;; *) fail "the decision's context is not an absolute path: $context" ;; esac
  case "$context/" in "$F"/*) fail "the text lies inside the repository: $context" ;; esac
  case "$context" in "$SCRATCH/private/"*) ;; *) fail "the text is not under the Private folder: $context" ;; esac
  require_file "$context"
  [ "$(grep -cF "$WITNESS" "$context")" -eq 3 ] || fail "the file the context names does not hold both findings whole"
}

test_nothing_reaches_git() {
  secure_fixture
  local a="$SCRATCH/in/answer.txt"
  answer "$a" "$SECURE_FINDINGS" critical no
  rec "$W" "$a" record review "$ID"
  [ "$STATUS" -eq 0 ] || fail "po record review exited $STATUS: $OUT"
  ! grep -rlF --exclude-dir=.git "$WITNESS" "$F" >/dev/null \
    || fail "the text is in the project's tree: $(grep -rlF --exclude-dir=.git "$WITNESS" "$F")"
  git -C "$W" add -A
  ! git -C "$W" grep -q --cached -F "$WITNESS" || fail "the text reached the worktree's index"
  git -C "$W" commit -q -m "$ID: review"
  ! git -C "$W" log -p --all | grep -qF "$WITNESS" || fail "the text reached a commit"
}

test_verdict_still_counts_them() {
  secure_fixture
  local a="$SCRATCH/in/answer.txt" file="$W/docs/reviews/$ID.md" secure plain
  answer "$a" "- critical — [security] — src/a.sh:1 — $WITNESS" critical no
  rec "$W" "$a" record review "$ID"
  [ "$STATUS" -eq 0 ] || fail "po record review exited $STATUS: $OUT"
  grep -qx 'Max severity: critical' "$file" || fail "Max severity: critical is gone from the review"
  [ "$(grep -E '^Ship allowed:' "$file" | tail -n 1)" = 'Ship allowed: no' ] || fail "Ship allowed: no is gone"
  [ "$(gate findings-shape)" -eq 0 ] || fail "findings-shape refuses the review once the findings are moved out"
  secure="$(gate ship-allowed)"
  rm -f "$file"
  answer "$a" "- critical — src/a.sh:1 — an ordinary finding" critical no
  rec "$W" "$a" record review "$ID"
  plain="$(gate ship-allowed)"
  [ "$secure" -eq "$plain" ] && [ "$secure" -ne 0 ] \
    || fail "ship-allowed gives $secure on a critical security finding, $plain on the whole review"

  rm -f "$file"
  answer "$a" "- major — [security] — src/c.sh:3 — $WITNESS" major yes
  rec "$W" "$a" record review "$ID"
  [ "$STATUS" -eq 0 ] || fail "po record review exited $STATUS: $OUT"
  [ "$(gate ship-allowed)" -eq 0 ] || fail "a major security finding with Ship allowed: yes no longer ships"
}

test_earlier_reviews_read_the_same() {
  secure_fixture
  local a="$SCRATCH/in/answer.txt" file="$W/docs/reviews/$ID.md" old="$SCRATCH/in/old.md"
  answer "$a" "- minor — src/a.sh:1 — the security lens ran on this line, nothing more" minor yes
  rec "$W" "$a" record review "$ID"
  [ "$STATUS" -eq 0 ] || fail "po record review exited $STATUS on an answer with no mark: $OUT"
  in_order "$file" "$a" "an answer with no [security] mark"
  ! grep -q '^Security findings:' "$file" || fail "an answer with no mark got a count line"
  [ "$(decisions)" -eq 0 ] || fail "an answer with no mark posted a decision"
  [ "$(gate findings-shape)" -eq 0 ] && [ "$(gate ship-allowed)" -eq 0 ] \
    || fail "the gates no longer pass a review recorded the way it was before"
  cp "$file" "$old"

  answer "$a" "$SECURE_FINDINGS" critical no 1
  rec "$W" "$a" record review "$ID"
  [ "$STATUS" -eq 0 ] || fail "po record review exited $STATUS on the next loop: $OUT"
  head -c "$(wc -c < "$old")" "$file" | cmp -s - "$old" || fail "recording a later loop changed the earlier block"
}

# Word counts before s178 (LC_ALL=C wc -w); the ceilings of tests/record-writes-reports.test.sh hold too.
test_words_hold() {
  local f limit words
  for f in templates/review.md:557 commands/po-review.md:1147 commands/po-execute.md:850 \
    agents/reviewer.md:1120 agents/implementer.md:1144 skills/review-lenses/SKILL.md:824 \
    skills/review-antihallu/SKILL.md:1605 templates/agents-local.md:1115 hooks/po-gate.sh:5843; do
    limit="${f##*:}"; words="$(LC_ALL=C wc -w < "$METHOD/${f%:*}")"
    [ "$words" -le "$limit" ] || fail "${f%:*} holds $words words, more than the $limit it held before s178"
  done
}
