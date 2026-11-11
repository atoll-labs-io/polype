#!/usr/bin/env bash
# s152 — the oracle of the story: an issue po-intake filed becomes a story that fixes it,
# reviewed on its issue and landed as framing, security staying with the person (ADR-0099).

INTAKE="$METHOD/commands/po-intake.md"
LAW="$METHOD/AGENTS.md"
AGENTIC="$METHOD/skills/agentic-stories/SKILL.md"
SREVIEW="$METHOD/skills/stories-review/SKILL.md"
SREVIEWER="$METHOD/agents/stories-reviewer.md"
HELP="$METHOD/commands/po-help.md"
HARNAIS="$ROOT/docs/harnais.md"
ADR99="$ROOT/docs/decisions/ADR-0099-l-echec-d-un-controle-planifie-devient-une-story.md"
ADR90="$ROOT/docs/decisions/ADR-0090-tout-ce-qui-est-a-traiter-devient-une-issue.md"

# Whitespace collapsed, so a phrase holds whatever the line wrapping.
flat() { tr -s '[:space:]' ' ' < "$1"; }
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1" | tr -s '[:space:]' ' '; }
holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }
reads() { settings_read_by "$1" | grep -qx "$2" || fail "${1##*/} does not list $2 in Reads settings"; }

test_intake_writes_defect_stories() {
  require_file "$INTAKE"
  local t p; t="$(flat "$INTAKE")"
  reads "$INTAKE" 'Issue tracker'
  for p in 'the open issues labelled `polype-intake` that no `Fixes` or `Corrige` line of `docs/stories.md` cites' \
    'one story per issue, appended after the existing stories and numbered from the next free `s<n>`' \
    'a `Fixes` line naming the issue (`Corrige` in a French stories file)' \
    'criteria that state the wrong behaviour and the expected one' \
    'the reproduction of the issue in its notes' \
    'an `Owns` drawn from the paths the failure implicates' \
    'no issue text enters a shell argument'; do
    holds "$t" "$p" "po-intake.md"
  done
}

test_intake_stories_reviewed_first() {
  require_file "$INTAKE"; require_file "$SREVIEW"; require_file "$SREVIEWER"
  local t s p
  grep -F '`subagent_type: stories-reviewer`' "$INTAKE" | grep -qF '`Model strong`' \
    || fail "po-intake.md does not dispatch stories-reviewer on \`Model strong\` on the same line"
  t="$(flat "$INTAKE")"
  for p in 'only the new stories, each with its issue as its scope source' \
    '`docs/reviews/stories-intake-<timestamp>.md`' \
    '`<timestamp>` is `date -u +%Y-%m-%d-%H%M`' \
    'nothing lands, and the issues of those stories go to the person'; do
    holds "$t" "$p" "po-intake.md"
  done
  s="$(section_of "$SREVIEW" 'Intake mode')"
  [ -n "$s" ] || fail "stories-review has no '## Intake mode' section"
  for p in 'each new story is judged against its issue, which stands in for the PRD or the brief' \
    'no coverage check of the rest of the file' \
    'so it runs with `Entry mode: —` too'; do
    holds "$s" "$p" "stories-review ## Intake mode"
  done
  t="$(flat "$SREVIEWER")"
  holds "$t" 'In intake mode' "stories-reviewer.md"
  holds "$t" 'its issue stands in for the scope source and `Entry mode` is not read' "stories-reviewer.md"
  frontmatter "$SREVIEWER" | grep -qF '/po-intake' || fail "stories-reviewer description does not name /po-intake"
  grep -F 'The framing files' "$LAW" | grep -qF '`docs/reviews/stories.md`, `docs/reviews/stories-intake-<timestamp>.md`' \
    || fail "Law 6 does not count docs/reviews/stories-intake-<timestamp>.md among the framing files"
}

test_intake_lands_as_framing() {
  require_file "$INTAKE"
  local t p s
  t="$(flat "$INTAKE")"
  for s in 'Target branch' 'Merge mode' 'Ship confirmation'; do reads "$INTAKE" "$s"; done
  for p in 'landed as `## Landing the framing` of `/po-setup` says' \
    'on the branch `framing/intake-<timestamp>`' \
    'cites each issue as `#<n>` and holds no closing keyword' \
    '`close`, `closes`, `closed`, `fix`, `fixes`, `fixed`, `resolve`, `resolves`, `resolved`' \
    'The effective `Ship confirmation` applies as it does to any merge'; do
    holds "$t" "$p" "po-intake.md"
  done
}

test_security_issue_goes_to_the_person() {
  require_file "$INTAKE"
  local t; t="$(flat "$INTAKE")"
  holds "$t" 'An issue whose text bears on security — a secret or a token, an authorization or tenant check, an injection — gets no story' "po-intake.md"
  holds "$t" 'it goes to the person (ADR-0090)' "po-intake.md"
  holds "$t" 'in doubt, it bears on security' "po-intake.md"
}

test_law_7_names_the_exception() {
  require_file "$LAW"; require_file "$AGENTIC"; require_file "$HELP"; require_file "$HARNAIS"
  local law
  law="$(section_of "$LAW" 'Law 7 — Defects are not stories')"
  holds "$law" 'only a person turns a finding into a story.' "Law 7"
  holds "$law" 'The one exception is the failure of a scheduled check filed by `po-intake`, which `/po-intake` turns into a story that fixes it (ADR-0099).' "Law 7"
  holds "$(section_of "$AGENTIC" 'Defect stories')" \
    'The one exception is the failure of a scheduled check filed by `po-intake`, which `/po-intake` turns into such a story (ADR-0099).' "agentic-stories ## Defect stories"
  holds "$(section_of "$HELP" 'Outils')" '`/po-intake`' "po-help ## Outils"
  grep -F 'po-intake.sh --label' "$HARNAIS" | grep -qF "claude -p '/po-intake'" \
    || fail "docs/harnais.md has no line running /po-intake after a check wrapped by po-intake"
}

test_adr_records_the_intake_loop() {
  local files fm t p
  files=$(find "$ROOT/docs/decisions" -name 'ADR-0099-*.md')
  [ "$(printf '%s\n' "$files" | grep -c .)" -eq 1 ] || fail "expected exactly one ADR-0099"
  require_file "$ADR99"
  fm="$(frontmatter "$ADR99")"
  for p in 'adr: 0099' 'status: accepted' 'supersedes: [ADR-0090]' 'superseded-by: []'; do
    grep -qxF -- "$p" <<< "$fm" || fail "ADR-0099 frontmatter lacks the line: $p"
  done
  t="$(flat "$ADR99")"
  for p in "**B. L'issue seule, cadrée par une personne au jalon suivant.** Écartée" \
    'la boucle reste lente' \
    '**C. Une autonomie selon la sévérité.** Écartée' \
    'une échelle de plus à tenir' \
    "Elle remplace l'ADR-0090 sur ce seul point"; do
    holds "$t" "$p" "ADR-0099"
  done
  require_file "$ADR90"
  [ "$(frontmatter "$ADR90")" = "adr: 0090
title: Tout ce qui est à traiter devient une issue dans Issue tracker, la sécurité allant à la personne
status: accepted
date: 2026-10-14
scope: story s134-everything-to-handle-is-an-issue
supersedes: []
superseded-by: [ADR-0099]" ] || fail "ADR-0090 frontmatter must change only its superseded-by line, to [ADR-0099]"
  [ "$(awk 'n >= 2 {print} /^---$/ {n++}' "$ADR90" | cksum)" = "3744232405 4583" ] \
    || fail "the body of ADR-0090 changed: an accepted ADR is never rewritten"
}
