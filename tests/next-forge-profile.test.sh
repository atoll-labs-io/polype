#!/usr/bin/env bash
# s42 — the next-forge profile: lint, grounding in the real repository, gaps, ownership.

PROFILE="$ROOT/boilerplates/next-forge/profile.md"

# The body of one `## <heading>` section of a file, heading excluded.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

identity_value() { grep -m1 "^- $2:" "$1" | sed "s/^- $2:[[:space:]]*//"; }

# Backticked tokens that name a path of the boilerplate; placeholders and globs are left out.
repo_paths() {
  grep -o '`[^`]*`' "$1" | tr -d '`' \
    | grep -E '^(apps|packages|docs)/|^(package\.json|turbo\.json|bun\.lock)$' \
    | grep -v '[<*]' || true
}

root_scripts() {
  if command -v jq >/dev/null; then
    jq -r '.scripts | keys[]' "$1/package.json"
  else
    node -e 'for (const k of Object.keys(require(process.argv[1]).scripts)) console.log(k)' "$1/package.json"
  fi
}

# One line per fact of the profile that the source checkout at <src> contradicts.
profile_grounding_breaches() {
  local profile="$1" src="$2" head commit token resolved=0 value script scripts cell cells ok
  head=$(git -C "$src" rev-parse HEAD)
  commit=$(identity_value "$profile" 'Commit profiled')
  [[ "$commit" =~ ^[0-9a-f]{40}$ ]] || echo "commit profiled is not a full hash: '$commit'"
  [ "$commit" = "$head" ] || echo "commit profiled $commit differs from the source HEAD $head"
  [ "$(identity_value "$profile" Origin)" = "https://github.com/vercel/next-forge" ] \
    || echo "origin is not https://github.com/vercel/next-forge"
  [ "$(identity_value "$profile" Licence)" = MIT ] || echo "licence is not MIT"
  head -1 "$src/license.md" | grep -q '^MIT License' || echo "the source licence is not MIT"

  while IFS= read -r token; do
    [ -n "$token" ] || continue
    if [ -e "$src/${token%/}" ]; then resolved=$((resolved + 1)); else echo "path not in the source: $token"; fi
  done < <(repo_paths "$profile")
  [ "$resolved" -ge 15 ] || echo "only $resolved path(s) resolved, expected at least 15"

  scripts=$(root_scripts "$src")
  while IFS= read -r value; do
    [ -n "$value" ] && [ "$value" != "—" ] || continue
    [ "$value" = "bun install" ] && continue
    script=${value#bun run }
    if [ "$script" = "$value" ] || ! grep -qxF -- "$script" <<< "$scripts"; then
      echo "command not in the source's root scripts: $value"
    fi
  done < <(section_of "$profile" Commands | awk '/^```/ {f=!f; next} f {sub(/^[^:]*:[[:space:]]*/, ""); sub(/[[:space:]]+$/, ""); print}')

  cells=$(section_of "$profile" Capabilities | awk -F'|' '/^\|/ {c=$2; gsub(/^[ \t]+|[ \t]+$/, "", c); if (c == "Capability" || c ~ /^-+$/) next; print c "\t" $4}')
  while IFS=$'\t' read -r name cell; do
    [ -n "$name" ] || continue
    ok=0
    while IFS= read -r token; do
      [ -n "$token" ] && [ -e "$src/${token%/}" ] && ok=1
    done < <(printf '%s\n' "$cell" | repo_paths /dev/stdin)
    [ "$ok" = 1 ] || echo "capability $name cites no path of the source"
  done <<< "$cells"
}

test_next_forge_profile_passes_the_lint() {
  local out status=0 copy
  require_file "$PROFILE"
  out=$(bash "$ROOT/bin/po-lint" 2>&1) || status=$?
  [ "$status" -eq 0 ] || fail "po-lint reports breaches: $out"

  copy=$(mktemp -d); trap "rm -rf '$copy'" EXIT
  cp -r "$METHOD" "$copy/method"
  mkdir -p "$copy/boilerplates/next-forge"
  sed '/^## UI inventory$/d' "$PROFILE" > "$copy/boilerplates/next-forge/profile.md"
  status=0; out=$(bash "$ROOT/bin/po-lint" "$copy/method" 2>&1) || status=$?
  [ "$status" -ne 0 ] || fail "po-lint accepted the profile without '## UI inventory'"
  grep -qF 'boilerplates/next-forge/profile.md' <<< "$out" || fail "po-lint did not name the profile: $out"
}

test_next_forge_profile_is_grounded_in_the_real_repository() {
  local src tmp commit breaches
  require_file "$PROFILE"
  tmp=$(mktemp -d); trap "rm -rf '$tmp'" EXIT
  if [ -n "${NEXT_FORGE_SRC:-}" ]; then
    src="$NEXT_FORGE_SRC"
  else
    src="$tmp/next-forge"
    commit=$(identity_value "$PROFILE" 'Commit profiled')
    if ! { git clone -q --depth 1 "$(identity_value "$PROFILE" Origin)" "$src" \
        && git -C "$src" fetch -q --depth 1 origin "$commit" \
        && git -C "$src" checkout -q "$commit"; } 2>/dev/null; then
      echo "      (next-forge not reachable: grounding not checked)" >&2
      return 0
    fi
  fi

  breaches=$(profile_grounding_breaches "$PROFILE" "$src")
  [ -z "$breaches" ] || fail "profile not grounded in next-forge: $breaches"

  sed 's|^- `packages/auth/`|- `packages/blockchain/` — made up.\n&|' "$PROFILE" > "$tmp/mutant.md"
  grep -qF '`packages/blockchain/`' "$tmp/mutant.md" || fail "the mutant was not built"
  breaches=$(profile_grounding_breaches "$tmp/mutant.md" "$src")
  grep -qF 'path not in the source: packages/blockchain/' <<< "$breaches" \
    || fail "the grounding check accepted a made-up path: $breaches"
}

test_next_forge_profile_states_its_gaps_against_adr_0020() {
  local caps
  require_file "$PROFILE"
  caps=$(section_of "$PROFILE" Capabilities)
  grep -qxF 'Gaps against the default bricks (ADR-0020):' <<< "$caps" || fail "no gap list in ## Capabilities"
  for bullet in Database Auth Files Jobs Email Observability Deployment; do
    grep -q "^- $bullet " <<< "$caps" || fail "no gap bullet for $bullet"
  done
  for word in 'Better Auth' Garage PostgreSQL pg-boss OpenTelemetry Dockerfile; do
    grep -qF -- "$word" <<< "$caps" || fail "the gaps do not name $word"
  done
  grep -qE '^- Auth .*rewrite `packages/auth/`' <<< "$caps" || fail "the Auth gap does not rewrite packages/auth/"
  grep -qE '^- Files .*rewrite `packages/storage/`' <<< "$caps" || fail "the Files gap does not rewrite packages/storage/"
  grep -qE '^- Database .*`packages/database/' <<< "$caps" || fail "the Database gap does not name packages/database/"
}

test_next_forge_profile_declares_ownership_granularity() {
  local own
  require_file "$PROFILE"
  own=$(section_of "$PROFILE" 'Ownership granularity')
  for phrase in 'one package per capability' 'packages/<name>/' 'packages/design-system/' turbo.json bun.lock schema.prisma; do
    grep -qF -- "$phrase" <<< "$own" || fail "## Ownership granularity does not say: $phrase"
  done
}
