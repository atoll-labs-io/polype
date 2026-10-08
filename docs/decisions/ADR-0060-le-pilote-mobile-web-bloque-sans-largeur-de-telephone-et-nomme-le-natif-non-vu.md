---
adr: 0060
title: Le pilote mobile-web bloque sans largeur de téléphone, et chaque rapport nomme ce que le rendu web ne montre pas
status: accepted
date: 2026-10-08
scope: story s82-mobile-web-driver
supersedes: []
superseded-by: []
---

# ADR-0060 — Le pilote mobile-web bloque sans largeur de téléphone et nomme le natif non vu

## Context and Problem Statement
ADR-0054 vérifie un écran mobile par le rendu web de la pile, dans le navigateur, en largeur de téléphone, et ADR-0057 route une story `screen` d'un projet `mobile` vers `qa-drivers/mobile-web.md`. Trois points restent ouverts : ce que fait le pilote quand l'outil de navigateur de la session ouvre une page sans pouvoir fixer sa taille ; si ce que le rendu web ne montre pas (permissions natives, notifications, caméra, gestes système, clavier à l'écran, zones sûres) figure dans chaque rapport ou seulement quand un critère en dépend ; à quels écrans s'appliquent les règles mobiles de `design-doctrine`.

## Considered Options
- **Outil sans réglage de la fenêtre : `QA status: blocked`, la cause écrite** — retenue. Une capture en largeur de bureau est la preuve d'un autre écran.
- **Outil sans réglage : capturer à la taille disponible et le signaler** — écartée : le rapport dirait `complete` sur des captures qui ne montrent pas ce qu'un téléphone affiche.
- **Outil sans réglage : simuler la largeur par le zoom** — écartée : le zoom change aussi la taille apparente des zones tactiles et les points de rupture CSS ne réagissent pas de la même façon.
- **Le natif non vu : une ligne permanente dans `## Not seen`, plus une ligne par critère qui en dépend** — retenue. La revue sait toujours que seul le rendu web a été regardé, et chaque critère concerné garde sa propre raison.
- **Le natif non vu : seulement les critères qui en dépendent** — écartée : un rapport sans critère concerné laisserait croire que le rendu web vaut l'app.
- **Le natif non vu : la liste entière ligne par ligne dans chaque rapport** — écartée : six lignes répétées à chaque story, recopiées dans chaque revue, noient les vrais manques.
- **Règles mobiles pour les écrans d'un projet dont `Platform` contient `mobile`** — retenue.
- **Règles mobiles aussi pour tout écran web en largeur mobile** — écartée : elle changerait sans le dire le contrat du designer et de la revue des projets web, ce que cette story ne demande pas.

## Decision Outcome
Chosen option: **bloquer sans largeur de téléphone, une ligne permanente du natif non vu plus une par critère concerné, et des règles mobiles qui valent pour un projet `mobile`**, parce que chacune empêche un rapport de dire plus qu'il n'a vu sans exiger d'outil que la session n'a pas.

- Les largeurs sont des pixels CSS : au zoom par défaut, un pixel CSS vaut un point iOS ou un dp Android, et 44 points se mesurent 44 pixels CSS dans le rendu web.
- Les zones sûres et le clavier à l'écran sont des règles que le designer et le reviewer tiennent en lisant le code ; le rendu web dans un navigateur de bureau ne les montre pas, donc le pilote les range dans ce qu'il ne peut pas montrer.

### Consequences
- Good, because aucun rapport de QA mobile ne passe `complete` sur des captures de bureau, et la revue reçoit toujours la limite du rendu web dans `## Not verified`.
- Bad, because une session dont l'outil de navigateur ne fixe pas la taille de la fenêtre ne peut pas faire la QA d'un écran mobile.
- Neutral: l'émulateur Android d'un lot suivant pourra réduire la ligne permanente ; il faudra alors un nouvel ADR qui remplace celui-ci en partie.
