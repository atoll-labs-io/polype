#!/usr/bin/env bash
# s162 — the oracle of the story. Its first three criteria speak to a model (case 3 of the M20 rule of
# 2026-11-13): the reviewer judges them by reading, and no test here looks for their phrases.

# Ceilings: each file's word count on main at 756cb05, the story's start point, as `LC_ALL=C wc -w` counts it.
test_no_file_grows() {
  local entry path ceiling words
  for entry in \
    'agents/designer.md 967' \
    'templates/stories.md 315' \
    'skills/agentic-stories/SKILL.md 1119' \
    'skills/stories-review/SKILL.md 1248' \
    'agents/stories-reviewer.md 451' \
    'commands/po-setup.md 2278'; do
    path="${entry% *}"; ceiling="${entry##* }"
    require_file "$METHOD/$path"
    words="$(LC_ALL=C wc -w < "$METHOD/$path" | tr -d ' ')"
    [ "$words" -le "$ceiling" ] || fail "method/$path holds $words words, $ceiling before s162"
  done
}
