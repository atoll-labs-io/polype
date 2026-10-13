---
adr: 0086
title: Aucun CLAUDE.md dans un projet, l'installeur absorbe celui qu'il trouve dans AGENTS.local.md
status: accepted
date: 2026-10-13
scope: story s115-no-claude-md
supersedes: [ADR-0073]
superseded-by: []
---

# ADR-0086 — Aucun CLAUDE.md dans un projet : l'installeur l'absorbe

## Context and Problem Statement
ADR-0073 a cessé d'écrire le pont `CLAUDE.md` → `@AGENTS.md` et n'en retire que la ligne d'import, en laissant au projet le reste du fichier. Or Claude Code ne lit `AGENTS.md` que si aucun `CLAUDE.md` ni `CLAUDE.local.md` n'existe. Un projet qui garde quelques notes dans son `CLAUDE.md` perd donc toutes les règles de Polype, sans que rien ne le signale : nautile a failli les perdre ainsi. Il faut que plus aucun projet n'ait de `CLAUDE.md`, sans perdre ce qu'il contenait.

## Considered Options
Les options sont du texte de méthode et du shell, sans dépendance ; elles se départagent sur la friction et sur le risque de perdre des règles.

- **A. L'installeur absorbe le fichier.** `init`, `install` et `update` déplacent le contenu d'un `CLAUDE.md` ou d'un `CLAUDE.local.md` racine, sans la ligne `@AGENTS.md`, à la fin d'`AGENTS.local.md` sous `## Notes moved from CLAUDE.md`, puis suppriment le fichier et le disent. Le pre-commit refuse tout `CLAUDE.md` ajouté ou modifié, et `po-session` signale celui qui reste. Retenue.
- **B. S'arrêter et demander à la main.** L'installeur refuse de continuer tant qu'un `CLAUDE.md` existe. Écartée : une friction à chaque projet, pour un déplacement qu'une machine fait sans risque.
- **C. Garder le reste du fichier (ADR-0073).** Écartée : c'est le défaut de nautile, un `CLAUDE.md` résiduel désactive la lecture d'`AGENTS.md`.

## Decision Outcome
Option choisie : **A**, retenue par le porteur le 2026-10-13. C'est la seule qui laisse chaque projet sans `CLAUDE.md` et sans perte, sans demander d'effort au porteur.

- Ce qui reste d'ADR-0073 tient toujours : l'installeur n'écrit jamais de `CLAUDE.md`, et `/po-setup` n'en committe jamais.
- Le seul `CLAUDE.md` est le global de l'utilisateur (`~/.claude/CLAUDE.md`), que l'installeur ne touche jamais, pose globale comprise.
- Un fichier qui ne contenait que l'import est supprimé sans rien ajouter.
- `AGENTS.local.md` absent : l'installeur ne le crée pas, puisque `/po-setup` le crée et refuse de tourner s'il existe déjà. L'absorption est alors sautée et dite, le fichier reste tel quel, et le reste de la pose continue ; `/po-setup` puis `polype update .` l'absorbent. Arrêter toute la commande bloquerait un projet neuf, car `/po-setup` lit son gabarit dans `.polype/templates/`, que pose `init`.
- `remove` garde le comportement d'ADR-0073 : il retire seulement l'ancienne ligne d'import.

### Consequences
- Good, because aucun projet ne garde de `CLAUDE.md` qui masque `AGENTS.md`, et ses notes passent dans `AGENTS.md` dès la pose qui les absorbe.
- Bad, because l'installeur écrit désormais dans `AGENTS.local.md`, qu'il ne faisait que lire ; il n'y fait qu'ajouter, jamais réécrire.
- Neutral: un `CLAUDE.md` en sous-dossier n'est pas absorbé, seulement refusé au commit ; les mentions de `CLAUDE.md` dans les stories, plans et revues passés restent telles quelles.
