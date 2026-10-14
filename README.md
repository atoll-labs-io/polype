# Polype

> Le polype, minuscule animal qui bâtit le récif. Une méthode de dev agentique qui emmène un SaaS de l'intention à la production, portée par des agents Claude Code encadrés par des gates mécaniques.

Polype n'est pas un framework ni un générateur : c'est un jeu de règles, de commandes et de subagents posés dans un dépôt. Les règles tiennent dans `AGENTS.md`, les réglages du projet dans `AGENTS.local.md`, et toute la trace du travail — recherche, plan, vérification, revue — reste en markdown dans `docs/`, donc en git, à côté du code qu'elle justifie.

Quatre principes portent le reste : rien n'atteint le code hors d'une story, celui qui écrit le code ne le juge pas, chaque gate est fermé tant qu'un fichier ne l'ouvre pas, et chaque story vit dans son propre worktree.

**Statut** : le cycle, le cadrage et la flotte tournent — Polype se construit avec Polype. Venture outillage sous Atoll.

## Trois points d'entrée

| Objectif | Point de départ | Cadrage |
|---|---|---|
| **Remplacer** un SaaS existant | Un SaaS que je paie et veux internaliser | Analyse de la cible, boucle cœur (20 %), cimetière des features lourdes |
| **Adapter** un SaaS existant | Un concurrent à reprendre avec un angle propre | Idem + l'angle au-delà de la parité, devient des stories dédiées |
| **Partir de zéro** | Une idée sans cible à copier | Interrogation sceptique, carte des manques, pre-mortem, puis brief |

Les trois convergent vers le même tronc, cadré une seule fois : `/po-setup` écrit les réglages, `/po-prd` ou `/po-brief` le périmètre approuvé, `/po-stories` le découpe et `/po-stories-review` le relit, puis `/po-architect` et `/po-design-system` fixent l'architecture, ses ADR et le socle visuel.

## Le cycle d'une story

Une story traverse ces étapes, aucune sautée, aucune inversée :

| Étape | Commande | Produit |
|---|---|---|
| Recherche | `/po-research` | le worktree de la story et ce que le code dit vraiment |
| Design (story avec écran) | `/po-design` | l'écran dérivé du design system |
| Plan | `/po-plan` | des tâches testables, approuvées avant tout code |
| Exécution | `/po-execute` | le code, ses tests, un relevé de vérification, un commit |
| QA (story que `QA stage` envoie en QA) | `/po-qa` | la surface vérifiée avec son pilote, preuves dans `docs/qa/<id>/` |
| Revue | `/po-review` | une relecture en contexte frais, avec un verdict |
| Ship | `/po-ship` | un commit `<id>: <titre>` sur la branche cible, par une pull request |

Trois gates mécaniques bornent la traversée : pas de code sans plan marqué validé, pas de revue qui s'appuie sur un relevé de vérification périmé, pas de ship sans verdict explicite. Un hook de pre-commit refuse, sur toutes les branches, un commit qui ajoute un secret — fichier d'environnement, clé privée ou jeton connu — et, sur une branche de story, un commit de code dont le plan n'est pas validé. Seul un défaut critique bloque le ship ; un majeur est tracé et repris plus tard.

`/po-flow` fait recherche et plan en une passe pour une petite story, `/po-orchestrator` enchaîne le cycle complet, `/po-status` dit où en est chaque story. `/po-orchestrator` et la flotte lancent eux-mêmes la QA d'une story que `QA stage` y envoie ; une revue bloquée par la QA repart vers `/po-qa` sans consommer de fix run.

## La flotte

`/po-drive` ouvre une lane par story prête et les fait avancer en même temps, chacune dans son worktree. Deux limites gardent le parallélisme honnête : les ships restent sériels, dans l'ordre où les revues sont passées, et la ligne `Owns` d'une story borne les chemins que sa lane peut toucher — deux stories qui partagent un chemin ne tournent jamais ensemble. `/po-drive status` donne le même état sans rien lancer.

## Prérequis

- **Claude Code**, qui fait tourner les commandes, les subagents et les hooks.
- **git** : chaque story vit dans son worktree, et toute la trace du travail est en git.
- **bash 4.2 ou plus récent** : l'installeur et le hook de session s'arrêtent en le disant sur une
  version plus ancienne. Sur macOS, `/bin/bash` est en 3.2 : `brew install bash`, ouvrir un nouveau
  shell, puis vérifier avec `bash --version`. Rien d'autre que bash n'est promis sur macOS : les
  scripts supposent les outils GNU, et `find`, `sed` ou `readlink` BSD peuvent s'y comporter autrement.
- **jq** : il fusionne le hook `SessionStart` dans `.claude/settings.json`, et sans lui les hooks des
  bornes d'`implementer`, de `qa` et de `reviewer` refusent tout appel, donc aucune story n'avance.
- **gh**, connecté (`gh auth login`), pour un projet dont la forge est GitHub : `/po-ship` y livre
  chaque story par une pull request.

## Démarrage rapide

D'abord, récupérer Polype :

