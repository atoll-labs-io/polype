#!/usr/bin/env bash
# s171 — the oracle of the story: po is released per platform with its sha256, and the installer
# downloads it, checks it against the sum it carries, falls back to the sources, cleans what an
# older po left, and check audits it (ADR-0115, ADR-0117, ADR-0121). Nothing is ever downloaded:
# the download command is a double named by POLYPE_PO_FETCH, and cargo is a double on the PATH.

RELEASE_WORKFLOW="$ROOT/.github/workflows/release.yml"

sha_of() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum < "$1" | cut -d' ' -f1
  else shasum -a 256 < "$1" | cut -d' ' -f1; fi
}

# A throwaway copy of Polype at $C, a throwaway HOME, CLAUDE_CONFIG_DIR at $H, a cargo double first
# on the PATH (it logs to $SCRATCH/cargo.log and builds a po printing $PO_DOUBLE_MARK), and a cargo
# target dir of the test's own, so the real po of the suite is never overwritten.
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
  VERSION="$(sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$C/bin/polype")"
  [ -n "$VERSION" ] || fail "bin/polype carries no POLYPE_VERSION"
  : > "$SCRATCH/cargo.log"
  cat > "$SCRATCH/stubs/cargo" <<EOF
#!/usr/bin/env bash
echo "cargo \$*" >> "$SCRATCH/cargo.log"
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

# Runs bin/po-release of the copy into $DIST; sets BIN (the binary) and SUMFILE (its .sha256).
release_into_dist() {
  DIST="$SCRATCH/dist"
  local out
  out="$(cd "$SCRATCH" && PO_DOUBLE_MARK=prebuilt "$C/bin/po-release" "$DIST" 2>&1)" || fail "po-release failed: $out"
  BIN="$(find "$DIST" -maxdepth 1 -type f -name "po-$VERSION-*" ! -name '*.sha256' | head -n 1)"
  [ -n "$BIN" ] || fail "po-release wrote no po-$VERSION-<platform> in $DIST: $(ls "$DIST" 2>&1)"
  SUMFILE="$BIN.sha256"
  [ -f "$SUMFILE" ] || fail "po-release wrote no ${BIN##*/}.sha256"
}

