---
adr: 0133
title: Combien de passages payants fondent le retrait d'une règle
status: accepted
date: 2026-11-23
scope: story s206-real-run-before-a-release
supersedes: []
superseded-by: []
---

# ADR-0133 — Combien de passages payants fondent le retrait d'une règle

## Context and Problem Statement
s206 mesure ce qu'une règle lue par un modèle change : un bras « règle » (la méthode telle quelle) et un bras « témoin » (la même méthode, la phrase retirée) tournent sur le même cas, avec le même modèle, et des scripts notent chaque passage. Chaque passage est payant et son issue varie d'un passage à l'autre. Trop peu de passages ferait retirer une règle utile (le témoin réussit par chance) ou garder une règle morte (le témoin échoue par chance). Le porteur fixe combien de passages fondent une proposition de retrait, et ce qu'un passage réel avant publication peut coûter. Retirer une règle reste sa décision, prise sur le relevé.

**Ce que coûte un passage (estimation, à corriger par le premier relevé).** Base : chaque contexte d'agent part d'environ 25 à 30 k jetons (invite système et outils de Claude Code, 15 à 20 k, non mesurés ici ; `method/AGENTS.md`, 3 732 mots ; le fichier de l'agent, ses skills préchargés et la commande lue, 4 000 à 7 200 mots) et relit tout son contexte à chaque tour.
- Un **cas court** (une commande, un ou deux agents, souvent un arrêt) : 0,3 à 1,5 M de jetons d'entrée traités, dont 85 à 90 % lus en cache, et 5 à 20 k en sortie ; 5 à 10 minutes.
- Un **passage du parcours** (`/po-drive` sur deux stories : un chef, deux planners, deux implementers, deux reviewers, les ships) : 5 à 11 M de jetons traités, 40 à 100 k en sortie ; 20 à 60 minutes. Une boucle de correction ajoute 1,5 à 2,5 M.
- En dollars, au tarif d'API d'un grand modèle à 5 $ / 25 $ le million (entrée / sortie, cache lu à 10 %) : environ 1 $ par million traité, soit 0,3 à 2 $ un cas court et 5 à 11 $ un passage du parcours ; trois fois plus à 15 $ / 75 $. Sur un jeton d'abonnement (`claude setup-token`), c'est du quota, pas des dollars.
- **Incertitude** : un facteur 2 dans chaque sens (nombre de tours, taille de l'invite système, taux de cache). Le relevé de chaque passage garde le coût et l'usage que `claude -p` rend : le premier passage réel remplace cette estimation.

**Ce qu'il y aurait à mesurer.** 24 des 28 règles nommées par s206 ont un cas, et une dizaine de règles de sécurité gardées aussi : environ 34 règles sur une trentaine de cas, dont quatre du gabarit du parcours. Un bras règle sert toutes les règles d'un même cas ; chaque règle a son bras témoin. Pour N passages par bras : environ 64 × N passages, dont 9 × N longs. Les chiffres ci-dessous valent pour tout mesurer d'un coup ; mesurer une seule règle coûte 2 × N passages courts (ou longs pour le parcours).

## Considered Options
« Erreur » : la chance de retirer une règle utile (effet fort : 95 % de réussite avec la règle contre 40 % sans ; effet moyen : 95 % contre 70 %), et celle de garder une règle morte (les deux bras à 97 %, ou à 80 % quand le cas est bruité). Calculé par simulation, 20 000 tirages par cas de figure.

- **O1. Deux temps.** 3 passages par bras pour toutes les règles ; une règle dont le taux bouge d'au moins 1 est gardée. Une règle qui n'a rien bougé est remesurée sur 13 passages par bras, et n'est proposée au retrait que si l'écart reste sous 2. Retirer une règle utile : 0 % (fort), 12 % (moyen). Garder une morte : 10 % (stable), 40 % (bruité). Coût par règle : 6 passages si elle bouge, 32 sinon. Tout mesurer : environ 200 passages si toutes les règles bougent, jusqu'à 900 si aucune ne bouge, soit 400 M à 1,8 G de jetons, 400 à 1 800 $ à 5 $ / 25 $, 40 à 180 heures en série.
- **O2. Séquentiel.** Des lots de 3 par bras, jusqu'à 12 ; on s'arrête dès que l'écart atteint 2 (gardée), ou après 6 si les deux bras réussissent tout (proposée au retrait). Retirer une utile : 1 % (fort), 21 % (moyen). Garder une morte : 3 % (stable), 28 % (bruité). Coût par règle : 9 à 21 passages, 15 en moyenne. Tout mesurer : environ 450 passages, 900 M de jetons, 900 $, 90 heures.
- **O3. Fixe, 3 par bras** (la mesure de s113 à s119 dans `docs/evals/reuse-ladder.md`). Retirer une utile : 11 % (fort), 42 % (moyen). Garder une morte : 8 % (stable), 29 % (bruité). Tout mesurer : 192 passages, 380 M de jetons, 380 $ (1 100 $ à 15 $ / 75 $), 40 heures.
- **O4. Fixe, 10 par bras**, écart d'au moins 2. Retirer une utile : 1 % (fort), 26 % (moyen). Garder une morte : 3 % (stable), 20 % (bruité). Tout mesurer : 640 passages, 1,3 G de jetons, 1 270 $, 130 heures.
- **O5. Fixe, 20 par bras**, écart d'au moins 3. Retirer une utile : 0 % (fort), 13 % (moyen). Garder une morte : 1 % (stable), 16 % (bruité). Tout mesurer : 1 280 passages, 2,5 G de jetons, 2 500 $, 260 heures.

Dans toutes les options, un passage réel avant chaque publication est **un** passage du parcours, sans bras (5 à 11 $, 20 à 60 minutes) : il dit si un modèle suit encore la méthode de la version publiée, il ne fonde aucun retrait.

**Classement par les critères du porteur.** Ouvert ou auto-hébergeable, sobre en matériel : les cinq se valent (la commande est la nôtre, le modèle est payant dans tous les cas). Sobre en jetons payants : O3, puis O1 et O2, puis O4, puis O5. Passe à l'échelle : O1 et O2, qui dépensent là où la mesure hésite, et pas sur les règles qui bougent tout de suite. Facile pour une IA : O3, O4, O5 (un seul nombre), puis O1 (deux nombres fixes), puis O2 (une règle d'arrêt). D'où : **O1, O2, O3, O4, O5**. O3 est le moins cher mais passe après O1 et O2 : sur un effet moyen, il retire une règle utile quatre fois sur dix, l'erreur même que la story veut éviter.

## Decision Outcome
Option choisie : **O1**, par le porteur le 2026-11-23 (d-0057), parce qu'elle dépense là où un retrait est en jeu et garde l'erreur la plus coûteuse, retirer une règle utile, la plus basse parmi les options abordables.

Ce qui vaut désormais :
- **Rien n'est mesuré tant que personne ne propose de retirer une règle.** La mesure se fait alors règle par règle, sur les cas que le registre de `po-eval real` lui donne.
- **Premier temps** : 3 passages par bras. Une règle dont un taux a bougé d'au moins 1 est gardée.
- **Second temps** : une règle qui n'a rien bougé est remesurée à 13 passages par bras, et n'est proposée au retrait que si l'écart reste sous 2. La marge de `po-eval` vaut donc 1 jusqu'à 5 passages par bras, 2 au-delà.
- **Retirer reste la décision du porteur**, posée par la boîte avec le relevé daté ; la commande ne retire rien.
- **Avant chaque publication, un passage du parcours, sans bras**, cité par la publication.

Options écartées :
- **O2** (séquentiel) : des erreurs proches d'O1, pour un relevé plus difficile à lire et une règle d'arrêt de plus à tenir dans le code.
- **O3** (3 par bras, fixe) : le moins cher, mais il retire une règle utile à effet moyen quatre fois sur dix.
- **O4** (10 par bras) et **O5** (20 par bras) : trois à six fois le coût d'O3 sur toutes les règles, y compris celles qui bougent dès le troisième passage.

Ce qui rouvrirait la décision :
- un premier passage réel qui coûte plus de trois fois l'estimation ;
- des taux collés à 100 % dans les deux bras pour les arrêts que `po next` déclenche déjà, qui rendraient le second temps inutile ;
- un porteur pour qui garder une règle morte coûte autant que retirer une utile.

### Consequences
- Good, because la dépense va aux règles dont le retrait est en jeu, et le relevé dit pour chacune sur combien de passages elle a été mesurée.
- Bad, because une règle à effet moyen garde environ une chance sur huit d'être proposée au retrait à tort, et beaucoup de règles mortes restent : elles coûtent des mots, pas un comportement.
- Neutral: ces erreurs supposent des passages indépendants et un modèle qui ne change pas pendant la mesure ; un relevé daté nomme le modèle, et une mesure faite sur un autre modèle ne compte pas.
