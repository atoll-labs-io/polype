---
adr: 0057
title: qa choisit son pilote par la surface et la plateforme, le lit dans le dossier de la skill chargée, et un profil nomme un pilote que po-lint vérifie
status: accepted
date: 2026-10-08
scope: story s79-qa-drivers
supersedes: []
superseded-by: []
---

# ADR-0057 — qa choisit son pilote par la surface et la plateforme

## Context and Problem Statement
ADR-0054 donne la table des pilotes de QA et ADR-0055 la table des surfaces admises par chaque plateforme. Quatre points restent ouverts et `qa` doit les trancher sans interpréter : quel pilote pour une story `screen` quand `Platform` déclare à la fois `web` et `mobile` ; où lire le fichier d'un pilote, alors que les skills sont posées dans `~/.claude/skills/` ou dans `.claude/skills/` selon l'installation ; ce que vaut la section `## QA driver` d'un profil ; ce que fait `qa` quand l'arbre n'est plus propre après son passage.

## Considered Options
- **`screen` avec `web` et `mobile` : les deux pilotes, `browser` puis `mobile-web`** — retenue. Aucune donnée de la story ne dit quel rendu elle vise ; passer les deux ne demande aucune lecture du texte.
- **`screen` avec `web` et `mobile` : deviner d'après les fichiers du diff** — écartée : c'est l'interprétation qu'ADR-0054 refuse (« deviner la plateforme depuis le code »).
- **`screen` avec `web` et `mobile` : le pilote du profil de boilerplate** — écartée : le profil n'est pas recopié dans `AGENTS.local.md`, `qa` ne le lit pas, et un projet sans profil n'aurait pas de réponse.
- **Fichier du pilote lu dans le dossier de base annoncé pour la skill chargée** — retenue. Il vaut pour la pose globale comme pour la pose projet.
- **Fichier lu à `.claude/skills/qa-drivers/<pilote>.md` du worktree** — écartée : faux après `polype install --global`, où la skill vit dans `~/.claude/skills/`.
- **Ligne `- QA driver: <nom>` dont `po-lint` vérifie qu'elle nomme un fichier `method/skills/qa-drivers/<nom>.md` autre que `SKILL.md`, ou `—`** — retenue, pour la raison d'ADR-0055 : une section libre laisserait passer `Browser` ou `navigateur` sans que personne le voie.
- **Section `## QA driver` exigée, contenu libre** — écartée pour la même raison.
- **Liste des pilotes écrite dans `po-lint`** — écartée : une deuxième liste à tenir, alors que les fichiers de la skill sont la liste.
- **Arbre sale après la QA (un changement hors `docs/qa/<id>/`) : `QA status: blocked` en nommant les chemins, rien supprimé** — retenue : `qa` ne répare pas (Loi 2), et une suppression pourrait toucher un fichier qui n'est pas le sien.
- **Arbre sale : `qa` supprime ce qu'il a laissé** — écartée pour la même raison.

## Decision Outcome
Chosen option: **les deux pilotes pour `screen` sur `web` et `mobile`, le fichier lu dans le dossier de base de la skill chargée, une ligne `- QA driver:` vérifiée contre les fichiers de `qa-drivers`, et un arbre sale qui bloque la QA**, parce que chaque cas se décide alors sur des faits que `qa` et `po-lint` lisent sans interpréter de prose.

- Un fichier de pilote absent, ou un dossier de base que la session n'annonce pas : `QA status: blocked`, la cause écrite dans le rapport.
- Une story sans ligne `Surface` suit l'ancienne règle : `screen` si son texte montre un écran, sinon rien à vérifier.

### Consequences
- Good, because un pilote ajouté par une story suivante (`mobile-web`, `scenarios`, `scene`, `simulation`) devient valable pour les profils dès que son fichier existe, sans toucher `po-lint`.
- Bad, because un projet `web, mobile` passe deux pilotes sur chaque story `screen`, et reste bloqué en QA d'écran tant que `mobile-web.md` n'existe pas (s82).
- Neutral: un profil dont le pilote n'est pas encore écrit (natif iOS ou Android) écrit `- QA driver: —` ; le jour où l'émulateur arrive, son fichier de pilote rend la valeur acceptable.
