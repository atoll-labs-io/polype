#!/usr/bin/env bash
# s196 — the oracle of the story: `po ship clean <id>`, run from the repository root, removes a
# landed lane — its worktree without --force, then story/<id> locally and on origin — once it proves
# the landing itself: a commit of Target branch, as origin holds it under pr, titled exactly
# `<id>: <story title>`. origin is a github.com URL that git rewrites to a local bare repository; gh
# (also named by PO_GH) is a double that logs any call and fails, since the cleanup asks no forge.
# What ship_is_a_short_command leaves to a model is judged in review.

need_po() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO (tests/run.sh builds it before the suite)"
}

is() { jq -e "$1" <<< "$OUT" >/dev/null || fail "$2: $OUT"; }

SUBJECT='s01-a: Un titre'

# project [pr|local]: a fresh project under $SCRATCH (made once, removed on exit) whose story s01-a
# changed code.txt in its worktree $W, with an ignored .env as /po-research copies it, no gate hook
# and a review that does not allow the ship. Under pr, origin is the bare $ORIGIN.
project() {
  local mode="${1:-pr}"
  if [ -z "${SCRATCH:-}" ]; then
    SCRATCH="$(cd "$(mktemp -d)" && pwd -P)"
    trap 'rm -rf "$SCRATCH"' EXIT
    N=0
  fi
  N=$((N + 1))
  R="$SCRATCH/p$N/project" W="$SCRATCH/p$N/project/.worktrees/s01-a" D="$SCRATCH/p$N/doubles"
  ORIGIN="$SCRATCH/p$N/origin.git" MODE="$mode"
  mkdir -p "$SCRATCH/home" "$D/bin"
  : > "$D/calls"
  git init -q -b main "$R"
  git -C "$R" config user.email test@example.com
  git -C "$R" config user.name test
  git -C "$R" config commit.gpgsign false
  mkdir -p "$R/docs"
  printf 'Target branch: main\nMerge mode: %s\nIssue tracker: —\nShip confirmation: automatic\nWorktree root: .worktrees/\n' \
    "$mode" > "$R/AGENTS.local.md"
  printf '.worktrees/\n.env\n' > "$R/.gitignore"
  printf '# Stories\n\n### s01-a — Un titre\n\n- **Complexité** : 1\n' > "$R/docs/stories.md"
  printf 'one\n' > "$R/code.txt"
  git -C "$R" add -A && git -C "$R" commit -qm base
  if [ "$mode" = pr ]; then
    git init -q --bare -b main "$ORIGIN"
    git -C "$R" remote add origin https://github.com/acme/widget.git
    git -C "$R" config "url.$ORIGIN.insteadOf" https://github.com/acme/widget.git
    git -C "$R" push -q origin main
  fi
  git -C "$R" worktree add -q -b story/s01-a "$W"
  printf 'two\n' > "$W/code.txt"
  mkdir -p "$W/docs/reviews"
  printf 'Review status: complete\nShip allowed: no\n' > "$W/docs/reviews/s01-a.md"
  git -C "$W" add -A && git -C "$W" commit -qm 'code and review'
  printf 'TOKEN=x\n' > "$W/.env"
  cat > "$D/bin/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DOUBLES/calls"
exit 1
EOF
  chmod +x "$D/bin/gh"
}

# landing <parent> [subject]: the landing commit of s01-a on <parent>, as po ship land builds it.
landing() { git -C "$W" commit-tree 'HEAD^{tree}' -p "$1" -m "${2:-$SUBJECT}"; }

# sent: the landing commit on origin's story/s01-a, as po ship push leaves it before the merge.
sent() {
  git -C "$R" fetch -q origin
  SENT="$(landing "$(git -C "$R" rev-parse refs/remotes/origin/main)")"
  git -C "$R" push -q origin "$SENT:refs/heads/story/s01-a"
}

# merged [message]: the forge's rebase merge, a new commit of the same tree on origin's main. The
# root's copy of origin/main is put back, so only a fetch of the command's own can see the merge.
merged() {
  local tracking commit
  tracking="$(git -C "$R" rev-parse refs/remotes/origin/main)"
  commit="$(GIT_COMMITTER_DATE='2001-02-03T04:05:06Z' landing "$(git -C "$ORIGIN" rev-parse refs/heads/main)" "${1:-$SUBJECT}")"
  git -C "$R" push -q origin "$commit:refs/heads/main"
  git -C "$R" update-ref refs/remotes/origin/main "$tracking"
}

clean() {
  STATUS=0
  OUT="$(cd "$R" && env PATH="$D/bin:$PATH" PO_GH="$D/bin/gh" DOUBLES="$D" HOME="$SCRATCH/home" \
    "$PO" ship clean s01-a 2>"$SCRATCH/stderr" </dev/null)" || STATUS=$?
}

has_worktree() { [ -d "$W" ] || git -C "$R" worktree list --porcelain | grep -qxF "worktree $W"; }
has_branch() { git -C "$R" rev-parse -q --verify refs/heads/story/s01-a >/dev/null; }
has_remote() { git -C "$ORIGIN" rev-parse -q --verify refs/heads/story/s01-a >/dev/null; }

intact() {
  [ -f "$W/code.txt" ] || fail "$1: the worktree was removed"
  has_branch || fail "$1: story/s01-a was deleted"
  [ "$MODE" = local ] || has_remote || fail "$1: origin's story/s01-a was deleted"
}

