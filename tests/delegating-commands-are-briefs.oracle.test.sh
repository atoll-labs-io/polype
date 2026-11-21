#!/usr/bin/env bash
# s198 — the oracle of the story: `/po-execute`, `/po-qa` and `/po-review` keep the brief of their
# subagent and the recording of its answer. Only the lint and the word counts are read by a script;
# `routing_is_said_once`, `drive_and_commands_share_one_text` and `nothing_is_lost` speak to a model
# and are judged in review.

PO_NEXT_TOOL='Bash("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" next)'

# Word counts before s198 (LC_ALL=C wc -w), taken on bec755c.
THREE_BEFORE=2704
FILE_WORDS_BEFORE="po-execute:847 po-qa:712 po-review:1145 po-drive:2413 po-help:718"

sorted_tools() { tools_of "$METHOD/commands/$1.md" | LC_ALL=C sort | tr '\n' '|'; }

test_commands_still_lint() {
  local out rc=0 f
  out="$(bash "$ROOT/bin/po-lint" "$METHOD" 2>&1)" || rc=$?
  [ "$rc" -eq 0 ] || fail "bin/po-lint refuses method/ ($rc): $out"
  for f in po-execute po-qa po-review; do
    require_file "$METHOD/commands/$f.md"
    grep -q '^Reads settings: ' "$METHOD/commands/$f.md" || fail "$f.md lost its Reads settings: line"
  done
  # ADR-0120: /po-execute runs po next and nothing else; /po-review gains the same narrow form.
  [ "$(sorted_tools po-execute)" = "Agent|$PO_NEXT_TOOL|Glob|Grep|Read|" ] \
    || fail "po-execute tools are not exactly Read, Glob, Grep, Agent and po next: $(sorted_tools po-execute)"
  local review="Agent|$PO_NEXT_TOOL|"'Bash("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" record review:*)|Bash(.polype/hooks/po-gate.sh findings-shape:*)|Glob|Grep|Read|Write|'
  [ "$(sorted_tools po-review)" = "$review" ] \
    || fail "po-review tools are not its narrow set plus po next: $(sorted_tools po-review)"
  [ "$(sorted_tools po-qa)" = "Agent|Bash|Glob|Grep|Read|" ] \
    || fail "po-qa tools changed: $(sorted_tools po-qa)"
}

test_words_go_down() {
  local total=0 f n entry name limit
  for f in po-execute po-qa po-review; do
    n="$(LC_ALL=C wc -w < "$METHOD/commands/$f.md")"; total=$((total + n))
  done
  [ "$total" -le $((THREE_BEFORE - 650)) ] \
    || fail "the three commands hold $total words, not 650 fewer than the $THREE_BEFORE they held before s198"
  for entry in $FILE_WORDS_BEFORE; do
    name="${entry%:*}"; limit="${entry##*:}"
    n="$(LC_ALL=C wc -w < "$METHOD/commands/$name.md")"
    [ "$n" -le "$limit" ] || fail "$name.md holds $n words, more than the $limit it held before s198"
  done
}
