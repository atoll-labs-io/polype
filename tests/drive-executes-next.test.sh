#!/usr/bin/env bash
# s173 — /po-execute gained one shell command without growing (#241 m7).

test_execute_does_not_grow() {
  local f="$METHOD/commands/po-execute.md" words
  require_file "$f"
  words="$(LC_ALL=C wc -w < "$f")"
  [ "$words" -le 854 ] || fail "po-execute.md holds $words words, past 854"
}
