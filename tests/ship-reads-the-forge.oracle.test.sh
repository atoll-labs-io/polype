#!/usr/bin/env bash
# s192 — the oracle of the story: `po ship forge` reads the forge and gives the effective
# `Ship confirmation`. Every forge tool is a double first on PATH and named by PO_GH, PO_CURL,
# PO_GLAB and PO_TEA: no test reaches a real forge. ship_command_reads_the_value speaks to a model
# and is judged in review.

need_po() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO (tests/run.sh builds it before the suite)"
}

# The one place the command's shape is written: `po ship forge`, run from the project.
forge_read() {
  STATUS=0
  OUT="$(cd "$F" && env PATH="$D/bin:$PATH" HOME="$SCRATCH/home" GH_CONFIG_DIR="$SCRATCH/home/gh" \
    PO_GH="$D/bin/gh" PO_CURL="$D/bin/curl" PO_GLAB="$D/bin/glab" PO_TEA="$D/bin/tea" \
    "$PO" ship forge "$@" 2>"$SCRATCH/stderr" </dev/null)" || STATUS=$?
  ERR="$(cat "$SCRATCH/stderr")"
}

one_object() {
  [ "$(jq -s 'length' <<< "$OUT" 2>/dev/null)" = 1 ] || fail "$1 did not print exactly one JSON value: $OUT"
  jq -e '.contract == 1' <<< "$OUT" >/dev/null || fail "$1 does not carry contract 1: $OUT"
}

is() { jq -e "$1" <<< "$OUT" >/dev/null || fail "$2: $OUT"; }

# project <Ship confirmation line> [<origin url>]: a scratch project whose origin/main is its main.
project() {
  SCRATCH="$(cd "$(mktemp -d)" && pwd -P)"
  SCRATCHES="${SCRATCHES:-} $SCRATCH"
  trap 'rm -rf $SCRATCHES' EXIT
  F="$SCRATCH/project" D="$SCRATCH/doubles"
  mkdir -p "$F" "$D/bin" "$D/calls" "$SCRATCH/home"
  : > "$D/responses"
  git -C "$F" init -q -b main
  git -C "$F" config user.email test@example.com
  git -C "$F" config user.name test
  git -C "$F" config commit.gpgsign false
  printf 'Target branch: main\nMerge mode: pr\nShip confirmation: %s\n' "$1" > "$F/AGENTS.local.md"
  git -C "$F" add -A && git -C "$F" commit -qm base
  git -C "$F" remote add origin "${2:-https://github.com/acme/project.git}"
  git -C "$F" update-ref refs/remotes/origin/main main
  doubles
}

# answer <api path> <status> <json body>: what the GitHub API answers for that path, query
# dropped; the last answer given for a path wins.
answer() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$D/responses"; }

# solo_github: the user alone may write, no protection, no ruleset.
solo_github() {
  answer user 200 '{"login":"me"}'
  answer repos/acme/project/collaborators 200 '[{"login":"me","permissions":{"push":true,"admin":true}},{"login":"reader","permissions":{"push":false}}]'
  answer repos/acme/project/branches/main/protection 404 '{"message":"Branch not protected"}'
  answer repos/acme/project/rules/branches/main 200 '[]'
}

# codeowners_on_origin <line>: a CODEOWNERS that origin/main holds and the local main does not.
codeowners_on_origin() {
  git -C "$F" checkout -q -b owners
  mkdir -p "$F/.github" && printf '%s\n' "$1" > "$F/.github/CODEOWNERS"
  git -C "$F" add -A && git -C "$F" commit -qm owners
  git -C "$F" update-ref refs/remotes/origin/main owners
  git -C "$F" checkout -q main && git -C "$F" branch -q -D owners
}

