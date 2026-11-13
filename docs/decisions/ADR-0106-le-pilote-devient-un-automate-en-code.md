---
adr: 0106
title: Le pilote devient un automate en code
status: accepted
date: 2026-11-13
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
Chosen option: **l'option 2, un binaire Rust, dès maintenant**, tranché par le porteur le 2026-11-13. La recommandation était l'option 1 avec un seuil de sortie vers Rust à 800 lignes. Ce seuil aurait sans doute été atteint dès la première version complète de l'automate (`po-bounds.sh` compte déjà 855 lignes, `po-gate.sh` 677) : le porteur préfère écrire l'automate une seule fois, dans le langage où les états et les transitions sont vérifiés avant l'exécution, plutôt que de le réécrire quelques stories plus tard.

Ce qui ne change pas avec le langage : l'automate dérive l'état et calcule la prochaine action, il ne lance aucun agent, ce que la session Claude Code continue de faire en lisant sa sortie ; il se prouve par des cas rejoués — un état de dépôt, une action attendue ; les hooks existants (`po-gate`, `po-bounds`, `po-run`, `po-intake`, `po-session`) restent en bash.

Deux choix techniques en découlent et restent au porteur avant que `/po-stories` reprenne M21 : la façon de construire et de distribuer le binaire, et la liste des scripts de M21 qui y entrent (`docs/a-trancher.md`, D11 et D12).

### Consequences
- Good, because une règle de routage devient un cas dans une table et une branche que le compilateur oblige à traiter, et un changement de règle un diff lisible.
- Good, because `/po-status`, `po-session` et un agent extérieur lisent le même état (ADR-0107).
- Bad, because Polype gagne une chaîne de compilation et une distribution par plateforme, l'installeur doit poser un binaire, et la méthode tient désormais en deux langages.
- Bad, because s164, s168 et s170, écrites pour bash, sont reprises par `/po-stories` avant tout plan, ce qui retarde M21.
- Bad, because la parité avec le pilote en prose est à établir cas par cas, et un cas oublié change le comportement de la flotte.
- Neutral: `/po-drive` reste une commande, réduite à exécuter ce que l'automate lui dit.
