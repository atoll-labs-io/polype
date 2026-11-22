---
adr: 0131
title: La preuve d'un atterrissage est le titre du commit sur la branche cible
status: accepted
date: 2026-11-22
scope: framing
supersedes: [ADR-0081]
superseded-by: []
---

# ADR-0131 — La preuve d'un atterrissage est le titre du commit sur la branche cible

## Context and Problem Statement
L'ADR-0081 fait atterrir une story en un commit `<id>: <titre>` et note, dans ses conséquences, que « la preuve de merge reste donc `MERGED` », l'état de la pull request lu sur la forge. Depuis, le ship est entré dans `po` (ADR-0130), et quatre stories ont retenu une autre preuve, chacune dans son plan : s193 pour reconnaître une story déjà atterrie, s194 pour reprendre un ship interrompu, s195 avant de déposer les constats, s196 avant de supprimer une lane. Le porteur l'a actée pour le nettoyage (décision d-0047). Cette preuve n'a jamais été écrite comme une décision ; il faut la consigner, avec ce qu'elle ne reconnaît pas.

## Considered Options
- **A. Le titre du commit sur la branche cible.** Une story a atterri quand un commit de la branche cible, absent de la branche de la story, porte exactement le titre `<id>: <titre>`. La branche cible est celle d'`origin` après un `fetch` sous `Merge mode: pr`, la branche locale sous `local`.
- **B. L'état `MERGED` de la pull request**, lu sur la forge (la conséquence de l'ADR-0081). Écartée : la preuve dépend d'une forge et n'existe pas sous `local` ; la pull request se retrouve par le nom de sa branche, que la décision d-0047 a jugé insuffisant ; et un état `MERGED` ne dit pas quel commit a été fusionné.
- **C. L'ascendance du commit envoyé** (`merge-base --is-ancestor`). Écartée : la fusion par rebase de la forge réécrit l'identifiant du commit, qui n'est donc jamais ancêtre de la branche cible (ADR-0081).
- **D. Le contenu seul** (l'arbre ou le changement du commit, sans son titre). Écartée comme preuve unique : le contenu ne se compare plus dès que la branche cible a avancé ou qu'un commit ultérieur a touché les mêmes lignes.

## Decision Outcome
Option choisie : **A**, par le porteur le 2026-11-22 (décision d-0048, après d-0047), parce qu'elle ne dépend d'aucune forge, vaut sous `local` comme sous `pr`, et survit à la fusion par rebase et au temps qui passe ; un identifiant de story n'est jamais réutilisé.

Ce qui vaut désormais :
- `po ship land`, `po ship push`, `po ship file` et `po ship clean` lisent cette preuve eux-mêmes ; `/po-ship` ne la demande plus à la forge.
- Le titre suffit pour dire « déjà atterrie » et ne rien refaire. Il ne suffit pas pour supprimer : avant de retirer une référence, `po ship clean` vérifie que ce qu'elle contient a atterri — la branche locale seulement si l'atterrissage contient déjà tous ses changements, la branche distante seulement si sa tête est l'atterrissage. Dans le doute il garde la référence et le dit (`branch-not-landed`, `remote-kept`).
- Une fusion dont une personne a changé le titre (un squash qui ajoute `(#N)`) n'est pas reconnue : la commande répond `not-landed`, ne supprime rien, et le nettoyage se fait à la main.

Cette décision remplace, dans l'ADR-0081, la seule phrase de ses conséquences sur la preuve de merge ; le reste de l'ADR-0081 tient.

### Consequences
- Good, because la preuve est la même sans forge et avec, et un ship interrompu se reprend sans rien refaire deux fois.
- Good, because une suppression exige plus que le titre : un commit qui ne porterait que le titre d'une story ne fait pas disparaître son travail.
- Bad, because une personne qui fusionne en changeant le titre doit nettoyer la lane elle-même.
- Bad, because `po next` ne lit l'atterrissage que sur les références locales : après une fusion faite par une personne, il répond « merge waiting » tant que rien n'a récupéré le distant (#437).
- Neutral: sur une forge autre que GitHub, rien de tout cela n'a tourné contre une vraie instance (#75) ; la première exécution réelle (s206) le dira.
