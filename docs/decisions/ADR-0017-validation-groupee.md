---
adr: 0017
title: Validation groupée des plans par vague, ship story par story
status: accepted
date: 2026-09-21
deciders: [lecrabe]
tags: [adr, polype, flotte, autonomie]
supersedes: [ADR-0014]
superseded-by: []
---

# ADR-0017 — Validation groupée des plans par vague, ship story par story

## Context and Problem Statement
ADR-0014 portait deux décisions d'un bloc : les plans d'une vague se valident en une seule question, et le ship humain se fait sur la PR du milestone. ADR-0015 a supprimé le second volet — « le ship "au niveau du milestone" tombe avec cette décision » — sans superséder ADR-0014, qui reste `accepted`. Deux ADR vivantes se contredisent donc devant chaque agent qui lit « les ADR acceptées », au moment précis où M3 implémente la validation groupée dans `/po-drive`.

## Considered Options
- **Garder ADR-0014 telle quelle** — rien à écrire, mais la contradiction reste : un lecteur doit savoir qu'ADR-0015 a mangé la moitié d'ADR-0014 dans ses conséquences.
- **Redécider la validation groupée de zéro** — une ADR neuve qui ignore ADR-0014 et laisse son statut ouvert : la contradiction demeure et l'historique de la décision se perd.
- **Superséder ADR-0014 par ce qui tient encore** — une seule décision vivante, qui garde la validation groupée et enregistre que le ship est redevenu affaire de story.

## Decision Outcome
Chosen option: **Superséder ADR-0014 par ce qui tient encore**, parce qu'une décision à demi périmée coûte plus cher à lire qu'à réécrire.

Ce qui vaut désormais :
- En flotte, les plans d'une vague se valident en une seule `AskUserQuestion` sous `Plan validation: human` : approuver toute la vague, choisir lesquels, ou arrêter. Un plan non approuvé garde `validated: no`, sa voie attend la vague suivante et aucun implementer ne part pour elle.
- Sous `Plan validation: autonomous`, les plans partent sans question et le rapport de vague dit que personne ne les a relus.
- Le ship reste story par story, réglé par `Merge mode` et `Ship confirmation` (ADR-0015) : il n'y a pas de checkpoint de milestone.

### Consequences
- Good, because une seule ADR décrit le regard humain sur la flotte, et `/po-drive` a une référence unique à citer.
- Bad, because relire d'un coup les plans d'une vague demande plus d'attention qu'un plan isolé, et l'approbation partielle retarde d'une vague les voies refusées.
- Neutral: `Plan validation` et `Ship confirmation` restent des réglages ; un projet solo garde le rythme story par story sans rien changer.
