---
adr: 0043
title: L'installeur signale les réglages manquants sans les écrire ni changer le code de sortie de check
status: accepted
date: 2026-10-08
scope: story s65-upgrade-path
supersedes: []
superseded-by: []
---

# ADR-0043 — L'installeur signale les réglages manquants sans les écrire ni changer le code de sortie de check

## Context and Problem Statement
Le gabarit `method/templates/agents-local.md` gagne des réglages au fil des stories (`QA stage`, `Dev`, puis `Model strong`, `Model light`, `Light up to` avec s59). L'installeur ne touche jamais l'`AGENTS.local.md` d'un projet, si bien qu'après une mise à jour les commandes qui lisent un réglage absent s'arrêtent sans que rien ne l'ait annoncé (revue de s59, majeur). Il faut décider comment l'installeur rend ces absences visibles, et ce que `check` en fait.

## Considered Options
- **Ajouter les lignes manquantes à `AGENTS.local.md`, avec la valeur du gabarit** — rien ne s'arrête plus, mais le fichier du projet cesse d'être à lui, et des valeurs comme `Merge mode: pr` ou `Issue tracker: github` seraient choisies à sa place, en silence.
- **Lister les absences et faire sortir `check` en 1** — visible en CI, mais `check` mélangerait l'intégrité des fichiers posés et la configuration du projet ; un projet sans `AGENTS.local.md` (pas encore de `/po-setup`) ou qui n'a pas besoin d'un réglage toléré (`QA stage` chez `/po-drive`) échouerait sans rien d'installé de travers.
- **Une sous-commande dédiée (`polype settings`)** — séparée et explicite, mais c'est une commande de plus que personne ne lance au moment où il le faudrait : juste après la mise à jour.
- **Lister les absences à chaque pose projet et dans `check`, sans écrire et sans toucher au code de sortie** — `install`, `init` et `update` sur un projet les nomment sur `stderr`, `check` sur `stdout`, chacune sous la forme `missing setting: <Nom>: <valeur du gabarit>`.

## Decision Outcome
Chosen option: **lister à chaque pose projet et dans `check`, sans écrire et sans changer le code de sortie**, parce que la liste paraît là où la mise à jour se fait — `init` compris, seule voie de rafraîchissement d'un projet servi par la pose globale — tandis que le choix des valeurs reste à la personne et que `check` garde un seul sens pour son code de sortie : les fichiers posés sont-ils intacts.

Règles : un réglage du gabarit est une ligne non vide d'un de ses blocs délimités par trois backticks, son nom le texte avant le premier `:`, sa valeur le texte après, espaces retirés. Il est présent quand une ligne d'`AGENTS.local.md` porte exactement ce nom avant son premier `:` (`Test budget` ne vaut pas `Test`). Sans `AGENTS.local.md`, rien n'est listé : chaque commande renvoie déjà vers `/po-setup`. La pose globale ne liste rien, elle n'a pas de projet.

### Consequences
- Good, because une mise à jour dit ce qui manque au moment où elle se fait, et `polype check <projet>` le redit à la demande.
- Bad, because une CI qui ne regarde que le code de sortie de `check` ne voit pas un réglage manquant ; il faut lire la sortie.
- Neutral: la valeur proposée est celle du gabarit, pas forcément la bonne pour le projet ; la documentation renvoie au tableau des valeurs avant d'ajouter la ligne.
