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
| Revue | `/po-review` | une relecture en contexte frais, avec un verdict |
| Ship | `/po-ship` | un squash sur la branche cible |

Trois gates mécaniques bornent la traversée : pas de code sans plan marqué validé, pas de revue qui s'appuie sur un relevé de vérification périmé, pas de ship sans verdict explicite. Un hook de pre-commit refuse un commit de code sur une branche de story dont le plan n'est pas validé. Seul un défaut critique bloque le ship ; un majeur est tracé et repris plus tard.

`/po-flow` fait recherche et plan en une passe pour une petite story, `/po-orchestrator` enchaîne le cycle complet, `/po-status` dit où en est chaque story.

## La flotte

`/po-drive` ouvre une lane par story prête et les fait avancer en même temps, chacune dans son worktree. Deux limites gardent le parallélisme honnête : les ships restent sériels, dans l'ordre où les revues sont passées, et la ligne `Owns` d'une story borne les chemins que sa lane peut toucher — deux stories qui partagent un chemin ne tournent jamais ensemble. `/po-drive status` donne le même état sans rien lancer.

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
