---
adr: 0032
title: Décider sur le modèle fort, adapter seulement l'exécution
status: accepted
date: 2026-10-08
deciders: [lecrabe]
tags: [adr, polype, flotte, coût]
supersedes: []
superseded-by: []
---

# ADR-0032 — Décider sur le modèle fort, adapter seulement l'exécution

## Context and Problem Statement
L'implementer est figé sur `model: opus` et tous les autres subagents héritent du modèle de la session. Une session sur le modèle le plus fort fait donc tourner chaque planner, implementer, designer, QA et reviewer sur ce modèle, même pour une story de complexité 1. Une vague de deux stories lance six subagents ou plus ; la dépense suit, sans rapport avec la difficulté du travail. Mais un plan, un design ou un verdict faibles coûtent plus cher que ce qu'ils économisent : tout ce qui suit s'appuie dessus.

## Considered Options
- **Garder l'état actuel** — rien à écrire, mais le coût reste celui du modèle le plus fort partout, et le `opus` figé de l'implementer ignore la session.
- **Tous les subagents d'une story simple sur un modèle léger, la revue seule sur le modèle fort** — l'économie la plus grande, mais le plan et le design d'une story simple deviennent faibles, et la revue doit rattraper des décisions mal prises plutôt que du code mal écrit.
- **Un modèle par rôle, réglé dans `AGENTS.local.md`** — chaque projet choisit, mais une story de complexité 1 et une de complexité 4 reçoivent le même implementer.
- **Les rôles qui décident toujours sur le modèle fort, l'implementer seul adapté à la complexité** — le plan fixe ce qu'il faut écrire ; l'exécuter est la part dont la difficulté suit la complexité.

## Decision Outcome
Chosen option: **les rôles qui décident toujours sur le modèle fort, l'implementer seul adapté à la complexité**, parce que la qualité d'une story se joue dans le plan, le design et la revue, et que l'implementer suit un plan validé qui ne lui laisse rien à décider. Planner, designer, reviewer, QA et stories-reviewer reçoivent `Model strong` ; l'implementer reçoit `Model light` jusqu'à `Light up to`, `Model strong` au-delà. Décision de l'utilisateur, le 2026-10-08.

### Consequences
- Good, because une story simple n'écrit plus son code sur le modèle le plus cher, et aucune décision n'est prise sur un modèle léger.
- Good, because l'implementer cesse d'ignorer le modèle de la session (`model: inherit`).
- Bad, because l'économie est plus faible que si tout s'adaptait : le planner et le reviewer restent les plus gros consommateurs d'une lane.
- Neutral: les evals de s55 et le taux de fix runs par modèle diront si `Light up to` peut monter.
