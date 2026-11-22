#!/usr/bin/env bash
# s191 — the oracle of the story: `/po-orchestrator` and `/po-flow` are gone from the method, and an
# update takes them out of a project. `drive_takes_an_id` and `nothing_only_they_said_is_lost`
# speak to a model and are judged in review.

GONE="po-orchestrator po-flow"

test_two_commands_are_gone() {
  local name named out
  for name in $GONE; do
    [ ! -e "$METHOD/commands/$name.md" ] || fail "method/commands/$name.md still exists"
  done
  named="$(grep -rlE 'po-orchestrator|po-flow' "$METHOD" "$ROOT/README.md" || true)"
  [ -z "$named" ] || fail "still naming a removed command: $named"
  out="$(bash "$ROOT/bin/po-lint" "$METHOD" 2>&1)" || fail "bin/po-lint fails: $out"
}

test_update_removes_them_from_a_project() {
  scratch_repo
  export HOME="$SCRATCH/home" CLAUDE_CONFIG_DIR="$SCRATCH/home/.claude"
  mkdir -p "$CLAUDE_CONFIG_DIR"
  local old="$SCRATCH/previous" P="$SCRATCH/project" name out status=0 state
  # The previous version: today's method, with the two commands it still shipped.
  mkdir -p "$old" "$P"
  cp -r "$ROOT/bin" "$ROOT/method" "$old/"
  for name in $GONE; do
    [ -f "$old/method/commands/$name.md" ] \
      || printf -- '---\ndescription: %s, as the previous version shipped it\n---\n# /%s\n' "$name" "$name" \
        > "$old/method/commands/$name.md"
  done
  git -C "$P" init -q -b main
  out="$(bash "$old/bin/polype" install "$P" 2>&1)" || fail "install with the previous version failed: $out"
  for name in $GONE; do
    [ -f "$P/.claude/commands/$name.md" ] || fail "the previous version did not lay $name.md"
  done

  out="$(bash "$ROOT/bin/polype" update "$P" 2>&1)" || status=$?
  [ "$status" -eq 0 ] || fail "update failed ($status): $out"
  for name in $GONE; do
    [ ! -e "$P/.claude/commands/$name.md" ] || fail "update left .claude/commands/$name.md: $out"
    [ ! -e "$P/.claude/commands/$name.md.before-polype" ] || fail "update set $name.md aside"
    ! grep -qF "commands/$name.md" <<< "$out" || fail "update kept $name.md as the person's file: $out"
    for state in "$P/.polype/manifest" "$P/.polype/checksums" "$P/.claude/.polype-checksums"; do
      [ ! -f "$state" ] || ! grep -qF "commands/$name.md" "$state" || fail "${state#"$P"/} still lists $name.md"
    done
  done
  [ -z "$(find "$P" -path "$P/.git" -prune -o -name '*polype.kept*' -print)" ] || fail "update kept a copy aside"
}
