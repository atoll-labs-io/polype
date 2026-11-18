#!/usr/bin/env bash
# s191 — the oracle of the story: `/po-orchestrator` and `/po-flow` are gone from the method, an
# update takes them out of a project, and the method loses words. `drive_takes_an_id` and
# `nothing_only_they_said_is_lost` speak to a model and are judged in review.

GONE="po-orchestrator po-flow"

# Word counts before s191 (LC_ALL=C wc -w), taken on fb21c56.
METHOD_WORDS_BEFORE=72702
FILE_WORDS_BEFORE="method/AGENTS.md:3739 method/commands/po-drive.md:2450 method/commands/po-help.md:758
method/commands/po-status.md:395 method/commands/po-execute.md:850 method/commands/po-research.md:764
method/agents/planner.md:1336 method/templates/plan-flow.md:735 method/skills/diagnostic/SKILL.md:452
README.md:1611 docs/migration.md:1737 docs/parite-killer-saas.md:3816 docs/direction.md:1192"

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

test_words_go_down() {
  local total=0 f n entry path limit
  while IFS= read -r -d '' f; do
    n="$(LC_ALL=C wc -w < "$f")"; total=$((total + n))
  done < <(find "$METHOD" -type f -print0)
  [ "$total" -le $((METHOD_WORDS_BEFORE - 3000)) ] \
    || fail "method/ holds $total words, not 3000 fewer than the $METHOD_WORDS_BEFORE it held before s191"
  for entry in $FILE_WORDS_BEFORE; do
    path="${entry%:*}"; limit="${entry##*:}"
    require_file "$ROOT/$path"
    n="$(LC_ALL=C wc -w < "$ROOT/$path")"
    [ "$n" -le "$limit" ] || fail "$path holds $n words, more than the $limit it held before s191"
  done
}
