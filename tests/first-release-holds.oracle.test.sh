#!/usr/bin/env bash
# s189 — the oracle of the story: a release of po refuses a tag that is not v<version>, reruns
# without failing, the cleanup after a pose waits for this version's po, and a command writes
# PO_SUMS. Nothing reaches a forge: release.yml's run: lines are played in file order against a gh
# double that refuses what the real gh refuses (an existing release, an existing asset without
# --clobber). Fixture shape of s171's oracle, copied, not sourced.

sha_of() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum < "$1" | cut -d' ' -f1
  else shasum -a 256 < "$1" | cut -d' ' -f1; fi
}

# A throwaway copy of Polype at $C, HOME and CLAUDE_CONFIG_DIR ($H) under $SCRATCH, and a cargo
# double first on the PATH that builds a po printing $PO_DOUBLE_MARK.
copy_of_polype() {
  scratch_repo
  SCRATCH="$(cd "$SCRATCH" && pwd -P)"
  C="$SCRATCH/polype"
  mkdir -p "$C/po" "$SCRATCH/stubs" "$SCRATCH/home/.claude"
  cp -R "$ROOT/bin" "$ROOT/method" "$ROOT/.github" "$C/"
  cp "$ROOT/po/Cargo.toml" "$ROOT/po/Cargo.lock" "$C/po/"
  cp -R "$ROOT/po/src" "$C/po/"
  export HOME="$SCRATCH/home" CLAUDE_CONFIG_DIR="$SCRATCH/home/.claude" CARGO_TARGET_DIR="$SCRATCH/target"
  H="$CLAUDE_CONFIG_DIR"
  VERSION="$(sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$C/bin/polype")"
  [ -n "$VERSION" ] || fail "bin/polype carries no POLYPE_VERSION"
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

# The gh double: one directory per release under $SCRATCH/forge, one file per asset. Like gh, it
# refuses to create a release that exists and to upload over an asset without --clobber.
gh_double() {
  mkdir -p "$SCRATCH/forge"
  : > "$SCRATCH/gh.log"
  cat > "$SCRATCH/stubs/gh" <<EOF
#!/usr/bin/env bash
echo "gh \$*" >> "$SCRATCH/gh.log"
forge="$SCRATCH/forge"
[ "\${1-}" = release ] || exit 2
verb="\${2-}"; shift 2
tag="" clobber=no files=()
while [ \$# -gt 0 ]; do
  case "\$1" in
    --repo|-R|--title|-t|--notes|-n|--notes-file|-F|--target|--pattern|-p|--dir|-D) shift ;;
    --clobber) clobber=yes ;;
    -*) ;;
    *) if [ -z "\$tag" ]; then tag="\$1"; else files+=("\$1"); fi ;;
  esac
  shift
done
[ -n "\$tag" ] || exit 2
case "\$verb" in
  view) [ -d "\$forge/\$tag" ] || { echo "release not found" >&2; exit 1; } ;;
  create)
    if [ -d "\$forge/\$tag" ]; then echo "a release with the same tag name already exists: \$tag" >&2; exit 1; fi
    mkdir -p "\$forge/\$tag" ;;
  upload)
    [ -d "\$forge/\$tag" ] || { echo "release not found" >&2; exit 1; }
    for f in "\${files[@]}"; do
      [ -f "\$f" ] || { echo "no such file: \$f" >&2; exit 1; }
      if [ -e "\$forge/\$tag/\${f##*/}" ] && [ "\$clobber" = no ]; then
        echo "asset under the same name already exists: \${f##*/}" >&2; exit 1
      fi
    done
    for f in "\${files[@]}"; do cp "\$f" "\$forge/\$tag/"; done ;;
  *) exit 2 ;;
esac
EOF
  chmod +x "$SCRATCH/stubs/gh"
}

# publish <tag>: plays every run: line of the copy's release.yml in file order, from the copy's
# root, as the runner would for a push of <tag>, stopping at the first that fails. Sets STATUS, OUT.
# The copy gets the origin/main the release job's checkout fetches, holding no sum yet.
publish() {
  local line value
  STATUS=0 OUT=""
  [ -d "$C/.git" ] || { git -C "$C" init -q -b main && git -C "$C" add bin/polype \
    && git -C "$C" -c user.email=test@example.com -c user.name=test -c commit.gpgsign=false commit -qm main \
    && git -C "$C" update-ref refs/remotes/origin/main HEAD; } || fail "the copy got no origin/main"
  while IFS= read -r line; do
    value="$(sed -E 's/^[[:space:]]*(- )?run:[[:space:]]*//; s/[[:space:]]+$//' <<< "$line")"
    OUT+="$(cd "$C" && GITHUB_REF_NAME="$1" GITHUB_REPOSITORY=example/polype GH_TOKEN=x \
      PO_DOUBLE_MARK=prebuilt bash -e -c "$value" 2>&1)"$'\n' || { STATUS=$?; return 0; }
  done < <(grep -E '^[[:space:]]*(- )?run:' "$C/.github/workflows/release.yml")
}

