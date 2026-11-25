#!/usr/bin/env bash
# s189 — task tests beside the oracle: a wrong tag creates no release, a rerun is refused once the
# version's sums have ever been on the target branch, the tag guard fails closed and passes only a
# commit of the target branch, and po-release --sums refuses a broken .sha256, or a tag that is not
# a commit of the target branch, without touching bin/polype. Fixture shape of the oracle, copied,
# not sourced: a throwaway copy of Polype, a cargo double, a gh double, nothing reaches a forge.

copy_of_polype() {
  scratch_repo
  SCRATCH="$(cd "$SCRATCH" && pwd -P)"
  C="$SCRATCH/polype"
  mkdir -p "$C/po" "$SCRATCH/stubs"
  cp -R "$ROOT/bin" "$ROOT/.github" "$C/"
  # The copy stands for a version not yet summed, whatever PO_SUMS of main holds.
  sed -i "/^PO_SUMS='\$/,/^'\$/{/^PO_SUMS='\$/!{/^'\$/!d}}" "$C/bin/polype"
  [ -z "$(awk "/^PO_SUMS='\$/ {inside=1; next} inside && /^'\$/ {exit} inside {print}" "$C/bin/polype")" ] \
    || fail "the copy's PO_SUMS block is not empty"
  cp "$ROOT/po/Cargo.toml" "$C/po/"
  VERSION="$(sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$C/bin/polype")"
  [ -n "$VERSION" ] || fail "bin/polype carries no POLYPE_VERSION"
  cat > "$SCRATCH/stubs/cargo" <<EOF
#!/usr/bin/env bash
target=""
while [ \$# -gt 0 ]; do
  case "\$1" in --target-dir) target="\$2"; shift ;; esac
  shift
done
mkdir -p "\$target/release"
printf '#!/bin/sh\necho prebuilt\n' > "\$target/release/po"
chmod +x "\$target/release/po"
EOF
  chmod +x "$SCRATCH/stubs/cargo"
  export PATH="$SCRATCH/stubs:$PATH" CARGO_TARGET_DIR="$SCRATCH/target"
}

# Like gh, refuses to create a release that exists; records every release it creates.
gh_double() {
  mkdir -p "$SCRATCH/forge"
  cat > "$SCRATCH/stubs/gh" <<EOF
#!/usr/bin/env bash
echo "gh \$*" >> "$SCRATCH/gh.log"
forge="$SCRATCH/forge"
[ "\${1-}" = release ] || exit 2
verb="\${2-}"; tag="\${3-}"
case "\$verb" in
  view) [ -d "\$forge/\$tag" ] || exit 1 ;;
  create) [ ! -d "\$forge/\$tag" ] || exit 1; mkdir -p "\$forge/\$tag" ;;
  upload) [ -d "\$forge/\$tag" ] || exit 1 ;;
  *) exit 2 ;;
esac
EOF
  chmod +x "$SCRATCH/stubs/gh"
}

git_c() { git -C "$C" -c user.email=test@example.com -c user.name=test -c commit.gpgsign=false "$@"; }

# The copy's HEAD is the commit tagged v$VERSION, holding its own bin/polype (empty PO_SUMS);
# origin/main starts there, as the release job's fetch-depth: 0 checkout brings it.
tagged_commit() {
  [ -d "$C/.git" ] && return 0
  git -C "$C" init -q -b main && git -C "$C" add bin/polype && git_c commit -qm tagged \
    && git -C "$C" tag "v$VERSION" && git -C "$C" update-ref refs/remotes/origin/main HEAD \
    || fail "the copy got no tagged commit"
}

# main_commit <file or empty>: origin/main gains a commit whose bin/polype is <file>, or which has
# no bin/polype when empty; HEAD stays where it is.
main_commit() {
  local index="$SCRATCH/main-index" blob tree commit
  tagged_commit
  rm -f "$index"
  GIT_INDEX_FILE="$index" git -C "$C" read-tree refs/remotes/origin/main || fail "cannot read origin/main"
  if [ -n "$1" ]; then
    blob="$(git -C "$C" hash-object -w "$1")" \
      && GIT_INDEX_FILE="$index" git -C "$C" update-index --add --cacheinfo "100755,$blob,bin/polype" \
      || fail "cannot stage bin/polype"
  else
    GIT_INDEX_FILE="$index" git -C "$C" update-index --force-remove bin/polype || fail "cannot drop bin/polype"
  fi
  tree="$(GIT_INDEX_FILE="$index" git -C "$C" write-tree)" \
    && commit="$(git_c commit-tree "$tree" -p refs/remotes/origin/main -m main)" \
    && git -C "$C" update-ref refs/remotes/origin/main "$commit" \
    || fail "origin/main got no new commit"
}

