#!/usr/bin/env bash
# s178 — beside the oracle: what `po record review` owns around the text it keeps private — modes,
# the Private folder setting and its refusals, the `~/` expansion, the blocking rule, the inbox refusal.

# The oracle's fixture and helpers, loaded only inside a test so its own tests are not counted here.
secure_helpers() { source "$ROOT/tests/security-findings-stay-private.oracle.test.sh"; secure_fixture; }

# set_private <value>: the Private folder line of the fixture replaced, or removed when the value is empty.
set_private() {
  sed -i '/^Private folder:/d' "$F/AGENTS.local.md"
  [ -z "$1" ] || printf 'Private folder: %s\n' "$1" >> "$F/AGENTS.local.md"
}

record_marked() {
  local a="$SCRATCH/in/answer.txt"
  answer "$a" "${1:-$SECURE_FINDINGS}" "${2:-critical}" no
  rec "$W" "$a" record review "$ID"
}

# Nothing was written: no review, no decision, the witness nowhere outside the answer's folder.
nothing_written() {
  jq -e --arg e "$1" '.error == $e and .written == false' <<< "$OUT" >/dev/null \
    || fail "$2: not refused as $1, written false: $OUT"
  [ ! -e "$W/docs/reviews/$ID.md" ] || fail "$2: the review was written"
  [ "$(decisions)" -eq 0 ] || fail "$2: a decision was posted"
  ! grep -rlF --exclude-dir=in "$WITNESS" "$SCRATCH" >/dev/null \
    || fail "$2: the text was left on disk: $(grep -rlF --exclude-dir=in "$WITNESS" "$SCRATCH")"
}

context_of_review() {
  local id; id="$(sed -nE 's/^Security findings: [0-9]+ — decision (d-[0-9]+)$/\1/p' "$W/docs/reviews/$ID.md")"
  [ -n "$id" ] || fail "the review holds no count line"
  (cd "$W" && "$PO" inbox "$id") | jq -r '.context'
}

test_private_text_is_owner_only() {
  secure_helpers
  record_marked
  [ "$STATUS" -eq 0 ] || fail "po record review exited $STATUS: $OUT"
  local file; file="$(context_of_review)"
  [ -n "$(find "$file" -maxdepth 0 -perm 0600)" ] || fail "the private file is not 0600: $(stat -c %a "$file")"
  [ -n "$(find "$SCRATCH/private" -maxdepth 0 -perm 0700)" ] || fail "the created Private folder is not 0700"
  [ -n "$(find "$(dirname "$file")" -maxdepth 0 -perm 0700)" ] || fail "the created project folder is not 0700"
}

test_missing_private_folder_refuses_before_writing() {
  secure_helpers
  local value
  for value in "" "—"; do
    set_private "$value"
    record_marked
    [ "$STATUS" -eq 2 ] || fail "Private folder '$value' exited $STATUS, not 2: $OUT"
    nothing_written no-private-folder-setting "Private folder '$value'"
    grep -qF 'Private folder' <<< "$OUT" || fail "the refusal does not name the setting: $OUT"
  done
  record_marked "- minor — src/b.sh:2 — style" minor
  [ "$STATUS" -eq 0 ] || fail "an answer with no mark no longer records without the setting: $OUT"
}

test_unusable_private_folder_is_refused() {
  secure_helpers
  local value
  for value in relative/private/ '$HOME/x' "$F/private/" "$F/.git/private/"; do
    set_private "$value"
    record_marked
    [ "$STATUS" -eq 1 ] || fail "Private folder '$value' exited $STATUS, not 1: $OUT"
    nothing_written private-folder-unusable "Private folder '$value'"
  done
}

test_tilde_is_expanded_from_home() {
  secure_helpers
  set_private "~/p/"
  record_marked
  [ "$STATUS" -eq 0 ] || fail "Private folder ~/p/ exited $STATUS: $OUT"
  local file; file="$(context_of_review)"
  case "$file" in "$HOME/p/project/"*) ;; *) fail "the text is not under \$HOME/p/<project name>/: $file" ;; esac
}

test_only_critical_or_major_holds_the_lane() {
  secure_helpers
  record_marked "- minor — [security] — src/a.sh:1 — $WITNESS" minor
  [ "$STATUS" -eq 0 ] || fail "po record review exited $STATUS: $OUT"
  jq -e '.decision' <<< "$OUT" >/dev/null || fail "the reply names no decision: $OUT"
  (cd "$W" && "$PO" inbox "$(jq -r .decision <<< "$OUT")") | jq -e '.blocks == []' >/dev/null \
    || fail "a minor security finding alone holds the lane"
  rm -f "$W/docs/reviews/$ID.md"
  record_marked "- major — [security] — src/a.sh:1 — $WITNESS" major
  [ "$STATUS" -eq 0 ] || fail "po record review exited $STATUS: $OUT"
  (cd "$W" && "$PO" inbox "$(jq -r .decision <<< "$OUT")") | jq -e --arg id "$ID" '.blocks == [$id]' >/dev/null \
    || fail "a major security finding does not hold the lane"
}

test_no_inbox_refuses_before_writing() {
  secure_helpers
  sed -i '/^Decision inbox:/d' "$F/AGENTS.local.md"
  record_marked
  [ "$STATUS" -eq 2 ] || fail "no Decision inbox exited $STATUS, not 2: $OUT"
  nothing_written no-inbox-setting "no Decision inbox"
  [ -z "$(find "$SCRATCH/private" -type f 2>/dev/null)" ] || fail "a file was left under the Private folder"
}

# An answer that findings-shape refuses posts nothing; the corrected one, asked again, posts the only decision.
test_reasked_answer_posts_one_decision() {
  secure_helpers
  local a="$SCRATCH/in/answer.txt" file="$W/docs/reviews/$ID.md"
  answer "$a" "$SECURE_FINDINGS
critical: not a list item" critical no
  rec "$W" "$a" record review "$ID"
  jq -e '.error == "findings-shape" and .written == true' <<< "$OUT" >/dev/null \
    || fail "a malformed answer is not refused as findings-shape, written true: $OUT"
  [ "$(decisions)" -eq 0 ] || fail "an answer refused by findings-shape posted a decision"
  [ -z "$(find "$SCRATCH/private" -type f 2>/dev/null)" ] || fail "an answer refused by findings-shape left a private file"
  ! grep -qF "$WITNESS" "$file" || fail "the refused block holds the text"
  record_marked
  [ "$STATUS" -eq 0 ] || fail "the corrected answer exited $STATUS: $OUT"
  [ "$(decisions)" -eq 1 ] || fail "the inbox holds $(decisions) decisions, not 1"
  [ "$(find "$SCRATCH/private" -type f | grep -c .)" -eq 1 ] || fail "the Private folder holds several files"
  [ "$(grep -c '^Security findings: 2 — decision d-0001$' "$file")" -eq 1 ] || fail "the accepted block does not name d-0001: $(grep '^Security findings' "$file")"
}
