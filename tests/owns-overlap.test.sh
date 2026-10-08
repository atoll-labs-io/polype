#!/usr/bin/env bash
# s69 — Owns overlap understands globs.

DRIVE="$METHOD/commands/po-drive.md"
SREVIEW="$METHOD/skills/stories-review/SKILL.md"
ANTI="$METHOD/skills/review-antihallu/SKILL.md"
RTEMPLATE="$METHOD/templates/review.md"

RULE='Two `Owns` entries overlap when one path could match both: a folder `x/` covers every path beneath it, `*` matches within one path segment, `**` matches any number of segments; when in doubt, they overlap.'
CITE='the examples of check 8 of the `stories-review` skill'

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }
holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

test_overlap_rule_covers_globs() {
  local f
  for f in "$DRIVE" "$SREVIEW" "$ANTI" "$RTEMPLATE"; do require_file "$f"; done
  holds "$(section_of "$DRIVE" 'The ready set')" "$RULE" "po-drive ready set"
  holds "$(awk '/^\*\*8\./ {on=1; print; next} /^## |^\*\*[0-9]+\./ {on=0} on' "$SREVIEW")" "$RULE" "stories-review check 8"
  holds "$(section_of "$ANTI" 'Before anything: the diff stays inside `Owns`')" "$RULE" "review-antihallu scope section"
  holds "$(section_of "$RTEMPLATE" 'Ownership')" "overlap rule" "review template Ownership"
}

test_overlap_examples_are_written_once() {
  require_file "$SREVIEW"
  local c8; c8=$(awk '/^\*\*8\./ {on=1; print; next} /^## |^\*\*[0-9]+\./ {on=0} on' "$SREVIEW")
  grep -F 'crates/*/Cargo.toml' <<< "$c8" | grep -F 'crates/core/' | grep -qF 'overlap' \
    || fail "check 8 lacks the crates example marked overlap"
  grep -F 'src/a/*.ts' <<< "$c8" | grep -F 'src/b/' | grep -qF 'disjoint' \
    || fail "check 8 lacks the src/a example marked disjoint"
  local ex files
  for ex in 'crates/*/Cargo.toml' 'src/a/*.ts'; do
    files=$(grep -rlF -- "$ex" "$METHOD")
    [ "$files" = "$SREVIEW" ] || fail "'$ex' must live only in stories-review, found: $files"
  done
  holds "$(section_of "$DRIVE" 'The ready set')" "$CITE" "po-drive ready set"
  holds "$(section_of "$ANTI" 'Before anything: the diff stays inside `Owns`')" "$CITE" "review-antihallu scope section"
}
