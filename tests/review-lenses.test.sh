#!/usr/bin/env bash
# s53 — review lenses triggered by the diff.

AGENT="$METHOD/agents/reviewer.md"
TPL="$METHOD/templates/review.md"

test_one_reviewer_one_verdict() {
  frontmatter "$AGENT" | grep -qx '  - review-lenses' || fail "reviewer must preload review-lenses"
  local f
  for f in "$METHOD"/agents/*.md; do
    [ "$f" = "$AGENT" ] && continue
    ! frontmatter "$f" | grep -qx '  - review-lenses' || fail "${f##*/} must not preload review-lenses"
  done
  lacks_tool "$AGENT" Write

  local n
  n=$(grep -c '^Max severity:' "$TPL"); [ "$n" -eq 1 ] || fail "template has $n 'Max severity:' lines"
  n=$(grep -c '^Ship allowed:' "$TPL"); [ "$n" -eq 1 ] || fail "template has $n 'Ship allowed:' lines"
}
