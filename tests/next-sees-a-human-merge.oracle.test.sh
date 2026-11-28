#!/usr/bin/env bash
# s218 — the oracle of the story: after a person merges a lane's pull request, `po next --remote`
# sees the landing without anyone fetching first (#437); `merge waiting` follows the effective
# `Ship confirmation` that `po ship forge` computes, not the written line (#389); po's version goes
# up (ADR-0122). origin is named by a github.com URL that git rewrites to a local bare repository
# (insteadOf), and gh and curl are doubles: no test reaches a real forge.

# merge_project <Ship confirmation line>: a project under `Merge mode: pr` whose origin is a bare
# repository, with one lane s01-alpha whose review allows the ship and whose branch is on origin, as
# after `po ship push` opened its pull request. Sets F, W, ORIGIN, SCRATCH and the forge doubles.
merge_project() {
  # shellcheck source=/dev/null
  source "$ROOT/tests/driver-next-action.oracle.test.sh"
  project
  setting 'Merge mode' pr
  setting 'Ship confirmation' "$1"
  story s01-alpha command - 'src/a/'
  start
  ORIGIN="$SCRATCH/origin.git"
  git init -q --bare -b main "$ORIGIN"
  git -C "$F" remote add origin https://github.com/acme/app.git
  git -C "$F" config "url.$ORIGIN.insteadOf" https://github.com/acme/app.git
  git -C "$F" push -q origin main
  recorded_lane s01-alpha
  review_in s01-alpha complete 0 yes
  git -C "$W" push -q origin story/s01-alpha
  forge_doubles
}

# answer <api path> <status> <json body>: what the GitHub API answers for that path, query dropped;
# any other path answers 404.
answer() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$SCRATCH/responses"; }

# solo_forge: the user alone may write, no protection, no ruleset.
solo_forge() {
  answer user 200 '{"login":"me"}'
  answer repos/acme/app/collaborators 200 '[{"login":"me","permissions":{"push":true,"admin":true}}]'
  answer repos/acme/app/branches/main/protection 404 '{"message":"Branch not protected"}'
  answer repos/acme/app/rules/branches/main 200 '[]'
}

forge_doubles() {
  : > "$SCRATCH/responses"
  cat > "$SCRATCH/gh" <<EOF
#!/usr/bin/env bash
[ "\${1:-}" = api ] || exit 0
path="" skip="" include=""
for a in "\${@:2}"; do
  if [ -n "\$skip" ]; then skip=""; continue; fi
  case "\$a" in
    -i) include=1 ;;
    --hostname) skip=1 ;;
    -*) ;;
    *) path="\$a" ;;
  esac
done
path="\${path%%\\?*}"
line="\$(awk -F'\t' -v p="\$path" '\$1 == p {l = \$0} END {print l}' "$SCRATCH/responses")"
if [ -n "\$line" ]; then status="\$(cut -f2 <<< "\$line")"; body="\$(cut -f3- <<< "\$line")"
else status=404; body='{"message":"Not Found"}'; fi
[ -z "\$include" ] || printf 'HTTP/2.0 %s X\r\nContent-Type: application/json\r\n\r\n' "\$status"
printf '%s\n' "\$body"
[ "\$status" -lt 300 ] || exit 1
EOF
  printf '#!/usr/bin/env bash\nexit 7\n' > "$SCRATCH/curl"
  chmod +x "$SCRATCH/gh" "$SCRATCH/curl"
  export PO_GH="$SCRATCH/gh" PO_CURL="$SCRATCH/curl"
  unset GH_TOKEN GITHUB_TOKEN
}

# next_is <label> <action> <reason> [--remote]: one `po next`, s01-alpha expected to get that entry.
next_is() {
  local label="$1" action="$2" reason="$3"
  shift 3
  po_in "$F" next "$@"
  next_shape "$label"
  : > "$SCRATCH/expect"
  expect_lane s01-alpha "$action" "$reason"
  check_expectations
  [ -z "$BAD" ] || fail "$label: $BAD"
}

test_human_merge_is_seen() {
  ( merge_project 'human (chosen)'
    next_is "po next --remote before the merge" wait "merge waiting" --remote

    # A person merges the pull request on the forge: the landing commit reaches origin's main
    # from another clone, so nothing in the project knows of it yet.
    git clone -q "$ORIGIN" "$SCRATCH/person"
    git -C "$SCRATCH/person" config user.email person@example.com
    git -C "$SCRATCH/person" config user.name person
    git -C "$SCRATCH/person" merge -q --squash origin/story/s01-alpha >/dev/null
    git -C "$SCRATCH/person" commit -qm "s01-alpha: s01-alpha"
    git -C "$SCRATCH/person" push -q origin main

    # Without the option, po reads only what is local and writes nothing.
    local before
    before="$(git -C "$F" rev-parse refs/remotes/origin/main)"
    next_is "po next without --remote" wait "merge waiting"
    [ "$(git -C "$F" rev-parse refs/remotes/origin/main)" = "$before" ] \
      || fail "po next without --remote moved origin/main: it fetched"

    next_is "po next --remote after a human merge" ship landed --remote
  ) || exit 1
}

test_effective_confirmation_drives_merge_waiting() {
  # The line says automatic, but a CODEOWNERS naming a team makes the repository collaborative:
  # the effective value is human and the lane waits for the person's merge.
  ( merge_project automatic
    solo_forge
    git clone -q "$ORIGIN" "$SCRATCH/owners"
    git -C "$SCRATCH/owners" config user.email owner@example.com
    git -C "$SCRATCH/owners" config user.name owner
    mkdir -p "$SCRATCH/owners/.github"
    echo '* @acme/reviewers' > "$SCRATCH/owners/.github/CODEOWNERS"
    git -C "$SCRATCH/owners" add -A
    git -C "$SCRATCH/owners" commit -qm "chore: code owners"
    git -C "$SCRATCH/owners" push -q origin main
    git -C "$F" fetch -q origin
    next_is "po next, line automatic" ship "ship-allowed passes"
    next_is "po next --remote, line automatic on a collaborative forge" wait "merge waiting" --remote
  ) || exit 1

  # The line says human and follows the forge; on a solo forge the effective value is automatic,
  # so nothing waits for a person.
  ( merge_project human
    solo_forge
    next_is "po next, line human" wait "merge waiting"
    next_is "po next --remote, line human (forge) on a solo forge" ship "ship-allowed passes" --remote
  ) || exit 1
}

# The three places that carry po's version agree, and it is above the 0.13.1 that s216 left.
test_version_raised() {
  local toml lock polype
  toml="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$ROOT/po/Cargo.toml" | head -n 1)"
  lock="$(awk '$0 == "name = \"po\"" {getline; print; exit}' "$ROOT/po/Cargo.lock" | sed -n 's/^version = "\(.*\)"$/\1/p')"
  polype="$(sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$ROOT/bin/polype")"
  [ -n "$toml" ] && [ "$toml" = "$lock" ] && [ "$toml" = "$polype" ] \
    || fail "po's version differs: po/Cargo.toml $toml, po/Cargo.lock $lock, bin/polype $polype"
  [ "$toml" != 0.13.1 ] && [ "$(printf '0.13.1\n%s\n' "$toml" | sort -V | head -n 1)" = 0.13.1 ] \
    || fail "po's version $toml is not above 0.13.1"
}
