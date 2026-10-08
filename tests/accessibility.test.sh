#!/usr/bin/env bash
# s91 — accessibility beyond contrast in design-doctrine.

SKILL="$METHOD/skills/design-doctrine/SKILL.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

test_doctrine_covers_more_than_contrast() {
  local body phrase
  require_file "$SKILL"
  grep -qxF '## Accessibility' "$SKILL" || fail "no ## Accessibility section"
  body=$(section_of "$SKILL" 'Accessibility')
  for phrase in '**Visible focus**' '**Named controls**' '**Text alternatives**' '**Not by colour alone**' \
    'tab order' 'label' 'accessible name' 'alternative text' 'colour alone'; do
    printf '%s' "$body" | grep -qF -- "$phrase" || fail "Accessibility section lacks: $phrase"
  done
}

test_qa_walks_with_the_keyboard() {
  local body phrase
  require_file "$SKILL"
  body=$(section_of "$SKILL" 'Driving a browser')
  for phrase in 'keyboard alone' 'cannot reach' 'finding'; do
    printf '%s' "$body" | grep -qF -- "$phrase" || fail "Driving a browser lacks: $phrase"
  done
}
