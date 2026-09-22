#!/usr/bin/env bash
# s38 — docs/migration.md: what /spec and /drive become, what to remove, how to resume a project.

DOC="$ROOT/docs/migration.md"

# Every backticked token in the document, one per line.
tokens_of() { grep -o '`[^`]*`' "$1" | tr -d '`'; }

test_migration_maps_every_old_concept() {
  require_file "$DOC"
  contains "$DOC" 'Ce qui disparaît'

  # One notion of /spec or /drive per line, each with its Polype counterpart.
  contains "$DOC" 'Interrogation sceptique'
  contains "$DOC" 'Carte des manques et pre-mortem'
  contains "$DOC" 'Brief approuvé dans le vault'
  contains "$DOC" 'ADR par `/record-adr`'
  contains "$DOC" 'User stories par `/user-story`'
  contains "$DOC" 'Packet `F03`'
  contains "$DOC" '`owns` du packet'
  contains "$DOC" 'la ligne `Owns` de la story'
  contains "$DOC" 'Acceptation exécutable et bloc `Verify`'
  contains "$DOC" 'Worker : écrit le code, ses tests, et se relit'
  contains "$DOC" 'Worktree `feat/<slug>/F03`'
  contains "$DOC" 'un worktree par story sous `Worktree root`'
  contains "$DOC" "Branche d'intégration \`spec/<slug>\`"
  contains "$DOC" 'Lane et réglage `parallel`'
  contains "$DOC" 'État des packets dans le tracker (`octo`, `sensei`)'
  contains "$DOC" 'Bloc `autonomy` de la spec'
  contains "$DOC" 'Fichier de spec'

  # What disappears, each tied to the decision that retired it.
  contains "$DOC" 'squash direct sur `Target branch`'
  contains "$DOC" '(ADR-0015)'
  contains "$DOC" 'état dérivé des worktrees et de git'
  contains "$DOC" 'le réglage `Tracker` ne décide de rien'
  contains "$DOC" '(ADR-0018)'
  contains "$DOC" 'dans le vault (ADR-0002)'
}

test_migration_gives_a_step_by_step_removal() {
  require_file "$DOC"

  # The four files, named one by one: a reader must not have to guess the directory's contents.
  contains "$DOC" '~/.claude/skills/spec/SKILL.md'
  contains "$DOC" '~/.claude/skills/spec/interrogation.md'
  contains "$DOC" '~/.claude/skills/spec/product-scaffold.md'
  contains "$DOC" '~/.claude/skills/drive/SKILL.md'
  contains "$DOC" 'rmdir ~/.claude/skills/spec ~/.claude/skills/drive'

  # The safe order and the checks that come before the deletion.
  contains "$DOC" "D'abord poser Polype"
  contains "$DOC" 'Vérifier, avant de supprimer'
  contains "$DOC" 'polype check --global'
  contains "$DOC" "Aucun projet en cours ne dépend d'un packet non repris"
  contains "$DOC" '`octo` et `sensei` restent'
  contains "$DOC" 'ne fera pas ce travail'
  contains "$DOC" 'vivent hors du dépôt'
  contains "$DOC" 'chezmoi forget'
}

test_migration_covers_a_project_in_flight() {
  require_file "$DOC"

  contains "$DOC" 'Reprendre un projet en vol'
  contains "$DOC" 'Arrêter la flotte'
  contains "$DOC" 'git worktree remove'
  contains "$DOC" 'git worktree prune'
  contains "$DOC" "Solder la branche d'intégration"
  contains "$DOC" 'Réécrire les packets restants en stories'
  contains "$DOC" 'se recopie tel quel dans `Owns`'
  contains "$DOC" 'devient `Dépend de`'
  contains "$DOC" 'on renumérote en `s01-…`'
  contains "$DOC" 'Rapatrier le cadrage'
  contains "$DOC" 'Fermer le tracker'
  contains "$DOC" 'À partir de quel état on lance Polype'
  contains "$DOC" 'polype init <projet>'
  contains "$DOC" '/po-setup'
}

# The document exists, names both skills, and every reference it makes can be followed.
test_migration_doc_is_checked_by_a_test() {
  require_file "$DOC"
  contains "$DOC" '`/spec`'
  contains "$DOC" '`/drive`'

  # A repository path written between backticks must exist. A token holding a placeholder
  # (`<id>`, `…`) names a file of the reader's project, not of this repository: it cannot be
  # resolved, so it is skipped — which is why the document writes those as `<projet>/…`.
  local resolved=0 token
  while read -r token; do
    case "$token" in
      docs/*|method/*|bin/*|tests/*) ;;
      *) continue ;;
    esac
    case "$token" in *'<'*|*'…'*|*'*'*) continue ;; esac
    [ -e "$ROOT/$token" ] || fail "docs/migration.md points at a path that does not exist: $token"
    resolved=$((resolved + 1))
  done < <(tokens_of "$DOC")
  [ "$resolved" -gt 0 ] || fail "no repository path was resolved: the check proves nothing"

  # Same for the commands it sends the reader to.
  local commands=0 cmd
  while read -r cmd; do
    [ -n "$cmd" ] || continue
    [ -f "$METHOD/commands/${cmd#/}.md" ] || fail "docs/migration.md names an absent command: $cmd"
    commands=$((commands + 1))
  done < <(grep -o '/po-[a-z-]*' "$DOC" | sort -u)
  [ "$commands" -gt 0 ] || fail "no Polype command was resolved: the check proves nothing"
}
