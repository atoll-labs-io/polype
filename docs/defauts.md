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
| 9 | revue s17 | La règle « `po-design-system` n'édite aucun fichier source » n'a pas de test qui morde. | ouvert |
| 10 | revue s18 | L'arrêt de `po-design` quand `Design source` vaut `—` n'a pas de test qui morde. | ouvert |
| 11 | revue s19 | Les tests de `po-flow` vérifient les phrases déclencheuses, pas l'effet des règles : plusieurs règles s'inversent sans test rouge. | ouvert |

**Motif récurrent (n° 5, 7, 9, 10, 11)** : un test qui cherche une phrase dans un prompt prouve que la phrase existe, pas que l'agent l'applique. Les vraies preuves de comportement sont les passages de bout en bout (`docs/validation/`). Piste : des évaluations comportementales par commande, rejouées en headless.
