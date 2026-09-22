---
adr: 0016
title: La flotte est un driver unique qui lance des subagents en parallèle
status: accepted
date: 2026-09-21
deciders: [lecrabe]
tags: [adr, polype, flotte]
supersedes: []
superseded-by: []
---

# ADR-0016 — La flotte est un driver unique qui lance des subagents en parallèle

## Context and Problem Statement
M3 doit faire avancer plusieurs stories à la fois. Le cycle de M1 et M2 est une suite de commandes lancées par un humain dans une session ; il faut décider qui joue ce rôle quand plusieurs stories tournent.

## Considered Options
- **Plusieurs sessions Claude concurrentes**, une par story, coordonnées par un tracker — chaque session lance elle-même les commandes du cycle. Demande des verrous fiables (claim, reprise après crash, un seul propriétaire par story) dans un état partagé.
- **Un driver unique qui lance des subagents** — une session tient la flotte, prépare les worktrees, et lance en parallèle un subagent par lane : `planner` (research et plan), `implementer` (code), `reviewer` (verdict). Le driver ne code ni ne juge ; les ships restent en série, puisqu'ils écrivent tous sur la branche cible.
- **Séquentiel** — ce que fait M2 : une story à la fois.

## Decision Outcome
Chosen option: **Un driver unique qui lance des subagents**, parce que les lances parallèles se réduisent alors à plusieurs appels d'agent dans un seul message : l'attribution des stories est atomique sans verrou, l'état tient dans la session, et la reprise après crash se lit dans les worktrees.

### Consequences
- Good, because aucun verrou distribué à écrire pour parallléliser, et les garanties du cycle (plan validé, revue en contexte frais, gates) restent celles de M1.
- Bad, because le parallélisme est borné par une session : on ne fait pas travailler deux machines sur la même flotte.
- Neutral: le tracker d'ADR-0003 reste utile pour la visibilité et pour reprendre après un arrêt ; les sessions concurrentes redeviendront possibles le jour où un tracker partagé porte les claims. Un nouveau subagent `planner` naît de cette décision, parce qu'une commande ne peut pas s'exécuter dans un subagent.
