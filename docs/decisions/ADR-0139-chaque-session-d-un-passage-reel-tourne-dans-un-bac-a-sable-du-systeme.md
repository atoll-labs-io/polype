---
adr: 0139
title: Chaque session d'un passage réel tourne dans un bac à sable du système, Claude Code n'y vérifiant plus rien
status: proposed
date: 2026-11-25
scope: story s212-real-run-in-an-outer-sandbox
supersedes: [ADR-0137, ADR-0138]
superseded-by: []
---

# ADR-0139 — Chaque session d'un passage réel tourne dans un bac à sable du système, Claude Code n'y vérifiant plus rien

## Context and Problem Statement
Les cinq passages réels des 23-25/11 ont buté sur les couches de protection de Claude Code plutôt que sur la méthode : la liste de commandes (#476, [ADR-0136](ADR-0136-cd-et-les-commandes-de-lecture-entrent-dans-la-liste-de-permissions-d-un-passage-reel.md)), `cd` + `git` et les redirections, `.git` protégé (#495), l'exception de git qui laisse sortir des programmes (d-0062, d-0063, #502), les commandes composées gardées dans le bac à sable (#508), l'écriture du relevé de vérification refusée (#516), un masque du bac à sable pris pour une règle changée (#517). Le porteur a décidé le 2026-11-25 (#503) de confiner toute la session `claude -p` dans un bac à sable posé par le lanceur, et de retirer à l'intérieur le bac à sable de Claude Code ([ADR-0137](ADR-0137-un-passage-reel-confine-ses-commandes-par-le-bac-a-sable-de-claude-code.md)), l'exception de git ([ADR-0138](ADR-0138-git-seul-tourne-hors-du-bac-a-sable-d-un-passage-reel.md)) et toute demande de permission. Reste à choisir l'outil et ce que la session peut joindre sur le réseau. Le point d'accroche est unique : l'`exec` du vrai `claude` dans `evals/real/claude-print`.

Ce qui vaut quelle que soit l'option : écriture tenue au dossier du passage ; `HOME` et la configuration Claude Code de la personne illisibles, le binaire `claude`, les doublures et le dépôt Polype remontés en lecture seule ; `--permission-mode bypassPermissions` et `--permission-prompts none` (une demande qui subsisterait est refusée, jamais attendue) ; plus de clé `sandbox`, plus de liste `allow`, plus de règle `Bash(…)` ; `WebFetch` et `WebSearch` restent refusés, parce que WebSearch tourne chez Anthropic et qu'aucune règle réseau locale ne l'arrête ; la comparaison de ce qui gouverne une session reste. Le modèle doit joindre l'API d'Anthropic (`api.anthropic.com`).

## Considered Options
Classées par les critères du porteur, dans l'ordre : libre ou auto-hébergeable, sobre en matériel, extensible, facile à manier pour une IA (`## Ranking the options` du skill `capability-bricks`).

- **A. `bwrap` lancé directement par `claude-print`**, réseau de la machine partagé. Libre (LGPL-2.0+), déjà requis depuis s208, aucun processus de plus. `--ro-bind / /`, `--bind` du dossier du passage, `--tmpfs` sur le `HOME` de la personne, sa configuration Claude Code, `/run/user/<uid>` et le dossier temporaire des passages, `--unshare-pid`, `--proc`, `--dev`, `--die-with-parent`, `--new-session`. Aucun masque : `.git`, `.gitconfig`, `.claude/` s'écrivent comme dans un dépôt ordinaire. `socat` n'est plus requis.
  - Réseau : tout ce que la machine joint — Internet, le réseau local, les services en écoute sur `localhost`, les sockets Unix abstraites. Rien n'est filtré par domaine.
  - Variante A2, réseau dans son propre espace par `pasta` (installé ici, une dépendance de plus) : sortie vers Internet et le réseau local, sans les services locaux ni les sockets abstraites de la machine ; toujours aucun filtre par domaine.
  - Contre : Linux seulement (un passage réel ne part plus sous macOS) ; un passage non surveillé reste fermé, faute de borne réseau.
- **B. `sandbox-runtime` (`srt`) d'Anthropic**, réseau limité à `api.anthropic.com`. Libre (Apache-2.0), utilisable hors de Claude Code en ligne de commande (`srt --settings <f> -- <commande>`), Linux et macOS. Sous Linux : le même `bwrap` et `socat`, plus un processus Node (≥ 22.12) qui tient deux mandataires HTTP et SOCKS, et `ripgrep`. Réseau coupé (`--unshare-net`) sauf par les mandataires, qui ne laissent passer que les domaines listés ; sockets Unix bloquées par seccomp ; lectures permises partout sauf `denyRead`.
  - Pour : la seule option qui borne le réseau à l'API du modèle, condition qu'[ADR-0134](ADR-0134-un-passage-reel-se-lance-devant-une-personne-dans-une-configuration-confinee.md) pose à un passage non surveillé ; un seul fichier JSON.
  - Contre : version 0.0.83, « Beta Research Preview », format susceptible de changer ; une dépendance npm à épingler ; elle applique d'office les mêmes interdictions d'écriture que le bac à sable de Claude Code (`.git/config`, `.git/hooks`, `.gitconfig`, fichiers de shell, `.mcp.json`, `.claude/commands`, `.claude/agents`), donc les masques de #517 et `.git/config` de #495 reviennent, sauf `filesystem.allowGitConfig` ; que Claude Code passe par le `HTTPS_PROXY` qu'elle pose et quels autres hôtes il appelle (télémétrie, coupable par `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`) n'est pas vérifié.
- **C. Un conteneur `podman` sans privilèges.** Libre (Apache-2.0), système de fichiers à part, portable (une machine virtuelle sous macOS).
  - Contre : le plus lourd — une image à construire et à tenir (git, jq, bash, le binaire `claude`, `po` compilé pour elle), du disque, un démarrage plus lent, les identifiants de fichiers à faire correspondre (`--userns=keep-id`) ; réseau ouvert vers l'extérieur par `pasta`, un filtre par domaine demandant un mandataire de plus, comme A.

Classement : **A, puis B, puis C.** Les trois sont libres. A est la plus sobre (rien de plus que ce que la machine tient déjà) ; B ajoute un processus Node et ses dépendances ; C une image et son stockage. Sur l'extensibilité, B passe devant : elle seule borne le réseau à l'API et ouvre un jour le passage non surveillé. Le critère qui justifierait de passer A pour B est donc l'extensibilité, au prix d'un bêta et du retour des masques.

## Decision Outcome
**À trancher par le porteur.** Le plan de s212 est écrit pour l'option en tête, **A** (réseau de la machine partagé), avec `Technical choice: waiting for a human`.

Ce que la décision tranche dans tous les cas :
- Elle remplace ADR-0137 et ADR-0138 en entier : leurs réglages de bac à sable, l'exception de git, `Bash(git *)` et les règles `deny` sur git disparaissent de la configuration d'un passage. Ce qui reste d'ADR-0134 tient : une personne lance et regarde le passage, l'identifiant vient de l'environnement, `--max-budget-usd`, jamais de modèle de repli.
- Sans l'outil choisi sur le `PATH` du passage, `po-eval real` le nomme et ne lance rien, avant la confirmation.
- Le cas d'une personne qui active elle-même le bac à sable de Claude Code n'est plus éprouvé par un passage réel : la méthode n'y est plus mesurée, ni ses refus relevés.
- Ce que la décision n'ouvre pas : un passage non surveillé ou planifié. Sous A, le réseau n'est pas borné ; sous B il l'est, mais l'ouverture demande toujours une nouvelle ADR (ADR-0134).

### Consequences
- Good, because une commande composée, un `cd`, une redirection et git s'exécutent comme hors de tout passage ; la méthode se mesure sans les refus de Claude Code, et ce qu'une session écrit hors de son dossier ou lit chez la personne est refusé par le système, pour tout programme qu'elle lance.
- Bad, because une session n'a plus aucune demande de permission entre elle et ce que le bac à sable laisse faire : une faille de l'outil ouvre tout ce qu'il ne ferme pas, et sous A le réseau entier.
- Bad, because la session lit toujours son propre identifiant dans son environnement, et le vrai `claude` reste lisible par son chemin complet : une session imbriquée payante reste possible, comme ADR-0134 l'acceptait.
- Neutral: que `bypassPermissions` de Claude Code 2.1.33x demande encore quelque chose sur `.git` ou `.claude` (alors refusé) ne se voit qu'à un vrai passage. La CI installe l'outil, et sous Ubuntu 24.04 doit lever la restriction AppArmor des espaces de noms sans privilèges.
