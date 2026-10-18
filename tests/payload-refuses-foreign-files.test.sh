#!/usr/bin/env bash
# s142 — the payload signs itself with payload.sums, and a file there that Polype did not lay down
# stops the run. Every run happens in a throwaway HOME and CLAUDE_CONFIG_DIR.

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
  local dir path
  for dir in "$@"; do
    find "$dir" | sort | while IFS= read -r path; do
      if [ -L "$path" ]; then printf '%s -> %s\n' "$path" "$(readlink "$path")"
      elif [ -f "$path" ]; then printf '%s %s\n' "$path" "$(cksum < "$path")"
      else printf '%s\n' "$path"; fi
    done
  done
}

says() { grep -qF -- "$1" <<< "$OUT" || fail "output does not say: $1 — got: $OUT"; }

from_payload() { POLYPE="$H/polype/bin/polype"; }
from_repo() { POLYPE="$ROOT/bin/polype"; }

# stops <name> <command...>: exit 1, the home and the project untouched, the name in the output.
stops() {
  local name="$1" before; shift
  before="$(snapshot "$H" ${P:+"$P"})"
  run "$@"
  [ "$STATUS" -eq 1 ] || fail "polype $* should exit 1, got $STATUS: $OUT"
  [ "$(snapshot "$H" ${P:+"$P"})" = "$before" ] || fail "a stopped polype $* changed the home or the project"
  says "$name"
}

project() { P="$SCRATCH/project"; mkdir -p "$P"; }

test_payload_signs_itself() {
  home_in home
  ok install --global
  local sums="$H/polype/payload.sums" crc size path
  [ -f "$sums" ] || fail "install --global from a repository wrote no payload.sums"
  if grep -Eq ' polype/(manifest|checksums|version|payload\.sums)$|\.next$|\.polype-next$' "$sums"; then
    fail "payload.sums lists a state file"
  fi
  if grep -qx 'polype/payload.sums' "$H/polype/manifest"; then fail "the manifest lists payload.sums"; fi
  while IFS= read -r path; do
    grep -qF " $path" "$sums" || fail "payload.sums misses $path"
  done < <(grep '^polype/' "$H/polype/manifest")
  [ "$(wc -l < "$sums")" -eq "$(grep -c '^polype/' "$H/polype/manifest")" ] \
    || fail "payload.sums and the payload lines of the manifest differ in count"
  while read -r crc size path; do
    [ "$crc $size" = "$(cksum < "$H/$path")" ] || fail "payload.sums holds a wrong sum for $path"
  done < "$sums"

  rm "$sums"
  ok update --global
  [ -f "$sums" ] || fail "update --global from a repository did not sign the payload again"
}

test_foreign_payload_file_stops_install() {
  home_in home
  project
  ok install --global
  local mine="$H/polype/method/commands/mine.md"
  echo mine > "$mine"
  from_payload
  stops "polype: not laid down by Polype, inside the payload: $mine" update --global
  says "move each one out of $H/polype"
  stops "$mine" install --global
  stops "$mine" init "$P"
  from_repo
  stops "$mine" install --global --set-aside
  [ ! -e "$H/commands/mine.md" ] || fail "the foreign file was laid as a command"

  rm "$mine"
  ln -s "$SCRATCH/elsewhere.md" "$H/polype/method/skills/link.md"
  from_payload
  stops "$H/polype/method/skills/link.md" update --global
  rm "$H/polype/method/skills/link.md"
  ok update --global

  home_in collision
  mkdir -p "$H/polype/bin"
  echo mine > "$H/polype/bin/polype"
  from_repo
  stops "polype: not laid down by Polype, inside the payload: $H/polype/bin/polype" install --global --set-aside
  [ ! -e "$H/polype/bin/polype.before-polype" ] || fail "--set-aside set a payload file aside"
}

