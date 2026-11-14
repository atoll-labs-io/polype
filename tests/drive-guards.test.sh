#!/usr/bin/env bash
# s109 — a fleet lane keeps the guards of the single-story path.

DRIVE="$METHOD/commands/po-drive.md"
ORCH="$METHOD/commands/po-orchestrator.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

# The body of one `### <heading>` subsection, stopping at the next `##` or `###` heading.
subsection_of() { awk -v h="### $2" '$0 == h {on=1; next} /^##/ {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

test_lane_checks_its_start_point() {
  require_file "$DRIVE"
  local prep; prep=$(subsection_of "$DRIVE" 'Preparing the lanes')
  [ -n "$prep" ] || fail "po-drive.md has no '### Preparing the lanes' subsection"
  grep -qF 'git worktree add -b story/<id>' <<< "$prep" || fail "Preparing the lanes lost its git worktree add"
  holds "$(section_of "$DRIVE" 'Report')" 'the stories waiting for their framing pull request to merge' 'Report'
}

test_lone_decisions_are_all_logged() {
  require_file "$DRIVE"
  require_file "$ORCH"
  local dlog; dlog=$(section_of "$DRIVE" 'The decisions log')
  holds "$dlog" 'each implementation detail you settled without the person' 'drive decisions log'
  holds "$dlog" 'each answer you gave without asking' 'drive decisions log'

  local olog; olog=$(section_of "$ORCH" 'The decisions log')
  [ -n "$olog" ] || fail "po-orchestrator.md has no '## The decisions log' section"
  local s
  for s in 'Plan validation: autonomous' 'each fix run it started' '`/po-flow`' \
           'templates/decisions-log.md' 'Landing the framing' 'slug `decisions-log`' \
           'never before its ship'; do
    holds "$olog" "$s" 'orchestrator decisions log'
  done

  local stage8 heading
  stage8=$(grep -n -m1 '^## Stage 8' "$ORCH" | cut -d: -f1)
  heading=$(grep -n -m1 -Fx '## The decisions log' "$ORCH" | cut -d: -f1)
  [ -n "$stage8" ] || fail "po-orchestrator.md lost its Stage 8"
  [ "$heading" -gt "$stage8" ] || fail "the orchestrator decisions log comes before Stage 8"
}
