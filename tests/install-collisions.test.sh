#!/usr/bin/env bash
# s130 — the installer stops on a file it did not lay down, --set-aside moves it and remove puts it
# back, and a hand-written AGENTS.md is absorbed into AGENTS.local.md.
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

stops() {
  run "$@"
  [ "$STATUS" -eq 1 ] || fail "polype $* should exit 1, got $STATUS: $OUT"
}

# Every path under the directory, and the checksum of every file.
snapshot() {
  local dir="$1" path
  find "$dir" -path "$dir/.git" -prune -o -print | sort | while IFS= read -r path; do
    if [ -f "$path" ]; then printf '%s %s\n' "$path" "$(cksum < "$path")"; else printf '%s\n' "$path"; fi
  done
}

# A copy of bin/ and method/ the test may change; POLYPE then points at it.
copy_of_the_method() {
  COPY="$SCRATCH/.method-copy"
  mkdir -p "$COPY"
  cp -r "$ROOT/bin" "$ROOT/method" "$COPY/"
  POLYPE="$COPY/bin/polype"
}

says() { grep -qF -- "$1" <<< "$OUT" || fail "output does not say: $1 — got: $OUT"; }
never_says() { if grep -qF -- "$1" <<< "$OUT"; then fail "output names $1: $OUT"; fi; }

test_collision_stops_before_writing() {
  sandbox
  local P before; P="$(new_project a)"
  mkdir -p "$P/.claude/agents"
  echo mine > "$P/.claude/agents/reviewer.md"
  cp "$METHOD/agents/implementer.md" "$P/.claude/agents/implementer.md"
  before="$(snapshot "$P")"
  stops install "$P"
  says "$P/.claude/agents/reviewer.md"
  says '--set-aside'
  never_says 'implementer.md'
  [ "$(snapshot "$P")" = "$before" ] || fail "install wrote something before stopping"
  if [ -e "$P/.polype" ]; then fail "install created .polype/ before stopping"; fi

  local I; I="$(new_project b)"
  mkdir -p "$I/.polype/templates"
  echo mine > "$I/.polype/templates/plan.md"
  before="$(snapshot "$I")"
  stops init "$I"
  says "$I/.polype/templates/plan.md"
  [ "$(snapshot "$I")" = "$before" ] || fail "init wrote something before stopping"

  local U; U="$(new_project c)"
  ok install "$U"
  copy_of_the_method
  echo 'shipped' > "$COPY/method/agents/newcomer.md"
  echo mine > "$U/.claude/agents/newcomer.md"
  echo '.claude/agents/ghost.md' >> "$U/.polype/manifest"
  echo ghost > "$U/.claude/agents/ghost.md"
  before="$(snapshot "$U")"
  stops update "$U"
  says "$U/.claude/agents/newcomer.md"
  [ -f "$U/.claude/agents/ghost.md" ] || fail "update deleted a ghost before stopping"
  [ "$(snapshot "$U")" = "$before" ] || fail "update wrote something before stopping"

  POLYPE="$ROOT/bin/polype"
  rm "$P/.claude/agents/reviewer.md"
  ok install "$P"
  never_says 'implementer.md'
  cmp -s "$METHOD/agents/implementer.md" "$P/.claude/agents/implementer.md" || fail "the identical copy was not taken over"
}

test_collision_stops_before_writing_global() {
  sandbox
  local before
  mkdir -p "$H/agents"
  echo mine > "$H/agents/reviewer.md"
  before="$(snapshot "$SCRATCH")"
  stops install --global
  says "$H/agents/reviewer.md"
  says '--set-aside'
  if [ -e "$H/polype" ]; then fail "install --global created the payload before stopping"; fi
  [ "$(snapshot "$SCRATCH")" = "$before" ] || fail "install --global wrote something before stopping"

  rm "$H/agents/reviewer.md"
  ok install --global
  copy_of_the_method
  mkdir -p "$COPY/method/skills/newcomer" "$H/skills/newcomer"
  echo shipped > "$COPY/method/skills/newcomer/SKILL.md"
  echo mine > "$H/skills/newcomer/SKILL.md"
  before="$(snapshot "$SCRATCH")"
  stops update --global
  says "$H/skills/newcomer/SKILL.md"
  [ "$(snapshot "$SCRATCH")" = "$before" ] || fail "update --global wrote something before stopping"
}

