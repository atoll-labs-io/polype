---
adr: 0129
title: Les sommes de po reposent sur l'écriture restreinte au porteur
status: accepted
date: 2026-11-18
scope: story s189-first-release-holds
supersedes: []
superseded-by: []
---

# ADR-0129 — Les sommes de `po` reposent sur l'écriture restreinte au porteur

## Context and Problem Statement
Chaque installeur ne pose le `po` publié que si sa somme est égale à celle que porte le `PO_SUMS` de `bin/polype` (ADR-0121). Ces sommes, la personne qui les fait atterrir les prend dans la release de la version (`docs/ci.md`, « Publier une version »). `bin/po-release --tag` lie l'étiquette à la version de `bin/polype` et de `po/Cargo.toml` et à un commit de la branche cible, et refuse de rebâtir une version dont les sommes ont déjà atterri ; `bin/po-release --sums` n'écrit les sommes que d'une étiquette posée sur un commit de la branche cible. Rien ne lie en revanche les fichiers d'une release à ce que le commit étiqueté a construit : qui peut écrire sur le dépôt peut remplacer ces fichiers après la construction légitime, et une somme de 64 caractères hexadécimaux ne se vérifie pas à l'œil dans la pull request des sommes. La revue de s189 l'a relevé ; il faut dire si ce risque se ferme maintenant, et comment.

Aujourd'hui, une seule personne, le porteur, peut écrire sur le dépôt et sur ses publications. Le seul autre écrivain est le workflow `release.yml`, avec la seule permission `contents: write`. Un jeu de règles de la forge, « release tags », réserve aux administrateurs la création, le déplacement et la suppression des étiquettes `v*`.

## Considered Options
- **A. Accepter le risque restant et garder l'écriture restreinte.** Pas de code de plus : le risque ne vient que de qui peut écrire, et ce cercle se réduit au porteur et au workflow de publication.
- **B. Des attestations de construction émises par la forge**, vérifiées avant d'écrire les sommes. Écartée : la vérification dépendrait d'un service propre à une forge, alors que `bin/po-release` ne lit rien de la forge et sert tel quel sur Forgejo (ADR-0105), et qu'un projet auto-hébergé doit pouvoir s'en passer.
- **C. Reconstruire `po` à l'identique dès maintenant**, pour que la personne compare les sommes publiées à une construction faite chez elle. Écartée pour cette story : rendre la construction reproductible est un chantier à part entière (chaîne d'outils figée, chemins, horodatages, quatre plateformes), sans rapport avec la tenue de la première publication.

## Decision Outcome
Option choisie : **A**, par le porteur le 2026-11-18 (décisions d-0037 à d-0039), parce que le risque ne vise qu'un dépôt où personne d'autre que lui n'écrit, et que l'option qui le lève sans lier Polype à une forge, C, a sa place dans M23.

Ce qui est lié par le code : l'étiquette à la version et à la branche cible, la publication unique de chaque version, et des sommes qui ne viennent que d'une étiquette de la branche cible. Ce qui reste accepté : les fichiers d'une release peuvent être remplacés par qui a le droit d'écrire, et la personne qui fait atterrir les sommes les reçoit telles que la release les sert.

Ce qui le lèvera : la story que le porteur a placée dans M23 (`docs/stories.md`, section M23), où `po` se reconstruit à l'identique ; la personne qui fait atterrir les sommes d'une version les compare alors à une construction faite sur sa propre machine.

Cette décision se rouvre le jour où une deuxième personne reçoit le droit d'écrire sur le dépôt ou sur ses publications, ou si le jeu de règles « release tags » est retiré.

### Consequences
- Good, because aucun code ni aucune dépendance à une forge n'entre pour un risque que le cercle des écrivains borne déjà.
- Bad, because jusqu'à M23, les sommes que porte `bin/polype` valent ce que vaut l'accès en écriture au dépôt : un compte du porteur compromis suffirait à faire publier un autre binaire.
- Neutral: la personne qui fait atterrir des sommes prend la release juste après la publication de la version et s'assure que personne d'autre n'a pu y écrire entre-temps (`docs/ci.md`).
