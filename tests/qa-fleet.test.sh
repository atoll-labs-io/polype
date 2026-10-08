#!/usr/bin/env bash
# s57 — the orchestrator and the fleet run QA for a screen story, and a review blocked on QA goes back to QA.

ORCH="$METHOD/commands/po-orchestrator.md"
DRIVE="$METHOD/commands/po-drive.md"
STATUS="$METHOD/commands/po-status.md"
REVIEW="$METHOD/commands/po-review.md"
HELP="$METHOD/commands/po-help.md"
README="$ROOT/README.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

# Line number of the only line holding the phrase; fails when it is absent or ambiguous.
only_line() {
  local hits; hits=$(grep -nF -- "$2" <<< "$1" | cut -d: -f1)
  [ -n "$hits" ] || fail "$3 lacks: $2"
  [ "$(wc -l <<< "$hits")" -eq 1 ] || fail "$3 holds more than one line with: $2"
  echo "$hits"
}

before() { [ "$1" -lt "$2" ] || fail "$3"; }

reads_setting() { settings_read_by "$1" | grep -qx "$2" || fail "${1##*/} does not read $2"; }

test_orchestrator_runs_qa_for_a_screen() {
  require_file "$ORCH"
  reads_setting "$ORCH" 'QA stage'
  local e q r
  e=$(grep -n '^## Stage 5 — Execute$' "$ORCH" | cut -d: -f1)
  q=$(grep -n '^## Stage 6 — QA$' "$ORCH" | cut -d: -f1)
  r=$(grep -n '^## Stage 7 — Review$' "$ORCH" | cut -d: -f1)
  [ -n "$e" ] && [ -n "$q" ] && [ -n "$r" ] || fail "po-orchestrator.md needs Stage 5 — Execute, Stage 6 — QA and Stage 7 — Review"
  before "$e" "$q" "the QA stage must follow execute"
  before "$q" "$r" "the QA stage must precede review"
  local qa; qa=$(section_of "$ORCH" 'Stage 6 — QA')
  holds "$qa" '`QA stage` is `screens`' 'the QA stage'
  holds "$qa" 'Apply `/po-qa` as written' 'the QA stage'
  holds "$qa" 'first run and fix run alike' 'the QA stage'
  holds "$qa" 'no review is requested on a walk that did not happen' 'the QA stage'
  holds "$(section_of "$ORCH" 'Stage 1 — Track')" 'because `/po-flow` runs no QA' 'the track stage'
}

test_drive_wave_includes_qa() {
  require_file "$DRIVE"
  reads_setting "$DRIVE" 'QA stage'
  local wave; wave=$(section_of "$DRIVE" 'A wave')
  local i q r
  i=$(only_line "$wave" 'subagent_type: implementer' 'the wave section')
  q=$(only_line "$wave" 'subagent_type: qa' 'the wave section')
  r=$(only_line "$wave" 'subagent_type: reviewer' 'the wave section')
  before "$i" "$q" "the qa dispatch must follow the implementer"
  before "$q" "$r" "the qa dispatch must precede the reviewer"
  local item; item=$(sed -n "${q}p" <<< "$wave")
  holds "$item" '`QA stage` is `screens`' 'the QA item'
  holds "$item" 'the prompt `/po-qa` fixes' 'the QA item'
  holds "$item" 'QA evidence' 'the QA item'
  holds "$item" '-- docs/qa/<id>/' 'the QA item'
  holds "$item" 'every qa of a wave leaves before any of them is waited on' 'the QA item'
  holds "$wave" 'then every implementer, then every qa, then every reviewer' 'the wave section'
  holds "$(section_of "$DRIVE" 'Checks')" '`QA stage` missing → only the lanes of stories whose text shows a screen stop' 'the checks'
}

