---
adr: 0096
title: Le contrôle de forme refuse tout ce que /po-ship ne sait pas ouvrir
status: accepted
date: 2026-10-18
scope: story s144-shape-gate-matches-ship
supersedes: [ADR-0094]
superseded-by: []
---

# ADR-0096 — Le contrôle de forme refuse tout ce que /po-ship ne sait pas ouvrir

## Context and Problem Statement
ADR-0094 a fixé trois cas refusés par `po-gate findings-shape`, la sévérité se reconnaissant « en toute casse » et suivie de n'importe quel caractère hors mot. L'étape 3.2 de `/po-ship` est plus étroite : marqueur `- `, `* ` ou `<n>. `, sévérité en minuscules, nue ou en gras, puis `—`, `:` ou `-`. Entre les deux, des lignes comme `- major. a.sh:1 x`, `- MAJOR x`, `+ major — x` ou `1) major — x` passent le gate sans être déposées ni signalées : le dépôt silencieux de #112 revient (issue #126). Le porteur a décidé en cadrant M16 (2026-10-18) de resserrer le contrôle sur les seules formes que lit `/po-ship`. Par ailleurs, une sortie du gate autre que 0 et 1 n'avait pas de règle à l'enregistrement (issue #127).

## Considered Options
- **A. Le gate refuse tout ce que l'étape 3.2 ne sait pas ouvrir.** Un seul motif, celui de l'étape 3.2 : un item qui nomme une sévérité passe seulement sous cette forme ; un titre qui nomme une sévérité est refusé ; toute autre ligne de `## Findings`, hors ligne de suite indentée, dont le premier mot passé les caractères qui ne sont pas des lettres est une sévérité, en toute casse, est refusée. Retenue, par le porteur.
- **B. Garder « toute casse » et apprendre à `/po-ship` les autres formes.** Écartée : deux lectures de la même forme à tenir en accord, celle du gate et celle de l'étape 3.2, et chaque forme tolérée de plus élargit le `sed` du titre et le filet ; l'écart qui a produit #126 se rouvrirait à la prochaine forme.

## Decision Outcome
Option choisie : **A** (porteur, 2026-10-18), parce qu'une seule forme, celle que l'étape 3.2 ouvre, ne laisse aucune ligne entre ce que le gate accepte et ce que `/po-ship` dépose.

- Remplace ADR-0094 sur la seule règle des sévérités (« toute casse », trois cas refusés). Le reste d'ADR-0094 tient : contrôle à l'enregistrement, une seule relance du reviewer au même `Fix loop:`, rapport bloqué au second échec, permission Bash réduite pour `/po-review`, sortie 1 sans section `## Findings`.
- `po-gate findings-shape` sort 2 quand le contrôle ne peut pas tourner : id manquant, revue absente, aucun `Ship allowed:`, lecture en échec. Une sortie autre que 0 et 1 n'est pas une revue mal formée : le reviewer n'est pas relancé, et le contexte qui enregistre ajoute le rapport bloqué du second échec, dont le `Next action:` nomme `po-gate findings-shape`, dit que le contrôle n'a pas pu tourner et donne la sortie.

### Consequences
- Good, because aucune ligne qui nomme une sévérité ne peut plus passer le gate sans que l'étape 3.2 la dépose, et qu'un gate ancien ou cassé arrête la revue au lieu de relancer le reviewer pour rien.
- Bad, because des formes lisibles par un humain (`- Major — x`, `- major. x`) coûtent une relance du reviewer ; le gabarit `templates/review.md` montre déjà la seule forme acceptée.
- Neutral: le filet de l'étape 3.2 ne change pas ; les revues déjà enregistrées ne sont pas réécrites.
