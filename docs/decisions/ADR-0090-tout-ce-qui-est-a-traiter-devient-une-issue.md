---
adr: 0090
title: Tout ce qui est à traiter devient une issue dans Issue tracker, la sécurité allant à la personne
status: accepted
date: 2026-10-14
scope: story s134-everything-to-handle-is-an-issue
supersedes: []
superseded-by: []
---

# ADR-0090 — Tout ce qui est à traiter devient une issue

## Context and Problem Statement
La Law 7 envoyait un bug dans `Issue tracker`, mais laissait les constats de revue là où ils avaient été notés : « only a person turns one into an issue or a story ». Aucune commande ne lisait `Issue tracker`. Les idées, les fonctionnalités et les constats laissés ouverts au ship restaient dans une conversation, dans `docs/decisions-log.md` ou dans une revue, et s'y perdaient : c'est le constat qui ouvre M12. Le porteur a décidé le 2026-10-14 que tout ce qui reste à traiter devient une issue.

## Considered Options
- **A. Le chef de projet et `/po-ship` déposent tout, la sécurité va à la personne.** Le chef de projet dépose aussitôt, avec son contexte, toute idée de modification, fonctionnalité ou défaut, quel qu'en soit l'auteur et où qu'il ait été noté ; `/po-ship` dépose, une fois la fusion prouvée, les constats majeurs et mineurs que la dernière revue laisse ouverts. Retenue, par le porteur.
- **B. Seule la personne dépose.** Écartée : c'est la règle d'avant, et ce qui n'est pas déposé tout de suite se perd, ce que M12 constate.
- **C. Ne déposer que les défauts.** Écartée : les idées et les fonctionnalités resteraient dans les conversations, là où rien ne les retrouve.
- **D. Déposer aussi la sécurité.** Écartée : un tracker public, comme celui d'`atoll-labs-io/polype`, publierait la faille avant sa correction ; l'ADR-0077 range la sécurité parmi les décisions stratégiques qui vont à la personne. Cette retenue protège moins qu'elle n'en a l'air : la revue elle-même, constats de sécurité compris, est déjà publique dans la pull request et sur `Target branch` par le commit de la story. Ne pas déposer évite seulement une seconde publication, plus visible (une issue notifie qui suit le dépôt), et laisse la personne décider de la suite : corriger d'abord, passer par un canal privé, ou déposer.

## Decision Outcome
Option choisie : **A**.

- La Law 7 garde « only a person turns a finding into a story » : faire d'un constat une story reste une décision de la personne. Déposer une issue n'en est plus une.
- `/po-ship` dépose à l'étape 2 de son Step 3, entre la preuve de fusion et le retrait du worktree, parce qu'elle lit la revue dans le worktree ; la revue n'est pas perdue pour autant, puisque le Step 1 l'a commitée et qu'elle arrive avec le commit de la story (Law 6). Titre `<id>: <sévérité> — <début du constat>`, pas de doublon d'un titre déjà ouvert, comparé exactement à la liste des issues ouvertes et non par l'index de recherche, qui peut manquer une issue toute neuve. Une liste qui échoue, ou qui atteint sa limite de 1000 titres, ne prouve rien : rien n'est déposé et le rapport dit pourquoi. Un constat est un élément de liste (`- `, `* ` ou `1. `) ouvert par sa sévérité, nue ou en gras, et pris en entier avec ses sous-puces ; une ligne de `## Findings` qui nomme une sévérité sans entrer dans cette forme va à la personne, jamais perdue. Le texte d'un constat n'entre jamais dans un argument de shell : titre et corps passent par des fichiers découpés dans la revue par numéros de ligne, puis `--body-file` ou une expansion entre guillemets doubles. `github` passe par `gh` sur le dépôt github.com d'`origin`, le jeton n'allant qu'à l'hôte qui l'a émis (ADR-0083) ; `taskwarrior` crée une tâche `project:<nom du dépôt> +issue`.
- `/po-drive` relance `/po-ship <id>` sur un worktree resté en place dont la pull request, laissée à une personne, imprime `MERGED` : le dépôt a lieu là, sans slot `Parallel`.
- Un constat d'une revue dont la lentille Security a tourné, ou dont le texte touche la sécurité, n'est jamais déposé seul : il est porté à la personne, qui décide où il va.
- `/po-setup` écrit `github` pour un `origin` sur github.com, `taskwarrior` sinon, sans question ; Polype porte `Issue tracker: github`.

### Consequences
- Good, because rien de ce qui reste à faire ne vit seulement dans une conversation, un journal ou une revue.
- Bad, because `/po-ship` et `/po-drive` lisent un réglage de plus, et le tri « touche la sécurité » d'un constat reste un jugement de l'agent quand la ligne `Lenses run:` ne nomme pas la lentille.
- Neutral: avec `Issue tracker: —`, rien n'est déposé : le chef de projet porte chaque élément à la personne et `/po-ship` liste les constats ouverts dans son rapport. GitLab et Forgejo ne sont pas encore des valeurs ; ils font l'objet d'une issue à part.
