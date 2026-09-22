# Migration — `/spec` et `/drive` retirés, nautile repris

Date : 2026-09-22.

## Sur la machine

`/spec` et `/drive` sont retirés de `~/.claude/skills/` **et** de la source chezmoi, commit `0e9aedd` des dotfiles, poussé. Leur contenu reste récupérable dans l'historique du dépôt de dotfiles. Les trois renvois des instructions globales pointent maintenant vers Polype : le titre de la section, la ligne qui lançait `/spec` puis `/drive`, et la ligne qui distinguait les couches de décision.

Polype est installé globalement (version 0.2.0) et son dépôt est publié en privé : `atoll-io/polype`.

## Le projet repris : nautile

`~/dev/atoll/nautile` portait un spec `/spec` de 937 lignes, 19 packets, déposés en 20 issues GitHub. La reprise a produit, sur la branche `migrate-to-polype` (PR `atoll-io/nautile#21`) :

- `docs/brief.md` — le cadre : one-liner, wedge, non-objectifs, métriques de succès, règles non négociables, defaults (stack, moteur de stockage, noms de crates gelés, niveaux de confiance, tenant, scope), et ce qui ne se rattrape pas après coup ;
- `docs/stories.md` — 20 stories, une par packet, F05 découpée en deux le long d'un crate que la spec isolait déjà. Chaque story nomme son packet d'origine et son issue, et garde ses noms de tests : les 157 noms de la spec s'y retrouvent, aucun ajouté ni renommé ;
- Polype installé dans le dépôt (`.polype/`, `AGENTS.md`, `AGENTS.local.md`) : merge local sur `main`, plans validés en autonome, ship automatique, trois lanes.

`docs/specs/nautile.md` reste comme référence, amené sur la branche depuis `spec/nautile`.

## Ce que la reprise a révélé

Huit incohérences du spec d'origine, laissées telles quelles et signalées dans les notes des stories concernées : la propriété de `CLAUDE.md` et de `docs/architecture.md`, un test qui lit une forme définie par un packet livré plus tard, deux tests homonymes entre deux packets, un budget jamais défini, et une liste de constantes dont personne ne documente l'emplacement. Une migration est un bon relecteur : elle oblige à traduire chaque ligne, donc à la comprendre.
