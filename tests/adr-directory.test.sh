#!/usr/bin/env bash
# s46 — the ADR directory is a setting, not a fixed path.

test_settings_template_declares_the_adr_directory() {
  local template="$METHOD/templates/agents-local.md"
  template_settings | grep -qx 'ADR directory' || fail "the template declares no ADR directory setting"
  awk '/^```/ {fence=!fence; next} fence' "$template" | grep -qxE 'ADR directory:[[:space:]]+docs/decisions/' \
    || fail "ADR directory does not default to docs/decisions/"
}

test_lint_accepts_the_new_setting() {
  local out status=0
  out=$(bash "$ROOT/bin/po-lint" "$METHOD" 2>&1) || status=$?
  [ "$status" -eq 0 ] || fail "po-lint fails on method/: $out"

  LINT_COPY="$(mktemp -d)"
  trap 'rm -rf "$LINT_COPY"' EXIT
  cp -r "$METHOD" "$LINT_COPY/method"
  sed -i '/^ADR directory:/d' "$LINT_COPY/method/templates/agents-local.md"
  status=0
  out=$(bash "$ROOT/bin/po-lint" "$LINT_COPY/method" 2>&1) || status=$?
  [ "$status" -eq 1 ] || fail "po-lint exited $status without the ADR directory setting"
  grep -qF "reads unknown setting 'ADR directory'" <<< "$out" || fail "po-lint did not flag ADR directory: $out"
}
