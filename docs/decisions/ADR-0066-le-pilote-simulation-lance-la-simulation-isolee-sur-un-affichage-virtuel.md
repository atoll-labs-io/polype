---
adr: 0066
title: Le pilote simulation lance la simulation du projet depuis une copie, isolée du réseau et sur un affichage virtuel, et le profil ROS 2 part de ros_gz_project_template
status: accepted
date: 2026-10-08
scope: story s88-ros-simulation-driver
supersedes: []
superseded-by: []
---

# ADR-0066 — Le pilote simulation lance la simulation isolée sur un affichage virtuel, et le profil ROS 2 part de ros_gz_project_template

## Context and Problem Statement
ADR-0054 donne au pilote `behaviour` « la simulation (ROS 2 et Gazebo sans fenêtre) », preuve « journaux et enregistrements de topics ». Le gabarit officiel `gazebosim/ros_gz_project_template` ouvre pourtant l'interface de Gazebo et RViz : son lancement passe à `gz sim` le seul chemin du monde, sans `-s`, et `ros_gz_sim` n'offre aucun argument pour n'avoir que le serveur. Son monde démarre en pause (pas de `-r`). Par défaut, la découverte de ROS 2 et le transport de Gazebo atteignent tout processus de la machine et du réseau local, et les journaux s'écrivent sous le répertoire personnel. Il faut fixer comment le pilote lance une simulation sans fenêtre visible, sans parler à un autre système, sans écrire hors de son répertoire temporaire, ce qu'il garde comme preuve, et depuis quel gabarit le profil est écrit.

## Considered Options
- **La commande de simulation du projet, depuis une copie dans le répertoire `mktemp -d` (ADR-0059), sous `xvfb-run`, Qt forcé sur `xcb` et `WAYLAND_DISPLAY` retiré, la visionneuse coupée quand le lancement offre un argument pour cela** — retenue.
- **`gz sim -s --headless-rendering` (serveur seul, rendu EGL)** — écartée comme route : le lancement du gabarit ne peut pas recevoir `-s` sans être modifié, et la QA ne modifie rien de ce qu'elle vérifie ; RViz et les autres interfaces du lancement resteraient à part. Un projet dont la commande est déjà sans interface passe aussi sous `xvfb-run`, sans dommage.
- **Modifier le lancement dans la copie pour retirer les interfaces** — écartée : la QA vérifierait un lancement que le projet n'a pas écrit.
- **Lancer sur l'écran de la session** — écartée : des fenêtres sur l'écran de la personne, ce que le critère exclut.
- **Isolation : domaine et découverte par défaut** — écartée : un pilote qui publie une commande de vitesse pourrait faire bouger la pile d'un développeur ou un robot réel du réseau. Retenue : un `ROS_DOMAIN_ID` sur lequel rien ne répond avant le départ, `ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST`, un `GZ_PARTITION` propre à la QA et `GZ_IP=127.0.0.1`. `ROS_LOCALHOST_ONLY` écartée : dépréciée sous Jazzy.
- **Écritures : laisser les journaux de ROS et les fichiers de Gazebo sous le répertoire personnel** — écartée : hors du répertoire temporaire, seule exception de `qa-drivers`. Retenue : `HOME`, `ROS_HOME` et `ROS_LOG_DIR` dans le répertoire temporaire, `--no-daemon` pour la CLI `ros2`, `ros2 daemon stop` à la fin.
- **Preuve : les sacs `ros2 bag` bruts dans `docs/qa/<id>/`** — écartée : binaires, lourds, illisibles dans une revue ou un diff. Retenue : les sacs sous le répertoire temporaire, et dans `docs/qa/<id>/` le journal de la simulation, une transcription par critère et un extrait lisible des topics utiles.
- **Déclencher un comportement par un topic deviné** — écartée : le pilote ne prend un topic, un service ou une action que dans le critère, le code du projet ou la liste de la simulation lancée ; sinon le critère va dans `## Not seen`.
- **Monde en pause : attendre** — écartée ; le pilote attend que `/clock` avance, et sinon reprend le monde par la commande que nomme le projet, puis bloque si l'horloge reste figée.
- **Gabarit `gazebosim/ros_gz_project_template`, branche `main`, commit `045e981d03aac1cc3712ab6bb086f52ea79aebf9`, Apache-2.0, ROS 2 Jazzy avec Gazebo Harmonic** — retenu : le gabarit officiel qui relie ROS 2 et Gazebo, avec un robot, un monde, un pont de topics et un lancement.
- **Sa branche `fortress`** — écartée : elle vise Gazebo Fortress, quand `main` vise Harmonic et suivants.
- **Kilted avec Ionic** — écartée : le `CMakeLists.txt` du gabarit ne connaît que `gz-sim7` et `gz-sim8`.
- **Un dépôt de démonstrations (`ros_gz` lui-même, `gz_ros2_control_demos`)** — écartée : des démos, pas un point de départ de projet.

## Decision Outcome
Chosen option: **la commande de simulation du projet, depuis une copie, sous un affichage virtuel, isolée par domaine, plage de découverte et partition, ses écritures dans le répertoire temporaire, et le gabarit `ros_gz_project_template` au commit `045e981`**, parce que c'est la seule route qui fait tourner la simulation telle que le projet l'a écrite sans fenêtre visible et sans pouvoir toucher un autre système.

- La commande vient du projet (réglages, conventions, profil nommé dans les conventions, README), jamais inventée ; introuvable, ou pas d'affichage virtuel → `QA status: blocked`.
- À la fin, le groupe de processus lancé est arrêté, le démon `ros2` aussi, et plus aucun nœud ne répond sur le domaine choisi ; sinon `blocked`.
- Ce que seul le matériel réel montre est porté par une ligne permanente de `## Not seen`.

### Consequences
- Good, because chaque critère arrive en revue avec ce que le robot simulé a reçu et publié, et ni le worktree, ni le répertoire personnel, ni un autre système ROS ne sont touchés.
- Bad, because la machine de QA doit avoir ROS 2 Jazzy, Gazebo Harmonic et Xvfb, et la copie est reconstruite à chaque QA ; sans GPU, l'interface et le `gpu_lidar` passent par Mesa et peuvent ralentir ou ne rien publier.
- Bad, because les sacs bruts disparaissent avec le répertoire temporaire : l'extrait lisible est la seule trace qui reste.
- Neutral: une option du lancement pour n'avoir que le serveur, ajoutée par le projet, rendrait l'affichage virtuel inutile ; le profil suit `main` jusqu'à une nouvelle version du gabarit.
