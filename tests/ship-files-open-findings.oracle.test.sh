#!/usr/bin/env bash
# s195 — the oracle of the story: `po ship file <id>` files the open findings of the last review, once
# the story's landing commit sits on Target branch as origin holds it. Bare, it files nothing and says
# what it would file; `--file` files, `--hold <line>` and `--fixed <line>` naming what the model keeps
# back. origin is a github.com URL that git rewrites to a local bare repository; gh (also named by
# PO_GH) and task are doubles first on PATH that keep issues and tasks as JSON files and log every
# argument they receive. unmarked_security_stays_with_the_model speaks to a model: judged in review.

need_po() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO (tests/run.sh builds it before the suite)"
}

is() { jq -e "$1" <<< "$OUT" >/dev/null || fail "$2: $OUT"; }

accented() { local i; for ((i = 0; i < $1; i++)); do printf 'é'; done; }

# The review of s01-a: a first block whose finding was fixed since, then the last block, which holds
# a security count line, four findings to file, and one finding marked [security] that an older po
# left in the text.
review() {
  printf '%s\n' '# Review — s01-a' '' 'Review status: complete' 'Fix loop: 0' '' '## Findings' \
    '- major — old.sh:1 — from the first review only' '' 'Max severity: major' 'Ship allowed: no' '' \
    'Review status: complete' 'Fix loop: 1' '' '## Findings' 'Security findings: 1 — decision d-0042' \
    '- major — a.sh:1 — plain finding marker-a1 `$(touch injected)` "quoted"' \
    '  - a sub-bullet marker-b2' \
    '- **minor** — b.sh:2 — second finding' \
    '1. **minor**: already open finding' \
    '- minor — [security] — d.sh:4 — token secret-zz9 leaks' \
    '  - more of secret-zz9' \
    "- minor — $(accented 79) suite" \
    '' '## Not verified' 'None.' '' 'Max severity: major' 'Ship allowed: yes'
}

T_PLAIN='s01-a: major — a.sh:1 — plain finding marker-a1 `$(touch injected)` "quoted"'
T_SECOND='s01-a: minor — b.sh:2 — second finding'
T_OPEN='s01-a: minor — already open finding'
T_ACCENT="s01-a: minor — $(accented 79)"

# project <Issue tracker> [pr|local]: story s01-a changed code.txt and committed its review in $W.
# Under pr, origin is https://github.com/acme/widget.git, rewritten to the bare $ORIGIN.
project() {
  local mode="${2:-pr}"
  SCRATCH="$(cd "$(mktemp -d)" && pwd -P)"
  trap 'rm -rf "$SCRATCH"' EXIT
  R="$SCRATCH/project" W="$SCRATCH/project/.worktrees/s01-a" D="$SCRATCH/doubles" ORIGIN="$SCRATCH/origin.git"
  mkdir -p "$SCRATCH/home" "$SCRATCH/tmp" "$D/bin" "$D/calls" "$D/issues" "$D/tasks"
  : > "$D/calls/gh"; : > "$D/calls/task"
  git init -q -b main "$R"
  git -C "$R" config user.email test@example.com
  git -C "$R" config user.name test
  git -C "$R" config commit.gpgsign false
  mkdir -p "$R/docs"
  printf 'Target branch: main\nMerge mode: %s\nIssue tracker: %s\nShip confirmation: automatic\nWorktree root: .worktrees/\n' \
    "$mode" "$1" > "$R/AGENTS.local.md"
  printf '.worktrees/\n' > "$R/.gitignore"
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
  review > "$W/docs/reviews/s01-a.md"
  git -C "$W" add -A && git -C "$W" commit -qm 'code and review'
  doubles
}

# landing <parent>: the landing commit of s01-a on <parent>, as po ship land builds it.
landing() { git -C "$W" commit-tree 'HEAD^{tree}' -p "$1" -m 's01-a: Un titre'; }

