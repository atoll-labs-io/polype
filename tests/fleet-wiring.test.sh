#!/usr/bin/env bash
# s31 — rules, help and status know about the fleet.

RULES="$METHOD/AGENTS.md"
HELP="$METHOD/commands/po-help.md"
STATUS="$METHOD/commands/po-status.md"
MATRIX="$ROOT/docs/parite-killer-saas.md"

# The body of one `## <heading>` section, heading excluded; `###` subsections stay inside.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

# The body of one numbered step, from its bold title to the next numbered step.
step_of() {
  awk -v t="**$2.**" '
    index($0, t) && /^[0-9]+\. / {on = 1}
    on && /^[0-9]+\. / && !index($0, t) {exit}
    on
  ' "$1"
}

reads_setting() { settings_read_by "$1" | grep -qx "$2" || fail "${1##*/} does not read $2"; }

test_rules_describe_the_fleet() {
  require_file "$RULES"
  local law; law=$(section_of "$RULES" 'Law 1 — Nothing reaches the code except through a story')
  [ -n "$law" ] || fail "AGENTS.md has no Law 1 section"

  # One driver, one lane per ready story, the lanes advancing together.
  holds "$law" '`/po-drive` is one driver' 'Law 1'
  holds "$law" 'one lane per ready story and advances those lanes at the same time' 'Law 1'
  holds "$law" '`/po-drive status`' 'Law 1'

  # Ships stay serial, on the target branch, in review order.
  holds "$law" '**Ships stay serial**' 'Law 1'
  holds "$law" 'lands on `Target branch` alone' 'Law 1'
  holds "$law" 'in the order the reviews passed' 'Law 1'

  # `Owns` bounds a lane, and two lanes never share a path.
  holds "$law" 'the `Owns` line of a story fixes the paths its lane may change' 'Law 1'
  holds "$law" 'two stories sharing one of those paths never run at once' 'Law 1'
}

test_help_lists_po_drive() {
  require_file "$HELP"
  # `tests/pilot.test.sh` already proves `/po-drive` appears somewhere; what the
  # cheat sheet hides is the read-only mode and what the fleet entry promises.
  contains "$HELP" '`/po-drive` — la flotte : fait avancer en parallèle toutes les stories prêtes, une lane par story, et ship une par une.'
  contains "$HELP" '`/po-drive status`'
  contains "$HELP" 'ce qui est en vol, ce qui attend et pourquoi'
  contains "$HELP" 'ne lance rien'
}

test_status_shows_lanes_and_attempts() {
  require_file "$STATUS"
  reads_setting "$STATUS" 'Parallel'
  reads_setting "$STATUS" 'Max attempts'

  local fleet; fleet=$(step_of "$STATUS" 'Fleet')
  [ -n "$fleet" ] || fail "po-status.md has no Fleet step"

  # A lane is a worktree on its own story branch, counted against the cap.
  holds "$fleet" 'a worktree `<Worktree root><id>` whose `git -C <Worktree root><id> rev-parse --abbrev-ref HEAD` prints `story/<id>`' 'the fleet step'
  holds "$fleet" 'against `Parallel`' 'the fleet step'

  # Attempts come from the review file, never from memory.
  holds "$fleet" 'the `Fix loop:` line of `docs/reviews/<id>.md`' 'the fleet step'
  holds "$fleet" 'against `Max attempts`' 'the fleet step'

  # The four reasons /po-drive can block on.
  holds "$fleet" 'a dependency not shipped and which one' 'the fleet step'
  holds "$fleet" 'an `Owns` collision' 'the fleet step'
  holds "$fleet" '`Max attempts` reached' 'the fleet step'
  holds "$fleet" 'an orphan worktree' 'the fleet step'

  # A setting that cannot be read stops the section instead of being guessed.
  holds "$fleet" 'print no fleet section' 'the fleet step'
  holds "$fleet" 'neither is replaced by a guess' 'the fleet step'
}

test_parity_matrix_reflects_the_fleet() {
  require_file "$MATRIX"
  local id row status
  for id in A02 D05 D09 D16 D17; do
    row=$(grep -m1 "^| $id |" "$MATRIX") || fail "no row $id in the parity matrix"
    # Last cell of the row: the status.
    status=$(sed 's/ *|[[:space:]]*$//; s/.*| *//' <<< "$row")
    case "$status" in
      "fait — "*) ;;
      *) fail "$id is not done: $status" ;;
    esac
  done
  # D17 no longer claims the fleet state comes from a tracker (ADR-0016).
  grep -q "^| D17 .*État dérivé des worktrees et de git (ADR-0016)" "$MATRIX" \
    || fail "D17 must derive the state from the worktrees and git"
}
