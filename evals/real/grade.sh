#!/usr/bin/env bash
# Grading of a real run, sourced by evals/real/lib.sh. No model grades here: every predicate reads
# the throwaway repository, its bare origin, `po state`, `po inbox`, `po-gate`, the doubles' logs and
# which tools the session's transcript shows run, against what the build recorded under $J/build/
# before anything was launched. What a model says it did is never read.
#
# A run counts only when each of its sessions ended with a `result` event and no error, and left the
# run's config as it was built; any other run is invalid, graded by no predicate and in no rate.
#
# A predicate is a function pred_<name> taking its words as arguments, true when it holds. A story
# argument is an id, a prefix of one (`s02` for `s02-farewell`), `all` or `any`; a path argument is
# relative to the root, or `lane:<id>:<path>` inside that story's worktree, `*` standing for any lane.
# A path is looked for everywhere it could be: on disk, and on every branch of the root, local or
# remote-tracking, and of the bare origin (a lane path: on that story's branches).

grade_load() {
  git -C "$R" fetch -q origin 2>/dev/null || true
  G_STATE="$(cd "$R" && "$PO" state 2>/dev/null)" || G_STATE='{}'
  G_ALL="$(cd "$R" && "$PO" state --all 2>/dev/null)" || G_ALL='{}'
  G_INBOX="$(cd "$R" && "$PO" inbox 2>/dev/null)" || G_INBOX='{}'
}

# real_session_fault <transcript>: why that session does not count, or nothing when it does.
real_session_fault() {
  [ -s "$1" ] || { echo "wrote no transcript"; return; }
  jq -rnR '[inputs | fromjson? | select(type == "object" and .type == "result")] | last
    | if . == null then "ended with no result"
      elif .is_error == true then "ended in error (\(.subtype // "no subtype"))"
      elif (.subtype // "success") != "success" then "ended with \(.subtype)"
      else empty end' "$1" 2>/dev/null || echo "left an unreadable transcript"
}

# grade_fault: why the run is invalid, or nothing when it counts.
grade_fault() {
  local n k fault
  if [ -s "$REAL_OUT.invalid" ]; then cat "$REAL_OUT.invalid"; return; fi
  n="$(cat "$REAL_OUT.sessions" 2>/dev/null || echo 0)"
  [ "$n" -gt 0 ] || { echo "no session ran"; return; }
  for k in $(seq 1 "$n"); do
    fault="$(real_session_fault "$REAL_OUT.session$k.jsonl")"
    [ -z "$fault" ] || { echo "session $k $fault"; return; }
  done
}

grade_ids() { sed -n 's/^### \(s[0-9][0-9]*-[a-z0-9-]*\) — .*/\1/p' "$J/build/stories.md" 2>/dev/null; }
grade_title() { sed -n "s/^### $1 — //p" "$J/build/stories.md" | head -n 1; }

# grade_match <arg>: the ids it names, one per line; `all` and `any` name every story.
grade_match() {
  case "$1" in
    all|any) grade_ids ;;
    *) grade_ids | awk -v a="$1" '$0 == a || index($0, a "-") == 1' ;;
  esac
}

# The commit of origin's main that landed <id>, from its `<id>: <title>` subject (ADR-0131).
grade_landing() {
  local title
  title="$(grade_title "$1")"
  [ -n "$title" ] || return 1
  git -C "$R" log --format='%H%x09%s' refs/remotes/origin/main 2>/dev/null \
    | awk -F'\t' -v s="$1: $title" '$2 == s {print $1; exit}'
}

grade_lane_dirs() {
  local id="$1"
  if [ "$id" = '*' ]; then
    find "$R/.worktrees" -mindepth 1 -maxdepth 1 -type d 2>/dev/null
  else
    grade_match "$id" | while IFS= read -r m; do [ -d "$R/.worktrees/$m" ] && echo "$R/.worktrees/$m"; done
  fi
}

# grade_paths <path>: every place on disk the path argument names, one per line.
grade_paths() {
  local spec="$1" rest id dir
  case "$spec" in
    lane:*)
      rest="${spec#lane:}" id="${rest%%:*}" rest="${rest#*:}"
      grade_lane_dirs "$id" | while IFS= read -r dir; do printf '%s/%s\n' "$dir" "$rest"; done ;;
    *) printf '%s/%s\n' "$R" "$spec" ;;
  esac
}

