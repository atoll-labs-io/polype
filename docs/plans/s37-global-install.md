---
validated: yes
---
# Plan — s37-global-install

[Story](../stories.md) · [Research](../research/s37-global-install.md)

Branche `story/s37-global-install`. Lire `docs/research/s37-global-install.md` d'abord ; ce plan s'appuie dessus sans le répéter.

## Story
Poser Polype une fois dans `~/.claude`, l'activer projet par projet, documenter le suivi chezmoi (ADR-0004).
Critères : `installer_global_puts_commands_in_the_user_home`, `installer_init_activates_a_project_after_a_global_install`, `installer_global_update_is_idempotent`, `docs_explain_the_chezmoi_path`.

### Les trois questions ouvertes, tranchées
| Question | Décision | Raison |
| --- | --- | --- |
| Nom de la variable de surcharge | `CLAUDE_CONFIG_DIR`, défaut `$HOME/.claude` | Convention de Claude Code : un utilisateur ayant déplacé sa configuration est servi sans réglage. Les tests l'exportent **et** redéfinissent `HOME`, pour qu'un oubli ne puisse pas atteindre la vraie configuration. |
| `init` exige-t-il une pose globale ? | Non : `init` pose le volet projet quoi qu'il arrive, et avertit sur `stderr` quand `$CLAUDE_CONFIG_DIR/polype/version` manque | Le critère dit « après une installation globale » sans l'exiger ; un arrêt dur rendrait `init` inutilisable pendant une migration. |
| Portée de `--global` | Les quatre sous-commandes l'acceptent | Une fois la racine de pose paramétrée, `update`, `check` et `remove` en découlent sans code propre ; et s39 promet une aide qui dit « comment vérifier une installation », ce qui exige `check --global`. |

## Tasks
1. [x] **Paramétrer la racine de pose.** Remplacer la variable globale `project` par un couple `root` (base de destination) + `state_dir` (où vivent `manifest`, `checksums`, `version`), et faire prendre à `shipped_pairs` la liste de couples `source:destination` en argument au lieu de la figer (`bin/polype:47-56`). `cmd_install`/`cmd_update`/`cmd_check`/`cmd_remove` travaillent sur `root`. — Test qui échoue : `installer_supports_install_update_check_and_remove` et les 9 autres de `tests/installer.test.sh`, qui passent par ce chemin.
2. [x] **Découper l'analyse des arguments** (`bin/polype:27-42`, `main` `:262-274`) : `<install|update|check|remove> (--global | <projet>) [--hooks]` et `init <projet> [--hooks]`. `--global` et un répertoire de projet donnés ensemble → usage et sortie 2 ; ni l'un ni l'autre → usage et sortie 2. — Test : `installer_global_rejects_a_project_and_global_together`.
3. [x] **Le mode global.** `home="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"`. Couples posés : `commands:commands`, `agents:agents`, `skills:skills` (donc `~/.claude/commands/po-*.md`, pas de préfixe `.claude/`). Charge utile : `bin/` et `method/` copiés sous `$home/polype/`, si bien que `$home/polype/bin/polype` résout sa méthode par `../method` sans chemin en dur (recherche, fait 1). État dans `$home/polype/{manifest,checksums,version}`. Pas d'`AGENTS.md`, pas de `CLAUDE.md`, pas de `.gitignore`, pas de `core.hooksPath` : ces quatre-là sont du ressort du projet. — Test : `installer_global_puts_commands_in_the_user_home`.
4. [x] **`cmd_init`.** Pose côté projet seulement : `templates:.polype/templates`, `hooks:.polype/hooks` (exécutables), puis `assemble_agents_md`, `ignore_worktrees_and_env`, `set_hooks_path`, et les trois fichiers d'état sous `$projet/.polype/`. Aucune copie de `commands/`, `agents/`, `skills/`. Avertir sur `stderr` si `$home/polype/version` manque. — Test : `installer_init_activates_a_project_after_a_global_install`.
5. [x] **Élaguer sans mordre.** `prune_empty_dirs` (`bin/polype:57-59`) prend la liste des répertoires à élaguer. En mode projet, comportement inchangé (`.claude/`, `.polype/`, supprimés s'ils deviennent vides). En mode global, `-mindepth 1` sur `$home/commands`, `$home/agents`, `$home/skills` — jamais `$home` lui-même, jamais un répertoire que Polype n'a pas créé — et `$home/polype` retiré en entier par `remove --global`. Ne pas exécuter `chmod +x … hooks/*` quand la pose ne livre pas de hooks (`bin/polype:150`, `:190`). — Test : `installer_global_remove_leaves_the_user_home_intact`.
6. [x] **Usage, aide et message de fin.** `usage()` (`:25-31`) liste les deux formes et `init` ; le message de fin de `install --global` dit où la charge utile a été posée et renvoie à `init`. — Test : `installer_usage_names_global_and_init`.
7. [x] **`tests/global-install.test.sh`.** En-tête `# s37 — …`. Helper `global_home()` : `scratch_repo` puis `export HOME="$SCRATCH/home" CLAUDE_CONFIG_DIR="$SCRATCH/home/.claude"`, les deux, pour qu'aucun test ne puisse écrire dans la vraie configuration.
8. [x] **`docs/installation.md`.** Retirer la phrase `L'installation globale dans` `~/.claude` `n'existe pas encore` (`:17`), ajouter une section « Installation globale » (les deux formes, ce que chaque mode pose, `CLAUDE_CONFIG_DIR`) et une section « Suivre `~/.claude/polype/` avec chezmoi » : ce qu'on y met (la charge utile, versionnée avec la méthode), ce qu'on n'y met pas (`AGENTS.local.md` et l'état d'un projet, les fichiers d'état `manifest`/`checksums`/`version` qui décrivent une machine, tout secret), et comment mettre à jour sur une autre machine. — Test : `docs_explain_the_chezmoi_path`.

