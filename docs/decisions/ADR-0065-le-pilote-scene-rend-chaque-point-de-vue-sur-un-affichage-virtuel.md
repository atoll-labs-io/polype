---
adr: 0065
title: Le pilote scène rend chaque point de vue par le moteur sur un affichage virtuel, depuis une copie, et le profil Godot part de godot-xr-template 4.6.0
status: accepted
date: 2026-10-08
scope: story s87-godot-scene-driver
supersedes: []
superseded-by: []
---

# ADR-0065 — Le pilote scène rend chaque point de vue sur un affichage virtuel, et le profil Godot part de godot-xr-template 4.6.0

## Context and Problem Statement
ADR-0054 donne au pilote `scene` « le rendu sans fenêtre du moteur, ou WebXR dans le navigateur » et s80 met les points de vue dans `## Scene viewpoints` du plan. Deux faits du moteur ferment la lecture évidente : `--headless` de Godot remplace le rendu par un rasteriseur factice (`servers/display/display_server_headless.cpp:40` à `4.7.2-stable`), donc une capture y serait vide ; et lancé normalement, Godot ouvre sa fenêtre sur l'écran de la personne, sous Wayland comme sous X11. Il faut fixer comment le pilote rend une image sans fenêtre visible, comment il place la caméra de chaque point de vue, ce qu'il fait quand il ne peut pas, et depuis quel gabarit public le profil Godot est écrit.

## Considered Options
- **Le moteur sur un affichage virtuel (`xvfb-run`), le pilote d'affichage forcé sur celui-ci, depuis une copie dans le répertoire `mktemp -d`, un script de capture écrit dans ce répertoire qui place une caméra par point de vue et enregistre un PNG après une image rendue** — retenue.
- **Le mode `--headless` du moteur avec un script de capture** — écartée : rasteriseur factice, aucune image, et rien ne le signale à qui lit le PNG vide.
- **Le moteur dans une fenêtre sur l'écran de la session** — écartée : il prend l'écran de la personne, dépend de sa taille et de son compositeur, et contredit le critère « sans fenêtre ».
- **`--write-movie` (Movie Maker) seul** — écartée comme route : il enregistre ce que montre la caméra du jeu, pas les points de vue du plan, et demande lui aussi un affichage.
- **WebXR dans le navigateur comme route par défaut** — écartée : la page ne laisse pas placer une caméra, une session immersive ne démarre pas sans casque, et l'export web exige les modèles d'export du moteur. Gardée en repli : quand le projet ne nomme aucune commande du moteur mais que `Dev` sert une page WebXR, le pilote capture la vue en page que le navigateur montre, et tout point de vue que cette page n'atteint pas va dans `## Not seen`.
- **Une extension de capture ajoutée au projet (cadre de test, addon)** — écartée : une dépendance que la QA imposerait au projet, alors que la QA ne modifie rien.
- **Point de vue trop vague pour placer une caméra : le pilote devine** — écartée ; il va dans `## Not seen` en disant ce qui manque (position, cible ou champ). Un plan sans aucun point de vue pour une story `scene` → `QA status: blocked`.
- **Gabarit `GodotVR/godot-xr-template`, tag `4.6.0` (`7d8261cd37b07bbf28638cad39cf4b2d6cedd936`), MIT** — retenue : un point de départ de jeu XR, versionné et étiqueté, qui embarque Godot XR Tools et un préréglage d'export WebXR.
- **`godotengine/godot-demo-projects`** — écartée : une collection de démos, pas un point de départ ; il faudrait en élire un dossier.
- **Un projet vide créé par l'éditeur** — écartée : aucun dépôt public à un commit nommé à décrire.
- **La branche `4.2` du même gabarit** — écartée : elle vise Godot 4.2 à 4.5, quand `main` vise 4.6+ et que sa CI fixe 4.7.2.
- **`Dev` du profil : lancer le jeu (`godot --path .`)** — écartée : il ouvre une fenêtre et n'imprime aucune adresse, ce que le gabarit de profil demande à `Dev`. Le profil met `Dev: —` et nomme la commande du moteur dans sa prose, où le pilote la lit.

## Decision Outcome
Chosen option: **le moteur sur un affichage virtuel, depuis une copie, un script de capture par point de vue, WebXR en repli, et le gabarit `godot-xr-template` au tag `4.6.0`**, parce que c'est la seule route où une image est vraiment rendue, sans fenêtre visible, à l'endroit exact que le plan nomme.

- La commande du moteur vient du projet (réglages, conventions, profil nommé dans les conventions, README), jamais inventée ; introuvable, ou aucun affichage virtuel disponible → `QA status: blocked` avec la cause.
- Le pilote ne change ni la lumière ni les matériaux de la scène ; il note pour chaque capture la position, la cible, le champ de vision, la résolution et le rendu utilisés.
- Ce que seul un casque montre (confort, échelle ressentie, suivi des mains, manettes) est porté par une ligne permanente de `## Not seen`.

### Consequences
- Good, because chaque point de vue du plan devient une image que la revue compare au plan (`reviewer.md`), et le worktree reste intact par construction (ADR-0059).
- Bad, because la machine de QA doit avoir le moteur et Xvfb ; sans GPU, le rendu logiciel (Mesa) peut différer en lumière et en ombres d'un rendu matériel.
- Bad, because l'import du projet est refait dans la copie à chaque QA.
- Neutral: un moteur qui offre un vrai rendu hors écran pourra remplacer l'affichage virtuel ; le profil suit `godot-xr-template` jusqu'à un nouveau tag.
