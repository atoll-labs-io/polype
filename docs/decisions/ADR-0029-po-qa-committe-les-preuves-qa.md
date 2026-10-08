---
adr: 0029
title: /po-qa committe seul docs/qa/<id>/, et la revue n'exige la QA que sous QA stage screens
status: accepted
date: 2026-10-08
tags: [adr, polype, qa, gates, cycle]
scope: story s52-qa-wiring
supersedes: []
superseded-by: []
---

# ADR-0029 — /po-qa committe seul docs/qa/<id>/, et la revue n'exige la QA que sous QA stage screens

## Context and Problem Statement
ADR-0022 veut que la revue exige un rapport QA au même arbre que le code. Il faut donc que `docs/qa/<id>/` voyage sur `story/<id>` avant la revue, et qu'une gate dise si ce rapport est à jour. Or l'agent `qa` ne peut pas committer (mode `qa` de `po-bounds`, liste blanche de verbes git qui lisent, ADR-0026), et s51 avait livré `/po-qa` sans shell. Reste à dire qui committe, et quand la revue exige la gate, puisque `QA stage` vaut `—` par défaut.

## Considered Options
- **`/po-qa` reçoit Bash pour un seul usage : committer `docs/qa/<id>/` seul** — la commande qui a lancé la QA committe sa preuve, comme `/po-ship` committe la revue ; elle n'a toujours ni Write ni Edit.
- **`/po-ship` committe `docs/qa/<id>/` avec la revue** — `/po-qa` reste sans shell, mais le rapport reste non committé pendant la revue et pendant chaque boucle de correction ; la revue juge un arbre qui ne le porte pas.
- **Une exception `git add/commit -- docs/qa/<id>` dans le mode `qa` de `po-bounds`** — élargit une liste blanche de verbes qui lisent (ADR-0026) à un verbe qui écrit ; c'est l'agent qui juge l'écran qui écrirait l'historique.
- **L'implementer committe la QA au run suivant** — la preuve d'une story sans boucle de correction ne serait jamais committée.
- **La revue exige `qa-current` pour toute story avec écran** — bloque chaque story avec écran d'un projet sans QA (`QA stage: —`).
- **La revue exige `qa-current` seulement quand `QA stage` vaut `screens`** — un projet sans QA ne voit aucune différence.

## Decision Outcome
Chosen option: **`/po-qa` committe `docs/qa/<id>/` seul**, et **la revue n'exige `qa-current` que sous `QA stage: screens`**, parce que la preuve est committée au moment où elle existe, sans élargir le hook d'un agent qui juge, et sans rien changer pour un projet qui n'a pas activé la QA. La gate `po-gate qa-current` elle-même ne lit aucun réglage : comme `verif-current`, elle ne fait que comparer un fichier au code ; c'est le reviewer qui décide de l'appeler.

### Consequences
- Good, because le rapport et ses captures sont dans l'arbre que le reviewer juge, et le squash de `/po-ship` les emporte.
- Good, because `po-bounds` et l'agent `qa` restent tels que s51 les a livrés.
- Bad, because `/po-qa` perd la garantie « par construction » de s51 : son Bash peut tout faire, et seule sa consigne le limite au commit de `docs/qa/<id>/` (commit restreint par chemin, `-- docs/qa/<id>/`).
- Neutral: `qa-current` n'exige pas que le rapport soit committé ; un rapport non committé à jour passe. À revoir si `/po-drive` (s57) s'y fie pour reprendre une lane.
