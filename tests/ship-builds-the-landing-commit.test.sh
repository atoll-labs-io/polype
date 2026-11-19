#!/usr/bin/env bash
# s193 — the task tests of `po ship land <id>`, on the oracle's throwaway projects: the only remote
# is a local bare repository, and nothing is pushed.

source "$(dirname "${BASH_SOURCE[0]}")/ship-builds-the-landing-commit.oracle.test.sh"
unset -f test_gate_comes_first test_one_commit_no_merge test_conflict_goes_to_a_human \
  test_local_mode_lands_here test_version_goes_up

# set_setting <name> <value>: rewrites one setting of the project and commits it on main, so a
# local root stays clean.
set_setting() {
  sed -i "s/^$1: .*/$1: $2/" "$R/AGENTS.local.md"
  git -C "$R" commit -qam "$1"
}

test_land_refuses_outside_its_story() {
  need_po
  project local
  W="$R" land
  [ "$STATUS" -eq 2 ] || fail "po ship land from the root exited $STATUS: $OUT"
  one_object "po ship land from the root"
  is '.error == "wrong-branch"' "the root is not refused as wrong-branch"
  OUT="$(cd "$W" && "$PO" ship land </dev/null)" && fail "po ship land without an id was accepted"
  is '.error == "usage"' "po ship land without an id is not a usage refusal"
}

test_remote_check_both_ways() {
  need_po
  project pr
  git -C "$R" remote remove origin
  local before; before="$(snapshot)"
  land
  [ "$STATUS" -eq 1 ] || fail "Merge mode: pr without origin exited $STATUS: $OUT"
  is '.error == "remote-check"' "pr without origin is not refused as remote-check"
  [ "$(snapshot)" = "$before" ] || fail "the remote check still wrote under pr"

  project local
  git -C "$R" remote add origin "$SCRATCH/elsewhere.git"
  before="$(snapshot)"
  land --land
  [ "$STATUS" -eq 1 ] || fail "Merge mode: local with origin exited $STATUS: $OUT"
  is '.error == "remote-check"' "local with origin is not refused as remote-check"
  is '.message | contains("is only for a repository without a remote")' "the local refusal does not say why"
  [ "$(snapshot)" = "$before" ] || fail "the remote check still wrote under local"
}

test_failed_check_stops_the_ship() {
  need_po
  project local
  set_setting Test false
  local main story
  main="$(git -C "$R" rev-parse main)" story="$(git -C "$R" rev-parse story/s01-a)"
  land --land
  [ "$STATUS" -eq 1 ] || fail "a failing unit suite exited $STATUS: $OUT"
  one_object "po ship land on a failing check"
  is '.error == "check-failed" and .check == "unit suite" and .exit == 1 and .checks == []' \
    "the failing check is not reported"
  is 'has("sha") | not' "a landing commit was built after a failing check"
  [ "$(git -C "$R" rev-parse main)" = "$main" ] || fail "main moved after a failing check"
  [ "$(git -C "$R" rev-parse story/s01-a)" = "$story" ] || fail "story/s01-a moved after a failing check"
}

test_recorded_suite_is_not_rerun() {
  need_po
  project pr
  mkdir -p "$W/docs/verif"
  printf '# Verification\n\nTree: %s\n\n## Checks\n| Check | Command | Note |\n| --- | --- | --- |\n| Unit suite | `true` | |\n\nVerification status: complete\n\n' \
    "$REVIEWED" > "$W/docs/verif/s01-a.md"
  (cd "$W" && bash .polype/hooks/po-run.sh --story s01-a --label 'Unit suite' -- true) >/dev/null
  set_setting 'Full suite' execute-end
  set_setting Test false
  land
  [ "$STATUS" -eq 0 ] || fail "a recorded unit suite was run again: $STATUS $OUT"
  is '.checks[0] == {"check": "unit suite", "outcome": "recorded", "command": null}' \
    "the unit suite is not reported as recorded"
}

test_route_answer_is_required() {
  need_po
  project pr
  set_setting 'Build stage' ship-if-route
  local before; before="$(snapshot)"
  land
  [ "$STATUS" -eq 2 ] || fail "ship-if-route without --routes exited $STATUS: $OUT"
  is '.error == "usage"' "ship-if-route without --routes is not a usage refusal"
  [ "$(snapshot)" = "$before" ] || fail "a refused call still wrote"
  land --routes no
  [ "$STATUS" -eq 0 ] || fail "--routes no exited $STATUS: $OUT"
  is '.checks[2].check == "build" and .checks[2].outcome == "skipped"' "the build is not skipped on --routes no"
}

