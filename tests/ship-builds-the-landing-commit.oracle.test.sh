#!/usr/bin/env bash
# s193 — the oracle of the story: `po ship land <id>` runs the ship gate, then builds the landing
# commit beside story/<id>, and under `Merge mode: local` fast-forwards a clean root. Every
# repository is a throwaway one under mktemp -d; the only remote is a local bare repository.
# ship_command_calls_it speaks to a model and is judged in review.

need_po() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO (tests/run.sh builds it before the suite)"
}

# The one place the command's shape is written: `po ship land <id>`, run from the story worktree.
land() {
  STATUS=0
  OUT="$(cd "$W" && env HOME="$SCRATCH/home" GIT_CONFIG_NOSYSTEM=1 \
    "$PO" ship land s01-a "$@" 2>"$SCRATCH/stderr" </dev/null)" || STATUS=$?
}

one_object() {
  [ "$(jq -s 'length' <<< "$OUT" 2>/dev/null)" = 1 ] || fail "$1 did not print exactly one JSON value: $OUT"
  jq -e '.contract == 1' <<< "$OUT" >/dev/null || fail "$1 does not carry contract 1: $OUT"
}

is() { jq -e "$1" <<< "$OUT" >/dev/null || fail "$2: $OUT"; }

# project <pr|local>: a scratch project whose story s01-a changed code.txt, was reviewed on that
# code and waits in the worktree $W with its review not committed yet. Under pr, origin is a
# bare repository.
project() {
  SCRATCH="$(cd "$(mktemp -d)" && pwd -P)"
  SCRATCHES="${SCRATCHES:-} $SCRATCH"
  trap 'rm -rf $SCRATCHES' EXIT
  R="$SCRATCH/project" W="$SCRATCH/project/.worktrees/s01-a"
  mkdir -p "$SCRATCH/home"
  git init -q -b main "$R"
  git -C "$R" config user.email test@example.com
  git -C "$R" config user.name test
  git -C "$R" config commit.gpgsign false
  mkdir -p "$R/.polype/hooks" "$R/docs"
  cp "$METHOD/hooks/po-gate.sh" "$METHOD/hooks/po-run.sh" "$R/.polype/hooks/"
  printf 'Target branch: main\nMerge mode: %s\nShip confirmation: automatic\nFull suite: ship\nE2E stage: —\nBuild stage: —\nWorktree root: .worktrees/\n\nTest: true\nE2E: —\nBuild: —\n' \
    "$1" > "$R/AGENTS.local.md"
  printf '.worktrees/\n' > "$R/.gitignore"
  printf '# Stories\n\n### s01-a — Un titre\n\n- **Complexité** : 1\n' > "$R/docs/stories.md"
  printf 'one\n' > "$R/code.txt"
  git -C "$R" add -A && git -C "$R" commit -qm base
  if [ "$1" = pr ]; then
    ORIGIN="$SCRATCH/origin.git"
    git init -q --bare -b main "$ORIGIN"
    git -C "$R" remote add origin "$ORIGIN"
    git -C "$R" push -q origin main
  fi
  git -C "$R" worktree add -q -b story/s01-a "$W"
  printf 'two\n' > "$W/code.txt"
  git -C "$W" commit -qam code
  REVIEWED="$(git -C "$W" rev-parse 'HEAD^{tree}')"
  review yes
}

# review <yes|no>: the story's review, on the reviewed code, left uncommitted as a reviewer leaves it.
review() {
  mkdir -p "$W/docs/reviews"
  printf '# Review\n\n## Findings\n\nNone.\n\nReview status: complete\nReviewed tree: %s\nShip allowed: %s\n' \
    "$REVIEWED" "$1" > "$W/docs/reviews/s01-a.md"
}

# Every ref of the project and of origin, and what is uncommitted in the root and the worktree.
snapshot() {
  git -C "$R" for-each-ref --format='%(refname) %(objectname)'
  [ -z "${ORIGIN:-}" ] || git -C "$ORIGIN" for-each-ref --format='origin %(refname) %(objectname)'
  git -C "$R" status --porcelain
  git -C "$W" status --porcelain
}

