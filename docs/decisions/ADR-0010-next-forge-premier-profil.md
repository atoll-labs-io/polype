---
adr: 0010
title: next-forge comme premier boilerplate profilé
status: accepted
date: 2026-09-18
deciders: [lecrabe]
tags: [adr, polype, boilerplate, catalogue]
supersedes: []
superseded-by: []
---

# ADR-0010 — next-forge comme premier boilerplate profilé

## Context and Problem Statement
Le catalogue démarre avec des boilerplates open source (ADR-0008). Le premier profil sert aussi de banc d'essai pour le format de profil et pour les briques interchangeables (ADR-0009).

## Considered Options
- **next-forge** — Next.js, Turborepo, un package par capacité (auth, database, payments, storage, email, observability…), MIT ; services managés par défaut (Clerk, Neon, Vercel Blob, Resend).
- **ixartz/SaaS-Boilerplate** — Next.js complet (i18n, Sentry, Storybook, tests), MIT ; auth Clerk câblée dans l'application.
- **nextjs/saas-starter** — minimal et auto-hébergeable, MIT ; moins actif, peu de capacités.
- **Open SaaS** — paiement déjà interchangeable, jobs pg-boss, MIT ; framework Wasp, moins connu des agents.
- **Epic Stack** — auth et tests de référence, MIT ; ni billing ni multi-tenant, SQLite/Fly.

## Decision Outcome
Chosen option: **next-forge**, parce que son découpage en un package par capacité est déjà la forme d'ADR-0009 : remplacer une brique (Clerk par une auth auto-hébergée, Vercel Blob par un stockage S3 chez mustelinet) se fait dans un package sans toucher aux applications, et Next.js est le framework que les agents connaissent le mieux.

### Consequences
- Good, because les packages donnent des frontières d'ownership naturelles pour la flotte.
- Bad, because ses briques par défaut sont des services managés : les briques auto-hébergées nécessaires à mustelinet sont à écrire dès le premier prototype.
- Neutral: Prisma (et non Drizzle) vient avec lui ; on le garde tant que le profil n'a pas de raison d'en changer.
