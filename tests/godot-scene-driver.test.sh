#!/usr/bin/env bash
# s87 — the godot profile and the scene driver.

PROFILE="$ROOT/boilerplates/godot/profile.md"
TEMPLATE_URL=https://github.com/GodotVR/godot-xr-template

identity_value() { grep -m1 "^- $2:" "$1" | sed "s/^- $2:[[:space:]]*//"; }

# Backticked tokens of a profile matching an extended regex; placeholders and globs are left out.
tokens_matching() {
  grep -o '`[^`]*`' "$1" | tr -d '`' | grep -E "$2" | grep -v '[<*]' || true
}

# One line per fact of the profile that revision <rev> of the repository at <src> contradicts.
grounding_breaches() {
  local profile="$1" src="$2" rev="$3" token resolved=0 commit head
  commit=$(identity_value "$profile" 'Commit profiled')
  head=$(git -C "$src" rev-parse "$rev")
  [ "$commit" = "$head" ] || echo "commit profiled $commit differs from the source $head"
  git -C "$src" show "$rev:LICENSE" 2>/dev/null | head -1 | grep -q '^MIT License' \
    || echo "the source licence is not MIT"
  while IFS= read -r token; do
    [ -n "$token" ] || continue
    if git -C "$src" cat-file -e "$rev:${token%/}" 2>/dev/null; then
      resolved=$((resolved + 1))
    else
      echo "path not in the source: $token"
    fi
  done <<< "$(tokens_matching "$profile" '^(game|components|assets|addons|build|img)/|^(project\.godot|export_presets\.cfg|openxr_action_map\.tres|default_env\.tres)$')"
  [ "$resolved" -ge 6 ] || echo "only $resolved path(s) resolved, expected at least 6"
}

test_godot_profile_passes_the_lint() {
  local out status=0 copy cmds
  require_file "$PROFILE"
  out=$(bash "$ROOT/bin/po-lint" 2>&1) || status=$?
  [ "$status" -eq 0 ] || fail "po-lint reports breaches: $out"

  [ "$(identity_value "$PROFILE" Origin)" = "$TEMPLATE_URL" ] || fail "origin is not $TEMPLATE_URL"
  [[ "$(identity_value "$PROFILE" 'Commit profiled')" =~ ^[0-9a-f]{40}$ ]] || fail "commit profiled is not a full hash"
  grep -qxF -- '- QA driver: scene' "$PROFILE" || fail "QA driver is not scene"

  copy=$(mktemp -d); trap "rm -rf '$copy'" EXIT
  cp -r "$METHOD" "$copy/method"
  mkdir -p "$copy/boilerplates/godot"
  sed '/^## Known traps$/d' "$PROFILE" > "$copy/boilerplates/godot/profile.md"
  status=0; out=$(bash "$ROOT/bin/po-lint" "$copy/method" 2>&1) || status=$?
  [ "$status" -ne 0 ] || fail "po-lint accepted a profile without '## Known traps'"
  grep -qF 'boilerplates/godot/profile.md' <<< "$out" || fail "po-lint did not name the godot profile: $out"

  cp "$PROFILE" "$copy/boilerplates/godot/profile.md"
  rm "$copy/method/skills/qa-drivers/scene.md"
  status=0; out=$(bash "$ROOT/bin/po-lint" "$copy/method" 2>&1) || status=$?
  [ "$status" -ne 0 ] || fail "po-lint accepted the scene driver without its file"
  grep -qF "QA driver 'scene' is not a file of qa-drivers" <<< "$out" \
    || fail "po-lint did not tie the profile to scene.md: $out"
}

test_godot_profile_is_grounded_in_its_source() {
  local tmp src rev=HEAD breaches commit
  require_file "$PROFILE"
  tmp=$(mktemp -d); trap "rm -rf '$tmp'" EXIT
  src="${GODOT_TEMPLATE_SRC:-}"
  if [ -z "$src" ]; then
    commit=$(identity_value "$PROFILE" 'Commit profiled')
    src="$tmp/template"; rev=FETCH_HEAD
    if ! { git init -q "$src" \
        && git -C "$src" fetch -q --depth 1 --filter=blob:none "$(identity_value "$PROFILE" Origin)" "$commit"; } >/dev/null 2>&1; then
      echo "      (godot-xr-template not reachable: grounding not checked)" >&2
      return 0
    fi
  fi
  breaches=$(grounding_breaches "$PROFILE" "$src" "$rev")
  [ -z "$breaches" ] || fail "godot profile not grounded: $breaches"
  sed 's|^- `default_env.tres`|- `game/levels/boss.tscn` — made up.\n&|' "$PROFILE" > "$tmp/mutant.md"
  grep -qF '`game/levels/boss.tscn`' "$tmp/mutant.md" || fail "the mutant was not built"
  breaches=$(grounding_breaches "$tmp/mutant.md" "$src" "$rev")
  grep -qF 'path not in the source: game/levels/boss.tscn' <<< "$breaches" \
    || fail "the grounding check accepted a made-up path: $breaches"
}