test_gate_comes_first() {
  need_po
  project pr
  review no
  local before; before="$(snapshot)"
  land
  [ "$STATUS" -eq 1 ] || fail "a review that refuses the ship gave exit $STATUS"
  one_object "po ship land under a refusing review"
  is '.error == "gate-refused"' "the refusal is not gate-refused"
  is '.message | contains("does not allow shipping")' "the refusal does not carry the gate's reason"
  [ "$(snapshot)" = "$before" ] || fail "a refused gate still wrote: $(diff <(echo "$before") <(snapshot))"
  [ ! -e "$W/docs/verif" ] || fail "a check ran although the gate refused"
}

test_one_commit_no_merge() {
  need_po
  project pr
  # origin/main moves on (a framing landing touching docs/) while the local copy of it stays behind.
  local old fresh
  old="$(git -C "$R" rev-parse main)"
  git -C "$R" checkout -q -b moved
  printf 'log\n' > "$R/docs/decisions-log.md"
  git -C "$R" add -A && git -C "$R" commit -qm log
  git -C "$R" push -q origin moved:main
  git -C "$R" checkout -q main && git -C "$R" branch -q -D moved
  git -C "$R" update-ref refs/remotes/origin/main "$old"
  fresh="$(git -C "$ORIGIN" rev-parse main)"
  local story_before; story_before="$(git -C "$R" rev-parse story/s01-a)"
  land
  [ "$STATUS" -eq 0 ] || fail "po ship land exited $STATUS: $OUT $(cat "$SCRATCH/stderr")"
  one_object "po ship land"
  is ".base == \"$fresh\"" "the landing commit is not built on the fresh origin/main"
  local sha parents
  sha="$(jq -r .sha <<< "$OUT")"
  [ "$(git -C "$R" cat-file -t "$sha" 2>/dev/null)" = commit ] || fail "sha $sha is not a commit"
  parents="$(git -C "$R" rev-list --parents -n 1 "$sha")"
  [ "$parents" = "$sha $fresh" ] || fail "the landing commit does not have the fresh base as its only parent: $parents"
  [ "$(git -C "$R" log -1 --format=%s "$sha")" = 's01-a: Un titre' ] \
    || fail "the landing commit is not titled 's01-a: Un titre': $(git -C "$R" log -1 --format=%s "$sha")"
  git -C "$R" diff --quiet "$REVIEWED" "$sha" -- . ':(exclude)docs' \
    || fail "the landing commit's code outside docs/ is not the reviewed one"
  git -C "$R" cat-file -e "$sha:docs/decisions-log.md" || fail "the landing commit dropped what the fresh base brought"
  git -C "$R" diff --quiet "$REVIEWED" story/s01-a -- . ':(exclude)docs' \
    || fail "story/s01-a no longer holds its reviewed tree"
  git -C "$R" merge-base --is-ancestor "$story_before" story/s01-a || fail "story/s01-a was rewritten"
  [ "$(git -C "$R" rev-parse story/s01-a)" != "$sha" ] || fail "story/s01-a was moved onto the landing commit"
  [ "$(git -C "$R" rev-parse main)" = "$old" ] || fail "the local main moved under Merge mode: pr"
  [ "$(git -C "$ORIGIN" for-each-ref --format='%(refname) %(objectname)')" = "refs/heads/main $fresh" ] \
    || fail "something was sent to origin: $(git -C "$ORIGIN" for-each-ref)"
}

test_conflict_goes_to_a_human() {
  need_po
  project local
  printf 'three\n' > "$R/code.txt"
  git -C "$R" commit -qam 'main moves on code.txt'
  local before; before="$(snapshot)"
  land
  [ "$STATUS" -eq 1 ] || fail "a conflict with the base gave exit $STATUS: $OUT"
  one_object "po ship land on a conflict"
  is '.error == "conflict"' "the conflict is not refused as conflict"
  is '.paths == ["code.txt"]' "the conflicting paths are not given"
  [ "$(snapshot)" = "$before" ] || fail "a conflict still wrote: $(diff <(echo "$before") <(snapshot))"
  [ ! -e "$W/docs/verif" ] || fail "a check ran although the landing commit cannot be built"
}

