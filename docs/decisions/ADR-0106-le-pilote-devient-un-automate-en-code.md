---
adr: 0106
title: Le pilote devient un automate en code
status: proposed
date: 2026-11-12
scope: framing
supersedes: []
superseded-by: []
---

# ADR-0106 — Le pilote devient un automate en code

## Context and Problem Statement
`/po-drive` est une machine à états écrite en prose (environ 5 400 mots) qu'un modèle réinterprète à chaque vague : étape d'une lane, porte à passer, départ d'un fix run, ordre des ships. Chaque écart d'interprétation a été corrigé par une règle de plus, et rien ne prouve le comportement, seulement la présence des phrases (`docs/defauts.md`, motif récurrent). `po-session` dérive déjà une partie de cet état en bash, pour l'affichage. Il faut décider dans quel langage et à quel endroit vit l'automate qui dérive l'état et calcule la prochaine action (#203) ; le modèle garde ce qui demande du jugement : écrire, planifier, relire.

## Considered Options
Classées par les critères du porteur : libre ou auto-hébergeable, sobre en matériel, capable de grandir, facile à manier pour une IA.

1. **bash et jq, à côté des hooks existants** (`method/hooks/po-state.sh`) — même langage que les portes, les bornes et l'installeur, aucune dépendance de plus (`jq` est déjà requis), posé et versionné par l'installeur comme les autres hooks, testé par la suite existante. Un automate de plus de quelques centaines de lignes devient pénible à lire en bash, et bash ne vérifie rien avant l'exécution.
2. **Un binaire Rust** — compilateur strict, types pour les états et les transitions, sortie JSON sûre : le choix que M17 recommande à un projet (ADR-0097). Demande une chaîne de compilation, une distribution par plateforme et un installeur qui pose un binaire au lieu de fichiers lisibles ; les hooks restent en bash, donc deux langages.
3. **Un programme sur le Claude Agent SDK** (TypeScript ou Python) — l'automate lance lui-même les agents, sans session Claude Code pour le porter. Lie Polype à un fabricant, alors que la méthode vise tout harness (ADR-0005), ajoute un runtime, et remplace les subagents et les hooks sur lesquels les bornes reposent.
4. **Garder la prose et la raccourcir** — aucun outil nouveau. Ne change pas la nature du problème : un modèle continue d'interpréter l'automate.

## Decision Outcome
Proposé, à trancher par le porteur. Recommandation : **l'option 1, avec un seuil de sortie écrit d'avance**. L'automate dérive l'état et calcule la prochaine action ; il ne lance aucun agent, ce que la session Claude Code continue de faire en lisant sa sortie. C'est le plus petit pas qui retire l'interprétation, et il se prouve par des cas rejoués : un état de dépôt, une action attendue. Le seuil : si `po-state.sh` dépasse 800 lignes, ou si un second harness doit le lancer hors de bash, l'option 2 est reprise par une nouvelle ADR, la table des cas servant alors de spécification.

### Consequences
- Good, because une règle de routage devient une ligne dans une table de cas, et un changement de règle un diff lisible.
- Good, because `/po-status`, `po-session` et un agent extérieur lisent le même état (ADR-0107).
- Bad, because la parité avec le pilote en prose est à établir cas par cas, et un cas oublié change le comportement de la flotte.
- Neutral: `/po-drive` reste une commande, réduite à exécuter ce que l'automate lui dit.
