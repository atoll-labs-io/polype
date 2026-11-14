#!/usr/bin/env bash
# s171 — task tests beside the oracle: po.sum is a state file of the payload, check accepts a po
# laid before s171, and the suite's own environment never downloads po. Same fixture shape as the
# oracle (copied, not sourced): a throwaway copy of Polype, a cargo double, nothing downloaded.

copy_of_polype() {
  scratch_repo
  SCRATCH="$(cd "$SCRATCH" && pwd -P)"
  C="$SCRATCH/polype"
  mkdir -p "$C/po" "$SCRATCH/stubs" "$SCRATCH/home/.claude"
  cp -R "$ROOT/bin" "$ROOT/method" "$C/"
  cp "$ROOT/po/Cargo.toml" "$ROOT/po/Cargo.lock" "$C/po/"
  cp -R "$ROOT/po/src" "$C/po/"
  export HOME="$SCRATCH/home" CLAUDE_CONFIG_DIR="$SCRATCH/home/.claude" CARGO_TARGET_DIR="$SCRATCH/target"
  H="$CLAUDE_CONFIG_DIR"
  cat > "$SCRATCH/stubs/cargo" <<EOF
#!/usr/bin/env bash
target="" manifest=""
while [ \$# -gt 0 ]; do
  case "\$1" in --target-dir) target="\$2"; shift ;; --manifest-path) manifest="\$2"; shift ;; esac
  shift
done
[ -n "\$target" ] || target="\${CARGO_TARGET_DIR:-\$(dirname "\$manifest")/target}"
mkdir -p "\$target/release"
printf '#!/bin/sh\necho %s\n' "\${PO_DOUBLE_MARK:-built-from-sources}" > "\$target/release/po"
chmod +x "\$target/release/po"
EOF
  chmod +x "$SCRATCH/stubs/cargo"
  export PATH="$SCRATCH/stubs:$PATH"
}

# bin/po-release of the copy writes the binary into $DIST, and the copy's PO_SUMS expects its sum.
publish_this_platform() {
  DIST="$SCRATCH/dist"
  (cd "$SCRATCH" && PO_DOUBLE_MARK=prebuilt "$C/bin/po-release" "$DIST" >/dev/null 2>&1) || fail "po-release failed"
  local sumfile
  sumfile="$(find "$DIST" -maxdepth 1 -name 'po-*.sha256' | head -n 1)"
  [ -n "$sumfile" ] || fail "po-release wrote no .sha256"
  sed -i "/^PO_SUMS='\$/r $sumfile" "$C/bin/polype"
}

run() { STATUS=0; OUT="$(bash "$1" "${@:2}" 2>&1)" || STATUS=$?; }

test_po_record_is_a_state_file_of_the_payload() {
  copy_of_polype
  publish_this_platform
  cat > "$SCRATCH/fetch" <<EOF
#!/usr/bin/env bash
cp "$SCRATCH/dist/\${1##*/}" "\$2"
EOF
  chmod +x "$SCRATCH/fetch"
  export POLYPE_PO_FETCH="$SCRATCH/fetch"
  run "$C/bin/polype" install --global
  [ "$STATUS" -eq 0 ] || fail "install --global failed ($STATUS): $OUT"
  grep -qF ' prebuilt' "$H/polype/po.sum" 2>/dev/null || fail "install --global wrote no po.sum for the prebuilt po: $OUT"
  run "$H/polype/bin/polype" update --global
  [ "$STATUS" -eq 0 ] || fail "update --global from the payload stopped ($STATUS): $OUT"
  ! grep -qi 'po\.sum' <<< "$OUT" || fail "update --global named po.sum: $OUT"
  [ -f "$H/polype/po.sum" ] || fail "update --global did not keep po.sum"
}

test_check_accepts_a_po_laid_before_s171() {
  copy_of_polype
  export POLYPE_PO_FETCH=false
  run "$C/bin/polype" install --global
  [ "$STATUS" -eq 0 ] || fail "install --global failed ($STATUS): $OUT"
  [ -f "$H/polype/po" ] && [ -f "$H/polype/po.sum" ] || fail "install --global laid no po and its record: $OUT"
  rm -f "$H/polype/po.sum"
  run "$C/bin/polype" check --global
  [ "$STATUS" -eq 0 ] || fail "check --global fails on a po with no record ($STATUS): $OUT"
  grep -qE '^po not verified' <<< "$OUT" || fail "check --global does not say po is not verified: $OUT"
}

test_suite_environment_refuses_downloads() {
  [ "${POLYPE_PO_FETCH-}" = false ] || fail "the suite does not export POLYPE_PO_FETCH=false (got '${POLYPE_PO_FETCH-}')"
  copy_of_polype
  publish_this_platform
  local tool
  for tool in curl wget; do
    printf '#!/bin/sh\necho "%s $*" >> "%s/net.log"\nexit 1\n' "$tool" "$SCRATCH" > "$SCRATCH/stubs/$tool"
    chmod +x "$SCRATCH/stubs/$tool"
  done
  : > "$SCRATCH/net.log"
  run "$C/bin/polype" install --global
  [ "$STATUS" -eq 0 ] || fail "install --global failed ($STATUS): $OUT"
  [ ! -s "$SCRATCH/net.log" ] || fail "the installer reached for the network: $(cat "$SCRATCH/net.log")"
  grep -qF built-from-sources "$H/polype/po" 2>/dev/null || fail "po was not built from the sources: $OUT"
}