test_drive_resumes_on_qa_current() {
  require_file "$DRIVE"
  local resuming; resuming=$(section_of "$DRIVE" 'Resuming')
  local code blocked_qa stale_qa no_review stale_review review_on_qa fix_run
  code=$(only_line "$resuming" 'no record or `po-gate verif-current <id>` fails | the code stage' 'the resuming table')
  blocked_qa=$(only_line "$resuming" '`QA status:` of `docs/qa/<id>/report.md` is `blocked` | a human' 'the resuming table')
  stale_qa=$(only_line "$resuming" '`po-gate qa-current <id>` fails | the QA stage' 'the resuming table')
  no_review=$(only_line "$resuming" '| record current, no `docs/reviews/<id>.md` |' 'the resuming table')
  stale_review=$(only_line "$resuming" '| record current, review blocked,' 'the resuming table')
  review_on_qa=$(only_line "$resuming" '| a blocked review whose `Next action:` names `/po-qa` | the review stage, at the same `Fix loop:`' 'the resuming table')
  fix_run=$(only_line "$resuming" '| a fix run, at loop `Fix loop:` + 1 |' 'the resuming table')
  before "$code" "$blocked_qa" "a stale record must be rebuilt before any QA row applies"
  before "$blocked_qa" "$stale_qa" "a blocked walk goes to a human before a new walk is tried"
  before "$stale_qa" "$no_review" "the QA rows must come before every review row"
  before "$stale_review" "$review_on_qa" "a stale review must be judged again before the QA return applies"
  before "$review_on_qa" "$fix_run" "a review blocked on QA must not fall into the fix-run row"
  holds "$resuming" 'lists the report | the evidence commit of `/po-qa`, without a new walk' 'the resuming table'
  holds "$resuming" 'Commits whose subject is `<id>: QA evidence` are not implementer commits and are never counted' 'the resuming section'
}

test_status_reports_qa() {
  require_file "$STATUS"
  reads_setting "$STATUS" 'QA stage'
  contains "$STATUS" 'whether `po-gate qa-current <id>` passes'
  contains "$STATUS" '`QA stage` unset → shown as unset for a screen story, never guessed'
  contains "$STATUS" '· record · qa · review ·'
  contains "$STATUS" '→ QA (`/po-qa <id>`'
}

test_help_and_readme_show_qa() {
  require_file "$HELP"; require_file "$README"
  contains "$HELP" '`/po-orchestrator` et `/po-drive` la lancent eux-mêmes quand `QA stage` vaut `screens`'
  contains "$HELP" 'ajoute le design et la QA pour une story avec écran'
  local e q r
  e=$(grep -n '^| Exécution | `/po-execute`' "$README" | cut -d: -f1)
  q=$(grep -n '^| QA (story avec écran, `QA stage: screens`) | `/po-qa` |' "$README" | cut -d: -f1)
  r=$(grep -n '^| Revue | `/po-review`' "$README" | cut -d: -f1)
  [ -n "$e" ] && [ -n "$q" ] && [ -n "$r" ] || fail "README.md cycle table needs Exécution, QA and Revue rows"
  before "$e" "$q" "the README QA row must follow Exécution"
  before "$q" "$r" "the README QA row must precede Revue"
  contains "$README" 'une revue bloquée par la QA repart vers `/po-qa` sans consommer de fix run'
}

test_qa_blocked_review_goes_back_to_qa() {
  require_file "$REVIEW"; require_file "$ORCH"; require_file "$DRIVE"
  contains "$REVIEW" 'this review keeps the same `Fix loop:` value instead, because a QA return is not a fix run'
  contains "$REVIEW" 'Run /po-qa <id>, then /po-review <id> again; no fix run is spent.'
  contains "$REVIEW" '- Any other `Ship allowed: no` → "Ship blocked for <id>. Run /po-execute <id> (fix run)'

  local review; review=$(section_of "$ORCH" 'Stage 7 — Review')
  holds "$review" 'back to stage 6, then stage 7 again at the same `Fix loop:`' 'the review stage'
  holds "$review" 'spends none of the two' 'the review stage'
  holds "$review" 'two `<id>: QA evidence` commits since the last implementer commit → stop for a human' 'the review stage'
  holds "$(section_of "$ORCH" 'Stage 5 — Execute')" 'a review blocked on QA never triggers the fix run' 'the execute stage'

  local verdict; verdict=$(section_of "$DRIVE" 'The verdict, and the fix runs')
  holds "$verdict" 'A review blocked on QA is not a fix run: the lane goes back to `qa`, then to `reviewer` at the same `Fix loop:`' 'the verdict section'
  holds "$verdict" 'no `Max attempts` unit is spent' 'the verdict section'
  holds "$verdict" 'Any other `Ship allowed: no` sends that lane back to `implementer` as a fix run' 'the verdict section'
}
