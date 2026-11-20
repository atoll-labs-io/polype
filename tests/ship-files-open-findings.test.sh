#!/usr/bin/env bash
# s195 — the task tests of `po ship file <id>`: the shapes it reads and the net beside them, the
# --hold/--fixed checks, the listing guards told apart, Merge mode: local, and the words /po-ship
# loses. The setup copies the oracle's (tests/ship-files-open-findings.oracle.test.sh): origin is a
# github.com URL rewritten to a local bare repository, and gh and task are doubles that keep issues
# and tasks as JSON files. No real tracker is ever called.

need_po() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO (tests/run.sh builds it before the suite)"
}

is() { jq -e "$1" <<< "$OUT" >/dev/null || fail "$2: $OUT"; }

# Two ordinary findings, one marked [security], one critical. A test redefines it for other shapes.
review() {
  printf '%s\n' '# Review — s01-a' '' 'Review status: complete' 'Fix loop: 1' '' '## Findings' \
    'Security findings: 1 — decision d-0042' \
    '- major — a.sh:1 — first finding' \
    '- minor — b.sh:2 — second finding' \
    '- minor — [security] — d.sh:4 — token secret-zz9 leaks' \
    '- critical — c.sh:3 — a critical one' \
    '' 'Max severity: critical' 'Ship allowed: yes'
}

# project <Issue tracker> [pr|local]: story s01-a changed code.txt and committed its review in $W.
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

landing() { git -C "$W" commit-tree 'HEAD^{tree}' -p "$1" -m 's01-a: Un titre'; }

landed_on_origin() {
  git -C "$R" fetch -q origin
  git -C "$R" push -q origin "$(landing "$(git -C "$R" rev-parse origin/main)"):refs/heads/main"
}

line_of() { grep -nF -- "$1" "$W/docs/reviews/s01-a.md" | tail -n 1 | cut -d: -f1; }

po_file() {
  STATUS=0
  OUT="$(cd "$W" && env PATH="$D/bin:$PATH" HOME="$SCRATCH/home" GH_CONFIG_DIR="$SCRATCH/home/gh" \
    PO_GH="${GH_PROGRAM:-$D/bin/gh}" TMPDIR="$SCRATCH/tmp" DOUBLES="$D" \
    "$PO" ship file s01-a "$@" 2>"$SCRATCH/stderr" </dev/null)" || STATUS=$?
}

