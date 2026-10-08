---
adr: 0064
title: Les profils natifs partent de nimblehq/ios-templates et d'android/architecture-templates, sans Dev ni pilote de QA
status: accepted
date: 2026-10-08
scope: story s85-native-profiles
supersedes: []
superseded-by: [ADR-0069]
---

# ADR-0064 — Les profils natifs partent de `nimblehq/ios-templates` et d'`android/architecture-templates`, sans `Dev` ni pilote de QA

## Context and Problem Statement
s85 demande un profil iOS en Swift et un profil Android en Kotlin, chacun écrit depuis un gabarit de départ public sous licence libre à un commit nommé. Apple ne publie pas ses gabarits Xcode sous licence libre, et une app native n'a pas de rendu web : il faut fixer les sources, les commandes que `/po-setup` copiera, et ce que le profil déclare comme pilote de QA alors qu'aucun pilote ne lance un simulateur ou un émulateur.

## Considered Options
- **iOS : `nimblehq/ios-templates`, branche `develop`, commit `f009d02ebaacf3c789c84bd31d9baa2b2447d654`** — gabarit de départ SwiftUI maintenu, MIT, modules SPM, projet généré par Tuist via `iOSTemplateMaker`.
- **iOS : `nalexn/clean-architecture-swiftui`** — écarté : une app de démonstration (pays du monde), pas un gabarit de départ ; dernier commit en juillet 2025.
- **iOS : `kudoleh/iOS-Clean-Architecture-MVVM`** — écarté : aucun fichier de licence.
- **iOS : les gabarits de projet d'Xcode** — écarté : livrés avec Xcode, sans dépôt public ni licence libre.
- **Android : `android/architecture-templates`, branche `base`, commit `5467a8dcca30a81b4e31fda5863dd6c65836de0d`** — gabarit officiel mono-module, Apache-2.0, Compose, Hilt, Room, Navigation 3.
- **Android : la branche `multimodule` du même dépôt** — écarté : plus de modules à décrire pour le même contenu, et `base` est celle que le README fait cloner.
- **Android : `android/nowinandroid`** — écarté : une app d'exemple complète, pas un point de départ.
- **`- QA driver: mobile-web`** — écarté : aucune des deux apps n'a de rendu web, `mobile-web` exige un `Dev` qui le sert.
- **`- QA driver: —` et `Dev: —`** — retenu : le profil dit que le pilote web ne s'applique pas, et la QA d'écran reste bloquée jusqu'à un pilote simulateur ou émulateur.
- **iOS `Test` en `xcodebuild test` direct** — écarté : le nom du schéma dépend du nom de projet choisi au lancement du générateur, une commande à trou ne se copie pas telle quelle.

## Decision Outcome
Chosen option: **`nimblehq/ios-templates` à `f009d02` et `android/architecture-templates` (`base`) à `5467a8d`, plateforme `mobile`, `QA driver: —`, `Dev: —`**, parce que ce sont les seuls gabarits de départ publics, maintenus et sous licence libre trouvés pour chaque pile, et qu'un profil ne doit pas promettre une QA qu'aucun pilote ne sait faire.

iOS garde `Test: bundle exec fastlane buildAndTest`, la commande que le gabarit documente, et le profil signale que `scan` y tourne avec `failBuild: false`, si bien qu'un test rouge ne fait pas échouer le code de sortie tant qu'une story ne l'a pas changé.

### Consequences
- Good, because chaque profil se vérifie contre un commit précis par un clone superficiel, comme les profils précédents (ADR-0061, ADR-0063).
- Bad, because toutes les commandes iOS exigent un Mac avec Xcode, et aucune n'a été lancée ici ; Android exige le SDK et un JDK 17, pas lancés non plus.
- Bad, because une story à écran sur ces profils s'arrête à la QA tant qu'aucun pilote simulateur ou émulateur n'existe : elle passe par un humain.
- Neutral: le générateur iOS déplace et supprime des fichiers (dont `AGENTS.md` et `CLAUDE.md` à la racine) ; le profil décrit l'arbre généré et dit de générer hors du dépôt Polype.
