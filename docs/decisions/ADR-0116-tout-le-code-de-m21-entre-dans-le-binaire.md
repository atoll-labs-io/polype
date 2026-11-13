---
adr: 0116
title: Tout le code que M21 ajoute entre dans le binaire, les hooks restent en bash
status: accepted
date: 2026-11-13
scope: framing
supersedes: []
superseded-by: []
---

# ADR-0116 — Tout le code que M21 ajoute entre dans le binaire, les hooks restent en bash

## Context and Problem Statement
L'ADR-0106 met l'automate (l'état et la prochaine action) dans un binaire Rust et garde les hooks existants en bash. M21 ajoute d'autres scripts autour de l'automate, cadrés pour bash : la boîte de décisions, la réponse du porteur, l'écriture des rapports, la commande de l'agent extérieur (ADR-0107). Il faut fixer la frontière entre les deux langages (D12), car chaque story de M21 en tire ses `Owns` et ses tests.

## Considered Options
Classées par les critères du porteur : libre ou auto-hébergeable, sobre en matériel, capable de grandir, facile à manier pour une IA.

1. **Tout ce que M21 ajoute entre dans le binaire** (état, prochaine action, boîte, réponse, rapports, commande de l'agent extérieur), les hooks existants restant en bash — un seul langage pour le code nouveau, une seule commande à poser, des types partagés entre la boîte, la réponse et l'état.
2. **Seulement l'état et la prochaine action**, le reste de M21 en bash — binaire plus petit. Deux langages dans le même jalon, et le JSON que Rust produit est relu en `jq` : le contrat est écrit deux fois.
3. **Tout M21 et les hooks existants réécrits en Rust** — un seul langage. Rouvre des portes et des bornes qui tiennent, dont la parité serait à reprouver, et contredit l'ADR-0106.

## Decision Outcome
Chosen option: **l'option 1**, tranché par le porteur le 2026-11-13 : la réponse valide une option contre la boîte et l'agent extérieur lit l'état, ces scripts manipulent donc les mêmes structures ; les hooks (`po-gate`, `po-bounds`, `po-run`, `po-intake`, `po-session`) tiennent et ne sont pas rouverts.

### Consequences
- Good, because une réponse hors des options listées est refusée par du code que le compilateur a vérifié, et le contrat de [`interface-agent.md`](../interface-agent.md) n'est écrit qu'une fois.
- Bad, because les stories de M21 partagent un même crate : leurs `Owns` doivent être découpés pour que deux lanes ne se bloquent pas.
- Bad, because `po-session`, en bash, dérive déjà une partie de l'état : tant qu'il ne lit pas la sortie du binaire, deux lectures de l'état peuvent diverger.
- Neutral: le nom et le chemin de la commande que `interface-agent.md` donne sont repris par `/po-stories` (ADR-0107).
