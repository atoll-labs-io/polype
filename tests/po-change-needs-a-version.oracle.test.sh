#!/usr/bin/env bash
# s182 — the oracle of the story: a diff that touches po/ carries a new version, written the same in its
# three places, and the check compares against a base it receives as a git ref (ADR-0122, ADR-0125).

WORKFLOW="$ROOT/.github/workflows/ci.yml"

# A throwaway repository holding the version check and po at version $1, committed on main.
# Its Target branch is trunk, so a check that hardcodes main is caught.
versioned_repo() {
  scratch_repo
  S="$(cd "$SCRATCH" && pwd -P)"
  mkdir -p "$S/bin" "$S/po/src"
  cp -p "$ROOT/bin/po-version-check" "$S/bin/po-version-check"
  printf '```\nTarget branch:     trunk\n```\n' > "$S/AGENTS.local.md"
  printf 'fn main() {}\n' > "$S/po/src/main.rs"
  printf 'readme\n' > "$S/README.md"
  set_version "$1" "$1" "$1"
  commit base
}

# Writes po's version into po/Cargo.toml, po/Cargo.lock and bin/polype, in that order. The lock file
# carries a lock format version and another crate's version, as a real one does.
set_version() {
  printf '[package]\nname = "po"\nversion = "%s"\nedition = "2021"\n\n[dependencies]\nserde = "1"\n' "$1" \
    > "$S/po/Cargo.toml"
  printf '# lock\nversion = 4\n\n[[package]]\nname = "itoa"\nversion = "9.9.9"\n\n[[package]]\nname = "po"\nversion = "%s"\n' \
    "$2" > "$S/po/Cargo.lock"
  printf '#!/usr/bin/env bash\nPOLYPE_VERSION="%s"\n' "$3" > "$S/bin/polype"
}

commit() { git -C "$S" add -A && git -C "$S" commit -qm "$1"; }

# A branch named $1 forked from main.
case_branch() { git -C "$S" checkout -q -B "$1" main; }

# Runs the check of the scratch repository with the arguments given; sets ST and OUT.
check() { ST=0; OUT="$(cd "$S" && "$S/bin/po-version-check" "$@" 2>&1)" || ST=$?; }

test_po_diff_without_bump_is_refused() {
  require_file "$ROOT/bin/po-version-check"
  [ -x "$ROOT/bin/po-version-check" ] || fail "bin/po-version-check is not executable"
  versioned_repo 1.2.3
  case_branch story
  printf 'fn main() { println!("changed"); }\n' > "$S/po/src/main.rs"
  commit change
  check main
  [ "$ST" -ne 0 ] || fail "a change to po/src without a new version passed: $OUT"
  local w
  for w in 1.2.3 po/Cargo.toml po/Cargo.lock bin/polype; do
    grep -qF -- "$w" <<< "$OUT" || fail "the refusal does not name $w: $OUT"
  done
  set_version 1.2.10 1.2.10 1.2.10
  commit bump
  check main
  [ "$ST" -eq 0 ] || fail "the same change with po at 1.2.10 in its three places was refused (exit $ST): $OUT"
}

test_bump_moves_the_three_places() {
  versioned_repo 1.2.3
  local c i=0
  for c in '1.2.4 1.2.3 1.2.3' '1.2.3 1.2.4 1.2.3' '1.2.3 1.2.3 1.2.4' '1.2.4 1.2.4 1.2.3' \
           '1.2.4 1.2.3 1.2.4' '1.2.3 1.2.4 1.2.4' '1.2.2 1.2.2 1.2.2' '1.1.9 1.1.9 1.1.9'; do
    i=$((i + 1))
    case_branch "case$i"
    # shellcheck disable=SC2086
    set_version $c
    commit "versions $c"
    check main
    [ "$ST" -ne 0 ] || fail "Cargo.toml, Cargo.lock, bin/polype at $c (base 1.2.3) passed: $OUT"
  done
  case_branch good
  set_version 2.0.0 2.0.0 2.0.0
  commit "versions 2.0.0"
  check main
  [ "$ST" -eq 0 ] || fail "po at 2.0.0 in its three places was refused (exit $ST): $OUT"
}

