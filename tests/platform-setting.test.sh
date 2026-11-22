#!/usr/bin/env bash
# s78 — the project declares its platforms, each profile its own, each story its surface.

SETTINGS="$METHOD/templates/agents-local.md"
PROFILE="$METHOD/templates/profile.md"
STORIES_T="$METHOD/templates/stories.md"

test_platform_is_a_setting() {
  template_settings | grep -qx 'Platform' || fail "Platform is not a template setting"
  local row values
  row=$(grep -m1 '^| Platform |' "$SETTINGS") || fail "no Platform row in the values table"
  # po-lint reads exactly these words from the row, so any other one would widen the list.
  values=$(grep -o '`[a-z][a-z]*`' <<< "$row" | tr -d '`' | tr '\n' ' ')
  [ "$values" = "web mobile cli api lib xr robot " ] || fail "Platform row values are '$values'"
}

test_profiles_declare_their_platform() {
  grep -qxF '## Platform' "$PROFILE" || fail "profile template lacks ## Platform"
  grep -qx -- '- Platform: .*' "$PROFILE" || fail "profile template lacks a '- Platform:' line"

  local m p out status line
  PLATFORM_TMP="$(mktemp -d)"; trap 'rm -rf "$PLATFORM_TMP"' EXIT
  lint() { status=0; out=$(bash "$ROOT/bin/po-lint" "$m/method" 2>&1) || status=$?; }
  fresh() {
    m="$(mktemp -d "$PLATFORM_TMP/XXXXXX")"
    cp -r "$METHOD" "$m/method"
    mkdir -p "$m/boilerplates/demo"
    p="$m/boilerplates/demo/profile.md"
    cp "$PROFILE" "$p"
  }

  fresh
  sed -i '/^## Platform$/d' "$p"
  lint
  [ "$status" -ne 0 ] || fail "lint accepts a profile without ## Platform"
  [ "$(grep -c ': \[' <<< "$out")" = 1 ] || fail "expected one breach, lint said: $out"
  grep -qF "boilerplates/demo/profile.md:1: [profile] missing section '## Platform'" <<< "$out" \
    || fail "lint does not name the missing section: $out"

  fresh
  sed -i 's/^- Platform: web$/- Platform: Web/' "$p"
  line=$(grep -n -m1 '^- Platform: Web$' "$p" | cut -d: -f1)
  [ -n "$line" ] || fail "mutation not applied: no '- Platform: Web' line"
  lint
  [ "$status" -ne 0 ] || fail "lint accepts the platform Web"
  [ "$(grep -c ': \[' <<< "$out")" = 1 ] || fail "expected one breach, lint said: $out"
  grep -qF "boilerplates/demo/profile.md:$line: [profile] platform 'Web' is not a value of the Platform setting" <<< "$out" \
    || fail "lint does not flag Web at line $line: $out"

  fresh
  sed -i 's/^- Platform: web$/- Platform: web, mobile/' "$p"
  grep -qx -- '- Platform: web, mobile' "$p" || fail "mutation not applied: no 'web, mobile' line"
  lint
  [ "$status" -eq 0 ] || fail "lint rejects '- Platform: web, mobile': $out"
}

test_stories_declare_a_surface() {
  contains "$STORIES_T" "**Surface**"
}

test_polype_declares_its_platform() {
  grep -qx 'Platform:          cli' "$ROOT/AGENTS.local.md" || fail "AGENTS.local.md does not declare Platform: cli"
  local out
  out="$(bash "$ROOT/bin/polype" check "$ROOT" 2>&1 || true)"
  grep -q 'installed in' <<< "$out" || fail "check did not run: $out"
  ! grep -q '^missing setting:' <<< "$out" || fail "$out"
}
