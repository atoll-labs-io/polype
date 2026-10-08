#!/usr/bin/env bash
# s86 — the rust-cli and hono-api profiles: lint, scenarios, grounding in their starters.

RUST="$ROOT/boilerplates/rust-cli/profile.md"
HONO="$ROOT/boilerplates/hono-api/profile.md"
RUST_URL=https://github.com/rust-starter/rust-starter
HONO_URL=https://github.com/honojs/starter

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }
identity_value() { grep -m1 "^- $2:" "$1" | sed "s/^- $2:[[:space:]]*//"; }

# Backticked tokens of a profile matching an extended regex; placeholders and globs are left out.
tokens_matching() {
  grep -o '`[^`]*`' "$1" | tr -d '`' | grep -E "$2" | grep -v '[<*]' || true
}

# One line per fact of the profile that the checkout at <src> contradicts; kind is rust or hono.
grounding_breaches() {
  local kind="$1" profile="$2" src="$3" base token resolved=0 min x
  local commit at_head tokens
  commit=$(identity_value "$profile" 'Commit profiled')
  at_head=$(git -C "$src" rev-parse HEAD)
  [ "$commit" = "$at_head" ] || echo "commit profiled $commit differs from the source HEAD $at_head"
  if [ "$kind" = rust ]; then
    base="$src"; min=8
    head -1 "$src/LICENSE" | grep -q '^MIT License' || echo "the source licence is not MIT"
    tokens=$(tokens_matching "$profile" '^(src|cli|core|utils|tests|docker|\.github)/|^(Cargo\.toml|justfile|LICENSE)$')
  else
    base="$src/templates/nodejs"; min=4
    grep -q '"license": "MIT"' "$src/package.json" || echo "the source licence is not MIT"
    tokens=$(tokens_matching "$profile" '^src/|^(package\.json|tsconfig\.json|pnpm-workspace\.yaml)$')
    section_of "$profile" Commands | grep -o 'npm run [a-z]*' | sort -u | while read -r _ _ x; do
      grep -q "\"$x\":" "$base/package.json" || echo "npm script not in the source: $x"
    done
  fi
  while IFS= read -r token; do
    [ -n "$token" ] || continue
    if [ -e "$base/${token%/}" ]; then resolved=$((resolved + 1)); else echo "path not in the source: $token"; fi
  done <<< "$tokens"
  [ "$resolved" -ge "$min" ] || echo "only $resolved path(s) resolved, expected at least $min"
}

# Prints the checkout directory of a source, or nothing when it cannot be reached.
source_of() {
  local override="$1" profile="$2" dir="$3" commit
  if [ -n "$override" ]; then echo "$override"; return; fi
  commit=$(identity_value "$profile" 'Commit profiled')
  if { git clone -q --depth 1 "$(identity_value "$profile" Origin)" "$dir" \
      && git -C "$dir" fetch -q --depth 1 origin "$commit" \
      && git -C "$dir" checkout -q "$commit"; } >/dev/null 2>&1; then echo "$dir"; fi
}

test_cli_api_profiles_pass_the_lint() {
  local out status=0 copy p
  require_file "$RUST"; require_file "$HONO"
  out=$(bash "$ROOT/bin/po-lint" 2>&1) || status=$?
  [ "$status" -eq 0 ] || fail "po-lint reports breaches: $out"

  [ "$(identity_value "$RUST" Origin)" = "$RUST_URL" ] || fail "rust-cli origin is not $RUST_URL"
  [ "$(identity_value "$HONO" Origin)" = "$HONO_URL" ] || fail "hono-api origin is not $HONO_URL"
  for p in "$RUST" "$HONO"; do
    [ "$(identity_value "$p" Licence)" = MIT ] || fail "licence is not MIT in $p"
    [[ "$(identity_value "$p" 'Commit profiled')" =~ ^[0-9a-f]{40}$ ]] || fail "commit profiled is not a full hash in $p"
  done

  copy=$(mktemp -d); trap "rm -rf '$copy'" EXIT
  cp -r "$METHOD" "$copy/method"
  mkdir -p "$copy/boilerplates/rust-cli" "$copy/boilerplates/hono-api"
  sed '/^## Known traps$/d' "$RUST" > "$copy/boilerplates/rust-cli/profile.md"
  sed '/^## Known traps$/d' "$HONO" > "$copy/boilerplates/hono-api/profile.md"
  status=0; out=$(bash "$ROOT/bin/po-lint" "$copy/method" 2>&1) || status=$?
  [ "$status" -ne 0 ] || fail "po-lint accepted profiles without '## Known traps'"
  grep -qF 'boilerplates/rust-cli/profile.md' <<< "$out" || fail "po-lint did not name rust-cli: $out"
  grep -qF 'boilerplates/hono-api/profile.md' <<< "$out" || fail "po-lint did not name hono-api: $out"
}

test_cli_api_profiles_use_scenarios() {
  local p cmds
  require_file "$RUST"; require_file "$HONO"
  grep -qxF -- '- Platform: cli' "$RUST" || fail "rust-cli is not platform cli"
  grep -qxF -- '- Platform: api' "$HONO" || fail "hono-api is not platform api"
  for p in "$RUST" "$HONO"; do
    grep -qxF -- '- QA driver: scenarios' "$p" || fail "QA driver is not scenarios in $p"
    section_of "$p" Commands | grep -qF 'To run a scenario,' || fail "no launch paragraph in $p"
  done
  cmds=$(section_of "$RUST" Commands)
  grep -qF 'target/release/rust-starter' <<< "$cmds" || fail "rust-cli does not name its binary"
  cmds=$(section_of "$HONO" Commands)
  grep -qF 'node dist/index.js' <<< "$cmds" || fail "hono-api does not name its start command"
  grep -qF 'PORT' <<< "$cmds" || fail "hono-api does not say how the port is passed"
}

test_cli_api_profiles_are_grounded_in_their_sources() {
  local tmp rsrc hsrc breaches
  require_file "$RUST"; require_file "$HONO"
  tmp=$(mktemp -d); trap "rm -rf '$tmp'" EXIT
  rsrc=$(source_of "${RUST_CLI_SRC:-}" "$RUST" "$tmp/rust")
  hsrc=$(source_of "${HONO_API_SRC:-}" "$HONO" "$tmp/hono")
  [ -n "$rsrc" ] || echo "      (rust-starter not reachable: grounding not checked)" >&2
  [ -n "$hsrc" ] || echo "      (honojs/starter not reachable: grounding not checked)" >&2

  if [ -n "$rsrc" ]; then
    breaches=$(grounding_breaches rust "$RUST" "$rsrc")
    [ -z "$breaches" ] || fail "rust-cli not grounded: $breaches"
    sed 's|^- `utils/`|- `core/src/blockchain.rs` — made up.\n&|' "$RUST" > "$tmp/mutant.md"
    grep -qF '`core/src/blockchain.rs`' "$tmp/mutant.md" || fail "the mutant was not built"
    breaches=$(grounding_breaches rust "$tmp/mutant.md" "$rsrc")
    grep -qF 'path not in the source: core/src/blockchain.rs' <<< "$breaches" \
      || fail "the grounding check accepted a made-up path: $breaches"
  fi
  if [ -n "$hsrc" ]; then
    breaches=$(grounding_breaches hono "$HONO" "$hsrc")
    [ -z "$breaches" ] || fail "hono-api not grounded: $breaches"
  fi
}
