---
adr: 0020
title: Briques par défaut de chaque capacité — auto-hébergeables d'abord
status: accepted
date: 2026-09-22
deciders: [lecrabe]
tags: [adr, polype, capacites, briques]
supersedes: []
superseded-by: []
---

# ADR-0020 — Briques par défaut de chaque capacité, auto-hébergeables d'abord

## Context and Problem Statement
ADR-0009 pose qu'une capacité a une interface, une brique par défaut et des alternatives configurables, mais ne dit pas lesquelles. Sans ce choix, l'étape architecture décide au cas par cas et le catalogue de boilerplates (M4) n'a rien à profiler. ADR-0011 fixe l'usage : B2C d'abord, distribution auto-hébergée mise en avant, offre gérée vendue par abonnement et à l'usage ; les prototypes tournent chez mustelinet, qui ne fournit ni base ni stockage objet managés.

## Considered Options
- **Suivre les défauts du boilerplate choisi** (next-forge : Clerk, Neon, Vercel Blob) — zéro travail au départ, mais l'édition auto-hébergée devient impossible sans réécriture, et chaque prototype dépend de comptes tiers.
- **Auto-hébergeable par défaut, managé en alternative** — chaque capacité a une brique qui tourne chez nous, et une alternative managée activée par configuration quand un hébergeur ou une charge le justifie.
- **Tout managé** — le plus rapide à lancer, incompatible avec la distribution auto-hébergée d'ADR-0011.

## Decision Outcome
Chosen option: **Auto-hébergeable par défaut, managé en alternative**, parce que l'édition que les utilisateurs hébergent eux-mêmes ne peut dépendre d'aucun compte tiers, et qu'une brique managée s'ajoute ensuite sans toucher au code applicatif.

| Capacité | Brique par défaut | Alternatives |
|---|---|---|
| Base de données | PostgreSQL auto-hébergé, migrations versionnées par l'ORM du profil | Postgres managé de l'hébergeur |
| Auth | Better Auth, sessions et comptes dans notre base | Clerk ou l'auth du profil |
| Autorisation | policies applicatives, matrice testée une seule fois | — |
| Multi-tenant | organisations en base, filtre tenant vérifié au repository | — |
| Fichiers | API S3, Garage auto-hébergé | S3 de l'hébergeur, Vercel Blob |
| Jobs | file dans Postgres (pg-boss ou équivalent du profil) | Inngest, Trigger.dev |
| Email | SMTP, relais au choix | Resend ou équivalent |
| Paiement | Stripe pour l'offre gérée ; **aucune brique dans l'édition auto-hébergée** | Merchant of Record (Polar, Lemon Squeezy) quand la TVA B2C le justifie |
| Cache et limitation de débit | Postgres, ou Valkey auto-hébergé si la charge l'exige | Upstash |
| Observabilité | OpenTelemetry vers un collecteur auto-hébergé | Sentry |
| i18n | bibliothèque du framework du profil | — |
| Déploiement | image conteneur ; mustelinet en Kubernetes managé ou VM | plateforme de l'hébergeur retenu |

### Consequences
- Good, because un prototype tourne chez mustelinet sans aucun compte tiers, et l'édition auto-hébergée d'un produit reste complète sans paiement.
- Bad, because chaque brique auto-hébergée est à opérer : sauvegardes de Postgres, disponibilité de Garage, supervision du collecteur.
- Neutral: un profil de boilerplate déclare les briques qu'il apporte ; l'écart avec ce tableau se règle à l'étape architecture, brique par brique, et s'enregistre en ADR de projet.
