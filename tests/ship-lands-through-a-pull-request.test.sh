#!/usr/bin/env bash
# s194 — the task tests of `po ship push <id>`, on the oracle's throwaway projects: origin is a local
# bare repository named by a forge URL, and gh is a double.

source "$(dirname "${BASH_SOURCE[0]}")/ship-lands-through-a-pull-request.oracle.test.sh"
unset -f test_pr_mode_never_pushes_target test_human_stops_at_the_pull_request test_automatic_waits_for_checks \
  test_resumed_ship_does_not_land_twice test_forge_line_is_rewritten_by_the_command test_version_goes_up

origin_refs() { git -C "$ORIGIN" for-each-ref --format='%(refname) %(objectname)'; }
forge_writes() { gh_calls '^pr \(create\|merge\)'; }

test_push_refuses_before_writing() {
  need_po
  project 'automatic (chosen)'
  land
  local refs review
  refs="$(origin_refs)" review="$(cat "$W/docs/reviews/s01-a.md")"

  po_in_worktree push s01-a --sha "$SHA" --body-file "$SCRATCH/missing.md"
  [ "$STATUS" -eq 2 ] || fail "a missing description file gave exit $STATUS: $OUT"
  is '.error == "usage"' "a missing description file is not a usage error"

  printf '\nShip allowed: no\n' >> "$W/docs/reviews/s01-a.md"
  push
  [ "$STATUS" -eq 1 ] || fail "a refused gate gave exit $STATUS: $OUT"
  is '.error == "gate-refused"' "a refused gate is not gate-refused"
  printf '%s\n' "$review" > "$W/docs/reviews/s01-a.md"

  sed -i 's/^Merge mode: pr$/Merge mode: local/' "$R/AGENTS.local.md"
  push
  [ "$STATUS" -eq 2 ] || fail "Merge mode: local gave exit $STATUS: $OUT"
  is '.error == "usage"' "Merge mode: local is not a usage error"

  [ "$(origin_refs)" = "$refs" ] || fail "a refused run moved a ref of origin"
  [ ! -s "$D/pushed" ] || fail "a refused run pushed: $(cat "$D/pushed")"
  [ "$(forge_writes)" = 0 ] || fail "a refused run asked the forge to write: $(cat "$D/calls/gh")"
}

test_stale_sha_is_refused() {
  need_po
  project 'automatic (chosen)'
  land
  push "$(git -C "$W" rev-parse HEAD)"
  [ "$STATUS" -eq 1 ] || fail "a commit that is not the landing gave exit $STATUS: $OUT"
  is '.error == "stale-landing"' "a commit that is not the landing is not stale-landing"
  [ ! -s "$D/pushed" ] || fail "a stale commit was pushed: $(cat "$D/pushed")"
  [ "$(gh_calls '^pr ')" = 0 ] || fail "a stale commit reached the pull request step"
}

test_closed_pull_request_goes_to_a_human() {
  need_po
  project 'automatic (chosen)'
  jq -n '{number: 4, url: "https://github.com/acme/project/pull/4", state: "CLOSED", isDraft: false, headRefName: "story/s01-a", baseRefName: "main"}' \
    > "$D/prs/4.json"
  land
  push
  [ "$STATUS" -eq 1 ] || fail "a closed pull request gave exit $STATUS: $OUT"
  is '.error == "pull-request-closed"' "a closed pull request is not pull-request-closed"
  [ "$(forge_writes)" = 0 ] || fail "a closed pull request was replaced or merged: $(cat "$D/calls/gh")"
}