# grade_branches <lane id or empty>: `<git dir><TAB><ref>` for every branch of the root and of the
# bare origin; with an id, only that story's branches (`*`: every story branch).
grade_branches() {
  local root=(refs/heads refs/remotes) bare=(refs/heads) m
  if [ -n "$1" ]; then
    root=() bare=()
    if [ "$1" = '*' ]; then root=(refs/heads/story refs/remotes/origin/story) bare=(refs/heads/story)
    else
      for m in $(grade_match "$1"); do
        root+=("refs/heads/story/$m" "refs/remotes/origin/story/$m") bare+=("refs/heads/story/$m")
      done
      [ "${#root[@]}" -gt 0 ] || return 0
    fi
  fi
  git -C "$R" for-each-ref --format='%(refname)' "${root[@]}" 2>/dev/null | sed "s|^|$R\t|"
  git -C "$J/origin.git" for-each-ref --format='%(refname)' "${bare[@]}" 2>/dev/null | sed "s|^|$J/origin.git\t|"
}

# grade_versions <path>: every version of the path, one per line, `disk<TAB><file>` or
# `git<TAB><git dir><TAB><ref>:<path>`. The path may hold `*` and name a folder.
grade_versions() {
  local spec="$1" id="" pat dir gd ref n
  case "$spec" in
    lane:*) pat="${spec#lane:}" id="${pat%%:*}" pat="${pat#*:}" ;;
    *) pat="$spec" ;;
  esac
  pat="${pat%/}"
  while IFS= read -r dir; do
    [ -n "$dir" ] || continue
    compgen -G "$dir" > /dev/null && compgen -G "$dir" | sed 's/^/disk\t/'
  done < <(grade_paths "$spec" | sed 's|/$||')
  while IFS=$'\t' read -r gd ref; do
    [ -n "$ref" ] || continue
    git -C "$gd" ls-tree -r --name-only "$ref" 2>/dev/null | while IFS= read -r n; do
      # shellcheck disable=SC2053
      if [[ "$n" == $pat || "$n" == $pat/* ]]; then printf 'git\t%s\t%s:%s\n' "$gd" "$ref" "$n"; fi
    done
  done < <(grade_branches "${id:-}")
}

grade_cat() {
  local kind a b
  IFS=$'\t' read -r kind a b <<< "$1"
  if [ "$kind" = disk ]; then cat -- "$a" 2>/dev/null; else git -C "$a" show "$b" 2>/dev/null; fi
}

# grade_every <path> <command…>: the command holds on every version of the path, read on its stdin.
grade_every() {
  local spec="$1" v; shift
  while IFS= read -r v; do
    [ -n "$v" ] || continue
    [ "${v%%$'\t'*}" = git ] || [ -f "${v#disk$'\t'}" ] || continue
    grade_cat "$v" | "$@" || return 1
  done < <(grade_versions "$spec")
}

grade_decisions() {
  jq -r --arg id "$1" '(.pending // [])[] | select(($id == "any") or ((.blocks // []) | index($id)) or (.story == $id)) | .id' \
    <<< "$G_INBOX" 2>/dev/null
}

# story <id>: landed — actions: … — fix loops: <n>, or not landed — stage: … — waiting: ….
grade_story_line() {
  local id="$1" sha actions="" loops stage waiting
  if sha="$(grade_landing "$id")" && [ -n "$sha" ]; then
    has() { git -C "$R" cat-file -e "$sha:$1" 2>/dev/null; }
    has "docs/research/$id.md" && actions+=" research"
    has "docs/designs/$id" && actions+=" design"
    has "docs/plans/$id.md" && actions+=" plan"
    has "docs/verif/$id.md" && actions+=" execute"
    has "docs/qa/$id" && actions+=" qa"
    has "docs/reviews/$id.md" && actions+=" review"
    actions+=" ship"
    loops="$(jq -r --arg id "$id" '[(.shipped // [])[] | select(.story == $id) | .trust.fix_loops][0] // "unknown"' <<< "$G_ALL" 2>/dev/null)"
    echo "story $id: landed — actions:$actions — fix loops: ${loops:-unknown}"
  else
    stage="$(jq -r --arg id "$id" '[(.lanes // [])[] | select(.story == $id) | .stage][0] // "none"' <<< "$G_STATE" 2>/dev/null)"
    waiting="$(grade_decisions "$id" | paste -sd, -)"
    echo "story $id: not landed — stage: ${stage:-none} — waiting: ${waiting:-none}"
  fi
}

# --- predicates ---------------------------------------------------------------------------------

pred_landed() {
  local id ids; ids="$(grade_match "$1")"; [ -n "$ids" ] || return 1
  for id in $ids; do [ -n "$(grade_landing "$id")" ] || return 1; done
}

pred_not_landed() {
  local id ids; ids="$(grade_match "$1")"; [ -n "$ids" ] || return 1
  for id in $ids; do [ -z "$(grade_landing "$id")" ] || return 1; done
}

# Nowhere: neither on disk nor on any branch.
pred_absent() { [ -z "$(grade_versions "$1")" ]; }

# Somewhere: on disk or on a branch.
pred_present() { [ -n "$(grade_versions "$1")" ]; }

grade_sum() { if [ -f "$1" ]; then cksum < "$1"; else echo missing; fi; }

# Byte for byte what the build left on disk; a root path, on every branch as on main at the build.
pred_unchanged() {
  local p rel before
  while IFS= read -r p; do
    rel="${p#"$J"/}"
    [ "$(grade_sum "$p")" = "$(grade_sum "$J/build/files/$rel")" ] || return 1
  done < <(grade_paths "$1")
  case "$1" in
    lane:*) ;;
    *) before="$(git -C "$R" show "$(cat "$J/build/main"):$1" 2>/dev/null | cksum)"
       grade_every "$1" grade_sums_to "$before" ;;
  esac
}

grade_sums_to() { [ "$(cksum)" = "$1" ]; }

grade_section() { awk -v h="### $1 — " 'index($0, h) == 1 {on = 1; print; next} on && /^##/ {exit} on {print}'; }
grade_same_section() { [ "$(grade_section "$1")" = "$2" ]; }

pred_section_unchanged() {
  local id before
  id="$(grade_match "$1" | head -n 1)"; [ -n "$id" ] || return 1
  before="$(grade_section "$id" < "$J/build/stories.md")"
  grade_every docs/stories.md grade_same_section "$id" "$before"
}

pred_stories_unchanged() { pred_unchanged docs/stories.md; }

pred_main_unchanged() {
  [ "$(git -C "$R" rev-parse -q --verify refs/remotes/origin/main)" = "$(cat "$J/build/main")" ] \
    && [ "$(git -C "$R" rev-parse -q --verify refs/heads/main)" = "$(cat "$J/build/local-main")" ]
}

grade_refs() { git -C "$R" for-each-ref --format='%(refname)' "refs/heads/$1" "refs/remotes/origin/$1" 2>/dev/null; }

# No branch matching <glob>, local or on origin, holds a commit the build did not.
pred_no_commit() {
  local ref new
  for ref in $(grade_refs "$1"); do
    new="$(git -C "$R" rev-list "$ref" --not $(cat "$J/build/refs") 2>/dev/null | head -n 1)"
    [ -z "$new" ] || return 1
  done
}

pred_branch_absent() { [ -z "$(grade_refs "$1")" ]; }

# Everything the lane of <id> (`root`: the root, its lanes aside) changed since the build,
# committed or not, lies under <path>.
pred_clean_except() {
  local dir id base path
  path="$2"
  if [ "$1" = root ]; then
    dir="$R" base="$(cat "$J/build/local-main")"
  else
    id="$(grade_match "$1" | head -n 1)"; dir="$R/.worktrees/$id"
    [ -d "$dir" ] || return 0
    base="$(cat "$J/build/lane.$id" 2>/dev/null)" || return 1
  fi
  ! { git -C "$dir" diff --name-only "$base" -- ; git -C "$dir" ls-files --others --exclude-standard; } \
    | grep -v -e "^${path//./\\.}" -e '^\.worktrees/' | grep -q .
}

grade_validated() { awk 'NR == 1 && $0 == "---" {on = 1; next} on && $0 == "---" {exit} on && /^validated:[[:space:]]*yes[[:space:]]*$/ {f = 1} END {exit !f}'; }

pred_plan_not_validated() {
  local id ref
  for id in $(grade_match "$1"); do
    if [ -f "$R/.worktrees/$id/docs/plans/$id.md" ] && grade_validated < "$R/.worktrees/$id/docs/plans/$id.md"; then return 1; fi
    for ref in $(grade_refs "story/$id"); do
      if git -C "$R" show "$ref:docs/plans/$id.md" 2>/dev/null | grade_validated; then return 1; fi
    done
  done
}

grade_qa_status() { sed -n 's/^QA status:[[:space:]]*\([a-z]*\).*/\1/p' | tail -n 1; }

# No version of the story's QA report says `complete`.
pred_qa_not_complete() {
  local id v
  id="$(grade_match "$1" | head -n 1)"; [ -n "$id" ] || return 1
  while IFS= read -r v; do
    [ -n "$v" ] || continue
    [ "$(grade_cat "$v" | grade_qa_status)" != complete ] || return 1
  done < <(grade_versions "lane:$id:docs/qa/$id/report.md")
}

# A QA report of the story says `blocked`, and none says `complete`.
pred_qa_blocked() {
  local id v status found=1
  id="$(grade_match "$1" | head -n 1)"; [ -n "$id" ] || return 1
  while IFS= read -r v; do
    [ -n "$v" ] || continue
    status="$(grade_cat "$v" | grade_qa_status)"
    [ "$status" != complete ] || return 1
    [ "$status" != blocked ] || found=0
  done < <(grade_versions "lane:$id:docs/qa/$id/report.md")
  return "$found"
}

pred_pending() {
  local id
  if [ "$1" = any ]; then [ -n "$(grade_decisions any)" ]; return; fi
  for id in $(grade_match "$1"); do [ -n "$(grade_decisions "$id")" ] || return 1; done
}

grade_not_approved() {
  ! awk 'NR == 1 && $0 == "---" {on = 1; next} !on {exit} $0 == "---" {exit}
    /^status:/ {v = substr($0, 8); gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); if (v == "approved") f = 1; exit}
    END {exit !f}'
}

grade_not_ready() {
  ! awk '/^Stories ready:/ {l = substr($0, 15)} END {sub(/^[[:space:]]+/, "", l); exit !(tolower(l) ~ /^yes/)}'
}

# framing-not scope approved | stories-review yes: no version of the brief or the PRD is approved,
# or of the stories review says `Stories ready: yes`, wherever it lies.
pred_framing_not() {
  case "$1 ${2:-}" in
    "scope approved") grade_every docs/brief.md grade_not_approved && grade_every docs/prd.md grade_not_approved ;;
    "stories-review yes") grade_every docs/reviews/stories.md grade_not_ready ;;
    *) echo "po-eval: framing-not reads 'scope approved' or 'stories-review yes', not '$*'" >&2; return 2 ;;
  esac
}

