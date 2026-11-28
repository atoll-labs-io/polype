#!/usr/bin/env bash
# Shared helpers for the Polype test suite. Each *.test.sh defines test_<name> functions,
# and each test runs in its own process, so `fail` ends the test at the first broken assertion.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
METHOD="$ROOT/method"
PO="${CARGO_TARGET_DIR:-$ROOT/po/target}/release/po"

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

# A git repository in a temporary directory, removed when the test process exits; every folder made
# in the process is removed, not only the last one.
[ -n "${SCRATCH_DIRS+set}" ] || SCRATCH_DIRS=()
scratch_repo() {
  SCRATCH="$(mktemp -d)"
  SCRATCH_DIRS+=("$SCRATCH")
  trap 'rm -rf "${SCRATCH_DIRS[@]}"' EXIT
  git -C "$SCRATCH" init -q -b main
  git -C "$SCRATCH" config user.email test@example.com
  git -C "$SCRATCH" config user.name test
  git -C "$SCRATCH" config commit.gpgsign false
}

# po_bounded <what> <dir> <args...>: runs po in <dir>, sets OUT and STATUS as po_in does. Fails when po
# does not answer within 10 s (a po that waits spends no CPU, so only a cap stops it) or spends a second
# of CPU or more (CPU time, not wall time, which a loaded machine stretches). Any other status is the caller's.
po_bounded() {
  local what="$1" dir="$2" TIMEFORMAT='%3U %3S' cpu_f cpu_u cpu_s ms
  shift 2
  cpu_f="$(mktemp)"; STATUS=0
  { time OUT="$(cd "$dir" && timeout 10 "$PO" "$@" 2>/dev/null)" || STATUS=$?; } 2> "$cpu_f"
  read -r cpu_u cpu_s < "$cpu_f" || true
  rm -f "$cpu_f"
  [ "$STATUS" -ne 124 ] || fail "$what did not answer within 10 s"
  cpu_u="${cpu_u//[!0-9]/}"; cpu_s="${cpu_s//[!0-9]/}"
  ms=$(( 10#${cpu_u:-0} + 10#${cpu_s:-0} ))
  [ "$ms" -lt 1000 ] || fail "$what took ${ms} ms of CPU, not under a second"
}
