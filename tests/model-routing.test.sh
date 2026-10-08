#!/usr/bin/env bash
# s59 — deciders on the strong model, the implementer on a model fitted to the story's complexity.

TEMPLATE="$METHOD/templates/agents-local.md"
CMDS="$METHOD/commands"

# Fails unless one line of the file names `subagent_type: <role>` and `Model strong` together.
dispatches_on_strong() {
  grep -F -- "\`subagent_type: $2\`" "$1" | grep -qF '`Model strong`' \
    || fail "${1#"$ROOT"/} does not dispatch $2 on \`Model strong\` on the same line"
}

# Fails unless one line naming the implementer dispatch also names `Light up to`.
implementer_adapts_in() {
  grep -E -- '`subagent_type: implementer`|Delegate to `implementer`' "$1" | grep -qF '`Light up to`' \
    || fail "${1#"$ROOT"/} does not tie the implementer's model to \`Light up to\`"
}

test_settings_declare_the_model_routing() {
  local name row
  for name in "Model strong" "Model light" "Light up to"; do
    template_settings | grep -qx "$name" || fail "$name is not a setting of the template"
    row="$(grep -m1 "^| $name |" "$TEMPLATE" || true)"
    [ -n "$row" ] || fail "$name has no row in the values table"
    grep -qF '`—`' <<< "$row" || fail "the $name row does not say what \`—\` means"
  done
  grep -m1 '^| Model strong |' "$TEMPLATE" | grep -qF 'a name the Agent tool accepts' || fail "Model strong row lacks its values"
  grep -m1 '^| Model light |' "$TEMPLATE" | grep -qF '`Light up to`' || fail "Model light row does not point to Light up to"
  grep -m1 '^| Light up to |' "$TEMPLATE" | grep -qF 'highest story complexity' || fail "Light up to row lacks its meaning"
}

test_implementer_no_longer_pins_a_model() {
  local agent="$METHOD/agents/implementer.md"
  frontmatter "$agent" | grep -qx 'model: inherit' || fail "implementer must be model: inherit"
  ! frontmatter "$agent" | grep -qx 'model: opus' || fail "implementer still pins opus"
}

test_deciders_always_run_on_the_strong_model() {
  dispatches_on_strong "$CMDS/po-review.md" reviewer
  dispatches_on_strong "$CMDS/po-qa.md" qa
  dispatches_on_strong "$CMDS/po-stories-review.md" stories-reviewer
  dispatches_on_strong "$CMDS/po-flow.md" reviewer
  local role
  for role in planner designer qa reviewer; do dispatches_on_strong "$CMDS/po-drive.md" "$role"; done
  grep -F 'the `qa` subagent' "$CMDS/po-orchestrator.md" | grep -qF '`Model strong`' || fail "orchestrator QA stage lacks Model strong"
  grep -F 'Delegate to `reviewer`' "$CMDS/po-orchestrator.md" | grep -qF '`Model strong`' || fail "orchestrator review stage lacks Model strong"
  local f
  for f in po-review po-qa po-stories-review; do
    contains "$CMDS/$f.md" '`Model strong` missing → stop and name it.'
  done
}

test_only_the_implementer_adapts() {
  local exec="$CMDS/po-execute.md" f
  contains "$exec" 'The implementer gets `Model light` when the story'"'"'s complexity is at most `Light up to`, `Model strong` above it.'
  contains "$exec" 'the first line of `## Complexity` in `docs/research/<id>.md`'
  contains "$exec" 'No research file → the `Complexité`/`Complexity` of the story in `docs/stories.md`'
  contains "$exec" 'A fix run follows the same rule as the first run of the same story.'
  contains "$exec" 'A model setting at `—` passes no `model` at all'
  contains "$exec" 'Never retry with another model or with none'
  contains "$exec" '`subagent_type: implementer`, `model` as `## Model` settles'
  for f in po-drive po-orchestrator po-flow; do implementer_adapts_in "$CMDS/$f.md"; done
  grep -F 'fix-run sentence' "$CMDS/po-drive.md" | grep -qF '`Light up to`' || fail "drive fix runs drop the model rule"
  for f in po-orchestrator po-flow; do
    contains "$CMDS/$f.md" "run on the session's model, which no command can choose (ADR-0036)"
  done
}

test_drive_reports_the_model_of_each_lane() {
  local report
  report="$(awk '/^## Report/ {on=1; next} /^## / {on=0} on' "$CMDS/po-drive.md")"
  grep -qF 'shipped · models.' <<< "$report" || fail "the drive report table has no models column"
  grep -qF 'per lane and per stage, the model the subagent ran on' <<< "$report" || fail "the drive report does not state the model per lane and stage"
  grep -qF '`session` when `—` passed none' <<< "$report" || fail "the drive report does not say how a session model shows"
}

test_setup_offers_the_defaults() {
  local pair
  for pair in 'Model strong: opus' 'Model light: sonnet' 'Light up to: 2'; do
    contains "$CMDS/po-setup.md" "\`$pair\`"
  done
  grep -qE '^Model strong:[[:space:]]+opus$' "$TEMPLATE" || fail "template default for Model strong is not opus"
  grep -qE '^Model light:[[:space:]]+sonnet$' "$TEMPLATE" || fail "template default for Model light is not sonnet"
  grep -qE '^Light up to:[[:space:]]+2$' "$TEMPLATE" || fail "template default for Light up to is not 2"
}
