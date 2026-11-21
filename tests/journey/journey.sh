#!/usr/bin/env bash
# The replayed journey: walks throwaway stories from po next's `plan` to `<id>: <title>` on Target
# branch with no model, applying one written answer per action through the real gates, po-run,
# po record, po inbox and the five `po ship` sub-steps. Sourced after tests/lib.sh; it only defines
# functions.
#
# Every step is checked by hand rather than through `set -e`: the tests call journey_run inside
# `if` and `||`, where bash ignores `set -e` all the way down.

JOURNEY_SRC="$ROOT/tests/journey"

# The one folder of a journey, removed on any exit but a SIGKILL. An interrupt only exits: the
# EXIT trap does the removal.
journey_init() {
  local made vars
  made="$(mktemp -d "${TMPDIR:-/tmp}/polype-journey.XXXXXX")" || fail "mktemp failed"
  J="$(cd "$made" && pwd -P)" || fail "cannot resolve $made"
  trap 'rm -rf "$J"' EXIT
  trap 'exit 129' HUP
  trap 'exit 130' INT
  trap 'exit 143' TERM
  JOURNEY_LOG="$J/journey.log" R="$J/project" ORIGIN="$J/origin.git"
  mkdir -p "$J/bin" "$J/home" "$J/tmp" "$J/claude" "$J/calls" "$J/private" "$J/bound" || fail "cannot lay out $J"
  : > "$JOURNEY_LOG"
  : > "$J/asks"
  cp "$JOURNEY_SRC/doubles/gh" "$JOURNEY_SRC/doubles/cargo" "$J/bin/" || fail "cannot copy the doubles"
  local tool
  for tool in curl glab tea task claude; do
    cp "$JOURNEY_SRC/doubles/unexpected" "$J/bin/$tool" || fail "cannot copy the $tool double"
  done
  chmod +x "$J/bin/"*
  # git's own list, so a variable git adds later is cleared too (#432).
  vars="$(git rev-parse --local-env-vars)" && [ -n "$vars" ] || fail "git cannot list its location variables"
  # shellcheck disable=SC2086
  unset GH_TOKEN GITHUB_TOKEN JOURNEY_SETUP $vars
  export PATH="$J/bin:$PATH" HOME="$J/home" TMPDIR="$J/tmp" CLAUDE_CONFIG_DIR="$J/claude" JOURNEY_DIR="$J"
  export PO_GH="$J/bin/gh" PO_CURL="$J/bin/curl" PO_GLAB="$J/bin/glab" PO_TEA="$J/bin/tea"
  export PO_SHIP_POLL_SECONDS=0 GIT_ALLOW_PROTOCOL=file LC_ALL=C
}

# The template's settings with the journey's values; every other line stays the template's.
journey_settings() {
  local mode="$1" tracker=—
  [ "$mode" = pr ] && tracker=github
  printf 'Merge mode\t%s\nPlan validation\thuman\nShip confirmation\tautomatic\nFull suite\texecute-end\n' "$mode"
  printf 'E2E stage\t—\nBuild stage\t—\nQA stage\t—\nIssue tracker\t%s\nStory track\tauto\n' "$tracker"
  printf 'Flow threshold\t2\nForge checks\trequired\nPrivate folder\t%s/private/\nTest\tsh checks/run.sh\n' "$J"
}

