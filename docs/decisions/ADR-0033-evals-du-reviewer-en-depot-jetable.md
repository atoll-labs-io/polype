---
adr: 0033
title: Les evals du reviewer lancent l'agent seul dans un dépôt jetable et lisent ses lignes de verdict
status: accepted
date: 2026-10-08
scope: story s55-reviewer-evals
supersedes: []
superseded-by: []
---

# ADR-0033 — Les evals du reviewer lancent l'agent seul dans un dépôt jetable et lisent ses lignes de verdict

## Context and Problem Statement
Les tests de Polype ne vérifient que le texte de la méthode, jamais ce que fait un agent qui l'applique. s55 doit lancer le reviewer sur des stories piégées et en mesurer le taux de bons verdicts. Il faut choisir comment l'agent est lancé, quelle copie de la méthode il lit, et qui note le résultat ; chaque run coûte et ne se répète pas à l'identique.

## Considered Options
- **`claude -p "/po-review <id>"` dans le dépôt de fixture** — exerce la commande réelle, mais la pression ne peut pas passer par le message de lancement : `$ARGUMENTS` doit être un id exact, et la commande ajoute une couche (le contexte qui délègue) entre la pression et le reviewer.
- **Les agents de l'installation globale (`~/.claude/`)** — rien à poser, mais on mesure la version installée sur la machine, pas le `method/` qu'une story est en train de changer.
- **`--agents` avec la définition du reviewer passée en JSON** — indépendant de toute installation, mais il faut reconstruire à la main le préchargement des skills, et l'éval ne mesure plus l'agent tel qu'il est posé.
- **Un juge LLM qui lit le rapport** — note la qualité des constats, mais rend la note elle-même non déterministe et double le coût ; les deux lignes de verdict suffisent à décider ce qui compte : le ship est-il bloqué, à quel niveau.
- **`claude -p --agent reviewer` dans un dépôt temporaire où `bin/polype install` a posé le `method/` de ce checkout, avec le message de lancement de `/po-review` et la pression ajoutée ; note par les dernières lignes `Max severity:` et `Ship allowed:`, lues comme `po-gate` les lit.**

## Decision Outcome
Chosen option: **la dernière**, parce qu'elle mesure exactement le reviewer et les skills de ce checkout, avec le message que la méthode lui envoie vraiment, et une notation mécanique identique à celle de la gate qui décide du ship.

### Consequences
- Good, because une modification de `method/agents/reviewer.md` ou d'une skill de revue se mesure avant d'être livrée, et le taux par modèle (`--model`) nourrit le seuil d'ADR-0032.
- Good, because rien n'est écrit dans le dépôt Polype : chaque run reconstruit son dépôt de fixture et le jette.
- Bad, because une copie utilisateur d'une skill du même nom peut masquer celle du projet : `po-eval` refuse de lancer quand `~/.claude` (ou `CLAUDE_CONFIG_DIR`) contient une copie différente de `method/`.
- Bad, because le chemin `/po-review` → subagent n'est pas exercé ; un écart entre le lancement direct et la délégation ne serait pas vu.
- Neutral: si `--agent` ne précharge pas les `skills:` de l'agent en session principale, les rapports gardés par `po-eval` le montreront ; il faudra alors passer par une délégation via l'outil Agent, dans un nouvel ADR.
