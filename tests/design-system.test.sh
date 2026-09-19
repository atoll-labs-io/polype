#!/usr/bin/env bash
# s17 — design system command, design-doctrine skill and template.

COMMAND="$METHOD/commands/po-design-system.md"
SKILL="$METHOD/skills/design-doctrine/SKILL.md"
TEMPLATE="$METHOD/templates/design-system.md"

# The body of one `## <heading>` section of a file, heading excluded.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

test_design_system_never_invents_an_identity() {
  require_file "$COMMAND"
  needs_tool "$COMMAND" AskUserQuestion
  contains "$COMMAND" 'This command never invents an identity:'
  section_of "$COMMAND" 'Step 1 — The source' \
    | grep -qF 'with no visual direction and no system in the base, stop and ask for the source' \
    || fail "step 1 does not stop and ask for the source"
}

test_design_system_measures_contrast_once() {
  local step
  require_file "$COMMAND"
  needs_tool "$COMMAND" Bash
  step=$(section_of "$COMMAND" 'Step 3 — Measure contrast')
  for phrase in 'This is the only stage that measures.' \
                'every text/surface pair, in light and in dark' \
                'fix the failing tokens'; do
    grep -qF "$phrase" <<< "$step" || fail "step 3 lacks: $phrase"
  done
}

test_design_doctrine_covers_new_vs_derived_and_gaps() {
  require_file "$SKILL"
  frontmatter "$SKILL" | grep -qxF 'name: design-doctrine' || fail "skill is not named design-doctrine"
  contains "$SKILL" 'The repository is the source of truth.'
  contains "$SKILL" 'A derived screen'
  contains "$SKILL" 'deltas'
  contains "$SKILL" 'no mockup'
  contains "$SKILL" 'A new screen'
  contains "$SKILL" 'exactly one artefact'
  contains "$SKILL" 'Never invent a component or a token.'
  contains "$SKILL" 'record the gap'
  contains "$SKILL" 'A mockup is a reference, never code:'
}

test_design_system_template_has_tokens_components_patterns() {
  require_file "$TEMPLATE"
  for heading in '## Tokens' '## Components' '## State patterns' "## Do / Don't"; do
    grep -qxF "$heading" "$TEMPLATE" || fail "template lacks $heading"
  done
  section_of "$TEMPLATE" 'Contrast' | grep -qF '| Theme |' || fail "contrast table has no Theme column"
  section_of "$TEMPLATE" 'Tokens' | grep -qF '| Light | Dark |' || fail "token table has no light and dark values"
}
