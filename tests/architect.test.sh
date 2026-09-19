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
  contains "$COMMAND" 'Each structural choice becomes one ADR in `docs/decisions/` from `templates/adr.md`'
  step=$(section_of "$COMMAND" 'Step 3 — Structural decisions')
  for word in stack capability integration; do
    grep -qF "$word" <<< "$step" || fail "step 3 does not name the $word"
  done
}

test_architect_never_rewrites_the_base() {
  require_file "$COMMAND"
  contains "$COMMAND" 'Never propose rewriting, replacing or restructuring the base: stories adapt to it.'
}
