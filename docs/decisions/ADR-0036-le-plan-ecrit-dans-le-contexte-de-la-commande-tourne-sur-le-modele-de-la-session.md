---
adr: 0036
title: Le plan et le design écrits dans le contexte d'une commande tournent sur le modèle de la session
status: accepted
date: 2026-10-08
scope: story s59-model-by-complexity
supersedes: []
superseded-by: []
---

# ADR-0036 — Le plan et le design écrits dans le contexte d'une commande tournent sur le modèle de la session

## Context and Problem Statement
ADR-0032 veut que le planner et le designer tournent toujours sur `Model strong`. Seul `/po-drive` les lance comme subagents (`subagent_type: planner`, `subagent_type: designer`). `/po-orchestrator` écrit la recherche, le design et le plan dans son propre contexte, et `/po-flow` fait recherche et plan dans le sien pour ne payer que trois contextes. Une commande ne choisit pas le modèle du contexte qui l'exécute : il faut décider ce que ces deux chemins font du modèle fort.

## Considered Options
- **Faire lancer un planner (et un designer) en subagent par `/po-orchestrator` et `/po-flow`** — le modèle fort serait garanti partout, mais `/po-flow` perd sa raison d'être (un contexte de plus), et l'orchestrateur change de forme, ce qui dépasse s59.
- **Faire vérifier à la commande son propre modèle et s'arrêter s'il n'est pas `Model strong`** — un modèle ne peut pas prouver son identité à partir d'un fichier ; la vérification serait une déclaration, pas une preuve.
- **Laisser ces étapes dans le contexte de la commande, sur le modèle de la session, et le dire** — la commande écrit que le plan et le design qu'elle produit tournent sur le modèle de la session, conseille de lancer la session sur `Model strong`, et ne passe `Model strong` qu'aux subagents qu'elle lance réellement.

## Decision Outcome
Chosen option: **laisser ces étapes dans le contexte de la commande, sur le modèle de la session, et le dire**, parce que la forme à trois contextes de `/po-flow` et la séquence de `/po-orchestrator` sont des choix établis, et qu'une vérification de modèle invérifiable donnerait une fausse garantie. `/po-drive` reste le chemin où chaque rôle qui décide reçoit `Model strong` sans dépendre de la session.

### Consequences
- Good, because aucun contexte n'est ajouté et aucune garantie n'est affirmée sans preuve.
- Bad, because une session lancée sur un modèle léger produit, par `/po-orchestrator` ou `/po-flow`, un plan écrit sur ce modèle léger.
- Neutral: si l'écart se voit dans les fix runs, une story pourra faire lancer un planner en subagent par l'orchestrateur, en remplaçant cet ADR.
