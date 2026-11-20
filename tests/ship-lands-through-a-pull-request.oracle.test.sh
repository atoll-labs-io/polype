#!/usr/bin/env bash
# s194 — the oracle of the story: `po ship push <id> --sha <sha> --body-file <file>` sends the
# landing commit to story/<id> on origin with a lease, opens or reuses its pull request, and merges
# it only under an effective automatic, once the forge's checks passed and the gate was read again.
# origin is named by a github.com URL that git rewrites to a local bare repository (insteadOf), so
# the forge is recognised while nothing leaves the machine; gh is a double first on PATH and named
# by PO_GH. The bare repository's update hook logs every ref a push sends. Polling never sleeps:
# PO_SHIP_POLL_SECONDS=0. description_stays_with_the_model speaks to a model and is judged in review.

need_po() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO (tests/run.sh builds it before the suite)"
}

one_object() {
  [ "$(jq -s 'length' <<< "$OUT" 2>/dev/null)" = 1 ] || fail "$1 did not print exactly one JSON value: $OUT"
  jq -e '.contract == 1' <<< "$OUT" >/dev/null || fail "$1 does not carry contract 1: $OUT"
}

is() { jq -e "$1" <<< "$OUT" >/dev/null || fail "$2: $OUT"; }

# po run from the story worktree, with every forge tool doubled.
po_in_worktree() {
  STATUS=0
  OUT="$(cd "$W" && env PATH="$D/bin:$PATH" HOME="$SCRATCH/home" GH_CONFIG_DIR="$SCRATCH/home/gh" \
    PO_GH="$D/bin/gh" PO_CURL="$D/bin/curl" PO_GLAB="$D/bin/glab" PO_TEA="$D/bin/tea" \
    PO_SHIP_POLL_SECONDS=0 DOUBLES="$D" "$PO" ship "$@" 2>"$SCRATCH/stderr" </dev/null)" || STATUS=$?
}

# land: builds the landing commit, as /po-ship Step 1 does, and keeps its sha in SHA.
land() {
  po_in_worktree land s01-a
  [ "$STATUS" -eq 0 ] || fail "po ship land exited $STATUS: $OUT $(cat "$SCRATCH/stderr")"
  SHA="$(jq -r .sha <<< "$OUT")"
}

# The one place the command's shape is written: `po ship push <id> --sha <sha> --body-file <file>`.
push() { po_in_worktree push s01-a --sha "${1:-$SHA}" --body-file "$SCRATCH/body.md"; }

# project <Ship confirmation line>: story s01-a changed code.txt, was reviewed on that code, and
# waits in $W; origin/main is main; the forge is unreadable until answers are given. `Test: —`
# runs no check at ship, so a second `po ship land` builds the same tree under another sha.
project() {
  SCRATCH="$(cd "$(mktemp -d)" && pwd -P)"
  SCRATCHES="${SCRATCHES:-} $SCRATCH"
  trap 'rm -rf $SCRATCHES' EXIT
  R="$SCRATCH/project" W="$SCRATCH/project/.worktrees/s01-a" D="$SCRATCH/doubles" ORIGIN="$SCRATCH/origin.git"
  mkdir -p "$SCRATCH/home" "$D/bin" "$D/calls" "$D/prs"
  : > "$D/responses"; : > "$D/calls/gh"
  printf '[{"name":"suite","bucket":"pass","link":"https://ci.example/1"}]\n' > "$D/checks"
  git init -q -b main "$R"
  git -C "$R" config user.email test@example.com
  git -C "$R" config user.name test
  git -C "$R" config commit.gpgsign false
  mkdir -p "$R/.polype/hooks" "$R/docs"
  cp "$METHOD/hooks/po-gate.sh" "$METHOD/hooks/po-run.sh" "$R/.polype/hooks/"
  printf 'Target branch: main\nMerge mode: pr\nShip confirmation: %s\nForge checks: required\nFull suite: ship\nE2E stage: —\nBuild stage: —\nWorktree root: .worktrees/\n\nTest: —\nE2E: —\nBuild: —\n' \
    "$1" > "$R/AGENTS.local.md"
  printf '.worktrees/\n' > "$R/.gitignore"
  printf '# Stories\n\n### s01-a — Un titre\n\n- **Complexité** : 1\n' > "$R/docs/stories.md"
  printf 'one\n' > "$R/code.txt"
  git -C "$R" add -A && git -C "$R" commit -qm base
  git init -q --bare -b main "$ORIGIN"
  git -C "$R" remote add origin https://github.com/acme/project.git
  git -C "$R" config "url.$ORIGIN.insteadOf" https://github.com/acme/project.git
  git -C "$R" push -q origin main
  printf '#!/usr/bin/env bash\necho "$1" >> %q\n' "$D/pushed" > "$ORIGIN/hooks/update"
  chmod +x "$ORIGIN/hooks/update"
  : > "$D/pushed"
  git -C "$R" worktree add -q -b story/s01-a "$W"
  printf 'two\n' > "$W/code.txt"
  git -C "$W" commit -qam code
  mkdir -p "$W/docs/reviews"
  printf '# Review\n\n## Findings\n\nNone.\n\nReview status: complete\nReviewed tree: %s\nShip allowed: yes\n' \
    "$(git -C "$W" rev-parse 'HEAD^{tree}')" > "$W/docs/reviews/s01-a.md"
  # The description /po-ship writes, outside the worktree; its marker must never reach an argument.
  printf 'What: code.txt says two.\nWhy: the story asks it; $(touch %s) marker-7f3\nVerdict: no finding.\n' \
    "$SCRATCH/injected" > "$SCRATCH/body.md"
  doubles
}

