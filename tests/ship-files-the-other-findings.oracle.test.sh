#!/usr/bin/env bash
# s179 — the oracle of the story: `/po-ship` files the findings that are not security ones. Three
# criteria speak to a model and are judged in review; only the word counts are read by a script.

# Word counts before s179 (LC_ALL=C wc -w). The ceilings of tests/drive-executes-next.oracle.test.sh,
# tests/commands-read-po-state.test.sh, tests/answer-comes-back.test.sh and tests/decision-inbox.test.sh hold too.
test_words_hold() {
  local f limit words
  for f in commands/po-ship.md:3302 commands/po-drive.md:2483 commands/po-retro.md:976 AGENTS.md:3739; do
    limit="${f##*:}"; words="$(LC_ALL=C wc -w < "$METHOD/${f%:*}")"
    [ "$words" -le "$limit" ] || fail "${f%:*} holds $words words, more than the $limit it held before s179"
  done
}
