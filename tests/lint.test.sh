#!/usr/bin/env bash
# s25 — bin/po-lint. Contract of this file: a lint run on a green tree proves nothing,
# since it passes whether the script holds three rules or zero. So every test below
# copies method/, breaks exactly one invariant, and proves the lint sees that one.

MUTANTS="$(mktemp -d)"
trap 'rm -rf "$MUTANTS"' EXIT

# A fresh copy of method/, under the directory the test process removes when it exits.
# The trap has to live outside this function: `m=$(mutant)` runs it in a subshell.
mutant() {
  local dir
  dir="$(mktemp -d "$MUTANTS/XXXXXX")"
  cp -r "$METHOD" "$dir/method"
  echo "$dir/method"
}

lint_on() { LINT_STATUS=0; LINT_OUT=$(bash "$ROOT/bin/po-lint" "$@" 2>&1) || LINT_STATUS=$?; }

line_of() { grep -n -m1 -F -- "$2" "$1" | cut -d: -f1; }
line_of_exact() { grep -n -m1 -x -F -- "$2" "$1" | cut -d: -f1; }

# The lint must report exactly one breach on the mutant, at <file:line>, with that rule
# and that message — one mutation may never be caught by a rule it was not aimed at.
reports_one() {
  local dir="$1" where="$2" rule="$3" message="$4" count
  lint_on "$dir"
  [ "$LINT_STATUS" -ne 0 ] || fail "lint exited 0 on the mutant at $where"
  count=$(grep -c ': \[' <<< "$LINT_OUT" || true)
  [ "$count" = 1 ] || fail "expected one breach at $where, lint said: $LINT_OUT"
  grep -qF -- "$where: [$rule] $message" <<< "$LINT_OUT" \
    || fail "expected $where: [$rule] $message — lint said: $LINT_OUT"
}

test_lint_is_part_of_the_suite() {
  require_file "$ROOT/bin/po-lint"
  lint_on
  [ "$LINT_STATUS" -eq 0 ] || fail "po-lint reports breaches in method/: $LINT_OUT"
}

test_lint_checks_every_command_declares_its_settings() {
  local m f
  m=$(mutant); f="$m/commands/po-plan.md"
  sed -i '/^Reads settings:/d' "$f"
  reports_one "$m" "commands/po-plan.md:1" settings "no 'Reads settings:' line"

  m=$(mutant); f="$m/commands/po-plan.md"
  sed -i 's/^Reads settings: `[^`]*`/Reads settings: `Imaginary setting`/' "$f"
  reports_one "$m" "commands/po-plan.md:$(line_of "$f" 'Reads settings:')" \
    settings "reads unknown setting 'Imaginary setting'"
}

test_lint_checks_tool_permissions_match_the_contract() {
  local m f
  m=$(mutant); f="$m/commands/po-plan.md"
  sed -i '/^  - AskUserQuestion$/d' "$f"
  reports_one "$m" "commands/po-plan.md:$(line_of "$f" AskUserQuestion)" \
    tools "the body asks a question but AskUserQuestion is not declared"

  m=$(mutant); f="$m/commands/po-brief.md"
  sed -i 's/^  - Agent$/  - Agent\n  - Edit/' "$f"
  reports_one "$m" "commands/po-brief.md:$(line_of_exact "$f" '  - Edit')" \
    tools "declares Agent and Edit: whoever delegates does not edit"

  m=$(mutant); f="$m/commands/po-execute.md"
  sed -i 's/^  - Agent$/  - Agent\n  - Bash/' "$f"
  reports_one "$m" "commands/po-execute.md:$(line_of_exact "$f" '  - Bash')" \
    tools "says it cannot edit files or run a shell but declares Bash"

  m=$(mutant); f="$m/agents/reviewer.md"
  sed -i 's/^tools: \(.*\)$/tools: \1, Write/' "$f"
  reports_one "$m" "agents/reviewer.md:$(line_of "$f" 'tools:')" \
    tools "judges a story but declares Write"
}

test_lint_checks_fail_closed_rules_have_a_stop() {
  local m f
  m=$(mutant); f="$m/commands/po-design.md"
  sed -i 's|^\(.*`Design source` is `—`\) →.*|\1 → pick internal.|' "$f"
  reports_one "$m" "commands/po-design.md:$(line_of "$f" '`Design source` is `—`')" \
    fail-closed "an absence triggers no stop:"

  # Negative controls: the rule is narrow, not a machine that flags every arrow.
  # A non-blocking branch on a trigger that names no absence stays green inside a gate
  # section, and an absence outside the gate sections is not this rule's business.
  m=$(mutant); f="$m/commands/po-design.md"
  sed -i 's|^6\. The story has no screen.*|&\n- `replace` or `adapt` → continue.|' "$f"
  sed -i 's|^## Step 1 — Derived or new$|&\n- No mockup yet → continue.|' "$f"
  grep -qF '`replace` or `adapt` → continue.' "$f" || fail "negative control not applied"
  grep -qF 'No mockup yet → continue.' "$f" || fail "negative control not applied"
  lint_on "$m"
  [ "$LINT_STATUS" -eq 0 ] || fail "the fail-closed rule flags legitimate branches: $LINT_OUT"
}
