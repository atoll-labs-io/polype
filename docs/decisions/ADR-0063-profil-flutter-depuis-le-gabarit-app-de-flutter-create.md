---
adr: 0063
title: Le profil Flutter part du gabarit app de flutter create, servi en web par le device web-server
status: accepted
date: 2026-10-08
scope: story s84-flutter-profile
supersedes: []
superseded-by: []
---

# ADR-0063 — Le profil Flutter part du gabarit `app` de `flutter create`, servi en web par le device `web-server`

## Context and Problem Statement
s84 demande un profil Flutter écrit depuis le gabarit d'application officiel à un commit nommé, dont la commande `Dev` sert le rendu web. Ce gabarit n'est pas un dépôt qu'on clone : ce sont des fichiers `.tmpl` à moustaches dans `flutter/flutter`, que `flutter create` assemble selon ses options. Il faut fixer quels gabarits font foi, à quel commit, et quelles commandes le profil retient pour `Dev` et `Build`, car `/po-setup` les copie et le pilote `mobile-web` les lance.

## Considered Options
- **`flutter/flutter` au tag stable `3.47.6` (`5fc346839b5d0eef006ed8404392afb4dfae428d`), gabarits `app` + `app_test_widget`** — ce que `flutter create <nom>` produit sans option (`create.dart:497`), BSD-3-Clause.
- **Le même commit avec `--empty`** — écarté : il supprime le test de widget et ne laisse qu'un `Hello World!`, sans rien à réutiliser ni de commande `Test` démontrée.
- **Le gabarit `skeleton`** — écarté : il n'existe plus dans `packages/flutter_tools/templates/` à ce commit.
- **Une app générée publiée dans un dépôt tiers** — écarté : non officielle, et elle figerait le choix de plateformes et d'options de quelqu'un d'autre.
- **`Dev` sur le device `chrome`** — écarté : il ouvre lui-même un navigateur dont le pilote ne règle pas la taille ; `web-server` sert seulement et imprime l'adresse (`web_device.dart:454`).
- **`Dev` avec `--web-port` fixe** — écarté : deux lanes parallèles se disputeraient le port ; sans lui l'outil prend un port libre et l'imprime.
- **`Build` natif (`flutter build apk` ou `ipa`)** — écarté comme commande du profil : il exige le SDK Android ou un Mac ; `flutter build web` tourne partout où `Dev` tourne. Les builds natifs restent nommés dans le profil.

## Decision Outcome
Chosen option: **les gabarits `app` et `app_test_widget` de `flutter/flutter` au tag `3.47.6`, `Dev: flutter run -d web-server`, `Build: flutter build web`**, parce que c'est exactement ce que `flutter create` livre par défaut à cette version, et que le device `web-server` donne au pilote `mobile-web` une adresse sans ouvrir de fenêtre.

### Consequences
- Good, because le profil se vérifie contre un commit précis par une extraction partielle de quelques mégaoctets, comme les autres profils (ADR-0010, ADR-0061).
- Bad, because « apporter le boilerplate à son commit » veut dire installer le SDK Flutter `3.47.6` et lancer `flutter create`, pas cloner un dépôt : le profil doit le dire.
- Bad, because le rendu web de Flutter dessine sur un canevas : les contrôles n'existent dans le DOM qu'une fois la sémantique activée, ce qui gêne la mesure des zones tactiles par le pilote.
- Neutral: une montée de version de Flutter change les gabarits ; le profil se réécrit alors à un nouveau tag.
