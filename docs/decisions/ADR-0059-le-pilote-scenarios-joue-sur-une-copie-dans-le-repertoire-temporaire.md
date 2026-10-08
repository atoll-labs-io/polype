---
adr: 0059
title: Le pilote scenarios joue ses scénarios sur une copie du code dans le répertoire temporaire, et démarre lui-même le service sur un port libre de la boucle locale
status: accepted
date: 2026-10-08
scope: story s81-scenario-driver
supersedes: []
superseded-by: []
---

# ADR-0059 — Le pilote scenarios joue sur une copie dans le répertoire temporaire

## Context and Problem Statement
Une story `command` ou `endpoint` se vérifie en lançant le programme : il faut l'installer, souvent le construire, puis l'exécuter ou démarrer un service et l'interroger. Les outils de build écrivent dans le dossier du projet (`target/`, `dist/`, `node_modules/`), le plus souvent ignoré par git, si bien que `git status --porcelain`, que `qa` relance après sa visite, ne le voit pas ; et le mode `qa` de `po-bounds` refuse l'outil Write hors de `docs/qa/<id>/` et toute commande git qui écrit. `qa-drivers` permet un répertoire `mktemp -d` comme seule exception, sans dire ce qui y est joué. Pour une API, ni ADR-0054 ni le gabarit de réglages (`Dev` ne vaut que pour `screen`) ne disent comment démarrer le service sans heurter un service déjà lancé sur la machine.

## Considered Options
- **Jouer dans le worktree et rediriger la sortie de chaque outil** (`CARGO_TARGET_DIR`, `--outDir`…) — une règle par outil, et un outil sans option de sortie salit le worktree sans que `status --porcelain` le montre.
- **Jouer dans le worktree puis effacer ce qui a été produit** — `qa` ne retire rien de ce qu'il n'a pas créé, et rien ne distingue sûrement un fichier ignoré produit par la visite d'un fichier du développeur.
- **Un second worktree dans le répertoire temporaire** — `git worktree add` est refusé par le mode `qa` de `po-bounds`, qui ne laisse passer que `worktree list`.
- **Une copie des fichiers suivis (et des `.env*` ignorés) dans le répertoire `mktemp -d`, installée, construite et jouée là** — retenue.
- **Pour le service : réutiliser `Dev`** — `Dev` sert ce qu'une personne regarde, ne vaut que pour `screen` (gabarit de réglages), et son port est souvent fixe, donc partagé avec un serveur que le développeur a déjà lancé.

## Decision Outcome
Chosen option: **la copie dans le répertoire temporaire**, parce qu'elle laisse le worktree intact par construction, quel que soit l'outil de build, sans demander à `po-bounds` un seul verbe de plus.

- Le pilote copie les fichiers que liste `git ls-files` (le code commité, puisque `qa` s'arrête sur tout changement hors de `docs/`) et les `.env*` ignorés dans un sous-dossier du répertoire `mktemp -d`, y lance `Install` puis `Build` quand ils ne sont pas `—`, et exécute chaque scénario depuis un dossier de travail lui aussi dans le répertoire temporaire.
- Seules les transcriptions vont dans `docs/qa/<id>/` du worktree.
- Un service se démarre par la commande que le projet a écrite pour le lancer (réglages, conventions, profil nommé dans les conventions, README), jamais inventée ; sur `127.0.0.1` et un port où rien ne répondait avant, passé par la variable ou l'option que cette commande documente ; dans son propre groupe de processus, que le pilote arrête à la fin. Une commande introuvable, ou un service qui écoute ailleurs que sur ce port, arrête la QA en `blocked`.

### Consequences
- Good, because ni un build ni un fichier écrit par le programme testé ne peuvent atteindre le worktree, et la visite ne touche ni un port ni un processus qu'elle n'a pas ouverts.
- Bad, because l'installation est refaite dans la copie à chaque QA (temps, réseau), et les profils de s86 doivent écrire une commande de lancement dont le port se choisit.
- Neutral: les dépendances qu'un service atteint par son environnement (base de données, API tierce) ne sont pas démarrées par le pilote ; un critère qui n'apparaît qu'à travers elles va dans `## Not seen`. Le mode `qa` refusant `git init`, un scénario qui a besoin d'un dépôt git de test ne peut pas le construire.
