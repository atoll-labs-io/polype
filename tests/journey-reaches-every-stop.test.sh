#!/usr/bin/env bash
# s200 — the journey's new guards: the reader of po next's ask reasons, the caller's git location
# variables cleared at init (#432), and a forge double that answers its own repository only and
# merges onto a pull request's own base (#434).

source "$ROOT/tests/journey/journey.sh"

test_reason_reader_reads_every_ask() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  journey_init
  local copy="$J/next" reasons out
  cp -R "$ROOT/po/src/next" "$copy" || fail "cannot copy po/src/next"
  reasons="$(journey_ask_reasons "$copy")" || fail "the reader refuses po/src/next as it is: $reasons"
  printf '\nfn decoy() -> NextAction {\n    act("ask", "s200 decoy")\n}\n' >> "$copy/lane.rs"
  reasons="$(journey_ask_reasons "$copy")" || fail "the reader refuses a literal reason: $reasons"
  grep -qx 's200 decoy' <<< "$reasons" || fail "the reader does not read an added reason: $reasons"
  # Every reason but the decoy counts as reached: only the decoy may be named.
  grep -vx 's200 decoy' <<< "$reasons" >> "$J/asks"
  if out="$(journey_unreached "$copy")"; then fail "a reason no journey reached passed: $out"; fi
  [ "$out" = 's200 decoy' ] || fail "journey_unreached does not name the one reason left: $out"
  printf 's200 decoy\n' >> "$J/asks"
  out="$(journey_unreached "$copy")" || fail "every reason reached still fails: $out"

  mkdir -p "$copy/sub/deep" || fail "cannot make a nested folder"
  printf 'fn nested() -> NextAction {\n    act("ask", "s200 nested")\n}\n' > "$copy/sub/deep/nested.rs"
  if out="$(journey_unreached "$copy")"; then fail "a reason in a nested file passed: $out"; fi
  [ "$out" = 's200 nested' ] || fail "journey_unreached does not name the nested reason: $out"
  printf 's200 nested\n' >> "$J/asks"

  printf 'const ASK: &str = "ask";\nfn held() -> NextAction {\n    act(ASK, "s200 held")\n}\n' > "$copy/sub/held.rs"
  if out="$(journey_ask_reasons "$copy" 2>&1)"; then fail "an action held in a constant was taken for read: $out"; fi
  grep -qF "$copy/sub/held.rs:3 calls act" <<< "$out" || fail "the reader does not name the act call of a constant: $out"
  rm "$copy/sub/held.rs"

  printf '\nfn split() -> NextAction {\n    act(\n        "ask",\n        "s200 split",\n    )\n}\n' >> "$copy/overlap.rs"
  if out="$(journey_ask_reasons "$copy" 2>&1)"; then fail "a reason split over lines was taken for read: $out"; fi
  grep -qF "$copy/overlap.rs:" <<< "$out" || fail "the reader does not name the file of the split reason: $out"
  if journey_unreached "$copy" >/dev/null 2>&1; then fail "journey_unreached passes while the reader fails"; fi
}

test_journey_clears_the_callers_git() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO (tests/run.sh builds it before the suite)"
  export GIT_DIR=/nonexistent/s200-git GIT_WORK_TREE=/nonexistent/s200-work GIT_INDEX_FILE=/nonexistent/s200-index
  export JOURNEY_SETUP=1
  journey_init
  journey_project pr
  journey_story s01-greeting 'Une salutation'
  journey_run || fail "a pr story did not land under the caller's git variables: $(cat "$JOURNEY_LOG")"
  [ "$(git -C "$ORIGIN" log -1 --format=%s main)" = 's01-greeting: Une salutation' ] \
    || fail "origin's main does not end with the landing commit: $(git -C "$ORIGIN" log --format=%s -3 main)"
  grep -qx 'refs/heads/story/s01-greeting' <<< "$(journey_pushed)" \
    || fail "the push log does not hold the story branch: $(journey_pushed)"
}

