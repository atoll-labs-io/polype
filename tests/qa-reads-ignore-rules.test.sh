#!/usr/bin/env bash
# s157 — po-bounds lets the QA and the reviewer read ignore and attribute rules.

BOUNDS="$METHOD/hooks/po-bounds.sh"
ADR3="$METHOD/../docs/decisions/ADR-0103-la-qa-lit-les-regles-d-ignorance-de-git.md"

lane() {
  scratch_repo
  LANE_TMP="$(mktemp -d)"
  trap 'rm -rf "$SCRATCH" "$LANE_TMP"' EXIT
  export TMPDIR="$LANE_TMP"
  mkdir -p "$SCRATCH/docs"
  printf '# Stories\n\n### s01-demo — Demo\n- **Owns** : `src/app.sh`\n' > "$SCRATCH/docs/stories.md"
  git -C "$SCRATCH" add -A
  git -C "$SCRATCH" commit -qm stories
  git -C "$SCRATCH" worktree add -q -b story/s01-demo "$SCRATCH/.worktrees/s01-demo"
  WT="$SCRATCH/.worktrees/s01-demo"
}

run_hook() {
  local mode="$1" cmd="$2"
  jq -n --arg v "$cmd" --arg c "$SCRATCH" '{tool_name: "Bash", tool_input: {command: $v}, cwd: $c}' \
    | bash "$BOUNDS" "$mode" 2>&1 >/dev/null || true
}
hook_status() {
  local s=0
  jq -n --arg v "$2" --arg c "$SCRATCH" '{tool_name: "Bash", tool_input: {command: $v}, cwd: $c}' \
    | bash "$BOUNDS" "$1" >/dev/null 2>&1 || s=$?
  printf '%s' "$s"
}

test_qa_allows_check_ignore() {
  lane
  [ "$(hook_status qa "git -C $WT check-ignore -v site/dist site/.astro")" = 0 ] || fail "qa refuses check-ignore"
  [ "$(hook_status reviewer "git -C $WT check-ignore -v site/dist site/.astro")" = 0 ] || fail "reviewer refuses check-ignore"
}

test_qa_allows_check_attr() {
  lane
  [ "$(hook_status qa "git -C $WT check-attr -a README.md")" = 0 ] || fail "qa refuses check-attr"
}

test_qa_still_refuses_writing_verbs() {
  lane
  local c
  for c in "add -A" "commit -m x"; do
    [ "$(hook_status qa "git -C $WT $c")" = 2 ] || fail "qa allows git $c"
    run_hook qa "git -C $WT $c" | grep -qF 'forbidden in mode qa, which runs reading verbs only' || fail "no refusal text for $c"
  done
  local verbs adr
  verbs="$(grep '^QA_GIT_VERBS=' "$BOUNDS" | sed 's/^QA_GIT_VERBS="//; s/"$//' | tr ' ' '\n' | grep . | sort)"
  adr="$(grep '^Liste des verbes de lecture :' "$ADR3" | grep -o '`[^`]*`' | tr -d '`' | grep -vx 'worktree list' | sort)"
  [ -n "$verbs" ] && [ "$verbs" = "$adr" ] || fail "QA_GIT_VERBS and the ADR-0103 list differ"
}