journey_project() {
  local mode="${1:-}"
  case "$mode" in local|pr) ;; *) fail "journey_project takes local or pr, not '$mode'" ;; esac
  [ ! -e "$R" ] || fail "journey_project installs once per journey: $R exists"
  git init -q -b main "$R" || fail "git init failed"
  git -C "$R" config user.email journey@example.com
  git -C "$R" config user.name journey
  git -C "$R" config commit.gpgsign false
  cp -R "$JOURNEY_SRC/project/." "$R/" || fail "cannot copy the throwaway project"
  journey_settings "$mode" > "$J/settings.tsv"
  {
    printf '# project — Polype settings\n\n```\n'
    awk -F'\t' 'NR == FNR {value[$1] = $2; next}
      /^```/ {fence = !fence; next}
      fence && NF {name = $0; sub(/:.*/, "", name); print (name in value) ? name ": " value[name] : $0}' \
      "$J/settings.tsv" "$ROOT/method/templates/agents-local.md"
    printf '```\n'
  } > "$R/AGENTS.local.md" || fail "cannot write AGENTS.local.md"
  bash "$ROOT/bin/polype" install "$R" --hooks > "$J/install.log" 2>&1 || fail "polype install failed: $(cat "$J/install.log")"
  # The installer's own `cargo build` is the one call to cargo the journey expects.
  if [ -f "$J/calls/cargo" ]; then mv "$J/calls/cargo" "$J/calls/cargo.installer"; fi
  git -C "$R" add -A && git -C "$R" commit -qm 'throwaway project' || fail "cannot commit the throwaway project"
  [ "$mode" = pr ] || return 0
  git init -q --bare -b main "$ORIGIN" || fail "cannot create the bare origin"
  git -C "$R" remote add origin https://github.com/acme/project.git
  git -C "$R" config "url.$ORIGIN.insteadOf" https://github.com/acme/project.git
  # The journey's own setup pushes are not logged: only what po pushes is.
  printf '#!/usr/bin/env bash\n[ -n "${JOURNEY_SETUP:-}" ] || echo "$1" >> %q\n' "$J/calls/pushed" > "$ORIGIN/hooks/update"
  chmod +x "$ORIGIN/hooks/update"
  JOURNEY_SETUP=1 git -C "$R" push -q origin main || fail "cannot push main to the bare origin"
}

# journey_kind <local|screen|pr-human>: built once per journey folder, then restored from its snapshot.
journey_kind() {
  local kind="${1:-}"
  case "$kind" in local|screen|pr-human) ;; *) fail "journey_kind takes local, screen or pr-human, not '$kind'" ;; esac
  rm -rf "$J/bound" && mkdir -p "$J/bound" || fail "cannot empty $J/bound"
  if [ -d "$J/snapshots/kind.$kind/project" ]; then
    journey_restore "kind.$kind"
    return 0
  fi
  rm -rf "$R" "$ORIGIN" "$J/prs" "$J/count" || fail "cannot remove the previous project"
  rm -f "$J/calls/"* && : > "$JOURNEY_LOG"
  case "$kind" in
    local) journey_project local ;;
    screen)
      journey_project local
      journey_setting 'QA stage' screens
      journey_setting 'Design source' internal ;;
    pr-human)
      journey_project pr
      journey_setting 'Ship confirmation' 'human (chosen)' ;;
  esac
  journey_snapshot "kind.$kind"
}

# Commits on main what the setup changed, and pushes it when the project has an origin.
journey_commit_setup() {
  git -C "$R" commit -qam "$1" || fail "cannot commit: $1"
  if [ -d "$ORIGIN" ]; then
    JOURNEY_SETUP=1 git -C "$R" push -q origin main || fail "cannot push: $1"
  fi
}

journey_setting() {
  local name="${1:-}" value="${2:-}" file="$R/AGENTS.local.md"
  grep -q "^$name:" "$file" || fail "AGENTS.local.md has no line $name:"
  awk -v name="$name" -v value="$value" 'index($0, name ":") == 1 {$0 = name ": " value} {print}' "$file" > "$file.new" \
    && mv "$file.new" "$file" || fail "cannot set $name"
  journey_commit_setup "setting $name"
}

# journey_story_set <id> <field> <value>: a value of `-` removes the field's line.
journey_story_set() {
  local id="$1" field="$2" value="$3" file="$R/docs/stories.md"
  awk -v id="$id" -v key="- **$field** :" -v value="$value" '
    /^##/ {inside = (index($0, "### " id " — ") == 1)}
    inside && index($0, key) == 1 {found = 1; if (value == "-") next; $0 = key " " value}
    {print}
    END {exit !found}' "$file" > "$file.new" || fail "the story $id has no field $field"
  mv "$file.new" "$file" || fail "cannot rewrite $file"
  journey_commit_setup "story $id: $field"
}

