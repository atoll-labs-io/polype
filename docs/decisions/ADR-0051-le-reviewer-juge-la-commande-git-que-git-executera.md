---
adr: 0051
title: Le reviewer juge la commande git que git exécutera — -C enchaînés, core.worktree refusé, chemins des sondes sous le répertoire temporaire
status: accepted
date: 2026-10-08
tags: [adr, polype, review, hooks, bounds]
scope: story s74-reviewer-bounds-bypasses
supersedes: [ADR-0047]
superseded-by: []
---

# ADR-0051 — Le reviewer juge la commande git que git exécutera

## Context and Problem Statement
La revue de s70 (`docs/reviews/s70-reviewer-bounds.md`, M1 à M3) a écrit dans le dépôt principal depuis une sonde que le mode `reviewer` d'ADR-0047 laissait passer. `po-bounds` ne gardait que le dernier `-C`. Il sautait `-c` sans le lire. Dans un dépôt jetable, il acceptait tout verbe sans regarder ses chemins. En relisant le code, deux détours de même nature sont apparus. Le lexer efface une substitution du mot qui la porte : `git -C "$(echo <checkout>)" commit` est jugé dans le répertoire courant. `--attr-source <arbre>` et `--config-env <clé>=<var>` prennent un argument séparé : `po-bounds` lit cet argument comme le verbe, et `git --attr-source HEAD push` passe depuis une sonde. Cette ADR remplace ADR-0047 **en partie**. Les deux zones, la preuve de morsure et les refus « partout » d'ADR-0047 restent. Cette ADR précise comment le répertoire et le verbe sont lus, ajoute des refus, et donne une règle de chemins au dépôt jetable.

## Considered Options
Pour le répertoire d'une commande git :
- **Garder le dernier `-C`** (état actuel) — `git -C <checkout> -C . commit` est jugé dans `.`, alors que git l'exécute dans le checkout.
- **Refuser un second `-C` en mode `reviewer`** — sûr, mais l'implementer garde le même trou.
- **Enchaîner les `-C` comme git** — un `-C` relatif part du précédent, un `-C` absolu repart de zéro. Un mot dont la valeur est inconnue (substitution, `$`, `~` en tête) rend le répertoire inconnu.

Pour `core.worktree` :
- **Refuser `-c` en entier** — bloque `-c user.name=x`, dont les sondes ont besoin.
- **Refuser la clé `core.worktree`** donnée par `-c` ou `--config-env`, quelle que soit la casse, et les variables `GIT_CONFIG_PARAMETERS=` et `GIT_CONFIG_COUNT=`, qui portent des `-c` par l'environnement.

Pour les chemins d'un dépôt jetable :
- **Une table des verbes qui prennent une destination** (`init`, `clone`, `worktree add`…), avec leurs options à argument — exacte pour ce qu'elle liste, trouée pour `archive -o`, `bundle create`, `config core.worktree`, et à tenir à jour.
- **Tout mot d'un appel git du dépôt jetable, après le verbe, se résout sous le répertoire temporaire** — sans table. Une source lue hors de la zone est refusée aussi ; `file://<chemin>` reste permis, parce que git lit cette forme comme un chemin relatif quand elle est une destination.

## Decision Outcome
Chosen option: **enchaîner les `-C` comme git**, **refuser la clé `core.worktree`**, et **résoudre sous le répertoire temporaire tout mot d'un appel git du dépôt jetable**. Les trois échouent fermé sans liste de verbes à entretenir.

Ce qui change par rapport à ADR-0047 :
- **Répertoire** (tous les modes) : le répertoire d'un appel git part du répertoire courant, suivi à travers les `cd` de la commande. Chaque `-C` s'y enchaîne : un `-C` relatif s'ajoute au répertoire précédent, un `-C` absolu le remplace. Un mot qui portait une substitution, qui contient `$` ou qui commence par `~` rend le répertoire inconnu, qu'il soit la cible d'un `cd` ou la valeur d'un `-C`. `cd` sans argument et `cd -` le rendent inconnu aussi. Un `-C` absolu qui suit redonne un répertoire connu, comme dans git. Un appel git dont le répertoire est inconnu est jugé comme un appel hors zone : refusé en mode `reviewer`, refusé en mode `implementer` pour les verbes qui exigent un worktree `story/*`.
- **Verbe** : les options globales de git qui prennent un argument séparé sont `-C`, `-c`, `--git-dir`, `--work-tree`, `--namespace`, `--config-env` et `--attr-source`. Leur argument n'est jamais pris pour le verbe.
- **Partout, en mode `reviewer`**, s'ajoutent aux refus d'ADR-0047 :
  - un `-c` dont la clé, avant le premier `=` et sans tenir compte de la casse, est `core.worktree` ;
  - la même clé donnée par `--config-env` ;
  - les mots `GIT_CONFIG_PARAMETERS=` et `GIT_CONFIG_COUNT=`.
- **Dépôt jetable** : la règle d'ADR-0047, « une écriture doit aussi satisfaire cette condition », s'écrit ainsi. Chaque mot qui suit le verbe est vérifié, ainsi que la valeur d'une option `--nom=valeur` et ce qui suit les deux premiers caractères d'une option courte collée (`-o<chemin>`). Joint au répertoire de l'appel puis résolu physiquement, ce mot doit rester sous le répertoire temporaire. Un mot de valeur inconnue (substitution, `$`, `~` en tête) est refusé.

### Consequences
- Good, because `git -C <checkout> -C . commit`, `git -C "$(…)" commit`, `git --attr-source HEAD push`, `-c core.worktree=…`, `git init <checkout>/x`, `git clone <checkout> <checkout>/sub`, `git worktree add <checkout>/x` et `git config core.worktree <checkout>` sont refusés depuis une sonde.
- Good, because le trou accepté par ADR-0047, un `git config core.worktree` qui pointe un dépôt jetable vers le vrai arbre, est fermé quand le chemin est écrit dans la commande.
- Bad, because une sonde ne lit plus par git un chemin absolu hors de la zone : `git clone <checkout> <tmp>/c` et `git fetch <checkout>` sont refusés. `file://<checkout>` est la forme permise.
- Bad, because un mot qui commence par `/` hors de la zone, qui contient `$`, ou qui remonte par un segment `..` hors de la zone, est refusé dans un dépôt jetable même quand il n'est pas un chemin : `-m '/x'`, `-m 'coûte $5'`, `--format='$x'`.
- Bad, because restent des trous, permis sans être lus :
  - la portée d'un `cd` : un `cd` lancé dans un sous-shell, une substitution, une tâche de fond (`&`) ou un pipeline, ainsi que `pushd` et `popd`, sont lus comme s'ils changeaient le répertoire de la suite de la commande. Les distinguer demande au lexer de dire dans quel contexte tourne chaque commande ; c'est l'objet d'une story à venir ;
  - un alias git ou un hook d'un dépôt jetable, qui lancent un code que le hook ne lit pas, comme un script (ADR-0047, ADR-0050) ;
  - `GIT_CONFIG_GLOBAL` qui pointe un fichier de configuration.
- Neutral: sous git 2.56.0, un `core.worktree` venu de `-c`, de `--config-env` ou de `GIT_CONFIG_*` ne déplace pas `checkout` ni `reset` vers un autre arbre (essai en bac à sable lors de la recherche de s74). Le refus est une défense pour les autres versions de git, pas la fermeture d'une écriture reproduite ici.
- Neutral: ADR-0047 garde `status: accepted` et nomme cette ADR dans `superseded-by`, son corps inchangé.
