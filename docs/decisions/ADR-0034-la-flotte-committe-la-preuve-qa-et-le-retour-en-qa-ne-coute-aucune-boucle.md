---
adr: 0034
title: Dans la flotte, le driver committe la preuve QA, et un retour en QA ne coûte aucune boucle
status: accepted
date: 2026-10-08
tags: [adr, polype, qa, flotte, boucles]
scope: story s57-qa-in-the-fleet
supersedes: []
superseded-by: []
---

# ADR-0034 — Dans la flotte, le driver committe la preuve QA, et un retour en QA ne coûte aucune boucle

## Context and Problem Statement
ADR-0029 fait committer `docs/qa/<id>/` par la commande `/po-qa`. Or `/po-drive` ne lance pas de commande : il dispatche des subagents, et l'agent `qa` n'a pas le droit de committer (ADR-0026). Il faut dire qui committe la preuve dans une lane. Il faut aussi qu'une revue bloquée parce que `po-gate qa-current` échoue renvoie à la QA sans entamer `Max attempts`, alors que chaque revue prend aujourd'hui le `Fix loop:` précédent plus un, et que `Max attempts` se lit sur cette ligne.

## Considered Options
Qui committe la preuve dans une lane :
- **Le driver, par Bash, exactement comme `/po-qa` l'écrit** — même branche vérifiée, même pathspec `-- docs/qa/<id>/`, jamais `--no-verify` ; le driver enregistre déjà la revue par Bash.
- **L'agent `qa`** — il faudrait ouvrir à un verbe git qui écrit la liste blanche du mode `qa` de `po-bounds` ; refusé par ADR-0026 et ADR-0029.
- **L'implementer au run suivant, ou `/po-ship`** — la revue jugerait un arbre qui ne porte pas le rapport ; refusé par ADR-0029.

Comment compter un retour en QA :
- **La revue qui suit un retour en QA garde le `Fix loop:` de la revue bloquée** — `Fix loop:` reste le nombre de fix runs, donc l'invariant de reprise « une revue à `Fix loop: n` a jugé le n+1-ième commit de l'implementer » tient : un retour en QA n'ajoute aucun commit de l'implementer.
- **Chaque revue incrémente, et `Max attempts` est relevé** — mélange deux budgets ; une QA qui échoue deux fois rendrait la story à un humain sans qu'aucun code n'ait été corrigé.
- **Une ligne `QA loop:` dans le gabarit de revue** — un compteur de plus à lire, dans un gabarit que cette story ne possède pas.

Comment reconnaître une revue bloquée par la QA :
- **Sa ligne `Next action:` nomme `/po-qa`** — c'est ce que le skill `review-antihallu` écrit déjà.
- **Le message de la gate dans `Failure cause:`** — dépend du texte exact d'un message d'erreur.

## Decision Outcome
Chosen option: **le driver committe la preuve, la revue après un retour en QA garde son `Fix loop:`, et `Next action:` nommant `/po-qa` signe la revue bloquée par la QA**, parce que c'est la seule combinaison qui ne touche ni `po-bounds`, ni l'agent `qa`, ni le gabarit de revue, et qui garde intact le décompte des commits sur lequel repose la table de reprise.

Deux bornes empêchent une boucle QA ↔ revue : un rapport `QA status: blocked` rend la lane à un humain au lieu de relancer une marche qui échouerait pareil, et une revue encore bloquée par la QA quand `story/<id>` porte déjà deux commits `<id>: QA evidence` depuis le dernier commit de l'implementer rend aussi la lane à un humain.

### Consequences
- Good, because une lane avec écran passe par la QA sans commande lancée à la main, et sa preuve est dans l'arbre que le reviewer juge.
- Good, because une QA manquante ou périmée ne dépense plus de fix run que l'implementer ne pouvait pas résoudre (majeur M1 de la revue de s52).
- Bad, because le Bash du driver fait désormais un commit ; seule sa consigne le limite à `docs/qa/<id>/`, comme pour `/po-qa`.
- Neutral: `po-gate qa-current` accepte toujours un rapport non committé (mineur m2 de s52). La reprise du driver le compense sans toucher à la gate : un rapport à jour mais non committé déclenche le commit de preuve, pas une nouvelle marche. `/po-flow` et `/po-execute` lancés à la main envoient encore une revue bloquée par la QA en fix run ; à reprendre dans une story qui les possède.
