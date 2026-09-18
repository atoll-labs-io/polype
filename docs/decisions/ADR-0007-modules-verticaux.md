---
adr: 0007
title: Modules verticaux avec couches internes
status: accepted
date: 2026-09-18
deciders: [lecrabe]
tags: [adr, polype, architecture, boilerplate]
supersedes: []
superseded-by: []
---

# ADR-0007 — Modules verticaux avec couches internes

## Context and Problem Statement
La flotte ne fait tourner deux stories en parallèle que si les chemins qu'elles possèdent (`owns`) sont disjoints. L'architecture des boilerplates Polype décide donc directement du niveau de parallélisme atteignable.

## Considered Options
- **Couches horizontales** (Presentation → Service → Persistence à la racine, comme ShipSaaS) — simple et prévisible, mais chaque story touche les mêmes dossiers.
- **Modules verticaux avec couches internes** — un dossier par domaine (`src/modules/<domaine>/`) contenant ui, service, repository et policy ; un noyau partagé `src/core/` (auth, tenant, billing, db).
- **Hexagonal** (ports et adaptateurs) — découplage maximal, cérémonie lourde pour un SaaS.

## Decision Outcome
Chosen option: **Modules verticaux avec couches internes**, parce qu'une story correspond à un module, donc à une lane de la flotte, tout en gardant la testabilité des couches (règles métier testées dans `service`, sans HTTP ni base).

### Consequences
- Good, because les stories de modules différents tournent en parallèle sans conflit de fichiers.
- Bad, because le noyau `src/core/` devient un goulot : il doit être stabilisé tôt, et une story qui le modifie passe seule.
- Neutral: s'applique aux boilerplates maison. Un boilerplate tiers du catalogue garde son architecture ; son profil déclare la granularité d'ownership qu'il permet.
