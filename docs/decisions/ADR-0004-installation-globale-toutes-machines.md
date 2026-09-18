---
adr: 0004
title: Installation globale synchronisée sur toutes les machines
status: accepted
date: 2026-09-18
deciders: [lecrabe]
tags: [adr, polype, distribution]
supersedes: []
superseded-by: []
---

# ADR-0004 — Installation globale synchronisée sur toutes les machines

## Context and Problem Statement
Polype remplace `/spec` et `/drive`, qui sont des skills globaux. L'outil doit être disponible et identique sur chaque machine de travail.

## Considered Options
- **Par projet** — installé dans chaque repo, comme le mode par défaut de Killer SaaS.
- **Global, synchronisé par chezmoi** — installé dans `~/.claude`, suivi par les dotfiles.
- **Les deux** — global pour les commandes, un `init` par projet pour les templates et règles.

## Decision Outcome
Chosen option: **Global, synchronisé par chezmoi**, avec un `init` par projet qui dépose les règles et le fichier de settings, parce que la méthode doit suivre sur toutes les machines sans réinstallation manuelle.

### Consequences
- Good, because une mise à jour de la méthode atteint toutes les machines par la synchro des dotfiles.
- Bad, because une version globale unique : un projet ne peut pas épingler une ancienne version de la méthode.
- Neutral: la migration retire `/spec` et `/drive` une fois Polype validé sur un projet pilote.
