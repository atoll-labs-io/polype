---
adr: 0112
title: L'installeur nomme ce qu'il laisse derrière un arrêt
status: accepted
date: 2026-11-13
scope: story s161-installer-leftovers
supersedes: [ADR-0095]
superseded-by: []
---

# ADR-0112 — L'installeur nomme ce qu'il laisse derrière un arrêt

## Context and Problem Statement
Quatre chemins de `bin/polype` laissent un fichier de la personne sans le dire (#143, #137, #79) : un `remove --global` qui s'arrête garde un `.before-polype` dans `.polype-restore.<pid>` ; une pose `--set-aside` qui échoue après ses déplacements finit sur une erreur brute ; un `AGENTS.md.before-polype` est absorbé puis supprimé quel que soit l'`AGENTS.md` en place ; un `*.next` posé à n'importe quelle profondeur de `~/.claude/polype/` passe pour un fichier d'état, et `remove --global` l'emporte. L'ADR-0095 a écrit la dernière règle (« tout `*.next` et tout `*.polype-next` ») ; la story s161 la restreint.

## Considered Options
- **A. Un rapport à l'arrêt.** Un seul piège de sortie, qui n'agit que sur un code non nul : il remet à leur place les fichiers que `remove` tenait, nomme ceux qu'il ne peut pas remettre et le dossier où ils sont, et redit chaque fichier que `--set-aside` a déplacé avec son nouveau chemin. Un `AGENTS.md.before-polype` n'est absorbé que lorsque l'`AGENTS.md` en place est celui de Polype ; sinon il reste et l'installeur le dit. `*.next` et `*.polype-next` ne sont des fichiers d'état qu'à la racine de la charge utile.
- **B. Tout défaire à l'arrêt.** Le piège remet aussi chaque fichier mis de côté. Écartée : un second échec pendant ce retour masque la cause du premier, et la story demande une trace, pas un retour en arrière ; relancer la même commande termine la pose.
- **C. Garder `*.next` à toute profondeur et nommer seulement les noms exacts.** Une liste fermée (`manifest.next`, `checksums.next`, `payload.sums.next`). Écartée : chaque nouveau fichier temporaire d'état demanderait de changer la liste, alors que la racine de la charge utile n'accueille aucun fichier de la personne qui porte ce suffixe.

## Decision Outcome
Chosen option: **A. Un rapport à l'arrêt**, parce qu'il ferme les quatre chemins avec un seul mécanisme et ne change rien à une commande qui réussit.

- Un `remove --global` qui s'arrête remet chaque fichier tenu là où il était avant la commande (`<chemin>.before-polype` tant que la charge utile existe, `<chemin>` une fois partie) ; un fichier qu'il ne peut pas remettre est nommé avec le dossier qui le tient.
- Une pose qui s'arrête après des déplacements `--set-aside` finit par une ligne par fichier, ancien chemin et nouveau.
- Un `AGENTS.md.before-polype` sans `AGENTS.md` portant le marqueur de Polype n'est ni absorbé ni supprimé ; l'installeur le dit. Le flux de l'ADR-0088 (un premier passage sans `AGENTS.local.md` le met de côté et pose l'`AGENTS.md` de Polype, le suivant l'absorbe) ne change pas, et son absorption le nomme.
- Sous `polype/`, un `*.next` ou un `*.polype-next` plus profond que la racine est un fichier étranger : il arrête `install`, `update`, `init` et `remove`. C'est le seul point de l'ADR-0095 que cette décision remplace.

### Consequences
- Good, because aucun arrêt ne laisse plus un fichier de la personne hors de vue, et `remove --global` n'emporte plus un fichier qu'elle a nommé `.next`.
- Bad, because un `*.polype-next` laissé en profondeur par une pose tuée arrête la suivante : la personne le supprime à la main, comme tout fichier étranger.
- Neutral: un arrêt par signal (`kill -9`) ne passe pas par le piège ; `.polype-restore.<pid>` peut alors rester, comme avant.
