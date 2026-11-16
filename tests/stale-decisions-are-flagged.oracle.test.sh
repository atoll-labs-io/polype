#!/usr/bin/env bash
# s186 — the oracle of the story: a decision may name its origin story (`story`); a pending decision
# whose named stories have all landed carries `"stale": true` when read, never in its file (#331,
# ADR-0127). `contract_says_held_until_consumed` is a text no script reads: judged in review.

# The s165 fixture ($F project with an ignored .polype/inbox/, story s01-one, worktree $W) and its
# helpers (valid, po_in, po_add, refused, files_in), loaded inside a test only so its tests stay its own.
inbox_fixture() {
  # shellcheck source=/dev/null
  source "$ROOT/tests/decision-inbox.oracle.test.sh"
  need_po
  fixture
  INBOX="$F/.polype/inbox"
  mkdir -p "$INBOX"
}

# put <id> <origin story or ""> <blocks as JSON>: a pending decision file; no `story` key when "".
put() {
  valid | jq --arg id "$1" --arg story "$2" --argjson blocks "$3" '
    {id: $id, asked: "2026-11-16T09:00:00+01:00"} + . + {blocks: $blocks, status: "pending", answer: null}
    | if $story == "" then . else . + {story: $story} end' > "$INBOX/$1.json"
}

# land <story id>: the story ships on main, as /po-ship titles its commit.
land() { git -C "$F" commit -q --allow-empty -m "$1: landed"; }

# The ids `po inbox` marks stale, in its order.
marked() {
  po_in "$F" inbox
  [ "$STATUS" -eq 0 ] || fail "po inbox exited $STATUS: $OUT"
  jq -c '[.pending[] | select(has("stale")) | if .stale == true then .id else "bad:\(.id)" end]' <<< "$OUT"
}

# No decision file of the inbox carries the mark.
files_unmarked() {
  local file
  for file in "$INBOX"/d-*.json; do
    ! jq -e 'has("stale")' "$file" >/dev/null || fail "the mark was written into $(basename "$file")"
  done
}

test_decision_names_its_origin_story() {
  inbox_fixture
  po_add "$F" "$(valid | jq '.story = "s01-one"')"
  [ "$STATUS" -eq 0 ] || fail "po inbox add refused an origin story: $OUT"
  jq -e '.story == "s01-one"' <<< "$OUT" >/dev/null || fail "the reply does not name the origin story: $OUT"
  jq -e '.story == "s01-one"' "$INBOX/d-0001.json" >/dev/null || fail "the file does not name the origin story"
  [ "$(jq -S 'del(.contract)' <<< "$OUT")" = "$(jq -S . "$INBOX/d-0001.json")" ] \
    || fail "the file differs from the object po returned: $(cat "$INBOX/d-0001.json")"

  local bad
  for bad in 's01' 's01-' 'S01-one' 's01-One' 'story s01-one' '../s01-one' 'stories' ''; do
    po_add "$F" "$(valid | jq --arg s "$bad" '.story = $s')"
    refused malformed-decision 1 "origin story \"$bad\""
  done
  [ "$(files_in "$INBOX")" = 1 ] || fail "a refused origin story left a file: $(ls -A "$INBOX")"

  put d-0009 "" '["s01-one"]'
  po_in "$F" inbox d-0009
  [ "$STATUS" -eq 0 ] || fail "po inbox d-0009 exited $STATUS: $OUT"
  [ "$(jq -S 'del(.contract)' <<< "$OUT")" = "$(jq -S . "$INBOX/d-0009.json")" ] \
    || fail "a decision without an origin story does not read as its file: $OUT"

  (
    # shellcheck source=/dev/null
    source "$ROOT/tests/security-findings-stay-private.oracle.test.sh"
    secure_fixture
    a="$SCRATCH/in/answer.txt"
    answer "$a" "- minor — [security] — src/a.sh:1 — $WITNESS" minor no
    rec "$W" "$a" record review "$ID"
    [ "$STATUS" -eq 0 ] || fail "po record review exited $STATUS: $OUT"
    d="$(jq -r '.decision' <<< "$OUT")"
    (cd "$W" && "$PO" inbox "$d") | jq -e --arg id "$ID" '.story == $id and .blocks == []' >/dev/null \
      || fail "the decision po record review posted does not name $ID as its origin story"
  )
}

