---
adr: 0103
title: La QA lit les règles d'ignorance et d'attributs de git
status: accepted
date: 2026-11-10
tags: [adr, polype, qa, hooks, bounds]
scope: story s157-qa-reads-ignore-rules
supersedes: [ADR-0026]
superseded-by: []
---

# ADR-0103 — La QA lit les règles d'ignorance et d'attributs de git

## Context and Problem Statement
Sur lagon, `git check-ignore -v site/dist site/.astro` a été refusé par `po-bounds` en mode `qa` : le verbe manquait à la liste blanche d'ADR-0026, et le refus a arrêté la marche (`blocked`), puisque `method/agents/qa.md:57` fait de tout refus un arrêt. ADR-0026 disait au contraire que la QA reformule. Les deux textes se contredisent ; la liste doit couvrir ces lectures.

## Considered Options
- **Ajouter `check-ignore` et `check-attr` à la liste** — deux lectures pures, qui n'écrivent rien.
- **Laisser la QA reformuler** — écarté : un refus est un arrêt, et c'est ce qui a coûté sa marche à lagon.
- **Liste noire des verbes qui écrivent** — écarté, comme dans ADR-0026 : un verbe oublié passe.

## Decision Outcome
Chosen option: **ajouter `check-ignore` et `check-attr`**, parce qu'ils ne font qu'afficher ce que les règles disent et que le refus de `--output` s'applique encore à eux.

Liste des verbes de lecture : `status`, `diff`, `log`, `show`, `rev-parse`, `ls-files`, `ls-tree`, `cat-file`, `merge-base`, `grep`, `blame`, `describe`, `symbolic-ref`, `shortlog`, `check-ignore`, `check-attr`, plus `worktree list`.

Le reviewer reçoit les mêmes verbes dans sa zone de story (ADR-0047, ADR-0051). Cet ADR remplace ADR-0026 sur la liste seule ; le reste d'ADR-0026 (outils hérités, `Tree:` par `rev-parse`) reste en vigueur.

### Consequences
- Good, because une vérification d'ignorance ne devient plus un arrêt de la marche.
- Bad, because la liste s'élargit pour le reviewer aussi.
- Neutral: d'autres lectures (`branch --show-current`, `for-each-ref`, `config --get`) seraient une nouvelle idée pour `Issue tracker`.
