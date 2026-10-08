#!/usr/bin/env bash
# s40 — the boilerplate profile format: its template, the lint rule that holds every
# profile to it, and the catalogue documentation.

PROFILE="$METHOD/templates/profile.md"

# Setting names of the Commands fence of the profile template, one per line.
profile_command_names() {
  awk '
    /^## / {sec = ($0 == "## Commands"); next}
    sec && /^```/ {fence = !fence; next}
    sec && fence && NF {sub(/:.*/, ""); print}
  ' "$PROFILE"
}

test_profile_template_declares_every_section() {
  require_file "$PROFILE"
  local heading
  for heading in "## Identity and licence" "## Platform" "## Commands" "## Code map" "## Ownership granularity" \
      "## Where each rule lives" "## Capabilities" "## UI inventory" "## Known traps"; do
    grep -qxF -- "$heading" "$PROFILE" || fail "profile template lacks the section: $heading"
  done
  contains "$PROFILE" "Licence:"
  contains "$PROFILE" "| Capability | Brick | Notes |"
}

test_profile_commands_map_to_settings() {
  require_file "$PROFILE"
  local got
  got=$(profile_command_names | tr '\n' ' ')
  [ "$got" = "Install Test Typecheck E2E Build " ] \
    || fail "profile commands are '$got', expected exactly Install Test Typecheck E2E Build"
  local name
  for name in Install Test Typecheck E2E Build; do
    template_settings | grep -qxF "$name" || fail "$name is not a setting of agents-local.md"
  done
}

test_lint_checks_profiles() {
  local m p out status line
  PROFILE_TMP="$(mktemp -d)"; trap 'rm -rf "$PROFILE_TMP"' EXIT
  lint_profile() { status=0; out=$(bash "$ROOT/bin/po-lint" "$1" 2>&1) || status=$?; }
  fresh() {
    m="$(mktemp -d "$PROFILE_TMP/XXXXXX")"
    cp -r "$METHOD" "$m/method"
    mkdir -p "$m/boilerplates/demo"
    p="$m/boilerplates/demo/profile.md"
    cp "$PROFILE" "$p"
  }

  fresh
  lint_profile "$m/method"
  [ "$status" -eq 0 ] || fail "lint rejects a profile built from the template: $out"

  fresh
  sed -i '/^## Known traps$/d' "$p"
  ! grep -qxF '## Known traps' "$p" || fail "mutation not applied: section still there"
  lint_profile "$m/method"
  [ "$status" -ne 0 ] || fail "lint accepts a profile without Known traps"
  [ "$(grep -c ': \[' <<< "$out")" = 1 ] || fail "expected one breach, lint said: $out"
  grep -qF "boilerplates/demo/profile.md:1: [profile] missing section '## Known traps'" <<< "$out" \
    || fail "lint does not name the file and section: $out"

  fresh
  sed -i 's/^Test:/Tests:/' "$p"
  line=$(grep -n -m1 '^Tests:' "$p" | cut -d: -f1)
  [ -n "$line" ] || fail "mutation not applied: no Tests: line"
  lint_profile "$m/method"
  [ "$status" -ne 0 ] || fail "lint accepts a command named Tests"
  grep -qF "boilerplates/demo/profile.md:$line: [profile] command 'Tests' is not a setting" <<< "$out" \
    || fail "lint does not flag Tests: at line $line: $out"

  fresh
  sed -i 's/^| Deployment |.*/&\n| Blockchain | chain | |/' "$p"
  line=$(grep -n -m1 '^| Blockchain |' "$p" | cut -d: -f1)
  [ -n "$line" ] || fail "mutation not applied: no Blockchain row"
  lint_profile "$m/method"
  [ "$status" -ne 0 ] || fail "lint accepts a Blockchain capability"
  grep -qF "boilerplates/demo/profile.md:$line: [profile] capability 'Blockchain'" <<< "$out" \
    || fail "lint does not flag Blockchain at line $line: $out"
}

test_catalogue_doc_explains_the_three_levels() {
  local doc="$ROOT/docs/catalogue.md"
  require_file "$doc"
  contains "$doc" "boilerplates/<nom>/profile.md"
  contains "$doc" "method/templates/profile.md"
  contains "$doc" "bin/po-lint"
  contains "$doc" "maison"
  contains "$doc" "tiers profilé"
  contains "$doc" "aucun"
  contains "$doc" "parallélisme"
}
