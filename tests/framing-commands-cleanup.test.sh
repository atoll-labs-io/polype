#!/usr/bin/env bash
# s124 — the framing commands agree on one path and their landing rules are held by tests.

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

test_stories_paths_agree() {
  local st="$METHOD/commands/po-stories.md" rv="$METHOD/commands/po-stories-review.md" prd="$METHOD/templates/prd.md"
  require_file "$st"; require_file "$rv"; require_file "$prd"
  local fix; fix=$(section_of "$st" 'A story sent back by the review')
  holds "$fix" 'Next: /po-stories-review' 'fix path'
  holds "$fix" '"Before writing" runs again on the stories that remain' 'fix path'
  if grep -qF -- 'Next: /po-research' <<< "$fix"; then fail "fix path still announces /po-research"; fi
  local out; out=$(section_of "$rv" 'Outcome')
  holds "$out" 'Only this bullet applies to it.' 'Outcome'
  holds "$out" 'With a complete review' 'Outcome'
  if grep -qF -- 'read the whole' "$prd"; then fail "templates/prd.md still asks to read the whole document"; fi
  contains "$prd" 'every section has been approved on its own question' || fail "prd.md lacks the new status rule"
}

test_setup_landing_holds() {
  local setup="$METHOD/commands/po-setup.md"
  require_file "$setup"
  local s1; s1=$(section_of "$setup" 'Step 1 — Look before asking')
  holds "$s1" 'once question 1 of Step 2 has given `Target branch`' 'Step 1'
  local s2; s2=$(section_of "$setup" 'Step 2 — Five questions, one AskUserQuestion call each, plus the Platform, design, QA stage, Ship confirmation and Project CLAUDE file follow-ups and the catalogue offer')
  holds "$s2" 'from that reading of the forge, made once `Target branch` is known' 'Step 2'
  local land; land=$(section_of "$setup" 'Landing the framing')
  holds "$land" 'It never commits to `Target branch` directly and never pushes it.' 'landing'
  local loc; loc=$(awk '/^\*\*`Merge mode: local`\*\*/ {on=1} /^\*\*Report\.\*\*/ {on=0} on' <<< "$land")
  holds "$loc" 'A refusal → stop: `framing/<slug>` stays in place and is not deleted' 'local block'
}

test_framing_wording_is_clean() {
  local setup="$METHOD/commands/po-setup.md" arch="$METHOD/commands/po-architect.md"
  require_file "$setup"; require_file "$arch"
  contains "$setup" '→ stop: ancestry is never the proof' || fail "po-setup.md lacks the lower-case stop clause"
  if grep -qF -- 'stop: Ancestry' "$setup"; then fail "po-setup.md still capitalises after the colon"; fi
  local f
  for f in "$setup" "$arch"; do
    contains "$f" 'Never commit a `CLAUDE.md` (ADR-0086)' || fail "$f lacks the ADR reference inside its sentence"
    if grep -qF -- '`AGENTS.local.md`. (ADR-0086)' "$f"; then fail "$f leaves ADR-0086 outside a sentence"; fi
  done
}
