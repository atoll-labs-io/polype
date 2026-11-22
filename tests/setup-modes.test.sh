#!/usr/bin/env bash
# s11 — framing settings in the settings template.

TEMPLATE="$METHOD/templates/agents-local.md"

# The values-table row of a setting.
table_row() { grep -m1 "^| $1 |" "$TEMPLATE" || true; }

test_settings_template_declares_framing_settings() {
  local name value row missing=""
  for name in "Entry mode" "Design source" "Design skill" "Design tool" "Story track" "Flow threshold"; do
    template_settings | grep -qx "$name" || missing+="$name not in a block; "
    [ -n "$(table_row "$name")" ] || missing+="$name not in the values table; "
  done
  for pair in "Entry mode:replace" "Entry mode:adapt" "Entry mode:new" \
              "Design source:internal" "Design source:external" "Design source:—" \
              "Story track:full" "Story track:flow" "Story track:auto"; do
    name="${pair%%:*}" value="${pair#*:}"
    row=$(table_row "$name")
    [[ "$row" == *"\`$value\`"* ]] || missing+="$name row lacks \`$value\`; "
  done
  [ -z "$missing" ] || fail "$missing"
}