## Run interdicts
- `method/`, `bin/polype-dev-install`, `docs/parite-killer-saas.md`, `docs/defauts.md`, `docs/stories.md` finissent avec un diff vide. La ligne H01 de la matrice appartient à s39.
- `tests/installer.test.sh` et `tests/install.test.sh` finissent avec un diff vide et `bash tests/run.sh` reste vert dans sa totalité.
- Ne pas corriger le *major* de `has_drifted` relevé par la revue s36 (`docs/reviews/s36-installer.md:58`) : hors critères, et le volet global n'en hérite pas.
- Aucun test n'écrit hors de son `mktemp -d` : chaque test du nouveau fichier redéfinit `HOME` **et** `CLAUDE_CONFIG_DIR`.
- Pas de nouvelle dépendance : bash, coreutils, git, comme le reste du dépôt.

## The pivot
**La charge utile globale emporte `bin/` et `method/` ensemble sous `~/.claude/polype/`, donc `$(dirname "$0")/../method` continue de résoudre et aucun chemin n'est écrit en dur.** Trois façons dont ce pari peut être faux :
- *L'exécutable n'est pas sur le `PATH`.* `~/.claude/polype/bin/polype` ne s'appelle pas tout court. À comparer : la section chezmoi doit donner le lien symbolique ou l'alias, sinon l'installation globale n'est utilisable que par chemin complet.
- *Le clone du dépôt et la copie globale divergent.* Deux `bin/polype` coexistent. À comparer : `check --global` affiche la version posée et signale la dérive — vérifier qu'il le fait bien sur la charge utile, pas seulement sur les commandes.
- *chezmoi suit trop de choses.* Si les fichiers d'état partent dans les dotfiles, une machine hérite du manifeste d'une autre. À comparer : la section chezmoi doit nommer `manifest`, `checksums` et `version` comme locaux à une machine.

## Files touched
- `bin/polype` (remanié)
- `tests/global-install.test.sh` (nouveau)
- `docs/installation.md`
- preuves : `docs/research/s37-global-install.md`, `docs/plans/s37-global-install.md`, `docs/verif/s37-global-install.md`

## Test strategy
Sept tests bash dans `tests/global-install.test.sh`, sous le budget de 25, au seul niveau qui existe ici : exécuter l'installeur sur un `$HOME` jetable et regarder le système de fichiers. Chaque test part de `global_home()`.

| Test | Ce qui casse s'il est faux |
| --- | --- |
| `installer_global_puts_commands_in_the_user_home` | commandes, subagents et skills sous `$CLAUDE_CONFIG_DIR/`, charge utile (`bin/polype`, `method/AGENTS.md`) sous `$CLAUDE_CONFIG_DIR/polype/`, et `$CLAUDE_CONFIG_DIR/polype/version` posé |
| `installer_init_activates_a_project_after_a_global_install` | après `install --global` puis `init $P` : `.polype/templates/plan.md` et `.polype/hooks/po-gate.sh` exécutable présents, `AGENTS.md` assemblé, `@AGENTS.md` dans `CLAUDE.md`, et **aucun** `.claude/commands/` dans le projet |
| `installer_global_update_is_idempotent` | deux `install --global` de suite : manifeste identique au fichier près, aucune ligne en double, même nombre de fichiers posés |
| `installer_global_remove_leaves_the_user_home_intact` | un fichier que l'utilisateur a mis dans `$CLAUDE_CONFIG_DIR/commands/` survit à `remove --global`, `$CLAUDE_CONFIG_DIR` existe encore, `polype/` a disparu |
| `installer_global_rejects_a_project_and_global_together` | `install --global $P` sort en 2 ; `install` sans cible sort en 2 |
| `installer_usage_names_global_and_init` | `polype help` nomme `--global` et `init` |
| `docs_explain_the_chezmoi_path` | `docs/installation.md` parle de chezmoi, nomme `~/.claude/polype/`, et dit que `manifest`, `checksums` et `version` ne se synchronisent pas |

Contrôles visuels : aucun (pas d'écran). Contrôle de non-régression : `bash tests/run.sh` en entier, les 30 fichiers de tests.

## Done when
Un commit squash sur `m5-distribution` disant ce qui change, pourquoi et comment le vérifier ; `bash tests/run.sh` vert en entier ; une revue sans constat critique ouvert ; pas de déploiement pour ce dépôt.
