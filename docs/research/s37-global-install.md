# Research — s37-global-install

[Story](../stories.md)

## Structuring facts
- `bin/polype:22` résout la méthode par `method="$(cd "$(dirname "$0")/../method" && pwd)"` : si l'installation globale copie `bin/` **et** `method/` sous `~/.claude/polype/`, alors `~/.claude/polype/bin/polype init <projet>` trouve sa charge utile sans variable ni chemin en dur.
- `bin/polype:27-42` (`parse_project`) exige un répertoire de projet et sort en 2 sans lui : `install --global` n'a pas de projet, donc l'analyse des arguments doit se dédoubler avant toute autre chose.
- `bin/polype:57-59` (`prune_empty_dirs`) supprime les répertoires vides de `$project/.claude` : appliqué tel quel à `~/.claude`, il effacerait des répertoires vides de l'utilisateur. La pose globale ne doit pas réutiliser cette fonction sans la borner.
- `bin/polype:47-56` (`shipped_pairs`) fige les cinq couples source→destination ; le global en prend trois (`commands`, `agents`, `skills`) et l'`init` de projet les deux autres (`templates`, `hooks`) — la fonction doit se paramétrer, pas se dupliquer.
- La ligne H01 de `docs/parite-killer-saas.md:103` est dans le `Owns` de **s39**, pas de s37 : malgré la convention « une story met à jour ses lignes de matrice », s37 n'y touche pas.

## Story
Installer Polype une fois dans `~/.claude`, l'activer projet par projet, synchroniser par chezmoi (ADR-0004).
1. `installer_global_puts_commands_in_the_user_home` — `install --global` pose commandes, subagents et skills dans `~/.claude/`, charge utile dans `~/.claude/polype/`, racine surchargeable par variable d'environnement pour les tests.
2. `installer_init_activates_a_project_after_a_global_install` — `init <projet>` pose templates, gate, règles, `CLAUDE.md`, sans recopier les commandes déjà globales.
3. `installer_global_update_is_idempotent` — deux poses globales successives laissent le même état, sans doublon.
4. `docs_explain_the_chezmoi_path` — `docs/installation.md` explique le suivi de `~/.claude/polype/` par chezmoi et ce qu'il ne faut pas y mettre.

## Current code
- `bin/polype` (275 l., livré par s36) : quatre sous-commandes `install|update|check|remove`, toutes sur un répertoire de projet. Pose sous `.claude/` (commands, agents, skills) et `.polype/` (templates, hooks), puis assemble `AGENTS.md`, ajoute `@AGENTS.md` à `CLAUDE.md`, complète `.gitignore`, et avec `--hooks` pointe `core.hooksPath`. Trois fichiers d'état non listés au manifeste : `.polype/manifest`, `.polype/checksums`, `.polype/version`.
- `bin/polype-dev-install:3` : `exec "$(dirname "$0")/polype" install "$@"` — alias, hors `Owns`, inchangé.
- `docs/installation.md:17` affirme « L'installation globale dans `~/.claude` n'existe pas encore » : cette phrase est ce que la story rend faux.
- `tests/installer.test.sh` (s36, 10 tests) et `tests/install.test.sh` (s09) couvrent la pose projet. Hors `Owns` : doivent rester verts et intacts.

## Attachment points
| Ce qui change | Où |
| --- | --- |
| Analyse des arguments (`--global`, `init`) | `bin/polype:27-42`, `main()` `:262-274` |
| Couples source→destination paramétrés | `shipped_pairs()` `:47-56` |
| Racine de pose (projet ou `~/.claude`) | `parse_project`, `copy_into_project` `:61-65` |
| Fichiers d'état globaux | `manifest`/`checksums`/`version_file`, `:39-41` |
| Usage et documentation | `usage()` `:25-31`, `docs/installation.md` |

## Verified interfaces
- `sum_of()` `:44` = `cksum < "$1"` ; `load_checksums()` `:117-123` peuple `RECORDED` ; `has_drifted()` `:125-129`. Mécanique réutilisable telle quelle pour un manifeste global.
- `assemble_agents_md()` `:68-83` lit `$method/AGENTS.md` + `$project/AGENTS.local.md` : n'a de sens que pour un projet, donc appartient à `init`, pas au global.
- `ignore_worktrees_and_env()` `:85-96` et `set_hooks_path()` `:98-108` : idem, côté projet seulement.
- `tests/lib.sh:52-58` `scratch_repo()` crée un dépôt jetable dans `mktemp -d` avec `trap … EXIT` ; `tests/installer.test.sh:12-18` `copy_of_the_method()` copie `bin/` et `method/` pour simuler une version plus récente. Les deux sont les outils du test de s37.
- `tests/lib.sh:13` exporte déjà `GIT_CONFIG_GLOBAL=/dev/null` : la suite sait neutraliser l'environnement du développeur.

## Traps
- **`Owns` borne la lane** : `bin/polype`, `tests/global-install.test.sh`, `docs/installation.md`. Ni `method/`, ni `docs/parite-killer-saas.md` (s39), ni `docs/defauts.md`, ni les deux fichiers de tests existants.
- **Aucun test ne doit jamais écrire dans le vrai `~/.claude`** : la variable de surcharge doit être lue à chaque exécution, et le test échouer bruyamment plutôt que retomber sur `$HOME` si elle manque.
- `test_install_copies_skill_subdirectories` (`tests/install.test.sh:17-25`) exécute l'installeur depuis une copie temporaire : la résolution par `$(dirname "$0")/../method` est déjà sous test, ne pas la casser.
- **Major ouvert de la revue s36** (`docs/reviews/s36-installer.md:58`) : `has_drifted` traite un fichier sans empreinte enregistrée comme intact. Il ne concerne que la transition unique depuis l'ancien installeur ; une pose globale écrit toujours ses propres empreintes, donc le volet global n'en hérite pas. Connu, hors périmètre de s37 — ne pas le relever comme neuf.
- `set -euo pipefail` (`:15`) : tout `cd` ou test raté tue le script ; les nouveaux chemins doivent être créés avant d'être résolus par `cd … && pwd`.
- `chmod +x "$project"/.polype/hooks/*` (`:150`) suppose ce répertoire non vide : une pose globale qui ne livre pas de hooks ne doit pas exécuter cette ligne.
- Pas de remote sur ce dépôt ; `Test: bash tests/run.sh`, focalisé par `bash tests/run.sh global-install.test.sh`.

## Open questions
- Nom de la variable d'environnement : `CLAUDE_CONFIG_DIR` (convention de Claude Code, donc un utilisateur ayant déplacé sa configuration est servi gratuitement) ou un `POLYPE_*` spécifique (indépendant, mais ignore une configuration déplacée) ? Le plan tranche.
- `init` doit-il exiger une installation globale préalable, ou poser le volet projet quel que soit l'état de `~/.claude` ? Le critère dit « après une installation globale » sans l'exiger.
- `update --global` / `check --global` / `remove --global` : les quatre sous-commandes se déclinent-elles au global dans cette story, ou seules `install --global` et `init` ? Le critère d'idempotence ne parle que de deux poses successives.

## Complexity
Story : 3 → 3 après lecture. Le mécanisme (manifeste, empreintes, copie) existe et se paramètre ; le travail est une généralisation de la racine de pose plus un fichier de tests, sans invention.

## Split
Non requis.