test_set_aside_is_explicit_and_undone() {
  sandbox
  local P; P="$(new_project a)"
  mkdir -p "$P/.claude/agents"
  echo mine > "$P/.claude/agents/reviewer.md"
  ok install "$P" --set-aside
  says 'set aside'
  [ "$(cat "$P/.claude/agents/reviewer.md.before-polype")" = mine ] || fail "the person's file was not set aside"
  cmp -s "$METHOD/agents/reviewer.md" "$P/.claude/agents/reviewer.md" || fail "the shipped reviewer.md was not laid down"
  ok remove "$P"
  [ "$(cat "$P/.claude/agents/reviewer.md")" = mine ] || fail "remove did not put the person's file back"
  if [ -e "$P/.claude/agents/reviewer.md.before-polype" ]; then fail "remove left the .before-polype behind"; fi

  local B before; B="$(new_project b)"
  mkdir -p "$B/.claude/agents"
  echo mine > "$B/.claude/agents/reviewer.md"
  echo older > "$B/.claude/agents/reviewer.md.before-polype"
  before="$(snapshot "$B")"
  stops install "$B" --set-aside
  says "$B/.claude/agents/reviewer.md.before-polype"
  [ "$(snapshot "$B")" = "$before" ] || fail "an existing .before-polype was not respected"

  local U; U="$(new_project c)"
  mkdir -p "$U/.claude/agents"
  echo mine > "$U/.claude/agents/reviewer.md"
  ok install "$U" --set-aside
  copy_of_the_method
  rm "$COPY/method/agents/reviewer.md"
  ok update "$U"
  [ "$(cat "$U/.claude/agents/reviewer.md")" = mine ] || fail "update did not put back a file no longer shipped"
  if [ -e "$U/.claude/agents/reviewer.md.before-polype" ]; then fail "update left the .before-polype behind"; fi

  run install "$P" --bogus
  [ "$STATUS" -eq 2 ] || fail "an unknown option must exit 2, got $STATUS"
}

test_set_aside_is_explicit_and_undone_global() {
  sandbox
  mkdir -p "$H/agents" "$H/polype/bin"
  echo mine > "$H/agents/reviewer.md"
  echo mine > "$H/polype/bin/polype"
  ok install --global --set-aside
  [ "$(cat "$H/polype/bin/polype.before-polype")" = mine ] || fail "the payload-side file was not set aside"
  ok remove --global
  [ "$(cat "$H/agents/reviewer.md")" = mine ] || fail "remove --global did not put reviewer.md back"
  [ "$(cat "$H/polype/bin/polype")" = mine ] || fail "remove --global lost the file set aside under polype/"
  if [ -n "$(find "$H" -name '*.before-polype' -o -name '.polype-restore.*')" ]; then
    fail "remove --global left a backup or its hold directory behind"
  fi

  # A dotfiles link stays a link, even to the very content Polype ships.
  rm "$H/agents/reviewer.md"
  mkdir -p "$SCRATCH/dotfiles"
  cp "$METHOD/agents/reviewer.md" "$SCRATCH/dotfiles/reviewer.md"
  ln -s "$SCRATCH/dotfiles/reviewer.md" "$H/agents/reviewer.md"
  stops install --global
  says "$H/agents/reviewer.md"
  [ -L "$H/agents/reviewer.md" ] || fail "install --global replaced the person's link before stopping"
  ok install --global --set-aside
  [ -L "$H/agents/reviewer.md.before-polype" ] || fail "the link was not set aside as a link"
  ok remove --global
  [ "$(readlink "$H/agents/reviewer.md")" = "$SCRATCH/dotfiles/reviewer.md" ] || fail "remove --global did not put the link back"
}

