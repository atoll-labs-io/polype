#!/usr/bin/env bash
# s176 — the oracle of the story: `po state` carries what po-session prints at session start, the
# framing per item, each lane's path and every stop of a lane, so the hook can stop deriving it.

PO="${PO:-${CARGO_TARGET_DIR:-$ROOT/po/target}/release/po}"
HOOK="$METHOD/hooks/po-session.sh"

need_po() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO (tests/run.sh builds it before the suite)"
}

# A Polype project in $R, as tests/project-lead.test.sh builds it: AGENTS.local.md with the given
# extra settings, nothing committed yet.
polype_repo() {
  scratch_repo
  CLEANUP="${CLEANUP-} $SCRATCH"
  trap 'rm -rf $CLEANUP' EXIT
  R="$(cd "$SCRATCH" && pwd -P)"
  {
    printf 'Target branch: main\nWorktree root: .worktrees/\nEntry mode: new\n'
    printf '%s\n' "$@"
  } > "$R/AGENTS.local.md"
  printf '.worktrees/\n' > "$R/.gitignore"
}

commit_all() { git -C "$R" add -A && git -C "$R" commit -qm "${1:-framing}"; }
set_setting() { sed -i "s/^$1:.*/$1: $2/" "$R/AGENTS.local.md"; }
approved_brief() { mkdir -p "$R/docs"; printf -- '---\nstatus: approved\n---\n# Brief\n' > "$R/docs/brief.md"; }
lane() { git -C "$R" worktree add -q -b "story/$1" "${2:-$R/.worktrees}/$1" main; }
lane_file() { mkdir -p "$(dirname "$R/.worktrees/$1/$2")"; printf '%s\n' "${@:3}" > "$R/.worktrees/$1/$2"; }

# po_state [<dir>]: sets OUT to po state run in <dir> (the project root by default).
po_state() { OUT="$(cd "${1:-$R}" && "$PO" state 2>/dev/null)" || fail "po state failed in ${1:-$R}: $OUT"; }

# stories <surface>...: one story per surface, s01-a, s02-b, …
stories() {
  local n=0 surface
  mkdir -p "$R/docs"
  { printf '# Stories\n\n## M1 — One\n\n'
    for surface in "$@"; do n=$((n + 1)); printf '### s%02d-x — X\n- **Surface** : %s\n\n' "$n" "$surface"; done
  } > "$R/docs/stories.md"
}

# framing_is <stage> <next|null> <scope> <stories> <stories review> <architecture> <design system>
framing_is() {
  local got want
  po_state
  want="$(jq -Scn --arg stage "$1" --arg next "$2" --arg a "$3" --arg b "$4" --arg c "$5" --arg d "$6" --arg e "$7" '{
    stage: $stage, next: (if $next == "null" then null else $next end),
    items: [{item: "scope", state: $a}, {item: "stories", state: $b}, {item: "stories-review", state: $c},
            {item: "architecture", state: $d}, {item: "design-system", state: $e}]}')"
  got="$(jq -Sc '.framing | {stage, next, items}' <<< "$OUT")"
  [ "$got" = "$want" ] || fail "framing at $1:
      expected: $want
      got:      $got"
}

test_framing_items_are_listed() {
  need_po
  polype_repo 'Max attempts: 2' 'Merge mode: pr' 'Ship confirmation: automatic (chosen)'
  commit_all settings
  framing_is scope /po-brief missing missing none missing missing
  mkdir -p "$R/docs"; printf -- '---\nstatus: interviewing\n---\n# Brief\n' > "$R/docs/brief.md"; commit_all
  framing_is scope /po-brief 'in progress' missing none missing missing
  approved_brief; stories screen command; commit_all
  framing_is stories-review /po-stories-review approved present none missing missing
  mkdir -p "$R/docs/reviews"
  printf 'Stories ready: no\n' > "$R/docs/reviews/stories.md"; commit_all
  framing_is stories-review /po-stories-review approved present no missing missing
  printf 'Stories ready: yes\n' > "$R/docs/reviews/stories.md"; commit_all
  framing_is architecture /po-architect approved present yes missing missing
  printf '# Architecture\n' > "$R/docs/architecture.md"; commit_all
  framing_is design-system /po-design-system approved present yes present missing
  stories command command; commit_all
  framing_is done null approved present yes present 'not needed'
  stories screen; printf '# Design system\n' > "$R/docs/design-system.md"; commit_all
  framing_is done null approved present yes present present
  set_setting 'Entry mode' '—'
  framing_is done null 'by hand' present yes present present

  git -C "$R" rm -qf AGENTS.local.md && commit_all 'no setup'
  mkdir -p "$R/.polype" && echo 0.2.0 > "$R/.polype/version"
  po_state
  jq -e '.framing == {"stage": "setup", "next": "/po-setup", "items": []}' <<< "$OUT" >/dev/null \
    || fail "without AGENTS.local.md, framing is not the setup stage with no item: $(jq -c .framing <<< "$OUT")"
}

