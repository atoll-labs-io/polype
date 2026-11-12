---
adr: 0105
title: La suite tourne sur chaque pull request
status: proposed
date: 2026-11-12
scope: framing
supersedes: []
superseded-by: []
---

# ADR-0105 — La suite tourne sur chaque pull request

## Context and Problem Statement
Polype n'a aucune intégration continue : `.github/` ne contient qu'un modèle d'issue, et `bash tests/run.sh` tourne sur la machine de celui qui livre. Les portes comparent des arbres hors `docs/` : un fichier qui atterrit sous `docs/` n'est donc contrôlé par personne, et deux revues arrivées sans leur ligne de liens ont rendu `main` rouge (#168, #187). Il faut décider où tourne la suite ; qu'elle tourne sur chaque pull request et sur le commit d'atterrissage n'est pas en question (#201). Le dépôt est public, sur GitHub.

## Considered Options
Classées par les critères du porteur : libre ou auto-hébergeable, sobre en matériel, capable de grandir, facile à manier pour une IA.

1. **Forgejo Actions auto-hébergé, le dépôt GitHub en miroir** — forge et runner libres et auto-hébergés, syntaxe proche de GitHub Actions. Demande d'installer et de tenir une forge et un runner, et de faire de Forgejo la forge de référence : `gh`, les issues et les pull requests de Polype vivent aujourd'hui sur GitHub, et les forges autres que GitHub ne sont pas prouvées (#75).
2. **Runner auto-hébergé de GitHub Actions** — le runner est libre et tourne sur le matériel du porteur, la forge ne change pas. Sur un dépôt public, une pull request venue d'un fork ferait tourner du code inconnu sur la machine qui héberge le runner : il faut un runner éphémère et isolé, et l'approbation manuelle des contributeurs extérieurs.
3. **Runners hébergés de GitHub** — rien à installer, gratuit pour un dépôt public, le code d'une pull request tourne loin de toute machine du porteur. Ni libre ni auto-hébergeable.
4. **Un hook local `pre-push` seul** — aucun service. Ne contrôle que la machine qui pousse, se contourne, et ne dit rien du commit qu'une pull request fait atterrir.

## Decision Outcome
Proposé, à trancher par le porteur. Recommandation : **l'option 3 maintenant, écrite pour passer à l'option 1 sans réécriture**. Le contrôle lui-même est un script du dépôt, `bin/po-ci`, qui ne connaît aucune forge ; le fichier de workflow ne fait que l'appeler, dans une syntaxe que Forgejo Actions lit aussi. L'option 1 l'emporte sur les critères du porteur, mais elle suppose un chantier de forge que rien d'autre ne réclame aujourd'hui, et l'option 2 expose la machine qui héberge le runner tant que le dépôt est public. Le jour où une forge Forgejo auto-hébergée existe (#75), seul l'endroit où le workflow tourne change.

Quelle que soit l'option : `/po-ship` lit les contrôles de la forge sur le commit d'atterrissage et ne fusionne que s'ils passent, et rendre le contrôle obligatoire sur la branche cible (protection de branche) reste un geste du porteur.

### Consequences
- Good, because un fichier sous `docs/` qui casse la suite est vu avant d'atterrir, sans dépendre de la machine de celui qui livre.
- Bad, because chaque ship attend la fin de la suite sur la forge (quelques minutes).
- Neutral: la suite ne lance jamais `po-eval`, qui coûte des appels payants ; elle reste hors de la CI.