doubles() {
  # The GitHub API as gh and curl see it: status line and headers only under -i, as gh prints them.
  cat > "$D/bin/respond" <<'EOF'
#!/usr/bin/env bash
path="${1%%\?*}"; path="${path#/}"
line="$(awk -F'\t' -v p="$path" '$1 == p {l = $0} END {print l}' "$DOUBLES/responses")"
if [ -n "$line" ]; then status="$(cut -f2 <<< "$line")"; body="$(cut -f3- <<< "$line")"
else status=404; body='{"message":"Not Found"}'; fi
[ -z "$2" ] || printf 'HTTP/2.0 %s X\nContent-Type: application/json\r\n\r\n' "$status"
printf '%s\n' "$body"
[ "$status" -lt 300 ] || { printf 'gh: X (HTTP %s)\n' "$status" >&2; exit 1; }
EOF
  cat > "$D/bin/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DOUBLES/calls/gh"
[ -z "${GH_MISSING:-}" ] || exit 127
case "${1:-}" in
  auth) exit 0 ;;
  api) ;;
  *) exit 1 ;;
esac
[ -z "${GH_DOWN:-}" ] || { echo "error connecting to api.github.com" >&2; exit 1; }
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
exec "$DOUBLES/bin/respond" "$path" "$include"
EOF
  cat > "$D/bin/curl" <<'EOF'
#!/usr/bin/env bash
n="$(date +%s%N)"
printf '%s\n' "$*" >> "$DOUBLES/calls/curl"
cat > "$DOUBLES/calls/curl-stdin.$n"
url="" include=""
for a in "$@"; do
  case "$a" in -i|--include) include=1 ;; http://*|https://*) url="$a" ;; esac
done
printf '%s\n' "$url" > "$DOUBLES/calls/curl-url.$n"
case "$url" in
  https://api.github.com/*) exec "$DOUBLES/bin/respond" "${url#https://api.github.com/}" "$include" ;;
  */api/v1/version)
    host="${url#https://}"; host="${host%%/*}"
    [ "$host" = "${FORGEJO_HOST:-}" ] || exit 7
    [ -z "$include" ] || printf 'HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n'
    echo '{"version":"9.0.0"}' ;;
  *) exit 7 ;;
esac
EOF
  # glab and tea note any token variable they were launched with, then cannot reach their forge.
  cat > "$D/bin/glab" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DOUBLES/calls/glab"
for v in GITLAB_TOKEN GITLAB_ACCESS_TOKEN OAUTH_TOKEN; do [ -z "${!v+x}" ] || echo "glab $v" >> "$DOUBLES/calls/leaks"; done
exit 1
EOF
  cat > "$D/bin/tea" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DOUBLES/calls/tea"
for v in GITEA_TOKEN TEA_HOST GITEA_INSTANCE_URL; do [ -z "${!v+x}" ] || echo "tea $v" >> "$DOUBLES/calls/leaks"; done
case " $* " in *" --help "*) echo "Usage: tea api [options] <endpoint>"; exit 0 ;; esac
exit 1
EOF
  chmod +x "$D/bin/"*
  export DOUBLES="$D"
}

