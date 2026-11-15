---
adr: 0125
title: La version de po se vérifie contre origin/<Target branch>, dans la suite
status: accepted
date: 2026-11-15
scope: story s182-po-change-needs-a-version
supersedes: []
superseded-by: []
---

# ADR-0125 — La version de `po` se vérifie contre `origin/<Target branch>`, dans la suite

## Context and Problem Statement
L'ADR-0122 veut qu'un diff qui touche `po/` monte la version. Aucun contrôle ne le vérifie : s176 (ceece03) a changé quatre fichiers de `po/` sans changer la version, et son check `suite` a réussi. Pour vérifier, il faut comparer le diff à une base. Or le checkout de `.github/workflows/ci.yml:15-21` est de profondeur 1 et prend la tête de la pull request dans le dépôt du fork : la base n'y est pas. `bin/po-ci` ne lit aucune variable de forge (ADR-0105). Le workflow n'a le droit qu'à deux étapes `run:`, `jq` et `bin/po-ci`, et à aucun `uses:` autre que `actions/checkout` (`tests/ci-on-every-pr.oracle.test.sh:73-89`). Deux questions sont donc à trancher : où vit le contrôle, et comment il trouve la base sur n'importe quelle forge.

## Considered Options
Classées par les critères du porteur : open source ou auto-hébergeable, sobre en matériel, capable de grandir, facile à manier pour une IA. Les trois options sont un script bash du dépôt, sans service ni dépendance : le premier critère ne les départage pas. Le deuxième non plus, en pratique : l'historique complet pèse 3,3 Mo pour 382 commits (mesuré le 2026-11-15).

- **A. Un script `bin/po-version-check [<base>]`, lancé par un test de la suite ; la base par défaut est `origin/<Target branch>` ; le checkout prend tout l'historique.** Sans argument, le script lit `Target branch` dans `AGENTS.local.md` et compare `merge-base(HEAD, origin/<Target branch>)..HEAD`, soit le diff de la story au sens de la loi « Ids and branches ». Le workflow perd son contournement `head_ref` (devenu inutile depuis s181, qui a corrigé #221) et ajoute `fetch-depth: 0`. Sur une pull request, le checkout prend alors le commit de fusion du dépôt de base, et `origin/*` contient les branches de ce dépôt, jamais celles d'un fork.
  - Pour : aucune variable de forge, ni dans `bin/po-ci` ni dans le script. Une base nommée `origin/<branche>` existe déjà sur toute machine de développeur et dans `story_base` (`method/hooks/po-bounds.sh:131-153`). La suite complète d'une story, lancée par `po-run` en fin d'exécution, voit le refus avant la CI. `bin/po-ci` et l'ADR-0105 ne changent pas.
  - Contre : le check juge le commit de fusion, non plus la tête de la pull request ; `docs/ci.md:11` est à réécrire. Un clone sans `origin/<Target branch>` voit la suite échouer en nommant la référence. Sur un push vers `main`, la base est `HEAD` et le contrôle ne vérifie rien : la pull request l'a déjà fait.
- **B. Le même script, lancé par `bin/po-ci` avant la commande `Test` ; même base, même checkout.**
  - Pour : un lancement ciblé de `tests/run.sh` ne passe jamais par ce contrôle. Ce qui n'est pas un test reste hors de la suite.
  - Contre : `bin/po-ci` fait alors deux choses (`bin/po-ci:2` dit « nothing else »). L'oracle de s159 (`test_ci_entry_runs_the_suite`, `tests/ci-on-every-pr.oracle.test.sh:20-53`) construit un dépôt sans `origin` : il serait à changer. Surtout, la commande `Test` que `po-run` lance en fin de story ne verrait plus le refus, qui n'arriverait qu'en CI.
- **C. Le script va chercher sa base lui-même (`git fetch --depth=<n> origin <Target branch>`) ; le checkout reste de profondeur 1.**
  - Pour : le checkout le plus léger, quelle que soit la profondeur qu'une forge choisit.
  - Contre : la suite fait un appel réseau et réécrit les références du dépôt où elle tourne. Hors ligne, elle échoue. Avec un checkout tiré du fork, `origin` est le fork. Un `merge-base` sur un historique tronqué peut ne rien trouver, et la profondeur à prendre est une supposition.

## Decision Outcome
Option choisie : **A**, par le porteur le 2026-11-15 (décision d-0029 de la boîte), en connaissant son coût (tout l'historique rapatrié à chaque run, 3,3 Mo aujourd'hui) et sa réserve : aucun run de CI n'a encore montré que le checkout de tout l'historique laisse `origin/main` du dépôt de base ; le check `suite` de cette story le tranche, et la preuve sur un vrai diff de `po/` vient avec s183. Elle ne lit rien de la forge, comme `bin/po-ci`. Elle fait voir le refus en local avant la CI. Elle ne touche pas à l'ADR-0105. Le coût qu'elle ajoute au checkout est négligeable à la taille du dépôt. B ne gagne sur aucun des quatre critères et perd la vérification en local. C n'est meilleure que sur la sobriété, de quelques mégaoctets, et ajoute un appel réseau à la suite.

### Consequences
- Good, because un numéro de version désigne un seul état de `po/` dès que la suite est obligatoire sur `main`, et une story le voit avant de pousser.
- Bad, because chaque run de CI rapatrie tout l'historique, et le check d'une pull request juge sa fusion avec la base au lieu de sa tête.
- Neutral: la preuve sur une vraie pull request qui touche `po/` vient de s183. Passer à Forgejo ne change rien : il lit `fetch-depth`, et une autre forge n'a qu'à laisser `origin/<Target branch>` dans son checkout.
