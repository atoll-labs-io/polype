---
adr: 0006
title: Adapter Killer SaaS en s'en inspirant fortement, sans copie
status: accepted
date: 2026-09-18
deciders: [lecrabe]
tags: [adr, polype, killer-saas, licence]
supersedes: []
superseded-by: []
---

# ADR-0006 — Adapter Killer SaaS en s'en inspirant fortement, sans copie

## Context and Problem Statement
Killer SaaS est la référence de qualité de Polype, mais son repo n'a pas de licence : tous droits réservés. Polype sera installé globalement et synchronisé par chezmoi vers un repo GitHub (ADR-0004), donc tout texte repris serait republié.

## Considered Options
- **Forker après avoir demandé une licence à l'auteur** — qualité identique, dépend de sa réponse.
- **Surcouche** — installer Killer SaaS tel quel et construire Polype autour.
- **Adapter** — reprendre ses mécanismes et sa structure, réécrire chaque commande, skill, subagent et template à notre sauce.

## Decision Outcome
Chosen option: **Adapter**, parce que Polype doit évoluer librement (trois modes, flotte parallèle, tracker) sans dépendre de l'auteur ni de ses évolutions, et que la valeur de la méthode est dans ses mécanismes, qui se reprennent, pas dans ses phrases.

### Consequences
- Good, because Polype est entièrement à nous : distribuable, modifiable, commercialisable.
- Bad, because la qualité n'est plus garantie par la copie : elle doit être prouvée.
- Neutral: la preuve passe par une matrice de parité (chaque règle et mécanisme de `src/` de Killer SaaS au commit `43ec45f`, avec son équivalent Polype) et par une comparaison des deux méthodes sur un même projet pilote. Aucune issue n'est ouverte chez l'auteur.
