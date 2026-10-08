#!/usr/bin/env bash
# s97 — commands and texts follow M8.

RETRO="$METHOD/commands/po-retro.md"
SR="$METHOD/skills/stories-review/SKILL.md"
DD="$METHOD/skills/design-doctrine/SKILL.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

test_retro_prefers_an_exact_milestone() {
  require_file "$RETRO"
  local scope row a b c
  scope=$(section_of "$RETRO" 'Scope')
  a=$(printf '%s\n' "$scope" | grep -n -F 'whose whole text, after its `#` marks, equals the argument' | head -1 | cut -d: -f1)
  b=$(printf '%s\n' "$scope" | grep -n -F 'the label being the text before the first' | head -1 | cut -d: -f1)
  c=$(printf '%s\n' "$scope" | grep -n -F 'a heading whose text starts with it' | head -1 | cut -d: -f1)
  [ -n "$a" ] && [ -n "$b" ] && [ -n "$c" ] || fail "Scope lacks a precedence step"
  printf '%s' "$scope" | grep -qF 'the first step that matches anything decides' || fail "Scope lacks first-step rule"
  # the three steps sit in one bullet: equality must be read before prefix within it
  local line
  line=$(printf '%s\n' "$scope" | grep -F 'the first step that matches anything decides')
  case "${line%%starts with it*}" in *"equals the argument"*) ;; *) fail "exact match must precede the prefix rule" ;; esac
  row=$(grep -F '**majors still open**' "$RETRO")
  printf '%s' "$row" | grep -qF 'not blocked' || fail "majors row lacks the not-blocked clause"
}

test_texts_follow_m8() {
  local setup="$METHOD/commands/po-setup.md" help="$METHOD/commands/po-help.md"
  local d15 expo h
  require_file "$setup"; require_file "$help"
  h=$(grep -m1 '^## Step 2' "$setup")
  for p in 'Platform' 'QA stage' 'catalogue'; do
    printf '%s' "$h" | grep -qF -- "$p" || fail "Step 2 heading lacks: $p"
  done
  printf '%s' "$h" | grep -qF 'plus one follow-up on design' && fail "Step 2 heading still counts one follow-up"
  grep -qF "une story sans ligne \`Surface\` n'y va que si elle a un écran" "$help" || fail "po-help lacks the no-Surface rule"
  d15=$(grep -F '| D15 |' "$ROOT/docs/parite-killer-saas.md")
  printf '%s' "$d15" | grep -qF 'cinq signaux' && fail "D15 still counts five signals"
  printf '%s' "$d15" | grep -qF 'Fixes' || fail "D15 lacks the Fixes signal"
  expo=$(grep -F 'expo_profile_names_its_web_render' "$ROOT/docs/stories.md" | head -1)
  printf '%s' "$expo" | grep -qF 'et sa commande `Test` accepte des chemins' && fail "Expo criterion still claims a template Test command"
  printf '%s' "$expo" | grep -qF "qu'une première story installe" || fail "Expo criterion lacks the first-story clause"
}

test_stories_review_checks_owned_records() {
  require_file "$SR"
  local l maj
  l=$(section_of "$SR" 'Checks, in this order' | awk '/^\*\*10\./ {on=1} /^$/ {on=0} on')
  [ -n "$l" ] || fail "no check 10"
  for p in 'Fixes' 'Owns' 'supersedes' 'superseded-by'; do
    printf '%s' "$l" | grep -qF -- "$p" || fail "check 10 lacks: $p"
  done
  maj=$(section_of "$SR" 'Severity' | grep -F '**major**')
  printf '%s' "$maj" | grep -qF 'without owning' || fail "major list lacks the owned-records breach"
  grep -qF 'docs/defauts.md' "$SR" && fail "skill names a Polype path"
  return 0
}

test_keyboard_walk_test_bites() {
  local t="$ROOT/tests/accessibility.test.sh" n
  grep -qF "'written down as a finding'" "$t" || fail "accessibility test lacks the exact phrase"
  grep -qF "'cannot reach' 'finding'" "$t" && fail "accessibility test still asserts the bare finding"
  n=$(section_of "$DD" 'Driving a browser' | grep -cF 'written down as a finding')
  [ "$n" = 1 ] || fail "phrase must sit on exactly one line, found $n"
  section_of "$DD" 'Driving a browser' | grep -F 'written down as a finding' | grep -qF 'keyboard alone' || fail "phrase is not on the keyboard line"
}
