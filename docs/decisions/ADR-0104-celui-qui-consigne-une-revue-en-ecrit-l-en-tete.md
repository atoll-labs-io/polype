---
adr: 0104
title: Celui qui consigne une revue en écrit l'en-tête
status: accepted
date: 2026-11-11
scope: story s158-review-header-recorded
supersedes: []
superseded-by: []
---

# ADR-0104 — Celui qui consigne une revue en écrit l'en-tête

## Context and Problem Statement
Le #169 : l'en-tête d'une revue était ce que le relecteur avait recopié. La revue de s147 est arrivée sans sa ligne de liens (`f71ba00`) et a rendu main rouge ; elle a été réparée à la main (`2f98528`, #168). Le `Tree:` du dossier de vérification et la porte de ship excluent `docs/`, et `po-gate findings-shape` ne lit que le bloc des constats (ADR-0094, ADR-0096) : rien ne rattrape un en-tête manquant.

## Considered Options
- **Celui qui consigne la revue écrit l'en-tête** — le titre et la ligne de liens viennent du gabarit, le relecteur répond en dessous.
- **Insérer la ligne de liens seulement quand elle manque** — écarté : une exception conditionnelle de plus à la transcription, qui dépend de ce que le relecteur a recopié.
- **Faire refuser la revue par `po-gate` et arrêter la voie** — écarté : chaque oubli du relecteur devient un arrêt pour la personne, et une nouvelle réponse ajoutée après lui ne répare pas la ligne sous le premier titre.

## Decision Outcome
Chosen option: **Celui qui consigne la revue écrit l'en-tête**, parce que l'en-tête ne dépend alors plus de ce que le relecteur recopie.

La première écriture de `docs/reviews/<id>.md` commence par le titre et la ligne de liens de `templates/review.md`, `<id>` remplacé, un lien dont la cible manque dans le worktree étant retiré, puis le corps. Un fichier qui existe garde son en-tête et ne reçoit que le nouveau bloc.

Place dans la règle de transcription : le verdict, les constats et les lignes de statut restent mot pour mot ; seul l'en-tête du fichier vient du gabarit. `/po-orchestrator` et `/po-flow` en héritent par « as `/po-review` says ». Une revue consignée avant cet ADR est réparée par une personne avec `bin/po-link-artifacts`, jamais par une insertion conditionnelle.

### Consequences
- Good, because chaque revue naît avec son titre et sa ligne de liens, quoi que le relecteur renvoie.
- Bad, because un relecteur qui recopie quand même l'en-tête produit un titre double, gardé tel quel par la transcription.
- Neutral: les revues déjà consignées ne sont pas touchées ; le gabarit porte une note sous la ligne de liens.
