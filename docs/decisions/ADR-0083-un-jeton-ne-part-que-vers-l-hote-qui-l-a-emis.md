---
adr: 0083
title: Un jeton de forge ne part que vers l'hôte qui l'a émis, même quand la CLI le prend dans l'environnement
status: accepted
date: 2026-10-13
scope: story s107-forge-token-bound-to-host
supersedes: []
superseded-by: []
---

# ADR-0083 — Un jeton de forge ne part que vers l'hôte qui l'a émis

## Context and Problem Statement
La revue de s102 a relevé que `/po-ship` lit la forge par `curl` avec `GITLAB_TOKEN` ou `GITEA_TOKEN` vers l'hôte que nomme `origin` (`method/commands/po-ship.md:29`) : un dépôt cloné depuis une instance tierce reçoit le jeton d'une autre instance. Le 2026-10-13, le porteur a retenu (story s107) de ne garder le repli `curl` par variable d'environnement que pour github.com, et de lire GitLab et Forgejo/Gitea par leur CLI seule, censée lier chaque jeton à son hôte.

La recherche de s107 montre que cette liaison ne tient pas toujours. La documentation de `glab` (« Token precedence ») place `GITLAB_TOKEN`, `GITLAB_ACCESS_TOKEN` et `OAUTH_TOKEN` avant les identifiants enregistrés pour l'hôte, quel que soit l'hôte. `tea` 1.0 lit aussi `GITEA_TOKEN` dans l'environnement, avec son instance dans `TEA_HOST` ou `GITEA_INSTANCE_URL`. Avec ces variables exportées, `glab api` vers `gitlab.tiers.tld` y envoie le jeton. Comment fermer ce cas est un choix de sécurité que la story ne tranche pas : il revient au porteur (ADR-0077).

## Considered Options

Classées selon les critères du porteur : open source ou auto-hébergeable, sobre, scalable, facile à manipuler pour une IA. Les trois premières n'ajoutent aucune dépendance et ne coûtent rien ; elles se départagent sur la sécurité et l'usage.

- **A. Appeler `glab` et `tea` sans leurs variables de jeton.** `env -u GITLAB_TOKEN -u GITLAB_ACCESS_TOKEN -u OAUTH_TOKEN glab api --hostname <hôte d'origin> …`, et `tea` sans `GITEA_TOKEN`, `TEA_HOST` ni `GITEA_INSTANCE_URL`. Seul l'identifiant enregistré pour cet hôte part ; sans lui, la forge est illisible. Un préfixe de commande, rien à configurer. Recommandée.
- **B. Une variable de jeton présente rend la forge GitLab ou Forgejo/Gitea illisible.** Sûr aussi, mais une personne qui a à la fois une variable exportée et un `glab auth login` pour le bon hôte perd la lecture sans raison ; le rapport doit lui dire de retirer la variable.
- **C. Faire confiance à la CLI telle quelle** (le texte de la story à la lettre). Écartée : la fuite reste dès que `GITLAB_TOKEN` est exporté, cas courant.
- **D. Lier le jeton par une variable `*_HOST`.** Déjà écartée par le porteur le 2026-10-13 : convention de `glab` seulement, rien pour Forgejo.
- **E. Garder le repli `curl` tel quel.** Déjà écartée par le porteur le 2026-10-13.

## Decision Outcome
Chosen option: **A**, retenue par le porteur le 2026-10-13, parce qu'elle ferme la fuite sans retirer la lecture à qui a une connexion CLI pour le bon hôte, et qu'elle tient en un préfixe de commande. La sonde `/api/v1/version` part sans jeton ; aucun appel vers un hôte non reconnu n'en porte un ; GitHub garde son repli `curl` par `GH_TOKEN` ou `GITHUB_TOKEN`, puisqu'il n'est détecté que sur l'hôte `github.com`, qui les émet.

### Consequences
- Good, because aucun jeton ne quitte l'hôte qui l'a émis, même mal rangé dans l'environnement.
- Bad, because une personne qui lisait GitLab ou Forgejo par la seule variable d'environnement, sans `glab auth login` ni `tea` connecté, voit la forge devenir illisible ; le rapport le dit et dit comment se connecter.
- Neutral: le comportement de `tea` 1.0 avec `GITEA_TOKEN` sans instance et son option pour fixer l'hôte ne sont pas vérifiés sur un binaire réel ; à confirmer à la première lecture d'un Forgejo.
