#!/usr/bin/env bash
# s39 — rules, help, README and parity matrix must tell the same installation story as bin/polype.

RULES="$METHOD/AGENTS.md"
HELP="$METHOD/commands/po-help.md"
README="$ROOT/README.md"
MATRIX="$ROOT/docs/parite-killer-saas.md"

# Every backticked token of a file, one per line.
tokens_of() { grep -o '`[^`]*`' "$1" | tr -d '`'; }

# The status cell (last column) of the matrix row whose id is $1.
status_of() { awk -F'|' -v id=" $1 " '$2 == id {print $(NF - 1); exit}' "$MATRIX"; }

test_rules_point_at_the_installer() {
  require_file "$RULES"

  contains "$RULES" '`bin/polype` is the installer'

  # The two poses, told apart: global serves every project, init activates one repository.
  contains "$RULES" 'polype install --global'
  contains "$RULES" 'the commands, the subagents and the skills in `~/.claude/`'
  contains "$RULES" '`polype init <project>` then activates one repository'
  contains "$RULES" 'the templates, the gate and the assembled `AGENTS.md`'
  contains "$RULES" '`polype install <project>` does both at once inside a single repository'

  # The detail is not duplicated here: the reader is sent to the installation document.
  contains "$RULES" 'docs/installation.md'
  require_file "$ROOT/docs/installation.md"

  # What the section already guaranteed must survive the rewrite.
  contains "$RULES" 'a reference to `templates/<name>.md` means `.polype/templates/<name>.md`'
  contains "$RULES" 'called `po-gate` in these rules'
  contains "$RULES" 'committed on `Target branch`'
  contains "$RULES" 'Never edit an installed file'
}

test_help_mentions_installation_and_status() {
  require_file "$HELP"
  contains "$HELP" 'Reads settings: none'

  # Laying Polype down, both shapes.
  contains "$HELP" '`polype install --global` puis `polype init <projet>`'
  contains "$HELP" '`polype install <projet>` pose tout dans un seul dépôt'

  # Auditing an install: the stamped version and what drifted.
  contains "$HELP" '`polype check` — la version posée et les fichiers qui ont dérivé'

  # The block comes first: one installs Polype before framing a project with it.
  local install_line setup_line
  install_line=$(grep -n '^## Installation' "$HELP" | cut -d: -f1)
  setup_line=$(grep -n '^## Mise en place' "$HELP" | cut -d: -f1)
  [ -n "$install_line" ] || fail "po-help.md has no Installation section"
  [ -n "$setup_line" ] || fail "po-help.md lost its 'Mise en place' section"
  [ "$install_line" -lt "$setup_line" ] || fail "po-help.md puts Installation after 'Mise en place'"
}

