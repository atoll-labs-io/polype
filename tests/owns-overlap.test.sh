#!/usr/bin/env bash
# s69, s72 — Owns overlap understands globs; the direction of the matching.

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

C8_AWK='/^\*\*8\./ {on=1; print; next} /^## |^\*\*[0-9]+\./ {on=0} on'
CITE2='the overlap rule of check 8 of the `stories-review` skill'

test_diff_paths_match_owns_exactly() {
  require_file "$ANTI"
  local s; s=$(section_of "$ANTI" 'Before anything: the diff stays inside `Owns`')
  holds "$s" 'A diff path is matched exactly against the entries of its own story' "review-antihallu scope section"
  holds "$s" "The doubt clause of the rule serves only the check against another story's \`Owns\`" "review-antihallu scope section"
  ! grep -qF 'It holds for both cases below' <<< "$s" || fail "old doubt-for-both-cases sentence is still there"
}

test_drive_reports_name_the_entries() {
  require_file "$DRIVE"
  local lines n
  lines=$(section_of "$DRIVE" 'Report' | grep -F 'the path that collided')
  n=$(grep -c . <<< "$lines")
  [ "$n" -ge 2 ] || fail "fewer than two Report lines name the path that collided"
  [ "$(grep -cF 'the two entries that overlapped and one path matching both' <<< "$lines")" = "$n" ] \
    || fail "a Report line names the path without the two entries"
}

test_every_overlap_text_cites_the_rule() {
  local f
  for f in AGENTS.md commands/po-stories.md commands/po-status.md templates/stories.md templates/stories-review.md; do
    require_file "$METHOD/$f"
    holds "$(cat "$METHOD/$f")" "$CITE2" "$f"
  done
  for f in commands/po-stories.md templates/stories.md templates/stories-review.md; do
    ! grep -qE 'sharing a path|no path shared' "$METHOD/$f" || fail "$f still words the rule as sharing a path"
  done
}

test_how_to_decide_reads_as_a_sentence() {
  require_file "$SREVIEW"
  local c8; c8=$(awk "$C8_AWK" "$SREVIEW")
  holds "$c8" 'one of these holds: two segments at the same position are different plain names;' "stories-review check 8"
  holds "$c8" 'a plain name meets a `*` segment that cannot take it' "stories-review check 8"
  ! grep -qF 'or a plain name that the other' <<< "$c8" || fail "old verbless clause is still there"
}
