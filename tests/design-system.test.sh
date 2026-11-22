#!/usr/bin/env bash
# s17 — design system command, design-doctrine skill and template.

COMMAND="$METHOD/commands/po-design-system.md"
SKILL="$METHOD/skills/design-doctrine/SKILL.md"

# The body of one `## <heading>` section of a file, heading excluded.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

test_design_system_never_invents_an_identity() {
  local paragraph phrase
  require_file "$COMMAND"
  needs_tool "$COMMAND" AskUserQuestion

  # The rule holds only if the paragraph that states it also says what happens instead.
  paragraph=$(section_of "$COMMAND" 'Step 3 — Measure contrast' \
    | awk -v RS='' 'index($0, "The command edits no source file:")')
  [ -n "$paragraph" ] || fail "step 3 does not say the command edits no source file"
  for phrase in 'handed to the person' \
                'a quick fix they name or through a story' \
                'the code still carries the old values'; do
    grep -qF -- "$phrase" <<< "$paragraph" || fail "the contrast fixes have no consequence: $phrase"
  done
}

test_design_system_measures_contrast_once() {
  require_file "$COMMAND"
  needs_tool "$COMMAND" Bash
}

test_design_doctrine_covers_new_vs_derived_and_gaps() {
  require_file "$SKILL"
  frontmatter "$SKILL" | grep -qxF 'name: design-doctrine' || fail "skill is not named design-doctrine"
}
