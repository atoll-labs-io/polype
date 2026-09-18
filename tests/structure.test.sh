#!/usr/bin/env bash
# s01 — rules and settings.

M1_SETTINGS="Merge mode|Target branch|Plan validation|Ship confirmation|Test budget|Verification mode|Full suite|E2E stage|E2E scope|E2E browsers|Build stage|Issue tracker|Worktree root|Package manager|Install|Test|Typecheck|E2E|Build"

test_settings_template_one_value_per_line() {
  local bad
  bad=$(awk '/^```/ {fence=!fence; next} fence && NF' "$METHOD/templates/agents-local.md" \
    | grep -vE '^[A-Z][A-Za-z0-9 ]*:[[:space:]]+[^[:space:]#][^#]*$' || true)
  [ -z "$bad" ] || fail "malformed setting lines: $bad"
}

test_settings_template_declares_all_m1_settings() {
  local name missing=""
  IFS='|' read -ra names <<< "$M1_SETTINGS"
  for name in "${names[@]}"; do
    template_settings | grep -qx "$name" || missing+="$name, "
  done
  [ -z "$missing" ] || fail "missing from template: $missing"
}

test_every_setting_read_by_a_command_exists_in_template() {
  local f name bad=""
  for f in "$METHOD"/commands/*.md "$METHOD"/agents/*.md; do
    [ -f "$f" ] || continue
    grep -q '^Reads settings:' "$f" || { bad+="${f##*/} has no Reads settings line; "; continue; }
    while IFS= read -r name; do
      [ -n "$name" ] || continue
      template_settings | grep -qx "$name" || bad+="${f##*/} reads unknown setting '$name'; "
    done < <(settings_read_by "$f")
  done
  [ -z "$bad" ] || fail "$bad"
}

test_setup_never_overwrites_settings() {
  local f="$METHOD/commands/po-setup.md"
  require_file "$f" && contains "$f" "Never overwrite" && contains "$f" "already exist"
}

test_rules_state_absolute_rule_and_quick_fix_bounds() {
  local f="$METHOD/AGENTS.md"
  require_file "$f" \
    && contains "$f" "No code is written outside the pipeline" \
    && contains "$f" "### Quick fix" \
    && contains "$f" "It never covers" \
    && contains "$f" "A defect is not a story"
}