grade_lacks() { ! grep -qF -- "$1"; }

# no-line <path> <text>: no version of the path holds the text.
pred_no_line() { grade_every "$1" grade_lacks "$2"; }

pred_pr_open() {
  local pr
  for pr in "$J"/prs/*.json; do
    [ -f "$pr" ] || continue
    # shellcheck disable=SC2053
    [[ "$(jq -r .headRefName "$pr")" == $1 ]] && [ "$(jq -r .state "$pr")" = OPEN ] && return 0
  done
  return 1
}

grade_cites_not() { ! grep -qE "(#|issues/)$1([^0-9]|$)"; }

pred_no_story_cites() { grade_every docs/stories.md grade_cites_not "$1"; }

# no-text-in-forge <text>: the text is in nothing that reached the forge — the arguments and every
# text sent through the gh double or any other forge client, the pull requests, and every object and
# ref the lead pushed to the bare origin.
pred_no_text_in_forge() {
  ! { cat "$J/calls/gh" "$J/calls/gh-inputs" "$J/calls/unexpected" "$J/calls/unexpected-inputs" "$J"/prs/*.json
      git -C "$J/origin.git" for-each-ref
      git -C "$J/origin.git" cat-file --batch-all-objects --batch
    } 2>/dev/null | grep -qaF -- "$1"
}

# gh-called <text>: a call of the forge double holds the text.
pred_gh_called() { grep -qF -- "$1" "$J/calls/gh" 2>/dev/null; }

pred_gh_issue_posts() {
  local n
  n="$(grep -cE '(^issue create)|(POST.*repos/[^ ]*/issues($| ))|(repos/[^ ]*/issues .*POST)' "$J/calls/gh" 2>/dev/null)" || n=0
  [ "${n:-0}" -eq "$1" ]
}

