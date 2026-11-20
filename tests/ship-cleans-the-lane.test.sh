#!/usr/bin/env bash
# s196 — the guards of `po ship clean <id>` that the oracle leaves open: what it owns, what it
# refuses, what it keeps on origin. Fixtures live under one mktemp folder, removed on exit; origin is
# a github.com URL that git rewrites to a local bare repository, and gh is a double that fails.

need_po() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO (tests/run.sh builds it before the suite)"
}

is() { jq -e "$1" <<< "$OUT" >/dev/null || fail "$2: $OUT"; }

SUBJECT='s01-a: Un titre'

# project: a fresh pr project; the story's commit changes code.txt and adds shared.txt.
project() {
  if [ -z "${SCRATCH:-}" ]; then
    SCRATCH="$(cd "$(mktemp -d)" && pwd -P)"
    trap 'rm -rf "$SCRATCH"' EXIT
    N=0
  fi
  N=$((N + 1))
  R="$SCRATCH/p$N/project" W="$SCRATCH/p$N/project/.worktrees/s01-a" D="$SCRATCH/p$N/doubles"
  ORIGIN="$SCRATCH/p$N/origin.git" OTHER="$SCRATCH/p$N/other"
  mkdir -p "$SCRATCH/home" "$D/bin"
  git init -q -b main "$R"
  git -C "$R" config user.email test@example.com
  git -C "$R" config user.name test
  git -C "$R" config commit.gpgsign false
  mkdir -p "$R/docs"
  printf 'Target branch: main\nMerge mode: pr\nIssue tracker: —\nShip confirmation: automatic\nWorktree root: .worktrees/\n' > "$R/AGENTS.local.md"
  printf '.worktrees/\n.env\n' > "$R/.gitignore"
  printf '# Stories\n\n### s01-a — Un titre\n\n- **Complexité** : 1\n' > "$R/docs/stories.md"
  printf 'one\n' > "$R/code.txt"
  git -C "$R" add -A && git -C "$R" commit -qm base
  git init -q --bare -b main "$ORIGIN"
  git -C "$R" remote add origin https://github.com/acme/widget.git
  git -C "$R" config "url.$ORIGIN.insteadOf" https://github.com/acme/widget.git
  git -C "$R" push -q origin main
  git -C "$R" worktree add -q -b story/s01-a "$W"
  printf 'two\n' > "$W/code.txt"
  printf 'shared\n' > "$W/shared.txt"
  git -C "$W" add -A && git -C "$W" commit -qm 'code'
  printf '#!/usr/bin/env bash\nexit 1\n' > "$D/bin/gh" && chmod +x "$D/bin/gh"
}

landing() { git -C "$W" commit-tree 'HEAD^{tree}' -p "$1" -m "${2:-$SUBJECT}"; }

sent() {
  git -C "$R" fetch -q origin
  SENT="$(landing "$(git -C "$R" rev-parse refs/remotes/origin/main)")"
  git -C "$R" push -q origin "$SENT:refs/heads/story/s01-a"
}

# merged: the forge's rebase merge of the same commit, same tree.
merged() {
  local commit
  commit="$(GIT_COMMITTER_DATE='2001-02-03T04:05:06Z' landing "$(git -C "$ORIGIN" rev-parse refs/heads/main)")"
  git -C "$R" push -q origin "$commit:refs/heads/main"
}

# merged_after <file> <content>: origin's main moves first, then the merge replays the story's change
# on top of it, as a rebase merge does; the landing's tree is no longer the sent commit's.
merged_after() {
  git clone -q "$ORIGIN" "$OTHER"
  git -C "$OTHER" config user.email test@example.com
  git -C "$OTHER" config user.name test
  git -C "$OTHER" config commit.gpgsign false
  printf '%s\n' "$2" > "$OTHER/$1"
  git -C "$OTHER" add -A && git -C "$OTHER" commit -qm 'main moves'
  git -C "$OTHER" fetch -q origin refs/heads/story/s01-a
  LC_ALL=C git -C "$OTHER" cherry-pick FETCH_HEAD >/dev/null
  git -C "$OTHER" push -q origin HEAD:main
}

clean_with() {
  STATUS=0
  OUT="$(cd "$R" && env PATH="$D/bin:$PATH" PO_GH="$D/bin/gh" HOME="$SCRATCH/home" \
    "$PO" ship clean "$@" 2>"$SCRATCH/stderr" </dev/null)" || STATUS=$?
}
clean() { clean_with s01-a; }

has_branch() { git -C "$R" rev-parse -q --verify "refs/heads/${1-story/s01-a}" >/dev/null; }
has_remote() { git -C "$ORIGIN" rev-parse -q --verify "refs/heads/${1-story/s01-a}" >/dev/null; }

refused() {
  [ "$STATUS" -eq 1 ] || fail "$2: exited $STATUS, not 1: $OUT"
  is ".error == \"$1\"" "$2"
}

kept_everything() {
  [ -f "$W/code.txt" ] || fail "$1: the worktree was removed"
  has_branch || fail "$1: story/s01-a was deleted"
  has_remote || fail "$1: origin's story/s01-a was deleted"
}

