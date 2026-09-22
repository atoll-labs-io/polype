---
adr: 0018
title: L'état du travail se dérive des worktrees et de git ; le tracker n'est qu'un miroir
status: proposed
date: 2026-09-22
deciders: [lecrabe]
tags: [adr, polype, etat, flotte]
supersedes: [ADR-0003]
superseded-by: []
---

# ADR-0018 — L'état du travail se dérive des worktrees et de git ; le tracker n'est qu'un miroir

## Context and Problem Statement
ADR-0003 plaçait l'état du travail dans un tracker (GitHub Issues ou Taskwarrior), pour permettre le claim entre sessions parallèles et la reprise après crash. M3 a livré la flotte sous une autre forme : un seul driver lance des subagents (ADR-0016), donc il n'y a pas deux sessions à départager, et `/po-drive` reconstitue l'état depuis les worktrees et git. Les deux décisions se contredisent (défaut n° 22).

## Considered Options
- **Garder ADR-0003** — écrire chaque changement d'étape dans un tracker ; deux sources à tenir d'accord, pour un besoin que la flotte actuelle n'a plus.
- **État dérivé, tracker en miroir** — la vérité est dans les fichiers et dans git ; un tracker, quand le projet en a un, reçoit les états pour la visibilité et ne décide de rien.
- **Aucun tracker du tout** — simple, mais on perd la visibilité hors du dépôt et les défauts n'ont plus où aller (Loi 7).

## Decision Outcome
Chosen option: **État dérivé, tracker en miroir**, parce qu'un état dérivé ne peut pas mentir : il se recalcule, alors qu'un état écrit se désynchronise dès qu'une étape échoue au mauvais moment.

### Consequences
- Good, because `/po-drive` et `/po-status` répondent la même chose sans coordination, et une reprise après arrêt ne dépend d'aucun service.
- Bad, because deux machines ne peuvent pas travailler sur la même flotte : il faudra revenir à des claims partagés le jour où on le voudra (ADR-0016 le prévoit).
- Neutral: le réglage `Tracker` garde ses valeurs ; `github` publiera les états et les défauts quand le dépôt aura un remote. La Loi 7 continue d'envoyer les défauts vers `Issue tracker`.
