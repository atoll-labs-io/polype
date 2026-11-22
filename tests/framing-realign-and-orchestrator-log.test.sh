#!/usr/bin/env bash
# s121 — realigning the root forces nothing, and a merged framing branch is deleted only by its own next landing.

SETUP="$METHOD/commands/po-setup.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

base_block() {
  section_of "$SETUP" 'Landing the framing' |
    awk '/^\*\*Base\.\*\*/ {on=1} /^\*\*The commit, built beside the checkout\*\*/ {on=0} on'
}

test_every_landing_realigns_the_root() {
  require_file "$SETUP"
  local b; b=$(base_block)
  [ -n "$b" ] || fail "po-setup.md has no Base block in its landing section"
  holds "$b" 'no stash, checkout or reset forces it' 'Base'
  local land; land=$(section_of "$SETUP" 'Landing the framing')
  holds "$land" 'is deleted only by the next landing on that same slug' 'the human bullet'
}
