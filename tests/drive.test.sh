#!/usr/bin/env bash
# s27 — the fleet driver.

DRIVE="$METHOD/commands/po-drive.md"
TEMPLATE="$METHOD/templates/agents-local.md"

# The body of one `## <heading>` section, heading excluded; `###` subsections stay inside.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

test_drive_picks_a_ready_set_without_conflicts() {
  require_file "$DRIVE"
  local ready; ready=$(section_of "$DRIVE" 'The ready set')
  [ -n "$ready" ] || fail "po-drive.md has no '## The ready set' section"

  # State read from the files, not from the driver's memory of the last wave.
  holds "$ready" 'derived the way `/po-status` derives it' 'the ready set'
  holds "$ready" 'never from what you remember of an earlier wave' 'the ready set'

  # The three readiness clauses, then the cap.
  holds "$ready" 'it is not shipped' 'the ready set'
  holds "$ready" 'every story it depends on is shipped' 'the ready set'
  holds "$ready" 'its `Owns` paths are disjoint from those of the lanes already running **and** from those of the other stories of the batch' 'the ready set'
  holds "$ready" 'stop at `Parallel` lanes' 'the ready set'

  # A dropped story is named with what it collided with, or the conflict is invisible.
  holds "$ready" 'named in the report with the path that collided' 'the ready set'
}

test_drive_dispatches_lanes_in_one_message() {
  require_file "$DRIVE"
  local wave; wave=$(section_of "$DRIVE" 'A wave')
  [ -n "$wave" ] || fail "po-drive.md has no '## A wave' section"

  holds "$wave" 'in a single message' 'the wave section'
  holds "$wave" 'one Agent call per lane, all of them in that one message' 'the wave section'
  holds "$wave" 'Never two calls for the same story at once' 'the wave section'

  # The driver prepares the lane itself: planner may not.
  holds "$wave" 'You prepare each lane'"'"'s worktree yourself' 'the wave section'
  holds "$wave" 'git worktree add -b story/<id>' 'the wave section'

  # The three subagents, in that order, each under the contract of its own command.
  local order; order=$(grep -o 'subagent_type: [a-z]*' <<< "$wave" | sed 's/subagent_type: //' | tr '\n' ' ')
  [ "$order" = "planner implementer reviewer " ] \
    || fail "expected planner then implementer then reviewer, found: $order"
  holds "$wave" 'the prompt `/po-execute` fixes' 'the wave section'
  holds "$wave" 'the prompt `/po-review` fixes' 'the wave section'
  holds "$wave" 'A plan without that line never reaches an implementer' 'the wave section'
}

test_drive_never_writes_code_or_verdicts() {
  require_file "$DRIVE"
  lacks_tool "$DRIVE" Write
  lacks_tool "$DRIVE" Edit
  needs_tool "$DRIVE" Agent
  needs_tool "$DRIVE" Bash
  contains "$DRIVE" 'You have neither Write nor Edit, so you write no code and decide no verdict'

  # Bash records the reviewer's answer; it does not author one.
  local verdict; verdict=$(section_of "$DRIVE" 'The verdict, and the fix runs')
  [ -n "$verdict" ] || fail "po-drive.md has no '## The verdict, and the fix runs' section"
  holds "$verdict" 'recorded **verbatim** into `docs/reviews/<id>.md`' 'the verdict section'
  holds "$verdict" 'You transcribe it, you do not author it' 'the verdict section'
  holds "$verdict" 'no severity is yours to choose, no finding yours to soften or drop' 'the verdict section'

  # The one exception, the blocked fallback /po-review mandates.
  holds "$verdict" 'answers without both verdict lines is recorded as `Review status: blocked`' 'the verdict section'
  holds "$verdict" '`Max severity: critical` and `Ship allowed: no`' 'the verdict section'
}

test_drive_ships_serially_after_each_review() {
  require_file "$DRIVE"
  local ships; ships=$(section_of "$DRIVE" 'Ships, one at a time')
  [ -n "$ships" ] || fail "po-drive.md has no '## Ships, one at a time' section"

  holds "$ships" 'Ships never overlap.' 'the ship section'
  holds "$ships" 'you ship one story, prove it, then ship the next' 'the ship section'
  holds "$ships" 'requires the repository root clean and on `Target branch`' 'the ship section'

  # The gate, read exactly as /po-ship reads it.
  holds "$ships" '`po-gate ship-allowed <id>` first' 'the ship section'
  holds "$ships" 'the **last** `Ship allowed:` line of `docs/reviews/<id>.md` must be `yes`' 'the ship section'
  holds "$ships" '`Ship confirmation: human` means one AskUserQuestion per merge' 'the ship section'

  # A blocked story loops back, within a bounded number of attempts.
  local verdict; verdict=$(section_of "$DRIVE" 'The verdict, and the fix runs')
  holds "$verdict" '`Ship allowed: no` sends that lane back to `implementer` as a fix run' 'the verdict section'
  holds "$verdict" 'at most `Max attempts` fix runs' 'the verdict section'
  holds "$verdict" 'it is listed for a human with its open findings' 'the verdict section'
}

test_settings_template_declares_fleet_settings() {
  require_file "$TEMPLATE"
  local name
  for name in Parallel 'Max attempts' Tracker; do
    template_settings | grep -qx "$name" || fail "missing from the settings template: $name"
    grep -q "^| $name | " "$TEMPLATE" || fail "no documented row for $name in the settings template"
  done

  # The defaults the story fixes.
  local fence; fence=$(awk '/^```/ {fence=!fence; next} fence' "$TEMPLATE")
  grep -qE '^Parallel:[[:space:]]+3$' <<< "$fence" || fail "Parallel must default to 3"
  grep -qE '^Max attempts:[[:space:]]+2$' <<< "$fence" || fail "Max attempts must default to 2"
  grep -qE '^Tracker:[[:space:]]+none$' <<< "$fence" || fail "Tracker must default to none"

  # `github` is declared as a value, not implemented here.
  grep -q '^| Tracker | .*`github`' "$TEMPLATE" || fail "the Tracker row must name the github value"
  contains "$METHOD/commands/po-drive.md" '`Tracker: github` → say that publishing to GitHub is not handled yet'
}

