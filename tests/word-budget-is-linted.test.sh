#!/usr/bin/env bash
# s205 — the budget rule's refusals the oracle leaves out, its arguments, and a count that is the same on
# every machine. The throwaway trees come from the oracle's helpers.
source <(sed '/^test_/,$d' "$ROOT/tests/word-budget-is-linted.oracle.test.sh")

last_line() { grep -c '' "$1/word-budget"; }

test_a_word_holding_a_non_breaking_byte_counts_once() {
  local m
  m="$(fresh)"; mkdir -p "$m/skills/x"
  # « à » is the bytes C3 A0; some coreutils read A0 as a blank in the C locale and count two words here.
  printf 'd\303\240-vu\n' > "$m/skills/x/SKILL.md"
  write_budget "$m" 0 0
  set_ceiling "$m" skills/x/SKILL.md 1
  lint "$m"
  [ "$LINT_RC" -eq 0 ] || fail "one word holding the bytes C3 A0 is not counted once: $LINT_OUT"
}

test_budget_lines_are_refused_when_wrong() {
  local m
  m="$(fresh)"; write_budget "$m" 0 0
  printf 'commands/po-a.md 999\n' >> "$m/word-budget"
  lint "$m"
  refuses_once "word-budget:$(last_line "$m")" "commands/po-a.md is listed twice" "a key on two lines"

  m="$(fresh)"; write_budget "$m" 0 0
  printf 'commands/po-a.md 5 extra\n' >> "$m/word-budget"
  lint "$m"
  refuses_once "word-budget:$(last_line "$m")" "malformed line" "a line with a third field that is no decision"

  m="$(fresh)"; write_budget "$m" 0 0
  printf 'skills/none.md 5\n' >> "$m/word-budget"
  lint "$m"
  refuses_once "word-budget:$(last_line "$m")" "skills/none.md is no .md file of method/" "an unknown key"

  m="$(fresh)"; write_budget "$m" 0 0
  printf '../docs/../README.md 5\n' >> "$m/word-budget"
  lint "$m"
  refuses_once "word-budget:$(last_line "$m")" "malformed line" "a document path with a .. part"
}

test_a_symlinked_md_is_counted() {
  local m
  m="$(fresh)"; write_budget "$m" 0 50
  mkdir -p "$m/skills"
  printf 'Five words behind a link.\n' > "${m%/method}/outside.md"
  ln -s "${m%/method}/outside.md" "$m/skills/linked.md"
  lint "$m"
  refuses_once "skills/linked.md:1" "no line in word-budget" "a symlinked .md file with no line"
  printf 'skills/linked.md 4\n' >> "$m/word-budget"
  lint "$m"
  refuses_once "word-budget:$(last_line "$m")" "skills/linked.md holds 5 words" "a symlinked .md file past its ceiling"
}

test_base_must_come_first_and_share_history() {
  local r m
  m="$(fresh)"; write_budget "$m" 0 0
  lint "$m" --base nowhere/x
  [ "$LINT_RC" -eq 2 ] || fail "a --base after the directory did not stop the run: $LINT_RC: $LINT_OUT"
  grep -qF 'usage: po-lint' <<< "$LINT_OUT" || fail "a misplaced --base gives no usage: $LINT_OUT"
  lint "$m" "$m"
  [ "$LINT_RC" -eq 2 ] || fail "a second directory did not stop the run: $LINT_RC: $LINT_OUT"

  r="$(mktemp -d "$S205_TMP/XXXXXX")"; as_repository "$r"
  m="$(small_method "$r")"; write_budget "$m" 0 0
  git -C "$r" add -A && git -C "$r" commit -qm base
  git -C "$r" checkout -q --orphan lone && git -C "$r" commit -qm lone && git -C "$r" checkout -q main
  lint --base lone "$m"
  [ "$LINT_RC" -eq 2 ] || fail "a base sharing no commit with HEAD did not stop the run: $LINT_RC: $LINT_OUT"
  grep -qF 'no base to compare the word budget with: lone' <<< "$LINT_OUT" \
    || fail "the unrelated base is not named: $LINT_OUT"
}
