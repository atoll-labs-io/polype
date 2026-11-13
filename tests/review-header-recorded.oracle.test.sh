#!/usr/bin/env bash
# s158 — the oracle of the story: whoever records a review writes its title and link line,
# the reviewer answers below them (ADR-0104, issue #169).

REVIEW="$METHOD/commands/po-review.md"
AGENT="$METHOD/agents/reviewer.md"
TPL="$METHOD/templates/review.md"
LINK="$ROOT/bin/po-link-artifacts"
ADR="$ROOT/docs/decisions/ADR-0104-celui-qui-consigne-une-revue-en-ecrit-l-en-tete.md"

# Whitespace collapsed, so a phrase holds whatever the line wrapping.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1" | tr -s '[:space:]' ' '; }
holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }
line_of() { grep -nF -- "$2" "$1" | head -n 1 | cut -d: -f1; }

test_reviewer_answers_below_the_header() {
  require_file "$AGENT"
  local a; a="$(section_of "$AGENT" 'Your answer')"
  [ -n "$a" ] || fail "reviewer.md has no '## Your answer' section"
  holds "$a" "Your answer starts below the file's header: no \`# Review\` title and no link line" "reviewer ## Your answer"
  holds "$a" 'the context that records your answer writes those two lines itself' "reviewer ## Your answer"
  holds "$a" 'Everything else in `templates/review.md`, except the note under its link line, is the shape of your answer.' "reviewer ## Your answer"
  holds "$(section_of "$REVIEW" Delegation)" 'starting below its header: no `# Review` title and no link line' "po-review ## Delegation"
}

test_template_marks_the_header() {
  require_file "$TPL"
  [ "$(head -n 1 "$TPL")" = '# Review — <id>' ] || fail "review.md does not open with its title"
  local link
  link="$(awk 'NR > 1 && NF {print; exit}' "$TPL")"
  [ "$link" = '[Story](../stories.md) · [Plan](../plans/<id>.md) · [Verification](../verif/<id>.md)' ] \
    || fail "the link line under the title changed: $link"
  [ "$(line_of "$TPL" '<`po record` writes these lines')" -lt "$(line_of "$TPL" 'Diff reviewed:')" ] \
    || fail "the note must sit between the link line and the body"

  # A file recorded as the rule says — the template's two header lines, then an answer without
  # any title — is one po-link-artifacts already counts as linked.
  local d; d="$(mktemp -d)"
  trap "rm -rf '$d'" EXIT
  mkdir -p "$d/docs/reviews" "$d/docs/plans" "$d/docs/verif"
  : > "$d/docs/stories.md"
  printf -- '---\nvalidated: yes\n---\n# Plan — s01-a\n' > "$d/docs/plans/s01-a.md"
  printf '# Verification — s01-a\n' > "$d/docs/verif/s01-a.md"
  {
    awk 'NF {print; if (++n == 2) exit}' "$TPL" | sed 's/<id>/s01-a/g' | awk 'NR == 2 {print ""} {print}'
    printf '\nReview status: complete\nFix loop: 0\n\n## Findings\n- minor — a.sh:1 — style\n\nMax severity: minor\nShip allowed: yes\n'
  } > "$d/docs/reviews/s01-a.md"
  [ "$(sed -n 3p "$d/docs/reviews/s01-a.md")" = '[Story](../stories.md) · [Plan](../plans/s01-a.md) · [Verification](../verif/s01-a.md)' ] \
    || fail "the recorded header is not the template's: $(sed -n 1,3p "$d/docs/reviews/s01-a.md")"
  local out; out="$(bash "$LINK" "$d")" || fail "po-link-artifacts failed on the recorded review"
  ! grep -qx 'docs/reviews/s01-a.md' <<< "$out" || fail "po-link-artifacts still finds the recorded review unlinked"
}

test_adr_records_the_header_rule() {
  require_file "$ADR"
  frontmatter "$ADR" | grep -qx 'adr: 0104' || fail "ADR-0104 frontmatter lacks adr: 0104"
  frontmatter "$ADR" | grep -qx 'status: accepted' || fail "ADR-0104 is not accepted"
  frontmatter "$ADR" | grep -qx 'scope: story s158-review-header-recorded' || fail "ADR-0104 scope is not the story"
  local out opts
  out="$(section_of "$ADR" 'Decision Outcome')"
  holds "$out" "Celui qui consigne la revue écrit l'en-tête" "ADR-0104 ## Decision Outcome"
  holds "$out" 'le verdict, les constats et les lignes de statut restent mot pour mot' "ADR-0104 ## Decision Outcome"
  holds "$out" "seul l'en-tête du fichier vient du gabarit" "ADR-0104 ## Decision Outcome"
  opts="$(section_of "$ADR" 'Considered Options')"
  holds "$opts" 'Insérer la ligne de liens seulement quand elle manque' "ADR-0104 ## Considered Options"
  holds "$opts" 'une exception conditionnelle de plus à la transcription' "ADR-0104 ## Considered Options"
  holds "$opts" 'Faire refuser la revue par `po-gate` et arrêter la voie' "ADR-0104 ## Considered Options"
  holds "$opts" 'chaque oubli du relecteur devient un arrêt pour la personne' "ADR-0104 ## Considered Options"
  holds "$opts" 'ne répare pas la ligne sous le premier titre' "ADR-0104 ## Considered Options"
  [ "$(line_of "$ADR" 'Insérer la ligne de liens seulement quand elle manque')" -lt \
    "$(line_of "$ADR" 'Faire refuser la revue par `po-gate`')" ] \
    || fail "ADR-0104 must list the conditional insertion before the po-gate refusal"
}
