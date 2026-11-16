#!/usr/bin/env bash
# s188 — a waiting copy edited after Polype set it aside is no longer taken for that copy.
# Every run happens in a throwaway directory, with a throwaway HOME and CLAUDE_CONFIG_DIR.

POLYPE="$ROOT/bin/polype"

edited_sandbox() {
  scratch_repo
  export HOME="$SCRATCH/home"
  export CLAUDE_CONFIG_DIR="$HOME/.claude"
  mkdir -p "$CLAUDE_CONFIG_DIR"
}

# Sets OUT; fails the test when the run fails.
edited_ok() {
  case "${CLAUDE_CONFIG_DIR-}" in
    "$SCRATCH"/*) ;;
    *) fail "refusing to run: CLAUDE_CONFIG_DIR is '${CLAUDE_CONFIG_DIR-unset}', not inside $SCRATCH" ;;
  esac
  local status=0
  OUT="$(bash "$POLYPE" "$@" 2>&1)" || status=$?
  [ "$status" -eq 0 ] || fail "polype $* failed ($status): $OUT"
}

test_edited_waiting_copy_is_kept() {
  edited_sandbox
  local P="$SCRATCH/edited"
  mkdir -p "$P"
  git -C "$P" init -q -b main
  printf '# Our notes\nKeep it short.\n' > "$P/AGENTS.md"
  edited_ok install "$P"
  [ -f "$P/AGENTS.md.before-polype" ] || fail "install did not set the hand-written AGENTS.md aside: $OUT"
  printf 'Edited by hand.\n' >> "$P/AGENTS.md.before-polype"
  printf 'Merge mode:        local\n' > "$P/AGENTS.local.md"
  edited_ok update "$P"
  grep -qx 'Edited by hand.' "$P/AGENTS.md.before-polype" 2>/dev/null \
    || fail "the edited copy is gone or lost its edit: $OUT"
  if grep -qx 'Keep it short.' "$P/AGENTS.local.md"; then fail "the edited copy was moved into AGENTS.local.md"; fi
  grep -qF -- "$P/AGENTS.md.before-polype" <<< "$OUT" || fail "update did not name the edited copy: $OUT"
}
