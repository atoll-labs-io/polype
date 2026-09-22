---
track: flow
validated: yes
---
# Plan (short track) — s38-migration

## Verified facts

- **Le tableau de correspondance existe déjà, en partie, dans `docs/conception.md:11-24`** : une ligne par brique (point d'entrée, cadrage, boilerplate, design system, cycle par story, parallélisme, revue, doctrine de tests, gates, suivi, décisions, multi-outil), avec une colonne « `/spec` + `/drive` actuels ». C'est la matière première de `docs/migration.md`, pas le document lui-même : elle compare trois sources pour concevoir Polype, elle ne dit pas au développeur quoi retirer ni comment reprendre un projet.
- **Assumption corrigée — `docs/conception.md:22` est périmé sur le suivi.** Il annonce pour Polype « état dans le tracker ». `docs/decisions/ADR-0018-ou-vit-letat-du-travail.md` (supersedes ADR-0003) tranche l'inverse : l'état se dérive des worktrees et de git, le tracker n'est qu'un miroir. Le document de migration doit suivre l'ADR-0018, pas la ligne 22 : dire qu'`octo`/`sensei` ne sont plus la source de vérité, et que le réglage `Tracker` (`none` ici) ne décide de rien.
- **Les fichiers à retirer, relevés sur la machine** : `~/.claude/skills/spec/` contient `SKILL.md`, `product-scaffold.md`, `interrogation.md` ; `~/.claude/skills/drive/` contient `SKILL.md`. Les subagents `octo` et `sensei` vivent à part, dans `~/.claude/agents/`, et servent aussi hors `/spec` (todo personnel) : ils ne se retirent pas avec les skills.
- **`polype remove --global` ne les enlèvera pas** : `docs/installation.md:57-60` dit que la pose globale « ne retire jamais un fichier qu'elle n'a pas posé ». `/spec` et `/drive` n'étant pas dans son manifeste, le retrait est manuel — c'est précisément ce que la story demande d'écrire.
- **Les deux poses cohabitent sans collision de noms** : Polype installe `po-*` dans `~/.claude/commands/` et ses skills sous `~/.claude/skills/<nom>/` (`docs/installation.md:38-46`). Aucun nom commun avec `spec`/`drive`. On peut donc installer Polype avant de retirer l'ancien, ce qui est l'ordre sûr.
- **Les helpers de test** sont dans `tests/lib.sh` : `ROOT` (`:5`), `fail` (`:11`), `require_file` (`:41`), `contains` (`:43`, `grep -qF`, donc exact et sensible à la casse). `tests/run.sh` exécute toute fonction `test_*` de chaque `tests/*.test.sh`, chacune dans son propre processus.
- **Modèle de test de documentation** : `tests/global-install.test.sh`, fonction `test_docs_explain_the_chezmoi_path` — `require_file` puis une suite de `contains` sur des phrases courtes, et un `grep` négatif contre une formule devenue fausse. Même forme attendue ici.
- **`tests/overlap.test.sh` ne regarde que `method/`** (`bin/ks-overlap:17` résout `../method`). Un document sous `docs/` n'est pas dans son périmètre — ce qui n'autorise rien : l'ADR-0006 interdit de reprendre du texte de Killer SaaS partout, et ce document n'en a de toute façon pas besoin.
- **Aucun fichier ne référence encore `docs/migration.md`** (recherche dans tout le dépôt). C'est s39 qui câblera le renvoi depuis `README.md` et l'aide ; s38 écrit le document seul.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — le mot « migration » nomme le sujet du document, pas une migration de données ou de schéma ; les livrables annoncés par `Owns` sont un `.md` et un `.test.sh` | absent — aucun état persistant n'est touché : le document est créé ex nihilo, le test est un nouveau fichier |
| New screen | absent — la story ne décrit aucune interface | absent — le dépôt n'a pas de `docs/design-system.md` et ne rend aucun écran |
| Authorization or tenant scope | absent — rien sur les droits dans la story | absent — aucun code exécuté par un utilisateur n'est touché |
| API contract | absent — aucune interface entre programmes annoncée | absent — le test n'appelle que `bash tests/run.sh` et les helpers de `tests/lib.sh`, inchangés |
| New dependency | absent — la story ne nomme aucun outil | absent — le test tient avec bash, `grep` et `sed`, déjà utilisés par la suite |

## Story

**En tant que** développeur **je veux** savoir exactement quoi retirer et comment reprendre mes projets en cours **afin de** passer de `/spec` et `/drive` à Polype sans perdre de travail.

Critères d'acceptation, chacun porté par la fonction de test du même nom :
- `migration_maps_every_old_concept` — correspondance de chaque notion de `/spec` et `/drive` vers Polype (brief, stories, packets, worktrees, tracker, autonomie) et ce qui disparaît.
- `migration_gives_a_step_by_step_removal` — liste des fichiers à retirer de `~/.claude/skills/` et vérifications préalables.
- `migration_covers_a_project_in_flight` — reprise d'un projet qui a déjà des packets en cours.
- `migration_doc_is_checked_by_a_test` — le document existe, couvre les deux skills, ne renvoie vers aucun chemin inexistant.

## Tasks

1. [x] **`docs/migration.md` — la table de correspondance.** Une ligne par notion de `/spec` et `/drive`, sa contrepartie Polype et son sort. Au minimum : brief, gap map / pre-mortem, ADR et user stories, packet, `owns`, acceptation exécutable, worker, worktree, branche d'intégration, lane, tracker (`octo`/`sensei`), autonomie du driver. Une colonne dit explicitement ce qui **disparaît** (branche d'intégration → squash direct sur `Target branch` par ADR-0015 ; état écrit dans le tracker → état dérivé par ADR-0018 ; `/record-adr` vers le vault → ADR dans `docs/decisions/` par ADR-0002). Suit `docs/conception.md:11-24` pour les faits, l'ADR-0018 pour le suivi. → `test_migration_maps_every_old_concept` échoue si une notion manque.
2. [x] **`docs/migration.md` — le retrait, pas à pas.** Les quatre fichiers nommés plus haut, l'ordre sûr (installer Polype d'abord, vérifier, retirer ensuite), les vérifications avant de supprimer (aucun projet en cours ne dépend d'un packet non repris ; `octo`/`sensei` gardés car utilisés ailleurs ; `polype remove --global` ne fera pas ce travail), et le fait que ces chemins vivent hors du dépôt. → `test_migration_gives_a_step_by_step_removal`.
3. [x] **`docs/migration.md` — un projet en vol.** Comment reprendre un dépôt qui a déjà des packets : que devient la branche d'intégration existante, comment les packets restants se réécrivent en stories dans `docs/stories.md`, ce qu'il faut faire des worktrees ouverts par `/drive`, et à partir de quel état on lance `polype init` puis `/po-setup`. → `test_migration_covers_a_project_in_flight`.
4. [x] **`tests/migration-doc.test.sh`.** Quatre fonctions, une par critère. Les trois premières citent des phrases courtes et exactes du document via `contains`. La quatrième : `require_file`, puis les deux skills nommés (`/spec` et `/drive`), puis la résolution des chemins — tout jeton entre accents graves commençant par `docs/`, `method/`, `bin/` ou `tests/` doit exister sous `$ROOT`, et toute commande `/po-<nom>` citée doit avoir son `method/commands/po-<nom>.md`. Le test doit prouver qu'il mord : il compte les chemins qu'il a résolus et échoue s'il n'en a vu aucun. → `test_migration_doc_is_checked_by_a_test`.

## Run interdicts

- `docs/parite-killer-saas.md` doit finir avec un diff vide : la ligne H01 appartient à s39 (`Owns` de s39), pas à cette story, bien que la story cite « H01 (volet migration) ».
- `README.md`, `method/AGENTS.md` et `method/commands/po-help.md` : diff vide. Le câblage des renvois est le travail de s39.
- Aucun fichier de `method/`, `bin/` ou `.claude/` n'est modifié : la story ne change pas la méthode, elle la documente.
- Rien n'est écrit, déplacé ou supprimé sous `~/.claude/` : le document décrit le retrait, il ne l'exécute pas.
- Aucun test existant n'est modifié.

## Files touched

- `docs/migration.md` (créé)
- `tests/migration-doc.test.sh` (créé)
- `docs/plans/s38-migration.md`, `docs/verif/s38-migration.md` (l'évidence de la story)

## Test strategy

Un seul fichier, `tests/migration-doc.test.sh`, quatre fonctions — bien en deçà du `Test budget` de 25. Couche unique : ce sont des assertions sur un artefact de documentation, il n'existe pas d'autre couche où les poser. Rien n'est testé deux fois ailleurs dans la suite.

Le piège que la doctrine appelle un faux test est ici précis : un test qui se contente de `require_file` passerait sur un document vide. Chaque fonction cite donc une phrase exacte que seul le contenu attendu porte, et la quatrième compte les chemins qu'elle a effectivement résolus — un document sans aucun chemin la fait échouer, ce qui interdit de la satisfaire en retirant les renvois.

Suite complète en fin d'exécution (`Full suite: execute-end`), `bash tests/run.sh`, et l'enregistrement dans `docs/verif/s38-migration.md` (`Verification mode: record`).

## Done when

- `docs/migration.md` et `tests/migration-doc.test.sh` existent, commités en un commit sur `story/s38-migration` avec le plan et la vérif ;
- `bash tests/run.sh` est vert en entier, les 4 nouvelles fonctions comprises ;
- les interdits ci-dessus tiennent : `git diff m5-distribution...story/s38-migration --name-only` ne liste que les fichiers de la section « Files touched » ;
- revue sans finding critique ouvert.
