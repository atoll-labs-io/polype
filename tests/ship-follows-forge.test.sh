#!/usr/bin/env bash
# s102 — the ship follows the forge's review rule; a solo person's choice stays put.

TEMPLATE="$METHOD/templates/agents-local.md"
test_template_defaults_trust_the_gates() {
  local fenced
  fenced=$(awk '/^```/ {fence=!fence; next} fence' "$TEMPLATE")
  grep -qE '^Plan validation:[[:space:]]+autonomous$' <<< "$fenced" || fail "the template does not default Plan validation to autonomous"
  grep -qE '^Ship confirmation:[[:space:]]+automatic$' <<< "$fenced" || fail "the template does not default Ship confirmation to automatic"
}
