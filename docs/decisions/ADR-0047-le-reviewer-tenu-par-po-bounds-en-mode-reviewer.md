---
adr: 0047
title: Le reviewer est tenu par po-bounds en mode reviewer — le worktree de la story en lecture et restauration, les dépôts jetables du répertoire temporaire libres sauf push
status: accepted
date: 2026-10-08
tags: [adr, polype, review, hooks, bounds]
scope: story s70-reviewer-bounds
supersedes: []
superseded-by: [ADR-0051]
---

# ADR-0047 — Le reviewer est tenu par po-bounds en mode reviewer

## Context and Problem Statement
Pendant la revue de s62, un heredoc de sonde s'est refermé trop tôt et `git push` a tourné six fois dans le checkout principal (`docs/reviews/s62-bounds-scan.md`). Seul le texte du reviewer le retenait. Il lui faut un hook, comme à l'implementer (ADR-0022) et à la QA (ADR-0026). Ce hook doit laisser passer trois gestes de la revue : la preuve de morsure (modifier un fichier du worktree, lancer ses tests, le restaurer, `git diff --exit-code`), les lectures git de la revue, et les sondes que les revues de M6 et M7 ont montées dans des dépôts jetables sous `/tmp`, qui committent et créent des branches. Le hook ne reçoit pas l'id de la story.

## Considered Options
- **Rien de plus que le texte du reviewer** — c'est ce qui a laissé passer l'incident.
- **Réutiliser le mode `implementer`** — écritures bornées à l'`Owns` et à `docs/`, `commit` permis dans le worktree. Ce mode bloque les sondes dans le répertoire temporaire et laisse au reviewer le droit de committer.
- **Réutiliser le mode `qa`** — Edit refusé, git en liste blanche de lecture. Ce mode tue la preuve de morsure et interdit `git restore`.
- **Un mode `reviewer` qui interdit `commit`, `branch`… partout, dépôts jetables compris** — c'est la lecture littérale du critère. Elle bloque toute sonde qui construit un dépôt de test.
- **Un mode `reviewer` à deux zones** — retenu, décrit ci-dessous.
- **Répertoire temporaire = `/tmp` en dur, ou `/tmp` et `$TMPDIR`** — `/tmp` est faux sous macOS. Les dépôts de test de la suite vivent eux-mêmes sous `/tmp`, et ils deviendraient tous des dépôts jetables : aucun test ne pourrait plus voir un refus.
- **Lier le reviewer à sa seule story** (id passé au hook) — le frontmatter est statique et Claude Code ne passe aucun id au hook.

## Decision Outcome
Chosen option: **un mode `reviewer` à deux zones**, parce qu'il garde les trois gestes de la revue et ferme l'incident : `push` est refusé partout, et toute commande git hors des deux zones est refusée.

- **Le worktree d'une story** est un worktree lié sur une branche `story/<id>`, dont la story figure dans `docs/stories.md` avec une ligne `Owns` au point de départ (ADR-0038).
  - Write et Edit passent partout dans ce worktree, sauf sous `.git`.
  - Git n'y passe que pour les verbes de lecture de la liste de la QA (ADR-0026), avec les mêmes refus de `--output` et des formes d'écriture de `symbolic-ref`, plus deux formes de restauration. La première est `git checkout -- <chemin>…`, où `--` suit immédiatement le verbe. La seconde est `git restore [-q|--quiet|-W|--worktree] [--] <chemin>…`, avec au moins un chemin. Toute autre option de `restore`, dont `--staged` et `--source`, est refusée.
- **Le répertoire temporaire** est `${TMPDIR:-/tmp}`, résolu physiquement. Il est refusé s'il vaut `/` ou n'existe pas.
  - Write et Edit passent sous lui.
  - Git y passe pour tout verbe sauf `push` et `send-pack`. Il faut pour cela que le répertoire de la commande ne soit dans aucun dépôt, ou dans un dépôt dont le répertoire git commun et la racine sont eux aussi sous le répertoire temporaire. Un worktree du vrai dépôt posé sous `/tmp` n'est donc pas jetable.
  - Dans le dépôt jetable, une écriture doit aussi satisfaire cette condition.
- **Partout** :
  - `git push`, `git send-pack`, `--git-dir` et `--work-tree` sont refusés.
  - Un mot non cité qui commence par `GIT_DIR=` ou `GIT_WORK_TREE=` est refusé.
  - Une commande git dont le répertoire n'existe pas, ou qui n'est dans aucune zone, est refusée. C'est le cas du checkout principal et d'un chemin écrit avec une variable que le hook ne développe pas.
  - Une entrée illisible est refusée, comme dans les autres modes.

### Consequences
- Good, because une sonde qui s'échappe dans le checkout principal ne peut ni pousser, ni committer, ni rien écrire par git. Elle ne peut même pas y lire : le reviewer lit le dépôt par `-C <worktree>`, ce que son fichier demandait déjà.
- Good, because la preuve de morsure garde ses trois façons de défaire une modification (Edit, `git checkout --`, `git restore`).
- Bad, because le hook ne sait pas quelle story le reviewer relit : il peut écrire dans le worktree d'une autre lane en cours. Trou accepté.
- Bad, because les écritures faites en Bash ne sont pas vues : redirections, `cp`, `sed -i`, et un script qui lance git (la suite de tests en est un). Ne sont pas vus non plus un `export GIT_DIR` posé dans une commande antérieure, ni un `git config core.worktree` qui pointe un dépôt jetable vers le vrai arbre. Ces trous sont acceptés, comme pour l'implementer (ADR-0039).
- Bad, because une sonde doit écrire en clair le chemin de son dépôt jetable. `cd "$(mktemp -d)" && git init` est refusé : le reviewer lit d'abord le chemin rendu par `mktemp -d`, puis le réutilise tel quel.
- Bad, because `git branch --merged` est refusé dans le worktree. Le contrôle « branche non fusionnée » de la revue passe par `git merge-base --is-ancestor` ou `git log`.
- Neutral: un projet dont `.polype/hooks/po-bounds.sh` date d'avant s70 refuse tout appel du nouveau reviewer (mode inconnu), jusqu'à ce que `polype init <projet>` rafraîchisse le script. `docs/installation.md` et la phrase de `method/AGENTS.md` sur po-bounds ne parlent encore que de l'implementer et de la QA. Ces deux fichiers sont hors de l'`Owns` de s70 et restent à mettre à jour par une autre story.
