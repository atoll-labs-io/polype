---
adr: 0055
title: Le réglage Platform est une liste séparée par des virgules, chaque plateforme admet ses surfaces, et un profil écrit sa plateforme sur une ligne que po-lint vérifie
status: accepted
date: 2026-10-08
tags: [adr, polype, platforms, stories, profiles, m8]
scope: story s78-platform-setting
supersedes: []
superseded-by: []
---

# ADR-0055 — Chaque plateforme admet ses surfaces

## Context and Problem Statement
ADR-0054 crée le réglage `Platform` (une liste parmi `web`, `mobile`, `cli`, `api`, `lib`, `xr`, `robot`) et la ligne `Surface` d'une story. Elle laisse ouverts trois points dont dépendent `/po-setup`, `/po-stories`, `stories-review` et `bin/po-lint` :
- comment s'écrit la liste ;
- quelles surfaces une plateforme admet, puisque `stories-review` doit signaler en majeur une surface qui ne va pas avec les plateformes du projet ;
- comment un profil de boilerplate écrit la sienne pour que `/po-setup` filtre le catalogue.

## Considered Options
- **Liste séparée par des virgules, comme `Owns`** : retenue. `Platform: web, api`, valeurs en minuscules.
- **Une ligne `Platform` par plateforme** : écartée. `missing_settings` et chaque lecteur prennent la première ligne d'un nom ; la deuxième serait perdue.
- **Valeur du gabarit `web`** : retenue. Jusqu'à M7 tout projet Polype était web (ADR-0054, contexte) ; un projet qui se met à jour lit `missing setting: Platform: web`, la valeur qu'il avait sans l'écrire.
- **Valeur du gabarit `—`** : écartée. ADR-0054 ne liste pas `—` parmi les plateformes ; chaque lecteur devrait traiter un « non déclaré ».
- **Table stricte des surfaces admises** : retenue.
  - `screen` va avec `web` et `mobile`.
  - `command` va avec `cli`.
  - `endpoint` va avec `api` et `lib`.
  - `scene` va avec `xr`.
  - `behaviour` va avec `robot`.
  - `—` va avec toutes.

  Un projet web qui sert aussi une API déclare `web, api`.
- **Toute surface sur toute plateforme** : écartée. Le contrôle majeur de `stories-review` n'aurait plus rien à vérifier.
- **`web` admet aussi `endpoint`** : écartée. Ce serait une exception cachée qu'aucune autre plateforme n'aurait, alors que déclarer `api` suffit et dit aux pilotes de QA qu'un `curl` vaut.
- **Ligne `- Platform: <liste>` dans une section `## Platform` du profil, valeurs vérifiées par `po-lint` contre la ligne `Platform` de la table du gabarit de réglages** : retenue. La liste des valeurs n'est écrite qu'une fois, dans `templates/agents-local.md`.
- **Section `## Platform` libre, seule sa présence exigée** : écartée. Un profil qui écrit `Web` ou `website` passerait la lint et ne serait jamais proposé par `/po-setup`, sans que personne le voie.

## Decision Outcome
Chosen option: **liste séparée par des virgules, gabarit à `web`, table stricte des surfaces, ligne `- Platform:` vérifiée par `po-lint`**, parce que chaque lecteur (setup, stories, revue des stories, lint) décide alors sans interpréter de prose.

La table des surfaces admises est écrite une seule fois, dans la skill `agentic-stories`. La vérification 9 de `stories-review` et `/po-stories` la citent.

### Consequences
- Good, because une surface hors plateforme est un écart mécanique, et un profil mal déclaré casse la lint au lieu de disparaître du catalogue.
- Bad, because un projet web avec des routes d'API doit penser à déclarer `api` ; sinon `stories-review` signale ses stories `endpoint` en majeur.
- Neutral: `po-lint` lit les valeurs admises dans les mots en minuscules entre backticks de la ligne `| Platform |` du gabarit de réglages ; cette ligne ne doit pas en contenir d'autres.