# target_branch <sum line>...: origin/main gains a commit whose PO_SUMS holds exactly these lines,
# as po-release --sums writes it, replacing the block.
target_branch() {
  local polype="$SCRATCH/main-polype" line
  cp "$C/bin/polype" "$polype"
  for line in "$@"; do sed -i "/^PO_SUMS='\$/a $line" "$polype"; done
  main_commit "$polype"
}

guard() { STATUS=0; OUT="$(cd "$C" && "$1/bin/po-release" --tag "v$VERSION" origin/main 2>&1)" || STATUS=$?; }

sums() { STATUS=0; OUT="$("$C/bin/po-release" --sums "$1" origin/main 2>&1)" || STATUS=$?; }

publish() {
  local line value
  STATUS=0 OUT=""
  while IFS= read -r line; do
    value="$(sed -E 's/^[[:space:]]*(- )?run:[[:space:]]*//; s/[[:space:]]+$//' <<< "$line")"
    OUT+="$(cd "$C" && GITHUB_REF_NAME="$1" GITHUB_REPOSITORY=example/polype bash -e -c "$value" 2>&1)"$'\n' \
      || { STATUS=$?; return 0; }
  done < <(grep -E '^[[:space:]]*(- )?run:' "$C/.github/workflows/release.yml")
}

test_wrong_tag_creates_no_release() {
  copy_of_polype
  gh_double
  publish "v9.9.9-not-$VERSION"
  [ "$STATUS" -ne 0 ] || fail "a release of a wrong tag passed: $OUT"
  [ -z "$(ls "$SCRATCH/forge")" ] || fail "a wrong tag created a release: $(ls "$SCRATCH/forge")"
}

test_sums_refuse_a_broken_line() {
  copy_of_polype
  tagged_commit
  local sums="$SCRATCH/sums" good before name="po-$VERSION-linux-x86_64"
  good="$(printf '%064d' 0)"
  before="$(cksum < "$C/bin/polype")"

  mkdir -p "$sums"
  printf 'not-a-sum  %s\n' "$name" > "$sums/$name.sha256"
  sums "$sums"
  [ "$STATUS" -eq 1 ] && grep -qF "is not one line" <<< "$OUT" || fail "po-release --sums accepted a malformed sum ($STATUS): $OUT"
  [ "$(cksum < "$C/bin/polype")" = "$before" ] || fail "a malformed sum changed bin/polype"

  printf '%s  po-%s-macos-aarch64\n' "$good" "$VERSION" > "$sums/$name.sha256"
  sums "$sums"
  [ "$STATUS" -eq 1 ] && grep -qF "is not one line" <<< "$OUT" \
    || fail "po-release --sums accepted a sum naming another file than its own ($STATUS): $OUT"
  [ "$(cksum < "$C/bin/polype")" = "$before" ] || fail "a misnamed sum changed bin/polype"

  rm -f "$sums/$name.sha256"
  printf '%s  po-0.0.1-linux-x86_64\n' "$good" > "$sums/po-0.0.1-linux-x86_64.sha256"
  sums "$sums"
  [ "$STATUS" -eq 1 ] && grep -qF "no po-$VERSION-*.sha256" <<< "$OUT" \
    || fail "po-release --sums passed with no sum of version $VERSION ($STATUS): $OUT"
  [ "$(cksum < "$C/bin/polype")" = "$before" ] || fail "a directory with no sum of $VERSION changed bin/polype"
}

test_sums_only_for_a_tag_of_the_target_branch() {
  copy_of_polype
  local sums="$SCRATCH/sums" before name="po-$VERSION-linux-x86_64"
  mkdir -p "$sums"
  printf '%s  %s\n' "$(printf '%064d' 0)" "$name" > "$sums/$name.sha256"
  git -C "$C" init -q -b main && git -C "$C" add bin/polype && git_c commit -qm main \
    && git -C "$C" update-ref refs/remotes/origin/main HEAD || fail "the copy got no origin/main"
  before="$(cksum < "$C/bin/polype")"

  sums "$sums"
  [ "$STATUS" -eq 1 ] && grep -qF "no tag v$VERSION" <<< "$OUT" || fail "--sums passed with no tag v$VERSION ($STATUS): $OUT"
  [ "$(cksum < "$C/bin/polype")" = "$before" ] || fail "--sums with no tag changed bin/polype"

  git_c commit -q --allow-empty -m elsewhere && git -C "$C" tag "v$VERSION" || fail "no tag off main"
  sums "$sums"
  [ "$STATUS" -eq 1 ] && grep -qF "is not a commit of origin/main" <<< "$OUT" \
    || fail "--sums passed for a tag outside origin/main ($STATUS): $OUT"
  [ "$(cksum < "$C/bin/polype")" = "$before" ] || fail "--sums for a tag outside origin/main changed bin/polype"

  git -C "$C" update-ref refs/remotes/origin/main HEAD
  sums "$sums"
  [ "$STATUS" -eq 0 ] && grep -qxF "$(cat "$sums/$name.sha256")" "$C/bin/polype" \
    || fail "--sums did not write the sums of a tag of origin/main ($STATUS): $OUT"
}

