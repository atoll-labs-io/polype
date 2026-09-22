#!/usr/bin/env bash
# s16 — architecture on a boilerplate.

COMMAND="$METHOD/commands/po-architect.md"
TEMPLATE="$METHOD/templates/architecture.md"

# The body of one `## <heading>` section of a file, heading excluded.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

test_architect_asks_for_the_base() {
  require_file "$COMMAND"
  needs_tool "$COMMAND" AskUserQuestion
  contains "$COMMAND" 'a boilerplate from the catalogue or one the user owns'
  contains "$COMMAND" 'a scaffolded default, recorded as an ADR'
  contains "$COMMAND" 'an empty repository, assumed'
  contains "$COMMAND" 'Warn that parallelism will suffer:'
  contains "$COMMAND" 'This command never runs a generator or writes source code:'
}

test_architect_analyses_code_before_deciding() {
  local analysis decisions
  require_file "$COMMAND"
  require_file "$TEMPLATE"
  section_of "$COMMAND" 'Step 2 — Read the code before deciding' | grep -qF 'codebase-analysis' \
    || fail "step 2 does not apply codebase-analysis"
  contains "$COMMAND" 'No decision is drafted before this analysis is done.'
  analysis=$(grep -nxF '## Step 2 — Read the code before deciding' "$COMMAND" | cut -d: -f1)
  decisions=$(grep -nxF '## Step 3 — Structural decisions' "$COMMAND" | cut -d: -f1)
  [ -n "$analysis" ] && [ -n "$decisions" ] && [ "$analysis" -lt "$decisions" ] \
    || fail "the analysis does not come before the structural decisions"
  contains "$COMMAND" 'Write the conventions as rules in the `## Conventions` section of `AGENTS.local.md`'
  section_of "$TEMPLATE" 'Capabilities' | grep -qF '| Capability | Brick' \
    || fail "the architecture template has no capability table"
}

test_architect_records_structural_decisions_as_adrs() {
  local step
  require_file "$COMMAND"
  contains "$COMMAND" 'Each structural choice becomes one ADR in `<ADR directory>` from `templates/adr.md`'
  step=$(section_of "$COMMAND" 'Step 3 — Structural decisions')
  for word in stack capability integration; do
    grep -qF "$word" <<< "$step" || fail "step 3 does not name the $word"
  done
}

test_architect_never_rewrites_the_base() {
  require_file "$COMMAND"
  contains "$COMMAND" 'Never propose rewriting, replacing or restructuring the base: stories adapt to it.'
}

# s24 — a rerun completes the Conventions section instead of replacing it.
test_architect_merges_conventions_instead_of_replacing() {
  local step approval
  require_file "$COMMAND"
  step=$(section_of "$COMMAND" 'Step 4 — Conventions as rules')
  grep -qF 'keeps every rule already written there and adds the new ones after them' <<< "$step" \
    || fail "step 4 does not keep the rules already written on a rerun"
  grep -qF 'the section is never rewritten from scratch' <<< "$step" \
    || fail "step 4 does not forbid rewriting the section from scratch"
  grep -qF 'kept and reported, never deleted in passing' <<< "$step" \
    || fail "step 4 does not say what happens to a rule the code now contradicts"
  grep -qF 'a new rule that contradicts one already written is not added either' <<< "$step" \
    || fail "step 4 lets a contradicting rule be written in silence"
  ! grep -qF -- "section's placeholder or body" "$COMMAND" \
    || fail "the command still replaces the body of the Conventions section"
  approval=$(section_of "$COMMAND" 'Approval and commit')
  grep -qF 'what the new conventions would remove or contradict' <<< "$approval" \
    || fail "the grouped question does not show what a rerun would remove or contradict"
}

# s24 — the settings blocks are out of reach of step 4.
test_architect_protects_the_settings_blocks() {
  local step
  require_file "$COMMAND"
  step=$(section_of "$COMMAND" 'Step 4 — Conventions as rules')
  grep -qF 'Every settings block of `AGENTS.local.md` stays exactly as it is' <<< "$step" \
    || fail "step 4 does not leave the settings blocks untouched"
  grep -qF 'this command reads settings, it never decides them' <<< "$step" \
    || fail "step 4 does not repeat that settings are read, never decided"
  grep -qF 'edit no other section of that file' <<< "$step" \
    || fail "step 4 does not name the Conventions section as the only one it edits"
  grep -qF 'ask the user to edit the settings; do not change them' <<< "$step" \
    || fail "step 4 changes the settings itself when the base disagrees"
  ! grep -qF -- "section's placeholder or body" <<< "$step" \
    || fail "step 4 still replaces the body of the Conventions section"
}
