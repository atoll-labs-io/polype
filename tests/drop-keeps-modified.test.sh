#!/usr/bin/env bash
# s137 — a copy the person modified, that Polype no longer lays, stays in place and becomes theirs.
# Every run happens in a throwaway directory, with a throwaway HOME and CLAUDE_CONFIG_DIR.

POLYPE="$ROOT/bin/polype"

sandbox() {
  scratch_repo
  export HOME="$SCRATCH/home"
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

new_project() {
  local dir="$SCRATCH/$1"
  mkdir -p "$dir"
  git -C "$dir" init -q -b main
  printf '%s' "$dir"
}

# Sets OUT and STATUS; never fails by itself.
run() {
  guard_home
  STATUS=0
  OUT="$(bash "$POLYPE" "$@" 2>&1)" || STATUS=$?
}

ok() { run "$@"; [ "$STATUS" -eq 0 ] || fail "polype $* failed ($STATUS): $OUT"; }

snapshot() {
  local dir="$1" path
  find "$dir" -path "$dir/.git" -prune -o -print | sort | while IFS= read -r path; do
    if [ -f "$path" ]; then printf '%s %s\n' "$path" "$(cksum < "$path")"; else printf '%s\n' "$path"; fi
  done
}

copy_of_the_method() {
  COPY="$SCRATCH/.method-copy"
  mkdir -p "$COPY"
  cp -r "$ROOT/bin" "$ROOT/method" "$COPY/"
  POLYPE="$COPY/bin/polype"
}

says() { grep -qF -- "$1" <<< "$OUT" || fail "output does not say: $1 — got: $OUT"; }
never_says() { if grep -qF -- "$1" <<< "$OUT"; then fail "output says $1: $OUT"; fi; }

# An absent state file lists nothing.
not_listed() {
  local file="$1" path="$2"
  [ -f "$file" ] || return 0
  if grep -qF -- "$path" "$file"; then fail "${file#"$SCRATCH"/} still lists $path"; fi
}

out_of_the_state() {
  local P="$1" path="$2"
  not_listed "$P/.polype/manifest" "$path"
  not_listed "$P/.polype/checksums" "$path"
  not_listed "$P/.claude/.polype-checksums" "$path"
}

# A full install, one copy edited, then init: leaves P, EDITED (path) and KEPT (its edited bytes).
install_edit_then_init() {
  P="$(new_project a)"
  EDITED=.claude/commands/po-architect.md
  ok install "$P"
  echo "# my own line" >> "$P/$EDITED"
  KEPT="$SCRATCH/kept-copy"
  cp "$P/$EDITED" "$KEPT"
  ok init "$P"
}

test_init_keeps_a_modified_copy() {
  sandbox
  install_edit_then_init
  cmp -s "$KEPT" "$P/$EDITED" || fail "init did not keep the modified copy byte for byte"
  out_of_the_state "$P" "$EDITED"
  says "polype: modified, kept: $P/$EDITED"
  [ ! -e "$P/.claude/agents/reviewer.md" ] || fail "init kept an unmodified copy it no longer lays"
  local shipped
  shipped=$(( $(find "$ROOT/method/templates" "$ROOT/method/hooks" -type f | wc -l) ))
  [ "$(wc -l < "$P/.polype/manifest")" -eq "$shipped" ] \
    || fail "init manifest has $(wc -l < "$P/.polype/manifest") lines, expected $shipped"
}

test_update_ghost_keeps_a_modified_copy() {
  sandbox
  copy_of_the_method
  local P X=.claude/agents/reviewer.md Y=.claude/agents/implementer.md
  P="$(new_project a)"
  ok install "$P"
  echo "# mine" >> "$P/$X"
  cp "$P/$X" "$SCRATCH/x-edited"
  rm "$COPY/method/agents/reviewer.md" "$COPY/method/agents/implementer.md"
  ok update "$P"
  cmp -s "$SCRATCH/x-edited" "$P/$X" || fail "update did not keep the modified ghost"
  says "polype: modified, kept: $P/$X"
  out_of_the_state "$P" "$X"
  [ ! -e "$P/$Y" ] || fail "update kept an unmodified ghost"
  never_says "modified, kept: $P/$Y"
  [[ "$(tail -n 1 <<< "$OUT")" == *", 1 removed, "* ]] || fail "update counted a kept ghost: $OUT"
}

test_update_test_checks_all_state() {
  local self="$ROOT/tests/drop-keeps-modified.test.sh" body
  body="$(awk '$0 ~ /^test_update_ghost_keeps_a_modified_copy\(\)/ {on=1; next} on && /^}/ {exit} on' "$self")"
  grep -qF 'out_of_the_state' <<< "$body" \
    || fail "test_update_ghost_keeps_a_modified_copy does not check all three state files"
}

test_remove_keeps_a_modified_copy() {
  sandbox
  local P E=.claude/commands/po-plan.md
  P="$(new_project a)"
  ok install "$P"
  echo "# mine" >> "$P/$E"
  cp "$P/$E" "$SCRATCH/e-edited"
  ok remove "$P"
  cmp -s "$SCRATCH/e-edited" "$P/$E" || fail "remove did not keep the modified copy"
  says "polype: modified, kept: $P/$E"
  [ ! -e "$P/.claude/commands/po-execute.md" ] || fail "remove kept an unmodified copy"

  ok install --global
  echo "# mine" >> "$H/polype/method/AGENTS.md"
  ok remove --global
  [ ! -e "$H/polype" ] || fail "remove --global left the payload directory behind"
  never_says "modified, kept: $H/polype/"
}

test_modified_copy_over_a_set_aside_file() {
  sandbox
  local P R=.claude/agents/reviewer.md
  P="$(new_project a)"
  mkdir -p "$P/.claude/agents"
  echo mine > "$P/$R"
  ok install "$P" --set-aside
  echo "# edited" >> "$P/$R"
  cp "$P/$R" "$SCRATCH/r-edited"
  ok remove "$P"
  cmp -s "$SCRATCH/r-edited" "$P/$R" || fail "remove replaced the modified copy"
  [ "$(cat "$P/$R.before-polype")" = mine ] || fail "remove moved the set-aside file"
  says "polype: modified, kept: $P/$R; $P/$R.before-polype left as it is"
}

test_kept_copy_becomes_the_persons() {
  sandbox
  install_edit_then_init
  local before; before="$(snapshot "$P")"
  run install "$P"
  [ "$STATUS" -eq 1 ] || fail "install over a kept copy should exit 1, got $STATUS: $OUT"
  [ "$(snapshot "$P")" = "$before" ] || fail "a stopped install changed the project"
  says "$P/$EDITED"
  ok install "$P" --set-aside
  cmp -s "$KEPT" "$P/$EDITED.before-polype" || fail "--set-aside did not move the kept copy aside"
  cmp -s "$ROOT/method/commands/po-architect.md" "$P/$EDITED" || fail "--set-aside did not lay the shipped file"
}

test_header_lists_the_mode_file() {
  sed '/^set -euo pipefail/q' "$ROOT/bin/polype" | grep '^#' | grep -qF '.polype/mode' \
    || fail "the header comment of bin/polype does not name .polype/mode"
  grep -q '^recorded_mode() {' "$ROOT/bin/polype" || fail "recorded_mode is no longer defined"
}

test_adr_records_the_choice() {
  local adrs=("$ROOT"/docs/decisions/ADR-0092-*.md) adr old
  [ "${#adrs[@]}" -eq 1 ] && [ -f "${adrs[0]}" ] || fail "expected exactly one ADR-0092 file"
  adr="${adrs[0]}"
  frontmatter "$adr" | grep -qx 'status: accepted' || fail "ADR-0092 is not accepted"
  frontmatter "$adr" | grep -qx 'supersedes: \[ADR-0088\]' || fail "ADR-0092 does not supersede ADR-0088"
  contains "$adr" 'Écartée'
  contains "$adr" 'nouveau suffixe'
  contains "$adr" 'Arrêter la commande'
  contains "$adr" 'Exempter `remove`'
  contains "$adr" 'ADR-0087'
  contains "$adr" '`~/.claude/polype/`'
  old="$(ls "$ROOT"/docs/decisions/ADR-0088-*.md)"
  frontmatter "$old" | grep -qx 'superseded-by: \[ADR-0092\]' || fail "ADR-0088 does not link to ADR-0092"
  frontmatter "$old" | grep -qx 'status: accepted' || fail "ADR-0088 must stay accepted"
  contains "$ROOT/docs/installation.md" 'modified, kept:'
  contains "$ROOT/docs/installation.md" 'ADR-0092'
}
