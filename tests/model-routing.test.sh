#!/usr/bin/env bash
# s59 — deciders on the strong model, the implementer on a model fitted to the story's complexity.

TEMPLATE="$METHOD/templates/agents-local.md"

test_settings_declare_the_model_routing() {
  local name
  for name in "Model strong" "Model light" "Light up to"; do
    template_settings | grep -qx "$name" || fail "$name is not a setting of the template"
  done
}

test_implementer_no_longer_pins_a_model() {
  local agent="$METHOD/agents/implementer.md"
  frontmatter "$agent" | grep -qx 'model: inherit' || fail "implementer must be model: inherit"
  ! frontmatter "$agent" | grep -qx 'model: opus' || fail "implementer still pins opus"
}

test_setup_offers_the_defaults() {
  grep -qE '^Model strong:[[:space:]]+opus$' "$TEMPLATE" || fail "template default for Model strong is not opus"
  grep -qE '^Model light:[[:space:]]+sonnet$' "$TEMPLATE" || fail "template default for Model light is not sonnet"
  grep -qE '^Light up to:[[:space:]]+2$' "$TEMPLATE" || fail "template default for Light up to is not 2"
}