# The checkout of main a person runs --sums from: v$VERSION tags a commit of its origin/main.
tagged_on_main() {
  git -C "$C" init -q -b main && git -C "$C" add bin/polype \
    && git -C "$C" -c user.email=test@example.com -c user.name=test -c commit.gpgsign=false commit -qm main \
    && git -C "$C" tag "v$VERSION" && git -C "$C" update-ref refs/remotes/origin/main HEAD \
    || fail "the copy got no tag v$VERSION on origin/main"
}

uploads() { grep -E '^gh release upload' "$SCRATCH/gh.log" || true; }

fetch_double() {
  cat > "$SCRATCH/fetch" <<EOF
#!/usr/bin/env bash
[ ! -e "$SCRATCH/offline" ] || exit 1
cp "$SCRATCH/dist/\${1##*/}" "\$2" || exit 1
[ ! -e "$SCRATCH/tamper" ] || printf 'tampered\n' >> "\$2"
EOF
  chmod +x "$SCRATCH/fetch"
  export POLYPE_PO_FETCH="$SCRATCH/fetch"
}

project_repo() {
  P="$SCRATCH/project"
  mkdir -p "$P"
  git -C "$P" init -q -b main
  git -C "$P" config user.email test@example.com
  git -C "$P" config user.name test
  git -C "$P" config commit.gpgsign false
  git -C "$P" commit -q --allow-empty -m init
}

run() { STATUS=0; OUT="$(bash "$C/bin/polype" "$@" 2>&1)" || STATUS=$?; }

# The machine directory of $P, holding a file only an older po reads.
leave_an_old_machine_file() {
  M="$(git -C "$P" rev-parse --path-format=absolute --git-common-dir)/polype"
  mkdir -p "$M"
  printf '{}\n' > "$M/old-session.json"
}

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

test_tag_must_match_the_version() {
  copy_of_polype
  gh_double
  publish "v9.9.9-not-$VERSION"
  [ "$STATUS" -ne 0 ] || fail "a release of tag v9.9.9-not-$VERSION passed although po is at $VERSION: $OUT"
  [ -z "$(uploads)" ] || fail "a release of a wrong tag uploaded something: $(uploads)"

  sed -i 's/^version = ".*"$/version = "9.9.9"/' "$C/po/Cargo.toml"
  : > "$SCRATCH/gh.log"
  publish "v$VERSION"
  [ "$STATUS" -ne 0 ] || fail "a release passed with bin/polype at $VERSION and po/Cargo.toml at 9.9.9: $OUT"
  [ -z "$(uploads)" ] || fail "a release whose two versions differ uploaded something: $(uploads)"

  cp "$ROOT/po/Cargo.toml" "$C/po/Cargo.toml"
  : > "$SCRATCH/gh.log"
  publish "v$VERSION"
  [ "$STATUS" -eq 0 ] || fail "the release of v$VERSION failed ($STATUS): $OUT"
  [ -n "$(find "$SCRATCH/forge/v$VERSION" -maxdepth 1 -name "po-$VERSION-*.sha256")" ] \
    || fail "the release of v$VERSION published no po-$VERSION-<platform>.sha256: $(cat "$SCRATCH/gh.log")"
}

test_release_reruns_cleanly() {
  copy_of_polype
  gh_double
  publish "v$VERSION"
  [ "$STATUS" -eq 0 ] || fail "the first release of v$VERSION failed ($STATUS): $OUT"
  local before
  before="$(ls "$SCRATCH/forge/v$VERSION")"
  [ -n "$before" ] || fail "the first release uploaded nothing"
  publish "v$VERSION"
  [ "$STATUS" -eq 0 ] || fail "rerunning the release of v$VERSION, already published, failed ($STATUS): $OUT"
  [ "$(ls "$SCRATCH/forge/v$VERSION")" = "$before" ] || fail "the rerun changed the published assets: $(ls "$SCRATCH/forge/v$VERSION")"
}

