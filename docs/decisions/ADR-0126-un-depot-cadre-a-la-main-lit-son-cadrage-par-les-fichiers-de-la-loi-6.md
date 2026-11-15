---
adr: 0126
title: Un dépôt cadré à la main lit son cadrage par les fichiers de la loi 6
status: accepted
date: 2026-11-15
scope: story s184-session-shows-what-waits
supersedes: []
superseded-by: []
---

# ADR-0126 — Un dépôt cadré à la main lit son cadrage par les fichiers de la loi 6

## Context and Problem Statement
Sur ce dépôt, `po state` rend `stories review none · architecture missing` et `Framing next: /po-stories-review` alors que le jalon M22 est relu (`docs/reviews/stories-m22.md:79`, `Stories ready: yes`). `po` lit la revue dans `docs/reviews/stories.md` seul (`po/src/context/framing.rs:81-85`) et l'architecture dans `docs/architecture.md` seul (`framing.rs:86`) : les deux fichiers que la loi 6 nomme et que les commandes écrivent (`method/commands/po-stories-review.md:38`, `po-architect.md:68`). Ce dépôt n'a ni l'un ni l'autre, pour une seule raison : il tourne en `Entry mode: —`, et `/po-stories-review` refuse ce mode (`po-stories-review.md:26`). Le chef de projet tient donc depuis M13 des revues ponctuelles, une par jalon, sous des noms libres (`stories-m13.md`, `stories-m20-m21.md`, `stories-m21-s174.md`, `stories-m21-bis-s180.md` ; `docs/decisions-log.md:84`). Conséquence pratique : `po run` lance la commande de cadrage manquante au lieu de `/po-drive` (`po/src/run/mod.rs:165-167`), et un agent extérieur dit au porteur que le cadrage n'est pas fait. Deux questions distinctes sont à trancher (#244).

## Considered Options

### Question 1 — Où vit la revue des stories

Classement par les critères du porteur : les trois options sont du code ou des fichiers du dépôt, sans service ni matériel ; les deux premiers critères ne les départagent pas. Le troisième (grandir) et le quatrième (facile pour une IA) décident. Ordre : 1-B, 1-C, 1-A ; 2-A, 2-B.

- **1-B. Ce dépôt tient `docs/reviews/stories.md`** : la revue du jalon courant y est recopiée entière, et chaque revue à venir y remplace la précédente, comme `/po-stories-review` le fait (git garde les anciennes). Les fichiers par jalon restent en archive. `po` ne change pas pour #244.
  - Pour : une seule règle pour tous les projets, la même dans `po`, la loi 6, `/po-research:24` et `/po-orchestrator:31` ; un agent cherche un seul chemin. Aucun autre projet ne voit de différence.
  - Contre : une copie de 84 lignes entre `stories-m22.md` et `stories.md` ; le chef de projet de ce dépôt doit écrire ses revues ponctuelles dans `stories.md`, une habitude à changer que rien ne contrôle ; voir l'historique d'une revue demande `git log`.
- **1-C. La méthode passe aux revues par jalon** : `/po-stories-review` écrit `docs/reviews/stories-<jalon>.md`, `po` lit celle du jalon courant, la loi 6 et les commandes de cadrage changent.
  - Pour : sur un produit qui vit plusieurs jalons, chaque verdict reste lisible sans git, et `po` peut dire quel jalon est relu.
  - Contre : change une phrase de la loi 6 et trois commandes, hors du périmètre de s184 (une story à part, sa place naturelle étant M23 avec l'ordre du cadrage, ADR-0110) ; il faut une règle qui tire un nom de fichier d'un titre de jalon (`M21 bis` → `stories-m21-bis.md`), une règle de plus à appliquer pour chaque agent.
- **1-A. `po` reconnaît aussi `docs/reviews/stories-*.md`** quand `stories.md` manque, en prenant la plus récente.
  - Pour : rien ne change dans ce dépôt ni dans ses habitudes.
  - Contre : `po` lit un rangement qu'aucune commande ne produit et que seul ce dépôt pratique ; `/po-research` et `/po-orchestrator` continueraient à avertir « pas de revue » quand `po state` dirait `yes` ; « la plus récente » est à définir parmi des noms libres (`stories-m20-m21`, `stories-m21-s174`) et doit écarter `stories-intake-<horodatage>.md`, qu'écrit `/po-intake`.

### Question 2 — Ce que dit `architecture` en `Entry mode: —`

- **2-A. Rien ne change** : `architecture` reste `missing` tant que `docs/architecture.md` manque, quel que soit `Entry mode`. Ce dépôt écrit son `docs/architecture.md` (une carte qui renvoie à `docs/conception.md` et aux ADR), par une pull request de cadrage hors de s184, dont l'`Owns` ne le liste pas.
  - Pour : aucune règle nouvelle, aucun changement du contrat ; `/po-architect` reste exigé partout, ce que le porteur demande pour M23 (l'architecture se décide avec la personne).
  - Contre : ce dépôt reste à `architecture missing` jusqu'à cette pull request.
- **2-B. En `Entry mode: —`, `architecture` vaut `by hand`** comme `scope`, et ne retient plus le stade.
  - Pour : ce dépôt n'a rien à écrire.
  - Contre : `—` est la valeur du gabarit, qui veut dire « pas encore choisi » (`method/templates/agents-local.md:62`) ; un projet neuf qui oublie le réglage sauterait `/po-architect` sans que personne le voie. Une valeur nouvelle dans le contrat (`docs/interface-agent.md:96`).

## Decision Outcome
Options choisies : **1-B** et **2-A**, par le porteur le 2026-11-16 (décisions d-0030 et d-0031 de la boîte), comme cette ADR les recommandait. 1-B : ce dépôt tient `docs/reviews/stories.md`, comme tout autre projet, et `po` ne change pas sa lecture ; le porteur en connaissait le coût : rien ne contrôle l'habitude d'y écrire les revues suivantes, et les fichiers par jalon restent en archive. 2-A : `architecture` reste `missing` tant que `docs/architecture.md` manque, quel que soit `Entry mode` ; ce dépôt écrit son `docs/architecture.md` par une pull request de cadrage à part, hors de s184. 1-C reste la suite possible si un produit en a besoin, à cadrer dans M23. Les tâches du plan de s184 sont celles de 1-B et 2-A.

### Consequences
- Good, because `po state`, `/po-research` et `/po-orchestrator` lisent la même revue sur tous les projets.
- Bad, because ce dépôt garde une copie de sa revue de M22 et change d'habitude pour les suivantes.
- Neutral: même avec 1-B et 2-A, le cadrage de ce dépôt ne sera pas `done` : `design-system` reste `missing` parce que 77 stories anciennes n'ont pas de ligne `Surface` (`po/src/context/stories.rs:153-154`), et `/po-stories-review` continue de refuser `Entry mode: —`.
