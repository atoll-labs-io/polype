#!/usr/bin/env bash
# s16 — architecture on a boilerplate.

COMMAND="$METHOD/commands/po-architect.md"

# The body of one `## <heading>` section of a file, heading excluded.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

test_architect_asks_for_the_base() {
  require_file "$COMMAND"
  needs_tool "$COMMAND" AskUserQuestion
  contains "$COMMAND" 'This command never runs a generator or writes source code:'
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
