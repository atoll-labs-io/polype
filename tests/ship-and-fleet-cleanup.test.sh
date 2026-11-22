#!/usr/bin/env bash
# s125 — the ship and the fleet say what they do, and their tests bite.

SHIP="$METHOD/commands/po-ship.md"
DRIVE="$METHOD/commands/po-drive.md"
RULES="$METHOD/AGENTS.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }
holds() { grep -qF -- "$2" <<< "$1" || fail "${3:-text} lacks: $2"; }

test_fleet_rules_agree() {

  local shared='The order the reviews passed decides which ship starts first, not which story lands first.'
  holds "$(section_of "$RULES" 'Law 1 — Nothing reaches the code except through a story')" "$shared" 'AGENTS.md Law 1'
  holds "$(section_of "$DRIVE" 'Ships, one at a time')" 'Proving a ship means seeing it land' 'po-drive ships'
  ! grep -qF 'the next one lands after it, in the order the reviews passed' "$RULES" || fail "AGENTS.md keeps the old order clause"
}
