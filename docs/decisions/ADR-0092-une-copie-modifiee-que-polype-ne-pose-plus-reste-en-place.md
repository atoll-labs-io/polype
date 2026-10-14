---
adr: 0092
title: Une copie modifiée à la main que Polype ne pose plus reste en place et devient celle de la personne
status: accepted
date: 2026-10-14
scope: story s137-modified-copy-survives-drop
supersedes: [ADR-0088]
superseded-by: []
---

# ADR-0092 — Une copie modifiée que Polype ne pose plus reste en place

## Context and Problem Statement
Quand `init`, `install`, `update` ou `remove` ne posent plus un fichier listé au manifeste, ils le
suppriment sans regarder son empreinte (#89). Une copie que la personne a modifiée disparaît alors
sans un mot : passer un projet complet en `init`, ou retirer Polype, efface son travail. Il faut
décider ce que devient une telle copie.

## Considered Options
- **A. La laisser en place.** Elle sort du manifeste et des deux fichiers d'empreintes, une ligne
  `polype: modified, kept: <chemin>` la nomme sur `stderr`, et elle devient le fichier de la
  personne : la pose suivante qui la livre à nouveau s'arrête dessus comme sur une collision
  (ADR-0088). Retenue.
- **B. La mettre de côté sous un nouveau suffixe.** Écartée : un fichier de plus à trier à la main,
  à côté des `.before-polype`.
- **C. Arrêter la commande comme pour une collision.** Écartée : un `init` de réparation serait bloqué
  par une seule modification.
- **D. Exempter `remove` seulement.** Écartée : la modification serait perdue au moment même où
  Polype est retiré.

## Decision Outcome
Chosen option: **A. La laisser en place**, parce que rien n'est perdu, rien n'est bloqué, et la règle
des collisions prend le relais sans code nouveau (décision du propriétaire, 2026-10-14).

Une copie « modifiée » a une empreinte enregistrée qui diffère de son contenu. Cette décision
remplace ADR-0088 sur un seul point : quand la copie qui couvrait un `<chemin>.before-polype` a été
modifiée, `remove` ne remet plus le fichier mis de côté à sa place ; les deux restent, et la ligne
nomme les deux chemins. Le reste d'ADR-0088 vaut toujours.

### Consequences
- Good, because une modification à la main survit à `init`, à `install`, aux fantômes d'`update`
  (qui ne la comptent pas dans « removed ») et à `remove`.
- Good, because la pose suivante qui livre ce chemin s'arrête dessus ; `--set-aside` la déplace.
- Bad, because une copie sans empreinte enregistrée est supprimée comme avant : un clone frais, ou
  des copies de `.claude/` dont les empreintes sont hors de git depuis ADR-0087 ; git garde alors la
  modification.
- Bad, because `remove --global` emporte la charge utile sous `~/.claude/polype/` avec son
  répertoire, même modifiée, sans ligne « kept ».
- Neutral: les fichiers encore livrés suivent leurs règles d'avant : `install` les écrase, `update`
  laisse en place ceux qui sont modifiés.
