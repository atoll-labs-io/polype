#!/usr/bin/env bash
# s180 — the story's own tests, beside its oracle: where the private text of `po record review`
# may land, for the cases the oracle does not reach.

# The oracle's fixture and helpers (loose_fixture, rolled_back), loaded only inside a test so its
# tests are not counted here.
own_fixture() { source "$ROOT/tests/record-review-loose-ends.oracle.test.sh"; loose_fixture; }

test_folder_that_appears_after_prepare_is_refused() {
  own_fixture
  local a="$SCRATCH/in/answer.txt" hook="$W/.polype/hooks/po-gate.sh"
  mkdir -p "$F/elsewhere"
  cp "$hook" "$SCRATCH/in/po-gate.sh"
  # findings-shape runs after po has checked the folder and before it writes the text.
  cat > "$hook" <<EOF
#!/usr/bin/env bash
if [ "\$1" = findings-shape ]; then mkdir -p "$SCRATCH/private" && ln -s "$F/elsewhere" "$SCRATCH/private/project"; fi
exec bash "$SCRATCH/in/po-gate.sh" "\$@"
EOF
  answer "$a" "$SECURE_FINDINGS" critical no
  rec "$W" "$a" record review "$ID"
  [ "$STATUS" -eq 1 ] || fail "po record review exited $STATUS, not 1: $OUT"
  rolled_back private-folder-unusable "a folder that appears after the first check"
  [ -z "$(find "$F/elsewhere" -mindepth 1)" ] || fail "something was written under $F/elsewhere"
}

test_private_folder_value_resolves_as_written() {
  own_fixture
  local a="$SCRATCH/in/answer.txt"
  mkdir -p "$F/sub/deep"
  ln -s "$F/sub/deep" "$SCRATCH/lnk"
  sed -i "s|^Private folder: .*|Private folder: $SCRATCH/lnk/../private/|" "$F/AGENTS.local.md"
  git -C "$F" commit -qam "private folder"
  answer "$a" "$SECURE_FINDINGS" critical no
  rec "$W" "$a" record review "$ID"
  [ "$STATUS" -eq 1 ] || fail "po record review exited $STATUS, not 1: $OUT"
  rolled_back private-folder-unusable "the Private folder value"
  [ -z "$(find "$F/sub" -mindepth 1 ! -path "$F/sub/deep")" ] || fail "something was written under $F/sub"
}

# The shared layout of the tests below: an existing folder outside ($SCRATCH/far) holding a link to
# a folder of the repository (into) and one to its root (top), a link outside ($SCRATCH/away) and
# another worktree placed outside the root ($SCRATCH/side).
unverified_layout() {
  own_fixture
  mkdir -p "$F/sub/deep" "$SCRATCH/far"
  ln -s "$F/sub/deep" "$SCRATCH/far/into"
  ln -s "$F" "$SCRATCH/far/top"
  ln -s "$SCRATCH/far" "$SCRATCH/away"
  git -C "$F" worktree add -q -b side "$SCRATCH/side" main
}

# ask <sensitive> <context>: `po inbox add` from the project root; sets OUT and STATUS.
ask() {
  local json
  json="$(jq -n --argjson s "$1" --arg c "$2" --arg q "$WITNESS asked" '{
    motive: "security", sensitive: $s, question: $q, context: $c,
    options: [{key: "a", label: "one", consequence: "x"}, {key: "b", label: "two", consequence: "y"}],
    recommended: "a", why: "w", reversible: true, blocks: []}')"
  STATUS=0; OUT="$(cd "$F" && printf '%s' "$json" | "$PO" inbox add 2>/dev/null)" || STATUS=$?
}

nothing_under_sub() {
  [ -z "$(find "$F/sub" -mindepth 1 ! -path "$F/sub/deep")" ] || fail "$1: something was written under $F/sub"
}

test_a_path_that_cannot_be_verified_is_refused() {
  unverified_layout
  local s="$SCRATCH" context
  for context in "$s/far/gone/../into/x.md" "$s/far/gone/../top/x.md" "$s/far/gone/../../side/x.md" \
    "$s/far/gone/../../project/x.md" "$s/far/gone/../new/x.md" "$s/far/into/../x.md" "$s/far/into/gone/.."; do
    ask true "$context"
    [ "$STATUS" -eq 1 ] && jq -e '.error == "sensitive-context-in-repo"' <<< "$OUT" >/dev/null \
      || fail "the context $context was not refused: $STATUS $OUT"
  done
  [ "$(decisions)" -eq 0 ] || fail "a refused decision was written"
  for context in "$s/far/new/x.md" "$s/far/../new/x.md" "$s/away/x.md"; do
    ask true "$context"
    [ "$STATUS" -eq 0 ] || fail "the context $context, outside, was refused: $STATUS $OUT"
  done
  nothing_under_sub "a sensitive context"
}

test_an_inbox_that_cannot_be_verified_is_refused() {
  unverified_layout
  sed -i "s|^Decision inbox:.*|Decision inbox: $SCRATCH/far/gone/../into/inbox/|" "$F/AGENTS.local.md"
  ask false "docs/x.md"
  [ "$STATUS" -eq 1 ] && jq -e '.error == "inbox-not-ignored"' <<< "$OUT" >/dev/null \
    || fail "an inbox that cannot be verified was not refused: $STATUS $OUT"
  nothing_under_sub "the Decision inbox value"
  ! grep -rlF "$WITNESS" "$F" >/dev/null || fail "the decision landed in the repository"
  sed -i "s|^Decision inbox:.*|Decision inbox: $SCRATCH/far/../box/|" "$F/AGENTS.local.md"
  ask false "docs/x.md"
  [ "$STATUS" -eq 0 ] && [ -n "$(find "$SCRATCH/box" -name 'd-*.json')" ] \
    || fail "an inbox outside the repository was refused: $STATUS $OUT"
}

test_a_private_folder_that_cannot_be_verified_is_refused() {
  unverified_layout
  local a="$SCRATCH/in/answer.txt"
  sed -i "s|^Private folder: .*|Private folder: $SCRATCH/far/gone/../into/|" "$F/AGENTS.local.md"
  git -C "$F" commit -qam "private folder"
  answer "$a" "$SECURE_FINDINGS" critical no
  rec "$W" "$a" record review "$ID"
  [ "$STATUS" -eq 1 ] || fail "po record review exited $STATUS, not 1: $OUT"
  rolled_back private-folder-unusable "the Private folder value"
  nothing_under_sub "the Private folder value"
}
