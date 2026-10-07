---
adr: 0027
title: Le designer et /po-design héritent des outils de la session, navigateur compris
status: accepted
date: 2026-10-07
scope: story s58-designer-browser
supersedes: []
superseded-by: []
---

# ADR-0027 — Le designer et /po-design héritent des outils de la session, navigateur compris

## Context and Problem Statement
Le designer (`method/agents/designer.md:4`) déclare `tools:` et `/po-design` déclare `allowed-tools` ; ni l'un ni l'autre ne contient d'outil navigateur, alors que tous deux doivent ouvrir la maquette dans le navigateur de la session (défaut n° 33). ADR-0026 a réglé la même question pour l'agent QA ; il reste à choisir ce que le designer s'interdit, la forme de la commande, et si son périmètre d'écriture passe à un hook.

## Considered Options
- **Ajouter un outil navigateur nommé à chaque liste** — lie la méthode à un outil précis, ce que s51 et s58 interdisent.
- **Garder les listes telles quelles** — le défaut reste : la maquette n'est jamais regardée.
- **Designer sans `tools:`, `disallowedTools: AskUserQuestion, NotebookEdit` ; `/po-design` sans `allowed-tools`** — les deux héritent de la session, navigateur compris quel qu'il soit ; le designer perd la question (il ne demande rien, ADR-0019) et l'écriture de notebooks, garde Write, Edit et Bash.
- **Désinterdire aussi `Agent` et `WebFetch` au designer** — un subagent ne lance pas de subagent, et WebFetch ne sort pas du worktree : liste plus longue sans borne de plus.
- **Ajouter un mode `designer` à `po-bounds`** pour limiter Write et Edit à `docs/designs/<id>/` — `method/hooks/po-bounds.sh` et `tests/bounds.test.sh` sont hors du `Owns` de s58 ; c'est une story à part.

## Decision Outcome
Chosen option: **designer sans `tools:` avec `disallowedTools: AskUserQuestion, NotebookEdit`, et `/po-design` sans `allowed-tools`**, parce que c'est la seule forme qui atteint le navigateur sans en nommer un, et qu'elle reprend celle qu'ADR-0026 a déjà acceptée pour la QA.

### Consequences
- Good, because n'importe quel outil navigateur de la session sert au designer comme à `/po-design`, et la section « Seen and not seen » ne dit plus « pas de navigateur » par construction.
- Bad, because le designer hérite aussi des autres outils de la session (WebFetch, un serveur MCP qui écrit) ; sa borne d'écriture reste la prose de `## Limits`, comme avant, aucun hook ne la tient.
- Bad, because `bin/po-lint` ne vérifie plus que `/po-design` déclare AskUserQuestion : un fichier sans déclaration d'outils est sauté.
- Neutral: si `allowed-tools` d'une commande ne fait que pré-autoriser sans restreindre, retirer la liste ne coûte que des demandes de permission pendant `/po-design`. Un mode `designer` de `po-bounds` reste à confier à une story.
