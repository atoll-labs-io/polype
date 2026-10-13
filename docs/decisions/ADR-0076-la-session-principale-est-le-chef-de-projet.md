---
adr: 0076
title: La session principale d'un projet Polype en est le chef de projet
status: accepted
date: 2026-10-13
scope: pipeline
supersedes: []
superseded-by: []
---

# ADR-0076 — La session principale est le chef de projet

## Context and Problem Statement
Aujourd'hui, l'humain enchaîne lui-même les commandes : `/po-setup`, `/po-brief`, `/po-stories`, `/po-stories-review`, `/po-architect`, `/po-design-system`, puis `/po-drive` à relancer. Il est le chef d'orchestre. Il veut au contraire ouvrir une conversation sur un projet et parler à un interlocuteur unique, qui répond à ses questions et pilote les flottes jusqu'à ce que le jalon soit livré.

## Considered Options
- **Une nouvelle commande d'entrée.** Claire, mais il faut penser à la lancer ; une session ouverte sans elle retombe dans l'ancien rôle.
- **Étendre `/po-orchestrator` ou `/po-drive`.** Pas de nouveau fichier, mais un seul fichier porterait deux rôles, et le même oubli resterait possible.
- **Le rôle porté par `AGENTS.md`, nourri par un hook de début de session.** Retenu.

## Decision Outcome
Chosen option: **le rôle porté par `AGENTS.md` et un hook `SessionStart`**, parce qu'un comportement par défaut ne dépend pas de la mémoire de quiconque.

- `AGENTS.md`, que Claude Code charge nativement (ADR-0073), dit que la session principale est le chef de projet. Il répond aux questions de l'humain quoi qu'il arrive, enchaîne le cadrage en conversation (ADR-0074), puis lance `/po-drive` vague après vague jusqu'au bout du jalon.
- Un hook `SessionStart` donne au chef l'état du projet lu sur disque, comme `/po-status` : cadrage manquant, stories prêtes, voies en vol, escalades en attente.
- Les commandes `/po-*` sont ses outils ; l'humain peut toujours les lancer à la main.
- Law 2 tient : le chef planifie, délègue et rend compte, il n'écrit pas le code d'une story.
- Les worktrees de story ne sont pas concernés : un subagent n'est pas la session principale.

### Consequences
- Good, because l'humain n'a plus rien à taper pour que le projet avance, et la reprise après une coupure part de l'état sur disque, pas d'un souvenir.
- Bad, because une session ouverte pour une question ponctuelle porte aussi le rôle ; le chef répond d'abord à la question et ne relance la flotte que si le projet l'attend.
- Neutral: le même hook servira plus tard à Nautile pour pousser son contexte en début de session.
