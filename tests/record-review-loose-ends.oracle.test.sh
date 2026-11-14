#!/usr/bin/env bash
# s180 — the oracle of the story: `po record review` closes the three findings the review of s178
# left open (the first one is the finding of decision d-0022, kept off the repository by ADR-0123),
# and po's version goes up with it (ADR-0122).

# The s178 fixture and helpers ($F, $W, $SCRATCH, rec, answer, decisions, WITNESS, SECURE_FINDINGS),
# loaded only inside a test so the s178 tests are not counted here.
loose_fixture() { source "$ROOT/tests/security-findings-stay-private.oracle.test.sh"; secure_fixture; }

# rolled_back <error> <what> [copy]: refused as <error>, written false, the review as it was before
# (absent without a copy, byte-identical to the copy with one), no decision, the witness nowhere.
rolled_back() {
  local file="$W/docs/reviews/$ID.md"
  jq -e --arg e "$1" '.error == $e and .written == false' <<< "$OUT" >/dev/null \
    || fail "$2: not refused as $1, written false: $OUT"
  if [ -n "${3:-}" ]; then
    cmp -s "$3" "$file" || fail "$2: the review is not byte-identical to what it was before"
  else
    [ ! -e "$file" ] || fail "$2: a review that did not exist is left on disk"
  fi
  [ "$(decisions)" -eq 0 ] || fail "$2: a decision was posted"
  ! grep -rlF --exclude-dir=in "$WITNESS" "$SCRATCH" >/dev/null \
    || fail "$2: the text was left on disk: $(grep -rlF --exclude-dir=in "$WITNESS" "$SCRATCH")"
}

test_security_finding_of_d_0022_is_closed() {
  loose_fixture
  local a="$SCRATCH/in/answer.txt"
  mkdir -p "$SCRATCH/private" "$F/elsewhere"
  ln -s "$F/elsewhere" "$SCRATCH/private/project"
  answer "$a" "$SECURE_FINDINGS" critical no
  rec "$W" "$a" record review "$ID"
  [ "$STATUS" -eq 1 ] || fail "po record review exited $STATUS, not 1: $OUT"
  rolled_back private-folder-unusable "the d-0022 fixture"
  [ -z "$(find "$F/elsewhere" -mindepth 1)" ] || fail "something was written under $F/elsewhere"
}

test_failed_keep_rolls_the_review_back() {
  loose_fixture
  local a="$SCRATCH/in/answer.txt" before="$SCRATCH/in/before.md" blocked="$SCRATCH/private/project"
  # The project folder at mode 0500 makes the private write fail; root writes through any mode, so
  # under root a plain file stands where that folder goes, which no user can create a folder over.
  mkdir -p "$SCRATCH/private"
  if [ "$(id -u)" -eq 0 ]; then : > "$blocked"; else mkdir -m 0500 "$blocked"; fi

  answer "$a" "$SECURE_FINDINGS" critical no
  rec "$W" "$a" record review "$ID"
  [ "$STATUS" -eq 1 ] || fail "a failed keep on a new review exited $STATUS, not 1: $OUT"
  rolled_back private-folder-unusable "a failed keep on a new review"

  answer "$a" "- minor — src/b.sh:2 — style" minor yes
  rec "$W" "$a" record review "$ID"
  [ "$STATUS" -eq 0 ] || fail "an answer with no mark exited $STATUS: $OUT"
  cp "$W/docs/reviews/$ID.md" "$before"
  answer "$a" "$SECURE_FINDINGS" critical no 1
  rec "$W" "$a" record review "$ID"
  [ "$STATUS" -eq 1 ] || fail "a failed keep on an existing review exited $STATUS, not 1: $OUT"
  rolled_back private-folder-unusable "a failed keep on an existing review" "$before"
}

test_reply_is_true_when_the_last_write_fails() {
  loose_fixture
  local a="$SCRATCH/in/answer.txt" file="$W/docs/reviews/$ID.md" hook="$W/.polype/hooks/po-gate.sh" id
  cp "$hook" "$SCRATCH/in/po-gate.sh"
  # findings-shape runs after the first write and before the decision is posted. It puts a folder
  # where the next write's temp file goes (`.<name>.po-record.<po's pid>`, po being this script's
  # parent), so the rewrite of the count line fails for any user while the review can still be removed.
  cat > "$hook" <<EOF
#!/usr/bin/env bash
[ "\$1" != findings-shape ] || mkdir "docs/reviews/.\$2.md.po-record.\$PPID"
exec bash "$SCRATCH/in/po-gate.sh" "\$@"
EOF
  answer "$a" "$SECURE_FINDINGS" critical no
  rec "$W" "$a" record review "$ID"
  [ "$STATUS" -ne 0 ] || fail "a failed rewrite of the count line still exited 0: $OUT"
  jq -e '.error == "unwritable"' <<< "$OUT" >/dev/null || fail "the failure is not refused as unwritable: $OUT"
  if [ -e "$file" ]; then
    jq -e '.written == true' <<< "$OUT" >/dev/null || fail "the review is on disk but the reply says written false: $OUT"
    ! grep -qF 'none kept' "$file" || fail "the review keeps the provisional count line"
  else
    jq -e '.written == false' <<< "$OUT" >/dev/null || fail "no review is on disk but the reply says written true: $OUT"
  fi
  [ "$(decisions)" -eq 1 ] || fail "the inbox holds $(decisions) decisions, not the one already posted"
  id="$(basename "$(find "$F/.polype/inbox" -name 'd-*.json')" .json)"
  jq -e --arg id "$id" '.message | contains($id)' <<< "$OUT" >/dev/null || fail "the message does not name $id: $OUT"
  (cd "$W" && "$PO" inbox "$id") | jq -e '.status == "pending"' >/dev/null || fail "decision $id is not pending"
}

# The three places that carry po's version agree, and it is above the 0.3.0 that s178 shipped.
test_version_goes_up() {
  local toml lock script
  toml="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$ROOT/po/Cargo.toml" | head -n 1)"
  lock="$(awk '$0 == "name = \"po\"" {getline; print; exit}' "$ROOT/po/Cargo.lock" | sed -n 's/^version = "\(.*\)"$/\1/p')"
  script="$(sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$ROOT/bin/polype" | head -n 1)"
  [ -n "$toml" ] && [ "$toml" = "$lock" ] && [ "$toml" = "$script" ] \
    || fail "po/Cargo.toml says '$toml', po/Cargo.lock '$lock', bin/polype '$script'"
  [ "$toml" != 0.3.0 ] && [ "$(printf '0.3.0\n%s\n' "$toml" | sort -V | head -n 1)" = 0.3.0 ] \
    || fail "po's version $toml is not above 0.3.0"
}
