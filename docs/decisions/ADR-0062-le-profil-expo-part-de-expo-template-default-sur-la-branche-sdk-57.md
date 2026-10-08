---
adr: 0062
title: Le profil Expo part de expo-template-default sur la branche sdk-57, et nomme Jest comme commande de test
status: accepted
date: 2026-10-08
scope: story s83-expo-profile
supersedes: []
superseded-by: [ADR-0069]
---

# ADR-0062 — Le profil Expo part de expo-template-default sur la branche sdk-57

## Context and Problem Statement
s83 demande un profil Expo écrit depuis « le gabarit de départ officiel d'Expo à un commit nommé ». Le dépôt `expo/expo` porte cinq gabarits sous `templates/`, et sa branche `main` suit le SDK à venir (React Native `0.88.0-rc.4`, dépendances en `workspace:~`), pas celui que `npx create-expo-app` installe. La story demande aussi une commande `Test` qui accepte des chemins, alors que le gabarit n'embarque aucun lanceur de tests : son README renvoie au guide « Unit Testing with Jest ». Les deux choix fixent ce que `/po-setup` copie dans `AGENTS.local.md`.

## Considered Options
- **`templates/expo-template-default` à la tête de `sdk-57` (`345ae1660abdeb7e43ebca0e41b63e72b30969e8`)** — le gabarit que `create-expo` prend par défaut (`packages/create-expo/src/createAsync.ts:108`), à la version `57.0.29`, celle de l'étiquette npm `latest` le 2026-10-08 ; dépendances publiées, React Native `0.86.3`.
- **Le même gabarit sur `main`** — écarté : version `58.0.15` sous l'étiquette `next`, React Native en release candidate, dépendances `workspace:~` qu'un projet hors du monorepo ne résout pas.
- **`templates/expo-template-blank-typescript`** — écarté : ce n'est pas le défaut de `create-expo-app`, et sans expo-router ni écrans il ne dit rien du rendu web d'une app réelle.
- **`templates/expo-template-tabs`** — écarté : gabarit secondaire, choisi seulement par `--template tabs`.
- **`Test: —`, comme le profil hono-api** — écarté : le critère `expo_profile_names_its_web_render` exige une commande `Test` qui accepte des chemins, et le gabarit désigne lui-même Jest comme la voie de test.
- **`Test: npm test`** — écarté : le guide d'Expo écrit le script `test` en `jest --watchAll`, qui ne rend jamais la main.

## Decision Outcome
Chosen option: **`templates/expo-template-default` au commit `345ae1660abdeb7e43ebca0e41b63e72b30969e8`, avec `Test: npx jest`**, parce que c'est ce que reçoit un développeur qui lance `npx create-expo-app` aujourd'hui, et que `npx jest` est la commande du guide nommé par le README du gabarit qui accepte des chemins de fichiers et se termine.

### Consequences
- Good, because chaque fait du profil se vérifie dans un dossier précis d'un commit précis, comme ceux de next-forge, rust-cli et hono-api (ADR-0010, ADR-0061).
- Bad, because `npx jest` échoue sur un projet neuf tant que la première story de test n'a pas installé `jest-expo` et `jest` selon ce guide ; le profil le dit dans ses pièges.
- Bad, because la licence du gabarit (`0BSD`, dans son `package.json`) n'est pas celle du dépôt (`MIT`, dans `LICENSE`) ; le profil déclare celle du gabarit et nomme l'autre.
- Neutral: la branche `sdk-57` avance ; quand `latest` passera au SDK 58, un nouveau profil changera le commit, cette ADR restant celle du SDK 57.
