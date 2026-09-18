---
adr: 0005
title: Support de Codex différé d'environ un mois
status: accepted
date: 2026-09-18
deciders: [lecrabe]
tags: [adr, polype, multi-outil]
supersedes: []
superseded-by: []
---

# ADR-0005 — Support de Codex différé d'environ un mois

## Context and Problem Statement
Killer SaaS cible Claude Code et Codex. Supporter les deux dès le départ double la surface à tester pendant la phase où la méthode change le plus.

## Considered Options
- **Codex dès le départ** — parité immédiate.
- **Claude Code seul, Codex vers mi-octobre 2026** — porter une fois la méthode stabilisée.
- **Claude Code seul, définitivement.**

## Decision Outcome
Chosen option: **Claude Code seul, Codex vers mi-octobre 2026**, parce que le portage coûte moins cher sur une méthode qui ne bouge plus.

### Consequences
- Good, because une seule cible à éprouver pendant la conception.
- Bad, because un portage à faire plus tard, avec les écarts de garanties (permissions et subagents moins stricts côté Codex).
- Neutral: pour que ce portage reste bon marché, les règles vivent dès maintenant dans `AGENTS.md` (lu nativement par les deux outils), les skills suivent le standard `SKILL.md`, et les gates restent des scripts shell sur du markdown, jamais des permissions propres à Claude.
