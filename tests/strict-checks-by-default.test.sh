#!/usr/bin/env bash
# s147 — the strict check: declared by each profile, retained by /po-architect through
# a project ADR, reaching the project through Typecheck only (ADR-0097).

PROFILE="$METHOD/templates/profile.md"
ARCHITECT="$METHOD/commands/po-architect.md"
ARCH_TEMPLATE="$METHOD/templates/architecture.md"
STRICT_FIELDS=("Strict check" "Turned on by" "Passes at the commit profiled")

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

# Value of the `- <field>:` line of the `## Strictness` section of a profile.
strict_value() {
  section_of "$1" Strictness | grep -m1 -F -- "- $2:" | sed "s/^- $2:[[:space:]]*//; s/[[:space:]]*$//"
}

test_profile_declares_strictness() {
  require_file "$PROFILE"
  grep -qxF '## Strictness' "$PROFILE" || fail "profile template lacks '## Strictness'"
  local field m p out status heading_line
  for field in "${STRICT_FIELDS[@]}"; do
    section_of "$PROFILE" Strictness | grep -q "^- $field:" || fail "template Strictness lacks '- $field:'"
  done
  contains "$PROFILE" '`## Strictness` must hold its three lines'

  STRICT_TMP="$(mktemp -d)"; trap 'rm -rf "$STRICT_TMP"' EXIT
  lint() { status=0; out=$(bash "$ROOT/bin/po-lint" "$m/method" 2>&1) || status=$?; }
  fresh() {
    m="$(mktemp -d "$STRICT_TMP/XXXXXX")"
    cp -r "$METHOD" "$m/method"
    mkdir -p "$m/boilerplates/demo"
    p="$m/boilerplates/demo/profile.md"
    cp "$PROFILE" "$p"
  }

  fresh; lint
  [ "$status" -eq 0 ] || fail "lint rejects a profile built from the template: $out"

  fresh
  sed -i '/^## Strictness$/d' "$p"
  lint
  [ "$status" -ne 0 ] || fail "lint accepts a profile without '## Strictness'"
  grep -qF "boilerplates/demo/profile.md:1: [profile] missing section '## Strictness'" <<< "$out" \
    || fail "lint does not name the missing section: $out"

  for field in "${STRICT_FIELDS[@]}"; do
    fresh
    sed -i "/^- $field:/d" "$p"
    ! grep -q "^- $field:" "$p" || fail "mutation not applied: '- $field:' still there"
    heading_line=$(grep -n -m1 -x '## Strictness' "$p" | cut -d: -f1)
    lint
    [ "$status" -ne 0 ] || fail "lint accepts a profile without '- $field:'"
    [ "$(grep -c ': \[' <<< "$out")" = 1 ] || fail "expected one breach without '- $field:', lint said: $out"
    grep -qF "boilerplates/demo/profile.md:$heading_line: [profile] no '- $field:' line under '## Strictness'" <<< "$out" \
      || fail "lint does not name the missing '- $field:' line: $out"
  done
}