test_local_mode_lands_here() {
  need_po
  # Under an effective automatic, one call builds and lands.
  project local
  local old; old="$(git -C "$R" rev-parse main)"
  land --land
  [ "$STATUS" -eq 0 ] || fail "po ship land --land under Merge mode: local exited $STATUS: $OUT $(cat "$SCRATCH/stderr")"
  one_object "po ship land --land under Merge mode: local"
  is '.landed == true' "the landing is not reported as landed"
  local sha; sha="$(jq -r .sha <<< "$OUT")"
  [ "$(git -C "$R" rev-parse main)" = "$sha" ] || fail "main is not the landing commit"
  [ "$(git -C "$R" rev-list --parents -n 1 "$sha")" = "$sha $old" ] || fail "main did not move by fast-forward"
  [ "$(cat "$R/code.txt")" = two ] || fail "the root's working copy was not brought to the landing commit"
  [ -z "$(git -C "$R" remote)" ] || fail "a remote appeared"

  # Under an effective human, the first call stops with the commit built; /po-ship asks, then a
  # second call lands that very commit without running the checks again.
  project local
  old="$(git -C "$R" rev-parse main)"
  land
  [ "$STATUS" -eq 0 ] || fail "po ship land under Merge mode: local exited $STATUS: $OUT $(cat "$SCRATCH/stderr")"
  is '.landed == false' "a call without --land landed"
  sha="$(jq -r .sha <<< "$OUT")"
  [ "$(git -C "$R" rev-parse main)" = "$old" ] || fail "main moved before the person was asked"
  local rows; rows="$(cat "$W/docs/verif/s01-a.md")"
  land --sha "$sha"
  [ "$STATUS" -eq 0 ] || fail "po ship land --sha exited $STATUS: $OUT $(cat "$SCRATCH/stderr")"
  one_object "po ship land --sha"
  is '.landed == true' "the second call is not reported as landed"
  is ".sha == \"$sha\"" "the second call landed another commit than the one built"
  [ "$(git -C "$R" rev-parse main)" = "$sha" ] || fail "main is not the commit built by the first call"
  [ "$(cat "$W/docs/verif/s01-a.md")" = "$rows" ] || fail "the second call ran the checks again"

  project local
  printf 'dirty\n' > "$R/code.txt"
  local before; before="$(snapshot)"
  land --land
  [ "$STATUS" -eq 1 ] || fail "a root holding uncommitted work gave exit $STATUS: $OUT"
  one_object "po ship land on an unclean root"
  is '.error == "root-not-clean"' "an unclean root is not refused as root-not-clean"
  [ "$(snapshot)" = "$before" ] || fail "an unclean root still let the command write"
  [ "$(cat "$R/code.txt")" = dirty ] || fail "the root's uncommitted work was touched"
}

test_version_goes_up() {
  local toml lock polype
  toml="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$ROOT/po/Cargo.toml" | head -n 1)"
  lock="$(awk '$0 == "name = \"po\"" {getline; print; exit}' "$ROOT/po/Cargo.lock" | sed -n 's/^version = "\(.*\)"$/\1/p')"
  polype="$(sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$ROOT/bin/polype")"
  [ -n "$toml" ] && [ "$toml" = "$lock" ] && [ "$toml" = "$polype" ] \
    || fail "po's version differs: po/Cargo.toml $toml, po/Cargo.lock $lock, bin/polype $polype"
  [ "$toml" != 0.8.0 ] && [ "$(printf '0.8.0\n%s\n' "$toml" | sort -V | head -n 1)" = 0.8.0 ] \
    || fail "po's version $toml is not above 0.8.0"
}
