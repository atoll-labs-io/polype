---
adr: 0097
title: Le contrôle strict est le défaut d'un projet
status: accepted
date: 2026-11-10
scope: story s147-strict-checks-by-default
supersedes: []
superseded-by: []
---

# ADR-0097 — Le contrôle strict est le défaut d'un projet

## Context and Problem Statement
Le compilateur au plus strict et un linter dont les avertissements sont des erreurs sont la boucle de rétroaction la plus courte qu'un agent puisse avoir (issue #156). Or `/po-architect` recopiait la commande `Typecheck` des réglages dans `docs/architecture.md` sans la juger (`method/commands/po-architect.md:57` à c5ad4ec), et aucun profil de `boilerplates/` ne disait ce qu'est le contrôle strict de sa base : un projet pouvait démarrer avec un contrôle de type lâche, ou sans contrôle du tout, sans que personne l'ait décidé.

## Considered Options
- **A. Strict par défaut, dérogation par une ADR de projet.** Chaque profil déclare dans `## Strictness` la commande stricte de sa base, le fichier qui l'active et si elle passe au commit profilé ; `/po-architect` retient ce contrôle par une ADR de projet, et seule cette ADR peut garder un contrôle non strict, en disant pourquoi. Retenue, par le porteur.
- **B. L'imposer sans exception.** Écartée : elle bloque un projet repris sur une base héritée, dont le code ne passe pas encore le contrôle strict et qu'aucune story ne peut réécrire d'un coup.
- **C. Le recommander seulement.** Écartée : de la prose qu'un agent peut ignorer ; rien ne force la décision ni ne la trace.
- **D. Un réglage `Lint` à part.** Écartée : un réglage de plus que chaque commande doit lire, alors que l'étape du contrôle de type, une fois après la dernière modification, est celle où un lint bloquant doit tourner.

## Decision Outcome
Option choisie : **A** (porteur, 2026-11-10), parce qu'elle donne au contrôle strict la place du défaut sans bloquer une base héritée : la seule dérogation est une ADR de projet, qui en écrit la raison (base héritée telle quelle, aucun outil strict pour ce langage).

- Le contrôle strict passe par la commande `Typecheck`, sans nouveau réglage. `/po-architect` ne modifie aucun réglage : quand le profil dit `Passes at the commit profiled: yes`, il donne la commande à recopier dans `Typecheck` et demande à la personne de le faire.
- Quand le profil dit `no` ou `not run`, ou qu'aucun profil ne le dit, la base n'est pas modifiée : `docs/architecture.md` nomme le passage au strict comme une story à écrire, et la commande stricte n'entre dans `Typecheck` qu'une fois cette story livrée.
- `bin/po-lint` refuse un profil sans la section `## Strictness` ou sans l'une de ses trois lignes ; il ne juge pas leurs valeurs.

### Consequences
- Good, because un agent reçoit une erreur précise du compilateur ou du linter dès qu'il se trompe, plutôt qu'à l'exécution, et que tout contrôle non strict est une décision écrite.
- Bad, because la plupart des profils disent `not run` (les chaînes d'outils manquaient à l'écriture) : `/po-architect` proposera le plus souvent une story de passage au strict plutôt qu'une commande à recopier tout de suite.
- Neutral: une commande stricte déclarée dans un profil n'est vraie qu'au commit profilé ; une mise à jour du profil la relit.
