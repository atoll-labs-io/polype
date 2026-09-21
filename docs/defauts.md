# Défauts ouverts — Polype

Le tracker d'issues de Polype est ce fichier tant que le dépôt n'est pas sur GitHub. Un défaut n'est pas une story (Loi 7) : on le corrige au fil de l'eau (ADR-0015), par lot, au moment utile.

## Relevés par les revues de M2 (2026-09-19)

| # | Source | Défaut | Statut |
|---|---|---|---|
| 1 | revue s11 | `po-setup` demande `Design skill` ou `Design tool` « dans le même appel » selon la réponse sur `Design source`, alors qu'un appel `AskUserQuestion` pose toutes ses questions d'un coup. | corrigé par s21 |
| 2 | revue s18 | `/po-design` laisse `docs/designs/<id>/` non commité, mais l'`implementer` ne le compte pas parmi les documents non commités attendus : il s'arrêterait sur une story avec écran. | corrigé par s21 |
| 3 | revue s20 | Même cause que le n° 2, vue depuis `po-plan` et les Lois 1 et 4 : le chemin manuel (sans orchestrateur) du design n'est pas raccordé. | corrigé par s21 |
| 4 | revue s13 | `po-brief` écrit `status: approved` et l'ADR avant de contrôler la branche et les fichiers d'environnement : un arrêt à ce moment laisse un brief « approuvé » à moitié commité. | corrigé par s22 |
| 5 | revue s14 | L'exigence « brief approuvé » de `po-stories` n'a pas de test qui morde (la phrase testée figure deux fois). | corrigé par s22 |
| 6 | revue s15 | Pour un brief, `stories-review` traite les non-objectifs comme un élément à couvrir et déclare le contrôle du cimetière « non applicable », alors que les non-objectifs jouent ce rôle. | corrigé par s23 |
| 7 | revue s16 | La garde qui protège les blocs de réglages quand `po-architect` écrit la section Conventions n'a aucun test. | corrigé par s24 |
| 8 | revue s16 | En relance, `po-architect` remplace la section Conventions : des conventions écrites à la main peuvent disparaître. | corrigé par s24 |
| 9 | revue s17 | La règle « `po-design-system` n'édite aucun fichier source » n'a pas de test qui morde. | corrigé par s25 |
| 10 | revue s18 | L'arrêt de `po-design` quand `Design source` vaut `—` n'a pas de test qui morde. | corrigé par s25 |
| 11 | revue s19 | Les tests de `po-flow` vérifient les phrases déclencheuses, pas l'effet des règles : plusieurs règles s'inversent sans test rouge. | corrigé par s25 |

**Motif récurrent (n° 5, 7, 9, 10, 11)** : un test qui cherche une phrase dans un prompt prouve que la phrase existe, pas que l'agent l'applique. Les vraies preuves de comportement sont les passages de bout en bout (`docs/validation/`). Piste : des évaluations comportementales par commande, rejouées en headless.

## Relevés par les revues de M3 (2026-09-21)

| # | Source | Défaut | Statut |
|---|---|---|---|
| 12 | revue s27 | Une lane de `/po-drive` enchaîne planner → implementer → reviewer sans l'étape de design, alors que la Loi 1 l'impose pour une story avec écran. | à corriger par s32 |
| 13 | revue s25 | `bin/po-lint` conclut « aucun manquement » même quand il n'a lu aucun fichier (échec silencieux du listage). | à corriger par s32 |
| 14 | revue s31 | La matrice se contredit sur l'état de la flotte (D17 contre les lignes tracker), et `docs/conception.md` présente encore ADR-0014 comme vivante alors qu'ADR-0017 la remplace. | à corriger par s32 |
| 15 | revue s23 | `tests/design-handoff.test.sh` modifié hors du périmètre déclaré de la story. | ouvert |
| 16 | revue s30 | `docs/decisions/ADR-0014-…` modifiée hors du périmètre déclaré de la story. | ouvert |
| 17 | revue s28 | `method/templates/review.md` n'a pas de section pour le contrôle d'ownership, qui précède désormais les six étapes. | ouvert |
| 18 | revue s29 | `/po-drive` : la reprise « research présente, plan absent » est annoncée mais pas décrite jusqu'au bout. | ouvert |
| 19 | revue s29 | `/po-drive` : deux lignes de la table de reprise se recouvrent, sans priorité déclarée (cas d'un arrêt après un fix run). | ouvert |
| 20 | revue s25 | `tests/design.test.sh` : le message d'échec promet un contrôle « sur la même ligne » que l'assertion ne fait pas. | ouvert |
| 21 | revue s22 | Findings mineurs de formulation laissés par plusieurs revues (voir les rapports). | ouvert |
