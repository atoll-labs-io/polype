#!/usr/bin/env bash
# s85 — the native-ios and native-android profiles: lint, what QA cannot do, grounding in their starters.

IOS="$ROOT/boilerplates/native-ios/profile.md"
AND="$ROOT/boilerplates/native-android/profile.md"
IOS_URL=https://github.com/nimblehq/ios-templates
AND_URL=https://github.com/android/architecture-templates

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }
identity_value() { grep -m1 "^- $2:" "$1" | sed "s/^- $2:[[:space:]]*//"; }

# Backticked tokens of a profile matching an extended regex; placeholders and globs are left out.
tokens_matching() {
  grep -o '`[^`]*`' "$1" | tr -d '`' | grep -E "$2" | grep -v '[<*]' || true
}

# One line per fact of the profile that the checkout at <src> contradicts; kind is ios or android.
native_breaches() {
  local kind="$1" profile="$2" src="$3" token resolved=0 tokens commit at_head t
  commit=$(identity_value "$profile" 'Commit profiled')
  at_head=$(git -C "$src" rev-parse HEAD)
  [ "$commit" = "$at_head" ] || echo "commit profiled $commit differs from the source HEAD $at_head"
  if [ "$kind" = ios ]; then
    t="$src/template"
    head -1 "$src/LICENSE" | grep -q '^MIT License' || echo "the source licence is not MIT"
    tokens=$(tokens_matching "$profile" '^(Modules|\{PROJECT_NAME\}[A-Za-z]*|fastlane)/|^(Package\.swift|\.swiftlint\.yml|\.env\.example)$')
    while IFS= read -r token; do
      [ -n "$token" ] || continue
      if [ -e "$t/${token%/}" ] \
        || { [[ "$token" == '{PROJECT_NAME}/Sources/'* ]] \
             && [ -e "$t/Tuist/Interfaces/SwiftUI/Sources/${token#'{PROJECT_NAME}/Sources/'}" ]; }; then
        resolved=$((resolved + 1))
      else
        echo "path not in the source: $token"
      fi
    done <<< "$tokens"
  else
    grep -q 'Apache License' "$src/LICENSE" && grep -q 'Version 2.0' "$src/LICENSE" \
      || echo "the source licence is not Apache 2.0"
    tokens=$(tokens_matching "$profile" '^(app|gradle)/|^(settings\.gradle\.kts|build\.gradle\.kts|customizer\.sh|gradlew)$')
    while IFS= read -r token; do
      [ -n "$token" ] || continue
      if [ -e "$src/${token%/}" ]; then resolved=$((resolved + 1)); else echo "path not in the source: $token"; fi
    done <<< "$tokens"
  fi
  [ "$resolved" -ge 6 ] || echo "only $resolved path(s) resolved, expected at least 6"
}

# Prints the checkout directory of a source, or nothing when it cannot be reached.
source_of() {
  local override="$1" profile="$2" dir="$3" commit
  if [ -n "$override" ]; then echo "$override"; return; fi
  commit=$(identity_value "$profile" 'Commit profiled')
  if git clone -q --depth 1 --revision="$commit" "$(identity_value "$profile" Origin)" "$dir" >/dev/null 2>&1; then
    echo "$dir"
  elif { git clone -q --depth 1 "$(identity_value "$profile" Origin)" "$dir" \
      && git -C "$dir" fetch -q --depth 1 origin "$commit" \
      && git -C "$dir" checkout -q "$commit"; } >/dev/null 2>&1; then
    echo "$dir"
  fi
}

