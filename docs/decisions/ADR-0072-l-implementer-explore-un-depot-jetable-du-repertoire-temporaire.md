---
adr: 0072
title: L'implementer peut faire git checkout dans un dépôt jetable du répertoire temporaire, et rien n'en sort
status: accepted
date: 2026-10-08
scope: story s98-bounds-messages
supersedes: [ADR-0050, ADR-0052]
superseded-by: []
---

# ADR-0072 — L'implementer explore un dépôt jetable du répertoire temporaire

## Context and Problem Statement
ADR-0050 garde la règle d'ADR-0039 : en mode `implementer`, `po-bounds` refuse `git checkout` partout. Les implementers de s84 et s85 ont cloné une source dans le répertoire temporaire pour la lire, et le hook a refusé le `checkout` d'une version dans ce clone, qui ne touche ni le worktree de la story ni le checkout principal. Le refus protège le worktree de la story ; il n'a pas de raison dans un dépôt jetable. Cette ADR remplace **en partie** ADR-0050 (le refus de `checkout` en mode `implementer`) et ADR-0052 (la règle des chemins et des redirections du dépôt jetable, qui ne visait que le mode `reviewer`). Le reste des deux ADR tient.

## Considered Options
- **Garder le refus partout** et dire aux implementers de lire une version par `git show <rev>:<chemin>` ou `git archive`. Rien à changer dans le hook, mais le geste naturel d'exploration reste refusé, et chaque refus coûte un tour à l'agent.
- **Lever le refus de `checkout` dans le dépôt jetable, sans autre règle.** Le plus court, mais `git -C <clone> show HEAD:f > <worktree>/src/f` ou `git -C <clone> diff --output=<worktree>/x` font sortir un fichier du clone vers le worktree sans que le hook le lise.
- **Lever le refus de `checkout` dans le dépôt jetable, et y appliquer à tout appel git la règle des chemins du mode `reviewer`** : chaque chemin nommé après le verbe et chaque cible de redirection, lue depuis le dossier du shell, doit se résoudre sous le répertoire temporaire. Retenu.
- **Donner à l'implementer la zone entière du reviewer** (tout verbe sauf `push` et `send-pack`). Écarté : plus large que le besoin rapporté ; `commit`, `reset` et les autres gardent leur règle d'ADR-0050, qui exige un worktree `story/*`.
- **Autoriser aussi `git switch`.** Écarté pour l'instant : aucun refus de `switch` n'a été rapporté, et la story ne nomme que `checkout`.

## Decision Outcome
Chosen option: **lever le refus de `checkout` dans le dépôt jetable et y appliquer la règle des chemins**, parce que c'est la plus petite règle qui laisse explorer un clone et qui garde la promesse « rien n'en sort vers le worktree ».

- **Dépôt jetable** : le même que celui du reviewer (ADR-0047, ADR-0051) — un dossier connu sous `${TMPDIR:-/tmp}` physique, hors de tout dépôt ou dans un dépôt dont le dossier git commun et la racine sont eux aussi sous le répertoire temporaire. Un worktree lié d'un vrai dépôt placé dans le répertoire temporaire n'en est pas un. Un dossier inconnu (substitution, `$`, `~` en tête) n'en est pas un.
- **Ordre** : un dossier qui appartient au worktree d'une story est jugé comme tel d'abord ; `git checkout` y reste refusé, comme dans le checkout principal et partout hors du dépôt jetable.
- **Dans le dépôt jetable**, en mode `implementer` : `git checkout` passe ; les verbes de lecture passaient déjà ; `switch`, `stash`, `push`, `worktree add`, `update-ref`, `branch -f/-D/-M/-C` restent refusés, et `commit`, `reset`, `merge`, `rebase`, `cherry-pick`, `revert`, `am`, `pull` exigent toujours un worktree `story/*`. Tout appel git qui y tourne voit ses chemins et ses cibles de redirection tenus sous le répertoire temporaire, avec les exceptions `/dev/null`, `/dev/stdout`, `/dev/stderr`, `/dev/fd/1` et `/dev/fd/2` (ADR-0053).
- **Messages** (tous les modes) : aucun refus n'affiche l'octet de marquage du lexer ; `deny` le remplace par `<substitution>` avant d'écrire.
- **Descripteur nommé** (tous les modes) : `{nom}` collé à `<`, `>`, `>>`, `>|`, `<>`, `<&` ou `>&` est lu comme le descripteur de la redirection, pas comme un mot de la commande, comme le chiffre de `2>`.

### Consequences
- Good, because `git -C <clone> checkout <rev>` passe, et `git -C <clone> show HEAD:f > <worktree>/f` est refusé.
- Bad, because un clone d'un chemin local lancé depuis le dépôt jetable (`cd /tmp && git clone /chemin/du/depot x`) est désormais refusé : le chemin source sort du répertoire temporaire. Le contournement est celui du reviewer, une URL `file://<chemin>`, ou un clone lancé depuis le worktree de la story.
- Bad, because une redirection d'un appel git du worktree de la story, ou d'une commande hors git, n'est toujours pas lue (ADR-0052).
- Neutral: ADR-0050 et ADR-0052 gardent `status: accepted` et nomment cette ADR dans `superseded-by`, leur corps inchangé. `{nom}` devant `<<` ou `<<<` reste un mot, comme `2<<<` avant cette ADR.
