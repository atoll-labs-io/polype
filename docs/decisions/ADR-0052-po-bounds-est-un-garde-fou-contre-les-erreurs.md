---
adr: 0052
title: po-bounds est un garde-fou contre les erreurs d'un agent, pas une barrière contre un contournement délibéré — et une redirection n'est pas un chemin de git
status: accepted
date: 2026-10-08
tags: [adr, polype, review, hooks, bounds]
scope: story s76-bounds-guard-against-mistakes
supersedes: [ADR-0047, ADR-0051]
superseded-by: [ADR-0053, ADR-0072]
---

# ADR-0052 — po-bounds est un garde-fou contre les erreurs, pas une barrière

## Context and Problem Statement
Depuis s70, chaque revue de `po-bounds` trouve un nouveau détour et la story suivante le ferme : s71 (heredocs), s74 (`-C` enchaînés, `core.worktree`, chemins des sondes), puis la revue de s74 (`docs/reviews/s74-reviewer-bounds-bypasses.md`) trouve les options courtes groupées (`config -zf<chemin>`) (M1). Chaque fermeture rend le hook plus strict, et la dernière refuse déjà une sonde légitime : `git -C <dépôt jetable> log 2>/dev/null` est refusé, parce que la cible d'une redirection est lue comme un chemin de git (M2). Un hook qui lit des commandes bash dans un lexer awk ne peut pas battre un agent décidé à le contourner. Il faut dire contre quoi il protège. Cette ADR remplace **en partie** ADR-0047 et ADR-0051 : leurs deux zones, leurs refus et leur règle de chemins restent, sauf pour la lecture des redirections. Elle change aussi ce que vise le hook.

## Considered Options
Pour ce que vise le hook :
- **Une barrière** : fermer chaque contournement qu'une revue trouve. Chaque revue en trouve un de plus, et chaque fermeture risque de refuser un geste légitime, comme l'a montré M2.
- **Un garde-fou contre les erreurs** : le hook arrête ce qu'un agent de bonne foi fait par accident (une sonde mal fermée, une commande lancée dans le mauvais dossier, un chemin de sonde qui tombe dans le checkout), et les contournements qui demandent une intention sont listés et acceptés. Option A, choisie par l'utilisateur le 2026-10-08.
- **Un bac à sable** : faire tourner le reviewer dans une isolation du système (namespace, conteneur, checkout principal monté en lecture seule). Le seul moyen de tenir contre un contournement délibéré. Écarté pour l'instant : il dépend de la plateforme (Linux contre macOS), se règle au niveau de Claude Code et pas d'un hook, et sort du périmètre d'une story de texte et de lexer. Il reste une piste pour plus tard.

Pour les redirections d'un appel git du dépôt jetable :
- **Laisser passer `/dev/null` dans la règle de chemins** : un correctif d'une ligne. La cible reste lue comme un mot de git, résolue depuis le dossier de git au lieu de celui du shell : `git -C <sonde> log > out.txt` lancé depuis le checkout est jugé dans la sonde, alors que bash écrit `out.txt` dans le checkout.
- **Le lexer marque les redirections** : retenu. L'opérateur, son numéro de descripteur et sa cible ne sont plus des mots de la commande ; la cible est jugée à part, depuis le dossier du shell.

## Decision Outcome
Chosen option: **un garde-fou contre les erreurs** et **le lexer marque les redirections**, parce que le hook ne peut tenir que la promesse qu'un lexer peut tenir, et qu'une règle qui refuse une sonde légitime coûte une revue bloquée à chaque fois.

- **Ce que le hook arrête** : les erreurs d'un agent de bonne foi. Une commande qu'un agent écrirait par mégarde et que le hook laisse passer, ou un geste légitime de la revue qu'il refuse, est un défaut du hook.
- **Ce qu'il n'arrête pas** : les contournements délibérés, qui n'ont d'usage que pour échapper à la lecture du hook. Ceux qu'on connaît sont acceptés :
  - les options courtes groupées, comme `config -zf<chemin>` ou `format-patch -ko<dossier>` : seuls les deux premiers caractères sont retirés avant de lire le chemin ;
  - la portée d'un `cd` lancé dans un sous-shell, une substitution, une tâche de fond ou un pipeline, ainsi que `pushd` et `popd` (ADR-0051) ;
  - un alias git, et les hooks d'un dépôt jetable ;
  - `GIT_CONFIG_GLOBAL` qui pointe un fichier de configuration ;
  - une clé construite par substitution, comme `-c "$(echo core.worktree)=<chemin>"` ;
  - ceux qu'ADR-0047 et ADR-0050 acceptaient déjà : un script ou une suite de tests qui lance git, un `export GIT_DIR` d'une commande antérieure, une variable `$VAR` qui contient `git`.
  Un nouveau contournement de cette nature, trouvé par une revue, s'ajoute à cette liste par une ADR ; il ne se ferme pas dans le hook.
- **Redirections** (tous les modes) : `<`, `>`, `>>`, `>|`, `<>`, `&>`, `&>>`, `<&` et `>&` ne sont pas des mots de la commande. Un numéro de descripteur collé à l'opérateur (`2>`) n'en est pas un non plus. La cible d'un `<&` ou d'un `>&` qui est un numéro ou `-` (`2>&1`, `>&-`) n'est pas un chemin. En mode `qa`, `git symbolic-ref HEAD 2>/dev/null` ne compte donc plus `2` ni `/dev/null` comme une cible.
- **Cible d'une redirection, dépôt jetable** (mode `reviewer`) : pour un appel git d'un dépôt jetable, chaque cible de redirection qui n'est pas `/dev/null`, `/dev/stdout` ou `/dev/stderr` se résout depuis le dossier du shell (celui que suivent les `cd`), et doit rester sous le répertoire temporaire. Une cible de valeur inconnue (substitution, `$`, `~` en tête), ou relative quand le dossier du shell est inconnu, est refusée.

### Consequences
- Good, because `git -C <sonde> log 2>/dev/null`, `… >/dev/null`, `… &>/dev/null` et `… 2>&1 | head` passent, et `git -C <sonde> log > out.txt` lancé depuis le checkout principal est refusé, alors que l'ancienne lecture le jugeait dans la sonde.
- Good, because une revue qui trouve un contournement délibéré l'écrit ici, au lieu d'ouvrir une story qui rendrait le hook plus strict.
- Bad, because un agent qui veut sortir de ses bornes le peut, par les formes listées. Ce trou est accepté : le texte du reviewer et de l'implementer reste leur première borne, et le bac à sable la piste pour tenir contre un agent décidé.
- Bad, because une redirection d'une commande hors git, ou d'un appel git du worktree de la story, n'est toujours pas lue (ADR-0047).
- Neutral: ADR-0047 et ADR-0051 gardent `status: accepted` et nomment cette ADR dans `superseded-by`, leur corps inchangé.
