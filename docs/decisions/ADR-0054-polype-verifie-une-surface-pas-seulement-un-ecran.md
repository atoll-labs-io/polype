---
adr: 0054
title: Polype vérifie la surface d'une story sur toutes les plateformes, pas seulement un écran dans un navigateur
status: accepted
date: 2026-10-08
tags: [adr, polype, qa, platforms, m8]
scope: framing
supersedes: []
superseded-by: []
---

# ADR-0054 — Polype vérifie une surface, pas seulement un écran

## Context and Problem Statement
Jusqu'à M7, Polype suppose qu'un projet est une application web : une story « a un écran » quand son texte en montre un, le designer dessine ce que le navigateur affichera, et la QA visite les pages dans un navigateur. Les projets à venir ne s'y prêtent pas : clout est une application mobile, et l'utilisateur veut que Polype sache aussi piloter une CLI, une API ou une bibliothèque, une scène 3D ou XR, et un robot ou un système embarqué. Il faut dire ce qu'une story livre de visible pour chaque plateforme, comment on le vérifie avant la revue, et ce qui reste hors de portée d'un agent.

## Considered Options
- **Un agent de QA par plateforme** : cinq contrats presque identiques (rapport, statut, preuve committée, gate) qui divergeraient au fil des corrections.
- **Un seul agent de QA, un pilote par surface** : retenu. Le contrat de `qa` (rapport, `QA status:`, preuves sous `docs/qa/<id>/`, `qa-current`) ne change pas ; seule la façon de produire la preuve dépend de la surface.
- **Deviner la plateforme depuis le code** : fragile, et faux pour un dépôt vide comme clout au premier jour.
- **L'émulateur mobile dès M8** : écarté par l'utilisateur au profit du rendu web d'abord ; l'émulateur Android viendra dans un lot suivant.
- **Valider sur le matériel réel** (téléphone, casque, robot) : un agent ne peut pas le faire sans une personne présente ; la preuve d'un agent s'arrête à la simulation.

## Decision Outcome
Chosen option: **un seul agent de QA, un pilote par surface**, parce que la preuve change de forme selon la plateforme mais que la promesse faite à la revue (« ce qu'une personne verrait a été regardé, et voici la trace ») reste la même.

- **Plateforme du projet** : un réglage `Platform` dans `AGENTS.local.md`, une liste parmi `web`, `mobile`, `cli`, `api`, `lib`, `xr`, `robot`, que `/po-setup` demande. Il décide quels profils de boilerplate `/po-setup` propose et quels pilotes de QA s'appliquent.
- **Surface d'une story** : une ligne `Surface` dans chaque story de `docs/stories.md`, parmi `screen` (une page ou un écran d'app), `command` (une commande ou une sortie de CLI), `endpoint` (une requête et sa réponse d'API, ou l'appel public d'une bibliothèque), `scene` (une scène 3D ou XR), `behaviour` (un comportement de robot ou de système embarqué), ou `—`. Une story sans cette ligne garde l'ancienne règle : elle a un écran quand son texte en montre un.
- **Design** : seule une surface `screen` passe par le design. Une `scene` n'a pas de système de design ; ses repères visuels vont dans le plan.
- **QA** : `QA stage: screens` garde son sens (QA des seules surfaces `screen`) ; `QA stage: surfaces` fait passer en QA toute story dont la surface n'est pas `—`. `—` reste « pas de QA ».
- **Pilotes de QA**, écrits dans la skill `qa-drivers`, un fichier par pilote, préchargée par `qa` :

| Surface | Pilote | Preuve sous `docs/qa/<id>/` |
| --- | --- | --- |
| `screen`, plateforme `web` | navigateur (la section de `design-doctrine` qui l'explique déjà) | captures |
| `screen`, plateforme `mobile` | rendu web de la pile mobile dans le navigateur, en largeur de téléphone | captures |
| `command`, `endpoint` | scénarios lancés dans le shell (commande, `curl`, appel de la bibliothèque) | transcriptions entrée et sortie |
| `scene` | rendu sans fenêtre du moteur, ou WebXR dans le navigateur | captures de scène |
| `behaviour` | simulation (ROS 2 et Gazebo sans fenêtre) | journaux et enregistrements de topics |

- **Profils de boilerplate** : chaque profil déclare sa plateforme et son pilote de QA. M8 en écrit un par pile retenue : Expo (React Native), Flutter, natif iOS et Android, CLI en Rust (clap), API en TypeScript (Hono), Godot pour la 3D et l'XR, ROS 2 avec Gazebo pour la robotique.
- **Hors de portée** : le matériel réel, et le simulateur iOS (il demande un Mac). Le rapport QA le dit quand une story en aurait besoin, et la revue le reporte en « Not verified ».

### Consequences
- Good, because un projet mobile, une CLI ou un robot passent par le même cycle et les mêmes gates qu'un site web, et la revue garde une preuve de QA à jour quelle que soit la plateforme.
- Bad, because la ligne `Surface` est une donnée de plus à écrire par `/po-stories` et à relire par `/po-stories-review`, et chaque pilote est un outillage de plus à tenir à jour (navigateur, moteur, simulateur).
- Neutral: tant que le fichier d'un pilote n'existe pas, `qa` s'arrête sur une story de cette surface et le dit ; l'émulateur Android, le simulateur iOS et le matériel réel restent à décider dans un lot suivant.
