---
adr: 0136
title: cd et les commandes de lecture entrent dans la liste de permissions d'un passage réel
status: superseded
date: 2026-11-23
scope: story s207-real-run-is-usable
supersedes: [ADR-0135]
superseded-by: [ADR-0137]
---

# ADR-0136 — cd et les commandes de lecture entrent dans la liste de permissions d'un passage réel

## Context and Problem Statement
[ADR-0135](ADR-0135-gh-entre-dans-la-liste-de-permissions-d-un-passage-reel.md) fixe la liste de permissions d'un passage réel. Claude Code juge chaque morceau d'une commande composée, et la Law 4 impose `cd <worktree> && git …` à tout sous-agent. `cd` n'étant pas dans la liste, et toute demande étant refusée (`--permission-prompts none`), les deux implementers du premier passage réel (2026-11-23, `docs/evals/real-2026-11-23-v0.12.0.md`) se sont arrêtés à leur première commande : le flux de session porte quatre événements `permission_denied` sur `Bash`, tous chez des sous-agents.

## Considered Options
- **A. Élargir par une liste explicite** : `cd`, `cat`, `ls`, `wc`, `cksum`, `sed -n`, `grep`, `head`, `tail`, `diff` et `mktemp` entrent dans la liste ; rien d'autre.
- **B. Passer la session en `bypassPermissions`** : plus aucune liste, tout est permis sauf ce que `deny` refuse.

## Decision Outcome
Option choisie : **A**, par le porteur le 2026-11-23, notée dans la story s207-real-run-is-usable. Elle remplace ADR-0135 sur ce seul point : la liste tient désormais `git`, `gh`, `bash`, `sh`, `jq`, le `po` de la configuration, `.polype/hooks/*`, `cd`, `cat`, `ls`, `wc`, `cksum`, `sed -n`, `grep`, `head`, `tail`, `diff`, `mktemp`, les outils de fichiers limités au dossier du passage et l'outil Agent. Le reste d'ADR-0134 et d'ADR-0135 tient tel quel : refus des outils web, de `curl` et de `claude`, demandes refusées, passage lancé et regardé par une personne, et la limite de C1.

Option écartée :
- **B** : elle ôterait toute trace de ce qu'un agent de la méthode a besoin de lancer. Un refus y redevient impossible à voir, alors qu'il est justement ce que le premier passage a montré.

Aucune autre commande n'entre sans une nouvelle décision du porteur.

### Consequences
- Good, because un sous-agent qui suit la Law 4 peut entrer dans son worktree et lire ses fichiers, et un échec du passage redevient un signe sur la méthode.
- Bad, because `cat`, `head`, `tail`, `grep` et `diff` lisent tout chemin que la personne atteint, au-delà du dossier où l'outil Read est borné. C'était déjà vrai par `bash -c`, comme ADR-0134 l'admet ; c'est désormais permis sans détour.
- Neutral: seul un passage réel montre que Claude Code accepte `cd <chemin> && git …` quand chaque morceau est permis, et que `Bash(sed -n:*)` laisse passer `sed -n` sans laisser passer `sed -i`.
