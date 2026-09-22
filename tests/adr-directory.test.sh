#!/usr/bin/env bash
# s46 — the ADR directory is a setting, not a fixed path.

ADR_READERS=(
  commands/po-architect.md commands/po-plan.md commands/po-brief.md commands/po-drive.md commands/po-status.md
  agents/planner.md agents/implementer.md agents/reviewer.md agents/designer.md agents/stories-reviewer.md
)

test_settings_template_declares_the_adr_directory() {
  local template="$METHOD/templates/agents-local.md"
  template_settings | grep -qx 'ADR directory' || fail "the template declares no ADR directory setting"
  awk '/^```/ {fence=!fence; next} fence' "$template" | grep -qxE 'ADR directory:[[:space:]]+docs/decisions/' \
    || fail "ADR directory does not default to docs/decisions/"
  grep -F '| ADR directory |' "$template" | grep -qF "where the project's ADRs live, with its own numbering" \
    || fail "the values table does not document ADR directory"
}

test_rules_read_the_adr_directory_instead_of_a_fixed_path() {
  contains "$METHOD/AGENTS.md" 'Structural decisions are ADRs in `<ADR directory>NNNN-<slug>.md`'
  ! grep -qF 'docs/decisions/' "$METHOD/AGENTS.md" || fail "method/AGENTS.md still names docs/decisions/"
}

test_every_command_that_writes_an_adr_reads_the_setting() {
  local f
  for f in "${ADR_READERS[@]}"; do
    settings_read_by "$METHOD/$f" | grep -qx 'ADR directory' || fail "$f does not read ADR directory"
    ! grep -qF 'docs/decisions/' "$METHOD/$f" || fail "$f still names docs/decisions/"
  done
  ! grep -qF '(decisions/' "$METHOD/templates/architecture.md" \
    || fail "templates/architecture.md still links ADRs under decisions/"
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
