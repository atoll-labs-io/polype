---
adr: 0091
title: La mise à jour garde le mode d'activation du projet, enregistré dans .polype/mode
status: accepted
date: 2026-10-14
scope: story s135-update-keeps-init-mode
supersedes: []
superseded-by: []
---

# ADR-0091 — La mise à jour garde le mode d'activation du projet, enregistré dans `.polype/mode`

## Context and Problem Statement
Un projet activé par `polype init` a 23 fichiers de projet ; `polype update <projet>` y posait les
commandes, les subagents et les skills, soit 65 fichiers (#73). Rien n'enregistrait le mode
d'activation : `update` partait toujours du mode `project`. Il faut que `update`, et l'indice que
donne po-session, sachent comment le projet a été activé. ADR-0087 décrit les fichiers d'état ;
celle-ci en ajoute un.

## Considered Options
- **A. Un fichier `.polype/mode`.** Un mot, `init` ou `project`, écrit à chaque pose de projet,
  commité avec `.polype/`, lu par `update` et par po-session ; déduit du manifeste quand il manque.
  Retenue.
- **B. La déduction seule (inference), depuis le manifeste.** Écartée : un projet déjà gonflé par
  l'ancien `update` se lit comme une pose complète, et le défaut se perpétue.
- **C. Une option `update --init`.** Écartée : on l'oublie, et le défaut revient au premier oubli.
- **D. Une deuxième ligne dans `.polype/version`.** Écartée : elle couple au mode tous ceux qui lisent
  le tampon de version (`check`, po-session).

## Decision Outcome
Chosen option: **A. Un fichier `.polype/mode`**, parce que c'est le seul état explicite qui survit à
un projet gonflé et ne touche aucun lecteur existant (décision du propriétaire, 2026-10-14).

### Consequences
- Good, because `polype update .` sur un projet activé par `init` le laisse à ses fichiers de projet,
  et les indices de l'installeur et de po-session nomment la bonne commande.
- Good, because `install <projet>` ne lit pas le mode : il reste le moyen explicite de passer en
  pose complète, et `polype init .` répare un projet gonflé en enregistrant `init`.
- Bad, because un projet a un fichier d'état de plus à commiter.
- Neutral: sans `.polype/mode`, la déduction (pas de ligne `.claude/commands/` au manifeste → `init`)
  couvre les projets posés avant cette version ; `check` ne signale pas son absence.
