---
adr: 0088
title: L'installeur s'arrête sur un fichier qu'il n'a pas posé et absorbe un AGENTS.md écrit à la main
status: accepted
date: 2026-10-14
scope: story s130-install-refuses-collisions
supersedes: []
superseded-by: [ADR-0092, ADR-0095]
---

# ADR-0088 — L'installeur s'arrête sur une collision et absorbe l'`AGENTS.md`

## Context and Problem Statement
Une première pose remplace sans prévenir un fichier du même nom que l'un des siens (`lay_down`, `bin/polype:157`) : un agent `reviewer.md` ou une skill que la personne avait déjà dans `~/.claude/` disparaît, et `remove` ne le rend pas. Un `AGENTS.md` écrit à la main est copié en `AGENTS.md.before-polype` (`bin/polype:166-170`), que plus rien ne lit. Le manifeste et les sommes disent déjà ce que Polype a posé (ADR-0087) : tout autre fichier est à la personne. Le contrat de l'installeur doit dire ce qu'il fait d'un fichier qui n'est pas le sien.

## Considered Options
Les options sont du shell dans `bin/polype`, sans dépendance. Elles se départagent sur le risque de perdre un fichier et sur ce que la personne voit.

- **A. S'arrêter, avec une option qui met de côté ; absorber `AGENTS.md`.** `install`, `init` et `update`, pose globale comme pose projet, s'arrêtent en code 1 avant toute écriture quand une destination existe, n'est pas dans le manifeste et diffère du fichier livré, et listent chaque chemin. `--set-aside` déplace chacun en `<chemin>.before-polype` ; `remove` le remet en place. Un fichier identique au fichier livré est repris sans bruit. Un `AGENTS.md` écrit à la main va dans `AGENTS.local.md` sous `## Notes moved from AGENTS.md`, comme un `CLAUDE.md` (ADR-0086). Retenue.
- **B. Mettre de côté sans demander.** Chaque collision part en `.before-polype` et la pose continue, comme `AGENTS.md` aujourd'hui. Écartée : l'agent ou la skill de la personne cesse d'être chargé, et seule une ligne de sortie le dit.
- **C. Écraser (le comportement actuel).** Écartée : le fichier de la personne est perdu, et `remove` ne peut rien rendre.
- **D. Renommer les fichiers de Polype pour éviter les noms courants.** Écartée : elle ne protège que des noms déjà connus, et casse les références aux agents et aux skills dans toute la méthode.

## Decision Outcome
Option choisie : **A**, le contrat de la story s130, cadrée avec le porteur le 2026-10-14.

L'ADR-0086 a écarté son option B, s'arrêter et demander, pour un `CLAUDE.md`, parce qu'une machine déplace ce texte dans `AGENTS.local.md` sans rien perdre. Une collision n'a pas cette issue : deux fichiers ne peuvent pas porter le même nom, et lequel garder est un choix de la personne, qui vaut pour tous ses projets quand il s'agit de `~/.claude/`. L'arrêt est donc la règle ici, et `--set-aside` la réponse explicite. `AGENTS.md`, lui, se fusionne comme un `CLAUDE.md` : il suit l'option A de l'ADR-0086.

- Une collision est ce que le manifeste ne connaît pas. Un projet déjà installé n'en voit aucune à son `update` : ses fichiers sont dans son manifeste. Un fichier du manifeste modifié à la main garde le traitement de `update` (« modified, left as it is »).
- La comparaison se fait par `cksum`, comme `sum_of`.
- Un `<chemin>.before-polype` qui existe déjà n'est jamais écrasé : la commande s'arrête avant d'écrire.
- La liste des fichiers mis de côté n'est pas un nouveau fichier d'état : c'est chaque chemin du manifeste dont le `.before-polype` existe. `remove`, et `update` quand il retire un fichier qui n'est plus livré, remettent ce fichier en place. La pose globale met de côté ce qui se trouve sous `~/.claude/polype/` avant son `rm -rf`, puis le remet.
- `AGENTS.local.md` absent : l'`AGENTS.md` écrit à la main reste en `AGENTS.md.before-polype` et l'installeur le dit ; le premier `update` qui trouve `AGENTS.local.md` l'absorbe et supprime la copie. `remove` ne reconstruit pas un `AGENTS.md` absorbé : son texte reste dans `AGENTS.local.md`.
- Un projet posé par l'ancien installeur peut garder l'`AGENTS.md.before-polype` que celui-ci laissait. Le premier `update` qui trouve `AGENTS.local.md` l'absorbe et le supprime, une seule fois. Si la personne avait déjà recopié ces notes à la main, elles figurent alors deux fois dans `AGENTS.local.md` : c'est à elle d'en retirer une.
- Une destination qui est un lien symbolique est une collision, même vers un contenu identique au fichier livré : poser par-dessus remplacerait le lien par un fichier ordinaire, que `remove` supprimerait ensuite. `--set-aside` déplace le lien lui-même, et `remove` le remet.
- Sans `AGENTS.local.md`, un `AGENTS.md` écrit à la main et un `AGENTS.md.before-polype` différent arrêtent la commande, qui dit de lancer `/po-setup` d'abord ; `--set-aside` ne s'y applique pas. Deux copies identiques n'en font qu'une, et la pose continue.

### Consequences
- Good, because installer Polype ne fait plus rien perdre, ni dans `~/.claude/` ni dans un projet.
- Bad, because une première pose peut s'arrêter, et la personne doit relancer avec `--set-aside` ou ranger ses fichiers.
- Neutral: l'installeur écrit dans `AGENTS.local.md` pour un `AGENTS.md` comme pour un `CLAUDE.md`, toujours en ajout. `docs/installation.md` décrit encore l'ancien comportement jusqu'à s132.
