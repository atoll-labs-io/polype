---
adr: 0025
title: Le garde de plancher lit le diff ligne à ligne, garde ses motifs dans po-gate, et son code 2 bloque la revue
status: accepted
date: 2026-10-07
tags: [adr, polype, gates, review]
scope: story s48-floor-guard
supersedes: []
superseded-by: []
---

# ADR-0025 — Le garde de plancher lit le diff ligne à ligne, garde ses motifs dans po-gate, et son code 2 bloque la revue

## Context and Problem Statement
s48 ajoute `po-gate floor-guard <id> <base>`, qui signale ce qu'une story fait pour rendre les contrôles plus faciles à passer. Trois choix restent ouverts : comment lire le changement (diff ou fichiers entiers), où vivent les listes de motifs par langage, et ce que la revue fait d'un code 2 (« impossible de vérifier »), que la story interdit de lire comme propre sans dire ce qu'il devient.

## Considered Options
- **Comparer les fichiers entiers** (`git show <base>:<f>` contre la pointe) — compte exact des assertions, mais lit tout le dépôt touché, ce que la story exclut, et signale des suppressions déjà présentes avant la story.
- **Lire seulement `git diff -U0 <base>...story/<id>`** — lignes ajoutées et retirées, appariées par fichier ; une baisse d'assertions = retirées moins ajoutées, égale à la différence des comptes pour un fichier modifié.
- **Motifs dans un fichier de données à part** (`method/hooks/floor-patterns`) — plus lisible, mais hors de l'`Owns` de s48 et un fichier de plus que `po-gate` doit retrouver ou refuser.
- **Motifs dans `po-gate.sh`**, une table `extensions|règle|ERE` par langage en tête de la fonction — un seul fichier, compléter = ajouter une ligne.
- **Moteur `jq` ou `python3`** — inutile pour du texte de diff ; `po-gate` n'a aucune dépendance aujourd'hui.
- **bash + awk POSIX** — classes `[[:space:]]`, ni `\s` ni `\b`, pour tourner sous l'awk de macOS et mawk.
- **Code 2 → ligne « Not verified » sous un verdict normal** — le verdict peut alors dire `Ship allowed: yes` sur un diff que personne n'a scanné.
- **Code 2 → le reviewer refait le scan à la main** — une lecture d'agent remplace le contrôle mécanique, exactement ce que le garde devait éviter.
- **Code 2 → revue bloquée** — la règle de `reviewer.md` pour une commande qui empêche une revue complète.

## Decision Outcome
Chosen options: **lire seulement le diff**, **motifs dans `po-gate.sh`**, **bash + awk POSIX**, **code 2 → revue bloquée**, because la story borne la lecture au diff et l'`Owns` à `po-gate.sh`, et un code 2 qui laisse passer un verdict favorable serait lu comme propre.

### Consequences
- Good, because une suppression déjà présente sur la base n'est jamais signalée : seules les lignes de la story comptent.
- Good, because ajouter un langage ou une directive tient en une ligne de table, sans toucher au moteur.
- Bad, because l'heuristique ligne à ligne rate un `catch` vide dont l'accolade fermante n'est pas sur la ligne ajoutée suivante, et un seuil déplacé dans un autre fichier.
- Bad, because un dépôt sans `Target branch` locale bloque la revue au lieu de la laisser passer.
- Neutral: les seuils négatifs de Jest (nombre maximal non couvert), les règles ESLint passées à `off` dans la configuration et les seuils de `package.json` ou `setup.cfg` ne sont pas couverts ; à ajouter à la table quand un projet en a besoin.
