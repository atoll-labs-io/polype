---
adr: 0134
title: Un passage réel se lance devant une personne, dans une configuration confinée
status: accepted
date: 2026-11-23
scope: story s206-real-run-before-a-release
supersedes: []
superseded-by: [ADR-0135, ADR-0140]
---

# ADR-0134 — Un passage réel se lance devant une personne, dans une configuration confinée

## Context and Problem Statement
`po-eval real` (s206) lance un vrai chef de projet, par `po run`, sur un dépôt jetable : un modèle avec des outils (shell, écriture de fichiers, subagents) tourne sous le compte de la personne, avec un identifiant de connexion dans son environnement. Les bornes de `po-bounds` ne tiennent que l'implementer, la QA et le reviewer ; le chef et le planner n'en ont pas. Il faut dire ce qui confine le passage, et à quelles conditions il peut tourner.

## Considered Options
- **C1. Une configuration temporaire confinée, devant une personne.** Liste de permissions dans la configuration temporaire (`git`, `bash`, `sh`, `jq`, le `po` de la configuration, `.polype/hooks/*`, outils de fichiers limités au dossier du passage, outil Agent ; outils web, `curl` et `claude` refusés) ; toute demande de permission refusée (`--permission-prompts none`) ; `HOME`, `TMPDIR` et la configuration dans le dossier du passage ; doublures pour la forge et les trackers (`gh`, `curl`, `glab`, `tea`, `task`, `claude`), aucun jeton de forge ; plafond de dépense par session (`--max-budget-usd`) ; jamais de modèle de repli. Rien à installer.
- **C2. Tout le passage dans un bac à sable sans privilèges** (bubblewrap ou conteneur rootless) : seul le dossier du passage en écriture, le dépôt Polype en lecture, le réseau limité à l'API du modèle.
- **C3. `--dangerously-skip-permissions`**, à l'intérieur de C2.

## Decision Outcome
Option choisie : **C1**, par le porteur le 2026-11-23 (d-0056), parce que les passages qu'elle sert sont lancés et regardés par une personne, et qu'elle ne demande rien de plus à la machine.

Ce qui vaut désormais :
- **Un passage réel est pour une personne qui le lance et le regarde.** `po-eval real` affiche le nombre de passages payants et pose sa question de confirmation sur un terminal ; sans terminal sur cette question, la commande refuse et ne lance rien. Aucune option ne saute la confirmation.
- **L'identifiant de connexion vient de l'environnement** (`ANTHROPIC_API_KEY` ou `CLAUDE_CODE_OAUTH_TOKEN`). La commande n'en affiche que le nom ; la valeur ne passe par aucun argument, aucun fichier de `docs/`, ni git. Les transcriptions gardées restent dans un dossier temporaire en mode 700, nettoyées comme `po-intake` nettoie un rapport.
- **La limite de C1, acceptée en connaissance de cause** : le chef de projet et le planner ne sont pas bornés. Une commande permise peut atteindre tout chemin que la personne peut atteindre (un `git -C`, une redirection), et tout agent du passage peut lire son propre environnement, identifiant compris. C1 réduit ce qu'un agent de bonne foi fait par erreur ; elle n'arrête pas un agent qui chercherait à en sortir. La présence de la personne en est le complément.

Options écartées :
- **C2 dès maintenant** : une dépendance de plus sur la machine, pour des passages qu'une personne regarde déjà. Elle reste la condition de tout passage non surveillé.
- **C3** : sans demande de permission, tout repose sur le bac à sable, et un défaut de ce bac ouvre tout ; aucun passage ne le demande.

Ce qui rouvrirait la décision : vouloir un passage non surveillé ou planifié (un ordonnanceur, une CI, une nuit). Il demande d'abord C2, par une nouvelle ADR.

### Consequences
- Good, because un passage réel ne demande rien à installer, et ne peut partir sans qu'une personne l'ait vu annoncer son coût.
- Bad, because un passage ne peut pas tourner sans personne, et ce qui le confine reste contournable par un agent.
- Neutral: la syntaxe des règles de permission dépend de Claude Code ; une version qui la change se voit au premier passage, aux refus qu'il relève.
