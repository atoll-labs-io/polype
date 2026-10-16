#!/usr/bin/env bash
# s139 — a modified payload file Polype no longer ships moves to ~/.claude/polype.kept/, so a run
# from the payload cannot ship it again. Every run happens in a throwaway HOME and CLAUDE_CONFIG_DIR.

POLYPE="$ROOT/bin/polype"

# A fresh home under the same scratch directory; several may live in one test.
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

snapshot() {
  local dir="$1" path
  find "$dir" | sort | while IFS= read -r path; do
    if [ -f "$path" ]; then printf '%s %s\n' "$path" "$(cksum < "$path")"; else printf '%s\n' "$path"; fi
  done
}

says() { grep -qF -- "$1" <<< "$OUT" || fail "output does not say: $1 — got: $OUT"; }
never_says() { if grep -qF -- "$1" <<< "$OUT"; then fail "output says $1: $OUT"; fi; }

not_listed() {
  [ -f "$1" ] || return 0
  if grep -qF -- "$2" "$1"; then fail "${1#"$SCRATCH"/} still lists $2"; fi
}

# A global install from a copy of the method, its payload po-help edited, then dropped from the
# copy: leaves PAY (payload path), KEPT (kept path) and EDITED (the edited bytes).
edited_payload_file_dropped() {
  home_in "$1"
  COPY="$SCRATCH/$1-method"
  mkdir -p "$COPY"
  cp -r "$ROOT/bin" "$ROOT/method" "$COPY/"
  POLYPE="$COPY/bin/polype"
  ok install --global
  PAY="$H/polype/method/commands/po-help.md"
  KEPT="$H/polype.kept/method/commands/po-help.md"
  echo "# mine" >> "$PAY"
  EDITED="$SCRATCH/$1-edited"
  cp "$PAY" "$EDITED"
  rm "$COPY/method/commands/po-help.md"
}

moved_out() {
  cmp -s "$EDITED" "$KEPT" || fail "the kept copy does not hold the edit"
  [ ! -e "$PAY" ] || fail "the edited file stayed in the payload"
  not_listed "$H/polype/manifest" polype/method/commands/po-help.md
  not_listed "$H/polype/checksums" polype/method/commands/po-help.md
  says "polype: modified, moved out of the payload: $PAY -> $KEPT"
}

test_payload_copy_moves_out() {
  edited_payload_file_dropped install-home
  ok install --global
  moved_out

  edited_payload_file_dropped update-home
  ok update --global
  moved_out
  [ ! -e "$H/commands/po-help.md" ] || fail "update kept the unmodified active copy"
  # The unmodified active copy alone is counted: a moved-out ghost is kept, as under ADR-0092.
  [[ "$(tail -n 1 <<< "$OUT")" == *", 1 removed, "* ]] || fail "update counted the moved-out ghost: $OUT"
}

test_moved_copy_is_not_shipped() {
  edited_payload_file_dropped home
  ok install --global
  POLYPE="$H/polype/bin/polype"
  ok update --global
  [ ! -e "$H/commands/po-help.md" ] || fail "a run from the payload laid po-help again"
  [ ! -e "$PAY" ] || fail "a run from the payload brought po-help back into it"
  not_listed "$H/polype/manifest" po-help
}

test_kept_copy_removed_once_shipped() {
  home_in home
  local same="$H/polype.kept/method/skills/diagnostic/SKILL.md" other="$H/polype.kept/method/AGENTS.md"
  mkdir -p "$(dirname "$same")"
  cp "$ROOT/method/skills/diagnostic/SKILL.md" "$same"
  echo "my own AGENTS" > "$other"
  ok install --global
  [ ! -e "$same" ] || fail "a kept copy identical to the shipped file stayed"
  [ ! -e "$H/polype.kept/method/skills" ] || fail "the emptied directories of polype.kept stayed"
  says "polype: kept copy now shipped, removed: $same"
  [ "$(cat "$other")" = "my own AGENTS" ] || fail "a kept copy that differs from the shipped file went"
  never_says "removed: $other"

  home_in second
  same="$H/polype.kept/method/skills/diagnostic/SKILL.md"
  mkdir -p "$(dirname "$same")"
  cp "$ROOT/method/skills/diagnostic/SKILL.md" "$same"
  ok install --global
  [ ! -e "$H/polype.kept" ] || fail "an emptied polype.kept stayed"
}

