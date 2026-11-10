---
adr: 0098
title: Le planner écrit l'oracle d'acceptation
status: accepted
date: 2026-11-10
scope: story s149-planner-writes-the-oracle
supersedes: []
superseded-by: []
---

# ADR-0098 — Le planner écrit l'oracle d'acceptation

## Context and Problem Statement
Les tests d'une story étaient écrits par l'implémenteur, l'auteur même du code (`method/agents/planner.md:55` à c4a8483 interdisait au planner tout fichier de test) : un critère mal compris l'était deux fois, dans le code et dans ses tests, et les deux passaient ensemble (issue #152). L'étape *Bite* de la revue (ADR-0012) retire une garde pour voir si un test tombe ; elle trouve une règle mal testée, pas un critère que l'auteur a lu de travers.

## Considered Options
- **A. Le planner écrit l'oracle d'acceptation dans des fichiers à lui.** Un test par critère vérifiable, écrit depuis les critères avant tout code, à travers l'interface que fixent les tâches du plan ; le plan liste chaque fichier avec sa somme `cksum` sous `## Acceptance tests` ; l'implémenteur ne le change qu'avec une raison consignée sous `## Oracle changes` du relevé, que le relecteur juge. Retenue, par le porteur, 2026-11-10.
- **B. Un agent oracle dédié.** Écartée : une étape et un contexte de plus à chaque story.
- **C. Le relecteur en boîte noire.** Écartée : un trou découvert seulement en revue, au prix d'une boucle de correction.
- **D. Ne rien changer.** Écartée : l'étape *Bite* trouve une règle mal testée, pas un critère mal compris par celui qui a écrit le code et ses tests.

## Decision Outcome
Option choisie : **A** (porteur, 2026-11-10), parce que le planner lit déjà les critères et l'interface que fixent ses tâches, sans contexte de plus : l'oracle vient d'un autre contexte que le code, ce qui suffit à séparer leurs angles morts.

- Elle complète l'ADR-0012 sans la remplacer : l'étape *Bite* reste, et commence par les règles que tient l'oracle (s150).
- Les fichiers d'oracle sont dans l'`Owns` de la story ; un oracle qu'il faudrait écrire hors de l'`Owns` est signalé par le planner comme un trou de la story au lieu d'être écrit. Ils comptent comme travail non commité légitime jusqu'au commit de l'implémenteur (Law 4).
- Le contrôle des sommes (s150) protège de l'erreur, pas d'un implémenteur qui réécrirait aussi la somme, puisque celle-ci vit dans le plan qu'il commite : comme l'ADR-0052 le dit de `po-bounds`, c'est un garde-fou, pas une frontière de sécurité. Le relecteur juge chaque ligne de `## Oracle changes`.

### Consequences
- Good, because le code est jugé par des tests dont son auteur ne partage pas les angles morts, sans étape de plus.
- Bad, because le planner écrit des tests contre une interface qui n'existe pas encore : un oracle mal visé coûte à l'implémenteur un arrêt ou une ligne de `## Oracle changes`.
- Neutral: une story purement visuelle ou d'exploration écrit `—` avec sa raison sous `## Acceptance tests` et n'a pas d'oracle.