test_readme_describes_the_project_and_its_install() {
  require_file "$README"

  # What Polype is, and the three entry modes.
  contains "$README" 'Une méthode de dev agentique'
  contains "$README" '**Remplacer** un SaaS existant'
  contains "$README" '**Adapter** un SaaS existant'
  contains "$README" '**Partir de zéro**'

  # The cycle, its commands and the gates that bound them.
  contains "$README" '## Le cycle d'"'"'une story'
  contains "$README" 'pas de code sans plan marqué validé'
  contains "$README" 'pas de ship sans verdict explicite'
  contains "$README" 'Seul un défaut critique bloque le ship'

  # The fleet, with the two limits that keep it honest.
  contains "$README" 'les ships restent sériels'
  contains "$README" 'la ligne `Owns` d'"'"'une story borne les chemins'

  # The installation, with the installer and a link to the full procedure.
  contains "$README" '`bin/polype` pose la méthode'
  contains "$README" 'polype install --global'
  contains "$README" 'polype init <projet>'
  contains "$README" '[docs/installation.md](docs/installation.md)'

  # The two promises that never existed are gone.
  ! grep -qF 'install.sh' "$README" || fail 'README.md still announces install.sh, which does not exist'
  ! grep -qF 'boilerplates/' "$README" || fail 'README.md still announces boilerplates/, which does not exist'

  # Every repository path the README names must exist — backticked tokens and link targets alike.
  # A token holding a placeholder (`<projet>`, `…`) names a file of the reader's project: skipped.
  local resolved=0 token
  while read -r token; do
    case "$token" in
      docs/*|method/*|bin/*|tests/*) ;;
      *) continue ;;
    esac
    case "$token" in *'<'*|*'…'*|*'*'*) continue ;; esac
    [ -e "$ROOT/$token" ] || fail "README.md points at a path that does not exist: $token"
    resolved=$((resolved + 1))
  done < <(tokens_of "$README"; grep -o '](\([^):]*\))' "$README" | sed 's/^](//; s/)$//')
  [ "$resolved" -gt 0 ] || fail "no repository path was resolved: the check proves nothing"

  # Same for the commands it sends the reader to.
  local commands=0 cmd
  while read -r cmd; do
    [ -n "$cmd" ] || continue
    [ -f "$METHOD/commands/${cmd#/}.md" ] || fail "README.md names an absent command: $cmd"
    commands=$((commands + 1))
  done < <(grep -o '/po-[a-z-]*' "$README" | sort -u)
  [ "$commands" -gt 0 ] || fail "no Polype command was resolved: the check proves nothing"
}

test_parity_matrix_reflects_the_distribution() {
  require_file "$MATRIX"

  local id status
  for id in H01 H02 H03 H04; do
    status=$(status_of "$id")
    [ -n "$status" ] || fail "row $id is missing from the parity matrix"
    case "$status" in
      *'à faire'*) fail "$id is still 'à faire' while the distribution ships: $status" ;;
      *fait*|*partiel*) ;;
      *) fail "$id has no readable status: $status" ;;
    esac
  done

  # Done rows name where the mechanism lives; the installer is the answer for both.
  grep -qF 'bin/polype' <<< "$(status_of H01)" || fail 'H01 does not name bin/polype'
  grep -qF 'docs/installation.md' <<< "$(status_of H01)" || fail 'H01 does not name docs/installation.md'
  grep -qF 'bin/polype`' <<< "$(status_of H02)" || fail 'H02 does not name bin/polype'

  # Partial rows say what is missing, not just that something is.
  grep -qF 'partiel' <<< "$(status_of H03)" || fail 'H03 must stay partial: the Codex emission is deferred'
  grep -qF 'method/' <<< "$(status_of H03)" || fail 'H03 does not name the single source'
  grep -qF 'ADR-0005' <<< "$(status_of H03)" || fail 'H03 does not say what defers the Codex emission'
}

# The Polype cell (fourth column) of the matrix row whose id is $1.
polype_of() { awk -F'|' -v id=" $1 " '$2 == id {print $5; exit}' "$MATRIX"; }

test_readme_describes_the_pre_commit() {
  require_file "$README"

  contains "$README" 'refuse, sur toutes les branches'
  contains "$README" "fichier d'environnement, clé privée ou jeton connu"
  contains "$README" "un commit de code dont le plan n'est pas validé"
  contains "$METHOD/hooks/po-gate.sh" 'on every branch'
  ! grep -qF "Un hook de pre-commit refuse un commit de code" "$README" || fail 'README still states the narrow pre-commit rule'
}

test_parity_h04_matches_the_model_rule() {
  require_file "$MATRIX"

  local cell status
  cell=$(polype_of H04)
  status=$(status_of H04)
  grep -qF '`Model strong`' <<< "$cell" || fail 'H04 does not name Model strong'
  grep -qF '`Model light`' <<< "$cell" || fail 'H04 does not name Model light'
  grep -qF 'complexité' <<< "$cell" || fail 'H04 does not tie the model to complexity'
  grep -qF 'ADR-0032' <<< "$cell" || fail 'H04 does not cite ADR-0032'
  ! grep -qF 'Identique' <<< "$cell" || fail 'H04 still says the models are identical'
  grep -qF 'fait' <<< "$status" || fail "H04 is not done: $status"
  grep -qF 'method/commands/po-execute.md' <<< "$status" || fail 'H04 does not name where the rule lives'
  ! grep -qF 'partiel' <<< "$status" || fail "H04 is still partial: $status"
}
