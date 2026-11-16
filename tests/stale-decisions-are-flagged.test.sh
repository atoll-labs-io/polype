#!/usr/bin/env bash
# s186 — task tests: a review recorded for an id not of story form still posts its decision, with no
# origin story; without `Target branch`, no decision is marked and nothing is refused.

test_review_of_an_id_not_of_story_form_posts_without_origin() {
  # shellcheck source=/dev/null
  source "$ROOT/tests/security-findings-stay-private.oracle.test.sh"
  # shellcheck source=/dev/null
  source "$ROOT/tests/record-writes-reports.oracle.test.sh"
  ID=fix-a
  need_po; fixture
  export HOME="$SCRATCH/home"
  mkdir -p "$HOME" "$SCRATCH/in"
  printf 'Decision inbox: .polype/inbox/\nPrivate folder: %s/private/\n' "$SCRATCH" >> "$F/AGENTS.local.md"
  printf '.polype/inbox/\n' >> "$F/.gitignore"
  git -C "$F" add -A && git -C "$F" commit -q -m inbox

  local a="$SCRATCH/in/answer.txt" d
  answer "$a" "- minor — [security] — src/a.sh:1 — $WITNESS" minor no
  rec "$W" "$a" record review "$ID"
  [ "$STATUS" -eq 0 ] || fail "po record review of $ID exited $STATUS: $OUT"
  d="$(jq -r '.decision' <<< "$OUT")"
  (cd "$W" && "$PO" inbox "$d") | jq -e 'has("story") | not' >/dev/null \
    || fail "the decision posted for $ID names an origin story"
}

test_no_target_branch_marks_nothing() {
  # shellcheck source=/dev/null
  source "$ROOT/tests/decision-inbox.oracle.test.sh"
  need_po; fixture
  mkdir -p "$F/.polype/inbox"
  valid | jq '{id: "d-0001", asked: "2026-11-16T09:00:00+01:00"} + . + {story: "s01-one", blocks: [], status: "pending", answer: null}' \
    > "$F/.polype/inbox/d-0001.json"
  git -C "$F" commit -q --allow-empty -m "s01-one: landed"
  sed -i '/^Target branch:/d' "$F/AGENTS.local.md"

  po_in "$F" inbox
  [ "$STATUS" -eq 0 ] || fail "po inbox without Target branch exited $STATUS: $OUT"
  jq -e '.pending | map(.id) == ["d-0001"] and all(.[]; has("stale") | not)' <<< "$OUT" >/dev/null \
    || fail "po inbox without Target branch does not list the decision unmarked: $OUT"
  po_in "$F" state
  [ "$STATUS" -eq 0 ] || fail "po state without Target branch exited $STATUS: $OUT"
  jq -e '.waiting == ["d-0001"] and .stale == null' <<< "$OUT" >/dev/null \
    || fail "po state without Target branch: $(jq -c '{waiting, stale}' <<< "$OUT")"
}
