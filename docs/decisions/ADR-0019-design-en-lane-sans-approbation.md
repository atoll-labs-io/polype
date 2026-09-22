---
adr: 0019
title: Un design produit dans une lane part sans approbation humaine
status: accepted
date: 2026-09-22
deciders: [lecrabe]
scope: story s35-fleet-design
tags: [adr, polype, flotte, design, autonomie]
supersedes: []
superseded-by: []
---

# ADR-0019 — Un design produit dans une lane part sans approbation humaine

## Context and Problem Statement
La flotte gagne un subagent `designer` pour qu'une story avec écran traverse sa lane sans arrêt (défaut n° 24). Or `/po-design` se termine par une approbation humaine, et un subagent ne demande rien à personne : il faut dire qui approuve la note d'écran qu'une lane vient d'écrire, sous peine de rendre à la vague l'interruption qu'on lui enlève.

## Considered Options
- **Un réglage `Design validation` à lui seul** — miroir de `Plan validation` : sous `human`, la vague s'arrête sur chaque écran. Cela ajoute un réglage à installer, à documenter et à lire partout, pour retrouver sous sa valeur `human` exactement l'arrêt que la story supprime.
- **Plier le design dans la question groupée des plans (ADR-0017)** — une seule question pour la vague. Mais la lane dessine après avoir planifié : au moment où la question part, aucune note d'écran n'existe encore, et la poser après reviendrait à ouvrir une seconde question groupée par vague.
- **Aucune approbation en lane, le rapport de vague le dit** — la note est écrite, enregistrée, lue par l'implementer, et le rapport nomme chaque story dont personne n'a relu le design.

## Decision Outcome
Chosen option: **Aucune approbation en lane, le rapport de vague le dit**, parce que la flotte a déjà choisi ce régime pour les plans sous `Plan validation: autonomous` : le travail avance, et ce qui n'a pas été relu est nommé au lieu d'être tu.

Ce qui vaut désormais :
- Le subagent `designer` écrit `docs/designs/<id>/design.md` et, pour un écran nouveau, son artefact unique ; il n'attend aucune approbation et consigne ses doutes dans le `## Gaps` de la note.
- `/po-design`, la commande lancée par un humain, garde son approbation : c'est le chemin story par story, celui d'`/po-orchestrator`.
- Le rapport de `/po-drive` nomme, story par story, les designs qu'aucun humain n'a approuvés, comme il le fait déjà pour les plans.

### Consequences
- Good, because une story avec écran va du plan à la revue sans qu'un humain ait à intervenir au milieu d'une vague.
- Bad, because un écran que personne n'a regardé peut atteindre la revue : c'est le visage du produit, et la revue de design juge l'intention, pas le goût.
- Neutral: si ce régime se révèle trop lâche, le repli est le réglage `Design validation` écarté ici ; la note reste de toute façon modifiable en relançant `/po-design`.
