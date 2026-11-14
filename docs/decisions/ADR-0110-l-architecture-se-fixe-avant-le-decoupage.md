---
adr: 0110
title: L'architecture se fixe avant le découpage
status: accepted
date: 2026-11-12
scope: framing
supersedes: []
superseded-by: []
---

# ADR-0110 — L'architecture se fixe avant le découpage

## Context and Problem Statement
La chaîne de cadrage va de `/po-setup` au périmètre (`/po-brief` ou `/po-prd`), puis aux stories, à leur revue, à l'architecture et au design system. Or une story déclare dans `Owns` les chemins qu'elle a le droit de changer, et `po-bounds` les fait respecter : sur un projet neuf, ces chemins sont écrits avant que la base et l'arborescence soient choisies. Sur lophelia (2026-10-14), la revue des stories a trouvé des `Owns` incomplets (`Cargo.toml`, `Cargo.lock`) que `po-bounds` aurait refusés en pleine implémentation (#69) ; #166 est de la même famille. Faut-il changer l'ordre ?

## Considered Options
1. **Périmètre, architecture, stories, revue des stories, design system** — les stories s'écrivent sur une arborescence connue ; `/po-architect` lit le périmètre au lieu des stories pour choisir la base.
2. **Garder l'ordre, et faire compléter les `Owns` par `/po-architect`** — une seconde passe sur `docs/stories.md` après l'architecture, suivie d'une seconde revue.
3. **Ne rien changer** — les `Owns` faux se découvrent en revue des stories ou au premier refus de `po-bounds`.

## Decision Outcome
Chosen option: **l'option 1**, choisie par le porteur le 2026-11-14 (décision d-0004 de la boîte). Un seul cas la fondait à l'origine (lophelia) ; M21 en a ajouté huit : sur ses treize stories, huit ont demandé une retouche de cadrage avant de pouvoir être construites, presque toujours parce que leur `Owns` avait été écrit avant que le code qu'elles touchent existe.

Le porteur y attache une exigence sur la façon de fixer l'architecture, qui vaut pour `/po-architect` : elle se décide **avec la personne**. Chaque choix technique lui est présenté en détail, avec ses pour et ses contre ; l'agent prend le temps de chercher les architectures les mieux adaptées à une production qui passe à l'échelle, se surveille, se manie facilement par un agent et consomme le moins possible. Aucun choix d'architecture n'est arrêté sans cette discussion (ADR-0077). La forme que prend cette exigence dans `/po-architect` et dans la chaîne de cadrage est une story de M22.

### Consequences
- Good, because un `Owns` s'écrit sur des chemins qui existent ou que l'architecture a nommés.
- Bad, because l'architecture se choisit sans le détail des stories, et peut devoir être reprise après elles.
- Neutral: sur un projet qui a déjà son code, l'ordre importe peu, `/po-architect` lisant l'existant.
