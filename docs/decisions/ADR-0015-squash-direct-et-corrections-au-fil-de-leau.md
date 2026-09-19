---
adr: 0015
title: Chaque story est squashée dans la branche cible, sans PR de milestone
status: accepted
date: 2026-09-19
deciders: [lecrabe]
tags: [adr, polype, git]
supersedes: [ADR-0013]
superseded-by: []
---

# ADR-0015 — Chaque story est squashée dans la branche cible, sans PR de milestone

## Context and Problem Statement
ADR-0013 faisait passer chaque story par une branche d'intégration, relue d'un bloc dans une PR humaine en fin de milestone. À l'usage de M1, cette attente freine plus qu'elle ne protège : la revue en contexte frais et les gates filtrent déjà chaque story, et les défauts qui passent se corrigent mieux au moment où ils apparaissent.

## Considered Options
- **Garder ADR-0013** — branche d'intégration et PR humaine par milestone.
- **Squash direct dans la branche cible** — chaque story atterrit sur `Target branch` dès que sa revue l'autorise, en PR ou en local selon `Merge mode` ; on corrige au fil de l'eau.

## Decision Outcome
Chosen option: **Squash direct dans la branche cible**, parce qu'avancer et corriger quand le besoin se fait sentir coûte moins cher que d'attendre une relecture groupée.

### Consequences
- Good, because une story livrée est immédiatement disponible pour les suivantes, sans branche intermédiaire à maintenir.
- Bad, because aucune relecture humaine d'ensemble n'est imposée : un défaut qui traverse la revue d'une story se découvre à l'usage.
- Neutral: la revue transverse (`/roast-me`) reste disponible à la demande. Dans ADR-0014, la validation groupée des plans par vague reste valable ; le ship « au niveau du milestone » tombe avec cette décision et sera revu quand la flotte (M3) sera construite.