# journey_answers <id> <dir> [<dir>…]: each file is taken from the first folder that holds it.
journey_answers() {
  local id="${1:-}" dir
  [ -n "$id" ] && [ $# -ge 2 ] || fail "journey_answers <id> <dir> [<dir>…]"
  shift
  for dir in "$@"; do [ -d "$dir" ] || fail "journey_answers: no answers folder at '$dir'"; done
  printf '%s\n' "$@" > "$J/bound/$id"
}

journey_story() {
  local id="$1" title="$2" answers="${3:-$JOURNEY_SRC/answers/plain}"
  printf '\n### %s — %s\n\n- **Complexité** : 3\n- **Surface** : command\n- **Owns** : `src/%s.txt`, `checks/%s.check`\n' \
    "$id" "$title" "$id" "$id" >> "$R/docs/stories.md" || fail "cannot write the story $id"
  git -C "$R" add docs/stories.md && git -C "$R" commit -qm "story $id" || fail "cannot commit the story $id"
  if [ -d "$ORIGIN" ]; then
    JOURNEY_SETUP=1 git -C "$R" push -q origin main || fail "cannot push the story $id"
  fi
  journey_answers "$id" "$answers"
}

journey_snapshot_dir() { if [ -n "${1:-}" ]; then printf '%s\n' "$J/snapshots/$1"; else printf '%s\n' "$J/snapshot"; fi; }

journey_snapshot() {
  local dir; dir="$(journey_snapshot_dir "${1:-}")"
  rm -rf "$dir" && mkdir -p "$dir" || fail "cannot make the snapshot folder"
  cp -a "$R" "$dir/project" || fail "cannot snapshot the project"
  if [ -d "$ORIGIN" ]; then cp -a "$ORIGIN" "$dir/origin.git" || fail "cannot snapshot origin"; fi
  if [ -d "$J/prs" ]; then cp -a "$J/prs" "$dir/prs" || fail "cannot snapshot the pull requests"; fi
}

journey_restore() {
  local dir; dir="$(journey_snapshot_dir "${1:-}")"
  [ -d "$dir/project" ] || fail "no snapshot to restore"
  rm -rf "$R" "$ORIGIN" "$J/prs" "$J/count" || fail "cannot remove the project"
  cp -a "$dir/project" "$R" || fail "cannot restore the project"
  if [ -d "$dir/origin.git" ]; then cp -a "$dir/origin.git" "$ORIGIN" || fail "cannot restore origin"; fi
  if [ -d "$dir/prs" ]; then cp -a "$dir/prs" "$J/prs" || fail "cannot restore the pull requests"; fi
  rm -f "$J/calls/"* && : > "$JOURNEY_LOG"
}

journey_audit() {
  local found=1 line
  if [ -s "$J/calls/unexpected" ]; then
    while IFS= read -r line; do printf 'unexpected call to %s\n' "$line"; done < "$J/calls/unexpected"
    found=0
  fi
  if [ -s "$J/calls/cargo" ]; then
    while IFS= read -r line; do printf 'unexpected call to cargo: %s\n' "$line"; done < "$J/calls/cargo"
    found=0
  fi
  [ "$found" -eq 1 ]
}

journey_calls() { cat "$J/calls/$1" 2>/dev/null || true; }
journey_pushed() { cat "$J/calls/pushed" 2>/dev/null || true; }

# The reasons of every ask entry since journey_init, sorted and unique.
journey_asks() { sort -u "$J/asks" 2>/dev/null || true; }

# 0 when the last run stopped with an ask entry in its log.
journey_stopped_on_ask() {
  grep -q '^stopped' "$JOURNEY_LOG" && awk -F'\t' '$1 == "entry" && $4 == "ask" {f = 1} END {exit !f}' "$JOURNEY_LOG"
}

# The literal reasons of `act("ask", "<reason>")` in every .rs file under <dir>, subfolders
# included. Fails, naming each <file>:<line> on stderr, when a line holds an "ask" token that is
# not such a literal call, or calls act with an action that is not a literal (a constant, a variable).
journey_ask_reasons() {
  local dir="${1:-}" files=()
  [ -d "$dir" ] && mapfile -t files < <(find "$dir" -type f -name '*.rs' | sort)
  [ "${#files[@]}" -gt 0 ] || { echo "no Rust sources under '$dir'" >&2; return 1; }
  grep -ho 'act("ask", "[^"]*")' "${files[@]}" | sed 's/^act("ask", "\(.*\)")$/\1/' | sort -u
  awk '{
      tokens = gsub(/"ask"/, "&")
      literal = gsub(/act\("ask", "[^"]*"\)/, "&")
      if (tokens != literal) {print FILENAME ":" FNR " holds an \"ask\" that is not act(\"ask\", \"<literal>\")" > "/dev/stderr"; bad = 1}
      if ($0 !~ /fn act\(/ && $0 ~ /(^|[^A-Za-z0-9_])act\([^"]/) {print FILENAME ":" FNR " calls act with an action that is not a literal" > "/dev/stderr"; bad = 1}
    } END {exit bad}' "${files[@]}"
}

# Each reason of <dir> no run reached since journey_init.
journey_unreached() {
  local reasons missing
  reasons="$(journey_ask_reasons "${1:-}")" || return 1
  missing="$(grep -vxF -f <(journey_asks) <<< "$reasons" || true)"
  [ -z "$missing" ] || { printf '%s\n' "$missing"; return 1; }
}

# --- overridable steps --------------------------------------------------------

journey_po_next() { (cd "$R" && "$PO" next --remote); }

journey_validate_line() {
  local plan; plan="$(journey_lane "$1")/docs/plans/$1.md"
  awk 'NR == 1 && $0 == "---" {on = 1; print; next} on && $0 == "---" {on = 0}
    on && $0 == "validated: no" {$0 = "validated: yes"} {print}' "$plan" > "$plan.new" && mv "$plan.new" "$plan" \
    || journey_stop "$1: cannot validate $plan"
}

journey_po_run() {
  local test
  test="$(sed -n 's/^Test:[[:space:]]*\(.*[^[:space:]]\)[[:space:]]*$/\1/p' "$R/AGENTS.local.md" | head -n 1)"
  (cd "$(journey_lane "$1")" && .polype/hooks/po-run.sh --story "$1" --label 'Unit suite' -- "$test") >> "$J/po-run.log" 2>&1
}

# 0 recorded; 1 written but refused by findings-shape; 2 written but the shape check could not run.
journey_record_review() {
  local reply status=0
  reply="$(cd "$(journey_lane "$1")" && "$PO" record review "$1" < "$2")" || status=$?
  if [ "$status" -ne 0 ]; then
    if jq -e '.written == true' <<< "$reply" >/dev/null 2>&1; then
      case "$(jq -r '.error' <<< "$reply")" in
        findings-shape) return 1 ;;
        findings-shape-unrunnable) return 2 ;;
      esac
    fi
    journey_refused "$1" "po record review" "$reply"
  fi
  jq -e '.path' <<< "$reply" >/dev/null 2>&1 || journey_refused "$1" "po record review" "$reply"
}

# The blocked report /po-review composes, recorded unchecked.
journey_record_blocked() {
  local id="$1" report="$J/tmp/$1.blocked.md" reply
  printf '%s\n' 'Review status: blocked' "Fix loop: $2" "Reviewed tree: $3" '' '## When blocked' \
    "- Failure cause: $4" '- Missing: findings in the shape of templates/review.md, from a check that ran' \
    '- Required adaptation: a person settles the findings shape or repairs the installed gate' "- Next action: $5" '' \
    'Max severity: critical' 'Ship allowed: no' > "$report" || journey_stop "$id: cannot write $report"
  reply="$(cd "$(journey_lane "$id")" && "$PO" record review "$id" --composed < "$report")" \
    || journey_refused "$id" "po record review --composed" "$reply"
  jq -e '.path' <<< "$reply" >/dev/null 2>&1 || journey_refused "$id" "po record review --composed" "$reply"
}

# --- the loop -------------------------------------------------------------------

journey_lane() { printf '%s/.worktrees/%s\n' "$R" "$1"; }

journey_stop() { printf 'stopped\t%s\n' "$*" >> "$JOURNEY_LOG"; exit 1; }

journey_refused() {
  local id="$1" verb="$2" reply="$3" said
  said="$(jq -r '"\(.error // "no error"): \(.message // "no message")"' <<< "$reply" 2>/dev/null)" || said="$reply"
  journey_stop "$id: $verb did not answer as awaited: ${said:-$reply}"
}

# The written answer <file> of <id>, placeholders filled, written to <out>.
journey_fill() {
  local text
  text="$(cat "$2")" || journey_stop "$1: cannot read $2"
  text="${text//@ID@/$1}"
  text="${text//@TITLE@/$(journey_title "$1")}"
  text="${text//@TREE@/${4:-}}"
  text="${text//@N@/${JOURNEY_N:-}}"
  text="${text//@LOOP@/${JOURNEY_LOOP:-}}"
  printf '%s\n' "$text" > "$3" || journey_stop "$1: cannot write $3"
}

journey_title() { sed -n "s/^### $1 — //p" "$R/docs/stories.md" | head -n 1; }

journey_count() { cat "$J/count/$1.$2" 2>/dev/null || echo 0; }

# journey_answer_find <id> <action> <file>: on the n-th application of <action>, n ≥ 2, a folder's
# `<stem>.<n>.<ext>` stands in for its `<file>`; 1 when no bound folder holds either.
journey_answer_find() {
  local id="$1" action="$2" file="$3" n numbered dir
  n="$(journey_count "$id" "$action")"
  case "$file" in *.*) numbered="${file%.*}.$n.${file##*.}" ;; *) numbered="$file.$n" ;; esac
  [ -f "$J/bound/$id" ] || return 1
  while IFS= read -r dir; do
    if [ "$n" -ge 2 ] && [ -f "$dir/$numbered" ]; then printf '%s\n' "$dir/$numbered"; return 0; fi
    if [ -f "$dir/$file" ]; then printf '%s\n' "$dir/$file"; return 0; fi
  done < "$J/bound/$id"
  return 1
}

journey_answer_file() { journey_answer_find "$1" "$2" "$3" || journey_stop "no written answer for $2 of $1"; }

journey_po() {
  local id="$1" dir="$2" verb="$3"; shift 3
  (cd "$dir" && "$PO" ship "$verb" "$@" 2>>"$J/po.err")
}

# The Fix loop of the next review, as /po-review computes it.
journey_fix_loop() {
  local file loop status next
  file="$(journey_lane "$1")/docs/reviews/$1.md"
  [ -f "$file" ] || { echo 0; return 0; }
  loop="$(sed -n 's/^Fix loop:[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$file" | tail -n 1)"
  status="$(sed -n 's/^Review status:[[:space:]]*\([a-z]*\).*/\1/p' "$file" | tail -n 1)"
  next="$(grep '^- Next action:' "$file" | tail -n 1)"
  if [ "$status" = blocked ] && [[ "$next" == */po-qa* || "$next" == *"QA evidence"* ]]; then
    echo "${loop:-0}"
  else
    echo $(( ${loop:--1} + 1 ))
  fi
}

journey_open_lane() {
  local id="$1" lane start
  lane="$(journey_lane "$id")"
  [ ! -d "$lane" ] || return 0
  start=main
  if git -C "$R" remote get-url origin >/dev/null 2>&1; then
    git -C "$R" fetch -q origin || journey_stop "$id: git fetch failed"
    git -C "$R" rev-parse -q --verify refs/remotes/origin/main >/dev/null && start=origin/main
  fi
  git -C "$R" worktree add -q -b "story/$id" "$lane" "$start" 2>>"$J/po.err" || journey_stop "$id: cannot open the lane"
}

journey_ship() {
  local id="$1" reason="$2" lane reply mode effective sha state url dir body
  lane="$(journey_lane "$id")"
  if [ "$reason" != landed ]; then
    reply="$(journey_po "$id" "$lane" forge)"
    effective="$(jq -r '.effective // empty' <<< "$reply" 2>/dev/null)"
    mode="$(sed -n 's/^Merge mode:[[:space:]]*\([a-z]*\).*/\1/p' "$R/AGENTS.local.md" | head -n 1)"
    case "$effective/$mode" in
      automatic/*|human/pr) ;;
      *) journey_refused "$id" "po ship forge" "$reply" ;;
    esac
    if [ "$mode" = local ]; then
      reply="$(journey_po "$id" "$lane" land "$id" --land)"
      jq -e '.landed == true' <<< "$reply" >/dev/null 2>&1 || journey_refused "$id" "po ship land --land" "$reply"
    else
      reply="$(journey_po "$id" "$lane" land "$id")"
      sha="$(jq -re '.sha' <<< "$reply" 2>/dev/null)" || journey_refused "$id" "po ship land" "$reply"
      # po-ship.md Step 1: a landing already on Target branch goes straight to the cleanup.
      if ! jq -e '.already_landed == true' <<< "$reply" >/dev/null 2>&1; then
        body="$(journey_answer_file "$id" ship pr-body.md)" || exit 1
        dir="$(mktemp -d "$J/tmp/body.XXXXXX")" || journey_stop "$id: mktemp failed"
        journey_fill "$id" "$body" "$dir/body.md"
        reply="$(journey_po "$id" "$lane" push "$id" --sha "$sha" --body-file "$dir/body.md")"
        rm -rf "$dir"
        state="$(jq -r '.state // empty' <<< "$reply" 2>/dev/null)"
        case "$state" in
          merged) ;;
          waiting-for-human)
            url="$(jq -re '.pull_request.url' <<< "$reply" 2>/dev/null)" || journey_refused "$id" "po ship push" "$reply"
            printf 'pr-waiting\t%s\t%s\n' "$id" "$url" >> "$JOURNEY_LOG"
            return 0 ;;
          *) journey_refused "$id" "po ship push" "$reply" ;;
        esac
      fi
    fi
  fi
  reply="$(journey_po "$id" "$lane" file "$id")"
  jq -e '.findings' <<< "$reply" >/dev/null 2>&1 || journey_refused "$id" "po ship file" "$reply"
  reply="$(journey_po "$id" "$lane" file "$id" --file)"
  jq -e '.state == "filed" or .state == "no-tracker"' <<< "$reply" >/dev/null 2>&1 \
    || journey_refused "$id" "po ship file --file" "$reply"
  reply="$(journey_po "$id" "$R" clean "$id")"
  jq -e '.state == "cleaned"' <<< "$reply" >/dev/null 2>&1 || journey_refused "$id" "po ship clean" "$reply"
}

journey_review() {
  local id="$1" review retry tree status
  review="$(journey_answer_file "$id" review review.md)" || exit 1
  tree="$(git -C "$R" rev-parse "story/$id^{tree}")" || journey_stop "$id: story/$id has no tree"
  JOURNEY_LOOP="$(journey_fix_loop "$id")"
  journey_fill "$id" "$review" "$J/tmp/$id.review.md" "$tree"
  # Recorded: has whole seconds; two reviews in one second would tie and let the rank decide.
  while [ "$(date +%s)" = "$JOURNEY_LAST_REVIEW" ]; do sleep 0.1; done
  status=0; journey_record_review "$id" "$J/tmp/$id.review.md" || status=$?
  if [ "$status" -eq 1 ]; then
    retry="$(journey_answer_find "$id" review review.retry.md)" || journey_stop "no written answer for review retry of $id"
    journey_fill "$id" "$retry" "$J/tmp/$id.review.md" "$tree"
    status=0; journey_record_review "$id" "$J/tmp/$id.review.md" || status=$?
    if [ "$status" -eq 1 ]; then
      journey_record_blocked "$id" "$JOURNEY_LOOP" "$tree" "po-gate findings-shape $id refused the answer twice" \
        "a person settles the findings shape — po-gate findings-shape $id refused the reviewer twice"
    fi
  fi
  if [ "$status" -eq 2 ]; then
    journey_record_blocked "$id" "$JOURNEY_LOOP" "$tree" "po-gate findings-shape $id exited 2" \
      "a person runs po-gate findings-shape $id — the check could not run (exit 2)"
  fi
  JOURNEY_LAST_REVIEW="$(date +%s)"
}

journey_apply() {
  local id="$1" action="$2" reason="$3" track="$4" lane
  lane="$(journey_lane "$id")"
  mkdir -p "$J/count" || journey_stop "cannot count the answers"
  JOURNEY_N=$(( $(journey_count "$id" "$action") + 1 ))
  echo "$JOURNEY_N" > "$J/count/$id.$action" || journey_stop "cannot count the answers"
  case "$action" in
    plan)
      local research="" plan=""
      if [ "$track" = full ]; then research="$(journey_answer_find "$id" plan research.md)" || research=""; fi
      plan="$(journey_answer_find "$id" plan plan.md)" || plan=""
      # planner.md: a story with a screen and no design gets its research only.
      if [ -n "$plan" ] && journey_answer_find "$id" plan design.md >/dev/null \
        && [ ! -f "$lane/docs/designs/$id/design.md" ]; then
        plan=""
      fi
      [ -n "$research$plan" ] || journey_stop "no written answer for plan of $id"
      journey_open_lane "$id"
      mkdir -p "$lane/docs/research" "$lane/docs/plans"
      if [ -n "$research" ]; then journey_fill "$id" "$research" "$lane/docs/research/$id.md"; fi
      if [ -n "$plan" ]; then journey_fill "$id" "$plan" "$lane/docs/plans/$id.md"; fi ;;
    design)
      local design
      design="$(journey_answer_file "$id" design design.md)" || exit 1
      mkdir -p "$lane/docs/designs/$id"
      journey_fill "$id" "$design" "$lane/docs/designs/$id/design.md" ;;
    validate-plan)
      local answer
      answer="$(journey_answer_file "$id" validate-plan validate-plan)" || exit 1
      : > "$lane/journey-probe.txt"
      git -C "$lane" add journey-probe.txt || journey_stop "$id: cannot stage the probe"
      if git -C "$lane" commit -qm 'journey probe' >/dev/null 2>&1; then
        journey_stop "the pre-commit accepted a code commit on story/$id before its plan was approved"
      fi
      git -C "$lane" reset -q -- journey-probe.txt && rm -f "$lane/journey-probe.txt" || journey_stop "$id: cannot remove the probe"
      if [ "$(cat "$answer")" = Approve ]; then journey_validate_line "$id"; fi ;;
    execute)
      local patch record tree
      patch="$(journey_answer_file "$id" execute code.patch)" || exit 1
      record="$(journey_answer_file "$id" execute record.md)" || exit 1
      journey_fill "$id" "$patch" "$J/tmp/$id.patch"
      git -C "$lane" apply "$J/tmp/$id.patch" || journey_stop "$id: the patch does not apply"
      git -C "$lane" add -A && tree="$(git -C "$lane" write-tree)" || journey_stop "$id: cannot write the tree"
      mkdir -p "$lane/docs/verif"
      journey_fill "$id" "$record" "$lane/docs/verif/$id.md" "$tree"
      journey_po_run "$id"
      git -C "$lane" add -A && git -C "$lane" commit -qm "$id: $(journey_title "$id")" >>"$J/po.err" 2>&1 \
        || journey_stop "$id: the pre-commit refused the code commit"
      ;;
    fix)
      local patch record tree
      patch="$(journey_answer_file "$id" fix fix.patch)" || exit 1
      journey_fill "$id" "$patch" "$J/tmp/$id.fix.patch"
      git -C "$lane" apply "$J/tmp/$id.fix.patch" || journey_stop "$id: the fix does not apply"
      git -C "$lane" add -A && tree="$(git -C "$lane" write-tree)" || journey_stop "$id: cannot write the tree"
      record="$lane/docs/verif/$id.md"
      awk -v tree="$tree" '!done && /^Tree:/ {$0 = "Tree: " tree; done = 1} {print}' "$record" > "$record.new" \
        && mv "$record.new" "$record" || journey_stop "$id: cannot rewrite the Tree: of $record"
      journey_po_run "$id"
      git -C "$lane" add -A && git -C "$lane" commit -qm "$id: address review findings" >>"$J/po.err" 2>&1 \
        || journey_stop "$id: the pre-commit refused the fix commit"
      ;;
    qa)
      local qa capture tree reply
      qa="$(journey_answer_file "$id" qa qa.md)" || exit 1
      tree="$(git -C "$R" rev-parse "story/$id^{tree}")" || journey_stop "$id: story/$id has no tree"
      journey_fill "$id" "$qa" "$J/tmp/$id.qa.md" "$tree"
      reply="$(cd "$lane" && "$PO" record qa "$id" < "$J/tmp/$id.qa.md")" || journey_refused "$id" "po record qa" "$reply"
      jq -e '.path' <<< "$reply" >/dev/null 2>&1 || journey_refused "$id" "po record qa" "$reply"
      if capture="$(journey_answer_find "$id" qa qa-capture.txt)"; then
        cp "$capture" "$lane/docs/qa/$id/capture.txt" || journey_stop "$id: cannot copy the capture"
      fi
      git -C "$lane" add -- "docs/qa/$id/" && git -C "$lane" commit -qm "$id: QA evidence" -- "docs/qa/$id/" >>"$J/po.err" 2>&1 \
        || journey_stop "$id: the pre-commit refused the QA evidence commit"
      ;;
    review) journey_review "$id" ;;
    ship) journey_ship "$id" "$reason" ;;
    *) journey_stop "no written answer for $action of $id" ;;
  esac
}

# An ask goes to the inbox first when the story has a decision answer, then stops the journey.
journey_ask() {
  local id="$1" reason="$2" decision reply posted
  if decision="$(journey_answer_find "$id" ask decision.json)"; then
    journey_fill "$id" "$decision" "$J/tmp/$id.decision.json"
    reply="$(cd "$R" && "$PO" inbox add < "$J/tmp/$id.decision.json")"
    posted="$(jq -re '.id' <<< "$reply" 2>/dev/null)" \
      || journey_stop "$id: po inbox add refused: $(jq -r '.error // empty' <<< "$reply" 2>/dev/null || printf '%s' "$reply")"
    printf 'asked\t%s\t%s\n' "$id" "$posted" >> "$JOURNEY_LOG"
  fi
  journey_stop "ask for $id: $reason"
}

# journey_by_hand <id> <action>: a person's run of that action, outside po next.
journey_by_hand() {
  printf 'byhand\t%s\t%s\n' "$1" "$2" >> "$JOURNEY_LOG"
  (JOURNEY_LAST_REVIEW=0; journey_apply "$1" "$2" "by hand" -)
}

journey_loop() {
  local max="${JOURNEY_MAX_WAVES:-20}" wave=0 out status entries story action reason track applied
  declare -A last=()
  JOURNEY_LAST_REVIEW=0
  while :; do
    wave=$((wave + 1))
    [ "$wave" -le "$max" ] || journey_stop "more than $max waves"
    status=0
    out="$(journey_po_next)" || status=$?
    if [ "$status" -ne 0 ] || ! jq -e '.contract == 1' <<< "$out" >/dev/null 2>&1; then
      journey_stop "po next failed: $out"
    fi
    entries="$(jq -r '(.actions // [])[] | [.story, .action, .reason, (.track // "-")] | @tsv' <<< "$out")" \
      || journey_stop "po next failed: $out"
    # Logged before any stop, so an ask that comes with a warning is still seen.
    if [ -n "$entries" ]; then
      while IFS=$'\t' read -r story action reason track; do
        printf 'entry\t%s\t%s\t%s\t%s\t%s\n' "$wave" "$story" "$action" "$reason" "$track" >> "$JOURNEY_LOG"
        if [ "$action" = ask ]; then printf '%s\n' "$reason" >> "$J/asks"; fi
      done <<< "$entries"
    fi
    if jq -e '(.warnings // []) | length > 0' <<< "$out" >/dev/null; then
      journey_stop "po next warns: $(jq -c .warnings <<< "$out")"
    fi
    if [ -z "$entries" ]; then
      local audit
      audit="$(journey_audit)" || journey_stop "$audit"
      printf 'done\t%s\n' "$wave" >> "$JOURNEY_LOG"
      return 0
    fi
    applied=0
    while IFS=$'\t' read -r -u 3 story action reason track; do
      case "$action" in
        wait) continue ;;
        ask) journey_ask "$story" "$reason" ;;
      esac
      [ "${last[$story]:-}" != "$action"$'\t'"$reason" ] \
        || journey_stop "$story: po next answers $action ($reason) again after its answer: stopped at that gate"
      journey_apply "$story" "$action" "$reason" "$track"
      last[$story]="$action"$'\t'"$reason"
      applied=$((applied + 1))
    done 3<<< "$entries"
    [ "$applied" -gt 0 ] || journey_stop "nothing moves"
  done
}

journey_run() {
  : > "$JOURNEY_LOG"
  (journey_loop)
}
