#!/usr/bin/env bash
# s106 — framing and settings land on the target branch through a pull request, as a fast-forward.

SETUP="$METHOD/commands/po-setup.md"
RESEARCH="$METHOD/commands/po-research.md"

# Each framing command and the branch its landing uses.
FRAMING=(
  "po-setup|setup"
  "po-brief|brief"
  "po-prd|prd"
  "po-stories|stories"
  "po-stories-review|stories-review"
  "po-architect|architecture"
  "po-design-system|design-system"
)

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

landing() { section_of "$SETUP" 'Landing the framing'; }

test_framing_commits_on_a_branch() {
  require_file "$SETUP"
  local land; land=$(landing)
  [ -n "$land" ] || fail "po-setup.md has no '## Landing the framing' section"
  local s
  for s in 'GIT_INDEX_FILE' 'git commit-tree <tree> -p <base>' 'refs/heads/framing/<slug>' 'git add -- <paths>'; do
    holds "$land" "$s" 'the landing section'
  done

  local entry cmd slug file
  for entry in "${FRAMING[@]}"; do
    cmd=${entry%%|*}; slug=${entry##*|}; file="$METHOD/commands/$cmd.md"
    require_file "$file"
    contains "$file" "\`framing/$slug\`"
    [ "$cmd" = po-setup ] || contains "$file" '## Landing the framing'
    ! grep -n 'git push' "$file" | grep -vF 'framing/<slug>' | grep -q . \
      || fail "$cmd.md pushes something other than framing/<slug>"
    ! grep -inE 'commit[^.]* on (`Target branch`|the target branch)' "$file" | grep -q . \
      || fail "$cmd.md still commits on the target branch: $(grep -inE 'commit[^.]* on (`Target branch`|the target branch)' "$file" | head -1)"
    ! grep -qF 'Commit from the repository root, on `Target branch`' "$file" \
      || fail "$cmd.md still commits from the root on the target branch"
  done
}

test_framing_pr_fast_forwards() {
  local land; land=$(landing)
  local s
  for s in 'gh pr merge <url> --rebase --match-head-commit <sha>' '`MERGED`' \
           'git merge --ff-only origin/<Target branch>' 'git merge --ff-only framing/<slug>' \
           "## The forge's review rule" \
           '"Framing pull request ready: <url>. Land it with Rebase and merge;' 'AskUserQuestion'; do
    holds "$land" "$s" 'the landing section'
  done
}

test_research_waits_for_framing_merge() {
  require_file "$RESEARCH"
  contains "$RESEARCH" 'git show <start point>:docs/stories.md'
  contains "$RESEARCH" 'waits for its merge'
  local fetch show add
  fetch=$(grep -n -m1 -F '`git fetch` it' "$RESEARCH" | cut -d: -f1)
  show=$(grep -n -m1 -F 'git show <start point>:docs/stories.md' "$RESEARCH" | cut -d: -f1)
  add=$(grep -n -m1 -F 'git worktree add -b story/<id>' "$RESEARCH" | cut -d: -f1)
  [ -n "$fetch" ] && [ -n "$add" ] || fail "po-research.md lost its fetch or its worktree creation"
  [ "$fetch" -lt "$show" ] && [ "$show" -lt "$add" ] \
    || fail "po-research.md does not check the story between the fetch and the worktree creation"
}
