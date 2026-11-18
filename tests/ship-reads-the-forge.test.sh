#!/usr/bin/env bash
# s192 — the task tests of `po ship forge`, against the oracle's doubles: no test reaches a forge.

source "$(dirname "${BASH_SOURCE[0]}")/ship-reads-the-forge.oracle.test.sh"
unset -f test_verdict_follows_the_three_signals test_absence_is_not_an_error test_chosen_is_never_rewritten \
  test_token_never_travels test_version_goes_up

test_github_read_is_pinned_and_curl_skips_curlrc() {
  need_po
  project 'automatic (forge)'
  solo_github
  forge_read
  is '.verdict == "solo"' "the GitHub reading through gh did not read the forge"
  grep -q '^api ' "$D/calls/gh" || fail "gh api was never called"
  ! grep '^api ' "$D/calls/gh" | grep -vqF -- '--hostname github.com' \
    || fail "a gh api call is not pinned to github.com: $(cat "$D/calls/gh")"

  project 'automatic (forge)'
  solo_github
  GH_TOKEN=s192-witness GH_MISSING=1 forge_read
  is '.verdict == "solo"' "the GitHub reading through curl did not read the forge"
  [ -s "$D/calls/curl" ] || fail "curl was never called"
  ! grep -vq '^-q ' "$D/calls/curl" || fail "a curl call does not start with -q: $(cat "$D/calls/curl")"

  project 'automatic (forge)' https://code.example.org/acme/project.git
  FORGEJO_HOST=code.example.org forge_read
  is '.forge == "forgejo"' "the Forgejo probe did not recognise the forge"
  ! grep -vq '^-q ' "$D/calls/curl" || fail "the probe does not start with -q: $(cat "$D/calls/curl")"
}

test_full_collaborator_page_is_unreadable() {
  need_po
  project 'automatic (forge)'
  solo_github
  answer repos/acme/project/collaborators 200 \
    "$(jq -cn '[range(100) | {login: "reader\(.)", permissions: {push: false}}]')"
  forge_read
  is '.verdict == "unreadable" and .signals.writer == null' "a full page without another writer was read as solo"
  is 'any(.failed[]; .signal == "writer" and .reason == "list-truncated")' "the truncated list is not named"

  local total
  for total in 2 -; do
    project 'automatic (forge)' https://code.example.org/acme/project.git
    answering_cli
    answer user 200 '{"login":"me"}'
    answer repos/acme/project/collaborators 200 '[{"login":"dev"}]'
    answer repos/acme/project/collaborators/dev/permission 200 '{"permission":"read"}'
    answer repos/acme/project/branch_protections 200 '[]'
    printf 'repos/acme/project/collaborators\t%s\n' "$total" > "$D/totals"
    FORGEJO_HOST=code.example.org forge_read
    is '.forge == "forgejo" and .verdict == "unreadable" and .signals.writer == null' \
      "a Forgejo page whose total is $total was read as complete"
    is 'any(.failed[]; .signal == "writer" and .reason == "list-truncated")' "the Forgejo list cut short is not named"
  done
}

test_target_branch_is_one_path_segment() {
  need_po
  local target='rel#{1}%' encoded='rel%23%7B1%7D%25' via
  for via in gh curl; do
    project 'automatic (forge)'
    solo_github
    git -C "$F" update-ref "refs/remotes/origin/$target" main
    answer "repos/acme/project/branches/$encoded/protection" 200 \
      '{"required_pull_request_reviews":{"required_approving_review_count":1}}'
    answer "repos/acme/project/rules/branches/$encoded" 200 '[]'
    if [ "$via" = gh ]; then forge_read --target "$target"
    else GH_TOKEN=s192-witness GH_MISSING=1 forge_read --target "$target"; fi
    is '.verdict == "collaborative" and .signals.protection == true' \
      "through $via, the target branch did not reach its own protection call"
  done
  ! grep -vqF -- '--globoff' "$D/calls/curl" || fail "a curl call may expand globs: $(cat "$D/calls/curl")"
}

test_access_failure_names_its_call() {
  need_po
  project 'automatic (forge)'
  GH_TOKEN='' GITHUB_TOKEN='' GH_MISSING=1 forge_read
  is '.verdict == "unreadable" and ([.failed[] | select(.reason == "no-cli-no-token") | .call] == ["gh auth status", "gh auth status"])' \
    "a GitHub reading without gh nor token does not name gh auth status"
  project 'automatic (forge)' https://gitlab.example.org/acme/project.git
  forge_read
  is '[.failed[] | select(.reason == "no-glab-login") | .call] == ["glab auth status", "glab auth status"]' \
    "a GitLab reading without a glab login does not name glab auth status"
}

test_setup_reads_with_target_only() {
  need_po
  project 'automatic (forge)'
  solo_github
  git -C "$F" rm -q AGENTS.local.md && git -C "$F" commit -qm "no settings yet"
  git -C "$F" update-ref refs/remotes/origin/main main
  mkdir -p "$F/.polype" && echo 1.0.0 > "$F/.polype/version"
  forge_read --target main
  [ "$STATUS" -eq 0 ] || fail "po ship forge --target exited $STATUS: $OUT"
  one_object "po ship forge --target main"
  is '.verdict == "solo" and .line == null and .effective == null and .rewrite == null' \
    "a project without AGENTS.local.md is not read with --target"
  forge_read
  [ "$STATUS" -eq 2 ] || fail "without Target branch nor --target, po ship forge exited $STATUS"
  is '.error == "missing-setting"' "a missing Target branch is not refused as missing-setting"
}

