#!/usr/bin/env bash
# s108 — a resumed ship merges the head it already pushed; the forge read pins its host and skips curlrc.

SHIP="$METHOD/commands/po-ship.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

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

test_forge_read_pins_and_skips_curlrc() {
  local forge probes
  forge=$(section_of "$SHIP" "The forge's review rule")
  holds "$forge" '`gh api`, pinned with `--hostname github.com`' "the forge section"
  probes=$(grep -F 'curl' <<< "$forge" | grep -F 'carries no token' || true)
  [ -n "$probes" ] || fail "no forge line says a curl carries no token"
  while IFS= read -r l; do
    holds "$l" '`curl -q`' "a tokenless curl line"
    ! grep -qF 'plain `curl`,' <<< "$l" || fail "a plain curl without -q remains"
  done <<< "$probes"
}
