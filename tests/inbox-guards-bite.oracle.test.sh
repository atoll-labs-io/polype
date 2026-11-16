#!/usr/bin/env bash
# s187 — the oracle of the story: each guard of the decision inbox has a test that fails whenever
# the guard goes, a refusal for a path po cannot verify says so, `output::not_built` is gone and
# po's version goes up (issues #263, #260, #329, #328, #290).

need_po() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO (tests/run.sh builds it before the suite)"
}

# po_in <dir> <args...>: sets OUT (stdout) and STATUS; never fails by itself.
po_in() { local dir="$1"; shift; STATUS=0; OUT="$(cd "$dir" && "$PO" "$@" 2>/dev/null)" || STATUS=$?; }

# post <sensitive> <context>: `po inbox add` from the project root; sets OUT and STATUS.
post() {
  local json
  json="$(jq -n --argjson s "$1" --arg c "$2" '{
    motive: "strategic", sensitive: $s, question: "Which one?", context: $c,
    options: [{key: "a", label: "one", consequence: "x"}, {key: "b", label: "two", consequence: "y"}],
    recommended: "a", why: "w", reversible: true, blocks: []}')"
  STATUS=0; OUT="$(cd "$F" && printf '%s' "$json" | "$PO" inbox add 2>/dev/null)" || STATUS=$?
}

# refused <code> <exit> <what>: OUT is one error object with that code, and po exited <exit>.
refused() {
  [ "$STATUS" -eq "$2" ] || fail "$3: exited $STATUS instead of $2: $OUT"
  jq -e --arg c "$1" '.contract == 1 and .error == $c' <<< "$OUT" >/dev/null || fail "$3: error is not $1: $OUT"
}

decisions_in() { find "$1" -name 'd-*.json' 2>/dev/null | grep -c . || true; }

set_setting() { sed -i "s|^$1:.*|$1: $2|" "$F/AGENTS.local.md"; }

# $F: a Polype project on main whose .gitignore ignores the inbox $I; $SCRATCH is no repository.
guards_fixture() {
  SCRATCH="$(mktemp -d)"
  trap 'rm -rf "$SCRATCH"' EXIT
  SCRATCH="$(cd "$SCRATCH" && pwd -P)"
  F="$SCRATCH/project"; I="$F/.polype/inbox"
  mkdir -p "$F/docs" "$F/sub" "$SCRATCH/far"
  git -C "$F" init -q -b main
  git -C "$F" config user.email test@example.com
  git -C "$F" config user.name test
  git -C "$F" config commit.gpgsign false
  printf '# fixture\n\n```\nTarget branch:     main\nDecision inbox: .polype/inbox/\n```\n' > "$F/AGENTS.local.md"
  printf '# Stories\n' > "$F/docs/stories.md"
  printf '.polype/inbox/\n' > "$F/.gitignore"
  git -C "$F" add -A
  git -C "$F" commit -qm init
}

test_held_lock_is_refused_every_time() {
  need_po
  guards_fixture
  local id
  post false "docs/x.md"
  [ "$STATUS" -eq 0 ] || fail "po inbox add exited $STATUS: $OUT"
  id="$(jq -r '.id' <<< "$OUT")"
  : > "$I/.$id.lock"
  po_in "$F" answer "$id" a
  refused inbox-busy 2 "po answer while the lock of $id is held"
  jq -e '.status == "pending" and .answer == null' "$I/$id.json" >/dev/null \
    || fail "the decision changed while its lock was held: $(cat "$I/$id.json")"
  rm -f "$I/.$id.lock"
  po_in "$F" answer "$id" a
  [ "$STATUS" -eq 0 ] || fail "po answer once the lock is released exited $STATUS: $OUT"
  jq -e '.status == "answered" and .answer.key == "a"' "$I/$id.json" >/dev/null \
    || fail "the answer given once the lock is released is not in the file: $(cat "$I/$id.json")"
}

test_path_in_an_outside_worktree_is_refused() {
  need_po
  guards_fixture
  local context
  git -C "$F" worktree add -q -b side "$SCRATCH/side" main
  for context in "$SCRATCH/side/docs/x.md" "$SCRATCH/side/new/x.md"; do
    post true "$context"
    refused sensitive-context-in-repo 1 "a sensitive context in the worktree at $SCRATCH/side"
  done
  [ "$(decisions_in "$I")" -eq 0 ] || fail "a refused decision was written"
  post true "$SCRATCH/far/x.md"
  [ "$STATUS" -eq 0 ] || fail "a sensitive context outside the repository was refused: $STATUS $OUT"
}

