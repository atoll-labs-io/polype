#!/usr/bin/env bash
# s41 — the capability catalogue: default bricks, contract tests, the architect's gaps.

SKILL="$METHOD/skills/capability-bricks/SKILL.md"
ARCHITECT="$METHOD/commands/po-architect.md"
PROFILE="$METHOD/templates/profile.md"

# The body of one `## <heading>` section of a file, heading excluded.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

# Each data row of the first table of a section, as tab-separated trimmed cells.
table_rows() {
  section_of "$1" "$2" | awk '
    /^\|/ {seen = 1
      n = split($0, cell, "|"); row = ""
      for (i = 2; i < n; i++) { c = cell[i]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", c); row = row (i > 2 ? "\t" : "") c }
      if (++count <= 2) next
      print row; next }
    seen {exit}
  '
}

# The twelve capability names, in order, as the profile template fixes them.
profile_names() { table_rows "$PROFILE" 'Capabilities' | cut -f1; }

test_skill_lists_the_capabilities_and_their_default_bricks() {
  local rows name default alternatives switch expected
  require_file "$SKILL"
  require_file "$PROFILE"
  contains "$SKILL" '| Capability | Default brick | Alternatives | Switch when |'
  rows=$(table_rows "$SKILL" 'Default bricks')
  [ "$(cut -f1 <<< "$rows")" = "$(profile_names)" ] \
    || fail "the default bricks table does not list the profile template's capabilities in order"
  while IFS=$'\t' read -r name default alternatives switch; do
    [ -n "$switch" ] || fail "$name has no switch condition"
    case "$name" in
      Database) expected='PostgreSQL|Postgres' ;;
      Auth) expected='Better Auth|Clerk' ;;
      Files) expected='Garage|Vercel Blob' ;;
      Jobs) expected='pg-boss|Inngest' ;;
      Email) expected='SMTP|Resend' ;;
      Payment) expected='Stripe|Polar' ;;
      'Cache and rate limiting') expected='Valkey|Upstash' ;;
      Observability) expected='OpenTelemetry|Sentry' ;;
      Deployment) expected='container image|' ;;
      Authorization|Multi-tenancy|i18n)
        [ "$alternatives" = '—' ] || fail "$name should have no alternative"
        continue ;;
      *) fail "unexpected capability: $name" ;;
    esac
    grep -qF -- "${expected%%|*}" <<< "$default" || fail "$name default does not name ${expected%%|*}"
    [ -z "${expected#*|}" ] || grep -qF -- "${expected#*|}" <<< "$alternatives" \
      || fail "$name alternatives do not name ${expected#*|}"
  done <<< "$rows"
}

test_skill_defines_what_a_contract_test_must_prove() {
  local rows name nominal refusal effect
  require_file "$SKILL"
  contains "$SKILL" '| Capability | Nominal behaviour | Expected refusal | Observable data effect |'
  contains "$SKILL" 'A contract test is written against the capability, never against one brick: every brick that implements it must pass the same tests.'
  rows=$(table_rows "$SKILL" 'Contract tests')
  [ "$(cut -f1 <<< "$rows")" = "$(profile_names)" ] \
    || fail "the contract tests table does not list the profile template's capabilities in order"
  while IFS=$'\t' read -r name nominal refusal effect; do
    for cell in "$nominal" "$refusal" "$effect"; do
      [ -n "$cell" ] && [ "$cell" != '—' ] || fail "$name leaves a contract column empty"
    done
  done <<< "$rows"
}

test_architect_chooses_bricks_and_records_the_gaps() {
  local step clause
  require_file "$ARCHITECT"
  step=$(section_of "$ARCHITECT" 'Step 3 — Structural decisions')
  for clause in \
    'capability-bricks' \
    'compare the brick the profile declares with the default brick of the skill' \
    'retain exactly one brick per capability' \
    'each gap is recorded in the project ADR of that capability' \
    'A gap is never settled in silence.'; do
    grep -qF -- "$clause" <<< "$step" || fail "step 3 does not say: $clause"
  done
}

test_self_hosted_edition_has_no_payment_brick() {
  local editions payment
  require_file "$SKILL"
  editions=$(section_of "$SKILL" 'Two editions')
  grep -qF 'The self-hosted edition is built without any payment brick.' <<< "$editions" \
    || fail "the self-hosted edition may carry a payment brick"
  grep -qF 'The managed offer carries subscription and usage billing.' <<< "$editions" \
    || fail "the managed offer does not carry subscription and usage billing"
  payment=$(table_rows "$SKILL" 'Default bricks' | awk -F'\t' '$1 == "Payment" {print $2}')
  grep -qF 'self-hosted edition has no payment brick' <<< "$payment" \
    || fail "the Payment default does not exclude the self-hosted edition"
}
