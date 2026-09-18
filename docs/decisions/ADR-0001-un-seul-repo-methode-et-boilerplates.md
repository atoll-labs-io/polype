---
adr: 0001
title: Un seul repo pour la méthode et les boilerplates
status: accepted
date: 2026-09-18
deciders: [lecrabe]
tags: [adr, polype, repo]
supersedes: []
superseded-by: []
---

# ADR-0001 — Un seul repo pour la méthode et les boilerplates

## Context and Problem Statement
La méthode impose des règles d'architecture (couches, emplacement des règles métier, commandes de test) qui dépendent directement du boilerplate sur lequel les agents travaillent. Si les deux évoluent séparément, les règles décrivent un code qui n'existe plus.

## Considered Options
- **Un seul repo** — la méthode dans `method/`, les socles dans `boilerplates/<nom>/`, versionnés ensemble.
- **Deux repos** — le boilerplate vit comme un template indépendant, la méthode le référence par version.
- **Boilerplate externe** — s'appuyer sur un kit du marché (ShipSaaS, MakerKit…) et n'écrire que la méthode.

## Decision Outcome
Chosen option: **Un seul repo**, parce qu'un changement de convention dans le boilerplate et la règle de méthode qui en dépend arrivent dans le même commit, sans matrice de compatibilité à maintenir.

### Consequences
- Good, because une seule version de vérité pour les règles et le code qu'elles décrivent.
- Bad, because le boilerplate traîne l'historique de la méthode quand on l'instancie : l'installeur doit copier le dossier, pas cloner le repo.
- Neutral: à reconsidérer si un boilerplate devient un produit distribué seul.
