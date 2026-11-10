---
adr: 0102
title: Le rapport de QA revient en texte, et le contexte qui coordonne l'écrit
status: accepted
date: 2026-11-10
scope: story s156-qa-report-returned-as-text
supersedes: [ADR-0029]
superseded-by: []
---

# ADR-0102 — Le rapport de QA revient en texte, et le contexte qui coordonne l'écrit

## Context and Problem Statement
L'outil Write de Claude Code (version 2.1.322) refuse, dans un subagent seulement, tout fichier dont le nom de base répond à `report*.md` (aussi `summary`, `findings`, `analysis`) : « Subagents should return findings as text ». Or l'agent `qa` devait écrire `docs/qa/<id>/report.md`. Trois projets l'ont constaté (#88 sur lophelia, #148 sur nacre, clione et lagon) : les captures sont écrites, le rapport ne l'est pas, `/po-qa` ne trouve rien à committer et la marche est perdue. Il faut dire qui écrit le rapport.

## Considered Options
- **`qa` rend son rapport comme réponse, et le contexte qui coordonne le transcrit mot pour mot par un heredoc quoté** — le chemin même que le harnais demande ; `/po-drive` transcrit déjà ainsi la réponse du reviewer.
- **L'agent écrit le rapport par Bash** — contourne un refus du harnais ; deux routes différentes ont déjà été prises sur le terrain (#148), et `qa.md` interdit d'atteindre par une autre route ce qu'un garde a refusé.
- **Write pour `/po-qa`, comme `/po-review`** — une commande sans Write ni Edit n'édite aucun fichier du dépôt, et `/po-drive` transcrit déjà les revues par Bash : un second mécanisme pour la même chose.
- **Renommer le rapport pour que son nom échappe au garde** — esquive une règle dont l'intention est explicite, et déplace un chemin que lisent `po-gate qa-current`, la revue, `/po-status` et `/po-retro`.

## Decision Outcome
Chosen option: **`qa` rend son rapport comme réponse finale**, rempli sur `templates/qa.md` et rien d'autre, et continue d'écrire ses preuves sous `docs/qa/<id>/`. Le contexte qui coordonne — `/po-qa`, `/po-drive`, et `/po-orchestrator` à travers `/po-qa` tel qu'il est écrit — écrit cette réponse mot pour mot dans `docs/qa/<id>/report.md` par un heredoc quoté, seulement quand elle porte une ligne `QA status:`, puis fait le commit `<id>: QA evidence`. Le chemin du rapport et le commit restent ceux d'ADR-0029 et d'ADR-0034.

Cet ADR remplace ADR-0029 sur un seul point : le Bash de `/po-qa` passe d'un usage (le commit) à deux (la transcription et le commit) ; `/po-qa` n'a toujours ni Write ni Edit. Il complète ADR-0034 sans le remplacer.

Pourquoi un heredoc quoté est permis ici alors que `/po-ship` interdit tout heredoc pour le texte d'une revue : `/po-ship` envoie ce texte vers le tracker, à travers des arguments de commande ; ici le texte va dans un fichier, et rien de plus. Avec `<<'DELIM'`, rien ne s'y développe ; le seul risque restant est une ligne du rapport égale au délimiteur, qui finirait le heredoc trop tôt. Le délimiteur est donc choisi absent du rapport, et le texte n'entre jamais dans un argument de commande (Law 7).

### Consequences
- Good, because le rapport existe enfin après une marche, et la gate `qa-current` lit le même chemin qu'avant.
- Good, because aucun garde n'est contourné : le harnais demande précisément que le subagent rende ses constats en texte.
- Bad, because le Bash de `/po-qa` a un usage de plus, que seule sa consigne borne.
- Neutral: un préambule que `qa` mettrait avant son rapport serait transcrit aussi ; la gate ne lit que la dernière ligne `QA status:` et son `Tree:`, donc elle tient, mais `qa.md` demande le rapport seul.
