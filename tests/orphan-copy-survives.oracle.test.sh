#!/usr/bin/env bash
# s188 — an AGENTS.md.before-polype that Polype did not set aside itself survives every run.
# Every run happens in a throwaway directory, with a throwaway HOME and CLAUDE_CONFIG_DIR.

POLYPE="$ROOT/bin/polype"

orphan_sandbox() {
  scratch_repo
  export HOME="$SCRATCH/home"
  export CLAUDE_CONFIG_DIR="$HOME/.claude"
  mkdir -p "$CLAUDE_CONFIG_DIR"
}

# Sets OUT and STATUS; never fails by itself.
orphan_run() {
  case "${CLAUDE_CONFIG_DIR-}" in
    "$SCRATCH"/*) ;;
    *) fail "refusing to run: CLAUDE_CONFIG_DIR is '${CLAUDE_CONFIG_DIR-unset}', not inside $SCRATCH" ;;
  esac
  STATUS=0
  OUT="$(bash "$POLYPE" "$@" 2>&1)" || STATUS=$?
}

orphan_ok() { orphan_run "$@"; [ "$STATUS" -eq 0 ] || fail "polype $* failed ($STATUS): $OUT"; }

orphan_project() {
  local dir="$SCRATCH/$1"
  mkdir -p "$dir"
  git -C "$dir" init -q -b main
  printf '%s' "$dir"
}

test_orphan_survives_every_run() {
  orphan_sandbox
  local P before run
  P="$(orphan_project orphan)"
  printf 'Merge mode:        local\n' > "$P/AGENTS.local.md"
  printf '# Notes the person wrote\nKeep these.\n' > "$P/AGENTS.md.before-polype"
  before="$(cksum < "$P/AGENTS.md.before-polype")"
  for run in install update update; do
    orphan_ok "$run" "$P"
    [ -f "$P/AGENTS.md.before-polype" ] && [ "$(cksum < "$P/AGENTS.md.before-polype")" = "$before" ] \
      || fail "after $run, the orphan AGENTS.md.before-polype is gone or changed: $OUT"
    grep -qF -- "$P/AGENTS.md.before-polype" <<< "$OUT" || fail "$run did not name the orphan: $OUT"
  done
  if grep -qx 'Keep these.' "$P/AGENTS.local.md"; then fail "the orphan's text was moved into AGENTS.local.md"; fi
}

test_pending_copy_is_still_absorbed() {
  orphan_sandbox
  local P sums
  P="$(orphan_project pending)"
  printf '# Our notes\nKeep it short.\n' > "$P/AGENTS.md"
  orphan_ok install "$P"
  grep -qx 'Keep it short.' "$P/AGENTS.md.before-polype" \
    || fail "without AGENTS.local.md the hand-written AGENTS.md was not set aside: $OUT"
  orphan_ok update "$P"
  grep -qx 'Keep it short.' "$P/AGENTS.md.before-polype" \
    || fail "an update without AGENTS.local.md dropped the waiting copy: $OUT"
  printf 'Merge mode:        local\n' > "$P/AGENTS.local.md"
  orphan_ok update "$P"
  grep -qF 'AGENTS.md.before-polype moved into AGENTS.local.md' <<< "$OUT" \
    || fail "the first update with AGENTS.local.md did not say it absorbed the waiting copy: $OUT"
  grep -qx '## Notes moved from AGENTS.md' "$P/AGENTS.local.md" || fail "no heading in AGENTS.local.md"
  [ "$(grep -cx 'Keep it short.' "$P/AGENTS.local.md")" -eq 1 ] || fail "the notes are not in AGENTS.local.md exactly once"
  if [ -e "$P/AGENTS.md.before-polype" ] || [ -L "$P/AGENTS.md.before-polype" ]; then
    fail "the waiting copy was left after its absorption"
  fi
  sums="$(cksum < "$P/AGENTS.local.md") $(cksum < "$P/AGENTS.md")"
  orphan_ok update "$P"
  [ "$(cksum < "$P/AGENTS.local.md") $(cksum < "$P/AGENTS.md")" = "$sums" ] \
    || fail "an update after the absorption changed AGENTS.local.md or AGENTS.md: $OUT"
}

test_remove_restores_as_before() {
  orphan_sandbox
  local P settings
  # A waiting copy: remove gives the hand-written AGENTS.md back and leaves no Polype state.
  P="$(orphan_project waiting)"
  printf '# Our notes\nKeep it short.\n' > "$P/AGENTS.md"
  orphan_ok install "$P"
  orphan_ok remove "$P"
  [ "$(cat "$P/AGENTS.md")" = "$(printf '# Our notes\nKeep it short.')" ] \
    || fail "remove did not give the hand-written AGENTS.md back as it was: $OUT"
  if [ -e "$P/AGENTS.md.before-polype" ]; then fail "remove left the copy next to the restored AGENTS.md"; fi
  if [ -e "$P/.polype" ] || [ -e "$P/.claude" ]; then fail "remove left .polype/ or .claude/ behind: $OUT"; fi

  # An orphan: remove drops the assembled AGENTS.md and puts the orphan in its place, as it did.
  P="$(orphan_project orphan)"
  printf 'Merge mode:        local\n' > "$P/AGENTS.local.md"
  printf '# Notes the person wrote\n' > "$P/AGENTS.md.before-polype"
  settings="$(cksum < "$P/AGENTS.local.md")"
  orphan_ok install "$P"
  orphan_ok remove "$P"
  [ "$(cat "$P/AGENTS.md")" = '# Notes the person wrote' ] || fail "remove did not put the orphan back as AGENTS.md: $OUT"
  if [ -e "$P/AGENTS.md.before-polype" ]; then fail "remove left the orphan next to the restored AGENTS.md"; fi
  [ "$(cksum < "$P/AGENTS.local.md")" = "$settings" ] || fail "remove changed AGENTS.local.md"
  if [ -e "$P/.polype" ] || [ -e "$P/.claude" ]; then fail "remove left .polype/ or .claude/ behind: $OUT"; fi
}

# The state the previous installer left: its copy sits next to Polype's AGENTS.md, and nothing
# says where it came from.
test_existing_installs_lose_nothing() {
  orphan_sandbox
  local P run
  P="$(orphan_project legacy)"
  orphan_ok install "$P"
  head -n 1 "$P/AGENTS.md" | grep -qF '<!-- Assembled by Polype.' || fail "install did not assemble AGENTS.md: $OUT"
  printf '# Notes set aside by an older installer\nLegacy line.\n' > "$P/AGENTS.md.before-polype"
  printf 'Merge mode:        local\n' > "$P/AGENTS.local.md"
  for run in update update; do
    orphan_ok "$run" "$P"
    if [ -f "$P/AGENTS.md.before-polype" ]; then
      grep -qx 'Legacy line.' "$P/AGENTS.md.before-polype" || fail "after $run, the older copy changed: $OUT"
    else
      grep -qx 'Legacy line.' "$P/AGENTS.local.md" || fail "after $run, the older copy was deleted without being absorbed: $OUT"
    fi
  done
}
