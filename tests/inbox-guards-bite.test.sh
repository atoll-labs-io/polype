#!/usr/bin/env bash
# s187 — task tests: an inbox in a worktree outside the root is refused; a decision whose `blocks`
# holds an entry of the short story form and that names no story is never marked stale.

test_inbox_in_an_outside_worktree_is_refused() {
  # shellcheck source=/dev/null
  source "$ROOT/tests/inbox-guards-bite.oracle.test.sh"
  need_po
  guards_fixture
  git -C "$F" worktree add -q -b side "$SCRATCH/side" main
  mkdir -p "$SCRATCH/side/inbox"
  set_setting "Decision inbox" "$SCRATCH/side/inbox/"
  post false "docs/x.md"
  refused inbox-not-ignored 1 "po inbox add into an inbox in the worktree at $SCRATCH/side"
  [ "$(decisions_in "$SCRATCH/side/inbox")" -eq 0 ] || fail "a decision was written into the worktree"
}

test_blocks_entry_not_of_story_form_is_never_stale() {
  # shellcheck source=/dev/null
  source "$ROOT/tests/decision-inbox.oracle.test.sh"
  need_po; fixture
  mkdir -p "$F/.polype/inbox"
  valid | jq '{id: "d-0001", asked: "2026-11-16T09:00:00+01:00"} + . + {blocks: ["s01"], status: "pending", answer: null}' \
    > "$F/.polype/inbox/d-0001.json"
  git -C "$F" commit -q --allow-empty -m "s01: landed"

  po_in "$F" inbox
  [ "$STATUS" -eq 0 ] || fail "po inbox exited $STATUS: $OUT"
  jq -e '.pending | map(.id) == ["d-0001"] and all(.[]; has("stale") | not)' <<< "$OUT" >/dev/null \
    || fail "po inbox marks a decision with no story: $OUT"
  po_in "$F" state
  [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS: $OUT"
  jq -e '.stale == []' <<< "$OUT" >/dev/null || fail "po state lists a stale decision: $(jq -c '{waiting, stale}' <<< "$OUT")"
}
