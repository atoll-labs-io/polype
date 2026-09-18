---
adr: 0002
title: Les ADR d'un projet vivent dans son repo
status: accepted
date: 2026-09-18
deciders: [lecrabe]
tags: [adr, polype, decisions]
supersedes: []
superseded-by: []
---

# ADR-0002 — Les ADR d'un projet vivent dans son repo

## Context and Problem Statement
Jusqu'ici les ADR vivent dans le vault Obsidian avec un pointeur Graphiti. Les workers de la flotte travaillent dans un worktree, sans accès garanti au vault : une décision qu'ils ne lisent pas est une décision qu'ils réinventent.

## Considered Options
- **Vault + Graphiti** — l'existant, canonique hors du repo.
- **Repo seul** — `docs/decisions/` dans le projet.
- **Repo + pointeur Graphiti** — canonique dans le repo, pointeur daté dans Graphiti pour la recherche transverse.

## Decision Outcome
Chosen option: **Repo + pointeur Graphiti**, parce que la décision voyage avec le code qu'elle gouverne et reste lisible par tout agent qui a le repo, tandis que Graphiti garde la recherche entre projets.

### Consequences
- Good, because un worker lit les ADR depuis son propre arbre, à la version de sa branche.
- Bad, because `/record-adr` (qui écrit dans le vault) doit apprendre ce mode ; d'ici là, les ADR de projet s'écrivent à la main au même format.
- Neutral: le vault reste le lieu des décisions transverses ou personnelles, hors d'un repo de projet.