test_lanes_carry_their_path() {
  need_po
  polype_repo 'Max attempts: 2' 'Merge mode: pr' 'Ship confirmation: automatic (chosen)'
  commit_all
  lane s01-a
  po_state
  jq -e '[.lanes[] | {story, path}] == [{"story": "s01-a", "path": ".worktrees/s01-a"}]' <<< "$OUT" >/dev/null \
    || fail "the lane's path is not relative to the project root: $(jq -c .lanes <<< "$OUT")"
  po_state "$R/.worktrees/s01-a"
  jq -e '[.lanes[] | {story, path}] == [{"story": "s01-a", "path": ".worktrees/s01-a"}]' <<< "$OUT" >/dev/null \
    || fail "run from the lane, its path is not relative to the main checkout: $(jq -c .lanes <<< "$OUT")"

  local outside
  outside="$(mktemp -d)"
  CLEANUP="$CLEANUP $outside"
  outside="$(cd "$outside" && pwd -P)"
  sed -i "s|^Worktree root:.*|Worktree root: $outside/|" "$R/AGENTS.local.md"
  lane s02-b "$outside"
  po_state
  jq -e --arg p "$outside/s02-b" '[.lanes[] | {story, path}] == [{"story": "s02-b", "path": $p}]' <<< "$OUT" >/dev/null \
    || fail "a lane outside the project does not carry its absolute path $outside/s02-b: $(jq -c .lanes <<< "$OUT")"
}

test_every_stop_of_a_lane_is_listed() {
  need_po
  polype_repo 'Max attempts: 2' 'Merge mode: pr' 'Ship confirmation: human (forge)'
  approved_brief
  commit_all
  lane s11-two
  lane_file s11-two docs/research/s11-two.md '# Research' 'Root cause: not found'
  lane_file s11-two docs/plans/s11-two.md '---' 'validated: no' '---' 'Technical choice: waiting for a human'
  lane s12-qa
  lane_file s12-qa docs/qa/s12-qa/report.md 'QA status: blocked'
  lane_file s12-qa docs/reviews/s12-qa.md 'Review status: complete' 'Fix loop: 3' 'Ship allowed: no'
  lane s14-pr
  lane_file s14-pr docs/reviews/s14-pr.md 'Review status: complete' 'Fix loop: 0' 'Ship allowed: yes'
  git -C "$R" update-ref refs/remotes/origin/story/s14-pr main
  lane s15-plain

  po_state
  local want got
  want="$(jq -Sc . <<'EOF'
[
  {"story": "s11-two", "blocked_by": "root-cause-not-found", "stops": [
    {"code": "root-cause-not-found", "file": "docs/research/s11-two.md"},
    {"code": "technical-choice", "file": "docs/plans/s11-two.md", "command": "/po-plan s11-two"}]},
  {"story": "s12-qa", "blocked_by": "qa-blocked", "stops": [
    {"code": "qa-blocked", "file": "docs/qa/s12-qa/report.md"},
    {"code": "max-attempts", "fix_loop": 3, "max_attempts": 2}]},
  {"story": "s14-pr", "blocked_by": "merge-waiting", "stops": [
    {"code": "merge-waiting", "branch": "story/s14-pr"}]},
  {"story": "s15-plain", "blocked_by": null, "stops": []}
]
EOF
)"
  got="$(jq -Sc '[.lanes[] | {story, blocked_by, stops}] | sort_by(.story)' <<< "$OUT")"
  [ "$got" = "$want" ] || fail "the stops of the lanes are not all listed with their values:
      expected: $want
      got:      $got"
}

# po state formatted as po-session prints its framing, lanes and stops, the CLAUDE.md hint aside.
SESSION_LINES='
def spaced: gsub("-"; " ");
def stop_line($id):
  if .code == "root-cause-not-found" then "\($id): root cause not found (\(.file))"
  elif .code == "technical-choice" then "\($id): technical choice waiting for a human (\(.file)) → \(.command)"
  elif .code == "qa-blocked" then "\($id): QA blocked (\(.file))"
  elif .code == "max-attempts" then "\($id): Max attempts reached (Fix loop: \(.fix_loop), Max attempts: \(.max_attempts))"
  elif .code == "merge-waiting" then "\($id): pull request presumed waiting for a human merge (\(.branch) pushed; the forge was not asked)"
  else "\($id): unknown stop \(.code)" end;
