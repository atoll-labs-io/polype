---
adr: 0009
title: Techno optimale par capacité, briques interchangeables selon l'hébergeur
status: accepted
date: 2026-09-18
deciders: [lecrabe]
tags: [adr, polype, architecture, deploiement]
supersedes: []
superseded-by: []
---

# ADR-0009 — Techno optimale par capacité, briques interchangeables selon l'hébergeur

## Context and Problem Statement
Les prototypes tournent chez mustelinet (cloud OpenStack d'un ami : VM, volumes, Kubernetes managé, publication HTTP/HTTPS seulement, ni base managée ni stockage objet documentés). La production ira chez un gros hébergeur, pas encore choisi. Il faut choisir les technos sans les enfermer dans l'un ou l'autre.

## Considered Options
- **Standards uniquement** — Postgres pour tout, API S3, conteneur ; portable, mais on renonce à la meilleure techno quand elle n'est pas un standard.
- **Techno optimale, figée** — le meilleur outil pour chaque besoin, câblé en dur ; changer d'hébergeur oblige à réécrire.
- **Techno optimale par capacité, derrière une brique interchangeable** — chaque capacité (base, auth, fichiers, jobs, email, paiement, observabilité, déploiement…) a une interface, une brique par défaut choisie pour notre usage, et des briques alternatives sélectionnées par configuration.

## Decision Outcome
Chosen option: **Techno optimale par capacité, derrière une brique interchangeable**, parce qu'on garde le meilleur outil par défaut sans que l'hébergeur dicte le code : quand il impose autre chose, on ajoute une brique au lieu de réécrire l'application.

### Consequences
- Good, because un changement d'hébergeur se traduit par une brique de plus et un changement de configuration, pas par une migration de code applicatif.
- Bad, because chaque capacité paie une interface et au moins un jeu de tests de contrat que toutes ses briques doivent passer.
- Neutral: le profil d'un boilerplate déclare quelles capacités il fournit et avec quelles briques. Le choix des briques d'un projet se fait à l'étape architecture et s'enregistre en ADR de projet. La liste des capacités, avec brique par défaut et alternatives, vit dans un catalogue de capacités de la méthode.