# answer <api path> <status> <json body>: what the GitHub API answers for that path, query dropped.
answer() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$D/responses"; }

# Another collaborator may write: the repository is collaborative.
collaborative_github() {
  answer user 200 '{"login":"me"}'
  answer repos/acme/project/collaborators 200 '[{"login":"me","permissions":{"push":true}},{"login":"other","permissions":{"push":true}}]'
  answer repos/acme/project/branches/main/protection 404 '{"message":"Branch not protected"}'
  answer repos/acme/project/rules/branches/main 200 '[]'
}

gh_calls() { grep -c -- "$1" "$D/calls/gh" || true; }
origin_ref() { git -C "$ORIGIN" rev-parse -q --verify "refs/heads/$1" || true; }

doubles() {
  cat > "$D/bin/respond" <<'EOF'
#!/usr/bin/env bash
path="${1%%\?*}"; path="${path#/}"
line="$(awk -F'\t' -v p="$path" '$1 == p {l = $0} END {print l}' "$DOUBLES/responses")"
if [ -n "$line" ]; then status="$(cut -f2 <<< "$line")"; body="$(cut -f3- <<< "$line")"
else status=404; body='{"message":"Not Found"}'; fi
[ -z "$2" ] || printf 'HTTP/2.0 %s X\nContent-Type: application/json\r\n\r\n' "$status"
printf '%s\n' "$body"
[ "$status" -lt 300 ] || exit 1
EOF
  # gh: the API for the forge reading, and pull requests kept as JSON files in $DOUBLES/prs. A pull
  # request's head lives in acme/project and is read from the bare origin unless its file names
  # its own repository or head. A merge is a rebase made by the forge: a new commit on main.
  cat > "$D/bin/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DOUBLES/calls/gh"
origin="$(cat "$DOUBLES/origin")"
opt() { local want="$1"; shift; while [ $# -gt 0 ]; do [ "$1" = "$want" ] && { echo "${2:-}"; return; }; shift; done; }
has() { local want="$1"; shift; for a in "$@"; do [ "$a" = "$want" ] && return 0; done; return 1; }
with_head() { local pr="$1" head; head="$(jq -r .headRefName "$pr")"
  jq --arg oid "$(git -C "$origin" rev-parse -q --verify "refs/heads/$head")" \
    '{isCrossRepository: false, headRepositoryOwner: {login: "acme"}} + . | if has("headRefOid") then . else . + {headRefOid: $oid} end' "$pr"; }
find_pr() { local key="$1" pr; for pr in "$DOUBLES"/prs/*.json; do [ -f "$pr" ] || continue
  jq -e --arg k "$key" '(.url == $k) or ((.number | tostring) == $k) or (.headRefName == $k)' "$pr" >/dev/null && { echo "$pr"; return; }; done; }
target() { local a; for a in "${@:3}"; do case "$a" in -*) ;; *) echo "$a"; return ;; esac; done; }
case "${1:-} ${2:-}" in
  "auth status") exit 0 ;;
  "pr list")
    head="$(opt --head "$@")"
    for pr in "$DOUBLES"/prs/*.json; do
      [ -f "$pr" ] && [ "$(jq -r .headRefName "$pr")" = "$head" ] && with_head "$pr"
    done | jq -s . ;;
  "pr view")
    pr="$(find_pr "$(target "$@")")"; [ -n "$pr" ] || { echo "no pull requests found" >&2; exit 1; }
    with_head "$pr" ;;
  "pr create")
    [ ! -f "$DOUBLES/fail-create" ] || { rm "$DOUBLES/fail-create"; echo "HTTP 502" >&2; exit 1; }
    n=$(( $(ls "$DOUBLES/prs" | wc -l) + 1 )); head="$(opt --head "$@")"
    cp "$(opt --body-file "$@")" "$DOUBLES/calls/body.$n" 2>/dev/null || true
    draft=false; has --draft "$@" && draft=true
    jq -n --argjson n "$n" --arg h "$head" --arg b "$(opt --base "$@")" --argjson d "$draft" \
      '{number: $n, url: "https://github.com/acme/project/pull/\($n)", state: "OPEN", isDraft: $d, headRefName: $h, baseRefName: $b}' \
      > "$DOUBLES/prs/$n.json"
    echo "https://github.com/acme/project/pull/$n" ;;
  "pr checks")
    [ ! -f "$DOUBLES/on-checks" ] || bash "$DOUBLES/on-checks"
    out="$(head -n 1 "$DOUBLES/checks")"
    [ "$(wc -l < "$DOUBLES/checks")" -le 1 ] || sed -i 1d "$DOUBLES/checks"
    printf '%s\n' "$out"
    case "$out" in *'"fail"'*|*'"cancel"'*) exit 1 ;; *'"pending"'*|'[]') exit 8 ;; esac ;;
  "pr merge")
    [ ! -f "$DOUBLES/fail-merge" ] || { rm "$DOUBLES/fail-merge"; echo "HTTP 502" >&2; exit 1; }
    pr="$(find_pr "$(target "$@")")"; [ -n "$pr" ] || exit 1
    sha="$(opt --match-head-commit "$@")" head="$(jq -r .headRefName "$pr")"
    [ "$sha" = "$(git -C "$origin" rev-parse "refs/heads/$head")" ] || { echo "head moved" >&2; exit 1; }
    has --rebase "$@" || { echo "not a rebase" >&2; exit 1; }
    new="$(GIT_AUTHOR_NAME=forge GIT_AUTHOR_EMAIL=f@example.com GIT_COMMITTER_NAME=forge GIT_COMMITTER_EMAIL=f@example.com \
      git -C "$origin" commit-tree "$sha^{tree}" -p refs/heads/main -m "$(git -C "$origin" log -1 --format=%B "$sha")")"
    git -C "$origin" update-ref refs/heads/main "$new"
    jq '.state = "MERGED"' "$pr" > "$pr.new" && mv "$pr.new" "$pr" ;;
  "api "*)
    path="" skip="" include=""
    for a in "${@:2}"; do
      if [ -n "$skip" ]; then skip=""; continue; fi
      case "$a" in
        -i|--include) include=1 ;;
        --hostname|-H|--header|-X|--method|-q|--jq|-t|--template|-f|-F|--field|--raw-field|--cache) skip=1 ;;
        -*) ;;
        *) path="$a" ;;
      esac
    done
    exec "$DOUBLES/bin/respond" "$path" "$include" ;;
  *) exit 1 ;;
esac
EOF
  printf '#!/usr/bin/env bash\nexit 7\n' > "$D/bin/curl"
  printf '#!/usr/bin/env bash\nexit 1\n' > "$D/bin/glab"
  printf '#!/usr/bin/env bash\nexit 1\n' > "$D/bin/tea"
  chmod +x "$D/bin/"*
  printf '%s\n' "$ORIGIN" > "$D/origin"
}

test_pr_mode_never_pushes_target() {
  need_po
  project 'automatic (chosen)'
  # An older landing already sits on origin's story branch: the lease replaces it.
  git -C "$R" push -q origin main:refs/heads/story/s01-a
  : > "$D/pushed"
  local main_before; main_before="$(origin_ref main)"
  land
  push
  [ "$STATUS" -eq 0 ] || fail "po ship push exited $STATUS: $OUT $(cat "$SCRATCH/stderr")"
  one_object "po ship push"
  is ".sha == \"$SHA\"" "the reply does not name the commit sent"
  [ "$(origin_ref story/s01-a)" = "$SHA" ] || fail "origin's story/s01-a is not the landing commit"
  [ "$(sort -u "$D/pushed")" = refs/heads/story/s01-a ] || fail "a push sent another ref than story/s01-a: $(cat "$D/pushed")"
  [ "$(gh_calls '^pr create')" = 1 ] || fail "not exactly one pull request was opened: $(cat "$D/calls/gh")"
  grep '^pr create' "$D/calls/gh" | grep -qF -- '--head story/s01-a' || fail "the pull request is not opened from story/s01-a"
  grep '^pr create' "$D/calls/gh" | grep -qF -- '--base main' || fail "the pull request does not target main"
  ! grep -qF marker-7f3 "$D/calls/gh" || fail "the description travelled in an argument"
  cmp -s "$SCRATCH/body.md" "$D/calls/body.1" || fail "the pull request body is not the description file"
  [ ! -e "$SCRATCH/injected" ] || fail "the description was run by a shell"
  [ "$(git -C "$ORIGIN" log -1 --format=%s main)" = 's01-a: Un titre' ] && [ "$(origin_ref main)" != "$main_before" ] \
    || fail "the forge did not land the story on main"

  # A pull request already open from story/s01-a is reused, never doubled.
  project 'human (chosen)'
  jq -n '{number: 7, url: "https://github.com/acme/project/pull/7", state: "OPEN", isDraft: false, headRefName: "story/s01-a", baseRefName: "main"}' \
    > "$D/prs/7.json"
  land
  push
  [ "$STATUS" -eq 0 ] || fail "po ship push with an open pull request exited $STATUS: $OUT"
  is '.pull_request.url == "https://github.com/acme/project/pull/7"' "the open pull request is not reused"
  [ "$(gh_calls '^pr create')" = 0 ] || fail "a second pull request was opened"
  [ "$(sort -u "$D/pushed")" = refs/heads/story/s01-a ] || fail "a push sent another ref than story/s01-a"
}

test_human_stops_at_the_pull_request() {
  need_po
  # The line says automatic, the forge is collaborative: the effective value is human.
  project 'automatic (chosen)'
  collaborative_github
  local main_before; main_before="$(origin_ref main)"
  land
  push
  [ "$STATUS" -eq 0 ] || fail "po ship push under an effective human exited $STATUS: $OUT $(cat "$SCRATCH/stderr")"
  one_object "po ship push under an effective human"
  is '.state == "waiting-for-human" and .effective == "human"' "an effective human does not stop at the pull request"
  is '.pull_request.url | test("^https://github.com/acme/project/pull/[0-9]+$")' "the stop does not give the pull request"
  [ "$(gh_calls '^pr merge')" = 0 ] || fail "a merge was asked under an effective human"
  [ "$(gh_calls '^pr checks')" = 0 ] || fail "the checks were awaited under an effective human"
  [ "$(origin_ref main)" = "$main_before" ] || fail "main moved under an effective human"

  project 'human (chosen)'
  land
  push
  is '.state == "waiting-for-human"' "a human line does not stop at the pull request"
  [ "$(gh_calls '^pr merge')" = 0 ] || fail "a merge was asked under a human line"
}

test_automatic_waits_for_checks() {
  need_po
  # No check yet, then one pending, then passed: the merge comes after the last reading only.
  project 'automatic (chosen)'
  printf '[]\n[{"name":"suite","bucket":"pending","link":"https://ci.example/1"}]\n[{"name":"suite","bucket":"pass","link":"https://ci.example/1"}]\n' > "$D/checks"
  land
  push
  [ "$STATUS" -eq 0 ] || fail "po ship push under automatic exited $STATUS: $OUT $(cat "$SCRATCH/stderr")"
  is '.state == "merged"' "the story is not reported merged"
  [ "$(gh_calls '^pr checks')" -ge 3 ] || fail "the merge did not wait for the checks to pass: $(cat "$D/calls/gh")"
  local last merge
  last="$(grep -n '^pr checks' "$D/calls/gh" | tail -n 1 | cut -d: -f1)"
  merge="$(grep -n '^pr merge' "$D/calls/gh" | cut -d: -f1)"
  [ "$(wc -w <<< "$merge")" = 1 ] && [ "$merge" -gt "$last" ] || fail "not one merge after the checks passed: $(cat "$D/calls/gh")"
  grep '^pr merge' "$D/calls/gh" | grep -qF -- "--match-head-commit $SHA" || fail "the merge is not bound to the commit sent"

  # The gate is read again before the merge: a verdict withdrawn meanwhile merges nothing.
  project 'automatic (chosen)'
  printf 'printf "\\nShip allowed: no\\n" >> %q\n' "$W/docs/reviews/s01-a.md" > "$D/on-checks"
  land
  push
  [ "$STATUS" -eq 1 ] || fail "a verdict withdrawn before the merge gave exit $STATUS: $OUT"
  is '.error == "gate-refused"' "a verdict withdrawn before the merge is not gate-refused"
  [ "$(gh_calls '^pr merge')" = 0 ] || fail "a merge was asked although the gate refused"

  # A failing check sends the story to a fix run and merges nothing.
  project 'automatic (chosen)'
  printf '[{"name":"suite","bucket":"fail","link":"https://ci.example/9"}]\n' > "$D/checks"
  land
  push
  [ "$STATUS" -eq 1 ] || fail "a failing check gave exit $STATUS: $OUT"
  is '.error == "checks-failed"' "a failing check is not checks-failed"
  is '.message | contains("/po-execute s01-a")' "a failing check does not send the story to a fix run"
  is '[.checks[] | .link] == ["https://ci.example/9"]' "the failing check is not named with its link"
  [ "$(gh_calls '^pr merge')" = 0 ] || fail "a merge was asked after a failing check"
}

test_resumed_ship_does_not_land_twice() {
  need_po
  project 'automatic (chosen)'
  # Two commits of the base that only resemble the landing: one quotes the subject in its body,
  # one has a title extending it. Neither is the landing.
  git -C "$R" checkout -q -b decoys
  printf 'a\n' > "$R/note-a.txt"; git -C "$R" add -A
  git -C "$R" commit -qm 'docs: note' -m 'It quotes s01-a: Un titre on its own line.'
  printf 'b\n' > "$R/note-b.txt"; git -C "$R" add -A
  git -C "$R" commit -qm 's01-a: Un titre, suite'
  git -C "$R" push -q origin decoys:main
  git -C "$R" checkout -q main && git -C "$R" branch -q -D decoys
  : > "$D/pushed"

  po_in_worktree land s01-a
  [ "$STATUS" -eq 0 ] || fail "po ship land exited $STATUS: $OUT"
  is '.already_landed == false' "a commit only quoting the title, or extending it, passed for the landing"
  SHA="$(jq -r .sha <<< "$OUT")"

  # Interrupted after the push, before the pull request.
  touch "$D/fail-create"
  push
  [ "$STATUS" -ne 0 ] || fail "a failed pull request creation was not reported"
  [ "$(origin_ref story/s01-a)" = "$SHA" ] || fail "the landing commit was not sent before the interruption"

  # Rebuilt under another date, the landing gets another sha; the commit already sent is kept.
  local again
  GIT_COMMITTER_DATE='2001-01-01T00:00:00Z' GIT_AUTHOR_DATE='2001-01-01T00:00:00Z' po_in_worktree land s01-a
  again="$(jq -r .sha <<< "$OUT")"
  [ -n "$again" ] && [ "$again" != "$SHA" ] || fail "the test could not build a second landing commit: $OUT"
  touch "$D/fail-merge"
  push "$again"
  [ "$STATUS" -ne 0 ] || fail "a failed merge was not reported"
  [ "$(origin_ref story/s01-a)" = "$SHA" ] || fail "the commit already sent was rebuilt under another sha"
  [ "$(grep -cx refs/heads/story/s01-a "$D/pushed")" = 1 ] || fail "the landing commit was pushed twice: $(cat "$D/pushed")"
  [ "$(gh_calls '^pr create')" = 2 ] || fail "the pull request was not opened once the forge answered: $(cat "$D/calls/gh")"
  [ "$(ls "$D/prs" | wc -l)" = 1 ] || fail "a second pull request was opened"

  # Interrupted before the merge: the rerun reuses the pull request and merges the commit sent.
  push
  [ "$STATUS" -eq 0 ] || fail "the resumed ship exited $STATUS: $OUT $(cat "$SCRATCH/stderr")"
  is ".state == \"merged\" and .sha == \"$SHA\"" "the resumed ship did not merge the commit already sent"
  [ "$(ls "$D/prs" | wc -l)" = 1 ] || fail "the resumed ship opened a second pull request"

  # Run once more after the merge: it leads to cleanup and writes nothing.
  local calls pushed main
  calls="$(gh_calls '^pr \(create\|merge\)')" pushed="$(cat "$D/pushed")" main="$(origin_ref main)"
  push
  [ "$STATUS" -eq 0 ] || fail "a ship rerun after the merge exited $STATUS: $OUT"
  is '.state == "merged"' "a ship rerun after the merge does not lead to cleanup"
  [ "$(gh_calls '^pr \(create\|merge\)')" = "$calls" ] || fail "a ship rerun after the merge asked the forge to write"
  [ "$(cat "$D/pushed")" = "$pushed" ] && [ "$(origin_ref main)" = "$main" ] || fail "a ship rerun after the merge pushed or moved main"
  [ "$(git -C "$ORIGIN" log --format=%s main | grep -cx 's01-a: Un titre')" = 1 ] || fail "the story landed twice"
}

test_forge_line_is_rewritten_by_the_command() {
  need_po
  project 'automatic (forge)'
  collaborative_github
  local main_before; main_before="$(origin_ref main)"
  land
  push
  [ "$STATUS" -eq 0 ] || fail "po ship push with a (forge) line to rewrite exited $STATUS: $OUT $(cat "$SCRATCH/stderr")"
  local framing; framing="$(origin_ref framing/ship-confirmation)"
  [ -n "$framing" ] || fail "no framing/ship-confirmation branch was sent"
  [ "$(git -C "$ORIGIN" rev-list --parents -n 1 "$framing")" = "$framing $main_before" ] || fail "the rewrite is not one commit on origin/main"
  [ "$(git -C "$ORIGIN" diff --name-only main "$framing")" = AGENTS.local.md ] || fail "the rewrite touches more than AGENTS.local.md"
  git -C "$ORIGIN" show "$framing:AGENTS.local.md" | grep -qE '^Ship confirmation:[[:space:]]*human \(forge\)$' \
    || fail "the rewritten line is not human (forge)"
  [ "$(git -C "$ORIGIN" log -1 --format=%s "$framing")" = 'chore: Ship confirmation follows the forge' ] || fail "the rewrite is not titled as the method says"
  grep '^pr create' "$D/calls/gh" | grep -F -- '--head framing/ship-confirmation' | grep -qF -- '--draft' \
    || fail "no draft pull request was opened for the rewrite: $(cat "$D/calls/gh")"
  [ "$(origin_ref main)" = "$main_before" ] || fail "the rewrite moved main"
  ! grep -qx refs/heads/main "$D/pushed" || fail "main was pushed"

  # Rerun: the branch already holds the line, its draft is reused.
  push
  [ "$(origin_ref framing/ship-confirmation)" = "$framing" ] || fail "the rewrite was sent again"
  [ "$(grep '^pr create' "$D/calls/gh" | grep -cF -- '--head framing/ship-confirmation')" = 1 ] || fail "a second draft was opened"

  # A (chosen) line is never touched, even on a collaborative forge.
  project 'automatic (chosen)'
  collaborative_github
  land
  push
  [ -z "$(origin_ref framing/ship-confirmation)" ] || fail "a (chosen) line was rewritten"
  ! grep -qF 'framing/ship-confirmation' "$D/calls/gh" || fail "a draft was opened for a (chosen) line"
}

test_version_goes_up() {
  local toml lock polype
  toml="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$ROOT/po/Cargo.toml" | head -n 1)"
  lock="$(awk '$0 == "name = \"po\"" {getline; print; exit}' "$ROOT/po/Cargo.lock" | sed -n 's/^version = "\(.*\)"$/\1/p')"
  polype="$(sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$ROOT/bin/polype")"
  [ -n "$toml" ] && [ "$toml" = "$lock" ] && [ "$toml" = "$polype" ] \
    || fail "po's version differs: po/Cargo.toml $toml, po/Cargo.lock $lock, bin/polype $polype"
  [ "$toml" != 0.9.0 ] && [ "$(printf '0.9.0\n%s\n' "$toml" | sort -V | head -n 1)" = 0.9.0 ] \
    || fail "po's version $toml is not above 0.9.0"
}