test_verdict_follows_the_three_signals() {
  need_po

  # Solo: the user is the only writer, CODEOWNERS names only them, nothing requires an approval.
  project 'automatic (forge)'
  solo_github
  codeowners_on_origin '* @me'
  forge_read
  [ "$STATUS" -eq 0 ] || fail "po ship forge exited $STATUS: $OUT $ERR"
  one_object "po ship forge"
  is '.forge == "github" and .verdict == "solo"' "a solo repository is not read as solo"
  is '.signals.writer == false and .signals.codeowners == false and .signals.protection == false' "the three signals of a solo repository are not all false"
  is '.effective == "automatic"' "a (forge) line on a solo repository is not automatic"
  grep -q 'repos/acme/project/collaborators' "$D/calls/gh" || fail "the collaborators were not asked: $(cat "$D/calls/gh")"

  # Another writer.
  project 'automatic (chosen)'
  solo_github
  answer repos/acme/project/collaborators 200 '[{"login":"me","permissions":{"push":true}},{"login":"other","permissions":{"push":true}}]'
  forge_read
  is '.verdict == "collaborative" and .signals.writer == true' "another writer does not make the repository collaborative"
  is '.effective == "human"' "a collaborative repository is not human whatever the line says"

  # A CODEOWNERS on origin/main naming someone else; a team counts too.
  project 'automatic (forge)'
  solo_github
  codeowners_on_origin '* @acme/reviewers'
  forge_read
  is '.verdict == "collaborative" and .signals.codeowners == true' "a CODEOWNERS naming a team on origin/main does not make the repository collaborative"

  # CODEOWNERS is read on origin/<Target branch>, never on the local checkout.
  project 'automatic (forge)'
  solo_github
  mkdir -p "$F/.github" && printf '* @other\n' > "$F/.github/CODEOWNERS"
  git -C "$F" add -A && git -C "$F" commit -qm "local owners"
  forge_read
  is '.verdict == "solo" and .signals.codeowners == false' "a CODEOWNERS absent from origin/main was counted"

  # A branch protection requiring an approval, then a ruleset requiring one.
  project 'automatic (forge)'
  solo_github
  answer repos/acme/project/branches/main/protection 200 '{"required_pull_request_reviews":{"required_approving_review_count":1}}'
  forge_read
  is '.verdict == "collaborative" and .signals.protection == true' "a protection requiring an approval does not make the repository collaborative"

  project 'automatic (forge)'
  solo_github
  answer repos/acme/project/rules/branches/main 200 '[{"type":"pull_request","parameters":{"required_approving_review_count":2}}]'
  forge_read
  is '.verdict == "collaborative" and .signals.protection == true' "a ruleset requiring an approval does not make the repository collaborative"
}

test_absence_is_not_an_error() {
  need_po

  # A 404 on the protection and the plan's 403 on the ruleset both mean "no protection".
  project 'automatic (forge)'
  solo_github
  answer repos/acme/project/rules/branches/main 403 '{"message":"Upgrade to GitHub Pro or make this repository public to enable this feature."}'
  forge_read
  [ "$STATUS" -eq 0 ] || fail "po ship forge exited $STATUS on a 404 and a plan 403: $OUT"
  is '.verdict == "solo" and .signals.protection == false' "a 404 or the plan's 403 was not read as an absence"

  # Only the answers ADR-0079 names are an absence: a rights 403 on the protection, or a 404 on the
  # collaborators, leaves that signal unreadable, never solo.
  project 'automatic (forge)'
  solo_github
  answer repos/acme/project/branches/main/protection 403 '{"message":"Must have admin rights to Repository."}'
  forge_read
  [ "$STATUS" -eq 0 ] || fail "po ship forge exited $STATUS on a rights 403: $OUT"
  is '.verdict == "unreadable" and .signals.protection == null and .rewrite == null' "a rights 403 on the protection was read as an absence"

  project 'automatic (forge)'
  solo_github
  answer repos/acme/project/collaborators 404 '{"message":"Not Found"}'
  forge_read
  is '.verdict == "unreadable" and .signals.writer == null' "a 404 on the collaborators was read as an absence"

  # A forge that cannot be reached is unreadable, never solo, and the line's value stands.
  project 'human (chosen)'
  solo_github
  GH_DOWN=1 forge_read
  [ "$STATUS" -eq 0 ] || fail "po ship forge exited $STATUS on an unreachable forge: $OUT"
  one_object "po ship forge on an unreachable forge"
  is '.verdict == "unreadable"' "an unreachable forge is not unreadable"
  is '.effective == "human" and .rewrite == null' "the line's value does not stand on an unreadable forge"
  is '(.failed | length) > 0 and all(.failed[]; (.call | type) == "string" and (.reason | type) == "string")' \
    "an unreadable forge does not name the call that failed and why"

  project 'automatic (forge)'
  solo_github
  GH_DOWN=1 forge_read
  is '.verdict == "unreadable" and .effective == "automatic" and .rewrite == null' "an unreadable forge moved a (forge) line"

  # One positive signal is enough, even with another one unreadable.
  project 'automatic (forge)'
  solo_github
  codeowners_on_origin '* @other'
  answer repos/acme/project/branches/main/protection 500 '{"message":"Server Error"}'
  forge_read
  is '.verdict == "collaborative"' "a positive signal beside an unreadable one is not collaborative"

  # No origin: unreadable.
  project 'automatic (forge)'
  git -C "$F" remote remove origin
  forge_read
  [ "$STATUS" -eq 0 ] || fail "po ship forge exited $STATUS without an origin: $OUT"
  is '.verdict == "unreadable" and .forge == null' "a repository without origin is not unreadable"
}

