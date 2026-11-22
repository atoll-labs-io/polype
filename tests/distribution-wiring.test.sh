#!/usr/bin/env bash
# s39 — the rules point at the installer, and the README tells the pre-commit's refusals as po-gate holds them.

RULES="$METHOD/AGENTS.md"
README="$ROOT/README.md"

test_rules_point_at_the_installer() {
  contains "$RULES" 'Never edit an installed file'
}

test_readme_describes_the_pre_commit() {
  require_file "$README"

  contains "$README" 'refuse, sur toutes les branches'
  contains "$README" "fichier d'environnement, clé privée ou jeton connu"
  contains "$README" "un commit de code dont le plan n'est pas validé"
  contains "$METHOD/hooks/po-gate.sh" 'on every branch'
  ! grep -qF "Un hook de pre-commit refuse un commit de code" "$README" || fail 'README still states the narrow pre-commit rule'
}
