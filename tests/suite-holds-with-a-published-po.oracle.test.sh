#!/usr/bin/env bash
# s214 — the oracle of the story: the payload test of s164 holds once bin/polype carries, in PO_SUMS,
# the sum of the very po a source build lays here, as on CI once a release's sums landed (the release
# job and the suite build the same binary on the same runner), whether a download would fail or
# succeed; and no test of the suite lets the installer download po.

# A throwaway copy of Polype whose cargo is a double: every build gives the same binary, and the
# copy's PO_SUMS expects that binary for this platform.
summed_copy() {
  scratch_repo
  SCRATCH="$(cd "$SCRATCH" && pwd -P)"
  C="$SCRATCH/polype"
  DIST="$SCRATCH/dist"
  mkdir -p "$C/po" "$C/tests" "$SCRATCH/stubs"
  cp -R "$ROOT/bin" "$ROOT/method" "$C/"
  cp "$ROOT/po/Cargo.toml" "$ROOT/po/Cargo.lock" "$C/po/"
  cp -R "$ROOT/po/src" "$C/po/"
  require_file "$ROOT/tests/state-as-json.test.sh"
  cp "$ROOT/tests/lib.sh" "$ROOT/tests/state-as-json.test.sh" "$C/tests/"
  cat > "$SCRATCH/stubs/cargo" <<'EOF'
#!/usr/bin/env bash
target="" manifest=""
while [ $# -gt 0 ]; do
  case "$1" in --target-dir) target="$2"; shift ;; --manifest-path) manifest="$2"; shift ;; esac
  shift
done
[ -n "$target" ] || target="${CARGO_TARGET_DIR:-$(dirname "$manifest")/target}"
mkdir -p "$target/release"
printf '#!/bin/sh\necho po-double\n' > "$target/release/po"
chmod +x "$target/release/po"
EOF
  chmod +x "$SCRATCH/stubs/cargo"
  export PATH="$SCRATCH/stubs:$PATH" CARGO_TARGET_DIR="$SCRATCH/target"
  (cd "$SCRATCH" && "$C/bin/po-release" "$DIST" >/dev/null 2>&1) || fail "po-release failed in the copy"
  SUMFILE="$(find "$DIST" -maxdepth 1 -name 'po-*.sha256' | head -n 1)"
  [ -n "$SUMFILE" ] || fail "po-release wrote no .sha256"
  sed -i "/^PO_SUMS='\$/r $SUMFILE" "$C/bin/polype"
  bash -n "$C/bin/polype" || fail "the copy's bin/polype no longer parses once summed"
  grep -qxF "$(cat "$SUMFILE")" "$C/bin/polype" || fail "the copy's PO_SUMS does not hold $(cat "$SUMFILE")"
  cat > "$SCRATCH/fetch" <<EOF
#!/usr/bin/env bash
cp "$DIST/\${1##*/}" "\$2"
EOF
  chmod +x "$SCRATCH/fetch"
}

payload_test_in_copy() {
  (cd "$C/tests" && bash -c "set -eu; source ./lib.sh; source ./state-as-json.test.sh; test_po_is_a_state_file_of_the_payload")
}

test_payload_run_keeps_its_po() {
  summed_copy
  local out
  export POLYPE_PO_FETCH=false
  out="$(payload_test_in_copy 2>&1)" \
    || fail "po_is_a_state_file_of_the_payload fails once PO_SUMS holds the sum of the po built here, no download possible: $out"
  export POLYPE_PO_FETCH="$SCRATCH/fetch"
  out="$(payload_test_in_copy 2>&1)" \
    || fail "po_is_a_state_file_of_the_payload fails once PO_SUMS holds the sum of the po built here, a download possible: $out"
}

test_no_test_reaches_the_network_for_po() {
  local file name token bad=""
  grep -qx 'export POLYPE_PO_FETCH=false' "$ROOT/tests/run.sh" \
    || fail "tests/run.sh does not export POLYPE_PO_FETCH=false for every test"
  for file in "$ROOT"/tests/*.sh; do
    name="${file##*/}"
    [ "$name" != suite-holds-with-a-published-po.oracle.test.sh ] || continue
    while IFS= read -r token; do
      case "$token" in
        POLYPE_PO_FETCH=false|POLYPE_PO_FETCH=\"\$SCRATCH/*) ;;
        *) bad+="$name sets $token; " ;;
      esac
    done < <(grep -oE 'POLYPE_PO_FETCH=[^[:space:];)]*' "$file" || true)
    if grep -nE '(unset|env[[:space:]].*-u)[[:space:]]+.*POLYPE_PO_FETCH' "$file" >/dev/null; then
      bad+="$name drops POLYPE_PO_FETCH; "
    fi
    if grep -nE 'env[[:space:]]+-i[[:space:]].*(polype|POLYPE)' "$file" >/dev/null; then
      bad+="$name runs the installer with a cleared environment; "
    fi
  done
  [ -z "$bad" ] || fail "a test can let the installer download po: $bad"
}
