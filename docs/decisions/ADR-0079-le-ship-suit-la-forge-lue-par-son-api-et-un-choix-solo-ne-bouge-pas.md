---
adr: 0079
title: Le ship suit la forge lue par son API, un dépôt collaboratif interdit le merge d'agent, un choix solo ne bouge pas
status: accepted
date: 2026-10-13
scope: story s102-ship-follows-the-forge
supersedes: []
superseded-by: []
---

# ADR-0079 — Le ship suit la forge lue par son API, et un choix solo ne bouge pas

## Context and Problem Statement
ADR-0075 veut un `Ship confirmation` posé depuis la forge, marqué `(forge)` ou `(choisi)` (`(chosen)` dans la méthode, écrite en anglais), et relu à chaque ship. Elle laisse ouverts : la façon de lire la forge, ce que vaut une valeur sans suffixe (tous les projets installés avant s102), ce qui l'emporte entre la forge et un choix de la personne, et le chemin d'une ligne réécrite, que ADR-0080 interdit désormais de pousser sur `Target branch`.

Une première version de cette ADR, écrite par le planner sans discussion, retenait « sans suffixe = `(chosen)` », GitHub seul lu par `gh` et un commit de réglage sur `Target branch`. Le porteur l'a réécrite en conversation le 2026-10-13 : cette version-ci est sa décision.

## Considered Options
- **Lire GitHub seul, par `gh`, et tenir toute autre forge pour illisible.** Écarté : les forges libres et auto-hébergeables (GitLab, Forgejo, Gitea) resteraient toujours illisibles.
- **Lire chaque forge par son API, via sa CLI quand elle est là.** Retenu.
- **Une valeur sans suffixe vaut `(chosen)`.** Écarté : les projets existants, mis à `human` par l'ancien gabarit, ne suivraient jamais la forge.
- **Une valeur sans suffixe arrête le ship et demande l'origine.** Écarté : chaque projet existant serait bloqué pour une question de format.
- **Une valeur sans suffixe vaut `(forge)`.** Retenu.
- **Un `automatic (chosen)` merge même sur un dépôt collaboratif.** Écarté : un agent ne merge jamais seul là où d'autres personnes relisent.
- **Le dépôt collaboratif impose `human (forge)` ; la personne seule choisit.** Retenu.
- **Un 403 « Upgrade to GitHub Pro » rend la forge illisible.** Écarté : tout dépôt privé gratuit resterait illisible pour toujours.
- **Commiter la ligne réécrite sur `Target branch`.** Écarté : ADR-0080 interdit à tout agent de pousser sur cette branche.
- **La ligne réécrite va sur une branche, poussée, en PR draft.** Retenu.

## Decision Outcome
Chosen option: **la forge est lue par son API ; un dépôt collaboratif donne `human (forge)` quoi que dise la ligne ; un dépôt solo suit le choix de la personne ; une valeur `(forge)` ou sans suffixe suit la forge ; une ligne réécrite part en PR draft et le ship suit tout de suite la valeur effective**, retenue par le porteur le 2026-10-13.

1. **Lecture.** La forge se déduit du remote `origin` : `github.com` → GitHub ; un hôte qui contient `gitlab` → GitLab ; sinon l'hôte est sondé sur `/api/v1` pour reconnaître Forgejo ou Gitea. Elle est lue par son API, via sa CLI quand elle est installée (`gh`, `glab`, `tea`). Pas de remote, hôte inconnu ou pas de jeton : la forge est illisible, la valeur de la ligne reste et le rapport le dit.
2. **Dépôt collaboratif** : un autre collaborateur avec droit d'écriture, un `CODEOWNERS` qui nomme quelqu'un d'autre, ou une protection de `Target branch` qui exige une approbation. Le merge par un agent y est interdit quoi que dise la ligne : la valeur effective est `human (forge)`.
3. **Dépôt solo** : la valeur est le choix de la personne au setup, `automatic (chosen)` ou `human (chosen)`. Elle la change plus tard en conversation ; un agent ne la réécrit jamais de lui-même.
4. **Valeur `(forge)` ou sans suffixe** : elle suit la forge. Un dépôt solo y donne `automatic (forge)`, un dépôt collaboratif `human (forge)`. Le 403 « Upgrade to GitHub Pro » d'un dépôt privé sur un plan gratuit vaut « aucune protection » ; la collaboration se lit encore par les collaborateurs et `CODEOWNERS`.
5. **Ligne réécrite** : elle est commitée sur une branche, poussée et proposée en PR draft (ADR-0080), jamais poussée sur `Target branch`. Le ship en cours suit déjà la valeur effective, sans attendre le merge de cette PR.

La gate `ship-allowed` ne change pas : aucun merge sans elle, quelle que soit la valeur.

### Consequences
- Good, because une personne seule n'est plus sollicitée pour merger ce que la gate a prouvé, et un dépôt où d'autres relisent garde sa revue sans que personne y pense.
- Good, because les forges libres et auto-hébergeables sont lues comme GitHub.
- Bad, because un projet installé avant s102 avec `Ship confirmation: human` sans suffixe, sur un dépôt solo, passe à `automatic (forge)` à son prochain ship : la PR draft et le rapport le montrent, la personne peut écrire `human (chosen)`.
- Bad, because les appels d'API de GitLab, Forgejo et Gitea ne sont pas encore vérifiés sur une instance réelle, et `/po-ship` n'ouvre encore ses PR que sur GitHub (ADR-0081) : ailleurs, la branche de réglage est poussée et le rapport demande d'ouvrir la PR.
- Neutral: un 403 de droits (lecture de la protection sans être admin) se distingue du 403 de plan par son message seulement ; à surveiller si GitHub le change. Les jetons ne sont jamais écrits dans un fichier ni affichés.
