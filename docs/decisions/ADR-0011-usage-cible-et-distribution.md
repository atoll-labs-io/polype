---
adr: 0011
title: Usage cible — B2C d'abord, auto-hébergé en avant, offre gérée payante
status: accepted
date: 2026-09-18
deciders: [lecrabe]
tags: [adr, polype, produit, billing]
supersedes: []
superseded-by: []
---

# ADR-0011 — Usage cible : B2C d'abord, auto-hébergé en avant, offre gérée payante

## Context and Problem Statement
Le choix de la brique par défaut de chaque capacité (ADR-0009) dépend de l'usage des SaaS que Polype produira : à qui on vend, comment le produit est distribué, comment il est facturé.

## Considered Options
- **B2B multi-tenant d'abord** — organisations, rôles, facturation par siège.
- **B2C d'abord, auto-hébergé en avant, offre gérée payante** — chaque produit est auto-hébergeable par ses utilisateurs, et une offre gérée en SaaS est vendue par abonnement et à l'usage.
- **SaaS géré seulement** — pas de distribution auto-hébergée.

## Decision Outcome
Chosen option: **B2C d'abord, auto-hébergé en avant, offre gérée payante**, et les briques prévoient les deux modes de déploiement (auto-hébergé et géré) dès le départ.

### Consequences
- Good, because l'édition auto-hébergée ne dépend d'aucun service payant, ce qui aligne les briques par défaut sur l'auto-hébergement.
- Bad, because chaque produit vit en deux éditions : l'édition auto-hébergée doit tourner sans brique de paiement, l'offre gérée doit porter abonnement **et** facturation à l'usage (compteurs d'usage).
- Neutral: en B2C dans l'UE, la TVA se collecte selon le pays de l'acheteur ; la brique de paiement devra proposer un Merchant of Record (qui prend la TVA en charge) à côté de Stripe. Le multi-tenant B2B reste une capacité à ajouter plus tard. Interprétation à confirmer : « auto-hébergé en avant » est lu comme « le produit est distribué pour être auto-hébergé par ses utilisateurs ».
