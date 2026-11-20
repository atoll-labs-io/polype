#!/usr/bin/env bash
# s134 — everything to handle is an issue.

LAW="$METHOD/AGENTS.md"
SHIP="$METHOD/commands/po-ship.md"
DRIVE="$METHOD/commands/po-drive.md"
SETUP="$METHOD/commands/po-setup.md"
TEMPLATE="$METHOD/templates/agents-local.md"

section_of() { awk -v h="$2" '$0 == h {on=1; next} /^## / {on=0} on' "$1" | tr -s '[:space:]' ' '; }

has() { case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac; }

holds() { has "$1" "$2" || fail "$3 lacks: $2"; }

test_law_files_everything_to_handle() {
  local law person p
  grep -qx '## Law 7 — Defects are not stories' "$LAW" || fail "Law 7 heading changed"
  law="$(section_of "$LAW" '## Law 7 — Defects are not stories')"
  for p in 'only a person turns a finding into a story.' \
    'is filed at once in `Issue tracker` by the lead, with its context' \
    'the person, a review, a subagent or the lead itself' \
    '`docs/decisions-log.md`' \
    'With `Issue tracker: —`, nothing is filed: the lead brings each item to the person instead.' \
    'The findings a shipped review leaves open are filed by `/po-ship`'; do
    holds "$law" "$p" "Law 7"
  done
  grep -qF 'into an issue or a story' "$LAW" && fail "method/AGENTS.md still says: into an issue or a story"
  person="$(section_of "$LAW" '## What goes to the person')"
  holds "$person" 'a new idea outside the approved scope, whoever brought it up; the lead also files it in `Issue tracker`' "What goes to the person"
  holds "$person" 'three motives, and only these, plus the hand-over of Law 7: under `Issue tracker: —`' "What goes to the person"
}

test_ship_files_open_findings() {
  local step3 n_proof n_file n_remove
  step3="$(section_of "$SHIP" '## Step 3 — Cleanup, only after proof')"
  for p in 'the review is not lost with the worktree, since Step 1 committed it and it lands with the story'"'"'s commit'; do
    holds "$step3" "$p" "po-ship Step 3"
  done
  n_proof=$(grep -n '^1\. Proof\.' "$SHIP" | cut -d: -f1)
  n_file=$(grep -n '^2\. File the open findings' "$SHIP" | cut -d: -f1)
  n_remove=$(grep -n 'git worktree remove <path>' "$SHIP" | cut -d: -f1)
  [ -n "$n_proof" ] && [ -n "$n_file" ] && [ -n "$n_remove" ] || fail "po-ship Step 3 lacks the proof, filing or removal step"
  [ "$n_proof" -lt "$n_file" ] && [ "$n_file" -lt "$n_remove" ] || fail "filing must sit after the proof and before the worktree removal"
  holds "$(section_of "$DRIVE" '## Report')" 'the merged lanes waiting for cleanup, each with its pull request URL' "po-drive report"
  holds "$(section_of "$DRIVE" '## Report')" 'a merged lane waiting for cleanup — its pull request prints `MERGED` while its worktree still exists — is listed among them' "po-drive status"
}

test_security_goes_to_the_person() {
  local step3
  step3="$(section_of "$SHIP" '## Step 3 — Cleanup, only after proof')"
  holds "$step3" '"not filed: security (ADR-0077)"' "po-ship Step 3"
  holds "$(section_of "$LAW" '## Law 7 — Defects are not stories')" \
    'A security finding or a security idea is never filed on its own: it goes to the person' "Law 7"
}

test_readers_list_issue_tracker() {
  local f
  for f in "$SHIP" "$DRIVE"; do
    settings_read_by "$f" | grep -qx 'Issue tracker' || fail "${f##*/} does not list Issue tracker in Reads settings"
  done
  for f in "$METHOD"/commands/*.md "$METHOD"/agents/*.md; do
    [ "${f##*/}" = po-setup.md ] && continue
    grep -v '^Reads settings:' "$f" | grep -qF '`Issue tracker`' || continue
    settings_read_by "$f" | grep -qx 'Issue tracker' || fail "${f##*/} mentions Issue tracker without reading it"
  done
}

test_setup_proposes_the_forge() {
  holds "$(section_of "$SETUP" '## Step 2 — Five questions, one AskUserQuestion call each, plus the Platform, design, QA stage, Ship confirmation and Project CLAUDE file follow-ups and the catalogue offer')" \
    'write `github` when its host is `github.com`, and `taskwarrior` for any other host or when there is no remote' "po-setup Step 2"
  contains "$SETUP" 'Nothing else is asked'
  grep -qF 'takes no question either' "$SETUP" && fail "po-setup still says: takes no question either"
  holds "$(section_of "$SETUP" '## Step 3 — Write and commit')" 'Then name the `Issue tracker` value written from the forge and say the person changes it by asking in conversation' "po-setup finish"
  contains "$TEMPLATE" 'where ideas, features and defects to handle are filed'
  grep -qx 'Issue tracker:     github' "$ROOT/AGENTS.local.md" || fail "AGENTS.local.md lacks: Issue tracker:     github"
}

test_adr_records_the_rule() {
  local files adr p
  files=$(find "$ROOT/docs/decisions" -name 'ADR-0090-*.md')
  [ "$(printf '%s\n' "$files" | grep -c .)" -eq 1 ] || fail "expected exactly one ADR-0090"
  adr="$(tr -s '[:space:]' ' ' < "$files")"
  for p in 'adr: 0090' 'status: accepted' \
    '**B. Seule la personne dépose.** Écartée' \
    '**C. Ne déposer que les défauts.** Écartée' \
    '**D. Déposer aussi la sécurité.** Écartée' \
    'avec `Issue tracker: —`, rien n'"'"'est déposé' \
    'Cette retenue protège moins qu'"'"'elle n'"'"'en a l'"'"'air : la revue elle-même, constats de sécurité compris, est déjà publique' \
    'parce qu'"'"'elle lit la revue dans le worktree' \
    'non par l'"'"'index de recherche' \
    'Le texte d'"'"'un constat n'"'"'entre jamais dans un argument de shell'; do
    holds "$adr" "$p" "ADR-0090"
  done
}

test_finding_text_never_enters_a_command() {
  holds "$(section_of "$LAW" '## Law 7 — Defects are not stories')" \
    'Whoever files, the text never travels inside a shell argument' "Law 7"
}
