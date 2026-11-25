#!/usr/bin/env bash
# s213 — the oracle of the story: the release tests of s171 and s189 hold when the bin/polype they
# copy already carries, in PO_SUMS, the sums of the version they test, as main does once a
# release's sums have landed; and po-release still refuses to rebuild a version summed on the
# target branch. Nothing reaches a forge: the tests run against a throwaway copy of Polype.

RELEASE_TEST_FILES=(first-release-holds.oracle.test.sh first-release-holds.test.sh po-prebuilt-and-verified.oracle.test.sh)

# The seven tests that failed once the sums of po 0.13.0 landed (PR #520).
FAILED_ON_LANDED_SUMS=(release_reruns_cleanly tag_must_match_the_version
  release_only_from_a_commit_of_the_target_branch rerun_refused_after_later_sums_replace_them
  rerun_refused_once_sums_landed tag_guard_fails_closed installer_falls_back_to_sources)

# set_sums <bin/polype> <version or empty>: replaces the PO_SUMS block of that file, as
# po-release --sums does, with one sum per release platform of <version>, or with nothing.
set_sums() {
  local polype="$1" version="$2" platform lines=""
  [ "$(grep -c "^PO_SUMS='\$" "$polype")" = 1 ] || fail "${polype#"$SCRATCH"/} has no single PO_SUMS=' line"
  if [ -n "$version" ]; then
    for platform in linux-aarch64 linux-x86_64 macos-aarch64; do
      lines+="$(printf '%064d' 0)  po-$version-$platform"$'\n'
    done
  fi
  SUMS="${lines%$'\n'}" awk '
    inside && /^'\''$/ { inside = 0 }
    inside { next }
    { print }
    /^PO_SUMS='\''$/ { if (ENVIRON["SUMS"] != "") print ENVIRON["SUMS"]; inside = 1 }
  ' "$polype" > "$polype.new" && mv "$polype.new" "$polype" || fail "cannot rewrite PO_SUMS"
  bash -n "$polype" || fail "bin/polype no longer parses once PO_SUMS is rewritten"
}

sums_block() { awk "/^PO_SUMS='\$/ {inside=1; next} inside && /^'\$/ {exit} inside {print}" "$1"; }

version_of() { sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$1"; }

test_release_tests_hold_with_landed_sums() {
  scratch_repo
  local copy="$SCRATCH/polype" version file name names out ran="" failed=""
  mkdir -p "$copy/po" "$copy/tests"
  cp -R "$ROOT/bin" "$ROOT/method" "$ROOT/.github" "$copy/"
  cp "$ROOT/po/Cargo.toml" "$ROOT/po/Cargo.lock" "$copy/po/"
  cp -R "$ROOT/po/src" "$copy/po/"
  cp "$ROOT/tests/lib.sh" "$copy/tests/"
  for file in "${RELEASE_TEST_FILES[@]}"; do
    require_file "$ROOT/tests/$file"
    cp "$ROOT/tests/$file" "$copy/tests/"
  done
  version="$(version_of "$copy/bin/polype")"
  [ -n "$version" ] || fail "bin/polype carries no POLYPE_VERSION"
  set_sums "$copy/bin/polype" "$version"
  [ "$(sums_block "$copy/bin/polype" | grep -c "  po-$version-")" = 3 ] \
    || fail "the copy's PO_SUMS does not hold the sums of $version: $(sums_block "$copy/bin/polype")"

  for file in "${RELEASE_TEST_FILES[@]}"; do
    names="$(cd "$copy/tests" && bash -c "source ./lib.sh && source './$file' && declare -F" \
      | awk '$3 ~ /^test_/ {print $3}')" || fail "$file does not load"
    [ -n "$names" ] || fail "$file defines no test"
    for name in $names; do
      ran+="${name#test_}"$'\n'
      out="$(cd "$copy/tests" && bash -c "set -eu; source ./lib.sh; source './$file'; $name" 2>&1)" \
        || failed+="$file ${name#test_}: $out"$'\n'
    done
  done
  for name in "${FAILED_ON_LANDED_SUMS[@]}"; do
    grep -qx "$name" <<< "$ran" || fail "$name no longer runs in the release tests"
  done
  [ -z "$failed" ] || fail "release tests fail once the sums of $version are in PO_SUMS: $failed"
}

test_release_still_refuses_a_summed_version() {
  scratch_repo
  local copy="$SCRATCH/polype" version status out
  mkdir -p "$copy/po"
  cp -R "$ROOT/bin" "$copy/"
  cp "$ROOT/po/Cargo.toml" "$copy/po/"
  version="$(version_of "$copy/bin/polype")"
  [ -n "$version" ] || fail "bin/polype carries no POLYPE_VERSION"
  git -C "$copy" init -q -b main || fail "no repository for the copy"
  commit_main() {
    git -C "$copy" add bin/polype po/Cargo.toml \
      && git -C "$copy" -c user.email=test@example.com -c user.name=test -c commit.gpgsign=false commit -qm "$1" \
      && git -C "$copy" update-ref refs/remotes/origin/main HEAD || fail "origin/main got no commit $1"
  }

  set_sums "$copy/bin/polype" ""
  commit_main unsummed
  status=0; out="$(cd "$copy" && bin/po-release --tag "v$version" origin/main 2>&1)" || status=$?
  [ "$status" -eq 0 ] || fail "po-release refused v$version although origin/main holds no sum of it ($status): $out"

  set_sums "$copy/bin/polype" "$version"
  commit_main summed
  status=0; out="$(cd "$copy" && bin/po-release --tag "v$version" origin/main 2>&1)" || status=$?
  [ "$status" -ne 0 ] && grep -qF "held the sums of $version" <<< "$out" \
    || fail "po-release did not refuse v$version once origin/main holds its sums ($status): $out"
}
