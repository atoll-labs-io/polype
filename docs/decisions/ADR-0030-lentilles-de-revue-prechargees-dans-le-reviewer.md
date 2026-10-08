---
adr: 0030
title: Les lentilles de revue sont un skill préchargé par le seul reviewer, déclenché par sa lecture du diff
status: accepted
date: 2026-10-08
tags: [adr, polype, revue]
scope: story s53-review-lenses
supersedes: []
superseded-by: []
---

# ADR-0030 — Les lentilles de revue sont un skill préchargé par le seul reviewer, déclenché par sa lecture du diff

## Context and Problem Statement
s53 veut que la revue cherche les défauts de sécurité, de migration, de dépendance et de performance quand le diff touche ces sujets, sans second reviewer ni second verdict. Il faut choisir où vivent ces listes, qui décide qu'une lentille s'applique, et à quel moment de la procédure `review-antihallu` elles passent, sachant que les six étapes numérotées sont figées par `tests/review.test.sh`.

## Considered Options
- **Un skill `review-lenses` préchargé par le reviewer, appliqué après l'étape 6, déclenché par une table de chemins et de contenus que le reviewer lit dans le diff** — un seul contexte, une seule échelle, un seul verdict ; les déclencheurs restent de la prose.
- **Un subagent par lentille, dont les constats sont fusionnés** (gstack `review/specialists/`) — plusieurs contextes, plusieurs échelles à réconcilier, et une fusion par LLM que `docs/references/gstack-agent-skills.md` écarte déjà.
- **Le reviewer lit le fichier du skill à la demande, seulement quand une lentille se déclenche** — économise le préchargement, mais le chemin du skill change selon la pose (`~/.claude/skills/` en global, `.claude/skills/` en projet) : une lecture ratée se tait, une lentille non chargée ne cherche rien.
- **Une sous-commande `po-gate lenses` qui calcule les lentilles depuis le diff** — déterministe pour les chemins, mais `po-gate.sh` est hors des `Owns` de s53, et les déclencheurs de contenu (un appel sortant vers une URL fournie, un appel LLM) demandent une lecture qu'un motif ne tient pas.
- **Les listes écrites dans `review-antihallu` même** — un seul fichier, mais il mêle « comment juger » et « où regarder », et alourdit un skill dont des dizaines de phrases sont figées par les tests.

## Decision Outcome
Chosen option: **un skill `review-lenses` préchargé, appliqué après l'étape 6, déclenché par le reviewer**, parce qu'il garde un seul juge et une seule échelle, que les listes sont assez courtes pour être préchargées à chaque revue, et qu'il ne demande aucun script hors des `Owns` de la story. Les sévérités que nomment les lentilles (autorisation manquante critique, renommage en place majeur) sont des placements sur l'échelle de `review-antihallu`, pas une échelle nouvelle.

### Consequences
- Good, because une lentille ajoute des choses à chercher sans toucher au verdict : `Max severity:` et `Ship allowed:` restent les deux seules lignes de verdict.
- Good, because la ligne `Lenses run:` du rapport rend visible ce qui a été cherché, et ce qui ne l'a pas été.
- Bad, because le déclenchement est une lecture, pas un calcul : un reviewer peut rater un chemin. s55 (evals du reviewer) mesurera ce taux.
- Neutral: si les evals montrent des lentilles oubliées, les déclencheurs de chemin pourront passer dans `po-gate` par une story qui le possède ; les déclencheurs de contenu resteront une lecture.