test_drive_lane_includes_design_when_the_story_has_a_screen() {
  require_file "$DRIVE"
  local wave; wave=$(section_of "$DRIVE" 'A wave')
  [ -n "$wave" ] || fail "po-drive.md has no '## A wave' section"

  # The stage sits between the plan and the code.
  local planner design implementer
  planner=$(grep -n -F 'subagent_type: planner' <<< "$wave" | cut -d: -f1 || true)
  design=$(grep -n -F '**The design stage**' <<< "$wave" | cut -d: -f1 || true)
  implementer=$(grep -n -F 'subagent_type: implementer' <<< "$wave" | cut -d: -f1 || true)
  [ -n "$design" ] || fail 'the wave section names no design stage'
  { [ "$planner" -lt "$design" ] && [ "$design" -lt "$implementer" ]; } \
    || fail "the design stage must sit between plan ($planner) and implementation ($implementer), found $design"

  # A stop, not a dispatch, and the reason is stated.
  holds "$wave" 'a command does not run inside a subagent (ADR-0016)' 'the wave section'
  holds "$wave" 'no design subagent exists' 'the wave section'
  holds "$wave" '`/po-design <id>` to run in `<Worktree root><id>`' 'the wave section'

  # Both of /po-design's own conditions, checked before the stop.
  holds "$wave" '`docs/design-system.md` missing there → the lane stops' 'the wave section'
  holds "$wave" '`Design source` at `—` → the lane stops' 'the wave section'

  # Never skipped to keep a lane moving.
  holds "$wave" 'The stage is never skipped' 'the wave section'
  holds "$wave" 'the implementer does not start' 'the wave section'

  # A resumed lane knows the stage exists.
  local resuming; resuming=$(section_of "$DRIVE" 'Resuming')
  [ -n "$resuming" ] || fail "po-drive.md has no '## Resuming' section"
  holds "$resuming" '`docs/designs/<id>/design.md` is absent | the design stage' 'the resuming table'

  settings_read_by "$DRIVE" | grep -qx 'Design source' \
    || fail 'po-drive.md does not declare it reads `Design source`'
}

# s33 — the parallelism the fleet promises.

test_drive_dispatches_a_whole_stage_in_one_message() {
  require_file "$DRIVE"
  local wave; wave=$(section_of "$DRIVE" 'A wave')
  [ -n "$wave" ] || fail "po-drive.md has no '## A wave' section"

  # The single message covers a whole stage, not just a pair of lanes.
  holds "$wave" 'This holds stage by stage' 'the wave section'
  holds "$wave" 'a stage is dispatched whole or not at all' 'the wave section'

  # The prohibition and what it costs when it is broken.
  holds "$wave" 'Sending one call per message is forbidden' 'the wave section'
  holds "$wave" 'the lanes run one after the other and `Parallel` buys nothing' 'the wave section'
}

test_drive_reports_what_it_observed_not_what_it_intended() {
  require_file "$DRIVE"
  local report; report=$(section_of "$DRIVE" 'Report')
  [ -n "$report" ] || fail "po-drive.md has no '## Report' section"

  holds "$report" 'per stage, how many subagents left together in the same message' 'the report section'
  holds "$report" 'reported as sequential, with the number of messages it took' 'the report section'
  holds "$report" 'claims that lanes ran at the same time unless they were dispatched in one message' 'the report section'
}

test_drive_uses_absolute_paths_only() {
  require_file "$DRIVE"

  # A backquoted `cd ` in the driver's own file is a permission to drift.
  local found; found=$(grep -nF -- '`cd ' "$DRIVE" || true)
  [ -z "$found" ] || fail "po-drive.md lets the driver change directory: $found"

  local wave; wave=$(section_of "$DRIVE" 'A wave')
  [ -n "$wave" ] || fail "po-drive.md has no '## A wave' section"
  holds "$wave" 'You never leave the directory you were started in' 'the wave section'
  holds "$wave" 'resolved once, as the absolute path `<repository root>/<Worktree root><id>`' 'the wave section'
  holds "$wave" 'every git command you run against a lane is `git -C <absolute path>`' 'the wave section'
  holds "$wave" 'every subagent prompt carries that same absolute path' 'the wave section'
}

test_shared_numbering_is_assigned_by_the_driver() {
  require_file "$DRIVE"
  local wave; wave=$(section_of "$DRIVE" 'A wave')
  [ -n "$wave" ] || fail "po-drive.md has no '## A wave' section"

  # The driver allocates before the wave leaves, one number per lane, never twice.
  holds "$wave" 'ADR numbers are a shared resource no `Owns` line can divide' 'the wave section'
  holds "$wave" 'you assign them before the wave leaves' 'the wave section'
  holds "$wave" 'hand each lane of the wave its own number, the following ones in sequence' 'the wave section'
  holds "$wave" 'a number is never handed to a second lane of the same wave' 'the wave section'

  # The planner takes what it was handed and invents none.
  local planner="$METHOD/agents/planner.md"
  require_file "$planner"
  contains "$planner" 'The number is not yours to choose'
  contains "$planner" 'use the one the driver reserved for this lane in the message you received'
  contains "$planner" 'create no file whose name you invented'
}
