#!/usr/bin/env bash
# s29 — the driver resumes a fleet instead of restarting it.

DRIVE="$METHOD/commands/po-drive.md"

# The body of one `## <heading>` section, heading excluded; `###` subsections stay inside.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

test_drive_resumes_from_what_exists() {
  require_file "$DRIVE"
  local resuming; resuming=$(section_of "$DRIVE" 'Resuming')
  [ -n "$resuming" ] || fail "po-drive.md has no '## Resuming' section"

  # The stage is derived from what is on disk, and only for the stories the ready set kept.
  holds "$resuming" 'A wave never sends a story back to stage one' 'the resuming section'
  holds "$resuming" 'For each story the ready set kept' 'the resuming section'
  holds "$resuming" 'derive the stage it reached from the files of `<Worktree root><id>` and from git' 'the resuming section'

  # A record is a reached stage only when the gate accepts it.
  holds "$resuming" '`po-gate plan-validated <id>` passes, no record or `po-gate verif-current <id>` fails | the code stage' 'the resuming table'
  holds "$resuming" '`po-gate verif-current <id>` is what tells a record from a stale one' 'the resuming section'

  # A blocked review resumes at the next loop; a shipped story resumes at nothing.
  holds "$resuming" 'a fix run, at loop `Fix loop:` + 1' 'the resuming table'
  holds "$resuming" 'nothing — the story is done' 'the resuming table'

  # Attempts live in the review file, not in the driver's memory.
  holds "$resuming" 'read from the `Fix loop:` line of `docs/reviews/<id>.md`' 'the resuming section'
  holds "$resuming" 'never from what you remember of this session' 'the resuming section'
  holds "$resuming" '`Max attempts` counts the loops of every session together' 'the resuming section'

  # Nothing already recorded is redone to produce a cleaner file.
  holds "$resuming" 'A stage already recorded is resumed, never replayed.' 'the resuming section'
  holds "$resuming" 'No research, plan, record or review is overwritten' 'the resuming section'

  # Resuming is decided before the lanes are prepared, so the section comes before the wave.
  local order; order=$(grep -n '^## \(Resuming\|A wave\)$' "$DRIVE" | sed 's/^[0-9]*://' | tr '\n' '|')
  [ "$order" = '## Resuming|## A wave|' ] || fail "expected '## Resuming' before '## A wave', found: $order"
}

test_drive_status_reports_lanes() {
  require_file "$DRIVE"
  local report; report=$(section_of "$DRIVE" 'Report')
  [ -n "$report" ] || fail "po-drive.md has no '## Report' section"

  # status launches nothing and writes nothing.
  holds "$report" 'no subagent is dispatched, nothing is shipped, no `docs/reviews/<id>.md` is written' 'the report section'
  holds "$report" 'no gate that could change a file is run' 'the report section'

  # The lanes in flight, with the attempts already spent.
  holds "$report" 'the stage it resumes at, its worktree path, and the loops already spent against `Max attempts`' 'the report section'

  # What each blocked story waits for.
  holds "$report" 'a dependency not shipped and which one' 'the report section'
  holds "$report" 'an `Owns` collision with the path that collided and the lane holding it' 'the report section'
  holds "$report" '`Max attempts` reached with the open findings' 'the report section'
  holds "$report" 'an orphan worktree as it was found' 'the report section'
}

test_drive_detects_an_orphan_worktree() {
  require_file "$DRIVE"
  local wave; wave=$(section_of "$DRIVE" 'A wave')
  [ -n "$wave" ] || fail "po-drive.md has no '## A wave' section"

  # Both axes: the branch of the path, and the path of the branch.
  holds "$wave" 'confirmed on two axes, never repaired' 'the wave section'
  holds "$wave" 'rev-parse --abbrev-ref HEAD` must print `story/<id>`' 'the wave section'
  holds "$wave" '`git worktree list --porcelain` must show `story/<id>` checked out at `<Worktree root><id>` and at no other path' 'the wave section'
  holds "$wave" 'a `story/<id>` registered somewhere else' 'the wave section'

  # Reported as found, dropped, and never repaired.
  holds "$wave" 'named in the report with the path and the branch actually found' 'the wave section'
  holds "$wave" 'drops that lane from the wave' 'the wave section'
  holds "$wave" 'no `git worktree add --force`, `worktree remove`, `worktree prune`, `switch`, `checkout` or `stash`' 'the wave section'
}
