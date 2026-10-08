---
adr: 0038
title: po-bounds lit les Owns au point de départ de la story et en définit la syntaxe
status: accepted
date: 2026-10-08
scope: story s61-bounds-owns
supersedes: [ADR-0024]
superseded-by: []
---

# ADR-0038 — po-bounds lit les Owns au point de départ de la story et en définit la syntaxe

## Context and Problem Statement
ADR-0024 lit les `Owns` dans `HEAD:docs/stories.md` du worktree de la story. `docs/` reste inscriptible et `git commit` est permis sur `story/*` : un commit de la story élargit ses propres bornes (revue de s50, majeur 1). Ce point d'ADR-0024 est remplacé ici ; ses autres choix (story tirée du worktree visé, `jq`, analyse Bash en mots) restent. Le script ne lit aucun réglage et rien n'enregistre la branche d'où la story est partie : il faut décider d'où vient ce point de départ, et quelle syntaxe d'entrée `Owns` le script accepte (majeur 2 : globs refusés, entrées sans backticks ignorées).

## Considered Options
- **Garder `HEAD`** — l'auto-élargissement par commit reste ouvert.
- **Refuser toute écriture de `docs/stories.md` à l'implementer** — ferme un chemin seulement ; un commit via un autre outil élargit toujours, et `docs/` cesse d'être entièrement inscriptible.
- **Lire à la pointe de la branche cible** — voit une correction humaine faite pendant la lane, mais les bornes d'une lane changent sous elle pendant qu'elle tourne, et la story demande le point de départ.
- **Base de fusion avec `Target branch` lu dans `AGENTS.local.md`** — exacte, mais le script se met à lire un réglage, ce qu'ADR-0024 évitait comme `po-gate`.
- **Base de fusion avec l'upstream de `story/<id>`** — posé seulement quand la story part d'une branche distante ; absent pour un dépôt sans remote.
- **Base de fusion avec la branche du worktree principal et son upstream** — la Loi 4 tient la racine sur `Target branch` ; `git merge-base HEAD <branche> [<branche>@{upstream}]` rend le point de départ que la story soit partie de la branche locale ou de sa copie distante, sans réglage.
- **Syntaxe : chemins entre backticks, préfixes de dossier, globs `*`/`**`, le reste refusé en le nommant** — contre « ignorer ce qui ne se lit pas » (l'état actuel, qui échoue en silence) et contre des globs complets `?`, `[…]`, `{…}` (plus de surface, aucun besoin relevé).

## Decision Outcome
Chosen option: **base de fusion avec la branche du worktree principal et son upstream**, et **syntaxe stricte** : une entrée est un chemin relatif entre backticks, un dossier finissant par `/`, ou un glob où `*` couvre un segment et `**`, segment entier, en couvre zéro ou plusieurs ; les entrées sont séparées par des virgules ; tout autre texte de la ligne, et toute entrée avec `/` en tête, un segment `.`/`..`/vide, ou `?`, `[`, `]`, `{`, `}`, est refusé en le nommant, même si une autre entrée couvre le chemin. Parce que chacun échoue fermé : racine détachée ou nue, aucune base de fusion, story absente au point de départ → refus.

### Consequences
- Good, because un commit de la story sur `docs/stories.md` ne change plus rien à ses bornes.
- Good, because un projet écrit `crates/*/Cargo.toml` ou `crates/**/tests/` et son implementer n'est plus bloqué.
- Bad, because une correction d'`Owns` committée sur `Target branch` après le départ de la lane ne l'atteint pas : il faut fusionner `Target branch` dans la story, ce qui avance la base, ou relancer la lane. Le refus dit le commit où il a lu les `Owns`.
- Bad, because une racine laissée sur une autre branche que `Target branch` donne une autre base ; la Loi 4 l'interdit déjà, et une base plus ancienne qui ne connaît pas la story fait refuser.
- Neutral: le shell de l'implementer peut toujours déplacer une branche (`git update-ref`) ; le modèle reste l'erreur, pas l'hostilité, et la revue garde son contrôle d'ownership. `/po-drive` et la revue comparent les `Owns` en lisant : ils devront lire les globs selon la même syntaxe.
