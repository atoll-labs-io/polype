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
  holds "$prep" 'git show <start point>:docs/stories.md' 'Preparing the lanes'

  # The check must come before the worktree is created; offsets work across one line or several.
  local show add
  show=$(grep -bo -m1 -F 'git show <start point>:docs/stories.md' <<< "$prep" | head -1 | cut -d: -f1)
  add=$(grep -bo -m1 -F 'git worktree add -b story/<id>' <<< "$prep" | head -1 | cut -d: -f1)
  [ -n "$add" ] || fail "Preparing the lanes lost its git worktree add"
  [ "$show" -lt "$add" ] || fail "the start-point check comes after git worktree add"

  holds "$prep" 'waiting for its framing pull request to merge' 'Preparing the lanes'
  holds "$prep" 'gets no worktree' 'Preparing the lanes'
  holds "$prep" 'other lanes carry on' 'Preparing the lanes'
  holds "$(section_of "$DRIVE" 'Report')" 'the stories waiting for their framing pull request to merge' 'Report'
}

test_pr_wait_needs_effective_human() {
  require_file "$DRIVE"
  local resuming open_row ship_row
  resuming=$(section_of "$DRIVE" 'Resuming')
  open_row=$(grep -F 'printing `OPEN`' <<< "$resuming")
  [ "$(grep -c . <<< "$open_row")" -eq 1 ] || fail "Resuming needs exactly one OPEN row"
  holds "$open_row" 'an effective `Ship confirmation` of `human`' 'the OPEN row'

  # The ship row stays the unconditional fallthrough.
  ship_row=$(grep -F 'is `yes` | the ship' <<< "$resuming")
  [ -n "$ship_row" ] || fail "Resuming lost its ship row"
  ! grep -qF 'Ship confirmation' <<< "$ship_row" || fail "the ship row gained a Ship confirmation condition"
  ! grep -qF 'OPEN' <<< "$ship_row" || fail "the ship row gained an OPEN condition"

  holds "$resuming" 'Under an effective `automatic`, an open pull request matches neither the waiting row nor the closed row' 'Resuming'
  holds "$resuming" 'resumes at the ship' 'Resuming'
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
