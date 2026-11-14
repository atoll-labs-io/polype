# Intégration continue

## Ce qui tourne

Une seule entrée : `bin/po-ci`. Elle lit la commande `Test` de `AGENTS.local.md` (ici `bash tests/run.sh`, la suite complète) et la lance depuis la racine du dépôt, en transmettant sa sortie et son code de retour. Elle ne lit aucune variable de la forge et ne lance jamais `po-eval`, dont chaque run est payant (ADR-0105). Lancée à la main, elle fait exactement ce que fait la CI.

## Où

Sur les runners hébergés de GitHub, par `.github/workflows/ci.yml` : à chaque pull request et à chaque push sur `main`. Le job s'appelle `suite` ; il installe `jq` s'il manque, puis appelle `bin/po-ci`, sans autre étape. Le jeton du workflow n'a que le droit de lecture, et `actions/checkout` est épinglé sur un commit.

Sur une pull request, le checkout prend la tête de la branche et la pose en branche locale, pas le commit de fusion détaché que GitHub prend par défaut : la suite clone le dépôt et y lance `git pull`, qui refuse une HEAD détachée. Le check juge donc la tête de la pull request ; au ship, cette tête est le commit d'atterrissage, posé sur `main`.

Passer à Forgejo Actions revient à déplacer ce fichier : Forgejo lit la même syntaxe (#75), et l'installation de `jq` se passe de `sudo` quand le runner tourne en root.

## Publier une version

1. Monter ensemble `POLYPE_VERSION` dans `bin/polype` et `version` dans `po/Cargo.toml` :
   `bin/po-release` refuse de construire quand elles diffèrent.
2. Poser le tag `v<version>` sur `main` et le pousser.
3. `.github/workflows/release.yml` crée la release du tag, puis, sur un runner par plateforme
   (`linux-x86_64`, `linux-aarch64`, `macos-aarch64`), appelle `bin/po-release dist` et publie
   `po-<version>-<plateforme>` et son `.sha256`.
4. Une pull request colle les lignes des `.sha256` dans le bloc `PO_SUMS` de `bin/polype`. Tant
   qu'elle n'a pas atterri, les installeurs compilent `po` depuis les sources.

`bin/po-release` ne lit aucune variable de la forge, comme `bin/po-ci`. Sur Forgejo, seule change
l'étape qui publie (`gh release`) ; l'appel à `bin/po-release` reste le même (ADR-0105, ADR-0121).

## Ce que fait `Forge checks: required`

Avec `Forge checks: required` dans `AGENTS.local.md`, `/po-ship` en mode automatique attend que les checks de la forge passent sur le commit d'atterrissage avant de fusionner. Un check rouge, aucun check au bout de 30 minutes, ou une forge que `gh` ne sait pas lire : le ship s'arrête, la pull request reste ouverte, et la personne reçoit la liste des checks en échec avec leur lien. Avec `—`, ou sans la ligne, `/po-ship` fusionne comme avant.

## Le geste de la personne

Aucun agent ne règle la protection de `main`. Pour exiger le check sur GitHub :

1. Settings → Rules → Rulesets (ou Settings → Branches → règle de protection) pour `main`.
2. Cocher « Require status checks to pass ».
3. Ajouter le check `suite`.

Le check `suite` n'est proposé qu'après avoir tourné une première fois sur le dépôt.