test_cleanup_waits_for_the_new_po() {
  copy_of_polype
  project_repo
  export POLYPE_PO_FETCH=false
  local old="$SCRATCH/older" bare
  cp -R "$C" "$old"
  sed -i 's/^POLYPE_VERSION=".*"$/POLYPE_VERSION="0.0.1"/' "$old/bin/polype"
  STATUS=0; OUT="$(bash "$old/bin/polype" install "$P" 2>&1)" || STATUS=$?
  [ "$STATUS" -eq 0 ] && [ -x "$H/polype/po" ] || fail "the older installer laid no po ($STATUS): $OUT"
  leave_an_old_machine_file

  bare="$(path_without_cargo)"
  STATUS=0; OUT="$(PATH="$bare" "$bare/bash" "$C/bin/polype" update "$P" 2>&1)" || STATUS=$?
  [ "$STATUS" -eq 0 ] || fail "update without cargo failed ($STATUS): $OUT"
  grep -qF 'cargo not found' <<< "$OUT" || fail "update without cargo did not say po was not built: $OUT"
  [ -f "$M/old-session.json" ] || fail "an update that laid no po $VERSION removed a file the older po still reads: $OUT"

  run update "$P"
  [ "$STATUS" -eq 0 ] || fail "update with cargo failed ($STATUS): $OUT"
  [ ! -e "$M/old-session.json" ] || fail "once po $VERSION was laid, update did not clean the older po's file: $OUT"
}

test_refused_po_cleans_nothing() {
  copy_of_polype
  DIST="$SCRATCH/dist"
  (cd "$SCRATCH" && PO_DOUBLE_MARK=prebuilt "$C/bin/po-release" "$DIST" >/dev/null 2>&1) || fail "po-release failed"
  local sumfile
  sumfile="$(find "$DIST" -maxdepth 1 -name "po-$VERSION-*.sha256" | head -n 1)"
  [ -n "$sumfile" ] || fail "po-release wrote no .sha256"
  sed -i "/^PO_SUMS='\$/r $sumfile" "$C/bin/polype"
  fetch_double
  project_repo
  run install "$P"
  [ "$STATUS" -eq 0 ] || fail "install failed ($STATUS): $OUT"
  leave_an_old_machine_file

  printf '#!/bin/sh\necho another-po\n' > "$H/polype/po"
  touch "$SCRATCH/tamper"
  run update "$P"
  [ "$STATUS" -ne 0 ] && grep -qF 'po refused' <<< "$OUT" || fail "update did not refuse the altered download ($STATUS): $OUT"
  [ -f "$M/old-session.json" ] || fail "an update whose po was refused removed a machine file: $OUT"

  rm -f "$SCRATCH/tamper"
  run update "$P"
  [ "$STATUS" -eq 0 ] || fail "update with an intact download failed ($STATUS): $OUT"
  [ ! -e "$M/old-session.json" ] || fail "once the verified po was laid, update did not clean the older po's file: $OUT"
}

test_sums_are_written_by_a_command() {
  copy_of_polype
  DIST="$SCRATCH/dist"
  (cd "$SCRATCH" && PO_DOUBLE_MARK=prebuilt "$C/bin/po-release" "$DIST" >/dev/null 2>&1) || fail "po-release failed"
  local sums="$SCRATCH/sums" platform name block expected="" before
  mkdir -p "$sums"
  cp "$DIST"/*.sha256 "$sums/"
  # The two platforms this host did not build, as a release's other runners would publish them.
  for platform in linux-x86_64 linux-aarch64 macos-aarch64; do
    name="po-$VERSION-$platform"
    if [ ! -f "$sums/$name.sha256" ]; then
      printf 'po built on %s\n' "$platform" > "$SCRATCH/$name"
      printf '%s  %s\n' "$(sha_of "$SCRATCH/$name")" "$name" > "$sums/$name.sha256"
    fi
    expected+="$(cat "$sums/$name.sha256")"$'\n'
  done

  tagged_on_main
  STATUS=0; OUT="$("$C/bin/po-release" --sums "$sums" origin/main 2>&1)" || STATUS=$?
  [ "$STATUS" -eq 0 ] || fail "po-release --sums failed ($STATUS): $OUT"
  block="$(awk "/^PO_SUMS='\$/ {inside=1; next} inside && /^'\$/ {exit} inside {print}" "$C/bin/polype")"
  [ "$(sort <<< "$block")" = "$(sort <<< "${expected%$'\n'}")" ] \
    || fail "PO_SUMS does not hold the three .sha256 lines of the release: $block"
  bash -n "$C/bin/polype" || fail "bin/polype no longer parses once PO_SUMS is written"

  before="$(cksum < "$C/bin/polype")"
  STATUS=0; OUT="$("$C/bin/po-release" --sums "$sums" origin/main 2>&1)" || STATUS=$?
  [ "$STATUS" -eq 0 ] || fail "po-release --sums failed on its second run ($STATUS): $OUT"
  [ "$(cksum < "$C/bin/polype")" = "$before" ] || fail "a second po-release --sums changed bin/polype"

  fetch_double
  project_repo
  run install "$P"
  [ "$STATUS" -eq 0 ] || fail "install failed ($STATUS): $OUT"
  cmp -s "$H/polype/po" "$(find "$DIST" -maxdepth 1 -type f -name "po-$VERSION-*" ! -name '*.sha256' | head -n 1)" \
    || fail "the installer did not lay the published po from the sums the command wrote: $OUT"
}
