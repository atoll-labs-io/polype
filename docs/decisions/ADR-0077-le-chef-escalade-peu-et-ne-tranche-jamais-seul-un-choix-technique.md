---
adr: 0077
title: Le chef escalade sur trois motifs et ne tranche jamais seul un choix technique
status: accepted
date: 2026-10-13
scope: pipeline
supersedes: []
superseded-by: []
---

# ADR-0077 — Ce qui remonte à l'humain, et ce que le chef tranche seul

## Context and Problem Statement
Pour être autonome sans perdre la qualité de la méthode, le chef de projet (ADR-0076) doit savoir exactement quand solliciter l'humain. Sans contrat écrit, il demande trop (la plainte d'aujourd'hui) ou trop peu (un choix structurel pris en silence).

## Considered Options
- **Tenter une sortie autonome avant d'escalader** les cas qui vont déjà à un humain (`Max attempts` épuisé, cause racine introuvable, QA bloquée). Moins de sollicitations, mais le chef contournerait des arrêts posés exprès (ADR-0070).
- **Accumuler ces cas jusqu'à la fin du jalon.** Moins d'interruptions, mais une story bloquée attend sans raison.
- **Les escalader tout de suite, en laissant la flotte continuer les autres stories.** Retenu.

## Decision Outcome
Chosen option: **escalade immédiate des arrêts existants, sur trois motifs nouveaux, et aucun choix technique tranché seul.**

- Le chef sollicite l'humain pour : une **incohérence** (code, ADR acceptée et story qui se contredisent) ; une **idée nouvelle** hors du périmètre approuvé ; une **décision stratégique** (vision, périmètre, coût récurrent, sécurité, données personnelles, ou ce qui est difficile à défaire).
- **Tout choix technique ou technologique se discute avant d'être pris** : bibliothèque, framework, modèle de données, protocole, hébergement, tout ce qui mérite une ADR. Les options sont classées d'abord sur ces critères : open source et utilisable librement, ou auto-hébergeable ; sobre en ressources matérielles ; scalable ; facile à manipuler pour une IA.
- Un détail d'implémentation à l'intérieur d'un plan validé reste au chef.
- Les arrêts existants vont à l'humain tout de suite, un par un, et la flotte continue les autres voies.
- Ce que le chef tranche seul (ordre des vagues, boucles de fix, détails d'implémentation) est consigné dans `docs/decisions-log.md`, une ligne datée par décision avec sa raison.
- Aucune gate ne s'ouvre autrement qu'aujourd'hui.

### Consequences
- Good, because l'humain n'est sollicité que là où son jugement change le résultat, et le journal lui laisse tout relire après coup.
- Bad, because la frontière entre choix technique et détail d'implémentation reste un jugement : dans le doute, le chef demande.
- Neutral: les critères de choix rejoignent ceux de la skill `capability-bricks` (ADR-0009, ADR-0020), qui les intégrera.