test_rerun_refused_once_sums_landed() {
  copy_of_polype
  gh_double
  local sum
  sum="$(printf '%064d' 0)"
  target_branch "$sum  po-0.0.1-linux-x86_64"
  publish "v$VERSION"
  [ "$STATUS" -eq 0 ] || fail "the release of v$VERSION failed with only another version's sums on main: $OUT"
  publish "v$VERSION"
  [ "$STATUS" -eq 0 ] || fail "a rerun of v$VERSION failed before its sums landed: $OUT"

  target_branch "$sum  po-$VERSION-linux-x86_64"
  : > "$SCRATCH/gh.log"
  publish "v$VERSION"
  [ "$STATUS" -ne 0 ] && grep -qF "held the sums of $VERSION" <<< "$OUT" \
    || fail "a rerun of v$VERSION passed although main holds its sums ($STATUS): $OUT"
  [ ! -s "$SCRATCH/gh.log" ] || fail "a refused rerun reached the forge: $(cat "$SCRATCH/gh.log")"
}

test_rerun_refused_after_later_sums_replace_them() {
  copy_of_polype
  gh_double
  local sum
  sum="$(printf '%064d' 0)"
  target_branch "$sum  po-$VERSION-linux-x86_64"
  target_branch "$sum  po-9.9.9-linux-x86_64"
  git -C "$C" show refs/remotes/origin/main:bin/polype | grep -qF "  po-$VERSION-" \
    && fail "the later sums did not replace those of $VERSION on main"
  : > "$SCRATCH/gh.log"
  publish "v$VERSION"
  [ "$STATUS" -ne 0 ] && grep -qF "held the sums of $VERSION" <<< "$OUT" \
    || fail "a rerun of v$VERSION passed once a later version's sums replaced its own on main ($STATUS): $OUT"
  [ ! -s "$SCRATCH/gh.log" ] || fail "a refused rerun reached the forge: $(cat "$SCRATCH/gh.log")"
}

test_release_only_from_a_commit_of_the_target_branch() {
  copy_of_polype
  gh_double
  tagged_commit
  git_c commit -q --allow-empty -m elsewhere || fail "no commit off main"
  publish "v$VERSION"
  [ "$STATUS" -ne 0 ] && grep -qF "HEAD is not a commit of origin/main" <<< "$OUT" \
    || fail "a release of a commit outside origin/main passed ($STATUS): $OUT"
  [ ! -s "$SCRATCH/gh.log" ] || fail "a release of a commit outside origin/main reached the forge: $(cat "$SCRATCH/gh.log")"

  git -C "$C" update-ref refs/remotes/origin/main HEAD
  publish "v$VERSION"
  [ "$STATUS" -eq 0 ] || fail "the release of a commit of origin/main failed ($STATUS): $OUT"
}

test_tag_guard_fails_closed() {
  copy_of_polype
  local polype="$SCRATCH/no-block" shallow="$SCRATCH/shallow"
  main_commit ""
  guard "$C"
  [ "$STATUS" -ne 0 ] && grep -qF "cannot read bin/polype at origin/main" <<< "$OUT" \
    || fail "the guard passed although origin/main holds no bin/polype ($STATUS): $OUT"

  sed "s/^PO_SUMS='\$/PO_SUMS_RENAMED='/" "$C/bin/polype" > "$polype"
  main_commit "$polype"
  guard "$C"
  [ "$STATUS" -ne 0 ] && grep -qF "holds no PO_SUMS block" <<< "$OUT" \
    || fail "the guard passed although bin/polype at origin/main holds no PO_SUMS block ($STATUS): $OUT"

  git -C "$C" update-ref refs/remotes/origin/main HEAD
  guard "$C"
  [ "$STATUS" -eq 0 ] || fail "the guard refused a readable origin/main with no sum ($STATUS): $OUT"
  git clone -q --depth 1 "file://$C" "$shallow" 2>/dev/null || fail "no shallow clone"
  cp -R "$C/bin" "$C/po" "$shallow/"
  guard "$shallow"
  [ "$STATUS" -ne 0 ] && grep -qF "shallow" <<< "$OUT" \
    || fail "the guard passed in a shallow checkout ($STATUS): $OUT"

  local tree
  printf '# another bin/polype\n' >> "$polype"
  main_commit "$polype"
  tree="$(git -C "$C" rev-parse refs/remotes/origin/main^{tree})" || fail "no tree"
  main_commit "$C/bin/polype"
  rm -f "$C/.git/objects/${tree:0:2}/${tree:2}"
  guard "$C"
  [ "$STATUS" -ne 0 ] && grep -qF "cannot read the history of bin/polype" <<< "$OUT" \
    || fail "the guard passed although the history of origin/main cannot be read ($STATUS): $OUT"
}