test_stale_decision_is_flagged() {
  inbox_fixture
  put d-0001 s01-one '[]'
  put d-0002 "" '["s01-one", "s02-two"]'
  put d-0003 s01-one '["s01-one"]'
  put d-0004 s02-two '[]'
  local got
  got="$(marked)"; [ "$got" = '[]' ] || fail "marked while none of their stories landed: $got"

  land s01-one
  got="$(marked)"; [ "$got" = '["d-0001","d-0003"]' ] || fail "po inbox does not mark exactly d-0001 and d-0003: $got"
  po_in "$F" inbox d-0001
  jq -e '.stale == true' <<< "$OUT" >/dev/null || fail "po inbox d-0001 does not carry the mark: $OUT"
  po_in "$F" inbox d-0002
  jq -e 'has("stale") | not' <<< "$OUT" >/dev/null || fail "d-0002 is marked while s02-two has not landed: $OUT"
  po_in "$F" state
  [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS: $OUT"
  jq -e '.waiting == ["d-0001", "d-0002", "d-0003", "d-0004"] and .stale == ["d-0001", "d-0003"]' <<< "$OUT" >/dev/null \
    || fail "po state does not keep waiting as ids and list the stale ones apart: $(jq -c '{waiting, stale}' <<< "$OUT")"
  files_unmarked

  land s02-two
  got="$(marked)"; [ "$got" = '["d-0001","d-0002","d-0003","d-0004"]' ] || fail "once every named story landed, marked: $got"
  po_in "$F" state
  jq -e '.stale == ["d-0001", "d-0002", "d-0003", "d-0004"]' <<< "$OUT" >/dev/null || fail "po state: $(jq -c .stale <<< "$OUT")"
  files_unmarked
}

test_framing_blocks_are_never_stale() {
  inbox_fixture
  put d-0001 "" '[]'
  put d-0002 s01-one '["architecture"]'
  put d-0003 "" '["s01-one", "stories"]'
  put d-0004 s01-one '["M22 framing"]'
  land s01-one
  local got
  got="$(marked)"; [ "$got" = '[]' ] || fail "a decision naming no story, or a framing stage, is marked: $got"
  po_in "$F" state
  jq -e '.stale == [] and (.waiting | length) == 4' <<< "$OUT" >/dev/null || fail "po state: $(jq -c '{waiting, stale}' <<< "$OUT")"
}

test_answer_on_a_stale_decision_says_so() {
  inbox_fixture
  put d-0001 s01-one '[]'
  put d-0002 "" '["s02-two"]'
  land s01-one

  po_in "$F" answer d-0001 a
  [ "$STATUS" -eq 0 ] || fail "po answer refused a stale decision: $OUT"
  jq -e '.status == "answered" and .answer.key == "a" and .stale == true' <<< "$OUT" >/dev/null \
    || fail "po answer on a stale decision does not record it with the mark: $OUT"
  jq -e '.status == "answered" and .answer.key == "a"' "$INBOX/d-0001.json" >/dev/null || fail "the answer was not written"
  files_unmarked
  po_in "$F" inbox d-0001
  jq -e '.status == "answered" and (has("stale") | not)' <<< "$OUT" >/dev/null || fail "po inbox shows the mark on an answered decision: $OUT"
  po_in "$F" inbox --answered
  jq -e '.answered | map(.id) == ["d-0001"] and all(.[]; has("stale") | not)' <<< "$OUT" >/dev/null \
    || fail "po inbox --answered shows the mark: $OUT"

  po_in "$F" answer d-0002 b
  [ "$STATUS" -eq 0 ] || fail "po answer d-0002 exited $STATUS: $OUT"
  jq -e 'has("stale") | not' <<< "$OUT" >/dev/null || fail "po answer marks a decision that is not stale: $OUT"
  [ "$(jq -S 'del(.contract)' <<< "$OUT")" = "$(jq -S . "$INBOX/d-0002.json")" ] \
    || fail "po answer on a decision that is not stale no longer returns its file: $OUT"
}

test_version_goes_up() {
  local toml lock polype
  toml="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$ROOT/po/Cargo.toml" | head -n 1)"
  lock="$(awk '$0 == "name = \"po\"" {getline; print; exit}' "$ROOT/po/Cargo.lock" | sed -n 's/^version = "\(.*\)"$/\1/p')"
  polype="$(sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$ROOT/bin/polype")"
  [ -n "$toml" ] && [ "$toml" = "$lock" ] && [ "$toml" = "$polype" ] \
    || fail "po's version differs: po/Cargo.toml $toml, po/Cargo.lock $lock, bin/polype $polype"
  [ "$(printf '0.6.0\n%s\n' "$toml" | sort -V | head -n 1)" = 0.6.0 ] \
    || fail "po's version $toml is not a minor step above 0.5.0"
}
