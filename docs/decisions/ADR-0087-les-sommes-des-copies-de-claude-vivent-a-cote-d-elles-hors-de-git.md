---
adr: 0087
title: Les sommes des copies de .claude/ vivent à côté d'elles, hors de git
status: accepted
date: 2026-10-14
scope: story s123-local-copy-checksums
supersedes: []
superseded-by: []
---

# ADR-0087 — Les sommes des copies de `.claude/` vivent à côté d'elles, hors de git

## Context and Problem Statement
`.polype/checksums`, commité, garde le `cksum` de chaque fichier posé, copies de `.claude/` comprises. Dans Polype, pecten et nautile, `.claude/` n'est pas commité. Quand une mise à jour arrive par une PR, `.polype/checksums` décrit déjà la nouvelle version alors que les copies de chaque checkout sont restées à l'ancienne. `polype update` les prend pour des retouches, les laisse en place et les signale, et cela ne se résout jamais : 5 à 23 copies par projet le 2026-10-14.

## Considered Options
Les deux options sont du shell dans `bin/polype`, sans dépendance. Elles se départagent sur la simplicité et sur ce qu'il faut savoir de l'histoire de la méthode.

- **A. Un fichier de sommes local.** Les sommes des copies de `.claude/` vont dans `.claude/.polype-checksums`, que git ignore. `.polype/checksums` ne garde que ce que git suit. Chaque checkout compare ses copies à ce qu'il a lui-même posé. Retenue.
- **B. Reconnaître toute version publiée.** Une copie identique à n'importe quelle version déjà livrée de la méthode compte comme intacte. Écartée : plus lourd, et il faut l'historique de toutes les versions publiées.

## Decision Outcome
Option choisie : **A**, retenue par le porteur le 2026-10-14. Chaque checkout juge ses copies d'après ce qu'il a posé, quelle que soit la façon dont `.polype/` lui est arrivé.

- L'installeur s'assure que `.claude/.polype-checksums` est ignoré. Si git ne l'ignore pas déjà, il ajoute la ligne au `.gitignore` du projet.
- `polype check` lit les deux fichiers.
- Un projet installé avant ce changement est migré au premier `update` : ses copies qui correspondent encore à `.polype/checksums` comptent comme intactes.
- Une copie identique au fichier que l'installeur livre n'est jamais une retouche. Cette règle protège un projet qui commite `.claude/`, ce que l'installeur recommande pour `install <projet>` : une PR qui rafraîchit les copies elles-mêmes ne les fait pas passer pour modifiées.
- La pose globale ne change pas : elle n'est dans aucun dépôt.

### Consequences
- Good, because une mise à jour livrée par PR ne laisse plus de copies bloquées à l'ancienne version.
- Bad, because l'état d'une pose projet tient désormais en quatre fichiers, dont un hors de `.polype/`.
- Neutral: un checkout déjà bloqué au moment de la migration voit encore ses copies périmées signalées une fois. `polype install <projet>` les remet à neuf ; c'était le cas que B aurait couvert.
