---
adr: 0108
title: Un jalon de méthode naît d'un défaut vu sur un produit
status: proposed
date: 2026-11-12
scope: framing
supersedes: []
superseded-by: []
---

# ADR-0108 — Un jalon de méthode naît d'un défaut vu sur un produit

## Context and Problem Statement
Au 2026-11-12, Polype a livré 158 stories sur lui-même pour 79 stories sur les produits qu'il sert, et `method/` pèse environ 77 000 mots. La confiance y est prouvée sur le texte de la méthode (environ 600 assertions qui cherchent une phrase), pas sur le comportement des agents, ce que `docs/defauts.md` notait dès septembre. Chaque écart constaté a ajouté une règle en prose, donc du texte à relire à chaque étape et un test de phrase de plus. Il faut une règle qui dise quand la méthode a le droit de grandir.

## Considered Options
- **Continuer au fil des idées et des constats de revue** — chaque constat devient une story de méthode. C'est ce qui a produit l'écart ci-dessus.
- **Geler la méthode** jusqu'à ce qu'un produit soit en production — arrête la dérive, mais laisse en place les défauts que les produits rencontrent déjà (#149, #184, #87).
- **Tirer la méthode par les produits, sous budget** — voir ci-dessous.

## Decision Outcome
Proposé, à trancher par le porteur. Recommandation : **tirer la méthode par les produits, sous budget**, en quatre règles.

1. Après M22, un jalon de méthode ne s'ouvre que pour un défaut vu sur un produit, cité dans son objectif. Une idée sans défaut reste une issue étiquetée `parked`.
2. Une règle en prose n'entre dans `method/` que si une autre en sort : le budget de mots, contrôlé par `po-lint` (#208), ne monte pas.
3. Ce qu'un script peut décider ou écrire n'est pas confié à un modèle : état, routage, forme d'un rapport, validation d'une réponse.
4. Une règle se prouve par un comportement rejoué (#206) ou par un bras de contrôle de `po-eval` (#208), pas par la présence de sa phrase ; les tests de phrase qui ne sont lus par aucun script sont retirés (#207).

M20 à M22 sont l'exception qui met ces règles en place.

### Consequences
- Good, because le temps passé sur Polype se justifie par un produit qui avance.
- Bad, because des améliorations plausibles attendent qu'un produit en ait besoin (audit planifié, story d'exploration, plateforme desktop, portage Codex).
- Neutral: un constat de revue sur Polype lui-même reste déposé (Law 7) ; il n'ouvre pas un jalon à lui seul.