test_clean_owns_only_its_refs() {
  need_po
  project
  local upstream="$SCRATCH/p$N/upstream.git"
  git init -q --bare -b main "$upstream"
  git -C "$R" remote add upstream "$upstream"
  sent
  merged
  git -C "$R" branch story/s01-a-b story/s01-a
  git -C "$R" tag story/s01-a refs/heads/story/s01-a
  git -C "$R" push -q origin refs/heads/story/s01-a-b:refs/heads/story/s01-a-b "$SENT:refs/heads/story/s01-a-c"
  git -C "$R" push -q upstream refs/heads/story/s01-a:refs/heads/story/s01-a
  local main; main="$(git -C "$ORIGIN" rev-parse main)"
  clean
  [ "$STATUS" -eq 0 ] || fail "exited $STATUS: $OUT"
  is '.state == "cleaned" and .worktree == "removed" and .branch == "deleted" and .remote == "deleted"' "the lane"
  ! has_branch story/s01-a || fail "story/s01-a is still there"
  has_branch story/s01-a-b || fail "story/s01-a-b was deleted"
  git -C "$R" rev-parse -q --verify refs/tags/story/s01-a >/dev/null || fail "the tag story/s01-a was deleted"
  has_remote story/s01-a-b || fail "origin's story/s01-a-b was deleted"
  has_remote story/s01-a-c || fail "origin's story/s01-a-c was deleted"
  git -C "$upstream" rev-parse -q --verify refs/heads/story/s01-a >/dev/null || fail "upstream's story/s01-a was deleted"
  [ "$(git -C "$ORIGIN" rev-parse main)" = "$main" ] || fail "origin's main moved"
}

test_clean_refuses_a_branch_checked_out_elsewhere_or_a_lane_on_another_branch() {
  need_po
  project
  sent
  merged
  git -C "$R" worktree remove "$W"
  git -C "$R" worktree add -q "$SCRATCH/p$N/elsewhere" story/s01-a
  clean
  refused branch-in-use "the branch lives at another path"
  grep -qF "$SCRATCH/p$N/elsewhere" <<< "$OUT" || fail "the refusal does not name the path: $OUT"
  has_branch && has_remote || fail "branch-in-use removed a branch"
  [ -d "$SCRATCH/p$N/elsewhere" ] || fail "branch-in-use removed the other worktree"

  project
  sent
  merged
  git -C "$R" worktree remove "$W"
  git -C "$R" worktree add -q -b other "$W" main
  clean
  refused not-the-lane "the lane path holds another branch"
  [ -d "$W" ] && has_branch && has_remote || fail "not-the-lane removed something"
  [ "$(git -C "$W" rev-parse --abbrev-ref HEAD)" = other ] || fail "the lane path moved off its branch"
}

test_clean_stops_where_git_refuses() {
  need_po
  project
  sent
  merged
  git -C "$R" worktree lock "$W"
  clean
  refused worktree-refused "a locked worktree"
  kept_everything "a locked worktree"
}

test_clean_keeps_a_remote_branch_that_is_not_the_landing() {
  need_po
  project
  sent
  merged
  local extra
  extra="$(git -C "$W" commit-tree 'HEAD^{tree}' -p "$SENT" -m 'a late fix')"
  git -C "$R" push -q origin "$extra:refs/heads/story/s01-a"
  clean
  [ "$STATUS" -eq 1 ] || fail "a head that gained a commit: exited $STATUS: $OUT"
  is ".state == \"remote-kept\" and .remote == \"kept\" and .remote_head == \"$extra\" and .worktree == \"removed\" and .branch == \"deleted\"" "a head that gained a commit"
  [ "$(git -C "$ORIGIN" rev-parse refs/heads/story/s01-a)" = "$extra" ] || fail "the late commit was deleted with its branch"
  clean
  [ "$STATUS" -eq 1 ] || fail "the rerun exited $STATUS: $OUT"
  is '.state == "remote-kept" and .worktree == "absent" and .branch == "absent"' "a rerun finishes nothing more and says so"

  # The same subject with another change is no landing either.
  project
  sent
  merged
  printf 'three\n' > "$W/code.txt"
  git -C "$W" add -A
  extra="$(git -C "$W" commit-tree "$(git -C "$W" write-tree)" -p "$SENT" -m "$SUBJECT")"
  git -C "$R" push -q origin "$extra:refs/heads/story/s01-a"
  git -C "$W" reset -q --hard HEAD
  clean
  [ "$STATUS" -eq 1 ] || fail "a head with the subject and another change: exited $STATUS: $OUT"
  is '.state == "remote-kept"' "a head with the subject and another change"
  has_remote || fail "the head with another change was deleted"
}

