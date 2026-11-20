#!/usr/bin/env bash
# s109 — a fleet lane keeps the guards of the single-story path.

DRIVE="$METHOD/commands/po-drive.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

# The body of one `### <heading>` subsection, stopping at the next `##` or `###` heading.
subsection_of() { awk -v h="### $2" '$0 == h {on=1; next} /^##/ {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

test_lane_checks_its_start_point() {
  require_file "$DRIVE"
  local prep; prep=$(subsection_of "$DRIVE" 'Preparing the lanes')
  [ -n "$prep" ] || fail "po-drive.md has no '### Preparing the lanes' subsection"
  holds "$(section_of "$DRIVE" 'Report')" 'the stories waiting for their framing pull request to merge' 'Report'
}

test_lone_decisions_are_all_logged() {
  require_file "$DRIVE"
  local dlog; dlog=$(section_of "$DRIVE" 'The decisions log')
  holds "$dlog" 'each implementation detail you settled without the person' 'drive decisions log'
  holds "$dlog" 'each answer you gave without asking' 'drive decisions log'
}
