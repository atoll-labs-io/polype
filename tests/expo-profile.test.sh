#!/usr/bin/env bash
# s83 — the expo profile: lint, web render, grounding in the starter it was written from.

EXPO="$ROOT/boilerplates/expo/profile.md"
EXPO_URL=https://github.com/expo/expo

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }
identity_value() { grep -m1 "^- $2:" "$1" | sed "s/^- $2:[[:space:]]*//"; }

# One line per fact of the profile that the checkout at <src> contradicts.
grounding_breaches() {
  local profile="$1" src="$2" base token resolved=0 x commit head tokens
  base="$src/templates/expo-template-default"
  commit=$(identity_value "$profile" 'Commit profiled')
  head=$(git -C "$src" rev-parse HEAD)
  [ "$commit" = "$head" ] || echo "commit profiled $commit differs from the source HEAD $head"
  grep -q '"license": "0BSD"' "$base/package.json" || echo "the template licence is not 0BSD"
  section_of "$profile" Commands | grep -o 'npm run [a-z-]*' | sort -u | while read -r _ _ x; do
    grep -q "\"$x\":" "$base/package.json" || echo "npm script not in the source: $x"
  done
  tokens=$(grep -o '`[^`]*`' "$profile" | tr -d '`' \
    | grep -E '^(src|assets|scripts)/|^(app\.json|package\.json|tsconfig\.json)$' | grep -v '[<*]' || true)
  while IFS= read -r token; do
    [ -n "$token" ] || continue
    if [ -e "$base/${token%/}" ]; then resolved=$((resolved + 1)); else echo "path not in the source: $token"; fi
  done <<< "$tokens"
  [ "$resolved" -ge 6 ] || echo "only $resolved path(s) resolved, expected at least 6"
}

# Prints the checkout directory of the source, or nothing when it cannot be reached.
source_of() {
  local override="$1" profile="$2" dir="$3" commit
  if [ -n "$override" ]; then echo "$override"; return; fi
  commit=$(identity_value "$profile" 'Commit profiled')
  if { git clone -q --filter=blob:none --no-checkout --depth 1 "$(identity_value "$profile" Origin)" "$dir" \
      && git -C "$dir" sparse-checkout set --no-cone /LICENSE /templates/expo-template-default/ \
      && git -C "$dir" fetch -q --depth 1 origin "$commit" \
      && git -C "$dir" checkout -q "$commit"; } >/dev/null 2>&1; then echo "$dir"; fi
}

test_expo_profile_passes_the_lint() {
  local out status=0 copy
  require_file "$EXPO"
  out=$(bash "$ROOT/bin/po-lint" 2>&1) || status=$?
  [ "$status" -eq 0 ] || fail "po-lint reports breaches: $out"

  [ "$(identity_value "$EXPO" Origin)" = "$EXPO_URL" ] || fail "origin is not $EXPO_URL"
  [ "$(identity_value "$EXPO" Licence)" = 0BSD ] || fail "licence is not 0BSD"
  [[ "$(identity_value "$EXPO" 'Commit profiled')" =~ ^[0-9a-f]{40}$ ]] || fail "commit profiled is not a full hash"

  copy=$(mktemp -d); trap "rm -rf '$copy'" EXIT
  cp -r "$METHOD" "$copy/method"
  mkdir -p "$copy/boilerplates/expo"
  sed '/^## Known traps$/d' "$EXPO" > "$copy/boilerplates/expo/profile.md"
  status=0; out=$(bash "$ROOT/bin/po-lint" "$copy/method" 2>&1) || status=$?
  [ "$status" -ne 0 ] || fail "po-lint accepted a profile without '## Known traps'"
  grep -qF 'boilerplates/expo/profile.md' <<< "$out" || fail "po-lint did not name the expo profile: $out"
}

test_expo_profile_names_its_web_render() {
  local cmds
  require_file "$EXPO"
  grep -qxF -- '- Platform: mobile' "$EXPO" || fail "platform is not mobile"
  grep -qxF -- '- QA driver: mobile-web' "$EXPO" || fail "QA driver is not mobile-web"
  cmds=$(section_of "$EXPO" Commands)
  grep -qE '^Dev:[[:space:]]+npm run web$' <<< "$cmds" || fail "Dev is not 'npm run web'"
  grep -qE '^Test:[[:space:]]+npx jest$' <<< "$cmds" || fail "Test is not 'npx jest'"
  grep -qF 'web render' <<< "$cmds" || fail "Commands does not say Dev serves the web render"
  grep -qF 'Waiting on' <<< "$cmds" || fail "Commands does not say which line prints the address"
  grep -qF 'accepts paths to test files' <<< "$cmds" || fail "Commands does not say Test accepts paths"
}

test_expo_profile_is_grounded_in_its_source() {
  local tmp src breaches
  require_file "$EXPO"
  tmp=$(mktemp -d); trap "rm -rf '$tmp'" EXIT
  src=$(source_of "${EXPO_SRC:-}" "$EXPO" "$tmp/expo")
  if [ -z "$src" ]; then echo "      (expo/expo not reachable: grounding not checked)" >&2; return 0; fi

  breaches=$(grounding_breaches "$EXPO" "$src")
  [ -z "$breaches" ] || fail "expo not grounded: $breaches"
  sed 's|^- `src/hooks/`|- `src/app/settings.tsx` — made up.\n&|' "$EXPO" > "$tmp/mutant.md"
  grep -qF '`src/app/settings.tsx`' "$tmp/mutant.md" || fail "the mutant was not built"
  breaches=$(grounding_breaches "$tmp/mutant.md" "$src")
  grep -qF 'path not in the source: src/app/settings.tsx' <<< "$breaches" \
    || fail "the grounding check accepted a made-up path: $breaches"
}
