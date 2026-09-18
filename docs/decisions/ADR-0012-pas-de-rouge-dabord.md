---
adr: 0012
title: Pas de rouge-d'abord à l'implémentation, preuve de morsure en revue
status: accepted
date: 2026-09-18
deciders: [lecrabe]
tags: [adr, polype, tests]
supersedes: []
superseded-by: []
---

# ADR-0012 — Pas de rouge-d'abord à l'implémentation, preuve de morsure en revue

## Context and Problem Statement
`/drive` demandait d'écrire les tests d'acceptation d'abord et de les voir échouer. Killer SaaS l'interdit pendant l'implémentation et réserve la neutralisation des invariants à la revue, sur la foi de mesures en usage réel (tension T1 de la matrice de parité).

## Considered Options
- **Rouge-d'abord à l'implémentation** — l'auteur voit chaque test échouer avant de coder.
- **Rien à l'implémentation, preuve de morsure en revue** — l'auteur écrit code et tests en blocs ; le relecteur, en contexte frais, neutralise l'invariant et compte les tests rouges.
- **Les deux** — double coût.

## Decision Outcome
Chosen option: **Rien à l'implémentation, preuve de morsure en revue**, parce que l'auteur qui vient d'écrire un test sait déjà qu'il passe ; la même technique, appliquée par un autre contexte sur le filet d'un autre, est celle qui trouve les invariants non testés.

### Consequences
- Good, because chaque run de suite coûteux est fait une fois, là où il trouve quelque chose.
- Bad, because un invariant non testé n'est découvert qu'en revue, ce qui peut coûter une boucle de correction.
- Neutral: remplace la règle correspondante de `/drive` lors de la migration.
