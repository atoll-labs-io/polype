#!/usr/bin/env bash
# s167 — beside the oracle: the blocked report recorded unchecked, a header link to a missing file
# dropped, and the five commands that hand their recording to `po record` shorter than before.

# The oracle's fixture and helpers, loaded only inside a test so its own tests are not counted here.
oracle_helpers() { source "$ROOT/tests/record-writes-reports.oracle.test.sh"; }

test_composed_report_is_not_checked() {
  oracle_helpers; need_po; fixture
  local answer="$SCRATCH/blocked.txt" file="$W/docs/reviews/$ID.md"
  printf 'Review status: blocked\n\n## When blocked\n- Failure cause: the reviewer stopped\n\nMax severity: critical\nShip allowed: no\n' > "$answer"
  rec "$W" "$answer" record review "$ID" --composed
  one_object "po record review --composed"
  [ "$STATUS" -eq 0 ] || fail "a composed blocked report exited $STATUS: $OUT"
  in_order "$file" "$answer" "the composed report"
  ! grep -q -- '- Oracle:' "$file" || fail "a composed report got an oracle line"
}

# Word counts before s167 (LC_ALL=C wc -w): each command that hands its recording to po loses words.
test_commands_lose_words() {
  local f limit words
  for f in po-review:1244 po-qa:724 po-orchestrator:1908 po-flow:1572 po-drive:5470; do
    limit="${f#*:}"; words="$(LC_ALL=C wc -w < "$METHOD/commands/${f%%:*}.md")"
    [ "$words" -lt "$limit" ] || fail "${f%%:*}.md holds $words words, not fewer than $limit"
  done
  words="$(LC_ALL=C wc -w < "$METHOD/templates/review.md")"
  [ "$words" -le 558 ] || fail "templates/review.md grew to $words words, past 558"
}

test_missing_link_is_dropped() {
  oracle_helpers; need_po; fixture
  git -C "$W" rm -q "docs/verif/$ID.md" && git -C "$W" commit -q -m "$ID: no record"
  local answer="$SCRATCH/review.txt" file="$W/docs/reviews/$ID.md"
  review_answer "$answer"
  rec "$W" "$answer" record review "$ID"
  [ "$STATUS" -eq 0 ] || fail "po record review exited $STATUS: $OUT"
  local links; links="$(grep '^\[Story\](' "$file")" || fail "the review has no link line"
  ! grep -qF '[Verification]' <<< "$links" || fail "the link to a missing record stayed: $links"
  grep -qF "[Plan](../plans/$ID.md)" <<< "$links" || fail "the link to the plan went with it: $links"
}
