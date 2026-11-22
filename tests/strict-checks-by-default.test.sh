#!/usr/bin/env bash
# s147 — the strict check: declared by each profile, retained by /po-architect through
# a project ADR, reaching the project through Typecheck only (ADR-0097).

PROFILE="$METHOD/templates/profile.md"
ARCHITECT="$METHOD/commands/po-architect.md"
ARCH_TEMPLATE="$METHOD/templates/architecture.md"
STRICT_FIELDS=("Strict check" "Turned on by" "Passes at the commit profiled")

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

test_profile_declares_strictness() {
  require_file "$PROFILE"
  grep -qxF '## Strictness' "$PROFILE" || fail "profile template lacks '## Strictness'"
  local field m p out status heading_line
  for field in "${STRICT_FIELDS[@]}"; do
    section_of "$PROFILE" Strictness | grep -q "^- $field:" || fail "template Strictness lacks '- $field:'"
  done

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
  local out status=0
  out=$(bash "$ROOT/bin/po-lint" 2>&1) || status=$?
  [ "$status" -eq 0 ] || fail "po-lint reports breaches on the real tree: $out"
}

test_strict_command_reaches_typecheck() {
  require_file "$ARCHITECT"; require_file "$ARCH_TEMPLATE"
  ! template_settings | grep -qE 'Strict|Lint' || fail "a setting of its own was added for the strict check"
  ! settings_read_by "$ARCHITECT" | grep -qE 'Strict|Lint' || fail "/po-architect reads a strict or lint setting"
}
