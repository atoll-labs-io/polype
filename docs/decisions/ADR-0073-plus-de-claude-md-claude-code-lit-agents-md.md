---
adr: 0073
title: L'installeur n'écrit plus de CLAUDE.md, Claude Code lit AGENTS.md lui-même
status: superseded
date: 2026-10-09
scope: installer
supersedes: []
superseded-by: [ADR-0086]
---

# ADR-0073 — Plus de CLAUDE.md : Claude Code lit AGENTS.md

## Context and Problem Statement
Depuis s36 (parité H02 de `install.sh`), `init` et `install` créent un `CLAUDE.md` et y ajoutent `@AGENTS.md`, parce que Claude Code ne lisait que `CLAUDE.md`. Depuis la v2.1.277 (2026-09-18), Claude Code lit `AGENTS.md` comme instructions du projet, mais **seulement quand aucun `CLAUDE.md` ni `CLAUDE.local.md` n'existe** dans le dossier de travail ou au-dessus (https://code.claude.com/docs/en/memory, section « AGENTS.md »). Le pont ne sert donc plus, et `/po-setup` faisait committer un fichier que l'ignore git global de l'auteur exclut exprès, au point qu'un agent l'a forcé avec `git add -f` dans clout.

## Considered Options
- **Garder le pont.** Rien à changer, et les versions antérieures à 2.1.277 restent servies. Écarté : il maintient un fichier inutile dans chaque projet et dans chaque commit de setup, et il désactive la lecture native d'`AGENTS.md`.
- **Ne plus l'écrire, sans toucher aux projets déjà installés.** Le plus court, mais un projet installé avant garde son `CLAUDE.md` à une ligne jusqu'à un `remove`.
- **Ne plus l'écrire, et retirer l'ancienne ligne à chaque pose comme au retrait.** Retenu.

## Decision Outcome
Chosen option: **ne plus écrire de `CLAUDE.md` et retirer l'ancienne ligne `@AGENTS.md` à chaque `init`, `install`, `update` et `remove`**, parce que c'est la seule option qui laisse chaque projet, ancien ou nouveau, dans l'état où Claude Code lit `AGENTS.md` sans intermédiaire.

- Un `CLAUDE.md` qui ne contenait que la ligne est supprimé ; s'il contenait autre chose, seule la ligne part.
- Un `CLAUDE.md` sans la ligne appartient au projet : l'installeur n'y touche pas.
- `/po-setup` ne committe plus `CLAUDE.md` et interdit de le faire.

### Consequences
- Good, because un setup ne produit plus de fichier qui ne contient qu'un renvoi, et Claude Code charge `AGENTS.md` directement, worktrees de story compris puisque le fichier y est committé.
- Bad, because une version de Claude Code antérieure à 2.1.277, ou une session où la lecture d'`AGENTS.md` est désactivée (`/config` → « Project instructions »), ne voit plus les règles. Le remède est de mettre Claude Code à jour ou de réactiver le réglage, pas de rétablir le pont.
- Bad, because un projet qui garde son propre `CLAUDE.md` désactive la lecture d'`AGENTS.md` ; il doit y importer `@AGENTS.md` lui-même ou régler « Project instructions » sur `claude-md-and-agents-md`.
- Neutral: les mentions de `CLAUDE.md` dans les stories, plans et revues passés (s36, s37, s39, s45) décrivent l'état d'alors et restent telles quelles.
