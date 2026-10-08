---
adr: 0035
title: Le relevé de vérification tient un registre de lancements écrit par po-run, lu par po-gate
status: accepted
date: 2026-10-08
scope: story s56-evidence-runner
supersedes: []
superseded-by: []
---

# ADR-0035 — Le relevé de vérification tient un registre de lancements écrit par po-run, lu par po-gate

## Context and Problem Statement
Le relevé `docs/verif/<id>.md` est aujourd'hui une déclaration : l'implementer y recopie commandes et codes de sortie, et `po-gate verif-current` ne lit que `Tree:` et le statut. s56 fait écrire chaque lancement par un outil. Il faut fixer où vivent les lignes, comment la gate relie un contrôle déclaré à ses lancements, et comment l'arbre est calculé sans effet de bord.

## Considered Options
- **Un registre hors du dépôt (`~/…`, à la manière de gstack)** — impossible à éditer par l'agent dans le worktree, mais la preuve ne voyage plus avec la story, contrairement à la loi 6, et la revue sur une autre machine ne la voit pas.
- **Un fichier de lancements séparé (`docs/verif/<id>.runs`)** — le relevé rédigé ne peut plus effacer les lignes, mais deux fichiers par story, une forme de plus à apprendre à `po-status`, `po-drive` et aux evals.
- **Des lignes signées (HMAC avec une clé hors dépôt)** — rendrait une ligne forgée détectable, mais demande une clé à gérer par machine et par CI, et une revue ailleurs ne pourrait plus vérifier.
- **Correspondance par libellé seul** — simple, mais un lancement ciblé (`bash tests/run.sh plan.test.sh`) étiqueté « Unit suite » passerait pour la suite complète.
- **Retenu : une section `## Runs` à la fin du relevé, un tableau dont `po-run` ajoute une ligne par lancement (contrôle, commande, code, arbre, heure UTC) ; la section `## Checks` déclare les contrôles ; la gate exige, pour chaque contrôle déclaré dont la commande n'est pas `—`, une ligne de même libellé et de même commande sur le code de `Tree:` hors `docs/`, la dernière de ces lignes à 0. L'arbre est calculé par `git add -A` puis `git write-tree` sur une copie temporaire de l'index.**

## Decision Outcome
Chosen option: **la dernière**, parce qu'elle garde une seule preuve en git à côté du code, que la gate lit mécaniquement, et qu'une ligne ne peut compter que pour la commande réellement déclarée sur le code réellement livré.

### Consequences
- Good, because l'implementer ne recopie plus de résultat : un relevé réécrit qui perd ses lignes, ou un contrôle jamais lancé, fait refuser `verif-current`.
- Good, because seul le dernier lancement sur le code final compte : un échec suivi d'un succès sur un autre code ne passe pas.
- Good, because l'index de l'utilisateur n'est pas touché : `po-run` peut servir hors pipeline sans indexer ce qu'il n'a pas choisi.
- Bad, because une ligne reste un texte que l'agent peut écrire à la main ; la falsification délibérée n'est pas bloquée, seulement rendue visible à la revue (horodatage, arbre vérifiable par `git cat-file`).
- Bad, because les relevés au format précédent sont refusés : une lane en vol au moment du ship repasse par l'étape de code.
- Neutral: une commande déclarée doit être passée à `po-run` telle qu'elle est écrite dans `AGENTS.local.md` (un seul argument, lancé par `bash -c`), sinon la comparaison de commande échoue.
