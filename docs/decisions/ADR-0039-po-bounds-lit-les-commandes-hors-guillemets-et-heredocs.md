---
adr: 0039
title: po-bounds lit une commande Bash avec un lexer awk qui écarte les textes cités et les corps de heredoc
status: superseded
date: 2026-10-08
scope: story s62-bounds-scan
supersedes: [ADR-0024]
superseded-by: [ADR-0050]
---

# ADR-0039 — po-bounds lit une commande Bash avec un lexer awk qui écarte les textes cités et les corps de heredoc

## Context and Problem Statement
ADR-0024 a choisi une analyse Bash « en mots, guillemets retirés » : tout `git <verbe interdit>` présent dans le texte est refusé, même cité dans un `grep`, un `printf` ou le corps d'un heredoc. Les implementers de s49, s52 et s56 ont été bloqués en écrivant de la documentation. Ce point d'ADR-0024 est remplacé ici (remplacement partiel, comme ADR-0038 : la story tirée du worktree visé et `jq` restent). Deux trous voisins se ferment au passage : en mode `qa`, la liste blanche d'ADR-0026 laisse passer `symbolic-ref` qui écrit et `--output` (revue de s51, M1) ; en mode `implementer`, `git branch -f main`, `git update-ref` et `git reset` dans le worktree principal déplacent la branche de départ dont ADR-0038 tire la base des `Owns` (revue de s61, mineur).

## Considered Options
- **Garder l'analyse en mots** — échoue fermé, mais chaque document qui cite une commande git coûte un détour.
- **Lexer caractère par caractère en bash** — reste dans le script, mais `${s:i:1}` sur un corps de heredoc de plusieurs kilo-octets devient quadratique, sur un hook qui tourne à chaque appel Bash.
- **Faire parler le parseur de bash** (`bash -n`, `declare -f` d'une fonction enveloppe) — `-n` ne rend aucun arbre ; `declare -f` rend du texte qu'il faut relexer, et définir la fonction passe par `eval`.
- **`python3 -c 'import shlex'`** — écarté par ADR-0024 (absent par défaut sur macOS) ; `shlex` ne connaît ni heredoc ni `$(…)`.
- **Lexer awk portable (POSIX, sans extension gawk)** — un programme awk découpe la commande en commandes simples, un mot par champ, chaque mot marqué « cité » ou non ; le bash du script applique ensuite les règles git sur ces commandes simples.

## Decision Outcome
Chosen option: **lexer awk portable**, parce qu'il lit en une passe linéaire ce que bash exécute vraiment, et qu'il échoue fermé là où il ne sait pas lire. Ses règles :
- Les séparateurs `;`, `&`, `&&`, `|`, `||`, `(`, `)`, le retour à la ligne et l'ouverture d'une substitution `$(`, `` ` ``, `<(`, `>(` terminent une commande simple ; le contenu d'une substitution est lu comme des commandes, qu'elle soit hors guillemets, entre guillemets doubles ou dans un heredoc non cité.
- Un texte entre `'…'`, `$'…'` ou `"…"` reste un seul mot, jamais relu comme commande, sauf ses substitutions et sauf quand la commande simple contient un mot hors guillemets `sh`, `bash`, `zsh`, `dash`, `ksh` ou `eval` (nom de base) : ses mots cités sont alors relus comme des commandes.
- Le corps d'un heredoc `<<` / `<<-` est sauté jusqu'à son délimiteur ; délimiteur cité → rien n'y est lu ; délimiteur nu → seules ses substitutions sont lues, puisque bash les exécute. Dans `$((…))`, `<<` est un décalage, pas un heredoc.
- `#` en tête de mot hors guillemets ouvre un commentaire jusqu'à la fin de la ligne.
- Un guillemet jamais fermé, ou un heredoc dont le délimiteur ne vient jamais, refuse la commande en le disant : bash ne l'exécuterait pas telle quelle, et le lexer ne sait plus ce qui est texte.
- Un mot `git` (ou `…/git`) est un appel git hors guillemets à n'importe quelle place de la commande simple (ce qui garde `env git`, `xargs git`, `timeout 5 git`), et cité seulement en première place ; les arguments de cet appel s'arrêtent à la fin de la commande simple.

Avec lui, en mode `implementer` : `git update-ref` est refusé ; `git branch` avec `-f`, `--force`, `-D`, `-M` ou `-C` (seuls ou groupés) est refusé ; `commit`, `reset`, `merge`, `rebase`, `cherry-pick`, `revert`, `am` et `pull` exigent, comme `commit` aujourd'hui, de tourner dans un worktree sur `story/*`. En mode `qa` : `symbolic-ref` n'accepte que `-q`, `--quiet`, `--short`, `--no-recurse`, `--recurse` et un seul argument ; toute option `--output` ou `--output=…` est refusée, quel que soit le verbe.

### Consequences
- Good, because `grep -rn "git checkout" docs`, `printf '…git commit…'` et un `cat > f <<'EOF'` qui cite `git push` passent, et `git commit -m "fix; git push"` n'est plus lu comme un push.
- Good, because la base des `Owns` lue au point de départ (ADR-0038) ne peut plus être déplacée par les verbes qui bougent une branche, hors worktree de story.
- Bad, because un lexer qui n'est pas bash peut s'en écarter : un `)` de motif `case` à l'intérieur de `"$(…)"` ferme la substitution trop tôt et ce qui suit dans les guillemets est lu comme du texte. Le modèle reste l'erreur, pas l'hostilité (ADR-0038).
- Bad, because restent permis sans être lus : `$VAR` qui vaut `git`, un alias git, `GIT_DIR=… git reset`, `git --git-dir=… reset`, `git fetch . HEAD:main`. Un `echo git push` sans guillemets reste refusé.
- Bad, because un `cat <<EOF` (délimiteur nu) qui contient des backticks Markdown est refusé quand ils entourent une commande git : bash les exécuterait. Le refus invite à citer le délimiteur.
- Neutral: le script n'est éprouvé que sous gawk ici ; il s'interdit les extensions gawk pour tourner sous l'awk de macOS et mawk, ce qu'une personne doit confirmer.