# The forge landed the story: origin's main moves to a landing commit.
landed_on_origin() {
  git -C "$R" fetch -q origin
  git -C "$R" push -q origin "$(landing "$(git -C "$R" rev-parse origin/main)"):refs/heads/main"
}

line_of() { grep -nF -- "$1" "$W/docs/reviews/s01-a.md" | tail -n 1 | cut -d: -f1; }

po_file() {
  STATUS=0
  OUT="$(cd "$W" && env PATH="$D/bin:$PATH" HOME="$SCRATCH/home" GH_CONFIG_DIR="$SCRATCH/home/gh" \
    PO_GH="$D/bin/gh" TMPDIR="$SCRATCH/tmp" DOUBLES="$D" ${LOCALE:+LC_ALL="$LOCALE"} \
    "$PO" ship file s01-a "$@" 2>"$SCRATCH/stderr" </dev/null)" || STATUS=$?
}

creates() { grep -c '^api ' "$D/calls/gh" || true; }
imports() { grep -c ' import ' "$D/calls/task" || true; }
issue_titles() { jq -r .title "$D"/issues/*.json 2>/dev/null | sort; }

doubles() {
  # gh: `issue list` prints the open issues' titles as JSON; `api` with `--input <file>` creates an
  # issue from that file. Markers: list-fails, many-open, creates-before-fail (a count).
  cat > "$D/bin/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DOUBLES/calls/gh"
shopt -s nullglob
case "${1:-} ${2:-}" in
  "issue list")
    [ ! -f "$DOUBLES/list-fails" ] || { echo "HTTP 502" >&2; exit 1; }
    [ ! -f "$DOUBLES/many-open" ] || { jq -n '[range(1000) | {title: "other \(.)"}]'; exit 0; }
    files=("$DOUBLES"/issues/*.json)
    if [ ${#files[@]} -gt 0 ]; then jq -s 'map(select(.state == "open") | {title})' "${files[@]}"; else echo '[]'; fi ;;
  "api "*)
    input=""; prev=""
    for a in "$@"; do [ "$prev" = --input ] && input="$a"; prev="$a"; done
    [ -n "$input" ] && [ -f "$input" ] || { echo "no input file" >&2; exit 1; }
    if [ -f "$DOUBLES/creates-before-fail" ]; then
      k="$(cat "$DOUBLES/creates-before-fail")"
      if [ "$k" -eq 0 ]; then rm "$DOUBLES/creates-before-fail"; echo "HTTP 502" >&2; exit 1; fi
      echo $((k - 1)) > "$DOUBLES/creates-before-fail"
    fi
    files=("$DOUBLES"/issues/*.json); n=$(( ${#files[@]} + 1 ))
    jq --argjson n "$n" '. + {number: $n, state: "open"}' "$input" > "$DOUBLES/issues/$n.json" || exit 1
    printf '{"number":%s,"html_url":"https://github.com/acme/widget/issues/%s"}\n' "$n" "$n" ;;
  *) exit 1 ;;
esac
EOF
  # task: `... export` prints the tasks kept; `... import <file>` keeps the task(s) of that file.
  cat > "$D/bin/task" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DOUBLES/calls/task"
shopt -s nullglob
args=("$@"); last="${args[$(( ${#args[@]} - 1 ))]}"
if [ "$last" = export ]; then
  [ ! -f "$DOUBLES/list-fails" ] || { echo "task: database locked" >&2; exit 1; }
  files=("$DOUBLES"/tasks/*.json)
  if [ ${#files[@]} -gt 0 ]; then jq -s . "${files[@]}"; else echo '[]'; fi
elif [ ${#args[@]} -ge 2 ] && [ "${args[$(( ${#args[@]} - 2 ))]}" = import ]; then
  files=("$DOUBLES"/tasks/*.json); n=$(( ${#files[@]} + 1 ))
  jq -c 'if type == "array" then .[] else . end' "$last" > "$DOUBLES/tasks/$n.json" || exit 1
  echo "Imported 1 tasks."
else
  exit 1
fi
EOF
  chmod +x "$D/bin/gh" "$D/bin/task"
}

test_nothing_before_the_proof() {
  need_po
  project github
  po_file --file
  [ "$STATUS" -eq 1 ] || fail "with no landing anywhere, po ship file exited $STATUS"
  is '.error == "not-landed"' "no landing must refuse as not-landed"
  # The landing lands on the local main only: origin, where the forge lands it, does not hold it.
  git -C "$R" merge -q --ff-only "$(landing "$(git -C "$R" rev-parse main)")"
  po_file --file
  is '.error == "not-landed"' "a landing on the local main alone counted as proof under pr"
  # origin's main cites the subject in a body, and carries a subject that extends it.
  local base decoy
  git -C "$R" fetch -q origin
  base="$(git -C "$R" rev-parse origin/main)"
  decoy="$(git -C "$R" commit-tree "$base^{tree}" -p "$base" -m 'chore: unrelated' -m 's01-a: Un titre')"
  decoy="$(git -C "$R" commit-tree "$base^{tree}" -p "$decoy" -m 's01-a: Un titre long')"
  git -C "$R" push -q origin "$decoy:refs/heads/main"
  po_file --file
  is '.error == "not-landed"' "a commit citing or extending the subject counted as the landing"
  [ "$(creates)" = 0 ] && [ ! -s "$D/calls/task" ] || fail "something was filed before the proof: $(cat "$D/calls/gh")"
  grep -q '^issue list' "$D/calls/gh" && fail "the tracker was read before the proof"
  landed_on_origin
  po_file --file
  [ "$STATUS" -eq 0 ] || fail "after the landing on origin, po ship file exited $STATUS: $OUT $(cat "$SCRATCH/stderr")"
  [ "$(creates)" = 4 ] || fail "after the proof, $(creates) issues were created, not 4"
}

test_open_findings_are_filed_once() {
  need_po
  project github
  landed_on_origin
  jq -n --arg t "$T_OPEN" '{title: $t, body: "x", state: "open", number: 1}' > "$D/issues/1.json"
  jq -n --arg t "$T_SECOND x" '{title: $t, body: "x", state: "open", number: 2}' > "$D/issues/2.json"
  jq -n --arg t "$T_PLAIN" '{title: $t, body: "x", state: "closed", number: 3}' > "$D/issues/3.json"
  echo 1 > "$D/creates-before-fail"
  po_file --file
  [ "$STATUS" -ne 0 ] || fail "a create that failed did not fail the run: $OUT"
  [ "$(creates)" = 2 ] || fail "after a failed create the run went on: $(cat "$D/calls/gh")"
  po_file --file
  [ "$STATUS" -eq 0 ] || fail "the rerun exited $STATUS: $OUT $(cat "$SCRATCH/stderr")"
  po_file --file
  [ "$STATUS" -eq 0 ] || fail "the third run exited $STATUS: $OUT"
  is '(.filed | length) == 0' "a rerun filed again"
  jq -e --args '[.already_open[].title] | sort == ($ARGS.positional | sort)' "$T_PLAIN" "$T_SECOND" "$T_OPEN" "$T_ACCENT" \
    <<< "$OUT" >/dev/null || fail "the rerun does not name the four titles already open: $OUT"
  [ "$(jq -r 'select(.number > 3) | .title' "$D"/issues/*.json | sort)" = "$(printf '%s\n' "$T_PLAIN" "$T_SECOND" "$T_ACCENT" | sort)" ] \
    || fail "the issues created are not the three findings not yet open, once each: $(issue_titles)"
  local body; body="$(jq -r --arg t "$T_PLAIN" 'select(.title == $t) | .body' "$D"/issues/*.json)"
  for p in '- major — a.sh:1 — plain finding marker-a1' '  - a sub-bullet marker-b2' 'Fix loop: 1' 'docs/reviews/s01-a.md'; do
    grep -qF -- "$p" <<< "$body" || fail "the body of the first finding lacks: $p — $body"
  done
  ! grep -qF 'from the first review only' "$D"/issues/*.json || fail "a finding of an earlier block was filed"
  ! grep -qF 'Fix loop: 0' <<< "$body" || fail "the body names an earlier Fix loop"
  ! grep -qE 'marker-a1|marker-b2' "$D/calls/gh" || fail "finding text travelled in an argument: $(cat "$D/calls/gh")"
  grep '^api ' "$D/calls/gh" | grep -vF 'repos/acme/widget/issues' | grep -q . && fail "an issue went elsewhere than acme/widget"
  grep '^api ' "$D/calls/gh" | grep -vF -- '--hostname github.com' | grep -q . && fail "gh api was not bound to github.com"
  [ ! -e "$W/injected" ] && [ ! -e "$R/injected" ] && [ ! -e "$SCRATCH/home/injected" ] || fail "finding text was run by a shell"
  [ -z "$(ls -A "$SCRATCH/tmp")" ] || fail "po left files behind in TMPDIR: $(ls -A "$SCRATCH/tmp")"
}

test_security_findings_are_never_filed() {
  need_po
  project github
  landed_on_origin
  po_file
  [ "$STATUS" -eq 0 ] || fail "the listing exited $STATUS: $OUT"
  is '.security.decision == "d-0042"' "the listing does not return the decision of the security findings"
  is "(.security.lines == [$(line_of 'd.sh:4')])" "the listing does not name the marked finding by its line"
  po_file --file
  [ "$STATUS" -eq 0 ] || fail "po ship file --file exited $STATUS: $OUT"
  is '.security.decision == "d-0042"' "the filing does not return the decision of the security findings"
  local where
  for where in "$D/calls/gh" "$SCRATCH/stderr" "$D"/issues/*.json; do
    ! grep -qF secret-zz9 "$where" || fail "the text of a [security] finding reached $where"
  done
  ! grep -qF secret-zz9 <<< "$OUT" || fail "the text of a [security] finding was returned: $OUT"
  ! grep -qiF '[security]' "$D"/issues/*.json || fail "a [security] finding was filed"
  [ "$(creates)" = 4 ] || fail "$(creates) issues were created, not the 4 ordinary findings"
}

test_failed_listing_files_nothing() {
  need_po
  project github
  landed_on_origin
  touch "$D/list-fails"
  po_file --file
  [ "$STATUS" -eq 1 ] || fail "a failed listing exited $STATUS: $OUT"
  is '.error == "listing-failed"' "a failed listing is not refused as listing-failed"
  is '(.pending | length) == 4' "a failed listing does not hand the findings back"
  rm "$D/list-fails"; touch "$D/many-open"
  po_file --file
  [ "$STATUS" -eq 1 ] || fail "a listing at the 1000-title limit exited $STATUS: $OUT"
  is '.error == "too-many-open"' "a listing at its limit is not refused as too-many-open"
  is '(.pending | length) == 4' "a listing at its limit does not hand the findings back"
  [ "$(creates)" = 0 ] || fail "an issue was created on a listing that proves nothing"
  rm -rf "$SCRATCH"; trap - EXIT
  project taskwarrior
  landed_on_origin
  touch "$D/list-fails"
  po_file --file
  [ "$STATUS" -eq 1 ] && jq -e '.error == "listing-failed"' <<< "$OUT" >/dev/null \
    || fail "a failed task export is not refused as listing-failed: $STATUS $OUT"
  [ "$(imports)" = 0 ] || fail "a task was imported on a failed listing"
}

test_every_tracker_value_is_handled() {
  need_po
  project github
  landed_on_origin
  po_file --file
  [ "$STATUS" -eq 0 ] && [ "$(creates)" = 4 ] || fail "under github, $(creates) issues for 4 findings: $STATUS $OUT"
  is '(.filed | length) == 4 and (.filed | all(.url | startswith("https://github.com/acme/widget/issues/")))' "the filed issues carry no URL"
  rm -rf "$SCRATCH"; trap - EXIT

  project taskwarrior
  landed_on_origin
  po_file --file
  [ "$STATUS" -eq 0 ] && [ "$(imports)" = 4 ] || fail "under taskwarrior, $(imports) tasks for 4 findings: $STATUS $OUT $(cat "$D/calls/task")"
  grep ' export$' "$D/calls/task" | grep -qF 'project:widget' || fail "the pending tasks were not listed in project:widget"
  jq -se --arg t "$T_SECOND" 'map(select(.description == $t and .project == "widget" and (.tags | index("issue"))
      and (.annotations[0].description | contains("- **minor** — b.sh:2 — second finding")))) | length == 1' "$D"/tasks/*.json >/dev/null \
    || fail "the task of a finding lacks its title, project, tag or body: $(cat "$D"/tasks/*.json)"
  ! grep -qF 'second finding' "$D/calls/task" || fail "finding text travelled in a task argument"
  is '.filed | all(.uuid | test("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"))' "the filed tasks carry no uuid"
  po_file --file
  [ "$(imports)" = 4 ] || fail "a rerun under taskwarrior imported again"
  rm -rf "$SCRATCH"; trap - EXIT

  project —
  landed_on_origin
  po_file --file
  [ "$STATUS" -eq 0 ] || fail "under Issue tracker: — po ship file exited $STATUS: $OUT"
  is '.state == "no-tracker"' "under — the state is not no-tracker"
  jq -e --args '[.pending[].title] | sort == ($ARGS.positional | sort)' "$T_PLAIN" "$T_SECOND" "$T_OPEN" "$T_ACCENT" \
    <<< "$OUT" >/dev/null || fail "under — the four findings are not handed back: $OUT"
  [ ! -s "$D/calls/gh" ] && [ ! -s "$D/calls/task" ] || fail "under — a tracker was called"
}

test_findings_read_in_any_locale() {
  need_po
  project github
  landed_on_origin
  local loc first=""
  for loc in C C.UTF-8 zz_ZZ.UTF-8; do
    LOCALE="$loc" po_file
    [ "$STATUS" -eq 0 ] || fail "the listing under LC_ALL=$loc exited $STATUS: $OUT"
    jq -e --args '[.findings[].title] | sort == ($ARGS.positional | sort)' "$T_PLAIN" "$T_SECOND" "$T_OPEN" "$T_ACCENT" <<< "$OUT" >/dev/null \
      || fail "under LC_ALL=$loc the titles are not cut by characters: $(jq -c '[.findings[].title]' <<< "$OUT")"
    [ -n "$first" ] || first="$(jq -c .findings <<< "$OUT")"
    [ "$(jq -c .findings <<< "$OUT")" = "$first" ] || fail "LC_ALL=$loc reads the findings differently"
  done
  [ "$(creates)" = 0 ] || fail "a listing without --file created an issue"
  LOCALE=zz_ZZ.UTF-8 po_file --file
  [ "$STATUS" -eq 0 ] || fail "filing under a missing locale exited $STATUS: $OUT"
  issue_titles | grep -qxF -- "$T_ACCENT" || fail "under a missing locale the accented title was filed changed: $(issue_titles)"
}

test_version_goes_up() {
  local toml lock polype
  toml="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$ROOT/po/Cargo.toml" | head -n 1)"
  lock="$(awk '$0 == "name = \"po\"" {getline; print; exit}' "$ROOT/po/Cargo.lock" | sed -n 's/^version = "\(.*\)"$/\1/p')"
  polype="$(sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$ROOT/bin/polype")"
  [ -n "$toml" ] && [ "$toml" = "$lock" ] && [ "$toml" = "$polype" ] \
    || fail "po's version differs: po/Cargo.toml $toml, po/Cargo.lock $lock, bin/polype $polype"
  [ "$toml" != 0.10.0 ] && [ "$(printf '0.10.0\n%s\n' "$toml" | sort -V | head -n 1)" = 0.10.0 ] \
    || fail "po's version $toml is not above 0.10.0"
}
