#!/usr/bin/env bash
# s197 — the oracle of the story: the three commands that work in their own context still lint and
# lose words. `routing_is_said_once`, `worktree_is_prepared_in_one_place` and
# `subagents_keep_their_procedure` speak to a model and are judged in review.

# Word counts before s197 (LC_ALL=C wc -w), taken on 2cd31f3, the story's start point.
THREE_BEFORE=2521
FILE_WORDS_BEFORE="commands/po-research.md:764 commands/po-plan.md:871 commands/po-design.md:886
commands/po-drive.md:2441 agents/planner.md:1336 agents/designer.md:959"

test_commands_still_lint() {
  local out f
  out="$(bash "$ROOT/bin/po-lint" "$METHOD" 2>&1)" || fail "bin/po-lint fails on method/: $out"
  for f in po-research po-plan po-design; do
    require_file "$METHOD/commands/$f.md"
    grep -q '^Reads settings: `' "$METHOD/commands/$f.md" || fail "$f.md lost its Reads settings line"
  done
  [ "$(tools_of "$METHOD/commands/po-research.md" | tr '\n' ' ')" = "Read Glob Grep Write Bash " ] \
    || fail "po-research.md tools changed: $(tools_of "$METHOD/commands/po-research.md" | tr '\n' ' ')"
  [ "$(tools_of "$METHOD/commands/po-plan.md" | tr '\n' ' ')" = "Read Glob Grep Write Bash AskUserQuestion " ] \
    || fail "po-plan.md tools changed: $(tools_of "$METHOD/commands/po-plan.md" | tr '\n' ' ')"
  [ -z "$(tools_of "$METHOD/commands/po-design.md")" ] || fail "po-design.md now limits its tools to a list"
}

test_words_go_down() {
  local total=0 f n entry path limit
  for f in po-research po-plan po-design; do
    require_file "$METHOD/commands/$f.md"
    n="$(LC_ALL=C wc -w < "$METHOD/commands/$f.md")"; total=$((total + n))
  done
  [ "$total" -le $((THREE_BEFORE - 700)) ] \
    || fail "the three commands hold $total words, not 700 fewer than the $THREE_BEFORE they held before s197"
  for entry in $FILE_WORDS_BEFORE; do
    path="${entry%:*}"; limit="${entry##*:}"
    require_file "$METHOD/$path"
    n="$(LC_ALL=C wc -w < "$METHOD/$path")"
    [ "$n" -le "$limit" ] || fail "method/$path holds $n words, more than the $limit it held before s197"
  done
}