test_every_profile_fills_strictness() {
  local profiles f name field value passes count=0 out status=0
  profiles=$(ls "$ROOT"/boilerplates/*/profile.md)
  for f in $profiles; do
    count=$((count + 1))
    name="${f#"$ROOT"/boilerplates/}"; name="${name%/profile.md}"
    grep -qxF '## Strictness' "$f" || fail "$name: no '## Strictness' section"
    for field in "${STRICT_FIELDS[@]}"; do
      value=$(strict_value "$f" "$field")
      [ -n "$value" ] || fail "$name: no value on '- $field:'"
      [[ "$value" != *"<"* ]] || fail "$name: '- $field:' still holds a placeholder: $value"
    done
    passes=$(strict_value "$f" "Passes at the commit profiled")
    case "$passes" in yes|no|"not run") ;; *) fail "$name: Passes is '$passes', not yes, no or not run" ;; esac
    if [ "$(strict_value "$f" "Strict check")" = "—" ]; then
      [ "$(strict_value "$f" "Turned on by")" = "—" ] || fail "$name: no strict check but 'Turned on by' is not —"
      [ "$passes" = "not run" ] || fail "$name: no strict check but Passes is '$passes'"
      section_of "$f" Strictness | grep -qv '^- \|^$' || fail "$name: no strict check and no reason given"
    fi
  done
  [ "$count" -eq 9 ] || fail "expected nine profiles, found $count"
  out=$(bash "$ROOT/bin/po-lint" 2>&1) || status=$?
  [ "$status" -eq 0 ] || fail "po-lint reports breaches on the real tree: $out"
}

test_architect_retains_strict() {
  require_file "$ARCHITECT"
  local step3
  step3=$(section_of "$ARCHITECT" "Step 3 — Structural decisions")
  grep -qF -- '- the strict check:' <<< "$step3" || fail "Step 3 drafts no ADR on the strict check"
  grep -qF 'retained by default' <<< "$step3" || fail "Step 3 does not retain the strict check by default"
  grep -qF 'only through that ADR' <<< "$step3" || fail "Step 3 does not make the ADR the only derogation"
  grep -qF 'ranked like the others' <<< "$step3" || fail "Step 3 does not rank the strict-check options"
}

test_strict_command_reaches_typecheck() {
  require_file "$ARCHITECT"; require_file "$ARCH_TEMPLATE"
  local step4 body
  step4=$(section_of "$ARCHITECT" "Step 4 — Conventions as rules")
  grep -qF 'reaches the project through `Typecheck`, never through a setting of its own' <<< "$step4" \
    || fail "Step 4 does not route the strict check through Typecheck"
  grep -qF 'ask the person to do it' <<< "$step4" || fail "Step 4 does not leave the edit to the person"
  ! template_settings | grep -qE 'Strict|Lint' || fail "a setting of its own was added for the strict check"
  ! settings_read_by "$ARCHITECT" | grep -qE 'Strict|Lint' || fail "/po-architect reads a strict or lint setting"
  body=$(section_of "$ARCH_TEMPLATE" "Strict check")
  [ -n "$body" ] || fail "templates/architecture.md has no '## Strict check' section"
  grep -qF '`Typecheck`' <<< "$body" || fail "the Strict check section does not name Typecheck"
}

test_strict_switch_is_a_story() {
  local step4 body
  step4=$(section_of "$ARCHITECT" "Step 4 — Conventions as rules")
  grep -qF '`no` or `not run`' <<< "$step4" || fail "Step 4 does not handle a base that does not pass"
  grep -qF 'as a story to write' <<< "$step4" || fail "Step 4 does not name the switch as a story"
  grep -qF 'only once that story has shipped' <<< "$step4" || fail "Step 4 lets the strict command in too early"
  body=$(section_of "$ARCH_TEMPLATE" "Strict check")
  grep -qF 'not yet: the story' <<< "$body" || fail "the architecture template does not name the switch story"
}

test_adr_records_strict_default() {
  local adr options b c d
  adr=$(ls "$ROOT"/docs/decisions/ADR-0097-le-controle-strict-par-defaut.md 2>/dev/null) \
    || fail "ADR-0097 is missing"
  frontmatter "$adr" | grep -qx 'status: accepted' || fail "ADR-0097 is not accepted"
  frontmatter "$adr" | grep -qx 'supersedes: \[\]' || fail "ADR-0097 supersedes something"
  options=$(section_of "$adr" "Considered Options")
  grep -qF 'Strict par défaut, dérogation par une ADR de projet' <<< "$options" || fail "option A is not the strict default"
  b=$(grep -n -m1 'sans exception' <<< "$options" | cut -d: -f1)
  c=$(grep -n -m1 'Le recommander seulement' <<< "$options" | cut -d: -f1)
  d=$(grep -n -m1 'Un réglage `Lint` à part' <<< "$options" | cut -d: -f1)
  [ -n "$b" ] && [ -n "$c" ] && [ -n "$d" ] || fail "a rejected option is missing (b=$b c=$c d=$d)"
  [ "$b" -lt "$c" ] && [ "$c" -lt "$d" ] || fail "rejected options are not in the story's order"
  [ "$(grep -c 'Écartée' <<< "$options")" -eq 3 ] || fail "expected three rejected options"
  section_of "$adr" "Decision Outcome" | grep -qF 'la seule dérogation est une ADR de projet' \
    || fail "the outcome does not make the project ADR the only derogation"
}