# The installer of the copy expects the sum po-release wrote, in its PO_SUMS block.
expect_release_sum() {
  [ "$(grep -c "^PO_SUMS='\$" "$C/bin/polype")" = 1 ] || fail "bin/polype has no single PO_SUMS=' line opening its sums"
  sed -i "/^PO_SUMS='\$/r $SUMFILE" "$C/bin/polype"
}

# The download double: logs the URL, then serves the file of $DIST with the URL's last segment,
# altered when $SCRATCH/tamper exists, or fails when $SCRATCH/offline exists.
fetch_double() {
  cat > "$SCRATCH/fetch" <<EOF
#!/usr/bin/env bash
echo "\$1" >> "$SCRATCH/fetch.log"
[ ! -e "$SCRATCH/offline" ] || exit 1
cp "$SCRATCH/dist/\${1##*/}" "\$2" || exit 1
[ ! -e "$SCRATCH/tamper" ] || printf 'tampered\n' >> "\$2"
EOF
  chmod +x "$SCRATCH/fetch"
  export POLYPE_PO_FETCH="$SCRATCH/fetch"
}

project_repo() {
  P="$SCRATCH/project"
  mkdir -p "$P/notes"
  git -C "$P" init -q -b main
  git -C "$P" config user.email test@example.com
  git -C "$P" config user.name test
  git -C "$P" config commit.gpgsign false
  printf 'tracked\n' > "$P/notes/old-session.json"
  git -C "$P" add -A
  git -C "$P" commit -qm init
}

# run <args...>: sets OUT and STATUS from the copy's installer; never fails by itself.
run() { STATUS=0; OUT="$(bash "$C/bin/polype" "$@" 2>&1)" || STATUS=$?; }

# A directory linking every program of the PATH but cargo, rustc and rustup.
path_without_cargo() {
  local out="$SCRATCH/nocargo" d
  local -a dirs
  mkdir -p "$out"
  IFS=: read -ra dirs <<< "$PATH"
  for d in "${dirs[@]}"; do
    [ -d "$d" ] || continue
    find "$d" -maxdepth 1 \( -type f -o -type l \) -perm -u+x -print0 2>/dev/null \
      | xargs -0 -r ln -s -t "$out" 2>/dev/null || true
  done
  rm -f "$out/cargo" "$out/rustc" "$out/rustup"
  if PATH="$out" command -v cargo >/dev/null 2>&1; then fail "cargo is still reachable without it"; fi
  printf '%s' "$out"
}

test_release_builds_one_binary_per_platform() {
  copy_of_polype
  release_into_dist
  local name os line value runs=0 releases=0 dir=""
  name="${BIN##*/}"
  case "$(uname -s)" in Linux) os=linux ;; Darwin) os=macos ;; *) os="" ;; esac
  [[ "$name" =~ ^po-$VERSION-(linux|macos)-(x86_64|aarch64)$ ]] || fail "the binary is not named po-<version>-<os>-<arch>: $name"
  [ -z "$os" ] || [[ "$name" == "po-$VERSION-$os-"* ]] || fail "$name does not name the platform it was built on ($os)"
  grep -qF prebuilt "$BIN" || fail "the released binary is not what cargo built"
  [ -s "$SCRATCH/cargo.log" ] || fail "po-release did not call cargo"
  grep -qF -- '--release' "$SCRATCH/cargo.log" && grep -qF -- '--locked' "$SCRATCH/cargo.log" \
    || fail "po-release does not build with --release --locked: $(cat "$SCRATCH/cargo.log")"
  [ "$(cat "$SUMFILE")" = "$(sha_of "$BIN")  $name" ] \
    || fail "${SUMFILE##*/} is not the sha256sum line of the binary: $(cat "$SUMFILE")"

  require_file "$RELEASE_WORKFLOW"
  grep -qE '^[[:space:]]*tags:' "$RELEASE_WORKFLOW" || fail "the release workflow does not run on a tag"
  grep -qE 'runs-on:.*matrix\.' "$RELEASE_WORKFLOW" || fail "the release workflow does not run once per platform of a matrix"
  ! grep -qE '(^|[^[:alnum:]])(cargo|rustup|rustc)([^[:alnum:]]|$)' "$RELEASE_WORKFLOW" \
    || fail "the release workflow builds po itself instead of calling bin/po-release"
  while IFS= read -r line; do
    value="$(sed -E 's/^[[:space:]]*(- )?run:[[:space:]]*//; s/[[:space:]]+$//' <<< "$line")"
    case "$value" in ''|'|'*|'>'*) fail "each run: must stay on one line: $line" ;; esac
    if [[ "$value" =~ ^(bash\ )?(\./)?bin/po-release\ ([^[:space:]]+)$ ]]; then
      dir="${BASH_REMATCH[3]}"; runs=$((runs + 1))
    elif [[ "$value" == "gh release "* ]]; then
      releases=$((releases + 1))
    else
      fail "the release workflow runs something other than bin/po-release and gh release: $value"
    fi
  done < <(grep -E '^[[:space:]]*(- )?run:' "$RELEASE_WORKFLOW")
  [ "$runs" -eq 1 ] || fail "the release workflow calls bin/po-release $runs times, once per matrix job expected"
  grep -E '^[[:space:]]*(- )?run:[[:space:]]*gh release upload' "$RELEASE_WORKFLOW" | grep -qF "$dir/" \
    || fail "no gh release upload publishes what bin/po-release wrote in $dir"
}

test_installer_downloads_and_verifies() {
  copy_of_polype
  release_into_dist
  expect_release_sum
  fetch_double
  project_repo
  local expected found
  : > "$SCRATCH/cargo.log"
  run install "$P"
  [ "$STATUS" -eq 0 ] || fail "install failed ($STATUS): $OUT"
  [ -x "$H/polype/po" ] && cmp -s "$H/polype/po" "$BIN" || fail "install did not lay the released binary at $H/polype/po: $OUT"
  grep -qF "/${BIN##*/}" "$SCRATCH/fetch.log" || fail "install did not fetch ${BIN##*/}: $(cat "$SCRATCH/fetch.log" 2>&1)"
  ! grep -q . "$SCRATCH/cargo.log" || fail "install built po from sources although a verified binary was published: $OUT"

  printf '#!/bin/sh\necho old-po\n' > "$H/polype/po"
  touch "$SCRATCH/tamper"
  expected="$(cut -d' ' -f1 "$SUMFILE")"
  found="$(cat "$BIN" <(printf 'tampered\n') | { if command -v sha256sum >/dev/null 2>&1; then sha256sum; else shasum -a 256; fi; } | cut -d' ' -f1)"
  run update "$P"
  [ "$STATUS" -ne 0 ] || fail "update laid or accepted a binary whose sum differs: $OUT"
  grep -qF old-po "$H/polype/po" || fail "a refused download did not keep the po in place"
  grep -qF "$expected" <<< "$OUT" && grep -qF "$found" <<< "$OUT" \
    || fail "the refusal does not name both sums ($expected expected, $found found): $OUT"
  if find "$H/polype" -maxdepth 1 -type f -exec grep -lF tampered {} + 2>/dev/null | grep -q .; then
    fail "the tampered download was left in $H/polype"
  fi
}

