#!/usr/bin/env bash
# Shared helpers for the Polype test suite. Each *.test.sh defines test_<name> functions,
# and each test runs in its own process, so `fail` ends the test at the first broken assertion.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
METHOD="$ROOT/method"

# Throwaway repositories must not depend on the developer's global git configuration.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1

fail() { printf '      %s\n' "$*" >&2; exit 1; }

frontmatter() {
  awk 'NR==1 && $0=="---" {inside=1; next} inside && $0=="---" {exit} inside {print}' "$1"
}

# One tool per line, from either `allowed-tools:` (YAML list) or `tools: A, B` (inline).
tools_of() {
  frontmatter "$1" | awk '
    /^allowed-tools:/ {list=1; next}
    list && /^  - / {sub(/^  - /, ""); print; next}
    list && !/^  - / {list=0}
    /^tools:/ {sub(/^tools:[[:space:]]*/, ""); n=split($0, t, /,[[:space:]]*/); for (i=1;i<=n;i++) print t[i]}
  '
}

has_tool() { tools_of "$1" | grep -qx "$2"; }
lacks_tool() { ! has_tool "$1" "$2" || fail "${1##*/} must not have $2"; }
needs_tool() { has_tool "$1" "$2" || fail "${1##*/} needs $2"; }

# Setting names declared in the settings template: the `Name:` of every line inside fenced blocks.
template_settings() {
  awk '/^```/ {fence=!fence; next} fence && NF {sub(/:.*/, ""); print}' "$METHOD/templates/agents-local.md"
}

# Settings a file declares it reads, from its `Reads settings:` line.
settings_read_by() {
  grep -m1 '^Reads settings:' "$1" | sed 's/^Reads settings:[[:space:]]*//' | grep -o '`[^`]*`' | tr -d '`' || true
}

require_file() { [ -f "$1" ] || fail "missing file: ${1#"$ROOT"/}"; }

contains() { grep -qF -- "$2" "$1" || fail "${1#"$ROOT"/} does not say: $2"; }

# A git repository in a temporary directory, removed when the test process exits.
scratch_repo() {
  SCRATCH="$(mktemp -d)"
  trap 'rm -rf "$SCRATCH"' EXIT
  git -C "$SCRATCH" init -q -b main
  git -C "$SCRATCH" config user.email test@example.com
  git -C "$SCRATCH" config user.name test
  git -C "$SCRATCH" config commit.gpgsign false
}
