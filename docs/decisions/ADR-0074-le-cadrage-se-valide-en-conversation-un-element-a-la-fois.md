---
adr: 0074
title: Le cadrage se valide en conversation, un élément à la fois
status: accepted
date: 2026-10-13
scope: framing
supersedes: []
superseded-by: []
---

# ADR-0074 — Le cadrage se valide en conversation, un élément à la fois

## Context and Problem Statement
`/po-brief` et `/po-prd` demandent de lire le document « de bout en bout », `/po-stories` fait relire tout `docs/stories.md`, `/po-architect` soumet toutes ses ADR et ses conventions en une seule question. Sur un jalon, cela fait jusqu'à une vingtaine de fichiers à ouvrir d'un coup. L'humain doit fouiller les sources pour valider ce qui est justement la phase la plus importante : celle qui rend la suite autonome.

## Considered Options
- **Garder la relecture des fichiers.** Contrôle maximal, mais la charge décourage une lecture attentive et l'approbation devient un tampon.
- **Valider par lots de trois.** Plus rapide sur un gros jalon, mais un élément faible se cache derrière deux bons.
- **Approuver seuls les éléments triviaux.** Moins de questions, mais l'agent décide de ce qui mérite un regard, alors que ce tri est justement le rôle de l'humain au cadrage.
- **Un élément par question, à partir d'un résumé.** Retenu.

## Decision Outcome
Chosen option: **un élément par question, à partir d'un résumé**, parce que c'est la seule option où chaque décision reçoit une vraie attention sans que l'humain ouvre un seul fichier.

- Chaque story, chaque ADR et chaque section du brief ou du PRD est soumise seule : le quoi, le pourquoi, les options écartées (ADR) ou les critères (story), puis Approuver / Modifier / Écarter.
- Le résumé vise court, mais il s'allonge quand le sujet l'exige : on ne retire jamais une information nécessaire pour tenir une longueur.
- L'agent rédige les fichiers après l'approbation, sans demander de relecture. Une erreur de rédaction se corrige après coup.
- Le `stories-reviewer` reste un contrôle automatique et ne remonte que ses findings critiques, un par un, de la même façon.

### Consequences
- Good, because l'humain valide le fond sans jamais lire de markdown, et le fichier reste la trace complète.
- Bad, because l'humain approuve un résumé : une divergence entre le résumé et le fichier passe inaperçue jusqu'à ce qu'un stade aval la lise. La revue des stories et les gates aval restent là pour la rattraper.
- Neutral: les commandes gardent leurs gardes (`status: approved`, commit sur `Target branch`) ; seule la façon de recueillir l'accord change.
