---
adr: 0122
title: Un changement de po exige une nouvelle version
status: accepted
date: 2026-11-14
scope: framing
supersedes: []
superseded-by: []
---

# ADR-0122 — Un changement de `po` exige une nouvelle version

## Context and Problem Statement
Depuis s171, l'installeur pose un `po` précompilé quand `bin/polype` porte une somme pour la version et la plateforme (ADR-0121). Il choisit ce binaire d'après le numéro de version seul. Or `po/` a changé à chaque story de M21 sans que `POLYPE_VERSION` bouge de 0.2.0 : dès qu'une somme sera inscrite pour une version, un clone dont les sources ont évolué sous ce même numéro recevrait le binaire publié, plus ancien, sans message (constat majeur de la revue de s171, #296). Rien ne casse tant qu'aucune version n'est publiée.

## Considered Options
1. **Tout changement de `po` exige une nouvelle version** — une règle que la CI vérifie : un diff qui touche `po/` sans monter la version est refusé. Le numéro dit toujours quelles sources il désigne. Chaque story qui touche `po` entraîne une version, donc une publication.
2. **Une installation depuis un clone préfère ses propres sources** — un clone avec `cargo` compile toujours son `po` ; seules la charge installée et les machines sans Rust téléchargent. Aucune discipline de version à tenir, mais un même numéro continue de désigner plusieurs états du code.
3. **Les deux.**

## Decision Outcome
Chosen option: **l'option 1**, choisie par le porteur le 2026-11-14 (décision d-0015 de la boîte), contre la recommandation du chef de projet, qui proposait l'option 2 comme celle qui ne demande aucune discipline. Sa raison : il faut dès maintenant une discipline de version professionnelle, et un numéro qui désigne plusieurs états du code n'en est pas une.

Le porteur pose le même principe pour tout projet construit avec Polype : il est versionné avec cette rigueur. Ce que cela demande à la méthode (le schéma de version, qui monte le numéro et quand, le journal des changements, les étiquettes de publication) est un choix technique à cadrer avec lui dans M22 ; cette ADR ne tranche que le cas de `po`.

### Consequences
- Good, because une somme inscrite pour une version vaut pour un seul état des sources, et un `po` installé dit exactement de quel code il vient.
- Bad, because chaque story qui touche `po/` monte la version et demande une publication avant que sa somme serve à quelqu'un.
- Neutral: la vérification en CI, la montée de version et la publication qui la suit sont une story de M22 ; d'ici là, `PO_SUMS` reste vide et tout le monde compile depuis les sources.