test_clean_deletes_the_remote_after_the_base_moved() {
  need_po
  project
  sent
  merged_after other.txt other
  clean
  [ "$STATUS" -eq 0 ] || fail "the base moved by an unrelated commit: exited $STATUS: $OUT"
  is '.state == "cleaned" and .remote == "deleted"' "the base moved by an unrelated commit"
  ! has_remote || fail "origin's story/s01-a is still there"

  # The tree of the landing is the sent tree, the change it carries is not.
  project
  sent
  merged_after shared.txt shared
  [ "$(git -C "$ORIGIN" rev-parse main^{tree})" = "$(git -C "$ORIGIN" rev-parse "$SENT^{tree}")" ] \
    || fail "the fixture did not give the landing the sent tree"
  clean
  [ "$STATUS" -eq 0 ] || fail "a landing with the sent tree: exited $STATUS: $OUT"
  ! has_remote || fail "origin's story/s01-a is still there"
}

test_clean_usage() {
  need_po
  project
  clean_with
  [ "$STATUS" -eq 2 ] || fail "exit $STATUS: $OUT"
  is '.error == "usage"' "no id"
  clean_with bad
  [ "$STATUS" -eq 2 ] || fail "exit $STATUS: $OUT"
  is '.error == "usage"' "a bad id"
  clean_with s01-a s02-b
  [ "$STATUS" -eq 2 ] || fail "exit $STATUS: $OUT"
  is '.error == "usage"' "two ids"
  clean_with s01-a --force
  [ "$STATUS" -eq 2 ] || fail "exit $STATUS: $OUT"
  is '.error == "unknown-option"' "an option"
}

# other_clone: a second clone of origin, to give main commits the project did not make.
other_clone() {
  rm -rf "$OTHER"
  git clone -q "$ORIGIN" "$OTHER"
  git -C "$OTHER" config user.email test@example.com
  git -C "$OTHER" config user.name test
  git -C "$OTHER" config commit.gpgsign false
}

# lands_as <file>=<content>...: origin's main gains a commit titled as the story that carries only
# those files.
lands_as() {
  other_clone
  local pair
  for pair in "$@"; do printf '%s\n' "${pair#*=}" > "$OTHER/${pair%%=*}"; done
  git -C "$OTHER" add -A
  git -C "$OTHER" commit -q --allow-empty -m "$SUBJECT"
  git -C "$OTHER" push -q origin HEAD:main
}

test_clean_keeps_a_branch_that_the_landing_does_not_hold() {
  need_po
  local case
  for case in empty partial conflicting; do
    project
    case "$case" in
      empty) lands_as ;;
      partial) lands_as code.txt=two ;;
      conflicting) lands_as code.txt=other shared.txt=shared ;;
    esac
    clean
    refused branch-not-landed "a commit titled as the story, $case"
    [ -f "$W/code.txt" ] && has_branch || fail "$case: something was removed"
  done

  # A person deletes the branch by hand, and the rerun finishes the rest.
  git -C "$R" worktree remove "$W"
  git -C "$R" update-ref -d refs/heads/story/s01-a
  clean
  [ "$STATUS" -eq 0 ] || fail "the rerun exited $STATUS: $OUT"
  is '.state == "cleaned" and .worktree == "absent" and .branch == "absent"' "the rerun"
}

test_clean_keeps_a_remote_head_whose_parent_is_not_on_the_base() {
  need_po
  local fork head variant
  for variant in none moved; do
    project
    sent
    if [ "$variant" = none ]; then merged; else merged_after other.txt other; fi
    fork="$(git -C "$R" rev-parse "$SENT^")"
    head="$(git -C "$W" commit-tree "$fork^{tree}" -p "$fork" -m 'never landed')"
    head="$(git -C "$W" commit-tree "$SENT^{tree}" -p "$head" -m "$SUBJECT")"
    git -C "$R" push -q -f origin "$head:refs/heads/story/s01-a"
    clean
    [ "$STATUS" -eq 1 ] || fail "$variant: exited $STATUS: $OUT"
    is '.state == "remote-kept" and .branch == "deleted"' "a parent off the base"
    has_remote || fail "a head on a parent off the base was deleted"
  done
}

# swap_head <code.txt content>: origin's story branch becomes a commit titled as the story, on the
# fork point, whose only change is code.txt and shared.txt.
swap_head() {
  git -C "$OTHER" checkout -q -b y "$SENT^"
  printf '%b\n' "$1" > "$OTHER/code.txt"
  printf 'shared\n' > "$OTHER/shared.txt"
  git -C "$OTHER" add -A
  git -C "$OTHER" commit -qm "$SUBJECT"
  git -C "$OTHER" push -q -f origin y:refs/heads/story/s01-a
}

test_clean_compares_the_change_of_a_remote_head_byte_for_byte() {
  need_po
  local stored
  for stored in 'two |two' 'two\xff|two\xfe'; do
    project
    printf '%b\n' "${stored#*|}" > "$W/code.txt"
    git -C "$W" add -A && git -C "$W" commit -q --amend --no-edit
    sent
    merged_after other.txt other
    swap_head "${stored%|*}"
    clean
    [ "$STATUS" -eq 1 ] || fail "$stored: exited $STATUS: $OUT"
    is '.state == "remote-kept"' "a head whose change differs by one byte"
    has_remote || fail "$stored: the remote head was deleted"
  done
}