creates() { grep -c '^api ' "$D/calls/gh" || true; }
imports() { grep -c ' import ' "$D/calls/task" || true; }
issue_body() { jq -r --arg t "$1" 'select(.title == $t) | .body' "$D"/issues/*.json; }

doubles() {
  # gh: as the oracle's, with two more markers: list-garbage (exit 0, not JSON) and open-count (N titles).
  cat > "$D/bin/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DOUBLES/calls/gh"
shopt -s nullglob
case "${1:-} ${2:-}" in
  "issue list")
    [ ! -f "$DOUBLES/list-garbage" ] || { echo "<html>rate limited</html>"; exit 0; }
    [ ! -f "$DOUBLES/open-count" ] || { jq -n --argjson n "$(cat "$DOUBLES/open-count")" '[range($n) | {title: "other \(.)"}]'; exit 0; }
    files=("$DOUBLES"/issues/*.json)
    if [ ${#files[@]} -gt 0 ]; then jq -s 'map(select(.state == "open") | {title})' "${files[@]}"; else echo '[]'; fi ;;
  "api "*)
    input=""; prev=""
    for a in "$@"; do [ "$prev" = --input ] && input="$a"; prev="$a"; done
    [ -n "$input" ] && [ -f "$input" ] || { echo "no input file" >&2; exit 1; }
    files=("$DOUBLES"/issues/*.json); n=$(( ${#files[@]} + 1 ))
    jq --argjson n "$n" '. + {number: $n, state: "open"}' "$input" > "$DOUBLES/issues/$n.json" || exit 1
    printf '{"number":%s,"html_url":"https://github.com/acme/widget/issues/%s"}\n' "$n" "$n" ;;
  *) exit 1 ;;
esac
EOF
  cat > "$D/bin/task" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DOUBLES/calls/task"
shopt -s nullglob
args=("$@"); last="${args[$(( ${#args[@]} - 1 ))]}"
if [ "$last" = export ]; then
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

dups() { local i; for ((i = 0; i < 80; i++)); do printf 'd'; done; }

test_every_finding_shape_is_read() {
  need_po
  review() {
    printf '%s\n' '# Review — s01-a' 'Fix loop: 1' '' '## Findings' \
      '- major — plain shape' '   - a sub-bullet' \
      '- **major** — bold dash shape' \
      '1. **minor**: numbered shape' \
      '* minor: star shape' \
      '- **minor:** colon in bold' '  - an indented major sub-bullet' '' '  - kept after a blank' '' 'cut after a blank' \
      '- critical — c.sh:1 — a critical one' \
      "- minor — $(dups) tail-one" "- minor — $(dups) tail-two" \
      '' 'none' 'None.' 'No critical or major finding.' '- the majority of cases' \
      '' 'Max severity: critical' 'Ship allowed: yes'
  }
  project github
  (cd "$W" && bash "$METHOD/hooks/po-gate.sh" findings-shape s01-a) || fail "the gate refuses the shapes po ship file reads"
  landed_on_origin
  po_file
  [ "$STATUS" -eq 0 ] || fail "the listing exited $STATUS: $OUT"
  jq -e --args '[.findings[].title] | unique == ($ARGS.positional | sort)' 's01-a: major — plain shape' \
    's01-a: major — bold dash shape' 's01-a: minor — numbered shape' 's01-a: minor — star shape' \
    's01-a: minor — colon in bold' "s01-a: minor — $(dups)" <<< "$OUT" >/dev/null || fail "an opener of the gate was not read: $OUT"
  is '(.critical | length) == 1 and (.unrecognised | length) == 0' "the critical or the net is wrong"
  po_file --file
  [ "$STATUS" -eq 0 ] && [ "$(creates)" = 6 ] || fail "$(creates) issues for 6 titles: $STATUS $OUT"
  issue_body 's01-a: major — plain shape' | grep -qxF '   - a sub-bullet' || fail "a sub-bullet left its item"
  issue_body 's01-a: minor — colon in bold' | grep -qxF '  - kept after a blank' || fail "an indented line after a blank left its item"
  ! grep -qF 'cut after a blank' "$D"/issues/*.json || fail "a bare line after a blank was taken into an item"
  ! grep -qF 'a critical one' "$D"/issues/*.json || fail "a critical was filed"
  issue_body "s01-a: minor — $(dups)" | grep -qF tail-one && issue_body "s01-a: minor — $(dups)" | grep -qF tail-two \
    || fail "two findings sharing a title are not one issue holding both"
  rm -rf "$SCRATCH"; trap - EXIT

  review() {
    printf '%s\n' '# Review — s01-a' 'Fix loop: 1' '' '## Findings' '- major — real.sh:1 — a real one' \
      '### F1: major.' '- see the major point' 'Critical: x' 'No critical or major finding.' '- the majority of cases' \
      '- see the minor [security] leak secret-zz9' '' 'Max severity: major' 'Ship allowed: yes'
  }
  project github
  landed_on_origin
  po_file
  [ "$STATUS" -eq 0 ] || fail "the listing exited $STATUS: $OUT"
  jq -e --argjson a "$(line_of '### F1')" --argjson b "$(line_of 'see the major')" --argjson c "$(line_of 'Critical: x')" \
    --argjson d "$(line_of 'see the minor')" \
    '.unrecognised == [{line: $a, text: "### F1: major."}, {line: $b, text: "- see the major point"}, {line: $c, text: "Critical: x"}, {line: $d, text: null}]' \
    <<< "$OUT" >/dev/null || fail "the net does not list what the gate refuses, and only that: $(jq -c .unrecognised <<< "$OUT")"
  ! grep -qF secret-zz9 <<< "$OUT" || fail "a stray [security] line was quoted"
}

test_hold_and_fixed_are_checked() {
  need_po
  project github
  landed_on_origin
  local first crit
  first="$(line_of 'first finding')" crit="$(line_of 'a critical one')"
  po_file --hold "$first"
  is "(.held == [$first]) and ([.pending[].title] == [\"s01-a: minor — b.sh:2 — second finding\"]) and (.critical | length) == 1" \
    "--hold does not keep the finding out of what --file would file"
  po_file --file --hold "$(line_of 'Fix loop')"
  [ "$STATUS" -eq 2 ] && jq -e '.error == "unknown-finding"' <<< "$OUT" >/dev/null || fail "a line that opens no finding: $STATUS $OUT"
  po_file --file --hold "$first" --fixed "$first"
  [ "$STATUS" -eq 2 ] && jq -e '.error == "usage"' <<< "$OUT" >/dev/null || fail "a line given twice: $STATUS $OUT"
  [ "$(creates)" = 0 ] && ! grep -q '^issue list' "$D/calls/gh" || fail "a refused call reached the tracker"
  po_file --file --hold "$first" --fixed "$crit"
  [ "$STATUS" -eq 0 ] || fail "po ship file --file --hold --fixed exited $STATUS: $OUT"
  is "(.held == [$first]) and (.fixed == [$crit]) and (.critical | length) == 0" "--fixed does not remove the critical"
  [ "$(creates)" = 1 ] && ! grep -qF 'first finding' "$D"/issues/*.json || fail "a held finding was filed: $(cat "$D/calls/gh")"
}

test_listing_guards_tell_apart() {
  need_po
  project github
  landed_on_origin
  touch "$D/list-garbage"
  po_file --file
  [ "$STATUS" -eq 1 ] && jq -e '.error == "listing-failed" and (.pending | length) == 2' <<< "$OUT" >/dev/null \
    || fail "a listing that exits 0 without a list: $STATUS $OUT"
  rm "$D/list-garbage"; echo 999 > "$D/open-count"
  po_file --file
  [ "$STATUS" -eq 0 ] && [ "$(creates)" = 2 ] || fail "999 open titles refused the filing: $STATUS $OUT"
  rm "$D/open-count"
  GH_PROGRAM="$SCRATCH/no-such-gh" po_file --file
  [ "$STATUS" -eq 1 ] && jq -e '.error == "tracker-unavailable"' <<< "$OUT" >/dev/null || fail "gh that cannot start: $STATUS $OUT"
  git -C "$R" remote set-url origin https://gitlab.example.org/acme/widget.git
  git -C "$R" config --add "url.$ORIGIN.insteadOf" https://gitlab.example.org/acme/widget.git
  : > "$D/calls/gh"
  po_file --file
  [ "$STATUS" -eq 1 ] && jq -e '.error == "tracker-unavailable"' <<< "$OUT" >/dev/null || fail "origin off github.com: $STATUS $OUT"
  [ ! -s "$D/calls/gh" ] || fail "gh was called for an origin off github.com: $(cat "$D/calls/gh")"
}

test_local_mode_proves_on_target_and_names_the_project() {
  need_po
  project taskwarrior local
  local sha
  sha="$(landing "$(git -C "$R" rev-parse main)")"
  po_file --file
  [ "$STATUS" -eq 1 ] && jq -e '.error == "not-landed"' <<< "$OUT" >/dev/null || fail "a landing built but not on main: $STATUS $OUT"
  [ ! -s "$D/calls/task" ] || fail "task was called before the proof"
  git -C "$R" merge -q --ff-only "$sha"
  po_file --file
  [ "$STATUS" -eq 0 ] && [ "$(imports)" = 2 ] || fail "under local, $(imports) tasks for 2 findings: $STATUS $OUT"
  grep ' export$' "$D/calls/task" | grep -qF 'project:project' || fail "the project is not the main checkout's folder: $(cat "$D/calls/task")"
  jq -se 'all(.project == "project")' "$D"/tasks/*.json >/dev/null || fail "a task went to another project"
}

test_ship_words_go_down() {
  local ship="$METHOD/commands/po-ship.md" words
  words="$(LC_ALL=C wc -w < "$ship")"
  [ "$words" -le 1593 ] || fail "po-ship.md holds $words words, more than 1593"
  grep -qx '## Step 3 — Cleanup, only after proof' "$ship" || fail "po-ship.md lost its Step 3 heading"
  grep -q '^2\. File the open findings' "$ship" || fail "po-ship.md lost its filing step"
}