test_synced_payload_still_installs() {
  home_in a
  local copy="$SCRATCH/newer" A B
  mkdir -p "$copy"
  cp -r "$ROOT/bin" "$ROOT/method" "$copy/"
  echo "# a new command" > "$copy/method/commands/po-newbie.md"
  rm "$copy/method/commands/po-help.md"
  POLYPE="$copy/bin/polype"
  ok install --global
  A="$H"

  home_in b
  from_repo
  ok install --global
  B="$H"
  cp -r "$A/polype/bin" "$A/polype/method" "$A/polype/payload.sums" "$B/polype/"
  from_payload
  ok update --global
  [ -f "$B/commands/po-newbie.md" ] || fail "the new command of the synced payload was not laid"
  grep -qx 'commands/po-newbie.md' "$B/polype/manifest" || fail "the manifest does not list the new command"
  grep -qx 'polype/method/commands/po-newbie.md' "$B/polype/manifest" \
    || fail "the manifest does not list the new payload file"
  [ ! -e "$B/commands/po-help.md" ] || fail "a command the synced payload no longer signs was laid again"
  if grep -q 'po-help' "$B/polype/manifest"; then fail "the manifest still lists po-help"; fi
}

test_old_set_aside_never_put_back_in_payload() {
  home_in home
  ok install --global
  local aside="$H/polype/method/commands/po-help.md.before-polype"
  echo "the person's file" > "$aside"
  from_payload
  stops "polype: not laid down by Polype, inside the payload: $aside" update --global
  from_repo
  stops "$aside" install --global
  [ ! -e "$H/commands/po-help.md.before-polype" ] || fail "the set-aside file was laid as a command"

  ok remove --global
  [ "$(cat "$H/polype/method/commands/po-help.md")" = "the person's file" ] \
    || fail "remove --global did not put the set-aside file back"
}

test_remove_stops_on_foreign_payload_file() {
  home_in home
  ok install --global
  local notes="$H/polype/notes.md"
  echo "my notes" > "$notes"
  stops "polype: not laid down by Polype, inside the payload: $notes" remove --global
  rm "$notes"

  echo "signed elsewhere" > "$H/polype/method/extra.md"
  printf '%s polype/method/extra.md\n' "$(cksum < "$H/polype/method/extra.md")" >> "$H/polype/payload.sums"
  ok remove --global
  [ ! -e "$H/polype" ] || fail "remove --global left the payload behind"
}

test_unsigned_payload_says_so() {
  home_in home
  project
  ok install --global
  rm "$H/polype/payload.sums"
  from_payload
  local args
  for args in "update --global" "install --global" "init $P"; do
    # shellcheck disable=SC2086
    stops "not signed" $args
    says "Polype repository"
  done
  run check --global
  [ "$STATUS" -eq 0 ] || fail "check --global on a clean unsigned payload should exit 0, got $STATUS: $OUT"
  says "polype: the payload is not signed (no payload.sums)"
  ok remove --global
  says "remove trusts the manifest alone"
  [ ! -e "$H/polype" ] || fail "remove --global did not take the unsigned payload away"
}

test_adr_records_the_payload_rule() {
  local adrs=("$ROOT"/docs/decisions/ADR-0095-*.md) adr old doc="$ROOT/docs/installation.md"
  [ "${#adrs[@]}" -eq 1 ] && [ -f "${adrs[0]}" ] || fail "expected exactly one ADR-0095 file"
  adr="${adrs[0]}"
  frontmatter "$adr" | grep -qx 'status: accepted' || fail "ADR-0095 is not accepted"
  frontmatter "$adr" | grep -qx 'supersedes: \[ADR-0088\]' || fail "ADR-0095 does not supersede ADR-0088"
  contains "$adr" '#118'
  contains "$adr" '#115'
  contains "$adr" 's143'
  contains "$adr" 'polype.kept'
  contains "$adr" 'payload.sums'
  old="$(ls "$ROOT"/docs/decisions/ADR-0088-*.md)"
  frontmatter "$old" | grep -qx 'superseded-by: \[ADR-0092, ADR-0095\]' || fail "ADR-0088 does not link to ADR-0095"
  frontmatter "$old" | grep -qx 'status: accepted' || fail "ADR-0088 must stay accepted"
  contains "$doc" 'payload.sums'
  contains "$doc" 'ADR-0095'
}
