#!/usr/bin/env bash
# s110 — a second landing on the same framing branch stacks on it until a merge is proven, then the root realigns.

SETUP="$METHOD/commands/po-setup.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

base_block() {
  section_of "$SETUP" 'Landing the framing' |
    awk '/^\*\*Base\.\*\*/ {on=1} /^\*\*The commit, built beside the checkout\*\*/ {on=0} on'
}

offset() { grep -bo -m1 -F -- "$2" <<< "$1" | head -1 | cut -d: -f1; }

test_framing_merge_is_proven_per_forge() {
  require_file "$SETUP"
  local b; b=$(base_block)
  [ -n "$b" ] || fail "po-setup.md has no Base block in its landing section"
  local s
  for s in 'gh pr view framing/<slug> --json state --jq .state' '`MERGED`' \
    'git merge-base --is-ancestor origin/framing/<slug> origin/<Target branch>' \
    'ancestry is never the proof of a merge on GitHub' 'Any other state, or no pull request from that branch, means not merged.' 'step 3 of `/po-ship`'; do
    holds "$b" "$s" 'Base'
  done
}

test_second_landing_stacks_on_the_framing_branch() {
  require_file "$SETUP"
  local b; b=$(base_block)
  holds "$b" '`<base>` is `origin/framing/<slug>`, whether a pull request is open or not' 'Base'
  holds "$b" 'A merged branch is never taken as a base' 'Base'
  if grep -qF -- 'gh pr list --head framing/<slug> --state open' <<< "$b"; then
    fail "Base still decides the stacking from an open pull request alone"
  fi
  local nm m
  nm=$(offset "$b" 'Not merged →')
  m=$(offset "$b" 'Merged →')
  [ -n "$nm" ] && [ -n "$m" ] || fail "Base lost its Not merged or Merged branch"
  [ "$nm" -lt "$m" ] || fail "Base states Merged before Not merged"
}

test_root_realigns_after_a_merge() {
  require_file "$SETUP"
  local b; b=$(base_block)
  local s
  for s in 'git merge --ff-only origin/<Target branch>' 'A refusal is reported' 'git push origin --delete framing/<slug>'; do
    holds "$b" "$s" 'Base'
  done
  local land; land=$(section_of "$SETUP" 'Landing the framing')
  local endb rt
  endb=$(offset "$land" 'In the root, `git merge --ff-only origin/<Target branch>`, whatever the slug')
  rt=$(offset "$land" 'GIT_INDEX_FILE=<tmp> git read-tree <base>')
  [ -n "$endb" ] && [ -n "$rt" ] && [ "$endb" -lt "$rt" ] || fail "the realignment does not precede the commit build"
}
