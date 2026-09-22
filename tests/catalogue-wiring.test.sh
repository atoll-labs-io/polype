#!/usr/bin/env bash
# s44 — setup, rules and help point a new project at the boilerplate catalogue.

SETUP="$METHOD/commands/po-setup.md"
RULES="$METHOD/AGENTS.md"
HELP="$METHOD/commands/po-help.md"
MATRIX="$ROOT/docs/parite-killer-saas.md"

test_setup_offers_the_catalogue() {
  contains "$SETUP" "whether the repository has a base, as \`/po-architect\` defines it"
  contains "$SETUP" 'When step 1 found no base, offer the catalogue before question 5'
  contains "$SETUP" '`boilerplates/*/profile.md`'
  contains "$SETUP" 'plus the answer "no profile"'
  contains "$SETUP" "A chosen profile's \`## Commands\` block becomes the suggestions of question 5, copied verbatim."
  contains "$SETUP" 'A repository that already has a base gets no offer.'
  contains "$SETUP" 'the conventions section holds one line naming `boilerplates/<name>/profile.md` and its `Commit profiled`'
}

test_rules_name_the_catalogue() {
  contains "$RULES" "Boilerplate profiles live in Polype's repository, at \`boilerplates/<name>/profile.md\`."
  contains "$RULES" 'records the chosen one in the conventions of `AGENTS.local.md`'
  contains "$RULES" '`/po-architect` starts its reading from that profile'
}

test_help_mentions_the_catalogue() {
  contains "$HELP" 'propose le catalogue de profils de `boilerplates/`'
}

test_parity_matrix_reflects_the_catalogue() {
  local id cell bad=""
  for id in B03 C01 C07; do
    cell=$(grep -m1 "^| $id |" "$MATRIX" | awk -F' \\| ' '{print $NF}')
    [[ "$cell" == "fait — "* ]] || bad+="$id is not done; "
    [[ "$cell" != *"à venir"* && "$cell" != *"en M4"* ]] || bad+="$id still defers work; "
  done
  grep -m1 '^| C07 |' "$MATRIX" | grep -qF '`boilerplates/`' || bad+="C07 does not cite boilerplates/; "
  [ -z "$bad" ] || fail "$bad"
}