test_other_diffs_pass() {
  versioned_repo 1.2.3
  case_branch docs
  printf 'more\n' >> "$S/README.md"
  commit docs
  check main
  [ "$ST" -eq 0 ] || fail "a diff outside po/ was refused (exit $ST): $OUT"
  case_branch bump
  set_version 1.2.4 1.2.4 1.2.4
  commit bump
  check main
  [ "$ST" -eq 0 ] || fail "a bump with no other change was refused (exit $ST): $OUT"
  # The story's diff is base...HEAD: a po change landed on the base after the fork is not the story's.
  case_branch late
  printf 'late\n' >> "$S/README.md"
  commit late
  git -C "$S" checkout -q main
  printf 'fn main() { println!("landed"); }\n' > "$S/po/src/main.rs"
  set_version 1.2.4 1.2.4 1.2.4
  commit landed
  git -C "$S" checkout -q late
  check main
  [ "$ST" -eq 0 ] || fail "a docs-only branch was refused for a po change made on its base after the fork (exit $ST): $OUT"
}

test_missing_base_fails() {
  versioned_repo 1.2.3
  case_branch story
  printf 'more\n' >> "$S/README.md"
  commit docs
  check nowhere/branch
  [ "$ST" -ne 0 ] || fail "an absent base ref passed: $OUT"
  grep -qF 'nowhere/branch' <<< "$OUT" || fail "the failure does not name the absent ref: $OUT"
  check
  [ "$ST" -ne 0 ] || fail "with no argument and no origin/trunk, the check passed: $OUT"
  grep -qF 'origin/trunk' <<< "$OUT" || fail "with no argument, the failure does not name origin/<Target branch>: $OUT"
  git -C "$S" update-ref refs/remotes/origin/trunk main
  check
  [ "$ST" -eq 0 ] || fail "with origin/trunk present and a docs-only diff, the check failed (exit $ST): $OUT"
  printf 'fn main() { println!("changed"); }\n' > "$S/po/src/main.rs"
  commit change
  check
  [ "$ST" -ne 0 ] || fail "with no argument, a po change without a new version passed against origin/trunk: $OUT"
}

test_workflow_brings_the_base() {
  require_file "$WORKFLOW"
  local steps block repo target
  steps="$(grep -cE '^[[:space:]]*(- )?uses:[[:space:]]*actions/checkout@' "$WORKFLOW")"
  [ "$steps" -eq 1 ] || fail "the workflow has $steps checkout steps, one expected"
  # The checkout step: its uses: line and every line indented deeper than its dash.
  block="$(awk '
    on { match($0, /^ */); if (NF && RLENGTH <= base) exit; print; next }
    /^[[:space:]]*- uses:[[:space:]]*actions\/checkout@/ { on = 1; match($0, /^ */); base = RLENGTH; print }
  ' "$WORKFLOW")"
  grep -qE '^[[:space:]]*fetch-depth:[[:space:]]*0[[:space:]]*$' <<< "$block" \
    || fail "the checkout does not fetch the whole history, so the base branch is not there: $block"
  ! grep -qE '^[[:space:]]*ref:' <<< "$block" \
    || fail "the checkout sets ref:, so a pull request is not checked out as its merge with the base: $block"
  repo="$(sed -n 's/^[[:space:]]*repository:[[:space:]]*//p' <<< "$block" | sed 's/[[:space:]]*$//')"
  [ -z "$repo" ] || [ "$repo" = '${{ github.repository }}' ] \
    || fail "the checkout reads repository $repo, not the base repository"
  ! grep -qE 'head_ref|head\.repo|pull_request_target' "$WORKFLOW" \
    || fail "the workflow still reads the pull request's head repository or ref"
  # Where the suite runs, the ref the check takes by default is there.
  target="$(sed -n "s/^Target branch:[[:space:]]*\(.*[^[:space:]]\)[[:space:]]*\$/\1/p" "$ROOT/AGENTS.local.md" | head -n 1)"
  [ -n "$target" ] || fail "AGENTS.local.md has no Target branch"
  git -C "$ROOT" rev-parse --verify -q "origin/$target^{commit}" >/dev/null \
    || fail "origin/$target is not in this checkout, so the check has no base"
}

test_ci_still_has_one_entry() {
  # The rule of ADR-0105 lives in s159's oracle; this criterion holds it, not a copy of it.
  # shellcheck source=/dev/null
  source "$ROOT/tests/ci-on-every-pr.oracle.test.sh"
  test_workflow_only_calls_the_entry
}
