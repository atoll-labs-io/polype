---
adr: 0008
title: Catalogue de boilerplates décrits par profils, gratuits d'abord
status: accepted
date: 2026-09-18
deciders: [lecrabe]
tags: [adr, polype, boilerplate, catalogue]
supersedes: []
superseded-by: []
---

# ADR-0008 — Catalogue de boilerplates décrits par profils, gratuits d'abord

## Context and Problem Statement
La méthode doit pouvoir partir de plusieurs boilerplates. Écrire d'emblée un boilerplate maison équivalent à ShipSaaS coûterait des semaines avant le premier projet, sans savoir encore ce dont les projets auront besoin.

## Considered Options
- **Un boilerplate maison unique, écrit d'abord** — qualité maîtrisée, gros investissement initial.
- **Catalogue de profils, boilerplates open source d'abord** — chaque entrée est décrite par un profil (commandes, carte du code, granularité d'ownership, règles, inventaire UI, origine et licence) ; les boilerplates maison s'ajoutent au fil des projets.
- **Aucun boilerplate** — scaffold par défaut à chaque projet.

## Decision Outcome
Chosen option: **Catalogue de profils, boilerplates open source d'abord**, parce que la méthode dépend de ce qu'elle sait du boilerplate, pas du boilerplate lui-même, et qu'un profil coûte bien moins cher à écrire qu'un boilerplate.

### Consequences
- Good, because le premier projet peut démarrer dès que la méthode et un profil existent.
- Bad, because les boilerplates tiers imposent leur architecture : la granularité d'ownership, donc le parallélisme de la flotte, dépend de chacun.
- Neutral: seuls les boilerplates sous licence libre sont vendorisés ou référencés. Un boilerplate maison naît quand un projet en extrait un socle réutilisable ; il suit alors ADR-0007. ADR-0001 s'applique aux boilerplates maison.
