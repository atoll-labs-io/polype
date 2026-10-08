---
adr: 0044
title: po-gate qa-current ne compte plus les fichiers ignorés par git
status: accepted
date: 2026-10-08
scope: story s67-record-text
supersedes: [ADR-0037]
superseded-by: []
---

# ADR-0044 — po-gate qa-current ne compte plus les fichiers ignorés par git

## Context and Problem Statement
ADR-0037 fait refuser `qa-current` tant que `git status --porcelain --untracked-files=all --ignored -- docs/qa/<id>/` n'est pas vide, en disant que ce périmètre « colle au pathspec du commit de preuve ». C'est faux pour les fichiers ignorés : `git add -- docs/qa/<id>/` ne les prend jamais. La revue de s60 (M1) l'a reproduit : un `.DS_Store` ignoré sous `docs/qa/<id>/` fait refuser la gate pour toujours, son conseil (le commit de preuve) ne peut rien committer, et la revue renvoie la lane en QA sans fin. Cet ADR remplace le seul point « y compris les fichiers ignorés » d'ADR-0037 ; le reste de sa décision (rapport dans `HEAD`, contrôle placé après la fraîcheur, message « is current but docs/qa/<id>/ is not committed ») est repris tel quel.

## Considered Options
- **Retirer `--ignored` et garder `git cat-file -e HEAD:docs/qa/<id>/report.md`** — la gate voit ce que le commit de preuve peut emporter ; le rapport lui-même doit être dans `HEAD`, donc un rapport ignoré reste refusé, et le refus le nomme comme ignoré.
- **Garder `--ignored` avec un message distinct qui nomme le fichier ignoré** — le refus devient lisible, mais reste définitif pour un fichier que personne n'a à committer (`.DS_Store`, un log), et la lane boucle toujours.
- **Faire committer les ignorés par `/po-qa` (`git add -f`)** — emporterait des fichiers que le projet a choisi d'exclure, secrets compris ; `po-qa.md` est hors du périmètre de la story.

## Decision Outcome
Chosen option: **retirer `--ignored` et garder le contrôle du rapport dans `HEAD`**, parce que c'est la seule option où le conseil de la gate peut toujours être suivi. Le `cat-file`, redondant sous ADR-0037 (revue de s60, m3), devient le seul contrôle qui refuse un `report.md` ignoré ; un test le prouve.

### Consequences
- Good, because un fichier ignoré à côté du rapport ne bloque plus la gate ni la lane.
- Bad, because une capture que le projet ignore (`*.png` dans `.gitignore`) passe la gate sans voyager dans le squash ; la revue ne la voit pas. Le rapport, lui, voyage toujours.
- Neutral: un projet qui ignore tout `docs/qa/` voit toujours chaque rapport refusé, comme sous ADR-0037, avec un refus qui dit que le rapport est ignoré.
