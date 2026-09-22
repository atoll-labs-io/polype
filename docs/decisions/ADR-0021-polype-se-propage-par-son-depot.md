---
adr: 0021
title: Polype se propage par son dépôt git, pas par chezmoi
status: accepted
date: 2026-09-22
deciders: [lecrabe]
tags: [adr, polype, distribution]
supersedes: [ADR-0004]
superseded-by: []
---

# ADR-0021 — Polype se propage par son dépôt git, pas par chezmoi

## Context and Problem Statement
ADR-0004 prévoyait une installation globale « synchronisée par chezmoi ». À l'installation réelle, la question s'est posée fichier par fichier : les 18 commandes, les 5 subagents et les 8 skills posés dans `~/.claude/` sont des copies engendrées depuis `method/`, et les dotfiles de la machine ne suivent que ce que l'utilisateur écrit lui-même.

## Considered Options
- **Suivre les fichiers installés dans chezmoi** — une machine reçoit Polype avec ses dotfiles, sans cloner le dépôt ; mais les dotfiles se remplissent de copies régénérables, et deux sources peuvent diverger (une version dans les dotfiles, une autre dans `method/`).
- **Propager par le dépôt** — chaque machine clone ou met à jour `polype`, puis lance `polype install --global` ; chezmoi ne suit que les fichiers écrits à la main.
- **Publier une archive versionnée** — plus tard, si l'installation depuis le dépôt devient pénible.

## Decision Outcome
Chosen option: **Propager par le dépôt**, parce qu'une copie engendrée n'a pas à vivre dans les dotfiles, et que l'installeur sait déjà reposer la méthode à l'identique depuis sa source.

### Consequences
- Good, because il n'existe qu'une source de vérité, `method/`, et `polype check` sait dire si une machine a dérivé.
- Bad, because une machine sans le dépôt n'a pas Polype : la propagation attend que ce dépôt ait un remote.
- Neutral: remplace le volet « synchronisé par chezmoi » d'ADR-0004 ; l'installation globale elle-même, et le fait que la méthode vive dans `~/.claude/`, restent valables. `docs/installation.md` décrit la marche à suivre sur une nouvelle machine.
