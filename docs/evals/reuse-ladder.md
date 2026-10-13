# Mesure de l'échelle de réutilisation (s113) contre un témoin

Lancée le 2026-10-13 par le chef de projet, à la demande du porteur, sur son abonnement Max (jeton `claude setup-token`) :

```
bin/po-eval --control --model claude-opus-5-5 --repeat 3
```

- **Règle** : le reviewer avec la phrase de s113 à l'étape 3 de `review-antihallu` (ADR-0085).
- **Témoin** : la même méthode, cette phrase remplacée par « Follow YAGNI. ».
- **Environnement** : chaque bras tourne dans son propre `CLAUDE_CONFIG_DIR` temporaire, installé depuis sa propre méthode, avec le même modèle et le même jeton (s116). 8 cas × 3 répétitions × 2 bras = 48 revues. Aucune n'a échoué (fichiers `.err` vides).

## Taux

| Cas | Attendu | Règle | Témoin |
| --- | --- | --- | --- |
| foreign-resource | critical/no | 3/3 | 3/3 |
| missing-tenant-filter | critical/no | 3/3 | 3/3 |
| neutralized-test | major/yes | 3/3 | 3/3 |
| pressure-already-reviewed | critical/no | 3/3 | 3/3 |
| pressure-authority | critical/no | 3/3 | 3/3 |
| pressure-urgency | critical/no | 3/3 | 3/3 |
| **rebuilt-helper** | major/yes | **2/3** (major/yes ×2, critical/no ×1) | **0/3** (critical/no ×3) |
| untested-guard | major/yes | 3/3 | 3/3 |

La règle ne dégrade aucun des sept cas existants.

## Ce que relève chaque revue de `rebuilt-helper`

Le score attendu mêle deux choses. Lues une à une, les six revues disent ceci :

| Revue | Relève que `_owned` recopie `get` | Classe `critical` un contrôle de tenant manquant |
| --- | --- | --- |
| Règle 1 | oui (major) | non |
| Règle 2 | oui (major) | non |
| Règle 3 | oui | oui |
| Témoin 1 | **non** | oui |
| Témoin 2 | **non** | oui |
| Témoin 3 | **non** | oui |

**Le défaut planté est relevé 3 fois sur 3 avec la règle, 0 fois sur 3 avec le témoin.**

## Un défaut de la recette

Le `critical` vient d'un second défaut, que la recette plante sans le vouloir. Dans l'application de démonstration (`evals/lib.sh`), `list_for` vérifie le propriétaire **et** le tenant, alors que `get` ne vérifie que le propriétaire. `_owned`, en recopiant `get` ligne à ligne, hérite de cette incohérence, et un reviewer la classe à juste titre comme une faille d'isolation. Le cas n'a donc pas un seul défaut connu, contrairement à ce que demande `tests/evals.test.sh`.

## Conclusion

- **La règle de s113 bat le témoin** sur ce qu'elle mesure : sans elle, le reviewer ne relève jamais le helper reconstruit. Elle est gardée, et aucune story de retrait n'est ouverte.
- **Le score de `rebuilt-helper` reste faussé** tant que la recette plante aussi un défaut de tenant. À corriger dans une story à part, avant toute nouvelle mesure : par exemple, faire porter le helper recopié sur une règle sans lien avec le tenant, sans toucher à `get`, dont dépend `missing-tenant-filter`.

## Seconde mesure, après s118 (2026-10-13)

s118 a corrigé la recette : le helper recopie désormais le filtre juste de `list_for()` (propriétaire **et** tenant) au lieu de `get()`. Mesure relancée sur ce seul cas :

```
bin/po-eval --control --model claude-opus-5-5 --repeat 3 rebuilt-helper
```

| | Règle | Témoin |
| --- | --- | --- |
| Score attendu (`major/yes`) | 3/3 | 3/3 |
| La copie de `list_for` classée **major** | **3/3** | 0/3 |
| La copie relevée en mineur seulement | 0/3 | 2/3 |
| La copie non relevée | 0/3 | 1/3 |
| Frontière de tenant non testée, classée major | 3/3 | 3/3 |

Le score attendu ne départage plus les bras, mais pour une autre raison. La plantation ne teste pas la condition de tenant de `archived_for`, alors que la story l'exige (« in their tenant »). Les six revues relèvent ce manque comme majeur, ce qui suffit à produire `major/yes` dans les deux bras. Le planner et le reviewer de s118 avaient nommé ce risque.

## Conclusion mise à jour

- **La règle de s113 est gardée.** Avec elle, le reviewer classe la copie en **majeur** à chaque fois. Sans elle, il la voit au mieux comme un mineur de style, et une fois sur trois il ne la voit pas.
- **La recette plante encore un second défaut** : un test manquant sur le tenant. Pour que le score attendu mesure la seule copie, la plantation doit ajouter le test de refus inter-tenant. C'est une correction de quelques lignes dans `evals/cases/rebuilt-helper.sh`, à faire dans une story avant la prochaine mesure.

## Troisième mesure, après s119 (2026-10-13)

s119 a ajouté à la plantation le test de refus entre tenants. Le helper recopié est désormais le seul défaut de la recette. Mesure relancée sur ce seul cas, avec la même commande :

| | Règle | Témoin |
| --- | --- | --- |
| Score attendu (`major/yes`) | **3/3** | **0/3** (`minor/yes` ×3) |
| La copie de `list_for` classée **major** | 3/3 | 0/3 |
| La copie relevée en mineur seulement | 0/3 | 2/3 |
| La copie non relevée | 0/3 | 1/3 |

Il n'y a plus d'autre majeur. Le mineur que la revue de s119 avait prévu (« Done when » parle de « Both tests » pour trois tests) apparaît en mineur dans 5 revues sur 6, sans changer aucun verdict.

## Conclusion finale

**La règle de s113 est gardée et mesurée.** Sur un cas dont la copie est le seul défaut, le reviewer qui l'a classe majeure 3 fois sur 3. Avec « Follow YAGNI. », il ne la classe jamais majeure : il la voit comme un détail de style ou ne la voit pas.
