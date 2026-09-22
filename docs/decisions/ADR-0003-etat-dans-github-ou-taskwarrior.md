---
adr: 0003
title: L'état du travail vit dans GitHub Issues ou Taskwarrior
status: superseded
date: 2026-09-18
deciders: [lecrabe]
tags: [adr, polype, tracker]
supersedes: []
superseded-by: [ADR-0018]
---

# ADR-0003 — L'état du travail vit dans GitHub Issues ou Taskwarrior

## Context and Problem Statement
Killer SaaS dérive l'état de l'existence des fichiers dans `docs/`. La flotte parallèle doit en plus savoir qui a pris quelle story, reprendre après un crash et montrer l'avancement hors du repo.

## Considered Options
- **État dérivé des fichiers** — comme Killer SaaS, rien de stocké.
- **Tracker** — GitHub Issues + Project board via `octo`, ou Taskwarrior via `sensei` sans remote GitHub.
- **Fichier d'état dans le repo** — un JSON ou YAML mis à jour par le driver.

## Decision Outcome
Chosen option: **Tracker**, parce que le claim atomique entre sessions parallèles, la reprise après crash et la visibilité sur toutes les machines exigent un état partagé hors des worktrees.

### Consequences
- Good, because le driver sait qui fait quoi même quand plusieurs sessions tournent, et l'avancement se lit sur le board.
- Bad, because deux sources à garder cohérentes : les contrats dans `docs/`, l'état dans le tracker.
- Neutral: les gates restent des fichiers (`validated: yes`, `Ship allowed: yes`) ; le tracker porte l'état, jamais le verdict.
