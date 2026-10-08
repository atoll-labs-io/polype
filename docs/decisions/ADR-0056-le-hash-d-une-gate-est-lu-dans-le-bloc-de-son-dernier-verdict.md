---
adr: 0056
title: le hash d'une gate est lu dans le bloc de son dernier verdict
status: accepted
date: 2026-10-08
scope: story s92-review-tree-gate
supersedes: []
superseded-by: []
---

# ADR-0056 — le hash d'une gate est lu dans le bloc de son dernier verdict

## Context and Problem Statement
`po-gate` retient le dernier verdict d'un fichier (`Ship allowed:`, `QA status:`) mais le premier hash (`first_hash`, `method/hooks/po-gate.sh:34`). Quand `docs/reviews/<id>.md` empile deux revues, le verdict de la seconde est jugé contre l'arbre de la première (défaut n° 35). Il faut dire quel `Reviewed tree:` / `Tree:` appartient au verdict retenu, et quelles formes de ligne la gate accepte.

## Considered Options
- **Le dernier hash du bloc du dernier verdict** — le hash vient de la dernière ligne `<label>:` placée après l'avant-dernière ligne de verdict et avant la dernière ; absente ou illisible, la gate refuse, sans se rabattre sur une autre ligne.
- **La dernière ligne `<label>:` du fichier** — simple, mais une revue ajoutée et interrompue avant son verdict (arbre écrit, verdict absent) prêterait son arbre, égal à `HEAD`, au verdict favorable de la revue précédente : la gate laisserait partir du code jamais jugé.
- **La dernière ligne `<label>:` placée avant le dernier verdict, sans borne basse** — une revue dont l'en-tête a perdu son arbre emprunterait celui de la revue d'avant.
- **Le premier hash lisible, comme aujourd'hui** — c'est le défaut n° 35.

Pour la forme des lignes `Reviewed tree:` et `Tree:` : une puce `- ` ou `* ` en colonne 0 est permise ; la valeur est un hash de 40 caractères hexadécimaux, seul ou suivi d'un blanc puis d'un texte libre (une remarque). Sont refusés l'indentation, toute autre puce, un hash abrégé ou plus long, et un hash collé à autre chose qu'un blanc (`<hash>.`). `Ship allowed:` accepte la même puce mais aucun texte après `yes` : un verdict qualifié reste refusé. Tolérer la ponctuation collée au hash a été écarté : la frontière « un blanc » est la seule qui ne laisse aucun doute sur la fin du hash.

## Decision Outcome
Chosen option: **le dernier hash du bloc du dernier verdict**, parce que c'est la seule lecture où le verdict retenu et l'arbre qui le date viennent toujours de la même revue (ou du même rapport QA, du même relevé). Une même fonction lit les trois gates ; la ligne de verdict qui borne le bloc est `Ship allowed:` (puce permise), `QA status:` et `Verification status:` (sans puce, inchangées). `/po-ship` décrit cette lecture pour le contrôle sans hook, et `bin/po-eval` lit `Ship allowed:` avec la même puce.

### Consequences
- Good, because une revue empilée sur une autre est jugée sur son propre arbre, une revue inachevée ne peut pas emprunter un verdict, et une remarque après le hash ne fait plus échouer une revue favorable.
- Bad, because une ligne où le hash est collé à un point (la seconde revue de s78 : `<hash>. I took it again…`) reste refusée : le relecteur doit séparer le hash de sa remarque par un blanc.
- Neutral: `Max severity:` reste lue sans puce par `bin/po-eval` ; à revoir si les relecteurs l'écrivent en liste.
