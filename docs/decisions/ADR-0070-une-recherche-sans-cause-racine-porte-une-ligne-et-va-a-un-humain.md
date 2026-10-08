---
adr: 0070
title: Le diagnostic court sur tous les chemins, et une recherche sans cause racine porte une ligne qui l'envoie à un humain
status: accepted
date: 2026-10-08
scope: story s96-defect-and-routing-paths
supersedes: [ADR-0068]
superseded-by: []
---

# ADR-0070 — Une recherche sans cause racine porte une ligne et va à un humain

## Context and Problem Statement
ADR-0068 fait appliquer la skill `diagnostic` par le seul planner de la flotte. Sa conséquence neutre l'admet : `/po-research` et `/po-orchestrator` n'appliquent pas la skill. Une story `Fixes` que `/po-flow` renvoie en voie complète est donc recherchée sans diagnostic (revue s90, majeur 1). Quand le diagnostic échoue, la skill dit « pas de plan », mais n'écrit rien qu'un lecteur puisse reconnaître. La table de reprise de `/po-drive` voit alors une recherche sans plan et relance le planner, qui bâtit un plan sur elle (revue s90, majeur 2).

## Considered Options
- **Une ligne exacte `Root cause: not found` en tête de `## Structuring facts` de la recherche** — retenu. Le driver la lit avec `grep -x`. Elle voyage avec la recherche sur `story/<id>`, et la section existe déjà dans le gabarit.
- **Un fichier marqueur à part (`docs/research/<id>.blocked`)** — un fichier de plus, que `po-bounds`, la loi 4 et les droits d'écriture du planner devraient tous reconnaître. La cause d'arrêt serait séparée des hypothèses qui la justifient.
- **Un frontmatter dans la recherche** — le gabarit `templates/research.md` n'en a pas et n'appartient pas à cette story. Un champ de plus lu par un seul cas.
- **Reconnaître la phrase « no root cause was found » dans la prose** — rien ne la fixe. Deux agents l'écriraient différemment, et `/po-drive status` ne pourrait pas la dériver.
- **Laisser `/po-research` hors du diagnostic et ne traiter que le chemin `/po-orchestrator`** — `/po-research` lancé à la main resterait la porte d'un correctif deviné.

## Decision Outcome
Chosen option: **la ligne exacte `Root cause: not found`**, parce qu'un état que le driver dérive du disque doit être une donnée qu'on lit sans interprétation, comme `validated: yes` ou `QA status:`.

- `/po-research` et `/po-orchestrator` (étape 2) appliquent la skill `diagnostic` à une story qui porte une ligne `Fixes` (`Corrige`). Cela remplace la conséquence neutre d'ADR-0068 qui disait le contraire. Le reste d'ADR-0068 tient.
- Trois hypothèses écartées → la recherche porte, seule sur sa ligne, `Root cause: not found` en tête de `## Structuring facts`.
- Cette ligne arrête la story pour un humain :
  - une ligne de la table de reprise de `/po-drive`, lue avant la ligne du plan ;
  - le planner, qui ne bâtit aucun plan sur une telle recherche ;
  - `/po-plan`, qui s'arrête dans ses vérifications.
- Un humain qui trouve la cause réécrit la recherche et retire la ligne. La story reprend alors au plan.

### Consequences
- Good, because aucun chemin ne mène plus d'une story de défaut à un plan sans diagnostic, et l'arrêt se dérive du disque.
- Bad, because une ligne en anglais apparaît dans une recherche, quelle que soit la langue du projet. C'est une donnée lue par le driver, pas de la prose.
- Neutral: les commandes nomment la skill en prose, comme `codebase-analysis` dans `/po-research` ; aucune exécution réelle n'a montré que le contexte principal la charge.
