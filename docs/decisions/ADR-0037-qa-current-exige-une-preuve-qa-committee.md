---
adr: 0037
title: po-gate qa-current exige que docs/qa/<id>/ soit committé
status: accepted
date: 2026-10-08
scope: story s60-gate-parsing
supersedes: [ADR-0029]
superseded-by: [ADR-0041, ADR-0044]
---

# ADR-0037 — po-gate qa-current exige que docs/qa/<id>/ soit committé

## Context and Problem Statement
ADR-0029 laisse `qa-current` lire le rapport dans l'arbre de travail et note, en conséquence neutre, qu'un rapport à jour mais non committé passe, « à revoir ». La revue de s52 (m2) montre l'effet : si le commit de preuve de `/po-qa` a échoué sans bruit, la revue juge une preuve absente de l'arbre revu, et le squash peut ne pas l'emporter. s60 demande que la gate refuse ce cas. Il faut dire ce que « committé » veut dire pour la gate. La décision d'ADR-0029 (qui committe, quand la revue exige la QA) reste entière ; seule sa conséquence neutre change.

## Considered Options
- **Rapport présent dans `HEAD` et `git status --porcelain --untracked-files=all --ignored -- docs/qa/<id>/` vide** : le rapport et ses captures sont exactement ce que `HEAD` porte. C'est le même périmètre que le commit de `/po-qa` (`-- docs/qa/<id>/`).
- **Lire le rapport dans `HEAD` (`git show HEAD:…`) au lieu du disque** : écarte un rapport non committé, mais une capture non committée passe toujours, et la gate jugerait un autre fichier que celui que l'agent a sous les yeux.
- **Exiger seulement que `report.md` soit suivi et inchangé** : les captures, preuves du rapport, pourraient manquer au squash.
- **Ne rien changer, et laisser `/po-drive` committer** : c'est l'état actuel ; `/po-qa` lancé à la main et la revue restent exposés au commit refusé.

## Decision Outcome
Chosen option: **rapport dans `HEAD` et répertoire `docs/qa/<id>/` propre, y compris les fichiers ignorés**. C'est la seule option où la gate dit vrai sur ce que la revue et le squash emporteront, et elle colle au pathspec du commit de preuve. Le contrôle passe en dernier, après la fraîcheur : un rapport absent, bloqué ou périmé garde son message actuel.

### Consequences
- Good, because une preuve QA qui passe la gate est dans l'arbre revu et dans le squash.
- Bad, because la ligne de reprise de `/po-drive` « `qa-current` passe et `git status` liste le rapport → le commit de preuve, sans nouvelle marche » (`method/commands/po-drive.md:53`) ne peut plus s'appliquer : une lane dont le rapport à jour n'est pas committé repart en QA et refait une marche, et la phrase de `po-drive.md:62` devient fausse. `po-drive.md` appartient à s64 ; la correction lui revient, ou à une story de suivi.
- Neutral: un projet qui ignore `docs/qa/` dans `.gitignore` voit la gate refuser chaque rapport, ce qui est voulu : la preuve doit voyager sur la branche.