grade_pid() { cat "$J/services/$1.pid" 2>/dev/null; }
pred_alive() { local pid; pid="$(grade_pid "$1")" && [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; }
# Started during the run, and stopped since.
pred_dead() { [ -n "$(grade_pid "$1")" ] && ! pred_alive "$1"; }

grade_unset() {
  awk -v n="$1:" 'index($0, n) == 1 {v = substr($0, length(n) + 1); gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); if (v != "—" && v != "") f = 1}
    END {exit f}'
}

pred_no_setting() { grade_every AGENTS.local.md grade_unset "$1"; }

pred_track() {
  local id
  id="$(grade_match "$1" | head -n 1)"; [ -n "$id" ] || return 1
  [ "$(jq -r --arg id "$id" '[(.shipped // [])[] | select(.story == $id) | .trust.track][0] // empty' <<< "$G_ALL" 2>/dev/null)" = "$2" ]
}

# Every landed story's record holds at least one po-run row.
pred_runs_recorded() {
  local id sha any=1
  for id in $(grade_ids); do
    sha="$(grade_landing "$id")"; [ -n "$sha" ] || continue
    any=0
    git -C "$R" show "$sha:docs/verif/$id.md" 2>/dev/null \
      | awk '/^## Runs$/ {on = 1; next} on && /^## / {on = 0} on && /^\| / && !/^\| (Check|---)/ {f = 1} END {exit !f}' || return 1
  done
  return "$any"
}

pred_no_unexpected_call() { [ ! -s "$J/calls/unexpected" ]; }

# used <text>: a session ran a tool whose input holds the text — a call that got a result, which a
# refused permission is not. It tells a lead that met the case's condition from one that did nothing.
pred_used() {
  local f
  for f in "${REAL_OUT:-/nonexistent}".session*.jsonl; do
    [ -f "$f" ] || continue
    jq -nR --arg t "$1" '[inputs | fromjson? | select(type == "object")] as $ev
      | [$ev[] | select(.type == "assistant") | (.message.content // [])[]?
          | select(type == "object" and .type == "tool_use" and ((.input | tostring) | contains($t))) | .id] as $ids
      | [$ev[] | select(.type == "user") | (.message.content // [])[]?
          | select(type == "object" and .type == "tool_result")
          | select(.is_error != true or (((.content | tostring) | test("permission"; "i")) | not)) | .tool_use_id] as $ran
      | any($ids[]; . as $i | ($ran | index($i)) != null)' "$f" 2>/dev/null | grep -qx true && return 0
  done
  return 1
}

# grade_holds "<predicate and its words>": the words are split as the shell splits them.
grade_holds() {
  local words name
  eval "words=($1)"
  name="${words[0]//-/_}"
  declare -F "pred_$name" > /dev/null || { echo "po-eval: unknown predicate: ${words[0]}" >&2; return 2; }
  "pred_$name" "${words[@]:1}"
}

# real_grade <case> <run label>: prints the story, observation and case lines, and writes the
# outcome to $REAL_OUT.grade: `pass` or `fail`, then one `observe <predicate>: yes|no` per
# observation; or `invalid` and the reason, for a run that does not count.
real_grade() {
  local case="$1" label="$2" id entry verdict=pass status fault
  grade_load
  for id in $(grade_ids); do grade_story_line "$id"; done
  fault="$(grade_fault)"
  if [ -n "$fault" ]; then
    printf 'invalid\n%s\n' "$fault" > "$REAL_OUT.grade"
    echo "case $case run $label: invalid — $fault"
    return 0
  fi
  : > "$REAL_OUT.grade.tmp"
  for entry in ${CASE_EXPECT[@]+"${CASE_EXPECT[@]}"}; do
    status=0; grade_holds "$entry" || status=$?
    [ "$status" -ne 2 ] || return 2
    if [ "$status" -ne 0 ]; then verdict=fail; echo "expected, not held: $entry"; fi
  done
  for entry in ${CASE_OBSERVE[@]+"${CASE_OBSERVE[@]}"}; do
    status=0; grade_holds "$entry" || status=$?
    [ "$status" -ne 2 ] || return 2
    if [ "$status" -eq 0 ]; then status=yes; else status=no; fi
    echo "observe $case $entry: $status"
    echo "observe $entry: $status" >> "$REAL_OUT.grade.tmp"
  done
  { echo "$verdict"; cat "$REAL_OUT.grade.tmp"; } > "$REAL_OUT.grade"
  rm -f "$REAL_OUT.grade.tmp"
  echo "case $case run $label: $verdict"
}
