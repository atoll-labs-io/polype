---
adr: 0137
title: Un passage réel confine ses commandes par le bac à sable de Claude Code
status: accepted
date: 2026-11-23
scope: story s208-real-run-in-the-sandbox
supersedes: [ADR-0136]
superseded-by: []
---

# ADR-0137 — Un passage réel confine ses commandes par le bac à sable de Claude Code

## Context and Problem Statement
Les deux premiers passages réels (2026-11-23) ont mesuré la syntaxe des permissions plutôt que la méthode : une commande composée que la Law 4 impose était refusée tant qu'un de ses morceaux manquait à la liste d'[ADR-0136](ADR-0136-cd-et-les-commandes-de-lecture-entrent-dans-la-liste-de-permissions-d-un-passage-reel.md), et chaque commande ordinaire qu'un agent lance demanderait sa propre entrée. Claude Code sait isoler lui-même chaque commande Bash (bubblewrap et socat sous Linux) ; un essai du chef de projet, le 2026-11-23 sur Claude Code 2.1.330, y a fait passer la session principale et un sous-agent, et a vu refusées une écriture hors du projet et une sortie réseau.

## Considered Options
- **A. Le bac à sable natif de Claude Code** : `sandbox.enabled`, `autoAllowBashIfSandboxed` (une commande qui tourne dans le bac à sable est approuvée d'office), `failIfUnavailable` (sans bac à sable, la session ne démarre pas) ; écriture limitée au dossier du passage, réseau fermé ; plus aucune liste de commandes Bash.
- **B. Continuer d'élargir la liste** d'ADR-0136, commande par commande, à chaque refus vu sur un passage.
- **C. `bypassPermissions` ou `--dangerously-skip-permissions`** dans le bac à sable : plus aucune demande, tout reposant sur l'isolement.

## Decision Outcome
Option choisie : **A**, par le porteur le 2026-11-23, notée dans la story s208-real-run-in-the-sandbox. Elle remplace ADR-0136 en entier : la liste de commandes Bash disparaît de la configuration d'un passage. Ce qui reste d'ADR-0134 et d'ADR-0135 tient : un passage est lancé et regardé par une personne, toute demande de permission est refusée (`--permission-prompts none`), les outils web, `curl` et `claude` restent refusés par `deny`, les outils de fichiers restent limités au dossier du passage, l'outil Agent reste permis. Sous Linux, `po-eval real` refuse de lancer quoi que ce soit sans `bwrap` et `socat` sur le `PATH` du passage, et les nomme.

Options écartées :
- **B** : chaque passage paierait pour découvrir la commande suivante qui manque ; c'est la syntaxe des permissions qu'on mesurerait, pas la méthode.
- **C** : sans demande, une commande qui sort du bac à sable (une demande d'exécution hors bac) passerait sans que personne ne la refuse ; avec A, elle reste une demande, donc refusée.

Ce que cette décision n'ouvre pas : un passage non surveillé ou planifié. ADR-0134 le réserve à une nouvelle ADR, et le bac à sable de Claude Code n'isole que les commandes Bash, pas le processus de Claude Code lui-même.

### Consequences
- Good, because un agent qui suit la méthode lance ses commandes sans qu'aucune liste ne les prévoie, et ce qu'il écrit hors du dossier du passage ou envoie sur le réseau est refusé par le système, non par un motif de commande.
- Bad, because un passage demande `bwrap` et `socat` sur la machine (Linux), et un refus n'est plus nommé par la commande refusée mais par l'écriture ou la connexion que le bac à sable a bloquée.
- Bad, because le bac à sable masque des chemins à la racine du projet (`.zshrc`, `.gitconfig`, `.mcp.json`, `.idea`…) que `git status` voit : le `HOME` du passage les fait ignorer de git, sans quoi chaque lane paraîtrait modifiée.
- Neutral: le bac à sable protège `.git/config` et `.git/hooks` en écriture ; `git worktree add -b` y signale qu'il n'écrit pas le suivi de branche et réussit quand même. Seul un passage réel montre ce que Claude Code 2.1.330 et suivants en font, et la syntaxe des clés `sandbox` dépend de Claude Code.