test_hand_written_agents_md_is_absorbed() {
  sandbox
  local P; P="$(new_project a)"
  printf 'Merge mode:        local\n' > "$P/AGENTS.local.md"
  printf '# Our notes\nKeep it short.\n' > "$P/AGENTS.md"
  ok install "$P"
  says 'AGENTS.md moved into AGENTS.local.md'
  [ "$(head -n 1 "$P/AGENTS.local.md")" = 'Merge mode:        local' ] || fail "AGENTS.local.md lost its settings"
  grep -qx '## Notes moved from AGENTS.md' "$P/AGENTS.local.md" || fail "no heading in AGENTS.local.md"
  grep -qx 'Keep it short.' "$P/AGENTS.local.md" || fail "the notes did not reach AGENTS.local.md"
  head -n 1 "$P/AGENTS.md" | grep -qF '<!-- Assembled by Polype.' || fail "AGENTS.md was not assembled"
  grep -qx 'Keep it short.' "$P/AGENTS.md" || fail "the assembled AGENTS.md lacks the notes"
  if [ -e "$P/AGENTS.md.before-polype" ]; then fail "a backup was left after absorbing"; fi

  local W sums; W="$(new_project b)"
  printf '# Our notes\nKeep it short.\n' > "$W/AGENTS.md"
  ok install "$W"
  says 'run /po-setup'
  grep -qx 'Keep it short.' "$W/AGENTS.md.before-polype" || fail "without AGENTS.local.md the notes were not kept aside"
  printf 'Merge mode:        local\n' > "$W/AGENTS.local.md"
  ok update "$W"
  grep -qx 'Keep it short.' "$W/AGENTS.local.md" || fail "update did not absorb the kept AGENTS.md"
  if [ -e "$W/AGENTS.md.before-polype" ]; then fail "update left the backup after absorbing it"; fi
  sums="$(cksum < "$W/AGENTS.local.md") $(cksum < "$W/AGENTS.md")"
  ok update "$W"
  [ "$(cksum < "$W/AGENTS.local.md") $(cksum < "$W/AGENTS.md")" = "$sums" ] || fail "a second update changed AGENTS.local.md or AGENTS.md"

  local D before; D="$(new_project c)"
  printf 'new notes\n' > "$D/AGENTS.md"
  printf 'old notes\n' > "$D/AGENTS.md.before-polype"
  before="$(snapshot "$D")"
  stops install "$D"
  says 'run /po-setup first'
  [ "$(snapshot "$D")" = "$before" ] || fail "two hand-written copies without AGENTS.local.md were not both kept"

  local E; E="$(new_project d)"
  printf 'same notes\n' > "$E/AGENTS.md"
  printf 'same notes\n' > "$E/AGENTS.md.before-polype"
  ok install "$E"
  grep -qx 'same notes' "$E/AGENTS.md.before-polype" || fail "two identical copies were not kept aside as one"
}

test_hand_written_agents_md_is_absorbed_in_the_rules() {
  contains "$METHOD/AGENTS.md" 'except to append the notes it moves out of a `CLAUDE.md` or a hand-written `AGENTS.md`'
  contains "$METHOD/AGENTS.md" 'A hand-written root `AGENTS.md` is absorbed the same way, under `## Notes moved from AGENTS.md`'
  contains "$METHOD/AGENTS.md" 'unless `--set-aside` moves it (ADR-0088)'
  contains "$METHOD/commands/po-setup.md" 'the notes it moves out of a `CLAUDE.md` or a hand-written `AGENTS.md`.'
  contains "$ROOT/bin/polype" 'or a hand-written AGENTS.md.'
}

test_adr_records_the_contract() {
  local adrs=("$ROOT"/docs/decisions/ADR-0088-*.md)
  [ ${#adrs[@]} -eq 1 ] && [ -f "${adrs[0]}" ] || fail "expected exactly one ADR-0088"
  frontmatter "${adrs[0]}" | grep -qx 'status: accepted' || fail "ADR-0088 is not accepted"
  contains "${adrs[0]}" '--set-aside'
  contains "${adrs[0]}" '## Notes moved from AGENTS.md'
  contains "${adrs[0]}" 'ADR-0086'
  contains "${adrs[0]}" 'Écartée'
}
