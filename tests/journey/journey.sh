#!/usr/bin/env bash
# The replayed journey: walks throwaway stories from po next's `plan` to `<id>: <title>` on Target
# branch with no model, applying one written answer per action through the real gates, po-run,
# po record and the five `po ship` sub-steps. Sourced after tests/lib.sh; it only defines functions.
#
# Every step is checked by hand rather than through `set -e`: the tests call journey_run inside
# `if` and `||`, where bash ignores `set -e` all the way down.

JOURNEY_SRC="$ROOT/tests/journey"

# The one folder of a journey, removed on any exit but a SIGKILL. An interrupt only exits: the
# EXIT trap does the removal.
journey_init() {
  local made
  made="$(mktemp -d "${TMPDIR:-/tmp}/polype-journey.XXXXXX")" || fail "mktemp failed"
  J="$(cd "$made" && pwd -P)" || fail "cannot resolve $made"
  trap 'rm -rf "$J"' EXIT
  trap 'exit 129' HUP
  trap 'exit 130' INT
  trap 'exit 143' TERM
  JOURNEY_LOG="$J/journey.log" R="$J/project" ORIGIN="$J/origin.git"
  mkdir -p "$J/bin" "$J/home" "$J/tmp" "$J/claude" "$J/calls" "$J/private" "$J/bound" || fail "cannot lay out $J"
  : > "$JOURNEY_LOG"
  cp "$JOURNEY_SRC/doubles/gh" "$JOURNEY_SRC/doubles/cargo" "$J/bin/" || fail "cannot copy the doubles"
  local tool
  for tool in curl glab tea task claude; do
    cp "$JOURNEY_SRC/doubles/unexpected" "$J/bin/$tool" || fail "cannot copy the $tool double"
  done
  chmod +x "$J/bin/"*
  unset GH_TOKEN GITHUB_TOKEN
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

journey_answers() {
  [ -n "${1:-}" ] && [ -d "${2:-}" ] || fail "journey_answers <id> <dir>: no answers folder at '${2:-}'"
  printf '%s\n' "$2" > "$J/bound/$1"
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

journey_snapshot() {
  rm -rf "$J/snapshot" && mkdir -p "$J/snapshot" || fail "cannot make the snapshot folder"
  cp -a "$R" "$J/snapshot/project" || fail "cannot snapshot the project"
  if [ -d "$ORIGIN" ]; then cp -a "$ORIGIN" "$J/snapshot/origin.git" || fail "cannot snapshot origin"; fi
}

journey_restore() {
  [ -d "$J/snapshot/project" ] || fail "no snapshot to restore"
  rm -rf "$R" "$ORIGIN" "$J/prs" || fail "cannot remove the project"
  cp -a "$J/snapshot/project" "$R" || fail "cannot restore the project"
  if [ -d "$J/snapshot/origin.git" ]; then cp -a "$J/snapshot/origin.git" "$ORIGIN" || fail "cannot restore origin"; fi
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

# --- overridable steps --------------------------------------------------------

journey_po_next() { (cd "$R" && "$PO" next); }

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

journey_record_review() {
  local reply
  reply="$(cd "$(journey_lane "$1")" && "$PO" record review "$1" < "$2")" || journey_refused "$1" "po record review" "$reply"
  jq -e '.path' <<< "$reply" >/dev/null 2>&1 || journey_refused "$1" "po record review" "$reply"
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
  printf '%s\n' "$text" > "$3" || journey_stop "$1: cannot write $3"
}

journey_title() { sed -n "s/^### $1 — //p" "$R/docs/stories.md" | head -n 1; }

journey_answer_file() {
  local dir
  dir="$(cat "$J/bound/$1" 2>/dev/null)" || journey_stop "no written answer for $2 of $1"
  [ -f "$dir/$3" ] || journey_stop "no written answer for $2 of $1"
  printf '%s/%s\n' "$dir" "$3"
}

journey_po() {
  local id="$1" dir="$2" verb="$3"; shift 3
  (cd "$dir" && "$PO" ship "$verb" "$@" 2>>"$J/po.err")
}

journey_apply() {
  local id="$1" action="$2" reason="$3" track="$4" lane start dir research plan
  lane="$(journey_lane "$id")"
  case "$action" in
    plan)
      if [ "$track" = full ]; then research="$(journey_answer_file "$id" plan research.md)" || exit 1; fi
      plan="$(journey_answer_file "$id" plan plan.md)" || exit 1
      if [ ! -d "$lane" ]; then
        start=main
        if git -C "$R" remote get-url origin >/dev/null 2>&1; then
          git -C "$R" fetch -q origin || journey_stop "$id: git fetch failed"
          git -C "$R" rev-parse -q --verify refs/remotes/origin/main >/dev/null && start=origin/main
        fi
        git -C "$R" worktree add -q -b "story/$id" "$lane" "$start" 2>>"$J/po.err" || journey_stop "$id: cannot open the lane"
      fi
      mkdir -p "$lane/docs/research" "$lane/docs/plans"
      if [ "$track" = full ]; then journey_fill "$id" "$research" "$lane/docs/research/$id.md"; fi
      journey_fill "$id" "$plan" "$lane/docs/plans/$id.md" ;;
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
    review)
      local review tree
      review="$(journey_answer_file "$id" review review.md)" || exit 1
      tree="$(git -C "$R" rev-parse "story/$id^{tree}")" || journey_stop "$id: story/$id has no tree"
      journey_fill "$id" "$review" "$J/tmp/$id.review.md" "$tree"
      # Recorded: has whole seconds; two reviews in one second would tie and let the rank decide.
      while [ "$(date +%s)" = "$JOURNEY_LAST_REVIEW" ]; do sleep 0.1; done
      journey_record_review "$id" "$J/tmp/$id.review.md"
      JOURNEY_LAST_REVIEW="$(date +%s)" ;;
    ship)
      local reply mode
      if [ "$reason" != landed ]; then
        reply="$(journey_po "$id" "$lane" forge)"
        jq -e '.effective == "automatic"' <<< "$reply" >/dev/null 2>&1 || journey_refused "$id" "po ship forge" "$reply"
        mode="$(sed -n 's/^Merge mode:[[:space:]]*\([a-z]*\).*/\1/p' "$R/AGENTS.local.md" | head -n 1)"
        if [ "$mode" = local ]; then
          reply="$(journey_po "$id" "$lane" land "$id" --land)"
          jq -e '.landed == true' <<< "$reply" >/dev/null 2>&1 || journey_refused "$id" "po ship land --land" "$reply"
        else
          local body sha
          body="$(journey_answer_file "$id" ship pr-body.md)" || exit 1
          reply="$(journey_po "$id" "$lane" land "$id")"
          sha="$(jq -re '.sha' <<< "$reply" 2>/dev/null)" || journey_refused "$id" "po ship land" "$reply"
          dir="$(mktemp -d "$J/tmp/body.XXXXXX")" || journey_stop "$id: mktemp failed"
          journey_fill "$id" "$body" "$dir/body.md"
          reply="$(journey_po "$id" "$lane" push "$id" --sha "$sha" --body-file "$dir/body.md")"
          rm -rf "$dir"
          jq -e '.state == "merged"' <<< "$reply" >/dev/null 2>&1 || journey_refused "$id" "po ship push" "$reply"
        fi
      fi
      reply="$(journey_po "$id" "$lane" file "$id")"
      jq -e '.findings' <<< "$reply" >/dev/null 2>&1 || journey_refused "$id" "po ship file" "$reply"
      reply="$(journey_po "$id" "$lane" file "$id" --file)"
      jq -e '.state == "filed" or .state == "no-tracker"' <<< "$reply" >/dev/null 2>&1 \
        || journey_refused "$id" "po ship file --file" "$reply"
      reply="$(journey_po "$id" "$R" clean "$id")"
      jq -e '.state == "cleaned"' <<< "$reply" >/dev/null 2>&1 || journey_refused "$id" "po ship clean" "$reply"
      ;;
    *) journey_stop "no written answer for $action of $id" ;;
  esac
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
    if jq -e '(.warnings // []) | length > 0' <<< "$out" >/dev/null; then
      journey_stop "po next warns: $(jq -c .warnings <<< "$out")"
    fi
    if jq -e '(.actions // []) | length == 0' <<< "$out" >/dev/null; then
      local audit
      audit="$(journey_audit)" || journey_stop "$audit"
      printf 'done\t%s\n' "$wave" >> "$JOURNEY_LOG"
      return 0
    fi
    entries="$(jq -r '.actions[] | [.story, .action, .reason, (.track // "-")] | @tsv' <<< "$out")" \
      || journey_stop "po next failed: $out"
    applied=0
    while IFS=$'\t' read -r -u 3 story action reason track; do
      printf 'entry\t%s\t%s\t%s\t%s\t%s\n' "$wave" "$story" "$action" "$reason" "$track" >> "$JOURNEY_LOG"
      case "$action" in
        wait) continue ;;
        ask) journey_stop "ask for $story: $reason" ;;
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
