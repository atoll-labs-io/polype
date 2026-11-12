---
adr: 0109
title: Une seule commande fait avancer le travail
status: proposed
date: 2026-11-12
scope: framing
supersedes: []
superseded-by: []
---

# ADR-0109 — Une seule commande fait avancer le travail

## Context and Problem Statement
Le cycle d'une story se lance aujourd'hui à trois niveaux qui se recouvrent : sept commandes d'étape (`/po-research` à `/po-ship`), deux commandes de story (`/po-orchestrator`, `/po-flow`) et la flotte (`/po-drive`), soit dix commandes et environ 18 000 mots. Chaque niveau redit en prose le routage du niveau d'en dessous, et chaque écart entre deux redites est devenu un constat de revue (#139, #172, #180, #181, #193). L'ordre lui-même diffère d'un niveau à l'autre : la Law 1 place le design avant le plan, la flotte fait passer le designer après le planner, ce qui a produit #184. Un agent extérieur, lui, n'a besoin que d'un point d'entrée (`run`, ADR-0107). Quand l'automate de s168 calcule la prochaine action, il faut décider combien de commandes restent. Les étapes et leurs portes ne sont pas en question : plan validé, relevé à jour, QA, revue par un autre que l'auteur, ship.

## Considered Options
Classées par les critères du porteur ; les deux premiers ne départagent rien ici, restent la capacité à grandir et la facilité pour une IA.

1. **Une entrée, des étapes** — `/po-drive` fait avancer tout ce qui est prêt et `/po-drive <id>` une seule story ; `/po-orchestrator` et `/po-flow` disparaissent, la voie courte devenant une valeur que l'automate lit et non une commande ; les commandes d'étape restent, réduites au brief de leur subagent, pour reprendre une étape à la main. `/po-ship`, qui ne fait que des opérations déterministes, devient un script que la commande appelle (#211). Un seul endroit dit l'ordre des étapes : la table de cas de l'automate.
2. **Garder les trois niveaux, alimentés par l'automate** — aucune habitude ne change. Trois textes continuent de décrire le même parcours, et le majordome a trois façons de lancer.
3. **Une entrée, plus aucune commande d'étape** — le moins de texte. Reprendre une seule étape à la main demande alors de passer par l'automate, y compris pour déboguer la méthode.

## Decision Outcome
Proposé, à trancher par le porteur. Recommandation : **l'option 1, après s168**, et pas avant : retirer des commandes tant que le routage vit dans leur prose déplacerait le problème. L'ordre retenu est celui de la Law 1 : recherche, design, plan avec son oracle, exécution, QA, revue, ship ; la flotte s'y aligne par la table de cas. La cérémonie d'une story de complexité 1 ou 2 ne baisse pas en retirant des portes, mais en contextes et en mots lus : un planner (recherche et plan en une passe), un implementer, un relecteur, soit le minimum que permet la Law 2.

### Consequences
- Good, because l'ordre des étapes n'est écrit qu'à un endroit, et un agent extérieur n'a qu'une commande à faire lancer.
- Bad, because ceux qui lancent `/po-orchestrator` ou `/po-flow` changent d'habitude, et `docs/`, `/po-help` et les projets installés sont à mettre à jour.
- Neutral: la chaîne de cadrage n'est pas touchée ici (ADR-0110) ; `/po-status`, `/po-retro` et `/po-intake` restent des commandes, les deux premières lisant `po-state`.