test_unrunnable_shape_check_records_a_blocked_review() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO (tests/run.sh builds it before the suite)"
  journey_init
  journey_project local
  journey_story s01-greeting 'Une salutation'
  journey_answers s01-greeting "$ROOT/tests/journey/answers/no-verdict" "$ROOT/tests/journey/answers/plain"
  if journey_run; then fail "a review with no verdict went on: $(cat "$JOURNEY_LOG")"; fi
  journey_stopped_on_ask || fail "the journey did not stop on an ask: $(cat "$JOURNEY_LOG")"
  local review
  review="$(journey_lane s01-greeting)/docs/reviews/s01-greeting.md"
  [ "$(sed -n 's/^Review status:[[:space:]]*//p' "$review" | tail -n 1)" = blocked ] \
    || fail "no blocked report was recorded after the check could not run: $(cat "$review")"
  [ "$(grep '^- Next action:' "$review" | tail -n 1)" \
    = '- Next action: a person runs po-gate findings-shape s01-greeting — the check could not run (exit 2)' ] \
    || fail "the blocked report does not name the check that could not run: $(cat "$review")"
}

test_forge_double_holds_its_repository() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  journey_init
  local out work sha
  out="$(gh api --hostname github.com 'repos/acme/project/pulls?head=acme:story/s01-none&state=all&per_page=100')" \
    || fail "the double refused a pulls read: $out"
  [ "$(jq -c . <<< "$out")" = '[]' ] || fail "a branch with no pull request does not read as []: $out"
  journey_audit >/dev/null || fail "a pulls read failed the audit: $(journey_audit)"

  # A pull request whose base is not main lands on its base, and main stays where it was.
  work="$J/work"
  git init -q -b main "$work" && git -C "$work" config user.email s200@example.com && git -C "$work" config user.name s200 \
    && git -C "$work" config commit.gpgsign false || fail "cannot make the work repository"
  git -C "$work" commit -q --allow-empty -m base && git -C "$work" switch -q -c release \
    && git -C "$work" commit -q --allow-empty -m 'release only' \
    && git -C "$work" switch -q -c story/s01-base && git -C "$work" commit -q --allow-empty -m 's01-base: Sur une autre base' \
    || fail "cannot commit in the work repository"
  git init -q --bare -b main "$ORIGIN" && git -C "$work" push -q "$ORIGIN" main release story/s01-base \
    || fail "cannot fill the bare origin"
  sha="$(git -C "$work" rev-parse story/s01-base)"
  out="$(gh pr create --repo github.com/acme/project --base release --head story/s01-base --title t --body-file /dev/null)" \
    || fail "the double refused a pull request: $out"
  gh pr merge "$out" --repo github.com/acme/project --rebase --match-head-commit "$sha" >/dev/null || fail "the double refused the merge"
  [ "$(git -C "$ORIGIN" log -3 --format=%s release)" = "$(printf '%s\n' 's01-base: Sur une autre base' 'release only' base)" ] \
    || fail "the merge did not land on the pull request's base: $(git -C "$ORIGIN" log --format=%s -2 release)"
  [ "$(git -C "$ORIGIN" log -1 --format=%s main)" = base ] || fail "the merge moved main: $(git -C "$ORIGIN" log --format=%s -2 main)"
  journey_audit >/dev/null || fail "expected calls failed the audit: $(journey_audit)"

  if gh pr list --repo github.com/other/project --head story/s01-base --state all --json number >/dev/null 2>&1; then
    fail "the double answered a pull request list of another repository"
  fi
  if out="$(journey_audit)"; then fail "a call aimed at another repository passed the audit"; fi
  grep -qF 'unexpected call to gh: pr list --repo github.com/other/project' <<< "$out" \
    || fail "the audit does not name the call aimed at another repository: $out"
}