test_checks_that_never_pass_merge_nothing() {
  need_po
  # Checks that never arrive: the readings run out, a human is asked.
  project 'automatic (chosen)'
  printf '[]\n' > "$D/checks"
  land
  push
  [ "$STATUS" -eq 1 ] || fail "checks that never arrive gave exit $STATUS: $OUT"
  is '.error == "checks-timeout"' "checks that never arrive are not checks-timeout"
  [ "$(gh_calls '^pr checks')" = 60 ] || fail "the wait did not stop at 60 readings: $(gh_calls '^pr checks')"
  [ "$(gh_calls '^pr merge')" = 0 ] || fail "a merge was asked without passing checks"

  # gh disappears once the pull request is read: the checks cannot be read at all.
  project 'automatic (chosen)'
  mv "$D/bin/gh" "$D/bin/gh.real"
  printf '#!/usr/bin/env bash\n"$DOUBLES/bin/gh.real" "$@"; code=$?\n[ "${1:-} ${2:-}" != "pr view" ] || rm -f "$DOUBLES/bin/gh"\nexit $code\n' \
    > "$D/bin/gh"
  chmod +x "$D/bin/gh"
  land
  push
  [ "$STATUS" -eq 1 ] || fail "gh failing to start gave exit $STATUS: $OUT"
  is '.error == "checks-unreadable"' "gh failing to start is not checks-unreadable"
  [ "$(gh_calls '^pr merge')" = 0 ] || fail "a merge was asked with unreadable checks"

  # The pull request keeps showing another head than the commit sent: its checks are never read.
  project 'automatic (chosen)'
  mv "$D/bin/gh" "$D/bin/gh.real"
  cat > "$D/bin/gh" <<'EOF'
#!/usr/bin/env bash
case "$*" in "pr view "*headRefOid*) echo '{"headRefOid":"0123456789012345678901234567890123456789"}'; exit 0 ;; esac
exec "$DOUBLES/bin/gh.real" "$@"
EOF
  chmod +x "$D/bin/gh"
  land
  push
  [ "$STATUS" -eq 1 ] || fail "a pull request on another head gave exit $STATUS: $OUT"
  is '.error == "checks-timeout"' "a pull request on another head is not checks-timeout"
  [ "$(gh_calls '^pr checks')" = 0 ] || fail "checks were read on another head than the commit sent"
  [ "$(gh_calls '^pr merge')" = 0 ] || fail "a pull request on another head was merged"
}

test_forge_without_pull_requests_asks_a_person() {
  need_po
  project 'automatic (chosen)'
  git -C "$R" remote set-url origin https://gitlab.example.com/acme/project.git
  git -C "$R" config --add "url.$ORIGIN.insteadOf" https://gitlab.example.com/acme/project.git
  land
  push
  [ "$STATUS" -eq 0 ] || fail "po ship push on a forge without pull requests exited $STATUS: $OUT"
  is '.state == "no-pull-request" and .pull_request == null' "a forge without pull requests does not ask a person"
  [ "$(origin_ref story/s01-a)" = "$SHA" ] || fail "the landing commit was not sent"
  [ "$(gh_calls '^pr ')" = 0 ] || fail "gh pr ran against a forge that is not GitHub: $(cat "$D/calls/gh")"

  # A (forge) line to rewrite on a collaborative GitLab: the branch is sent, and the reply asks a
  # person to open its pull request.
  project 'automatic (forge)'
  git -C "$R" remote set-url origin https://gitlab.example.com/acme/project.git
  git -C "$R" config --add "url.$ORIGIN.insteadOf" https://gitlab.example.com/acme/project.git
  cat > "$D/bin/glab" <<'EOF'
#!/usr/bin/env bash
[ "$1" = auth ] && exit 0
path="" skip="" include=""
for a in "${@:2}"; do
  if [ -n "$skip" ]; then skip=""; continue; fi
  case "$a" in -i) include=1 ;; --hostname) skip=1 ;; -*) ;; *) path="$a" ;; esac
done
exec "$DOUBLES/bin/respond" "$path" "$include"
EOF
  answer user 200 '{"username":"me"}'
  answer 'projects/:id/members/all' 200 '[{"username":"me","access_level":50},{"username":"dev","access_level":30}]'
  answer 'projects/:id/approval_rules' 200 '[]'
  land
  push
  [ "$STATUS" -eq 0 ] || fail "po ship push with a (forge) line on GitLab exited $STATUS: $OUT $(cat "$SCRATCH/stderr")"
  is '.effective == "human" and .rewrite.branch == "framing/ship-confirmation" and .rewrite.url == null' \
    "the (forge) line on GitLab was not sent as a branch"
  is '.rewrite.next == "open-pull-request" and .rewrite.refused == false' "the reply does not ask a person to open the rewrite's pull request"
  [ -n "$(origin_ref framing/ship-confirmation)" ] || fail "framing/ship-confirmation was not sent"
}

# other_repository_pr <number> <head> <state>: a pull request whose head lives in another repository.
other_repository_pr() {
  jq -n --argjson n "$1" --arg h "$2" --arg s "$3" \
    '{number: $n, url: "https://github.com/acme/project/pull/\($n)", state: $s, isDraft: false, headRefName: $h, baseRefName: "main",
      isCrossRepository: true, headRepositoryOwner: {login: "other"}, headRefOid: "0123456789012345678901234567890123456789"}' \
    > "$D/prs/$1.json"
}

