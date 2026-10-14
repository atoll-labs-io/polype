---
adr: 0080
title: Tout arrive sur la branche cible par une PR, en fast-forward, et aucun agent ne pousse sur elle
status: accepted
date: 2026-10-13
scope: framing
supersedes: [ADR-0015]
superseded-by: [ADR-0081]
---

# ADR-0080 — Tout arrive sur la branche cible par une PR, en fast-forward

## Context and Problem Statement
Avec `Merge mode: local`, le ship squashe la story dans `Target branch` sur la machine puis pousse : un agent écrit directement sur `main`, et le cadrage y est commité de la même façon. Le 2026-10-13, le cadrage M9 est resté local, sans PR, et les worktrees partis de `origin/main` n'auraient pas vu les stories. Le porteur veut que `main` ne bouge que par des PR, quelle que soit l'autorisation de merge, et un historique linéaire sans commit de merge.

## Considered Options
- **Garder `local` et le squash direct (ADR-0015).** Rapide, mais un agent pousse sur `main` et rien n'y passe par une PR.
- **PR par story, squash merge côté forge.** Une story = un commit, mais la forge recrée le commit : ce n'est pas un fast-forward, et l'empreinte du commit change entre la branche et `main`.
- **PR par story, rebase des commits bruts.** Linéaire, mais une story porte 2 à 4 commits (code, revue, preuves de QA, fix runs) et l'historique perd « une story = un commit ».
- **PR par story, branche écrasée en un commit, rebasée, puis mergée en fast-forward.** Retenu.

## Decision Outcome
Chosen option: **chaque story arrive par une PR dont la branche est écrasée en un commit `<id>: <titre>`, rebasée sur `Target branch`, puis mergée en fast-forward**, parce que `main` ne bouge que par des PR, reste linéaire, et chaque story s'y annule d'un seul revert.

- Le ship écrase `story/<id>` en un commit, la rebase sur `Target branch`, la pousse, ouvre la PR et la merge en fast-forward (« Rebase and merge » côté forge).
- `Ship confirmation: automatic` → l'agent merge la PR quand `po-gate ship-allowed` passe et que les checks sont verts. `human` → il ouvre la PR, passe aux autres voies, et la personne merge.
- Aucun agent ne pousse jamais sur `Target branch`. Les commits de cadrage (brief, PRD, stories, ADR, architecture, design system, journal des décisions) et de réglage passent aussi par une branche et une PR.
- Un dépôt sans remote n'a pas de forge : le fast-forward se fait localement, rien n'est poussé.
- La gate `ship-allowed` ne change pas : aucune PR n'est mergée sans elle.

### Consequences
- Good, because chaque arrivée sur `main` laisse une PR, et l'historique reste un commit par story, sans commit de merge.
- Bad, because une story ne démarre qu'une fois sa PR de cadrage mergée sur la forge : `/po-research` part de `origin/<Target branch>`, qui doit déjà contenir la story.
- Bad, because une PR qui attend un merge humain pendant que `Target branch` avance doit être rebasée à nouveau : `story/<id>` est alors repoussée avec `--force-with-lease`, sur la branche de story seulement, jamais sur `Target branch`.
- Neutral: s105 porte le ship, s106 le cadrage et les réglages ; ADR-0079 (s102) s'appuie sur ce chemin pour la ligne `Ship confirmation` réécrite.