test_review_lands_with_the_story() {
  need_po
  project pr
  land
  [ "$STATUS" -eq 0 ] || fail "po ship land exited $STATUS: $OUT $(cat "$SCRATCH/stderr")"
  is '.committed != null' "the review was not committed"
  is '.committed == "'"$(git -C "$R" rev-parse story/s01-a)"'"' "committed is not the new head of story/s01-a"
  local sha; sha="$(jq -r .sha <<< "$OUT")"
  git -C "$R" cat-file -e "$sha:docs/reviews/s01-a.md" || fail "the landing commit lacks the review"
  git -C "$R" cat-file -e "$sha:docs/verif/s01-a.md" || fail "the landing commit lacks the record rows"
  [ -z "$(git -C "$W" status --porcelain)" ] || fail "the worktree is left dirty: $(git -C "$W" status --porcelain)"
}

test_stale_landing_is_refused() {
  need_po
  project local
  land
  [ "$STATUS" -eq 0 ] || fail "po ship land exited $STATUS: $OUT $(cat "$SCRATCH/stderr")"
  local sha main; sha="$(jq -r .sha <<< "$OUT")"
  printf 'other\n' > "$R/other.txt"
  git -C "$R" add other.txt && git -C "$R" commit -qm 'main moves on'
  main="$(git -C "$R" rev-parse main)"
  land --sha "$sha"
  [ "$STATUS" -eq 1 ] || fail "a landing built on an old base exited $STATUS: $OUT"
  is '.error == "stale-landing"' "a landing built on an old base is not refused as stale-landing"
  [ "$(git -C "$R" rev-parse main)" = "$main" ] || fail "main moved on a stale landing"

  # A docs-only commit on the story branch after the build changes the landing's tree, not its base.
  project local
  land
  sha="$(jq -r .sha <<< "$OUT")" main="$(git -C "$R" rev-parse main)"
  printf 'note\n' > "$W/docs/note.md"
  git -C "$W" add docs/note.md && git -C "$W" commit -qm 'a later note'
  land --sha "$sha"
  [ "$STATUS" -eq 1 ] || fail "a landing missing a later story commit exited $STATUS: $OUT"
  is '.error == "stale-landing"' "a landing missing a later story commit is not refused as stale-landing"
  [ "$(git -C "$R" rev-parse main)" = "$main" ] || fail "main moved on a landing missing a later story commit"

  project pr
  land --land
  [ "$STATUS" -eq 2 ] || fail "--land under pr exited $STATUS: $OUT"
  is '.error == "usage"' "--land under pr is not a usage refusal"
  land --sha "$(git -C "$R" rev-parse main)"
  [ "$STATUS" -eq 2 ] || fail "--sha under pr exited $STATUS: $OUT"
  is '.error == "usage"' "--sha under pr is not a usage refusal"
}

# rerun_finds_the_landing <label> [<file> <content>]: lands s01-a with --land, moves main past it by
# writing <content> to <file> (later.txt by default), reruns; the rerun reports the landing, writes
# nothing, main holds one commit of the story and keeps the later work.
rerun_finds_the_landing() {
  local file="${2:-later.txt}" content="${3:-later}"
  land --land
  [ "$STATUS" -eq 0 ] || fail "$1: po ship land --land exited $STATUS: $OUT $(cat "$SCRATCH/stderr")"
  local landing before; landing="$(git -C "$R" rev-parse main)"
  printf '%s\n' "$content" > "$R/$file"
  git -C "$R" add "$file" && git -C "$R" commit -qm 'main moves on'
  before="$(snapshot)"
  land --land
  [ "$STATUS" -eq 0 ] || fail "$1: a rerun after the landing exited $STATUS: $OUT"
  one_object "$1: a rerun after the landing"
  is '.already_landed == true and .landed == true and .sha == "'"$landing"'" and .checks == [] and .committed == null' \
    "$1: a rerun after the landing is not reported as already landed"
  [ "$(snapshot)" = "$before" ] || fail "$1: a rerun after the landing still wrote: $(diff <(echo "$before") <(snapshot))"
  [ "$(git -C "$R" log --format=%s main | grep -c '^s01-a: ')" = 1 ] || fail "$1: main holds more than one commit of s01-a"
  git -C "$R" merge-base --is-ancestor "$(jq -r .sha <<< "$OUT")" main || fail "$1: the reported sha is not on main"
  [ "$(git -C "$R" show "main:$file")" = "$content" ] || fail "$1: the later work on main was undone"
}

test_rerun_after_later_work_on_the_story_lines() {
  need_po
  # The next story edits the line s01-a changed: a three-way merge would conflict.
  project local
  rerun_finds_the_landing "a later edit" code.txt three
  # A later commit reverts what s01-a brought: a three-way merge would put it back.
  project local
  rerun_finds_the_landing "a later revert" code.txt one
}

