---
adr: 0026
title: L'agent QA hérite du navigateur de la session, ne lit git que par une liste blanche, et date son rapport par l'arbre committé
status: accepted
date: 2026-10-07
tags: [adr, polype, qa, hooks, bounds]
scope: story s51-qa-agent
supersedes: []
superseded-by: []
---

# ADR-0026 — L'agent QA hérite du navigateur de la session, ne lit git que par une liste blanche, et date son rapport par l'arbre committé

## Context and Problem Statement
ADR-0022 veut une QA en lecture seule, bornée par `po-bounds` en mode `qa`, et s51 interdit de rien construire autour d'un navigateur particulier. Trois choix restent ouverts. Un subagent qui déclare `tools:` ne reçoit que les outils nommés, MCP compris : la QA n'atteindrait aucun navigateur sans en nommer un. Le mode `qa` doit refuser « tout verbe git qui écrit » sans qu'une liste dise lesquels. Et le `Tree:` du rapport ne peut pas se prendre comme celui du relevé de vérification (`git add -A` puis `git write-tree`), puisque `git add` écrit l'index.

## Considered Options
- **`tools:` qui nomme un outil navigateur** (`mcp__playwright__*`…) — lie la méthode à un outil, contraire à la story.
- **`tools:` sans navigateur** — la forme du designer ; la QA ne pourrait rien ouvrir.
- **Pas de `tools:`, `disallowedTools: Edit, NotebookEdit`** — la QA hérite des outils de la session, navigateur compris, quel qu'il soit ; Claude Code ignore `disallowedTools` dès qu'un `tools:` existe.
- **Liste noire des verbes git qui écrivent** — un verbe oublié (`restore`, `clean`, `update-ref`…) passe.
- **Liste blanche des verbes git qui lisent** — `status`, `diff`, `log`, `show`, `rev-parse`, `ls-files`, `ls-tree`, `cat-file`, `merge-base`, `grep`, `blame`, `describe`, `symbolic-ref`, `shortlog`, `worktree list` ; tout autre verbe, ou aucun, est refusé.
- **`Tree:` par `git write-tree`** — exige `git add`, donc une écriture.
- **`Tree:` par `git rev-parse 'story/<id>^{tree}'`**, avec arrêt si du code hors `docs/` n'est pas committé — la forme du reviewer ; l'arbre nomme le code committé que la QA a vu.

## Decision Outcome
Chosen option: **pas de `tools:` et `disallowedTools: Edit, NotebookEdit`**, **liste blanche des verbes git**, et **`Tree:` par `rev-parse` sur du code committé**, parce que chacun tient sans navigateur nommé et échoue fermé : un verbe inconnu est refusé, un code non committé arrête la QA au lieu de produire un rapport daté d'un arbre qu'elle n'a pas vu.

### Consequences
- Good, because n'importe quel outil navigateur de la session sert, et la story s52 compare ce `Tree:` avec `code_matches` comme pour la revue.
- Bad, because la QA hérite aussi des autres outils de la session (WebFetch, un éventuel serveur MCP qui écrit des fichiers) ; le hook ne voit que Write, Edit et Bash.
- Bad, because une capture est un fichier binaire que Write ne produit pas : elle arrive sous `docs/qa/<id>/` par l'option fichier de l'outil navigateur ou par une copie en Bash, que le hook n'analyse pas (ADR-0022, Neutral). La borne d'écriture tient pour Write, pas pour ces chemins-là.
- Bad, because une lecture git légitime absente de la liste (`git branch --show-current`) est refusée ; la QA reformule (`git rev-parse --abbrev-ref HEAD`).
- Neutral: le designer déclare `tools:` sans navigateur alors qu'on lui demande d'ouvrir sa maquette (`method/agents/designer.md:4`, `:33`) ; c'est un défaut hors de s51, à confier à une personne.
