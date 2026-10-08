---
adr: 0024
title: po-bounds trouve la story par le worktree visé, lit son Owns committé et son entrée avec jq
status: accepted
date: 2026-10-07
tags: [adr, polype, hooks, bounds]
scope: story s50-implementer-bounds
supersedes: []
superseded-by: [ADR-0038, ADR-0039]
---

# ADR-0024 — po-bounds trouve la story par le worktree visé, lit son Owns committé et son entrée avec jq

## Context and Problem Statement
ADR-0022 tient les bornes de l'implementer par un hook PreToolUse de son frontmatter. La commande du hook est fixe : elle ne peut pas porter l'id de la story, et l'entrée que Claude Code lui passe ne le contient pas (`tool_name`, `tool_input`, `cwd`, `agent_type`). Le `cwd` ne suit pas les `cd` d'un subagent, dont le shell revient au répertoire de session à chaque commande. Il faut donc décider d'où vient la story, d'où vient son `Owns`, comment lire un JSON en bash, et jusqu'où analyser une commande Bash.

## Considered Options
- **Story tirée de la transcription** (`transcript_path`, message de lancement) — dépend d'un format de transcription que Claude Code ne garantit pas, écrit de façon asynchrone.
- **Fichier d'état de lane** écrit par le driver dans le worktree — un fichier de plus à poser, à nettoyer, et que l'implementer pourrait lui-même réécrire.
- **Story tirée du `cwd` de l'entrée** — faux pour un subagent : c'est le répertoire de session, pas le worktree.
- **Story tirée du worktree visé** — le chemin écrit (Write/Edit), ou le répertoire où git tourne (`-C`, sinon dernier `cd`, sinon `cwd`), doit être dans un worktree lié dont la branche est `story/<id>` ; l'id est la fin de la branche.
- **`Owns` lu dans la copie de travail de `docs/stories.md`** — `docs/` est inscriptible, l'implementer pourrait élargir ses propres bornes.
- **`Owns` lu dans `HEAD:docs/stories.md` du worktree** — la version committée ; une modification en cours ne l'élargit pas.
- **JSON en bash/awk pur** — aucune dépendance, mais un décodeur de chaînes JSON (échappements, unicode) maison est une surface de bugs, sur un contrôle qui doit échouer fermé.
- **`python3`** — absent par défaut sur macOS récent.
- **`jq`** — fait pour ça, présent sur macOS 15+ et la plupart des Linux ; absent → refus.
- **Analyse Bash sensible aux guillemets** — moins de faux positifs, mais un tokenizer shell partiel (`$(…)` dans des guillemets doubles, `sh -c '…'`) se trompe dans les deux sens.
- **Analyse Bash en mots, guillemets retirés** — tout `git <verbe interdit>` présent dans le texte est refusé, même cité dans un `grep` ou un `echo`.

## Decision Outcome
Chosen option: **story tirée du worktree visé**, **`Owns` lu dans `HEAD:docs/stories.md`**, **`jq`**, et **analyse Bash en mots, guillemets retirés**, parce que chacun échoue fermé là où l'alternative échoue ouvert ou devine : un chemin hors de tout worktree `story/*`, ou dans le worktree principal, est refusé ; une story absente du fichier committé est refusée ; `jq` absent est refusé ; un faux positif coûte une commande reformulée, un faux négatif laisse passer ce que la Loi 4 interdit.

### Consequences
- Good, because le script ne lit aucun réglage et ne dépend d'aucun état écrit par un autre agent, comme `po-gate`.
- Good, because une édition non committée de `docs/stories.md` n'élargit pas les bornes pendant un run.
- Bad, because `jq` devient une dépendance des projets dont l'implementer écrit : `docs/installation.md` le dit.
- Bad, because une écriture dans le worktree d'une autre story est jugée contre l'`Owns` de cette autre story, pas refusée d'office ; la revue (`review-antihallu`) garde son contrôle d'ownership.
- Bad, because `grep "git checkout" …` est refusé ; l'implementer reformule (`grep 'checkout'`).
- Neutral: s51 ajoute le mode `qa` au même script ; la résolution de la story et la lecture de l'entrée restent communes.
