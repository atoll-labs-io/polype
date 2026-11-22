#!/usr/bin/env bash
# s158 — the oracle of the story: whoever records a review writes its title and link line,
# the reviewer answers below them (ADR-0104, issue #169).

TPL="$METHOD/templates/review.md"
LINK="$ROOT/bin/po-link-artifacts"

test_template_marks_the_header() {
  require_file "$TPL"
  [ "$(head -n 1 "$TPL")" = '# Review — <id>' ] || fail "review.md does not open with its title"
  local link
  link="$(awk 'NR > 1 && NF {print; exit}' "$TPL")"
  [ "$link" = '[Story](../stories.md) · [Plan](../plans/<id>.md) · [Verification](../verif/<id>.md)' ] \
    || fail "the link line under the title changed: $link"

  # A file recorded as the rule says — the template's two header lines, then an answer without
  # any title — is one po-link-artifacts already counts as linked.
  local d; d="$(mktemp -d)"
  trap "rm -rf '$d'" EXIT
  mkdir -p "$d/docs/reviews" "$d/docs/plans" "$d/docs/verif"
  : > "$d/docs/stories.md"
  printf -- '---\nvalidated: yes\n---\n# Plan — s01-a\n' > "$d/docs/plans/s01-a.md"
  printf '# Verification — s01-a\n' > "$d/docs/verif/s01-a.md"
  {
    awk 'NF {print; if (++n == 2) exit}' "$TPL" | sed 's/<id>/s01-a/g' | awk 'NR == 2 {print ""} {print}'
    printf '\nReview status: complete\nFix loop: 0\n\n## Findings\n- minor — a.sh:1 — style\n\nMax severity: minor\nShip allowed: yes\n'
  } > "$d/docs/reviews/s01-a.md"
  [ "$(sed -n 3p "$d/docs/reviews/s01-a.md")" = '[Story](../stories.md) · [Plan](../plans/s01-a.md) · [Verification](../verif/s01-a.md)' ] \
    || fail "the recorded header is not the template's: $(sed -n 1,3p "$d/docs/reviews/s01-a.md")"
  local out; out="$(bash "$LINK" "$d")" || fail "po-link-artifacts failed on the recorded review"
  ! grep -qx 'docs/reviews/s01-a.md' <<< "$out" || fail "po-link-artifacts still finds the recorded review unlinked"
}
