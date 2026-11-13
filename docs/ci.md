# Intégration continue

## Ce qui tourne

Une seule entrée : `bin/po-ci`. Elle lit la commande `Test` de `AGENTS.local.md` (ici `bash tests/run.sh`, la suite complète) et la lance depuis la racine du dépôt, en transmettant sa sortie et son code de retour. Elle ne lit aucune variable de la forge et ne lance jamais `po-eval`, dont chaque run est payant (ADR-0105). Lancée à la main, elle fait exactement ce que fait la CI.

## Où

Sur les runners hébergés de GitHub, par `.github/workflows/ci.yml` : à chaque pull request et à chaque push sur `main`. Le job s'appelle `suite` ; il installe `jq` s'il manque, puis appelle `bin/po-ci`, sans autre étape. Le jeton du workflow n'a que le droit de lecture, et `actions/checkout` est épinglé sur un commit.

Sur une pull request, le checkout prend la tête de la branche et la pose en branche locale, pas le commit de fusion détaché que GitHub prend par défaut : la suite clone le dépôt et y lance `git pull`, qui refuse une HEAD détachée. Le check juge donc la tête de la pull request ; au ship, cette tête est le commit d'atterrissage, posé sur `main`.

Passer à Forgejo Actions revient à déplacer ce fichier : Forgejo lit la même syntaxe (#75), et l'installation de `jq` se passe de `sudo` quand le runner tourne en root.

## Ce que fait `Forge checks: required`

Avec `Forge checks: required` dans `AGENTS.local.md`, `/po-ship` en mode automatique attend que les checks de la forge passent sur le commit d'atterrissage avant de fusionner. Un check rouge, aucun check au bout de 30 minutes, ou une forge que `gh` ne sait pas lire : le ship s'arrête, la pull request reste ouverte, et la personne reçoit la liste des checks en échec avec leur lien. Avec `—`, ou sans la ligne, `/po-ship` fusionne comme avant.

## Le geste de la personne

Aucun agent ne règle la protection de `main`. Pour exiger le check sur GitHub :

1. Settings → Rules → Rulesets (ou Settings → Branches → règle de protection) pour `main`.
2. Cocher « Require status checks to pass ».
3. Ajouter le check `suite`.

Le check `suite` n'est proposé qu'après avoir tourné une première fois sur le dépôt.
