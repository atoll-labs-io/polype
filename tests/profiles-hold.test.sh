#!/usr/bin/env bash
# s95-profiles-hold: profile Test commands fail on red, skipped grounding shows, po-lint profile rules hold.

IOS="$ROOT/boilerplates/native-ios/profile.md"
EXPO="$ROOT/boilerplates/expo/profile.md"
ANDROID="$ROOT/boilerplates/native-android/profile.md"
RUST="$ROOT/boilerplates/rust-cli/profile.md"
TEMPLATE_PROFILE="$METHOD/templates/profile.md"

# Value of the `Test:` line of a profile's Commands fence, padding removed.
profile_test_value() { grep -m1 '^Test:' "$1" | sed 's/^Test:[[:space:]]*//'; }

adr_file() { ls "$ROOT"/docs/decisions/ADR-"$1"-*.md 2>/dev/null | head -n1; }

test_test_commands_fail_on_red() {
  local expected got adr n
  read -r expected <<'EOF'
rm -rf fastlane/test_output && bundle exec fastlane buildAndTest && xcrun xcresulttool get test-results summary --path fastlane/test_output/*.xcresult | grep -Eq '"result" *: *"Passed"'
EOF
  got=$(profile_test_value "$IOS")
  [ "$got" = "$expected" ] || fail "iOS Test is '$got'"
  got=$(profile_test_value "$EXPO")
  [ "$got" = "npx --no-install jest" ] || fail "Expo Test is '$got'"
  contains "$IOS" 'never shorten it to the lane'

  adr=$(adr_file 0069)
  [ -n "$adr" ] || fail "ADR-0069 is missing"
  frontmatter "$adr" | grep -qxF 'supersedes: [ADR-0062, ADR-0064]' || fail "ADR-0069 does not supersede ADR-0062 and ADR-0064"
  frontmatter "$adr" | grep -qxF 'status: accepted' || fail "ADR-0069 is not accepted"
  for n in 0062 0064; do
    adr=$(adr_file "$n")
    [ -n "$adr" ] || fail "ADR-$n is missing"
    frontmatter "$adr" | grep -qxF 'superseded-by: [ADR-0069]' || fail "ADR-$n is not superseded by ADR-0069"
    frontmatter "$adr" | grep -qxF 'status: accepted' || fail "ADR-$n is no longer accepted"
  done
}

test_skipped_grounding_is_visible() {
  local out status tmp
  RUN_TMP="$(mktemp -d)"; trap 'rm -rf "$RUN_TMP"' EXIT; tmp="$RUN_TMP"
  cp "$ROOT/tests/run.sh" "$ROOT/tests/lib.sh" "$tmp/"
  cat > "$tmp/fake.test.sh" <<'EOF'
test_reached() { :; }
test_offline() { echo "      (src not reachable: grounding not checked)" >&2; }
EOF
  status=0; out=$(bash "$tmp/run.sh" fake.test.sh 2>&1) || status=$?
  [ "$status" -eq 0 ] || fail "a skipped test turns the suite red: $out"
  grep -qxF '  ok    reached' <<< "$out" || fail "no ok line for reached: $out"
  grep -qxF '  skip  offline' <<< "$out" || fail "no skip line for offline: $out"
  grep -qxF '      (src not reachable: grounding not checked)' <<< "$out" || fail "the skip reason is not printed: $out"
  grep -qxF '1 passed, 0 failed, 1 skipped' <<< "$out" || fail "wrong summary: $out"

  cat > "$tmp/red.test.sh" <<'EOF'
test_red() { echo "      (src not reachable: grounding not checked)" >&2; return 1; }
EOF
  status=0; out=$(bash "$tmp/run.sh" red.test.sh 2>&1) || status=$?
  [ "$status" -ne 0 ] || fail "a failing test with the skip marker exits 0: $out"
  grep -qxF '  FAIL  red' <<< "$out" || fail "a failing test with the skip marker is not FAIL: $out"
}

test_lint_holds_its_profile_rules() {
  local m p out status line
  LINT_TMP="$(mktemp -d)"; trap 'rm -rf "$LINT_TMP"' EXIT
  lint() { status=0; out=$(bash "$ROOT/bin/po-lint" "$m/method" 2>&1) || status=$?; }
  fresh() {
    m="$(mktemp -d "$LINT_TMP/XXXXXX")"
    cp -r "$METHOD" "$m/method"
    mkdir -p "$m/boilerplates/demo"
    p="$m/boilerplates/demo/profile.md"
    cp "$TEMPLATE_PROFILE" "$p"
  }
  line_of() { grep -n -m1 -xF -- "$1" "$p" | cut -d: -f1; }

  # a. the template as is
  fresh; lint
  [ "$status" -eq 0 ] || fail "a: lint rejects the template: $out"

  # b. mobile-web with Dev: —
  fresh
  sed -i 's/^- QA driver: browser$/- QA driver: mobile-web/' "$p"
  line=$(line_of '- QA driver: mobile-web')
  [ -n "$line" ] || fail "b: mutation not applied"
  grep -qE '^Dev:[[:space:]]+—$' "$p" || fail "b: Dev is not '—' in the template"
  lint
  [ "$status" -ne 0 ] || fail "b: lint accepts mobile-web with Dev '—'"
  [ "$(grep -c ': \[' <<< "$out")" = 1 ] || fail "b: expected one breach, lint said: $out"
  grep -qF "boilerplates/demo/profile.md:$line: [profile] QA driver 'mobile-web' needs a Dev command" <<< "$out" \
    || fail "b: wrong breach: $out"

  # c. mobile-web with a Dev command
  fresh
  sed -i 's/^- QA driver: browser$/- QA driver: mobile-web/; s/^Dev:[[:space:]].*$/Dev:               npm run web/' "$p"
  grep -qxF -- '- QA driver: mobile-web' "$p" && grep -qxF 'Dev:               npm run web' "$p" \
    || fail "c: mutation not applied"
  lint
  [ "$status" -eq 0 ] || fail "c: lint rejects mobile-web with a Dev command: $out"

  # d. driver —
  fresh
  sed -i 's/^- QA driver: browser$/- QA driver: —/' "$p"
  grep -qxF -- '- QA driver: —' "$p" || fail "d: mutation not applied"
  lint
  [ "$status" -eq 0 ] || fail "d: lint rejects driver '—': $out"

  # e. partial platform value
  fresh
  sed -i 's/^- Platform: web$/- Platform: we/' "$p"
  line=$(line_of '- Platform: we')
  [ -n "$line" ] || fail "e: mutation not applied"
  lint
  [ "$status" -ne 0 ] || fail "e: lint accepts platform 'we'"
  grep -qF "boilerplates/demo/profile.md:$line: [profile] platform 'we' is not a value of the Platform setting" <<< "$out" \
    || fail "e: wrong breach: $out"

  # f. ## Platform without its line
  fresh
  sed -i '/^- Platform: web$/d' "$p"
  ! grep -q '^- Platform:' "$p" || fail "f: mutation not applied"
  line=$(line_of '## Platform')
  lint
  [ "$status" -ne 0 ] || fail "f: lint accepts a Platform section without its line"
  grep -qF "boilerplates/demo/profile.md:$line: [profile] no '- Platform:' line under '## Platform'" <<< "$out" \
    || fail "f: wrong breach: $out"

  # g. broken | Platform | row of the settings template
  fresh
  sed -i 's/^| Platform |/| Platforms |/' "$m/method/templates/agents-local.md"
  ! grep -q '^| Platform |' "$m/method/templates/agents-local.md" || fail "g: mutation not applied"
  lint
  [ "$status" -ne 0 ] || fail "g: lint accepts a settings table without its Platform row"
  grep -qF "templates/agents-local.md:1: [profile] no Platform values in the settings table" <<< "$out" \
    || fail "g: wrong breach: $out"

  # h. ## QA driver without its line
  fresh
  sed -i '/^- QA driver: browser$/d' "$p"
  ! grep -q '^- QA driver:' "$p" || fail "h: mutation not applied"
  lint
  [ "$status" -ne 0 ] || fail "h: lint accepts a QA driver section without its line"
  grep -qF "no '- QA driver:' line under '## QA driver'" <<< "$out" || fail "h: wrong breach: $out"
}

test_profile_slips_are_fixed() {
  contains "$IOS" 'xcbeautify is `latest`'
  ! grep -qF 'xcbeautify match the versions' "$IOS" || fail "iOS still says xcbeautify is pinned"
  contains "$ANDROID" '`CONTRIBUTING.md`'
  contains "$ANDROID" '`.google/`'
  contains "$ANDROID" 'and itself'
  contains "$ANDROID" 'outside that directory'
  ! grep -qF 'with its data and its tests' "$ANDROID" || fail "Android still gives the data to the feature directory"
  contains "$RUST" '`slog-journald`'
  ! grep -qF 'Every dependency of `utils`' "$RUST" || fail "Rust still puts every utils dependency under Linux"
}
