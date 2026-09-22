#!/usr/bin/env bash
# s18 — /po-design and its two templates.

COMMAND="$METHOD/commands/po-design.md"
SCREEN="$METHOD/templates/design-screen.md"
BRIEF="$METHOD/templates/design-brief.md"

# The body of one `## <heading>` section of a file, heading excluded.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

# Fails unless every phrase is found in the named section of the command.
section_holds() {
  local heading="$1" body phrase
  shift
  body=$(section_of "$COMMAND" "$heading")
  for phrase in "$@"; do
    grep -qF -- "$phrase" <<< "$body" || fail "section '$heading' lacks: $phrase"
  done
}

test_design_fails_closed_without_system_or_source() {
  require_file "$COMMAND"
  needs_tool "$COMMAND" AskUserQuestion
  section_holds 'Checks' \
    '`docs/design-system.md` is missing' \
    '`Design source` is `—`' \
    'Either way the command writes nothing and draws no mockup.'
}

# The phrases of the test above can survive their stop word: a decoy line holding the
# trigger would satisfy them. This one pins the occurrence that matters — each trigger
# appears once and that one stops — and that no production step precedes the gate.
test_design_test_message_matches_its_assertion() {
  local trigger hits checks checks_line first_step
  require_file "$COMMAND"
  for trigger in '`docs/design-system.md` is missing' '`Design source` is `—`'; do
    hits=$(grep -cF -- "$trigger" "$COMMAND" || true)
    [ "$hits" -eq 1 ] \
      || fail "'$trigger' appears $hits times in po-design.md: the stop could sit on another line"
    grep -F -- "$trigger" "$COMMAND" | grep -qF 'stop' \
      || fail "the line holding '$trigger' does not stop"
  done

  checks=$(section_of "$COMMAND" 'Checks')
  grep -qF 'Either way the command writes nothing and draws no mockup.' <<< "$checks" \
    || fail "section 'Checks' does not say both stops write nothing"
  hits=$(grep -cF 'no screen' <<< "$checks" || true)
  [ "$hits" -eq 1 ] \
    || fail "'no screen' appears $hits times in section 'Checks': another line could carry the rule"
  grep -F 'no screen' <<< "$checks" | grep -qF 'writing nothing' \
    || fail "the line holding 'no screen' does not say it writes nothing"

  checks_line=$(grep -n -x -F '## Checks' "$COMMAND" | cut -d: -f1)
  first_step=$(grep -n -E '^## (Step |Where the design lives)' "$COMMAND" | head -1 | cut -d: -f1)
  [ -n "$checks_line" ] || fail "po-design.md has no ## Checks section"
  [ -n "$first_step" ] || fail "po-design.md has no production section"
  [ "$checks_line" -lt "$first_step" ] || fail "a production section comes before ## Checks"
}

test_design_distinguishes_new_and_derived_screens() {
  require_file "$COMMAND"
  section_holds 'Step 2 — The note' 'the deltas only'
  section_holds 'Step 3 — The artefact' 'exactly one artefact' '`mockup.html`' '`brief.md`'
  require_file "$SCREEN"
  grep -qxF '## Deltas' "$SCREEN" || fail "design-screen template lacks ## Deltas"
  grep -qxF '## Artefact' "$SCREEN" || fail "design-screen template lacks ## Artefact"
  require_file "$BRIEF"
  grep -qxF '## System to use' "$BRIEF" || fail "design-brief template lacks ## System to use"
}

test_design_renders_and_looks_without_measuring() {
  require_file "$COMMAND"
  needs_tool "$COMMAND" Bash
  section_holds 'Step 4 — Look at the mockup' \
    'over local HTTP' \
    'in light and in dark' \
    'at desktop and at mobile width' \
    'Nothing is measured here.' \
    'what could not be seen'
}

test_design_lives_in_the_story_worktree() {
  require_file "$COMMAND"
  section_holds 'Checks' 'story/<id>'
  section_holds 'Where the design lives' \
    '`docs/designs/<id>/`' \
    'the story worktree' \
    'These files are the source of truth for the screen:'
}
