---
adr: 0032
title: Le modèle de chaque subagent choisi selon la complexité de la story
status: proposed
date: 2026-10-08
deciders: [lecrabe]
tags: [adr, polype, flotte, coût]
supersedes: []
superseded-by: []
---

# ADR-0032 — Le modèle de chaque subagent choisi selon la complexité de la story

## Context and Problem Statement
L'implementer est figé sur `model: opus` et tous les autres subagents héritent du modèle de la session. Une session sur le modèle le plus fort fait donc tourner chaque planner, implementer, designer, QA et reviewer sur ce modèle, même pour une story de complexité 1. Une vague de deux stories lance six subagents ou plus ; la dépense suit, sans rapport avec la difficulté du travail.

## Considered Options
- **Garder l'état actuel** — rien à écrire, mais le coût reste celui du modèle le plus fort partout, et le `opus` figé de l'implementer ignore la session.
- **Un modèle par rôle, fixé dans le frontmatter** — simple, mais le frontmatter est commun à tous les projets et ne connaît pas la story.
- **Un modèle par rôle, réglé dans `AGENTS.local.md`** — chaque projet choisit, mais une story de complexité 1 et une de complexité 4 reçoivent le même modèle.
- **Un modèle choisi par la commande qui dispatche, selon la complexité, avec la revue toujours sur le modèle fort** — l'outil Agent accepte un `model` à chaque appel ; deux réglages de modèle et un seuil suffisent.

## Decision Outcome
Chosen option: **un modèle choisi par la commande qui dispatche, selon la complexité, avec la revue toujours sur le modèle fort**, parce que la complexité est déjà notée pour chaque story (puis re-notée par la recherche) et qu'elle mesure ce qui coûte cher à rater. Le reviewer reste sur le modèle fort parce qu'il est le seul à juger le travail des autres.

### Consequences
- Good, because une story simple coûte un modèle léger pour le plan et le code, et le projet garde la main par trois réglages.
- Good, because l'implementer cesse d'ignorer le modèle de la session (`model: inherit`).
- Bad, because un modèle léger peut produire un plan ou un code plus faible ; la revue sur le modèle fort et les fix runs absorbent ce risque, au prix de boucles en plus.
- Neutral: les evals de s55 donneront le taux de défauts par modèle ; le seuil `Light up to` se règle d'après elles.
