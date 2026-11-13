#!/usr/bin/env bash
# s163 — two lanes in QA share neither a browser nor a port; the rule costs no words.

# Word counts of main 89ecf0d, before s163.
SKILL_WORDS_BEFORE=554
QA_WORDS_BEFORE=1013

test_no_file_grows() {
  local skill="$METHOD/skills/qa-drivers/SKILL.md" agent="$METHOD/agents/qa.md" words
  require_file "$skill"
  require_file "$agent"
  words="$(wc -w < "$skill")"
  [ "$words" -le "$SKILL_WORDS_BEFORE" ] \
    || fail "qa-drivers/SKILL.md grew: $words words, $SKILL_WORDS_BEFORE before s163"
  words="$(wc -w < "$agent")"
  [ "$words" -le "$QA_WORDS_BEFORE" ] \
    || fail "agents/qa.md grew: $words words, $QA_WORDS_BEFORE before s163"
}