gone() {
  ! has_worktree || fail "$1: the worktree is still there"
  ! has_branch || fail "$1: story/s01-a is still there"
  [ "$MODE" = local ] || ! has_remote || fail "$1: origin's story/s01-a is still there"
}

refused() {
  [ "$STATUS" -eq 1 ] || fail "$2: exited $STATUS, not 1: $OUT"
  is ".error == \"$1\"" "$2"
}

cleaned() {
  [ "$STATUS" -eq 0 ] || fail "$1: exited $STATUS: $OUT $(cat "$SCRATCH/stderr")"
  is '.state == "cleaned"' "$1"
  gone "$1"
}

test_nothing_is_removed_before_the_proof() {
  need_po
  project pr
  sent
  clean
  refused not-landed "a pull request sent but not merged"
  intact "not merged"

  # The landing on the root's own main is not the proof: origin is.
  git -C "$R" merge -q --ff-only "$SENT"
  clean
  refused not-landed "a landing on the root's main only"
  intact "landed on the root only"

  merged $'chore: tidy\n\ns01-a: Un titre'
  clean
  refused not-landed "a commit of origin's main that quotes the subject in its body"
  merged 's01-a: Un titre, suite'
  clean
  refused not-landed "a commit of origin's main whose subject extends the story's"
  intact "subject quoted or extended"

  project local
  clean
  refused not-landed "Merge mode: local, main without the landing"
  intact "local, not landed"

  [ ! -s "$SCRATCH/p1/doubles/calls" ] || fail "the cleanup asked the forge: $(cat "$SCRATCH/p1/doubles/calls")"
  ! grep -nE 'gh pr (view|list)' "$METHOD/commands/po-ship.md" \
    || fail "po-ship.md still asks the forge for the proof by the branch name"
}

test_cleanup_is_not_forced() {
  need_po
  project pr
  sent
  merged
  printf 'draft\n' > "$W/notes.txt"
  clean
  refused dirty-worktree "an untracked file in the worktree"
  grep -qF 'notes.txt' <<< "$OUT" || fail "the refusal does not name the uncommitted file: $OUT"
  intact "a dirty worktree"

  rm "$W/notes.txt"
  local main; main="$(git -C "$ORIGIN" rev-parse refs/heads/main)"
  clean
  cleaned "a clean worktree after a rebase merge"
  [ ! -e "$W/.env" ] || fail "the ignored .env outlived its worktree"
  [ "$(git -C "$ORIGIN" rev-parse refs/heads/main)" = "$main" ] || fail "origin's main moved"
  [ ! -s "$D/calls" ] || fail "the cleanup asked the forge: $(cat "$D/calls")"

  project local
  git -C "$R" merge -q --ff-only "$(landing "$(git -C "$R" rev-parse main)")"
  clean
  cleaned "Merge mode: local, the landing fast-forwarded onto main"
  is '.remote == null' "under local nothing is asked of a remote"
}

test_landed_lane_is_cleaned_alone() {
  need_po
  project pr
  sent
  merged
  git -C "$R" fetch -q origin
  local next
  next="$(cd "$R" && "$PO" next 2>/dev/null)" || true
  jq -e '.actions[] | select(.story == "s01-a") | .action == "ship" and .reason == "landed"' <<< "$next" >/dev/null \
    || fail "po next does not give the lane ship, reason landed: $next"

  local before_root before_origin head
  before_root="$(git -C "$R" rev-list --all | sort)"
  before_origin="$(git -C "$ORIGIN" rev-list --all | sort)"
  head="$(git -C "$R" rev-parse HEAD)"
  clean
  cleaned "a landed lane with no gate hook and a review that does not allow the ship"
  [ -z "$(comm -13 <(echo "$before_root") <(git -C "$R" rev-list --all | sort))" ] || fail "the cleanup made a commit in the root"
  [ -z "$(comm -13 <(echo "$before_origin") <(git -C "$ORIGIN" rev-list --all | sort))" ] || fail "the cleanup sent a commit to origin"
  [ "$(git -C "$R" rev-parse HEAD)" = "$head" ] || fail "the root's HEAD moved"
}

test_cleanup_reruns_cleanly() {
  need_po
  local cut
  for cut in worktree worktree-folder worktree-and-branch remote nothing-left; do
    project pr
    sent
    merged
    case "$cut" in
      worktree) git -C "$R" worktree remove "$W" ;;
      worktree-folder) rm -rf "$W" ;;
      worktree-and-branch) git -C "$R" worktree remove "$W" && git -C "$R" branch -q -D story/s01-a ;;
      remote) git -C "$R" push -q origin --delete refs/heads/story/s01-a ;;
      nothing-left) clean && cleaned "the first run" ;;
    esac
    clean
    cleaned "a rerun after an interruption ($cut)"
  done
}

test_version_goes_up() {
  local toml lock polype
  toml="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$ROOT/po/Cargo.toml" | head -n 1)"
  lock="$(awk '$0 == "name = \"po\"" {getline; print; exit}' "$ROOT/po/Cargo.lock" | sed -n 's/^version = "\(.*\)"$/\1/p')"
  polype="$(sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$ROOT/bin/polype")"
  [ -n "$toml" ] && [ "$toml" = "$lock" ] && [ "$toml" = "$polype" ] \
    || fail "po's version differs: po/Cargo.toml $toml, po/Cargo.lock $lock, bin/polype $polype"
  [ "$toml" != 0.11.0 ] && [ "$(printf '0.11.0\n%s\n' "$toml" | sort -V | head -n 1)" = 0.11.0 ] \
    || fail "po's version $toml is not above 0.11.0"
}