# pinned_pr <number> <head> <state>: origin's own pull request, its head on another commit.
pinned_pr() {
  jq -n --argjson n "$1" --arg h "$2" --arg s "$3" \
    '{number: $n, url: "https://github.com/acme/project/pull/\($n)", state: $s, isDraft: false, headRefName: $h, baseRefName: "main",
      headRefOid: "0123456789012345678901234567890123456789"}' \
    > "$D/prs/$1.json"
}

test_only_pull_requests_from_origin_are_used() {
  need_po
  project 'human (chosen)'
  other_repository_pr 9 story/s01-a OPEN
  land
  push
  [ "$STATUS" -eq 0 ] || fail "po ship push beside another repository's pull request exited $STATUS: $OUT $(cat "$SCRATCH/stderr")"
  is '.state == "waiting-for-human" and .pull_request.created == true and .pull_request.number != 9' \
    "another repository's pull request was reported ready"
  local url; url="$(jq -r .pull_request.url <<< "$OUT")"
  push
  [ "$STATUS" -eq 0 ] || fail "the rerun exited $STATUS: $OUT"
  is ".pull_request.url == \"$url\" and .pull_request.created == false" "the rerun did not reuse origin's own pull request"
  [ "$(gh_calls '^pr create')" = 1 ] || fail "not exactly one pull request was opened: $(cat "$D/calls/gh")"

  local state
  for state in CLOSED MERGED; do
    project 'automatic (chosen)'
    other_repository_pr 9 story/s01-a "$state"
    land
    push
    [ "$STATUS" -eq 0 ] || fail "another repository's $state pull request gave exit $STATUS: $OUT"
    is '.state == "merged" and .pull_request.created == true' "another repository's $state pull request decided the ship"
    [ "$(gh_calls '^pr merge https://github.com/acme/project/pull/9 ')" = 0 ] || fail "another repository's pull request was merged"
  done

  # A pull request that does not say where its head lives is not used.
  project 'human (chosen)'
  jq -n '{number: 9, url: "https://github.com/acme/project/pull/9", state: "OPEN", headRefName: "story/s01-a", isCrossRepository: null}' \
    > "$D/prs/9.json"
  land
  push
  [ "$STATUS" -eq 1 ] || fail "a pull request of unknown origin gave exit $STATUS: $OUT"
  is '.error == "pr-unreadable"' "a pull request of unknown origin is not pr-unreadable"
  [ "$(forge_writes)" = 0 ] || fail "a pull request of unknown origin let the forge write: $(cat "$D/calls/gh")"

  # The draft of the rewrite is origin's own as well.
  project 'automatic (forge)'
  collaborative_github
  other_repository_pr 9 framing/ship-confirmation OPEN
  land
  push
  [ "$STATUS" -eq 0 ] || fail "po ship push beside another repository's draft exited $STATUS: $OUT"
  is '.rewrite.url != null and .rewrite.url != "https://github.com/acme/project/pull/9"' "another repository's draft was reported as the rewrite"
  [ "$(grep '^pr create' "$D/calls/gh" | grep -cF -- '--head framing/ship-confirmation')" = 1 ] || fail "origin's own draft was not opened"
}

test_pull_request_on_another_commit_is_not_reported_ready() {
  need_po
  project 'human (chosen)'
  pinned_pr 7 story/s01-a OPEN
  land
  push
  [ "$STATUS" -eq 1 ] || fail "an open pull request on another commit gave exit $STATUS: $OUT"
  is '.error == "pr-head-differs"' "an open pull request on another commit was reported ready"
  [ "$(forge_writes)" = 0 ] || fail "an open pull request on another commit let the forge write"

  project 'automatic (chosen)'
  pinned_pr 7 story/s01-a MERGED
  land
  push
  [ "$STATUS" -eq 1 ] || fail "a pull request merged on another commit gave exit $STATUS: $OUT"
  is '.error == "pr-head-differs"' "a pull request merged on another commit passed for the landing"
  [ "$(forge_writes)" = 0 ] || fail "a pull request merged on another commit let the forge write"

  project 'automatic (forge)'
  collaborative_github
  pinned_pr 7 framing/ship-confirmation OPEN
  land
  push
  [ "$STATUS" -eq 0 ] || fail "po ship push beside a draft on another commit exited $STATUS: $OUT"
  is '.rewrite.url == null and .rewrite.refused == true and .rewrite.next == "write-line"' \
    "a draft on another commit was reported as the rewrite"
}

test_ship_words_go_down() {
  local words
  words="$(LC_ALL=C wc -w < "$METHOD/commands/po-ship.md")"
  [ "$words" -le 1998 ] || fail "po-ship.md holds $words words, more than 1998"
}
