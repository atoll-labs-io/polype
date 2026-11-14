#!/usr/bin/env bash
# s27 — the fleet driver.

DRIVE="$METHOD/commands/po-drive.md"
TEMPLATE="$METHOD/templates/agents-local.md"

# The body of one `## <heading>` section, heading excluded; `###` subsections stay inside.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

test_drive_dispatches_lanes_in_one_message() {
  require_file "$DRIVE"
  local wave; wave=$(section_of "$DRIVE" 'A wave')
  [ -n "$wave" ] || fail "po-drive.md has no '## A wave' section"

  holds "$wave" 'The lanes of a wave must **overlap in time**' 'the wave section'
  holds "$wave" 'every subagent of a stage is started before any of them is waited on' 'the wave section'
  holds "$wave" 'Never two calls for the same story at once' 'the wave section'

  # The driver prepares the lane itself: planner may not.
  holds "$wave" 'You prepare each lane'"'"'s worktree yourself' 'the wave section'
  holds "$wave" 'git worktree add -b story/<id>' 'the wave section'

  # The five subagents of a lane, in that order, each under the contract of its own file.
  local order; order=$(grep -o 'subagent_type: [a-z]*' <<< "$wave" | sed 's/subagent_type: //' | tr '\n' ' ')
  [ "$order" = "planner designer implementer qa reviewer " ] \
    || fail "expected planner then designer then implementer then qa then reviewer, found: $order"
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
  holds "$ships" 'the **last** `Ship allowed:` line of `docs/reviews/<id>.md` must be `yes` **and** its `Reviewed tree:` must still match the code outside `docs/`' 'the ship section'
  holds "$ships" '`Ship confirmation: human` means one AskUserQuestion per merge under `Merge mode: local`, and a pull request left for a person under `Merge mode: pr`' 'the ship section'
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

# s33 — the parallelism the fleet promises.

test_drive_requires_overlapping_lanes_not_a_message_shape() {
  require_file "$DRIVE"
  local wave; wave=$(section_of "$DRIVE" 'A wave')
  [ -n "$wave" ] || fail "po-drive.md has no '## A wave' section"

  # What is owed is overlap, over a whole stage, and what proves it.
  holds "$wave" 'must **overlap in time**' 'the wave section'
  holds "$wave" 'This holds stage by stage' 'the wave section'
  holds "$wave" 'a stage is started whole' 'the wave section'
  holds "$wave" "activity window" 'the wave section'
  holds "$wave" 'overlaps nothing, and `Parallel` buys nothing there' 'the wave section'

  # No shape is imposed, and the reason the old measure was wrong is stated.
  holds "$wave" 'No dispatch shape is imposed' 'the wave section'
  holds "$wave" 'a subagent starts in the background and hands the call back at once' 'the wave section'

  # The abandoned requirement must be gone from the whole file, not just from this section.
  local shape; shape=$(grep -n -F -e 'in a single message' -e 'dispatched in one message' "$DRIVE" || true)
  [ -z "$shape" ] || fail "po-drive.md still requires a dispatch shape: $shape"
}

test_drive_reports_what_it_observed_not_what_it_intended() {
  require_file "$DRIVE"
  local report; report=$(section_of "$DRIVE" 'Report')
  [ -n "$report" ] || fail "po-drive.md has no '## Report' section"

  holds "$report" 'per stage, the activity window of each lane' 'the report section'
  holds "$report" 'when its subagent started and when it answered' 'the report section'
  holds "$report" 'A stage whose windows do not overlap is reported as sequential' 'the report section'
  holds "$report" 'claims that lanes ran at the same time unless their activity windows show it' 'the report section'
  holds "$report" 'the number of messages the dispatch took is not evidence of anything' 'the report section'
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

test_planner_writes_only_its_documents_and_the_adr_assigned_to_it() {
  local planner="$METHOD/agents/planner.md"
  require_file "$planner"
  local limits; limits=$(section_of "$planner" 'Limits')
  [ -n "$limits" ] || fail "planner.md has no '## Limits' section"

  # The three files it may write, the ADR conditioned on the reservation, nothing else.
  holds "$limits" '`docs/research/<id>.md`, `docs/plans/<id>.md` and, when the driver reserved a number for this lane, the ADR that number names' 'the planner limits'
  holds "$limits" 'and no other file' 'the planner limits'
  holds "$limits" 'No source file, no test file, no commit' 'the planner limits'

  # The old wording forbade the very ADR the next paragraph orders: it must be gone.
  local contradiction
  contradiction=$(grep -n -F 'and `docs/plans/<id>.md`, and no other file' "$planner" || true)
  [ -z "$contradiction" ] || fail "planner.md still forbids the ADR it is told to write: $contradiction"

  # A resumed lane finds its research done: the planner reuses it instead of rewriting it.
  local contracts; contracts=$(section_of "$planner" 'The contracts you carry')
  holds "$contracts" 'a `docs/research/<id>.md` that exists is this lane'"'"'s research' 'the planner contracts'
  holds "$contracts" 'read it, build the plan on it, and never write that file again' 'the planner contracts'
}