test_native_profiles_pass_the_lint() {
  local out status=0 copy p
  require_file "$IOS"; require_file "$AND"
  out=$(bash "$ROOT/bin/po-lint" 2>&1) || status=$?
  [ "$status" -eq 0 ] || fail "po-lint reports breaches: $out"

  [ "$(identity_value "$IOS" Origin)" = "$IOS_URL" ] || fail "native-ios origin is not $IOS_URL"
  [ "$(identity_value "$AND" Origin)" = "$AND_URL" ] || fail "native-android origin is not $AND_URL"
  [ "$(identity_value "$IOS" Licence)" = MIT ] || fail "native-ios licence is not MIT"
  [ "$(identity_value "$AND" Licence)" = Apache-2.0 ] || fail "native-android licence is not Apache-2.0"
  for p in "$IOS" "$AND"; do
    [[ "$(identity_value "$p" 'Commit profiled')" =~ ^[0-9a-f]{40}$ ]] || fail "commit profiled is not a full hash in $p"
  done

  copy=$(mktemp -d); trap "rm -rf '$copy'" EXIT
  cp -r "$METHOD" "$copy/method"
  mkdir -p "$copy/boilerplates/native-ios" "$copy/boilerplates/native-android"
  sed '/^## Known traps$/d' "$IOS" > "$copy/boilerplates/native-ios/profile.md"
  sed '/^## Known traps$/d' "$AND" > "$copy/boilerplates/native-android/profile.md"
  status=0; out=$(bash "$ROOT/bin/po-lint" "$copy/method" 2>&1) || status=$?
  [ "$status" -ne 0 ] || fail "po-lint accepted profiles without '## Known traps'"
  grep -qF 'boilerplates/native-ios/profile.md' <<< "$out" || fail "po-lint did not name native-ios: $out"
  grep -qF 'boilerplates/native-android/profile.md' <<< "$out" || fail "po-lint did not name native-android: $out"
}

test_native_profiles_say_what_qa_cannot_do() {
  local p qa dev
  require_file "$IOS"; require_file "$AND"
  for p in "$IOS" "$AND"; do
    grep -qxF -- '- Platform: mobile' "$p" || fail "platform is not mobile in $p"
    grep -qxF -- '- QA driver: —' "$p" || fail "QA driver is not — in $p"
    dev=$(section_of "$p" Commands | grep -m1 '^Dev:' | sed 's/^Dev:[[:space:]]*//')
    [ "$dev" = '—' ] || fail "Dev is not — in $p"
    qa=$(section_of "$p" 'QA driver')
    grep -qF 'mobile-web' <<< "$qa" || fail "no mention of mobile-web in $p"
    grep -qF 'does not apply' <<< "$qa" || fail "does not say the web driver does not apply in $p"
    grep -qF '`blocked`' <<< "$qa" || fail "does not say the screen QA is blocked in $p"
  done
  section_of "$IOS" 'QA driver' | grep -qF 'needs a Mac' || fail "native-ios does not say the simulator needs a Mac"
  section_of "$AND" 'QA driver' | grep -qF 'later batch' || fail "native-android does not say the emulator driver is for a later batch"
}

test_native_profiles_are_grounded_in_their_sources() {
  local tmp isrc asrc breaches
  require_file "$IOS"; require_file "$AND"
  tmp=$(mktemp -d); trap "rm -rf '$tmp'" EXIT
  isrc=$(source_of "${NATIVE_IOS_SRC:-}" "$IOS" "$tmp/ios")
  asrc=$(source_of "${NATIVE_ANDROID_SRC:-}" "$AND" "$tmp/android")
  [ -n "$isrc" ] || echo "      (ios-templates not reachable: grounding not checked)" >&2
  [ -n "$asrc" ] || echo "      (architecture-templates not reachable: grounding not checked)" >&2

  if [ -n "$isrc" ]; then
    breaches=$(native_breaches ios "$IOS" "$isrc")
    [ -z "$breaches" ] || fail "native-ios not grounded: $breaches"
    sed 's|^- `fastlane/`|- `Modules/Payments/` — made up.\n&|' "$IOS" > "$tmp/mutant-ios.md"
    grep -qF '`Modules/Payments/`' "$tmp/mutant-ios.md" || fail "the iOS mutant was not built"
    breaches=$(native_breaches ios "$tmp/mutant-ios.md" "$isrc")
    grep -qF 'path not in the source: Modules/Payments/' <<< "$breaches" \
      || fail "the grounding check accepted a made-up iOS path: $breaches"
  fi
  if [ -n "$asrc" ]; then
    breaches=$(native_breaches android "$AND" "$asrc")
    [ -z "$breaches" ] || fail "native-android not grounded: $breaches"
    sed 's|^- `gradle/libs.versions.toml`|- `app/src/main/java/android/template/billing/` — made up.\n&|' "$AND" > "$tmp/mutant-and.md"
    grep -qF '`app/src/main/java/android/template/billing/`' "$tmp/mutant-and.md" || fail "the Android mutant was not built"
    breaches=$(native_breaches android "$tmp/mutant-and.md" "$asrc")
    grep -qF 'path not in the source: app/src/main/java/android/template/billing/' <<< "$breaches" \
      || fail "the grounding check accepted a made-up Android path: $breaches"
  fi
}
