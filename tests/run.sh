#!/usr/bin/env bash
# Runs every test_* function of tests/*.test.sh (or of the files given as arguments).
set -u
cd "$(dirname "$0")"
files=("$@")
[ ${#files[@]} -gt 0 ] || files=(*.test.sh)

# Taken before any test moves HOME, so a cargo the installer launches still finds its toolchain.
export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}" RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"
root="$(cd .. && pwd)"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$root/po/target}"
# The suite never downloads po: an installer run falls back to the sources. A test that needs a
# download sets its own double.
export POLYPE_PO_FETCH=false
# No test may reach the developer's real ~/.claude, even one that never sets it itself.
claude_tmp="$(mktemp -d)"
trap 'rm -rf "$claude_tmp"' EXIT
export CLAUDE_CONFIG_DIR="$claude_tmp/claude"
mkdir -p "$CLAUDE_CONFIG_DIR"

# A copy of this runner outside the repository has no crate to build.
if [ -f "$root/po/Cargo.toml" ]; then
  if ! build=$(cargo build --release --locked --quiet --manifest-path "$root/po/Cargo.toml" 2>&1); then
    echo "po does not build:"; echo "$build"; exit 1
  fi
  # A copy, not a symlink: an installer test running lay_po on this directory replaces the file.
  mkdir -p "$CLAUDE_CONFIG_DIR/polype" && cp "$CARGO_TARGET_DIR/release/po" "$CLAUDE_CONFIG_DIR/polype/po"
fi

passed=0 failed=0 skipped=0
for file in "${files[@]}"; do
  echo "${file}"
  if ! names=$(bash -c "source ./lib.sh && source './${file}' && declare -F" 2>&1); then
    echo "  FAIL  (file does not load)"; echo "$names"; failed=$((failed + 1)); continue
  fi
  names=$(awk '$3 ~ /^test_/ {print $3}' <<< "$names")
  [ -n "$names" ] || { echo "  FAIL  (no test found)"; failed=$((failed + 1)); continue; }
  for name in $names; do
    if out=$(bash -c "set -eu; source ./lib.sh; source './${file}'; ${name}" 2>&1); then
      if grep -qF 'not reachable: grounding not checked' <<< "$out"; then
        echo "  skip  ${name#test_}"; echo "$out"; skipped=$((skipped + 1))
      else
        echo "  ok    ${name#test_}"; passed=$((passed + 1))
      fi
    else
      echo "  FAIL  ${name#test_}"; [ -n "$out" ] && echo "$out"; failed=$((failed + 1))
    fi
  done
done
echo "${passed} passed, ${failed} failed, ${skipped} skipped"
[ "$failed" -eq 0 ]
