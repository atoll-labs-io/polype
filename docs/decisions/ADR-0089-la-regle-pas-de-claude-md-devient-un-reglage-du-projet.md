---
adr: 0089
title: La règle « pas de CLAUDE.md » devient le réglage Project CLAUDE file, absorbed par défaut
status: accepted
date: 2026-10-14
scope: story s131-claude-md-rule-as-setting
supersedes: [ADR-0086]
superseded-by: []
---

# ADR-0089 — `Project CLAUDE file` : la règle de l'ADR-0086 se règle par projet

## Context and Problem Statement
L'ADR-0086 impose à tout projet de n'avoir aucun `CLAUDE.md` : l'installeur l'absorbe dans `AGENTS.local.md` et le pre-commit en refuse un à toute profondeur. C'est un choix du porteur pour ses projets, pas une nécessité de la méthode : Claude Code lit un `CLAUDE.md` qui importe `@AGENTS.md` aussi bien qu'un `AGENTS.md` seul. Une personne qui donne son contexte à Claude par un `CLAUDE.md` ne peut pas adopter Polype sans changer cette habitude (question d'un premier testeur extérieur, cadrage M11 du 2026-10-14).

## Considered Options
Les options sont du texte de méthode et du shell, sans dépendance ; elles se départagent sur ce que le projet garde et sur le risque que les règles de Polype ne soient plus lues.

- **A. Un réglage `Project CLAUDE file`, `absorbed` ou `kept`, que `/po-setup` écrit à `absorbed`.** `absorbed` est la règle de l'ADR-0086. `kept` laisse `CLAUDE.md` et `CLAUDE.local.md` en place ; l'installeur fait commencer le `CLAUDE.md` racine par la ligne `@AGENTS.md`, et le crée avec cette seule ligne quand seul un `CLAUDE.local.md` existe ; le pre-commit les laisse passer ; `po-session` ne les signale plus. Sans la ligne, rien n'est choisi à la place du projet. Retenue.
- **B. Garder la règle pour tous (ADR-0086 telle quelle).** Écartée : elle oblige chaque adoptant à renoncer à son `CLAUDE.md`, ce que le porteur ne veut pas imposer hors de ses projets.
- **C. `kept` sans la ligne d'import.** Écartée : Claude Code lit alors le `CLAUDE.md` à la place d'`AGENTS.md`, et les règles de Polype cessent d'être lues sans que rien ne le signale, le défaut même qui a fait naître l'ADR-0086.
- **D. Une ligne absente vaut `absorbed`.** Écartée : un agent ne remplit jamais un réglage manquant (`AGENTS.md`, « Reading settings »), et l'installeur ne fait que nommer les réglages qui manquent (ADR-0043). Le porteur a choisi `absorbed` comme valeur écrite par `/po-setup`, pas comme valeur implicite.
- **E. Détecter le choix : garder le fichier quand il contient autre chose que l'import.** Écartée : c'est l'ancien comportement de l'ADR-0073, et un fichier de notes ne dit pas si la personne veut le garder.

## Decision Outcome
Option choisie : **A**, décidée par le porteur le 2026-10-14 et inscrite dans `docs/stories.md` (M11) et `docs/decisions-log.md`.

- `absorbed` : l'installeur absorbe, le pre-commit refuse, `po-session` signale, exactement comme l'ADR-0086 le décrit.
- `kept` : l'installeur ne déplace et ne supprime aucun `CLAUDE.md` ni `CLAUDE.local.md`. Dès que l'un des deux existe à la racine, le `CLAUDE.md` racine commence par la ligne `@AGENTS.md`, seule occurrence de cette ligne dans le fichier, et rien d'autre n'y change. Un `CLAUDE.md` qui est un lien symbolique est laissé tel quel, et l'installeur le dit. Le pre-commit n'en refuse plus aucun, à aucune profondeur. `remove` retire la ligne `@AGENTS.md`, et le fichier s'il ne tenait qu'elle, comme il le fait déjà depuis l'ADR-0073.
- Ligne absente, ou valeur qui n'est ni `absorbed` ni `kept` : l'installeur ne touche à aucun `CLAUDE.md`, le pre-commit refuse comme aujourd'hui, et `check`, l'installeur et `po-session` nomment le réglage au lieu d'annoncer que `polype update` déplacera le fichier.
- La règle de l'ADR-0073 que l'ADR-0086 reprenait, « l'installeur n'écrit jamais de `CLAUDE.md` », ne tient plus qu'avec `absorbed` : avec `kept`, l'installeur y écrit la ligne d'import, ou crée le fichier pour elle.
- `/po-setup` pose la question à chaque projet et suggère `absorbed`. Avec `kept`, il committe le `CLAUDE.md` racine que git suit déjà, pour que la ligne d'import atteigne chaque clone ; un `CLAUDE.md` que git ne suit pas reste hors du commit, et un clone sans `CLAUDE.md` lit `AGENTS.md` de lui-même.

### Ce que devient un projet déjà installé
Son `AGENTS.local.md` n'a pas la ligne. Son prochain `update` la nomme parmi les réglages manquants et cesse d'absorber : un `CLAUDE.md` créé depuis reste en place tant que le projet n'a pas écrit `Project CLAUDE file: absorbed` ou `kept`. Son pre-commit continue de refuser. Polype reçoit la ligne `absorbed` dans cette story ; pecten et nautile la reçoivent dans la pull request qui leur apporte cette version.

### Consequences
- Good, because une personne garde son `CLAUDE.md` sans que les règles de Polype cessent d'être lues, et le défaut du porteur reste celui de l'ADR-0086.
- Bad, because un projet déjà installé n'absorbe plus rien tant qu'il n'a pas écrit la ligne, et trois composants (installeur, pre-commit, `po-session`) lisent un réglage de plus.
- Neutral: `docs/installation.md` décrit encore l'absorption sans condition jusqu'à s132 ; un `CLAUDE.md` en sous-dossier n'est jamais modifié, seulement refusé au commit avec `absorbed` ou sans la ligne.