stops_on_the_taken_copy() {
  local before; before="$(snapshot "$H")"
  run "$@"
  [ "$STATUS" -eq 1 ] || fail "polype $* over a taken kept copy should exit 1, got $STATUS: $OUT"
  [ "$(snapshot "$H")" = "$before" ] || fail "a stopped polype $* changed the home"
  says "$KEPT"
  says "$PAY"
}

test_existing_kept_copy_never_overwritten() {
  edited_payload_file_dropped home
  mkdir -p "$(dirname "$KEPT")"
  echo "another edit" > "$KEPT"
  stops_on_the_taken_copy install --global
  stops_on_the_taken_copy update --global
  echo "# new agent" > "$COPY/method/agents/newbie.md"
  echo "the person's agent" > "$H/agents/newbie.md"
  stops_on_the_taken_copy install --global --set-aside

  cp "$EDITED" "$KEPT"
  ok install --global --set-aside
  [ ! -e "$PAY" ] || fail "the payload file stayed though its edit was already kept"
  cmp -s "$EDITED" "$KEPT" || fail "the already kept copy changed"
  says "polype: modified, already kept: $KEPT"
}

test_remove_leaves_kept_copies() {
  home_in home
  local A="$H/polype/method/AGENTS.md" K="$H/polype.kept/method/AGENTS.md"
  ok install --global
  echo "# mine" >> "$A"
  cp "$A" "$SCRATCH/a-edited"
  ok remove --global
  [ ! -e "$H/polype" ] || fail "remove --global left the payload directory behind"
  cmp -s "$SCRATCH/a-edited" "$K" || fail "remove --global did not keep the payload edit"
  says "polype: modified, moved out of the payload: $A -> $K"
  says "polype: kept copies left in $H/polype.kept"

  home_in taken
  A="$H/polype/method/AGENTS.md" K="$H/polype.kept/method/AGENTS.md"
  ok install --global
  echo "# mine" >> "$A"
  mkdir -p "$(dirname "$K")"
  echo "another edit" > "$K"
  local before; before="$(snapshot "$H")"
  run remove --global
  [ "$STATUS" -eq 1 ] || fail "remove --global over a taken kept copy should exit 1, got $STATUS: $OUT"
  [ "$(snapshot "$H")" = "$before" ] || fail "a stopped remove --global changed the home"

  home_in aside
  A="$H/polype/method/AGENTS.md" K="$H/polype.kept/method/AGENTS.md"
  mkdir -p "$(dirname "$A")"
  echo "the person's file" > "$A"
  ok install --global --set-aside
  echo "# mine" >> "$A"
  cp "$A" "$SCRATCH/aside-edited"
  ok remove --global
  cmp -s "$SCRATCH/aside-edited" "$K" || fail "remove --global lost the edit over a set-aside file"
  [ "$(cat "$A")" = "the person's file" ] || fail "remove --global did not put the set-aside file back"
  ! compgen -G "$H/.polype-restore.*" > /dev/null || fail "remove --global left its hold directory"
}

test_adr_records_the_kept_payload() {
  local adrs=("$ROOT"/docs/decisions/ADR-0093-*.md) adr old doc="$ROOT/docs/installation.md"
  [ "${#adrs[@]}" -eq 1 ] && [ -f "${adrs[0]}" ] || fail "expected exactly one ADR-0093 file"
  adr="${adrs[0]}"
  frontmatter "$adr" | grep -qx 'status: accepted' || fail "ADR-0093 is not accepted"
  frontmatter "$adr" | grep -qx 'supersedes: \[ADR-0092\]' || fail "ADR-0093 does not supersede ADR-0092"
  contains "$adr" 'polype.kept'
  contains "$adr" 'perdue pour de bon'
  # The ADR wraps its prose: the phrase is looked for across line breaks.
  tr '\n' ' ' < "$adr" | tr -s ' ' | grep -qF "rien n'en signale la fin" \
    || fail "ADR-0093 does not say: rien n'en signale la fin"
  old="$(ls "$ROOT"/docs/decisions/ADR-0092-*.md)"
  frontmatter "$old" | grep -qx 'superseded-by: \[ADR-0093\]' || fail "ADR-0092 does not link to ADR-0093"
  frontmatter "$old" | grep -qx 'status: accepted' || fail "ADR-0092 must stay accepted"
  contains "$doc" 'polype.kept'
  contains "$doc" 'ADR-0093'
  contains "$doc" 'moved out of the payload'
  if grep -qF 'emporte la charge utile' "$doc"; then fail "installation.md still says remove takes the payload edits"; fi
}
