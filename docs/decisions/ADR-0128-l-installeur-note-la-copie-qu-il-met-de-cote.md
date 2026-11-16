---
adr: 0128
title: L'installeur note la copie d'AGENTS.md qu'il met de côté
status: accepted
date: 2026-11-16
scope: story s188-orphan-copy-survives
supersedes: [ADR-0112, ADR-0088]
superseded-by: []
---

# ADR-0128 — L'installeur note la copie d'`AGENTS.md` qu'il met de côté

## Context and Problem Statement
Sans `AGENTS.local.md`, l'installeur range un `AGENTS.md` écrit à la main en `AGENTS.md.before-polype`, et le premier passage qui trouve `AGENTS.local.md` l'y verse puis le supprime (ADR-0088). Pour reconnaître cette copie en attente, `absorb_agents_md` regarde seulement si l'`AGENTS.md` en place porte le marqueur de Polype (`bin/polype:515`). Or chaque passage pose cet `AGENTS.md` marqué (`bin/polype:549-560`) : dès le deuxième passage, n'importe quel `AGENTS.md.before-polype`, y compris un fichier que la personne a écrit elle-même, est pris pour la copie de Polype, versé dans `AGENTS.local.md` et supprimé (#225, revue de s161). L'ADR-0112 promet le contraire (« n'est ni absorbé ni supprimé ») ; le code ne tient cette promesse qu'un passage. Rien sur le disque ne dit aujourd'hui qu'une copie vient de Polype : il faut choisir où le noter.

Toutes les options sont du shell dans `bin/polype`, sans dépendance, et laissent intacts le flux de l'ADR-0088 pour une copie notée et ce que `remove` rend. Elles ont une conséquence commune pour un projet posé par la version précédente : sa copie en attente ne porte aucune note, elle est donc traitée en orpheline, gardée et nommée à chaque passage, jamais supprimée ; la personne en reporte les notes à la main. C'est pourquoi cette décision remplace aussi la puce de l'ADR-0088 qui promettait l'absorption unique d'une copie laissée par l'ancien installeur.

## Considered Options
Classées par les critères du porteur. Les trois sont libres, auto-hébergées, sans dépendance, et coûtent un petit fichier ou une ligne : ces critères ne les séparent pas, sauf la facilité pour une IA. Ce qui les sépare est le risque de perte et ce qui voyage dans git.

- **A. Une note d'état dans `.polype/`, avec la somme de la copie.** Quand l'installeur range `AGENTS.md` en `AGENTS.md.before-polype`, il écrit la somme `cksum` de la copie dans un fichier d'état de `.polype/`. Une copie est la sienne si cette note existe et que la somme est égale ; il la verse et supprime copie et note ensemble. Toute autre copie, y compris une copie notée que la personne a modifiée depuis, reste et est nommée à chaque passage. `remove` supprime la note avec les autres fichiers d'état.
  - Pour : l'état reste où sont les autres (`manifest`, `checksums`, `version`, `mode`) et se lit d'un coup d'œil, par une personne comme par une IA ; le texte de la personne n'est jamais modifié ; la somme rend le doute sûr (copie retouchée → gardée).
  - Contre : la note voyage dans git avec `.polype/` alors que la copie n'y est peut-être pas ; un clone qui a la note sans la copie ne fait rien (note obsolète, effacée au passage suivant).
- **B. Une ligne de marque en tête de la copie.** L'installeur écrit une première ligne `<!-- Set aside by Polype. … -->` dans `AGENTS.md.before-polype` au moment où il la range. Une copie est la sienne si elle commence par cette ligne ; l'absorption et `remove` la retirent avant d'utiliser le texte.
  - Pour : la note et la copie ne peuvent pas se séparer, elles voyagent ensemble dans git ou pas du tout ; aucun fichier d'état nouveau.
  - Contre : Polype modifie le fichier de la personne ; `remove` doit retirer la ligne pour rendre l'`AGENTS.md` octet pour octet ; une copie retouchée garde sa marque et reste absorbée ; une personne qui copie ce fichier ailleurs emporte la marque.
- **C. Une note hors de git, sur la machine.** Comme A, mais dans un fichier que le `.gitignore` exclut (à côté de `.claude/.polype-checksums`).
  - Pour : rien de nouveau n'entre dans git.
  - Contre : une ligne de `.gitignore` de plus ; sur un autre clone la copie en attente n'a pas de note et devient orpheline, gardée mais plus versée ; un agent qui lit le dépôt ne voit pas cet état.

Écartée d'emblée : **D. Ne plus jamais verser la copie** et laisser la personne le faire à la main. Elle casse le flux de l'ADR-0088, que le critère `pending_copy_is_still_absorbed` garde.

## Decision Outcome
Option choisie : **A**, par le porteur le 2026-11-16 (décision d-0034 de la boîte), comme cette ADR la recommandait, parce qu'elle ne touche jamais au texte de la personne, garde l'état avec les autres fichiers d'état de `.polype/` et tranche par la somme le cas d'une copie retouchée du côté où rien ne se perd. Le porteur a accepté, avec cette réponse, que cette ADR remplace en partie l'ADR-0088 autant que l'ADR-0112.

Avec A, ce qui change par rapport à l'ADR-0112 et à l'ADR-0088 :
- Un `AGENTS.md.before-polype` n'est versé dans `AGENTS.local.md` puis supprimé que si l'installeur a noté l'avoir rangé lui-même et que la copie n'a pas changé depuis. Toute autre copie n'est ni versée ni supprimée, à chaque passage, et chaque passage la nomme. Cela remplace la troisième puce de la décision de l'ADR-0112.
- Une copie laissée par un installeur antérieur n'a pas de note : elle est gardée et nommée, plus versée automatiquement. Cela remplace la puce « Un projet posé par l'ancien installeur… » de l'ADR-0088.
- `remove` rend ce qu'il rendait : il supprime l'`AGENTS.md` marqué et remet `AGENTS.md.before-polype` en `AGENTS.md`, notée ou non.

### Consequences
- Good, because un fichier que la personne a nommé `AGENTS.md.before-polype` ne disparaît plus, et ses notes n'arrivent plus en double dans `AGENTS.local.md`.
- Bad, because une copie mise de côté par une version antérieure n'est plus versée seule : la personne suit le message et la reporte à la main.
- Neutral: la note suit `.polype/` dans git ; une note sans copie est effacée sans bruit.