(if .framing == null then empty
 elif .framing.stage == "setup" then "Framing: setup missing → /po-setup"
 else ("Framing: " + ([.framing.items[] | (.item | spaced) + " " + .state] | join(" · "))),
      ("Framing next: " + (.framing.next // "none — framing done"))
 end),
(if .lanes == null then empty
 elif (.lanes | length) == 0 then "Lanes in flight: none"
 else "Lanes in flight: " + ([.lanes[] | .story + " (" + .path + ")"] | join(", ")) end),
(if .lanes == null then empty else
  ([.lanes[] | .story as $id | .stops[] | stop_line($id)]
   + [.warnings[] | select(.code == "orphan-worktree") | "\(.path): orphan worktree (\(.branch // "detached HEAD"))"]) as $l
  | if ($l | length) == 0 then "Waiting for a human: nothing" else ("Waiting for a human:", ($l[] | "- " + .)) end
 end)'

# read_the_same <label>: every framing, lane and stop line po-session prints in $R reads in po state.
read_the_same() {
  local session from_po
  session="$(cd "$R" && CLAUDE_PROJECT_DIR="$R" bash "$HOOK" \
    | grep -E '^(Framing|Lanes in flight:|Waiting for a human|- )' | grep -vE '^- CLAUDE(\.local)?\.md: ')"
  po_state
  from_po="$(jq -r "$SESSION_LINES" <<< "$OUT")" || fail "$1: po state lacks a field po-session prints: $OUT"
  [ "$session" = "$from_po" ] || fail "$1: po state does not read as po-session:
$(diff <(printf '%s\n' "$session") <(printf '%s\n' "$from_po"))"
}

test_session_cases_read_the_same() {
  need_po
  # test_session_hook_reports_state_read_only
  polype_repo 'Max attempts: 2' 'Merge mode: pr' 'Ship confirmation: automatic (chosen)'
  approved_brief
  printf '%s\n' '# Stories' '## s01-a — A' '- **Depends on**: none' '## s02-b — B' '- **Depends on**: s01-a' \
    '## s03-c — C' '- **Dépend de** : s04-d' '## s04-d — D' '- **Depends on**: none' > "$R/docs/stories.md"
  commit_all
  git -C "$R" commit -q --allow-empty -m "s01-a: A"
  lane s04-d
  read_the_same "state read only"

  # test_session_hook_reports_framing_stage
  polype_repo 'Max attempts: 2' 'Merge mode: pr' 'Ship confirmation: automatic (chosen)'
  mkdir -p "$R/docs"
  printf -- '---\nstatus: interviewing\n---\n# Brief\n' > "$R/docs/brief.md"
  commit_all
  read_the_same "framing stage"
  git -C "$R" rm -q AGENTS.local.md && git -C "$R" commit -qm "no setup"
  mkdir -p "$R/.polype" && echo 0.2.0 > "$R/.polype/version"
  read_the_same "no setup"

  # test_session_hook_lists_human_escalations, with a root CLAUDE.md whose hint stays with the hook
  polype_repo 'Max attempts: 2' 'Merge mode: pr' 'Ship confirmation: human (forge)'
  approved_brief
  commit_all
  lane s11-root
  lane_file s11-root docs/research/s11-root.md '# Research' 'Root cause: not found'
  lane_file s11-root docs/plans/s11-root.md '---' 'validated: no' '---'
  lane s12-qa
  lane_file s12-qa docs/qa/s12-qa/report.md 'QA status: complete' 'QA status: blocked'
  lane s13-max
  lane_file s13-max docs/reviews/s13-max.md 'Review status: complete' 'Fix loop: 2' 'Ship allowed: no'
  lane s14-pr
  lane_file s14-pr docs/reviews/s14-pr.md 'Review status: complete' 'Fix loop: 0' 'Ship allowed: yes'
  git -C "$R" update-ref refs/remotes/origin/story/s14-pr main
  git -C "$R" branch -q other main
  git -C "$R" worktree add -q "$R/.worktrees/s15-orphan" other
  printf '# Notes\n' > "$R/CLAUDE.md"
  read_the_same "human escalations"

  # test_session_hook_keeps_ordinary_lanes_out, each of its four states
  polype_repo 'Max attempts: 2' 'Merge mode: pr' 'Ship confirmation: automatic (chosen)'
  approved_brief
  commit_all
  lane s21-loop
  lane_file s21-loop docs/reviews/s21-loop.md 'Review status: complete' 'Fix loop: 1' 'Ship allowed: no'
  lane s22-ok
  lane_file s22-ok docs/reviews/s22-ok.md 'Review status: complete' 'Fix loop: 0' 'Ship allowed: yes'
  lane s23-qa
  lane_file s23-qa docs/reviews/s23-qa.md 'Review status: blocked' 'Fix loop: 2' '- Next action: /po-qa s23-qa' 'Ship allowed: no'
  lane s24-plan
  lane_file s24-plan docs/research/s24-plan.md 'Root cause: not found'
  lane_file s24-plan docs/plans/s24-plan.md '---' 'validated: yes' '---'
  lane s25-qa
  lane_file s25-qa docs/qa/s25-qa/report.md 'QA status: blocked' 'QA status: complete'
  git -C "$R" update-ref refs/remotes/origin/story/s22-ok main
  read_the_same "ordinary lanes"
  set_setting 'Ship confirmation' 'human (forge)'
  git -C "$R" update-ref -d refs/remotes/origin/story/s22-ok
  read_the_same "ordinary lanes, human merge, branch not pushed"
  git -C "$R" update-ref refs/remotes/origin/story/s22-ok main
  set_setting 'Merge mode' 'local'
  read_the_same "ordinary lanes, local merge"
  set_setting 'Merge mode' 'pr'
  git -C "$R" commit -q --allow-empty -m "s22-ok: shipped"
  read_the_same "ordinary lanes, shipped"
}
