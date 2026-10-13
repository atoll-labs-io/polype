---
adr: 0081
title: Comment une story atterrit en un commit linéaire selon la forge, et comment le ship construit ce commit
status: accepted
date: 2026-10-13
scope: story s105-ship-through-pr
supersedes: [ADR-0080]
superseded-by: []
---

# ADR-0081 — Comment une story atterrit en un commit linéaire selon la forge

## Context and Problem Statement
ADR-0080 veut que chaque story arrive sur `Target branch` par une PR mergée « en fast-forward (« Rebase and merge » côté forge) ». Le 2026-10-13, la PR #6 d'atoll-io/polype mergée par ce bouton montre que ce n'est pas un fast-forward. La tête de la PR (`33e887b`) et le commit arrivé sur `main` (`a380428`) ont le même arbre (`f8e542d`), mais des empreintes différentes, et la tête n'est pas ancêtre de `main`. GitHub recrée toujours les commits. Il ne propose que merge, squash et rebase, ni dans l'interface ni dans `gh pr merge`. Deux questions sont donc ouvertes : comment atterrir sur chaque forge, et comment le ship construit le commit unique sans casser la reprise.

Ce choix est technique : il revient au porteur (ADR-0077), qui l'a tranché en conversation le 2026-10-13. Cette ADR remplace en partie ADR-0080, sur le seul sens de « fast-forward côté forge ».

## Considered Options

Les options sont classées selon les critères du porteur, dans cet ordre : open source ou auto-hébergeable, sobre, scalable, facile à manipuler pour une IA.

### Question 1 — L'atterrissage sur la forge

1. **Le mode natif de chaque forge, et sur GitHub, le rebase de la forge accepté tel qu'il est.** Recommandée.
   - Sur GitLab, la méthode de merge `ff` donne un vrai fast-forward. Sur Forgejo ou Gitea, c'est le style `fast-forward-only` (pas encore vérifié sur une instance réelle). Sur GitHub, `gh pr merge --rebase --match-head-commit <sha>` donne un seul commit, le même arbre et aucun commit de merge, mais une empreinte nouvelle.
   - Pour : les forges libres et auto-hébergeables obtiennent le vrai fast-forward. Aucun agent ne pousse `Target branch`. Les protections de branche sont respectées, donc l'option tient en équipe.
   - Contre : GitHub ne garde pas l'empreinte, et il faut une commande par forge. Seul GitHub est câblé aujourd'hui (`po-ship.md` n'appelle que `gh`).
2. **Rebase ou squash côté forge partout, sans viser l'identité d'empreinte.** ADR-0080 est alors amendée en « linéaire, un commit, sans commit de merge ».
   - Pour : une seule règle, la plus simple à suivre pour un agent. Rien n'y dépend de l'empreinte : la gate compare des arbres, la reprise lit `MERGED` et le sujet `<id>:`.
   - Contre : même un Forgejo auto-hébergé, qui sait faire un fast-forward, perd l'empreinte.
3. **Pousser la tête de la PR sur `Target branch` (`git push origin <sha>:<Target>`, sans force).** La forge marque alors la PR comme mergée.
   - Pour : un vrai fast-forward partout, en une seule commande git.
   - Contre : c'est exactement ce qu'ADR-0080 interdit, puisqu'un agent pousse `Target branch`. Une protection qui exige une PR refuse ce push, ce qui casse l'option en équipe. Sur Gitea et Forgejo, la PR n'est marquée mergée que si la détection du merge manuel est activée (non vérifié).

### Question 2 — La construction du commit unique

1. **Le construire à côté de la branche, avec `git merge-tree --write-tree <base> story/<id>` puis `git commit-tree <arbre> -p <base>`, et pousser ce commit seul sur `story/<id>` côté remote.** Recommandée.
   - Pour : la branche locale garde l'arbre relu. `po-gate ship-allowed` et la table de reprise de `/po-drive` continuent de la lire sans rien changer à la gate. On n'a ni checkout ni worktree en plus : c'est le plus sobre.
   - Contre : il faut git 2.38 ou plus.
2. **Écraser puis rebaser `story/<id>` sur place.**
   - Pour : des commandes connues de tous.
   - Contre : dès que `Target branch` a bougé, la gate refuse la branche, puisque l'arbre ne correspond plus au `Reviewed tree:`. Une reprise repart alors en revue. Il faudrait changer la gate, ce qu'interdit le critère `ship_gate_unchanged`.
3. **Rebaser dans un worktree jetable du répertoire temporaire.**
   - Pour : rien ne dépend de la version de git.
   - Contre : un worktree de plus à créer puis à retirer à chaque ship.

## Decision Outcome
Chosen option: **retenue par le porteur le 2026-10-13** : l'option 1 de la question 1 et l'option 1 de la question 2. Elle donne le vrai fast-forward sur les forges libres et le rebase de la forge sur GitHub. Aucun agent ne pousse `Target branch`, et la gate ne change pas.

### Consequences
- Good, because une fois la recommandation acceptée, `main` reste linéaire avec un commit par story, et ADR-0080 garde son interdit de pousser.
- Bad, because sur GitHub, la tête de la PR n'est pas ancêtre de `Target branch`. La preuve de merge reste donc `MERGED`, jamais `--is-ancestor`, comme avec le squash.
- Neutral: une fois acceptée, cette ADR remplace en partie ADR-0080, sur la phrase « Rebase and merge côté forge » prise pour un fast-forward. Le câblage de GitLab et de Forgejo revient à une story ultérieure.
