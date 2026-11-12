---
adr: 0110
title: L'architecture se fixe avant le découpage
status: proposed
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
Proposé, à trancher par le porteur. Recommandation : **l'option 1**, à vérifier sur le prochain projet cadré avant de toucher aux commandes : un seul cas (lophelia) la fonde, et `/po-architect` s'appuie aujourd'hui sur les stories pour repérer les intégrations. Le reste de la chaîne ne change pas : elle ne tourne qu'une fois par projet, en conversation avec la personne, et son coût n'est pas là où Polype dérive.

### Consequences
- Good, because un `Owns` s'écrit sur des chemins qui existent ou que l'architecture a nommés.
- Bad, because l'architecture se choisit sans le détail des stories, et peut devoir être reprise après elles.
- Neutral: sur un projet qui a déjà son code, l'ordre importe peu, `/po-architect` lisant l'existant.