test_chosen_is_never_rewritten() {
  need_po
  local line verdict effective rewrite before_file before_refs
  while IFS='|' read -r line verdict effective rewrite; do
    project "$line"
    solo_github
    [ "$verdict" = solo ] || answer repos/acme/project/collaborators 200 '[{"login":"me","permissions":{"push":true}},{"login":"other","permissions":{"push":true}}]'
    before_file="$(cksum < "$F/AGENTS.local.md")"
    before_refs="$(git -C "$F" for-each-ref --format='%(refname) %(objectname)')"
    forge_read
    [ "$STATUS" -eq 0 ] || fail "po ship forge exited $STATUS for '$line': $OUT"
    is ".verdict == \"$verdict\"" "'$line' was not read $verdict"
    is ".effective == \"$effective\"" "'$line' on a $verdict repository is not $effective"
    if [ "$rewrite" = null ]; then
      is '.rewrite == null' "'$line' on a $verdict repository proposes a rewrite"
    else
      is ".rewrite == \"$rewrite\"" "'$line' on a $verdict repository does not propose '$rewrite'"
    fi
    [ "$(cksum < "$F/AGENTS.local.md")" = "$before_file" ] || fail "po ship forge changed AGENTS.local.md for '$line'"
    [ "$(git -C "$F" for-each-ref --format='%(refname) %(objectname)')" = "$before_refs" ] \
      || fail "po ship forge moved a ref for '$line'"
    [ -z "$(git -C "$F" status --porcelain)" ] || fail "po ship forge left a change for '$line': $(git -C "$F" status --porcelain)"
    ! grep -vE '^(api|auth) ' "$D/calls/gh" | grep -q . || fail "gh was asked something other than api or auth: $(cat "$D/calls/gh")"
    ! grep -qE '(^| )(-X|--method)( |$)' "$D/calls/gh" || fail "gh was asked to send something: $(cat "$D/calls/gh")"
  done <<'EOF'
automatic (chosen)|collaborative|human|null
human (chosen)|solo|human|null
automatic (chosen)|solo|automatic|null
automatic (forge)|collaborative|human|human (forge)
automatic|collaborative|human|human (forge)
human (forge)|solo|automatic|automatic (forge)
human|solo|automatic|automatic (forge)
automatic|solo|automatic|null
human (forge)|collaborative|human|null
EOF
}

