---
adr: 0117
title: Un binaire po par machine, qui prévient et ne casse pas le travail fait
status: accepted
date: 2026-11-13
scope: framing
supersedes: []
superseded-by: []
---

# ADR-0117 — Un binaire `po` par machine, qui prévient et ne casse pas le travail fait

## Context and Problem Statement
L'ADR-0115 dit comment le binaire arrive sur une machine et laisse ouvert l'endroit où il est posé ; l'ADR-0116 y met tout le code de M21, pour l'agent extérieur comme pour le chef de projet. Le binaire ne voyage plus par git, alors qu'un worktree de story n'a que ce que git porte, et deux projets d'une même machine peuvent suivre deux versions de la méthode. Il faut fixer son nom et son emplacement avant de découper les stories, dont les `Owns` en dépendent.

## Considered Options
**Emplacement**, classé par les critères du porteur : libre ou auto-hébergeable, sobre en matériel, capable de grandir, facile à manier pour une IA.

1. **Un lanceur bash commité dans chaque projet, le binaire rangé par version hors des dépôts** — chaque clone et chaque worktree a le lanceur, chaque projet le binaire de sa version. Un script bash de plus et autant de binaires que de versions en usage.
2. **Le binaire dans `.polype/bin/` de chaque projet, ignoré par git** — une copie par projet, et un worktree de story ne l'a pas : chaque appelant remonte à la racine.
3. **Un binaire par machine, dans le dossier de Polype de l'utilisateur** — un seul fichier à poser et à mettre à jour. Deux projets à deux versions de la méthode partagent le même binaire.

**Nom**

1. **`po`** — neutre pour une commande qui sert l'agent extérieur (`state`, `inbox`, `answer`, `run`, `continue`) et le chef de projet (`next`, `record`, `inbox add`).
2. **`po-agent`** — le nom du contrat ; `po-agent record` se lit mal.

## Decision Outcome
Chosen option: **un binaire par machine (option 3), nommé `po`**, tranché par le porteur le 2026-11-13, à trois conditions de sa part, qui répondent au défaut de l'option :

- **Il prévient.** Quand la version du binaire n'est pas celle que le projet a installée, sa sortie le dit, sans refuser de répondre.
- **Il ne casse pas le travail fait.** Un binaire plus récent lit ce qu'une version plus ancienne de la méthode a écrit dans un projet (revues, relevés, décisions) ; ce qu'il ne sait pas lire vaut `null`, comme le contrat le dit déjà.
- **Sinon il nettoie.** Quand une montée de version ne peut pas garder cette compatibilité, l'installeur convertit ou retire ce que l'ancienne version a laissé, et dit ce qu'il a fait.

Le chemin exact sous le dossier de Polype de l'utilisateur reste un détail du plan.

### Consequences
- Good, because l'installeur pose un seul fichier par machine, et une commande ou un agent le trouve au même endroit depuis n'importe quel projet ou worktree.
- Bad, because la compatibilité arrière devient une obligation de chaque version : un changement de forme d'un fichier lu par `po` demande un cas rejoué sur l'ancienne forme.
- Bad, because un projet dont la méthode installée est plus récente que le binaire de la machine reçoit des réponses d'un automate en retard, que seul l'avertissement signale.
- Neutral: [`interface-agent.md`](../interface-agent.md) et [`direction.md`](../direction.md) nomment désormais `po` ; les stories de M21 reprennent le contrat.