```sh
git clone https://github.com/atoll-labs-io/polype.git ~/src/polype
```

Ton `~/.claude/` porte déjà tes propres agents ou skills ? Arrête-toi ici et essaie d'abord sans rien
poser de global : fais un clone jetable de ton projet, `git clone ~/mon-projet ~/essai`, puis lance
`~/src/polype/bin/polype install ~/essai` : tout est posé dans ce seul dépôt, rien dans
`~/.claude/`, et `~/src/polype/bin/polype remove ~/essai` le reprend. Une collision avec un de tes
fichiers arrête la pose avant toute écriture (voir
[ce que Polype fait de ta configuration](#ce-que-polype-fait-de-ta-configuration)).

Puis installer Polype pour tous ses projets, le mettre sur le `PATH` et activer un dépôt :

```sh
~/src/polype/bin/polype install --global
mkdir -p ~/.local/bin
ln -sf "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/bin/polype" ~/.local/bin/polype
export PATH="$HOME/.local/bin:$PATH"   # à mettre aussi dans le profil du shell
cd ~/mon-projet                        # ton dépôt git
polype init .
```

Puis, dans une session Claude Code ouverte dans ce dépôt, le cadrage une fois, et la flotte :

```text
/po-setup
/po-brief            (ou /po-prd pour remplacer ou adapter un SaaS existant)
/po-stories
/po-stories-review
/po-architect
/po-design-system
/po-drive
```

`/po-setup` relance l'installeur une fois les réglages écrits, si bien que l'`AGENTS.md` du projet
porte ces réglages.

### Mettre à jour

```sh
git -C ~/src/polype pull
~/src/polype/bin/polype update --global
cd ~/mon-projet
polype init .
```

Un projet activé par `init` se rafraîchit par `polype init .`, jamais par `polype update .` : sur un
tel projet, `update` y poserait aussi les commandes, les subagents et les skills.

## Ce que Polype fait de ta configuration

- **Un fichier du même nom qu'un des siens** — un agent `reviewer.md`, une skill, dans `~/.claude/`
  ou dans le `.claude/` d'un projet — arrête la pose avant toute écriture, et Polype le nomme.
  Relancée avec `--set-aside`, la pose déplace chacun en `<chemin>.before-polype` ; `polype remove`
  le remet à sa place.
- **Un `AGENTS.md` écrit à la main** va à la fin d'`AGENTS.local.md`, sous
  `## Notes moved from AGENTS.md`. Tant que `/po-setup` n'a pas créé `AGENTS.local.md`, il attend
  en `AGENTS.md.before-polype`.
- **Un `CLAUDE.md` ou un `CLAUDE.local.md`** suit le réglage `Project CLAUDE file` : `absorbed`
  verse leur contenu dans `AGENTS.local.md` puis les supprime ; `kept` les garde et met
  `@AGENTS.md` en tête du `CLAUDE.md` ; sans la ligne, Polype n'y touche pas et le dit.
- **Le poids** : les règles de Polype font environ 20 Ko, et elles sont chargées à chaque session,
  suivies des réglages du projet.
- **Pour essayer sans risque**, avant tout `--global` : `~/src/polype/bin/polype install <clone>`
  sur un clone jetable pose tout dans ce seul dépôt, et `~/src/polype/bin/polype remove <clone>` le
  reprend (voir le démarrage rapide).

## Installation

`bin/polype` pose la méthode, la rafraîchit, l'ausculte et la retire, sans jamais toucher aux réglages ni aux documents d'un projet.

```
polype install --global      commandes, subagents et skills dans ~/.claude, pour tous les projets
polype init <projet>         active un dépôt : templates, gate, AGENTS.md assemblé
polype install <projet>      tout dans un seul dépôt, sans rien de global
polype check                 la version posée et les fichiers qui ont dérivé
```

Le détail — la charge utile sous `~/.claude/polype/`, le suivi par chezmoi, la mise à jour par manifeste qui ne laisse pas de fantômes et ne réécrit pas ce qu'on a modifié à la main — est dans [docs/installation.md](docs/installation.md).

Pour un projet qui tournait sous `/spec` et `/drive`, [docs/migration.md](docs/migration.md) dit ce que devient chaque notion et comment reprendre un projet en vol.

## Dans le dépôt

- `method/` — la source : les règles, les commandes `po-*`, les subagents, les skills, les templates et les hooks.
- `bin/polype` — l'installeur ; `bin/polype-dev-install` en est un alias pour les scripts existants.
- `docs/` — la conception ([docs/conception.md](docs/conception.md)), les décisions dans `docs/decisions/`, la matrice de parité et les jalons.
- `tests/` — la suite bash qui vérifie que la méthode dit bien ce qu'elle doit dire (`bash tests/run.sh`).

## Inspiration

Méthode [Killer SaaS](https://github.com/MikeCodeur/killer-saas) de Mike Codeur et boilerplate [ShipSaaS](https://ship-saas.now). Aucun contenu n'en est copié : voir [docs/references/killer-saas.md](docs/references/killer-saas.md).
