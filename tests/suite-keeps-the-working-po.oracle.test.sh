#!/usr/bin/env bash
# s181 — the suite keeps the po built from the working tree, and the quickstart test runs from any
# checkout. Each test runs the suite of a throwaway copy of this tree, never this tree's own target.

# C: a repository holding this working tree's files, committed once on main.
tree_copy() {
  scratch_repo
  C="$SCRATCH/tree"
  mkdir -p "$C" "$SCRATCH/home"
  (cd "$ROOT" && git ls-files -z -co --exclude-standard \
    | while IFS= read -r -d '' f; do [ -e "$f" ] && printf '%s\0' "$f"; done \
    | tar --null -T - -cf -) | tar -xf - -C "$C" || fail "could not copy the working tree"
  git -C "$C" init -q -b main
  git -C "$C" add -A
  copy_commit -m 'the copy' || fail "could not commit the copy"
  # The copy's run builds here, never into po/target of the tree under test.
  export HOME="$SCRATCH/home" CARGO_TARGET_DIR="$SCRATCH/target"
}

copy_commit() { git -C "$C" -c user.email=test@example.com -c user.name=test -c commit.gpgsign=false commit -q "$@"; }

# The copy's own runner on the given test files; prints its output and never fails itself.
copy_suite() { (cd "$C" && bash tests/run.sh "$@" 2>&1) || true; }

test_working_po_survives_the_suite() {
  tree_copy
  # po/ of the copy now differs from its HEAD: this po answers one fixed word.
  printf 'fn main() {\n    println!("s181-working-tree-po");\n}\n' > "$C/po/src/main.rs"
  cat > "$C/tests/zz-s181-probe.test.sh" <<'EOF'
test_probe_gets_the_working_po() {
  local out
  out="$("$PO" 2>&1)" || true
  [ "$out" = s181-working-tree-po ] || fail "PO answered: $out"
}
EOF
  local out
  out="$(copy_suite readme-onboarding.test.sh zz-s181-probe.test.sh)"
  grep -qF 'ok    quickstart_runs_as_written' <<< "$out" || fail "the quickstart did not pass in the copy: $out"
  grep -qF 'ok    probe_gets_the_working_po' <<< "$out" \
    || fail "a test run after the quickstart did not get the working tree's po: $out"
}

test_quickstart_runs_from_a_detached_head() {
  tree_copy
  git -C "$C" checkout -q --detach
  copy_commit --allow-empty -m 'a commit no branch holds' || fail "could not commit on the detached HEAD"
  [ -z "$(git -C "$C" for-each-ref --contains HEAD refs/heads)" ] || fail "a branch still holds HEAD"
  local out
  out="$(copy_suite readme-onboarding.test.sh)"
  grep -qF 'ok    quickstart_runs_as_written' <<< "$out" || fail "the quickstart failed from a detached HEAD: $out"
}

test_quickstart_still_runs_as_written() {
  tree_copy
  # A line the README's update block gains must run, and its failure must fail the quickstart.
  awk '{print} $0 == "git -C ~/src/polype pull" {print "echo s181-readme-line-ran"; print "exit 7"}' \
    "$C/README.md" > "$SCRATCH/README.md" && mv "$SCRATCH/README.md" "$C/README.md"
  grep -qx 'echo s181-readme-line-ran' "$C/README.md" || fail "the README has no line 'git -C ~/src/polype pull'"
  local out
  out="$(copy_suite readme-onboarding.test.sh)"
  grep -qF 'FAIL  quickstart_runs_as_written' <<< "$out" || fail "the quickstart passed without running the README's line: $out"
  grep -qF 's181-readme-line-ran' <<< "$out" || fail "the README's added line did not run: $out"
}
