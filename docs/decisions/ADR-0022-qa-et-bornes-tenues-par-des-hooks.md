---
adr: 0022
title: Une étape QA en lecture seule, et des bornes de subagent tenues par des hooks
status: accepted
date: 2026-10-07
deciders: [lecrabe]
tags: [adr, polype, cycle, gates]
supersedes: []
superseded-by: []
---

# ADR-0022 — Une étape QA en lecture seule, et des bornes de subagent tenues par des hooks

## Context and Problem Statement
L'étude de gstack et d'agent-skills ([référence](../references/gstack-agent-skills.md)) montre deux trous que M6 veut fermer. Ce que l'utilisateur verra n'est vérifié que par une consigne à l'implementer (« ouvre l'écran dans un navigateur »), sans preuve. Et la ligne `Owns`, comme les verbes git interdits par la Loi 4, ne sont tenus que par la prose : la revue constate un débordement après coup, elle ne l'empêche pas. Les deux réponses touchent la forme du cycle et la façon dont Polype contraint ses agents : elles demandent une décision.

## Considered Options
- **QA par l'implementer** — il ouvre lui-même l'écran avant de committer ; c'est l'état actuel, et c'est l'auteur qui juge son propre écran (contraire à la Loi 2).
- **QA qui corrige** (`/qa` de gstack) — un agent trouve, corrige et revérifie ; celui qui juge écrit, ce que la Loi 2 interdit.
- **QA en lecture seule entre execute et review** — un subagent sans Edit écrit seulement `docs/qa/<id>/`, la revue exige un rapport au même arbre ; une story sans écran ne voit rien changer.
- **Bornes vérifiées en revue seulement** — l'état actuel ; un débordement coûte une boucle de correction.
- **Hooks globaux dans `settings.json`** — tiendraient tous les agents, mais toucheraient chaque session de la machine, Polype ou non, et sortiraient du dépôt.
- **Hooks PreToolUse dans le frontmatter des subagents** — `po-bounds`, posé sous `.polype/hooks/` comme `po-gate`, actif seulement pour l'implementer et la QA, avec un mode par agent.

## Decision Outcome
Chosen option: **QA en lecture seule entre execute et review**, et **hooks PreToolUse dans le frontmatter des subagents**, parce qu'ils ferment les deux trous sans relâcher la Loi 2 et sans rien imposer hors des agents de Polype. L'étape QA est activée par le réglage `QA stage` ; les hooks échouent fermés : un script introuvable ou une entrée illisible valent un refus (code 2).

### Consequences
- Good, because l'écran d'une story arrive en revue avec des preuves, et un débordement de `Owns` est refusé au moment de l'écriture.
- Good, because le mécanisme suit la même logique que `po-gate` : un script dans le dépôt, que n'importe quel outil peut appeler.
- Bad, because la vague de la flotte passe de quatre à cinq subagents pour une story avec écran, et une QA dépend d'un outil navigateur qui varie d'une session à l'autre.
- Bad, because la tenue des hooks dépend de la façon dont Claude Code honore un bloc `hooks:` dans le frontmatter d'un subagent ; s50 le vérifie avant d'écrire quoi que ce soit.
- Neutral: les redirections de Bash ne sont pas analysées ; la revue garde son contrôle d'ownership. À revoir si un débordement passe par là.
