---
adr: 0135
title: gh entre dans la liste de permissions d'un passage réel
status: accepted
date: 2026-11-23
scope: story s206-real-run-before-a-release
supersedes: [ADR-0134]
superseded-by: [ADR-0136]
---

# ADR-0135 — gh entre dans la liste de permissions d'un passage réel

## Context and Problem Statement
[ADR-0134](ADR-0134-un-passage-reel-se-lance-devant-une-personne-dans-une-configuration-confinee.md) fixe la liste de permissions de la configuration temporaire d'un passage réel, et `gh` n'y est pas. Or la méthode fait appeler `gh` directement par le chef de projet (`/po-intake`, `/po-setup`, `/po-drive`). Avec `--permission-prompts none`, un appel direct refusé laisse quatre cas sans issue pour un chef qui suit la méthode : `intake-security-issue`, `intake-listing-fails`, `intake-human-merge` et `framing-landing-human`. Chacun tombe alors à 0 dans les deux bras, et le résumé range le bras sous `moved no rate:`, ce qui sert d'entrée au retrait d'une règle.

## Considered Options
- **A. `gh` entre dans la liste** (`Bash(gh:*)`). Dans le passage, le premier `gh` du `PATH` est la doublure de forge, et aucun jeton de forge n'est dans l'environnement : rien de réel n'est atteint.
- **B. Garder `gh` refusé et retirer les quatre cas.**
- **C. Attendre le premier passage réel** pour voir si l'`allowed-tools: Bash` d'une commande lève le refus sous `-p`.

## Decision Outcome
Option choisie : **A**, par le porteur le 2026-11-23 (d-0060). Elle remplace ADR-0134 sur ce seul point : la liste de permissions tient désormais `git`, `gh`, `bash`, `sh`, `jq`, le `po` de la configuration, `.polype/hooks/*`, les outils de fichiers limités au dossier du passage et l'outil Agent. Le reste d'ADR-0134 tient tel quel : refus des outils web, de `curl` et de `claude`, demandes de permission refusées, passage lancé et regardé par une personne, et la limite de C1.

Options écartées :
- **B** : quatre règles d'arrêt et de sécurité perdraient leur cas, alors que le refus de `gh` ne protège de rien. `bash -c gh` passe déjà, et la doublure ne mène à aucune forge.
- **C** : un passage payant pourrait se dépenser sur des cas qui ne peuvent pas réussir. Si le refus tenait, il ferait aussi passer le résumé pour une preuve qu'une règle ne sert à rien.

### Consequences
- Good, because un chef qui suit la méthode peut réussir les cas de l'intake et de l'atterrissage du cadrage, et un échec y redevient un signe sur la règle.
- Bad, because un appel `gh` passe sans demande. Seuls la doublure en tête du `PATH` et l'absence de jeton empêchent qu'il atteigne une vraie forge. Un agent qui appellerait un autre `gh` par son chemin complet sortirait de ce cadre, comme ADR-0134 l'admet déjà pour tout programme.
- Neutral: la doublure `gh` du passage note chaque texte qu'un appel pourrait envoyer, et c'est ce que lit `no-text-in-forge`.
