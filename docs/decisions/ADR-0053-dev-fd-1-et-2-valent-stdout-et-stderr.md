---
adr: 0053
title: Pour po-bounds, /dev/fd/1 et /dev/fd/2 valent /dev/stdout et /dev/stderr comme cibles de redirection
status: accepted
date: 2026-10-08
tags: [adr, polype, review, hooks, bounds]
scope: story s77-last-review-leftovers
supersedes: [ADR-0052]
superseded-by: []
---

# ADR-0053 — /dev/fd/1 et /dev/fd/2 valent /dev/stdout et /dev/stderr

## Context and Problem Statement
ADR-0052 laisse passer trois cibles de redirection d'un appel git du dépôt jetable sans les résoudre : `/dev/null`, `/dev/stdout` et `/dev/stderr`. La revue de s76 (m2) relève que `git -C <sonde> log >/dev/fd/1` est refusé avec un message qui ne nomme pas la règle (`/dev/fd/1 is a symbolic link` sous Linux, « hors du répertoire temporaire » sous macOS), alors que bash l'écrit au même endroit que `/dev/stdout`. ADR-0052 range un geste légitime refusé parmi les défauts du hook. Cette ADR remplace **en partie** ADR-0052, sur la seule liste de ces cibles ; tout le reste d'ADR-0052 tient.

## Considered Options
- **Laisser le refus, avec un message qui nomme la règle** : le hook reste aussi strict, mais une sonde qui écrit `>/dev/fd/2` est toujours bloquée pour rien.
- **Ajouter `/dev/fd/1` et `/dev/fd/2` à la liste** : retenu. Ce sont les deux noms que bash et le système donnent à la sortie standard et à la sortie d'erreur ; leur sens ne dépend pas de la plateforme.
- **Accepter tout `/dev/fd/<n>`** : écarté. Un descripteur au-delà de 2 peut avoir été ouvert plus tôt sur un fichier du checkout (`exec 3>…`), et `>/dev/fd/3` y écrirait.
- **Résoudre `/dev/fd/<n>` par `readlink`** : écarté. `/dev/fd` est un lien vers `/proc/self/fd` sous Linux et un système de fichiers à part sous macOS ; le hook lirait ses propres descripteurs, pas ceux du shell de l'agent.

## Decision Outcome
Chosen option: **ajouter `/dev/fd/1` et `/dev/fd/2` à la liste**, parce qu'ils ne nomment rien d'autre que `/dev/stdout` et `/dev/stderr`, et qu'un refus sans raison coûte une revue bloquée.

- **Cible d'une redirection, dépôt jetable** (mode `reviewer`) : la règle d'ADR-0052 tient, la liste des cibles qui ne se résolvent pas devient `/dev/null`, `/dev/stdout`, `/dev/stderr`, `/dev/fd/1` et `/dev/fd/2`. Tout autre `/dev/fd/<n>` se résout comme un chemin et reste refusé hors du répertoire temporaire.

### Consequences
- Good, because `git -C <sonde> log >/dev/fd/1` et `… 2>/dev/fd/2` passent comme leurs équivalents `/dev/stdout` et `/dev/stderr`.
- Bad, because un `exec 1>…` lancé par une commande antérieure redirige aussi `/dev/fd/1`. Ce trou est celui que `/dev/stdout` avait déjà ; ADR-0052 l'accepte avec les autres contournements délibérés.
- Neutral: ADR-0052 garde `status: accepted` et nomme cette ADR dans `superseded-by`, son corps inchangé.