test_branch_bringing_nothing() {
  need_po
  # No commit of its own, and no commit of main carries its subject: nothing ever landed.
  project local
  git -C "$W" reset -q --hard main
  REVIEWED="$(git -C "$W" rev-parse 'HEAD^{tree}')"
  review yes
  local before; before="$(snapshot)"
  land --land
  [ "$STATUS" -eq 1 ] || fail "a story branch bringing nothing exited $STATUS: $OUT"
  one_object "a story branch bringing nothing"
  is '.error == "nothing-to-land"' "a story branch bringing nothing is not refused as nothing-to-land"
  [ "$(snapshot)" = "$before" ] || fail "a story branch bringing nothing still wrote"

  # The base already holds the story's change under another subject: that is a landing.
  project local
  printf 'two\n' > "$R/code.txt"
  git -C "$R" commit -qam 'the same change, another title'
  before="$(snapshot)"
  land --land
  [ "$STATUS" -eq 0 ] || fail "a base holding the story's change exited $STATUS: $OUT"
  is '.already_landed == true and .sha == "'"$(git -C "$R" rev-parse main)"'" and .checks == []' \
    "a base holding the story's change is not reported as already landed"
  [ "$(snapshot)" = "$before" ] || fail "a base holding the story's change still wrote"
}

test_rerun_after_landing_writes_nothing() {
  need_po
  # Full suite: ship — a rerun that reached the checks would append record rows.
  project local
  rerun_finds_the_landing "checks append rows"

  # Full suite: execute-end with the suite recorded — a rerun that reached the checks would append
  # nothing and land an empty second commit.
  project local
  mkdir -p "$W/docs/verif"
  printf '# Verification\n\nTree: %s\n\n## Checks\n| Check | Command | Note |\n| --- | --- | --- |\n| Unit suite | `true` | |\n\nVerification status: complete\n\n' \
    "$REVIEWED" > "$W/docs/verif/s01-a.md"
  (cd "$W" && bash .polype/hooks/po-run.sh --story s01-a --label 'Unit suite' -- true) >/dev/null
  set_setting 'Full suite' execute-end
  rerun_finds_the_landing "suite recorded"
}

test_rerun_after_a_merged_pull_request() {
  need_po
  project pr
  land
  [ "$STATUS" -eq 0 ] || fail "po ship land exited $STATUS: $OUT $(cat "$SCRATCH/stderr")"
  local landing before; landing="$(jq -r .sha <<< "$OUT")"
  # The pull request merged as a rebase merge would, then origin's main moved on.
  git -C "$R" push -q origin "$landing:refs/heads/main"
  git -C "$R" checkout -q --detach "$landing"
  printf 'later\n' > "$R/later.txt"
  git -C "$R" add later.txt && git -C "$R" commit -qm 'main moves on'
  git -C "$R" push -q origin HEAD:refs/heads/main
  git -C "$R" checkout -q main
  git -C "$R" fetch -q origin
  before="$(snapshot)"
  land
  [ "$STATUS" -eq 0 ] || fail "a rerun after the merge exited $STATUS: $OUT"
  is '.already_landed == true and .sha == "'"$landing"'" and .checks == [] and .committed == null' \
    "a rerun after the merge is not reported as already landed"
  [ "$(snapshot)" = "$before" ] || fail "a rerun after the merge still wrote: $(diff <(echo "$before") <(snapshot))"
}

test_land_needs_automatic() {
  need_po
  project local
  set_setting 'Ship confirmation' human
  local before; before="$(snapshot)"
  land --land
  [ "$STATUS" -eq 1 ] || fail "--land under Ship confirmation: human exited $STATUS: $OUT"
  one_object "--land under Ship confirmation: human"
  is '.error == "confirmation-required"' "--land under human is not refused as confirmation-required"
  [ "$(snapshot)" = "$before" ] || fail "--land under human still wrote"
  set_setting 'Ship confirmation' 'automatic (chosen)'
  land --land
  [ "$STATUS" -eq 0 ] || fail "--land under automatic (chosen) exited $STATUS: $OUT"
  is '.landed == true' "--land under automatic (chosen) did not land"
}

test_e2e_and_build_run_at_ship() {
  need_po
  project pr
  set_setting 'E2E stage' ship
  set_setting E2E true
  set_setting 'Build stage' ship
  set_setting Build false
  land
  [ "$STATUS" -eq 1 ] || fail "a failing build at ship exited $STATUS: $OUT"
  is '.error == "check-failed" and .check == "build"' "the failing build is not the check reported"
  is '.checks == [{"check": "unit suite", "outcome": "passed", "command": "true"}, {"check": "end to end", "outcome": "passed", "command": "true"}]' \
    "the end-to-end run is not reported before the build"
  set_setting 'Build stage' ship-if-route
  land --routes yes
  [ "$STATUS" -eq 1 ] || fail "--routes yes did not run the build: $STATUS $OUT"
  is '.error == "check-failed" and .check == "build"' "--routes yes did not run the build"
}
