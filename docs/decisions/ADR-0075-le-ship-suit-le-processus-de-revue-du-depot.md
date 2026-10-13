---
adr: 0075
title: Le ship suit le processus de revue du dépôt, réglé au setup et tenu à jour
status: accepted
date: 2026-10-13
scope: pipeline
supersedes: []
superseded-by: []
---

# ADR-0075 — Le ship suit le processus de revue du dépôt

## Context and Problem Statement
Le gabarit de `AGENTS.local.md` met par défaut `Merge mode: pr`, `Plan validation: human` et `Ship confirmation: human`. Un projet mené par une seule personne reçoit donc une question par merge, alors que les stories sont approuvées et que la gate `ship-allowed` a déjà prouvé la revue. À l'inverse, un dépôt où d'autres personnes relisent doit attendre leur PR.

## Considered Options
- **Lire la forge à chaque ship, sans réglage.** Suit le dépôt automatiquement, mais un solo qui veut relire ses PR ne peut pas le dire.
- **Un réglage posé au setup, figé.** Simple et prévisible, mais il ne voit pas un collaborateur qui arrive ou une protection de branche ajoutée.
- **Un réglage posé au setup depuis la forge, modifiable, et tenu à jour quand les règles du dépôt changent.** Retenu.

## Decision Outcome
Chosen option: **le réglage posé au setup depuis la forge et tenu à jour**, parce qu'il respecte à la fois le choix de la personne et les règles que le dépôt impose.

- `/po-setup` lit la forge (revue obligatoire en protection de branche, `CODEOWNERS`, autre collaborateur avec droit d'écriture) et propose `Ship confirmation`. La personne confirme ou change la valeur, et peut la modifier à tout moment.
- La valeur porte son origine : `(forge)` quand elle vient du dépôt, `(choisi)` quand la personne l'a fixée.
- À chaque ship, la forge est relue. Si elle exige désormais une revue, le réglage passe à `human (forge)`, la ligne est commitée et le rapport le signale. Si elle ne l'exige plus, il ne revient à `automatic` que si la valeur était `(forge)` : un `(choisi)` ne bouge jamais tout seul.
- Sous `human`, en mode `pr`, l'agent ouvre la PR et passe à la story suivante sans attendre ; il reprend le nettoyage quand le merge est prouvé.
- La gate `ship-allowed` ne change pas : aucune voie ne merge sans elle.

### Consequences
- Good, because un solo n'est plus sollicité pour merger ce que la gate a prouvé, et une équipe garde sa revue sans y penser.
- Bad, because cela assouplit la règle « an agent reads settings, it never decides them » : l'agent réécrit une valeur `(forge)`. Le changement est borné, puisqu'il ne fait que recopier une règle du dépôt, ne touche jamais un `(choisi)`, est commité et signalé.
- Neutral: les forges sans API lisible (Forgejo auto-hébergé sans jeton) gardent la valeur du setup et le rapport le dit.
