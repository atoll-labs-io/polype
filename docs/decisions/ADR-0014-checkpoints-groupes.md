---
adr: 0014
title: Checkpoints humains groupés par vague, ship au niveau du milestone
status: accepted
date: 2026-09-18
deciders: [lecrabe]
tags: [adr, polype, autonomie]
supersedes: []
superseded-by: []
---

# ADR-0014 — Checkpoints humains groupés par vague, ship au niveau du milestone

## Context and Problem Statement
Killer SaaS pose deux checkpoints humains par story (plan, ship) ; `/drive` accorde l'autonomie une fois et ne s'arrête qu'entre milestones (tension T4). Avec plusieurs stories en parallèle, une question par story bloquerait la flotte à chaque pas.

## Considered Options
- **Checkpoints par story** — contrôle maximal, flotte bloquée.
- **Autonomie totale jusqu'au milestone** — rapide, aucun regard sur les plans.
- **Réglage, avec regroupement en flotte** — `Plan validation` et `Ship confirmation` restent des réglages ; en flotte, les plans d'une vague se valident en une seule question et le ship humain se fait sur la PR du milestone.

## Decision Outcome
Chosen option: **Réglage, avec regroupement en flotte**, parce qu'il garde le regard humain sur les plans sans sérialiser le travail.

### Consequences
- Good, because un projet solo peut rester strict story par story, et la flotte avance par vagues.
- Bad, because valider une vague entière demande de relire plusieurs plans d'un coup.
- Neutral: s'implémente en M3 avec la flotte ; en M1 les checkpoints sont par story.
