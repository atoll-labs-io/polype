---
adr: 0013
title: Squash de chaque story dans la branche d'intégration, PR humaine par milestone
status: superseded
date: 2026-09-18
deciders: [lecrabe]
tags: [adr, polype, git]
supersedes: []
superseded-by: [ADR-0015]
---

# ADR-0013 — Squash de chaque story dans la branche d'intégration, PR humaine par milestone

## Context and Problem Statement
Killer SaaS squash chaque story dans la branche cible ; `/drive` merge chaque packet en `--no-ff` dans une branche d'intégration et ouvre une PR par milestone (tension T2).

## Considered Options
- **Squash direct dans la branche par défaut** — une PR ou un merge local par story.
- **Merge `--no-ff` dans la branche d'intégration** — l'historique de chaque story est conservé.
- **Squash dans la branche d'intégration, PR humaine par milestone** — une story = un commit sur la branche d'intégration, relue en bloc à la fin du milestone.

## Decision Outcome
Chosen option: **Squash dans la branche d'intégration, PR humaine par milestone**, parce que l'historique reste lisible (un commit par story) et que la relecture humaine se fait au rythme des milestones, pas de chaque story.

### Consequences
- Good, because les stories suivantes partent d'une branche qui contient déjà le travail fusionné de leurs dépendances.
- Bad, because une story fautive se découvre parfois seulement à la relecture du milestone.
- Neutral: le réglage `Merge mode` garde la PR par story pour les projets qui la préfèrent. En M1, sans flotte, la branche d'intégration est simplement la branche cible du réglage.
