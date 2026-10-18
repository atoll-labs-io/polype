#!/usr/bin/env bash
# s143 — a payload file that differs from what payload.sums signs is a payload edit: a run from the
# payload reports it and lays it nowhere. Every run happens in a throwaway HOME and CLAUDE_CONFIG_DIR.

POLYPE="$ROOT/bin/polype"

home_in() {
  [ -n "${SCRATCH-}" ] || scratch_repo
  export HOME="$SCRATCH/$1"
  export CLAUDE_CONFIG_DIR="$HOME/.claude"
  H="$CLAUDE_CONFIG_DIR"
  mkdir -p "$H"
}

guard_home() {
  case "${CLAUDE_CONFIG_DIR-}" in
    "$SCRATCH"/*) ;;
    *) fail "refusing to run: CLAUDE_CONFIG_DIR is '${CLAUDE_CONFIG_DIR-unset}', not inside $SCRATCH" ;;
  esac
}

# Sets OUT and STATUS; never fails by itself.
run() {
  guard_home
  STATUS=0
  OUT="$(bash "$POLYPE" "$@" 2>&1)" || STATUS=$?
}

ok() { run "$@"; [ "$STATUS" -eq 0 ] || fail "polype $* failed ($STATUS): $OUT"; }

says() { grep -qF -- "$1" <<< "$OUT" || fail "output does not say: $1 — got: $OUT"; }

from_payload() { POLYPE="$H/polype/bin/polype"; }
from_repo() { POLYPE="$ROOT/bin/polype"; }

sum_line() { grep -F " $1" "$2" | grep -E " $1\$" || true; }

# The edit of po-help.md must be reported, laid nowhere and kept out of every recorded sum.
edit_kept() {
  local path=polype/method/commands/po-help.md
  grep -qx 'EDIT' "$H/$path" || fail "the payload file lost its edit"
  [ "$(cksum < "$H/commands/po-help.md")" = "$active" ] || fail "the edit spread to the active copy"
  says "polype: modified, left as it is: $path"
  [ "$(grep -c "modified, left as it is: $path" <<< "$OUT")" -eq 1 ] || fail "the edit is reported more than once: $OUT"
  cmp -s "$H/polype/payload.sums" "$sums_copy" || fail "payload.sums changed"
  [ "$(sum_line "$path" "$H/polype/checksums")" = "$signed" ] \
    || fail "checksums does not hold the signed sum of $path: $(sum_line "$path" "$H/polype/checksums")"
}

test_payload_edit_reported_not_spread() {
  home_in home
  ok install --global
  signed="$(sum_line polype/method/commands/po-help.md "$H/polype/payload.sums")"
  [ -n "$signed" ] || fail "payload.sums does not sign po-help.md"
  active="$(cksum < "$H/commands/po-help.md")"
  sums_copy="$SCRATCH/payload.sums.before"
  cp "$H/polype/payload.sums" "$sums_copy"
  echo EDIT >> "$H/polype/method/commands/po-help.md"

  from_payload
  ok update --global
  edit_kept
  tail -n 1 <<< "$OUT" | grep -qF ', 1 left modified)' || fail "update does not count the edit: $OUT"

  ok install --global
  edit_kept
  tail -n 1 <<< "$OUT" | grep -qF '1 left modified' || fail "install does not count the edit: $OUT"
}

test_init_does_not_take_payload_edit() {
  home_in home
  ok install --global
  P="$SCRATCH/project"; mkdir -p "$P"
  from_payload
  ok init "$P"
  local copy="$P/.polype/templates/plan.md" before
  before="$(cksum < "$copy")"
  echo EDIT >> "$H/polype/method/templates/plan.md"

  ok init "$P"
  [ "$(cksum < "$copy")" = "$before" ] || fail "init laid the payload edit in the project"
  says "polype: modified, left as it is: polype/method/templates/plan.md"

  rm "$copy"
  ok init "$P"
  [ ! -e "$copy" ] || fail "init laid the edited payload file where the project copy was missing"

  local Q="$SCRATCH/second"
  mkdir -p "$Q/.polype/templates"
  echo mine > "$Q/.polype/templates/plan.md"
  ok init "$Q"
  grep -qx mine "$Q/.polype/templates/plan.md" || fail "init touched the project's own plan.md"
}

test_check_lists_payload_edit() {
  home_in home
  ok install --global
  echo EDIT >> "$H/polype/method/commands/po-help.md"
  from_payload
  ok update --global
  run check --global
  [ "$STATUS" -eq 1 ] || fail "check --global should exit 1, got $STATUS: $OUT"
  says "modified: polype/method/commands/po-help.md"
}

test_fresh_source_still_updates() {
  home_in home
  ok install --global
  local copy="$SCRATCH/newer"
  mkdir -p "$copy"
  cp -r "$ROOT/bin" "$ROOT/method" "$copy/"
  echo "a newer line" >> "$copy/method/commands/po-help.md"
  POLYPE="$copy/bin/polype"
  ok update --global
  cmp -s "$H/polype/method/commands/po-help.md" "$copy/method/commands/po-help.md" \
    || fail "the payload file was not replaced by the newer source"
  cmp -s "$H/commands/po-help.md" "$copy/method/commands/po-help.md" \
    || fail "the active copy was not replaced by the newer source"
  [ "$(sum_line polype/method/commands/po-help.md "$H/polype/payload.sums")" \
    = "$(cksum < "$copy/method/commands/po-help.md") polype/method/commands/po-help.md" ] \
    || fail "payload.sums does not carry the new sum"
}
