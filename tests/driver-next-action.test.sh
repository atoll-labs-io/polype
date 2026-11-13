#!/usr/bin/env bash
# s168 — beside the oracle: what `po next` does with an option, a review with no verdict, a setting
# it cannot read, and its cost on this repository.

# The oracle's fixture and helpers, loaded only inside a test so its own tests are not counted here.
oracle_helpers() { source "$ROOT/tests/driver-next-action.oracle.test.sh"; }

test_next_refuses_an_option() {
  oracle_helpers; project; start
  po_in "$F" next extra
  [ "$STATUS" -eq 2 ] || fail "po next extra exited $STATUS instead of 2: $OUT"
  jq -e '.contract == 1 and .error == "unknown-option"' <<< "$OUT" >/dev/null || fail "po next extra: $OUT"
}

test_review_without_verdict_asks() {
  oracle_helpers; project
  story s01-alpha command -
  start
  recorded_lane s01-alpha
  printf 'Review status: complete\nFix loop: 0\nReviewed tree: %s\n' "$(git -C "$W" rev-parse 'HEAD^{tree}')" \
    > "$W/docs/reviews/s01-alpha.md"
  : > "$SCRATCH/expect"
  expect_lane s01-alpha ask 'review without verdict'
  po_in "$F" next
  next_shape "po next"
  check_expectations
  [ -z "$BAD" ] || fail "$BAD"
}

test_plan_validation_unreadable_asks() {
  oracle_helpers; project
  setting 'Plan validation' -
  story s01-alpha command -
  start
  lane s01-alpha
  research_in s01-alpha
  plan_in s01-alpha no
  : > "$SCRATCH/expect"
  expect_lane s01-alpha ask 'setting unreadable: Plan validation'
  po_in "$F" next
  next_shape "po next"
  check_expectations
  [ -z "$BAD" ] || fail "$BAD"
}

test_max_attempts_unreadable_asks() {
  oracle_helpers; project
  setting 'Max attempts' -
  story s01-alpha command -
  start
  recorded_lane s01-alpha
  review_in s01-alpha complete 0 no
  : > "$SCRATCH/expect"
  expect_lane s01-alpha ask 'setting unreadable: Max attempts'
  po_in "$F" next
  next_shape "po next"
  check_expectations
  [ -z "$BAD" ] || fail "$BAD"
}

test_ready_and_held_null_without_parallel() {
  oracle_helpers; project
  setting Parallel -
  story s01-alpha command -
  story s02-bravo command -
  start
  lane s01-alpha
  po_in "$F" next
  next_shape "po next"
  jq -e '.ready == null and .held == null and .actions == [{"story": "s01-alpha", "action": "plan", "reason": "no research"}]' \
    <<< "$OUT" >/dev/null || fail "without Parallel: $OUT"
  po_in "$F" state
  jq -e '.ready == null and .held == null and .lanes[0].next.action == "plan"' <<< "$OUT" >/dev/null \
    || fail "po state without Parallel: $OUT"
}

test_next_on_this_repository_is_fast_and_writes_nothing() {
  oracle_helpers; need_po
  local marker before start elapsed written target
  marker="$(mktemp)"
  before="$(git -C "$ROOT" status --porcelain --untracked-files=all)"
  start="$(date +%s%N)"
  po_in "$ROOT" next
  elapsed=$(( ($(date +%s%N) - start) / 1000000 ))
  target="$(sed -n 's/^Target branch: *\([^ ]*\).*/\1/p' "$ROOT/AGENTS.local.md" | head -n 1)"
  if git -C "$ROOT" rev-parse --verify -q "$target^{commit}" >/dev/null; then
    next_shape "po next on this repository"
  else
    # A forge's pull_request checkout is a detached merge commit with no local target branch.
    [ "$STATUS" -eq 0 ] || fail "po next exited $STATUS without a readable $target: $OUT"
    jq -e '.contract == 1 and .actions == null and .ready == null and .held == null' <<< "$OUT" >/dev/null \
      || fail "po next without a readable $target: $OUT"
  fi
  [ "$elapsed" -lt 1000 ] || fail "po next took ${elapsed} ms on this repository, not under a second"
  written="$(find "$ROOT" \( -path "$ROOT/po/target" -o -path "$ROOT/.worktrees" -o -name .git \) -prune \
    -o -newer "$marker" -print)"
  rm -f "$marker"
  [ -z "$written" ] || fail "po next wrote: $written"
  [ "$(git -C "$ROOT" status --porcelain --untracked-files=all)" = "$before" ] || fail "po next changed the repository's status"
}

test_fix_loop_counts_against_the_origin_target_branch() {
  oracle_helpers; project
  story s01-alpha command -
  start
  echo landed > "$F/src/landed.txt"; git -C "$F" add -A; git -C "$F" commit -qm 'landed on the forge'
  echo again >> "$F/src/landed.txt"; git -C "$F" commit -qam 'landed on the forge again'
  git -C "$F" update-ref refs/remotes/origin/main main
  git -C "$F" update-ref refs/heads/main main~2
  W="$F/.worktrees/s01-alpha"
  git -C "$F" worktree add -q -b story/s01-alpha "$W" origin/main
  research_in s01-alpha; plan_in s01-alpha yes; code_in s01-alpha; record_in s01-alpha
  review_in s01-alpha complete 0 no
  : > "$SCRATCH/expect"
  expect_lane s01-alpha fix 'Ship allowed: no'
  po_in "$F" next
  next_shape "po next"
  check_expectations
  [ -z "$BAD" ] || fail "origin/main ahead of main: $BAD"
}
