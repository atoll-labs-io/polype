#!/usr/bin/env bash
# s108 — a resumed ship merges the head it already pushed.

SHIP="$METHOD/commands/po-ship.md"

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

test_resumed_ship_merges_the_pushed_head() {
  local step2 phrase skip merge mline
  step2=$(awk '/^## Step 2/ {on=1} /^## Step 3/ {on=0} on' "$SHIP")
  phrase='When the push is skipped, `<sha>` becomes that head'
  holds "$step2" 'git rev-parse origin/story/<id>' "Step 2"
  holds "$step2" "$phrase" "Step 2"
  skip=$(grep -nF -- "$phrase" <<< "$step2" | head -n 1)
  holds "${skip#*:}" 'Skip the push' "the skip bullet"
  merge=$(grep -nF 'gh pr merge' <<< "$step2" | head -n 1)
  mline=${merge%%:*}
  [ "${skip%%:*}" -lt "$mline" ] || fail "the rebinding of <sha> must come before gh pr merge"
  holds "${merge#*:}" '--match-head-commit <sha>' "the merge line"
}

