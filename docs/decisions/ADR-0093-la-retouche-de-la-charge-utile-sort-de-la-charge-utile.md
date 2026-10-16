---
adr: 0093
title: Une retouche de la charge utile globale que Polype ne livre plus sort de la charge utile
status: accepted
date: 2026-10-16
scope: story s139-payload-kept-outside
supersedes: [ADR-0092]
superseded-by: []
---

# ADR-0093 — La retouche de la charge utile sort de la charge utile

## Context and Problem Statement
ADR-0092 laisse en place une copie modifiée que Polype ne pose plus. Sous `~/.claude/polype/`, la
charge utile, ce n'est pas tenable : l'installeur lancé depuis la charge utile liste tout fichier
présent sous `polype/method/`, si bien que la copie gardée est reposée au run suivant et redevient
de la méthode active (#111, reproduit par la revue de s137). Et `remove --global` emporte la charge
utile avec son répertoire, retouches comprises, alors que la charge utile n'est pas dans git.

## Considered Options
- **A. Déplacer la retouche hors de la charge utile**, vers `~/.claude/polype.kept/<chemin sous
  polype/>`, et l'effacer dès qu'une version livre au même chemin un fichier de contenu identique,
  preuve que la retouche a été intégrée. Retenue.
- **B. Supprimer la retouche en la signalant.** Écartée : elle serait perdue pour de bon, la charge
  utile n'étant pas dans git.
- **C. Garder `polype.kept/` jusqu'à ce que la personne l'efface.** Écartée : rien n'en signale la
  fin, et une copie déjà intégrée y traînerait sans raison.
- **D. La laisser en place (ADR-0092).** Écartée : elle est reposée au run suivant (#111).

## Decision Outcome
Chosen option: **A. Déplacer la retouche hors de la charge utile**, parce que rien n'est perdu,
rien ne redevient actif, et la copie gardée s'efface d'elle-même une fois intégrée (décision du
propriétaire, 2026-10-15 et 2026-10-16, en cadrant #110 et #111).

En mode global, pour un chemin sous `polype/` :
- `install` et `update` déplacent un fichier modifié qu'ils ne livrent plus, octet pour octet, vers
  `polype.kept/`, le retirent du manifeste et des empreintes et écrivent
  `polype: modified, moved out of the payload: <ancien> -> <nouveau>`. Une copie gardée de même
  contenu vaut déjà gardée : le fichier de la charge utile part, avec
  `polype: modified, already kept: <chemin>`.
- Une copie gardée existante d'un autre contenu n'est jamais écrasée : la commande s'arrête avant
  toute écriture (sortie 1) et nomme les deux fichiers, comme pour un `.before-polype` déjà pris
  (ADR-0088).
- Une pose ou une mise à jour globale supprime une copie de `polype.kept/` dès que la charge utile
  livre au même chemin un fichier identique, avec `polype: kept copy now shipped, removed:
  <chemin>`, et les dossiers vidés disparaissent.
- `remove --global` déplace d'abord vers `polype.kept/` tout fichier modifié de la charge utile,
  encore livré ou non, laisse `polype.kept/` en place et écrit
  `polype: kept copies left in <racine>/polype.kept`. Un `.before-polype` couvert revient comme
  avant.

Cette décision remplace ADR-0092 sur deux points : la charge utile n'est plus un endroit où une
retouche reste, ni un endroit dont `remove --global` emporte une retouche. Les copies actives
(`commands/`, `agents/`, `skills/`) et les projets gardent la règle d'ADR-0092.

### Consequences
- Good, because une retouche de la charge utile survit à `install`, à `update` et à `remove
  --global`, sans jamais être reposée comme méthode active.
- Good, because `polype.kept/` se vide de lui-même quand une version intègre la retouche.
- Bad, because une retouche qui n'est jamais intégrée reste dans `polype.kept/` jusqu'à ce que la
  personne l'efface.
- Neutral: un fichier modifié de la charge utile encore livré suit toujours ses règles d'avant ;
  `polype.kept/` n'est ni au manifeste ni dans les empreintes, et `check` ne le lit pas.
