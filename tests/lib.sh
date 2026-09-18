#!/usr/bin/env bash
# Shared helpers for the Polype test suite. Each *.test.sh defines test_<name> functions.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
METHOD="$ROOT/method"

fail() { printf '      %s\n' "$*" >&2; return 1; }

frontmatter() {
  awk 'NR==1 && $0=="---" {inside=1; next} inside && $0=="---" {exit} inside {print}' "$1"
}

# Prints one tool per line, from either `allowed-tools:` (YAML list) or `tools: A, B` (inline).
tools_of() {
  frontmatter "$1" | awk '
    /^allowed-tools:/ {list=1; next}
    list && /^  - / {sub(/^  - /, ""); print; next}
    list && !/^  - / {list=0}
    /^tools:/ {sub(/^tools:[[:space:]]*/, ""); n=split($0, t, /,[[:space:]]*/); for (i=1;i<=n;i++) print t[i]}
  '
}

has_tool() { tools_of "$1" | grep -qx "$2"; }

# Settings declared in the settings template: the `Name:` of every line inside fenced blocks.
template_settings() {
  awk '/^```/ {fence=!fence; next} fence && NF {sub(/:.*/, ""); print}' "$METHOD/templates/agents-local.md"
}

# Settings a file declares it reads, from its `Reads settings:` line.
settings_read_by() {
  grep -m1 '^Reads settings:' "$1" | sed 's/^Reads settings:[[:space:]]*//' | grep -o '`[^`]*`' | tr -d '`'
}

require_file() { [ -f "$1" ] || fail "missing file: ${1#"$ROOT"/}"; }

contains() { grep -qiF -- "$2" "$1" || fail "${1#"$ROOT"/} does not mention: $2"; }