test_token_never_travels() {
  need_po
  local tok vars leaked
  tok="s192-sentinel-$$-$RANDOM"
  vars=(GH_TOKEN="$tok" GITHUB_TOKEN="$tok" GITLAB_TOKEN="$tok" GITLAB_ACCESS_TOKEN="$tok" OAUTH_TOKEN="$tok"
        GITEA_TOKEN="$tok" TEA_HOST="$tok" GITEA_INSTANCE_URL="$tok")

  # GitHub through gh: the token stays in gh's environment, never in an argument or the output.
  project 'automatic (forge)' "https://x-access:$tok@github.com/acme/project.git"
  solo_github
  STATUS=0; OUT="$(cd "$F" && env "${vars[@]}" PATH="$D/bin:$PATH" HOME="$SCRATCH/home" PO_GH="$D/bin/gh" \
    PO_CURL="$D/bin/curl" PO_GLAB="$D/bin/glab" PO_TEA="$D/bin/tea" "$PO" ship forge 2>&1 </dev/null)" || STATUS=$?
  one_object "po ship forge with a token in the environment"
  ! grep -qF "$tok" <<< "$OUT" || fail "the output carries a token"
  ! grep -qF "$tok" "$D/calls/gh" 2>/dev/null || fail "a gh argument carries a token"

  # GitHub without gh: curl reads the token from its standard input, never from an argument.
  project 'automatic (forge)'
  solo_github
  STATUS=0; OUT="$(cd "$F" && env "${vars[@]}" GH_MISSING=1 PATH="$D/bin:$PATH" HOME="$SCRATCH/home" \
    PO_GH="$SCRATCH/no-gh-here" PO_CURL="$D/bin/curl" PO_GLAB="$D/bin/glab" PO_TEA="$D/bin/tea" \
    "$PO" ship forge 2>&1 </dev/null)" || STATUS=$?
  one_object "po ship forge without gh"
  is '.verdict == "solo"' "the GitHub reading through curl and GH_TOKEN did not read the forge"
  ! grep -qF "$tok" <<< "$OUT" || fail "the output carries a token"
  [ -s "$D/calls/curl" ] || fail "curl was never asked while gh is missing"
  ! grep -qF "$tok" "$D/calls/curl" || fail "a curl argument carries a token: $(cat "$D/calls/curl")"
  local stdin url
  for stdin in "$D"/calls/curl-stdin.*; do
    grep -qF "$tok" "$stdin" || continue
    url="$(cat "${stdin/curl-stdin/curl-url}")"
    case "$url" in https://api.github.com/*) ;; *) fail "the token went to $url" ;; esac
  done
  grep -lF "$tok" "$D"/calls/curl-stdin.* >/dev/null 2>&1 || fail "no curl call carried the token in a header"

  # GitLab and Forgejo: their CLI runs without its token variables; the probe carries no token.
  local origin
  for origin in https://gitlab.example.org/acme/project.git https://code.example.org/acme/project.git; do
    project 'automatic (forge)' "$origin"
    STATUS=0; OUT="$(cd "$F" && env "${vars[@]}" FORGEJO_HOST=code.example.org PATH="$D/bin:$PATH" \
      HOME="$SCRATCH/home" PO_GH="$D/bin/gh" PO_CURL="$D/bin/curl" PO_GLAB="$D/bin/glab" PO_TEA="$D/bin/tea" \
      "$PO" ship forge 2>&1 </dev/null)" || STATUS=$?
    one_object "po ship forge on $origin"
    ! grep -qF "$tok" <<< "$OUT" || fail "the output carries a token on $origin"
    leaked="$(cat "$D/calls/leaks" 2>/dev/null || true)"
    [ -z "$leaked" ] || fail "a forge CLI was launched with a token variable on $origin: $leaked"
    case "$origin" in
      *gitlab*) [ -s "$D/calls/glab" ] || fail "glab was never asked about $origin" ;;
      *) [ -s "$D/calls/tea" ] || fail "tea was never asked about $origin" ;;
    esac
    ! grep -qF "$tok" "$D"/calls/curl* 2>/dev/null || fail "a curl call carried a token on $origin"
    ! grep -qE '(^| )(-H|--header|-u|--user|-n|--netrc)( |$)' "$D/calls/curl" 2>/dev/null \
      || fail "the probe of $origin carries a header or credentials: $(cat "$D/calls/curl")"
    is '.verdict == "unreadable"' "a forge whose CLI cannot answer is not unreadable on $origin"
  done
}

# The three places that carry po's version agree, a minor step above the 0.7.0 of s191's start point.
test_version_goes_up() {
  local toml lock polype
  toml="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$ROOT/po/Cargo.toml" | head -n 1)"
  lock="$(awk '$0 == "name = \"po\"" {getline; print; exit}' "$ROOT/po/Cargo.lock" | sed -n 's/^version = "\(.*\)"$/\1/p')"
  polype="$(sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$ROOT/bin/polype")"
  [ -n "$toml" ] && [ "$toml" = "$lock" ] && [ "$toml" = "$polype" ] \
    || fail "po's version differs: po/Cargo.toml $toml, po/Cargo.lock $lock, bin/polype $polype"
  [ "$(printf '0.8.0\n%s\n' "$toml" | sort -V | head -n 1)" = 0.8.0 ] \
    || fail "po's version $toml is not a minor step above 0.7.0"
}
