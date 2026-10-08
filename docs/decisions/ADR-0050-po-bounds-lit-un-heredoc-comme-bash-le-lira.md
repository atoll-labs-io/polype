---
adr: 0050
title: po-bounds lit un heredoc comme bash le lira et compte un git cité après l'option d'une enveloppe
status: accepted
date: 2026-10-08
scope: story s71-bounds-heredoc-expansion
supersedes: [ADR-0039]
superseded-by: [ADR-0072]
---

# ADR-0050 — po-bounds lit un heredoc comme bash le lira

## Context and Problem Statement
ADR-0039 a posé le lexer awk de `po-bounds`. La boucle de correction de s62 l'a étendu sans que l'ADR suive (revue de s62, m1), et la revue a trouvé qu'un heredoc à délimiteur non cité lu par un shell était relu tel que tapé, pas tel que bash le rend : `` echo \`git push\` `` passait (M1). Un `"git"` cité placé après l'option d'une enveloppe (`env -u X "git" push`) passait aussi. En relisant le code, un troisième trou est apparu : dans un heredoc non cité lu par un shell, les substitutions que le bash extérieur exécute en construisant le corps n'étaient pas lues (`echo '$(git push)'`). Cette ADR remplace ADR-0039 en entier : elle décrit ce que le lecteur fait réellement.

## Considered Options
Pour le corps d'un heredoc lu par un shell :
- **Relire le corps brut** (état actuel) — rate ce que l'expansion de bash fait apparaître.
- **Rendre le corps comme bash, puis le relire, et lire en plus ses substitutions extérieures** — deux lectures, chacune fidèle à un des deux shells.
- **Refuser tout heredoc non cité lu par un shell** — sûr, mais bloque `bash <<EOF` courant et pousse vers des contournements.

Pour un `git` cité après une enveloppe :
- **Table des options à argument de chaque enveloppe** (`env -u`, `sudo -u`, `nice -n`…) — exacte pour ce qu'elle liste, trouée pour le reste, à tenir à jour.
- **Lire les deux sens** : le mot qui suit une option d'enveloppe est à la fois candidat au nom de commande et argument possible de l'option ; le premier mot simple qui vient ensuite est candidat aussi.
- **Tout `git` cité après une enveloppe est un appel** — refuse aussi `sudo grep "git" f`.

## Decision Outcome
Chosen option: **rendre le corps comme bash et lire ses deux shells**, et **lire les deux sens après une option d'enveloppe**, parce que les deux échouent fermés sans liste à entretenir et restent dans la passe awk linéaire d'ADR-0039.

Ce que fait le lecteur, désormais :
- **Découpage** (inchangé depuis ADR-0039) : `;`, `&`, `&&`, `|`, `||`, `|&`, `(`, `)`, le retour à la ligne et l'ouverture de `$(`, `` ` ``, `<(`, `>(` terminent une commande simple ; le contenu d'une substitution est lu comme des commandes, hors guillemets, entre guillemets doubles ou dans un heredoc non cité. `#` en tête de mot ouvre un commentaire. Dans `$((…))`, `<<` est un décalage.
- **Texte cité** : un texte entre `'…'`, `$'…'` ou `"…"` n'est jamais lu comme commande, sauf ses substitutions, sauf quand il est le mot de commande (`env "git" push`, `A=1 'git'`), et sauf les mots cités d'un interprète, relus comme des commandes.
- **Mot de commande** : le premier mot qui n'est ni une affectation, ni une option, ni un compte, ni une enveloppe. Après une option d'enveloppe, le mot suivant est candidat **et** sauté comme argument possible ; le mot simple suivant est candidat aussi. Un `git` cité candidat est un appel git. Une affectation n'est jamais candidate.
- **Interprètes reconnus** : les shells `sh`, `bash`, `zsh`, `dash`, `ksh`, `mksh`, `ash`, `fish`, plus `eval`, `watch` et `su`. Enveloppes : `env`, `command`, `exec`, `builtin`, `time`, `nice`, `nohup`, `timeout`, `stdbuf`, `sudo`, `doas`, `xargs`, `setsid`, `ionice`, et les mots `!`, `{`, `if`, `then`, `else`, `elif`, `do`, `while`, `until`.
- **Lecture des heredocs** : délimiteur cité → corps jamais lu, sauf s'il est lu par un shell, où il est relu tel quel comme commandes. Délimiteur nu → ses substitutions sont lues, puisque le bash extérieur les exécute ; s'il est lu par un shell, le corps est en plus rendu comme bash le rend (`\` suivi d'un retour à la ligne disparaît, `\\`, `\$` et `` \` `` deviennent `\`, `$` et `` ` ``) puis relu comme commandes.
- **Refus du pipe vers un shell** : un shell qui lit ses commandes sur un pipe sans `-c` est refusé (`… | bash`), comme une substitution confiée à un interprète (`bash -c "$(cat f)"`, `bash <(…)`) et des backquotes imbriquées.
- **Échec fermé** : guillemet jamais fermé, heredoc sans délimiteur final, substitution non terminée, heredoc dans un heredoc → refus en le disant.

Les règles git par mode d'ADR-0039 restent : en mode `implementer`, `switch`, `checkout`, `stash`, `push`, `worktree add`, `update-ref` et `branch` avec `-f`, `--force`, `-D`, `-M`, `-C` sont refusés, et `commit`, `reset`, `merge`, `rebase`, `cherry-pick`, `revert`, `am`, `pull` exigent un worktree sur `story/*` ; en mode `qa`, liste blanche d'ADR-0026, `symbolic-ref` sans cible ni option d'écriture, aucun `--output`. Le mode `reviewer` relève d'ADR-0047.

### Consequences
- Good, because `` bash <<EOF `` + `` echo \`git push\` ``, `echo '$(git push)'` dans le même heredoc, `env -u X "git" push` et `sudo -u x "git" push` sont refusés.
- Good, because un corps doublement échappé (`` \\\`git push\\\` ``) passe : bash n'en fait qu'un texte.
- Bad, because la lecture des deux sens refuse quelques formes rares : `env -i grep "git" docs` est lu comme `git docs`, refusé en mode `qa`.
- Bad, because restent des trous acceptés, permis sans être lus :
  - un script écrit puis lancé : `bash f.sh`, `bash < f.sh`, `source f.sh`, `. f.sh`, `source <(…)` ;
  - `$VAR` qui vaut `git`, un alias git ;
  - `GIT_DIR=…` ou `git --git-dir=…` devant `reset` ou `commit`, et `git fetch . HEAD:main` (modes `implementer` et `qa` ; le mode `reviewer` refuse `GIT_DIR=`, ADR-0047) ;
  - ce que produit une substitution ou une variable développée dans un heredoc lu par un shell.
- Neutral: `bash <(…)`, que la story s71 croyait permis, est refusé : c'est une substitution confiée à un interprète. Un `)` de motif `case` dans `"$(…)"` ferme toujours la substitution trop tôt. Le lexer n'est éprouvé que sous gawk ; l'awk de macOS et mawk restent à confirmer par une personne.