test_installer_falls_back_to_sources() {
  copy_of_polype
  release_into_dist
  fetch_double
  project_repo
  run install "$P"
  [ "$STATUS" -eq 0 ] || fail "install without a published binary for this platform failed ($STATUS): $OUT"
  grep -qF built-from-sources "$H/polype/po" 2>/dev/null || fail "without a published binary, po was not built from the sources: $OUT"
  grep -qF 'from sources' <<< "$OUT" || fail "install did not say it built po from sources: $OUT"

  expect_release_sum
  rm -f "$H/polype/po"
  : > "$SCRATCH/cargo.log"
  touch "$SCRATCH/offline"
  run update "$P"
  [ "$STATUS" -eq 0 ] || fail "update without network failed ($STATUS): $OUT"
  grep -q . "$SCRATCH/fetch.log" || fail "update did not try the download first"
  grep -qF built-from-sources "$H/polype/po" 2>/dev/null || fail "without network, po was not built from the sources: $OUT"
  grep -qF 'from sources' <<< "$OUT" || fail "update did not say it built po from sources: $OUT"

  local bare Q="$SCRATCH/other"
  bare="$(path_without_cargo)"
  rm -f "$H/polype/po"
  mkdir -p "$Q"
  git -C "$Q" init -q -b main
  STATUS=0
  OUT="$(PATH="$bare" "$bare/bash" "$C/bin/polype" install "$Q" 2>&1)" || STATUS=$?
  [ "$STATUS" -eq 0 ] || fail "install without network nor cargo exited $STATUS: $OUT"
  [ -f "$Q/AGENTS.md" ] && [ -x "$Q/.polype/hooks/po-gate.sh" ] || fail "install without network nor cargo did not lay the rest: $OUT"
  [ ! -e "$H/polype/po" ] || fail "a po appeared without network nor cargo"
  grep -qF 'is missing' <<< "$OUT" || fail "install did not say po is missing: $OUT"
}

test_upgrade_cleans_what_the_old_version_left() {
  copy_of_polype
  release_into_dist
  expect_release_sum
  fetch_double
  project_repo
  local m line
  run install "$P"
  [ "$STATUS" -eq 0 ] || fail "install failed ($STATUS): $OUT"
  m="$(git -C "$P" rev-parse --path-format=absolute --git-common-dir)/polype"
  mkdir -p "$m/inbox" "$P/.polype/inbox"
  printf '{}\n' > "$m/old-session.json"
  printf '{"session": "kept"}\n' > "$m/lead-session.json"
  printf '1\n' > "$m/run.lock"
  printf 'decision\n' > "$m/inbox/d-0001.md"
  printf 'decision\n' > "$P/.polype/inbox/d-0002.md"
  printf '#!/bin/sh\necho old-po-binary\n' > "$H/polype/po"

  run update "$P"
  [ "$STATUS" -eq 0 ] || fail "update failed ($STATUS): $OUT"
  cmp -s "$H/polype/po" "$BIN" || fail "update did not replace the old po with the released one: $OUT"
  if grep -rlF old-po-binary "$H/polype" 2>/dev/null | grep -q .; then fail "the old po binary is still under $H/polype"; fi
  [ ! -e "$m/old-session.json" ] || fail "update left $m/old-session.json, which the new po does not read: $OUT"
  line="$(grep -F old-session.json <<< "$OUT" || true)"
  grep -qiF removed <<< "$line" || fail "update did not say it removed old-session.json: $OUT"
  [ -f "$m/lead-session.json" ] && [ -f "$m/run.lock" ] || fail "update removed a machine file the new po still reads"
  [ -f "$m/inbox/d-0001.md" ] && [ -f "$P/.polype/inbox/d-0002.md" ] || fail "update touched a decision inbox"
  [ "$(cat "$P/notes/old-session.json")" = tracked ] && git -C "$P" diff --quiet HEAD -- notes \
    || fail "update touched a file tracked by git"
}

test_check_audits_po() {
  copy_of_polype
  release_into_dist
  expect_release_sum
  fetch_double
  project_repo
  run install "$P"
  [ "$STATUS" -eq 0 ] || fail "install failed ($STATUS): $OUT"
  run check "$P"
  if grep -qE '^po (missing|modified|version)' <<< "$OUT"; then fail "check reports a problem with a po it just laid: $OUT"; fi

  printf '9.9.9\n' > "$P/.polype/version"
  run check "$P"
  grep -E '^po version' <<< "$OUT" | grep -qF 9.9.9 || fail "check does not report a po of another version than the project's: $OUT"
  printf '%s\n' "$VERSION" > "$P/.polype/version"

  printf 'appended\n' >> "$H/polype/po"
  run check "$P"
  grep -qE '^po modified' <<< "$OUT" || fail "check does not report a po whose sum is not the installed one: $OUT"
  [ "$STATUS" -ne 0 ] || fail "check exits 0 on a po whose sum differs: $OUT"

  rm -f "$H/polype/po"
  run check "$P"
  grep -qE '^po missing' <<< "$OUT" || fail "check does not report a missing po: $OUT"
}