test_ship_refuses_unknown_step_and_option() {
  need_po
  project 'automatic (forge)'
  local args want
  while IFS='|' read -r args want; do
    # shellcheck disable=SC2086
    forge_read $args
    [ "$STATUS" -eq 2 ] || fail "po ship forge $args exited $STATUS"
    is ".error == \"$want\"" "po ship forge $args is not refused as $want"
  done <<'EOF'
--bogus|unknown-option
--target|usage
extra|usage
EOF
  local out
  out="$(cd "$F" && "$PO" ship land </dev/null)" && fail "po ship land was accepted"
  [ "$(jq -r .error <<< "$out")" = usage ] || fail "po ship land is not a usage refusal: $out"
  out="$(cd "$F" && "$PO" ship </dev/null)" && fail "po ship without a step was accepted"
  [ "$(jq -r .error <<< "$out")" = usage ] || fail "po ship without a step is not a usage refusal: $out"
  out="$(cd "$SCRATCH/home" && "$PO" ship forge </dev/null)" && fail "po ship forge outside a project was accepted"
  [ "$(jq -r .error <<< "$out")" = not-a-project ] || fail "po ship forge outside a project: $out"
  [ -z "$(cat "$D/calls/gh" 2>/dev/null)" ] || fail "a refusal still asked the forge"
}

# glab and tea that answer, from the same responses as the GitHub doubles; a list carries the
# `X-Total-Count` header of its length, or the total `$D/totals` gives for its path (`-` for none).
answering_cli() {
  cat > "$D/bin/counted" <<'EOF'
#!/usr/bin/env bash
out="$("$DOUBLES/bin/respond" "$@")"; code=$?
total="$(awk -F'\t' -v p="${1%%\?*}" '$1 == p {t = $2} END {print t}' "$DOUBLES/totals" 2>/dev/null)"
[ -n "$total" ] || total="$(tail -n 1 <<< "$out" | jq 'if type == "array" then length else empty end' 2>/dev/null)"
if [ -n "$2" ] && [ -n "$total" ] && [ "$total" != - ]; then sed "1a X-Total-Count: $total" <<< "$out"
else printf '%s\n' "$out"; fi
exit "$code"
EOF
  chmod +x "$D/bin/counted"
  cat > "$D/bin/glab" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DOUBLES/calls/glab"
[ "$1" = auth ] && exit 0
path="" skip="" include=""
for a in "${@:2}"; do
  if [ -n "$skip" ]; then skip=""; continue; fi
  case "$a" in -i) include=1 ;; --hostname) skip=1 ;; -*) ;; *) path="$a" ;; esac
done
exec "$DOUBLES/bin/counted" "$path" "$include"
EOF
  cat > "$D/bin/tea" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DOUBLES/calls/tea"
case " $* " in
  *" --help "*) exit 0 ;;
  *" logins list "*) echo '[{"name":"work","url":"https://code.example.org"}]'; exit 0 ;;
esac
path="" skip="" include=""
for a in "${@:2}"; do
  if [ -n "$skip" ]; then skip=""; continue; fi
  case "$a" in -i) include=1 ;; --login) skip=1 ;; -*) ;; *) path="$a" ;; esac
done
exec "$DOUBLES/bin/counted" "$path" "$include"
EOF
}

test_gitlab_and_forgejo_signals() {
  need_po
  project 'automatic (forge)' https://gitlab.example.org/acme/project.git
  answering_cli
  answer user 200 '{"username":"me"}'
  answer 'projects/:id/members/all' 200 '[{"username":"me","access_level":50},{"username":"dev","access_level":20}]'
  answer 'projects/:id/approval_rules' 200 '[]'
  forge_read
  is '.forge == "gitlab" and .verdict == "solo"' "a GitLab member below 30 was counted"
  answer 'projects/:id/members/all' 200 '[{"username":"me","access_level":50},{"username":"dev","access_level":30}]'
  forge_read
  is '.verdict == "collaborative" and .signals.writer == true' "a GitLab member at 30 does not make it collaborative"
  grep -q -- '--hostname gitlab.example.org' "$D/calls/glab" || fail "glab is not pinned to the host of origin"

  project 'automatic (forge)' https://code.example.org/acme/project.git
  answering_cli
  answer user 200 '{"login":"me"}'
  answer repos/acme/project/collaborators 200 '[{"login":"dev"}]'
  answer repos/acme/project/collaborators/dev/permission 200 '{"permission":"read"}'
  answer repos/acme/project/branch_protections 200 '[{"rule_name":"other","required_approvals":1}]'
  FORGEJO_HOST=code.example.org forge_read
  is '.forge == "forgejo" and .verdict == "solo"' "a Forgejo reader or another branch's protection was counted"
  answer repos/acme/project/collaborators/dev/permission 200 '{"permission":"write"}'
  FORGEJO_HOST=code.example.org forge_read
  is '.verdict == "collaborative" and .signals.writer == true' "a Forgejo write collaborator does not make it collaborative"
  grep -q -- '--login work' "$D/calls/tea" || fail "tea does not use the login of the host of origin"
}
