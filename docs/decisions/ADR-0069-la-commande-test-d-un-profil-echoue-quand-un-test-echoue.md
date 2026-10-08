---
adr: 0069
title: La commande Test d'un profil échoue quand un test échoue — iOS lit le bundle de résultats après la lane, Expo n'installe rien à la volée
status: accepted
date: 2026-10-08
scope: story s95-profiles-hold
supersedes: [ADR-0062, ADR-0064]
superseded-by: []
---

# ADR-0069 — La commande Test d'un profil échoue quand un test échoue

## Context and Problem Statement
`/po-setup` copie la commande `Test` d'un profil dans `AGENTS.local.md`, puis `po-run` inscrit son code de sortie au relevé et la gate « Record current » s'y fie. Deux profils donnent une commande qui ne dit pas l'échec. iOS (ADR-0064) garde `bundle exec fastlane buildAndTest`, dont la lane appelle `scan` avec `failBuild: .userDefined(false)` (`template/fastlane/Helpers/Test.swift:33` de `ios-templates` à `f009d02`) : un test rouge sort en 0 (revue de s85, F1). Expo (ADR-0062) donne `npx jest`, qui sur un projet sans jest propose ou fait le téléchargement du dernier jest, sans le preset `jest-expo` (revue de s83). Cette ADR remplace **en partie** ADR-0062 et ADR-0064, sur la seule commande `Test` ; leurs sources, commits, plateformes, pilotes et autres commandes restent.

## Considered Options
- **iOS : la lane, puis le bundle de résultats lu par `xcresulttool`** — `rm -rf fastlane/test_output && bundle exec fastlane buildAndTest && xcrun xcresulttool get test-results summary --path fastlane/test_output/*.xcresult | grep -Eq '"result" *: *"Passed"'`. Le dossier est vidé d'abord (il est ignoré par git, `.gitignore:57`) pour qu'aucun bundle ancien ne réponde ; le motif évite le nom du schéma ; un bundle absent, une erreur de l'outil ou un résultat autre que `Passed` donnent un code non nul.
- **iOS : `xcodebuild test` direct** — écarté, comme dans ADR-0064 : le schéma vaut `"<nom du projet> Staging"`, une commande à trou ne se copie pas telle quelle.
- **iOS : `SCAN_FAIL_BUILD=true` devant la lane** — écarté : un paramètre passé explicitement à `scan` l'emporte sur la variable d'environnement.
- **iOS : une première story passe `failBuild` à vrai** — écarté : c'est de la prose ; d'ici là, la gate accepte des tests rouges.
- **iOS : `Test: —`** — écarté : le projet perd sa suite unitaire alors que le gabarit en a une, et le critère `test_commands_fail_on_red` demande une commande qui échoue.
- **Expo : `npx --no-install jest`** — retenu : sans jest installé il sort en erreur (`npx canceled due to missing packages`, code 1, npm 12) au lieu de télécharger ; une fois `jest-expo` et `jest` installés par une story, il lance ce jest-là.
- **Expo : `npx jest`** — écarté : installe à la volée un jest sans preset, dont le résultat ne dit rien du projet.
- **Expo : `npm test`** — écarté, comme dans ADR-0062 : le guide l'écrit en `jest --watchAll`, qui ne rend jamais la main.

## Decision Outcome
Chosen option: **la lane suivie de la lecture du bundle par `xcresulttool` pour iOS, `npx --no-install jest` pour Expo**, parce que ce sont les seules commandes qui, copiées telles quelles, sortent en erreur sur un test rouge sans toucher au code généré ni à un nom de projet.

### Consequences
- Good, because le code de sortie que `po-run` inscrit dit enfin l'état des tests sur ces deux profils.
- Bad, because la commande iOS n'a été lancée sur aucun Mac : le format `"result" : "Passed"` de `xcresulttool get test-results summary` (Xcode 16 et suivants, le gabarit demande Swift 6.1) est lu dans sa documentation, pas observé. Une personne avec un Mac la lance une fois verte et une fois rouge.
- Bad, because une lane qui ne trouve aucune cible de test (« Nothing to test ») ne laisse pas de bundle : `Test` échoue alors au lieu de passer, ce qu'on accepte (échec fermé).
- Neutral: `failBuild` reste à faux dans le gabarit ; si une story le passe à vrai, la commande reste juste.
