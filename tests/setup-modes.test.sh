#!/usr/bin/env bash
# s11 — framing settings and setup questions.

TEMPLATE="$METHOD/templates/agents-local.md"
SETUP="$METHOD/commands/po-setup.md"

# The values-table row of a setting.
table_row() { grep -m1 "^| $1 |" "$TEMPLATE" || true; }

# The body of setup's step 2, heading excluded.
setup_step2() { awk '/^## Step 2/ {on=1; next} /^## / {on=0} on' "$SETUP"; }

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

test_setup_asks_entry_mode_and_design_source() {
  local step count
  step=$(setup_step2)
  count=$(grep -cE '^[0-9]+\. ' <<< "$step" || true)
  [ "$count" -eq 5 ] || fail "step 2 lists $count questions, expected 5"
  grep -qE '^[0-9]+\. .*`Entry mode`' <<< "$step" || fail "no question sets \`Entry mode\`"
  grep -qE '^[0-9]+\. .*`Design source`' <<< "$step" || fail "no question sets \`Design source\`"
  contains "$SETUP" 'Nothing else is asked'
}

test_setup_never_defaults_design_silently() {
  contains "$SETUP" 'A `Design source` left at `—` is not a choice: every design command stops on it and asks for the source again.'
  contains "$SETUP" 'Setup never fills it on the user'"'"'s behalf.'
}
