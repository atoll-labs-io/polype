#!/usr/bin/env bash
# s84 — the flutter profile: lint, web render, grounding in Flutter's app template.

PROFILE="$ROOT/boilerplates/flutter/profile.md"
FLUTTER_URL=https://github.com/flutter/flutter
TEMPLATES=packages/flutter_tools/templates

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }
identity_value() { grep -m1 "^- $2:" "$1" | sed "s/^- $2:[[:space:]]*//"; }

# Backticked tokens of a profile matching an extended regex; placeholders and globs are left out.
tokens_matching() {
  grep -o '`[^`]*`' "$1" | tr -d '`' | grep -E "$2" | grep -v '[<*]' || true
}

# A generated path resolves when a template file or directory stands behind it:
# itself, itself + .tmpl, or its first segment + .tmpl (android/ -> android.tmpl/).
resolves_in_templates() {
  local src="$1" token="${2%/}" root first rest
  first="${token%%/*}"; rest=""
  [ "$first" = "$token" ] || rest="/${token#*/}"
  for root in app app_test_widget; do
    for cand in "$token" "$token.tmpl" "$first.tmpl$rest" "$first$rest.tmpl"; do
      [ -e "$src/$TEMPLATES/$root/$cand" ] && return 0
    done
  done
  return 1
}

# One line per fact of the profile that the checkout at <src> contradicts.
grounding_breaches() {
  local profile="$1" src="$2" token resolved=0 commit head
  commit=$(identity_value "$profile" 'Commit profiled')
  head=$(git -C "$src" rev-parse HEAD)
  [ "$commit" = "$head" ] || echo "commit profiled $commit differs from the source HEAD $head"
  grep -q 'Redistribution and use in source and binary forms' "$src/LICENSE" \
    || echo "the source licence is not BSD"
  while IFS= read -r token; do
    [ -n "$token" ] || continue
    if resolves_in_templates "$src" "$token"; then resolved=$((resolved + 1)); else echo "path not in the source: $token"; fi
  done <<< "$(tokens_matching "$profile" '^(lib|test|web|android|ios|linux|macos|windows)/|^(pubspec\.yaml|analysis_options\.yaml)$')"
  [ "$resolved" -ge 6 ] || echo "only $resolved path(s) resolved, expected at least 6"
}

# Prints a sparse checkout of the templates at the profiled commit, or nothing when unreachable.
source_of() {
  local override="$1" profile="$2" dir="$3" commit
  if [ -n "$override" ]; then echo "$override"; return; fi
  commit=$(identity_value "$profile" 'Commit profiled')
  mkdir -p "$dir"
  if { git -C "$dir" init -q \
      && git -C "$dir" remote add origin "$(identity_value "$profile" Origin)" \
      && git -C "$dir" config core.sparseCheckout true \
      && printf '/LICENSE\n/%s/app/\n/%s/app_test_widget/\n' "$TEMPLATES" "$TEMPLATES" > "$dir/.git/info/sparse-checkout" \
      && git -C "$dir" fetch -q --depth 1 --filter=blob:none origin "$commit" \
      && git -C "$dir" checkout -q FETCH_HEAD; } >/dev/null 2>&1; then echo "$dir"; fi
}

test_flutter_profile_passes_the_lint() {
  local out status=0 copy
  require_file "$PROFILE"
  out=$(bash "$ROOT/bin/po-lint" 2>&1) || status=$?
  [ "$status" -eq 0 ] || fail "po-lint reports breaches: $out"

  [ "$(identity_value "$PROFILE" Origin)" = "$FLUTTER_URL" ] || fail "origin is not $FLUTTER_URL"
  [ "$(identity_value "$PROFILE" Licence)" = BSD-3-Clause ] || fail "licence is not BSD-3-Clause"
  [[ "$(identity_value "$PROFILE" 'Commit profiled')" =~ ^[0-9a-f]{40}$ ]] || fail "commit profiled is not a full hash"

  copy=$(mktemp -d); trap "rm -rf '$copy'" EXIT
  cp -r "$METHOD" "$copy/method"
  mkdir -p "$copy/boilerplates/flutter"
  sed '/^## Known traps$/d' "$PROFILE" > "$copy/boilerplates/flutter/profile.md"
  status=0; out=$(bash "$ROOT/bin/po-lint" "$copy/method" 2>&1) || status=$?
  [ "$status" -ne 0 ] || fail "po-lint accepted a profile without '## Known traps'"
  grep -qF 'boilerplates/flutter/profile.md' <<< "$out" || fail "po-lint did not name the flutter profile: $out"
}

test_flutter_profile_names_its_web_render() {
  local cmds
  require_file "$PROFILE"
  grep -qxF -- '- Platform: mobile' "$PROFILE" || fail "platform is not mobile"
  grep -qxF -- '- QA driver: mobile-web' "$PROFILE" || fail "QA driver is not mobile-web"
  cmds=$(section_of "$PROFILE" Commands)
  grep -Eq '^Dev:[[:space:]]+flutter run -d web-server' <<< "$cmds" || fail "Dev does not serve the web render"
  grep -Eq '^Test:[[:space:]]+flutter test' <<< "$cmds" || fail "Test is not flutter test"
  grep -qF 'is being served at' <<< "$cmds" || fail "the profile does not say which line Dev prints"
}

test_flutter_profile_is_grounded_in_its_source() {
  local tmp src breaches
  require_file "$PROFILE"
  tmp=$(mktemp -d); trap "rm -rf '$tmp'" EXIT
  src=$(source_of "${FLUTTER_SRC:-}" "$PROFILE" "$tmp/flutter")
  if [ -z "$src" ]; then
    echo "      (flutter/flutter not reachable: grounding not checked)" >&2
    return 0
  fi
  breaches=$(grounding_breaches "$PROFILE" "$src")
  [ -z "$breaches" ] || fail "flutter profile not grounded: $breaches"
  sed 's|^- `pubspec.yaml`|- `lib/src/router.dart` — made up.\n&|' "$PROFILE" > "$tmp/mutant.md"
  grep -qF '`lib/src/router.dart`' "$tmp/mutant.md" || fail "the mutant was not built"
  breaches=$(grounding_breaches "$tmp/mutant.md" "$src")
  grep -qF 'path not in the source: lib/src/router.dart' <<< "$breaches" \
    || fail "the grounding check accepted a made-up path: $breaches"
}
