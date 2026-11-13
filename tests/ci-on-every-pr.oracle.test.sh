#!/usr/bin/env bash
# s159 — the oracle of the story: the suite runs on every pull request through one forge-neutral entry,
# and a project says whether /po-ship waits for the forge's checks (ADR-0105).

WORKFLOW="$ROOT/.github/workflows/ci.yml"

# A setting's first value, read as bin/polype reads it.
setting_of() { sed -n "s/^$2:[[:space:]]*\(.*[^[:space:]]\)[[:space:]]*\$/\1/p" "$1" | head -n 1; }

# The lines nested under key $2 of the YAML text $1, the key's own line first.
child() {
  awk -v k="$2" '
    { match($0, /^ */); ind = RLENGTH }
    on && NF && ind <= base { exit }
    on { print; next }
    $0 ~ ("^ *" k ":") { on = 1; base = ind; print }
  ' <<< "$1"
}

test_ci_entry_runs_the_suite() {
  require_file "$ROOT/bin/po-ci"
  [ -x "$ROOT/bin/po-ci" ] || fail "bin/po-ci is not executable"
  scratch_repo
  local s root plain forged st1=0 st2=0
  s="$SCRATCH"; root="$(cd "$s" && pwd -P)"
  mkdir -p "$s/bin" "$s/deep/er"
  cp -p "$ROOT/bin/po-ci" "$s/bin/po-ci"
  printf '#!/usr/bin/env bash\ntouch "%s/eval-called"\n' "$root" > "$s/bin/po-eval"
  chmod +x "$s/bin/po-eval"
  cat > "$s/AGENTS.local.md" <<'EOF'
# scratch — Polype settings

```
Test budget:       25
```

```
Install:           —
Test:              printf 'suite ran in %s\n' "$(pwd -P)"; printf 'on stderr\n' >&2; exit 3
Typecheck:         —
```
EOF
  plain="$(cd "$s/deep/er" && env -i PATH="$PATH" HOME="$s" "$s/bin/po-ci" 2>&1)" || st1=$?
  forged="$(cd "$s/deep/er" && env -i PATH="$PATH" HOME="$s" CI=true GITHUB_ACTIONS=true GITHUB_TOKEN=x \
    GITHUB_WORKSPACE=/nowhere GITHUB_REF=refs/heads/elsewhere RUNNER_TEMP=/nowhere GITLAB_CI=true \
    CI_PROJECT_DIR=/nowhere GITEA_ACTIONS=true FORGEJO_ACTIONS=true "$s/bin/po-ci" 2>&1)" || st2=$?
  [ "$st1" -eq 3 ] || fail "po-ci exited $st1, the Test command exits 3"
  grep -qxF "suite ran in $root" <<< "$plain" || fail "the Test command did not run from the root: $plain"
  grep -qxF 'on stderr' <<< "$plain" || fail "the Test command's stderr was not passed through: $plain"
  [ "$st2" -eq "$st1" ] && [ "$forged" = "$plain" ] \
    || fail "forge variables changed what po-ci did: exit $st2, output: $forged"
  [ ! -e "$root/eval-called" ] || fail "po-ci launched po-eval"
}

test_workflow_only_calls_the_entry() {
  require_file "$WORKFLOW"
  local target on pr push line value checks=0 jq=0
  target="$(setting_of "$ROOT/AGENTS.local.md" 'Target branch')"
  [ -n "$target" ] || fail "AGENTS.local.md has no Target branch"
  on="$(awk '/^on:/ {f=1; print; next} f && /^[^[:space:]#]/ {f=0} f' "$WORKFLOW")"
  [ -n "$on" ] || fail "the workflow has no top-level on:"
  grep -qE '(^|[^_[:alnum:]])pull_request([^_[:alnum:]]|$)' <<< "$on" || fail "the workflow does not run on pull_request"
  grep -qE '(^|[^_[:alnum:]])push([^_[:alnum:]]|$)' <<< "$on" || fail "the workflow does not run on push"
  pr="$(child "$on" pull_request)"
  ! grep -qE '^[[:space:]]*(branches|branches-ignore|paths|paths-ignore):' <<< "$pr" \
    || fail "the pull_request trigger is filtered, so not every pull request runs it"
  push="$(child "$on" push)"
  if grep -qE '^[[:space:]]*branches:' <<< "$push"; then
    grep -qwF -- "$target" <<< "$push" || fail "push runs on branches that leave out $target"
  fi
  grep -qE '^permissions:' "$WORKFLOW" || fail "the workflow sets no top-level permissions, so the token keeps its default rights"
  ! grep -qE ':[[:space:]]*write([[:space:]#]|$)|write-all' "$WORKFLOW" || fail "the workflow grants the token a write right"
  while IFS= read -r line; do
    value="$(sed -E 's/^[[:space:]]*(- )?run:[[:space:]]*//; s/[[:space:]]+$//' <<< "$line")"
    case "$value" in ''|'|'*|'>'*) fail "each run: must stay on one line: $line" ;; esac
    if grep -qF 'po-ci' <<< "$value"; then
      grep -qxE '(bash )?(\./)?bin/po-ci' <<< "$value" || fail "the check step does more than call bin/po-ci: $value"
      checks=$((checks + 1))
    elif grep -qE '(^|[^[:alnum:]])jq([^[:alnum:]]|$)' <<< "$value" && grep -qF 'install' <<< "$value"; then
      jq=$((jq + 1))
    else
      fail "a run: step that neither installs jq nor calls bin/po-ci: $value"
    fi
  done < <(grep -E '^[[:space:]]*(- )?run:' "$WORKFLOW")
  [ "$checks" -eq 1 ] || fail "the workflow has $checks steps calling bin/po-ci, one expected"
  [ "$jq" -ge 1 ] || fail "the workflow does not install jq"
  while IFS= read -r line; do
    grep -qE 'uses:[[:space:]]*actions/checkout@' <<< "$line" || fail "a step uses something other than checkout: $line"
  done < <(grep -E '^[[:space:]]*(- )?uses:' "$WORKFLOW")
}

test_setting_declares_forge_checks() {
  local tpl="$METHOD/templates/agents-local.md" v
  template_settings | grep -qx 'Forge checks' || fail "Forge checks is not a setting of the template"
  v="$(setting_of "$tpl" 'Forge checks')"
  [ "$v" = required ] || [ "$v" = '—' ] || fail "the template's Forge checks is '$v', not required or —"
  v="$(setting_of "$ROOT/AGENTS.local.md" 'Forge checks')"
  [ "$v" = required ] || fail "this repository's Forge checks is '$v', not required"
}