test_written_and_folded_paths_agree() {
  need_po
  guards_fixture
  mkdir -p "$SCRATCH/far/deeper"
  ln -s "$SCRATCH/far/deeper" "$F/sub/link"
  post true "$F/sub/link/../x.md"
  refused sensitive-context-in-repo 1 "the context $F/sub/link/../x.md"
  [ "$(decisions_in "$I")" -eq 0 ] || fail "a refused decision was written"
  post true "$SCRATCH/far/x.md"
  [ "$STATUS" -eq 0 ] || fail "the context $SCRATCH/far/x.md, outside, was refused: $STATUS $OUT"
}

# says_so <what>: the message of OUT neither places the path in the repository nor asks for .gitignore.
says_so() {
  local message
  message="$(jq -r '.message // empty' <<< "$OUT")"
  [ -n "$message" ] || fail "$1: the refusal carries no message: $OUT"
  case "$message" in
    *.gitignore* | *"in the repository"* | *"inside the repository"*) fail "$1: the message does not say the path went unverified: $message" ;;
  esac
}

test_unverified_path_says_so() {
  # shellcheck source=/dev/null
  source "$ROOT/tests/security-findings-stay-private.oracle.test.sh"
  secure_fixture
  local id a="$SCRATCH/in/answer.txt"
  mkdir -p "$F/sub/deep" "$SCRATCH/far"
  ln -s "$F/sub/deep" "$SCRATCH/far/into"

  set_setting "Decision inbox" "$SCRATCH/far/gone/../into/inbox/"
  post false "docs/x.md"
  refused inbox-not-ignored 1 "po inbox add into an inbox po cannot verify"
  says_so "po inbox add"

  set_setting "Decision inbox" ".polype/inbox/"
  post false "docs/x.md"
  [ "$STATUS" -eq 0 ] || fail "po inbox add exited $STATUS: $OUT"
  id="$(jq -r '.id' <<< "$OUT")"
  set_setting "Decision inbox" "$SCRATCH/far/into/../../.polype/inbox/"
  po_in "$F" answer "$id" a
  refused inbox-not-ignored 1 "po answer in an inbox po cannot verify"
  says_so "po answer"
  set_setting "Decision inbox" ".polype/inbox/"

  set_setting "Private folder" "$SCRATCH/far/gone/../into/"
  git -C "$F" commit -qam "private folder"
  answer "$a" "$SECURE_FINDINGS" critical no
  rec "$W" "$a" record review "$ID"
  refused private-folder-unusable 1 "po record review with a Private folder po cannot verify"
  says_so "po record review"
}

test_not_built_is_gone() {
  command -v cargo >/dev/null 2>&1 || fail "cargo is required by this test"
  local out
  out="$(cargo build --release --locked --manifest-path "$ROOT/po/Cargo.toml" 2>&1)" || fail "po does not build: $out"
  ! grep -qE 'dead_code|is never used|is never read|is never constructed' <<< "$out" \
    || fail "po builds with a dead_code warning: $(grep -E 'warning|-->' <<< "$out")"
}

test_version_goes_up() {
  local toml lock polype
  toml="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$ROOT/po/Cargo.toml" | head -n 1)"
  lock="$(awk '$0 == "name = \"po\"" {getline; print; exit}' "$ROOT/po/Cargo.lock" | sed -n 's/^version = "\(.*\)"$/\1/p')"
  polype="$(sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$ROOT/bin/polype" | head -n 1)"
  [ -n "$toml" ] && [ "$toml" = "$lock" ] && [ "$toml" = "$polype" ] \
    || fail "po's version differs: po/Cargo.toml $toml, po/Cargo.lock $lock, bin/polype $polype"
  [ "$toml" != 0.6.0 ] && [ "$(printf '0.6.1\n%s\n' "$toml" | sort -V | head -n 1)" = 0.6.1 ] \
    || fail "po's version $toml is not a patch step above 0.6.0"
}
