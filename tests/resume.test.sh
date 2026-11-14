#!/usr/bin/env bash
# s29 — the driver resumes a fleet instead of restarting it.

DRIVE="$METHOD/commands/po-drive.md"

# The body of one `## <heading>` section, heading excluded; `###` subsections stay inside.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

test_drive_detects_an_orphan_worktree() {
  require_file "$DRIVE"
  local wave; wave=$(section_of "$DRIVE" 'A wave')
  [ -n "$wave" ] || fail "po-drive.md has no '## A wave' section"

  # Reported as found, dropped, and never repaired.
  holds "$wave" 'named in the report with the path and the branch actually found' 'the wave section'
  holds "$wave" 'drops that lane from the wave' 'the wave section'
  holds "$wave" 'no `git worktree add --force`, `worktree remove`, `worktree prune`, `switch`, `checkout` or `stash`' 'the wave section'
}
