---
adr: 0138
title: git, et lui seul, tourne hors du bac à sable d'un passage réel
status: accepted
date: 2026-11-24
scope: story s209-git-runs-outside-the-sandbox
supersedes: [ADR-0137]
superseded-by: []
---

# ADR-0138 — git, et lui seul, tourne hors du bac à sable d'un passage réel

## Context and Problem Statement
Le troisième passage réel (2026-11-24, #495) a montré que la Law 4 ne peut pas tourner dans le bac à sable d'[ADR-0137](ADR-0137-un-passage-reel-confine-ses-commandes-par-le-bac-a-sable-de-claude-code.md) : `.git/config.lock` y est monté sur `/dev/null` et `.git/worktrees` en lecture seule, donc `git worktree add -b` crée la branche sans worktree. Le chef de projet a tenté hors du bac à sable, a été refusé faute de surface d'approbation (`--permission-prompts none`), et s'est arrêté. Le même passage a été invalidé par l'ignore global de git du `HOME` du passage, qu'ADR-0137 avait rangé parmi ce qui gouverne une session (#494).

## Considered Options
- **A. `sandbox.excludedCommands: ["git"]` et une règle `Bash(git *)`** : git, seul, passe par le chemin normal des permissions, où cette règle l'autorise ; toute autre commande reste dans le bac à sable.
- **B. Ouvrir l'écriture de `.git/` dans le bac à sable** (`sandbox.filesystem.allowWrite`) : le bac à sable protège `.git/config` et ses verrous quelles que soient les écritures permises, donc l'option ne lève pas le blocage vu.
- **C. Une sortie du bac à sable commande par commande** (`dangerouslyDisableSandbox`, `allowUnsandboxedCommands`) : chaque sortie est une demande, refusée sans surface d'approbation ; l'autoriser d'office laisserait sortir n'importe quelle commande.
- **D. Le lanceur ouvre les worktrees avant la session** : la Law 4 confie l'ouverture d'une lane au chef ; un passage ne mesurerait plus ce geste de la méthode.
- **E. Confiner tout le processus de Claude Code autrement** (un `bwrap` maison autour de la session) : une isolation de plus à écrire et à maintenir, sans que Claude Code sache qu'elle existe.
- Sur la ligne de commande de git : **refuser `-c` et `--config-env`** par quatre règles `deny`, plutôt que **laisser le cas à la comparaison d'après session**, qui ne le voit pas puisqu'un `-c` n'écrit rien.

Classées par les critères du porteur (libre ou auto-hébergeable, sobre, extensible, facile à manier pour une IA), A, B et C ne coûtent qu'un réglage ; B et C ne lèvent pas le blocage ou ouvrent toute commande ; D change ce que mesure le passage ; E ajoute du code maison.

## Decision Outcome
Option choisie : **A**, par le porteur le 2026-11-24 (option a), notée dans la story s209-git-runs-outside-the-sandbox. Elle remplace ADR-0137 sur ce seul point : le bac à sable reste actif, approuvé d'office et requis pour toute autre commande, les écritures tenues au dossier du passage, le réseau fermé ; la liste `deny` gagne quatre règles, `Bash(git -c *)`, `Bash(git * -c *)` et `Bash(git --config-env*)`, décidées par le porteur le 2026-11-24 après la revue, puis `Bash(git * --config-env*)`, décidée par le porteur le même jour après la seconde revue (d-0062), et rien d'autre ne la rejoint ; aucune autre commande ne sort du bac à sable sans une nouvelle décision du porteur.

Elle range aussi l'ignore global de git du `HOME` du passage (`.config/git/ignore`) hors de ce qui gouverne une session : il change ce que `git status` montre, pas ce qu'une session peut lancer, et Claude Code y écrit lui-même. Le reste de `.config/git/` reste comparé, puisque git y lit par exemple des attributs qui peuvent nommer un filtre. Un passage invalide garde, dans ses résultats, le fichier gouvernant qui a changé, avant et après, nettoyé comme `po-intake` nettoie une sortie.

Options écartées : B ne lève pas le blocage ; C ouvre toute commande ou n'ouvre rien ; D retire du passage ce qu'il doit mesurer ; E est une isolation maison de plus.

### Consequences
- Good, because le chef de projet et ses agents ouvrent une lane, committent et poussent vers l'origine locale comme la méthode le demande, sans qu'aucune autre commande ne quitte le bac à sable.
- Bad, because git hors du bac à sable écrit partout où la personne écrit et lance tout programme qu'on lui fait lancer. Les quatre règles refusent, sur la ligne de commande de git, un `-c` en mot isolé, en premier (`Bash(git -c *)`) ou après un autre argument (`Bash(git * -c *)`, `git -C <chemin> -c …`), et `--config-env`, suivi de `=` ou d'une espace, en premier (`Bash(git --config-env*)`) ou après un autre argument (`Bash(git * --config-env*)`, `git -C <chemin> --config-env=…`) ; un `-c` collé à sa clé (`-ccore.pager=cat`) ne tombe sous aucune d'elles, mais git le rejette (sortie 129, le relevé du Neutral). Un alias `!`, `core.hooksPath`, `core.sshCommand` ou `core.fsmonitor` donnés là sont refusés. Elles ne ferment pas : les mêmes clés écrites dans un fichier de configuration ou un hook par `git config` ou les outils de fichiers, qui agissent pendant la session et ne se voient qu'à sa fin (configuration et hooks de la racine et de l'origine, `.config/git/` et `.gitconfig` du `HOME` du passage) ; la configuration passée par l'environnement (`GIT_CONFIG_COUNT`/`GIT_CONFIG_KEY_<n>`, `GIT_CONFIG_PARAMETERS`, `GIT_SSH_COMMAND`, `GIT_EXTERNAL_DIFF`) posée devant `git`, que tranche la façon dont Claude Code filtre une affectation en tête de commande et que seul un vrai passage montre. `GIT_ALLOW_PROTOCOL=file` borne les transports de git. La présence de la personne qui regarde le passage reste la borne, comme le dit ADR-0134.
- Bad, because les règles sur `-c` refusent aussi un `-c` légitime (`git log -c`, `git diff -c`, `git commit -c <commit>`, `git grep -c`) et toute commande git dont les arguments contiennent ` -c `, message de commit compris ; celles sur `--config-env` ne refusent aucune commande git légitime, mais refusent aussi un message de commit qui contient ` --config-env` ; une lane refusée ainsi montre `permission_denied` sur `git` dans le flux.
- Bad, because ce que Claude Code écrit dans l'ignore global de git n'est plus relevé : une entrée qui cacherait un fichier à `git status` passerait sans invalider le passage ; la note par scripts lit les commits et les fichiers, pas `git status`.
- Neutral: le filtrage de Claude Code distingue la casse, observé le 2026-11-24 par le chef sur Claude Code avec ces règles et git hors du bac à sable : `git -C <chemin> status` et `git -C <chemin> log` ont tourné ; `git -c …`, `git -C <chemin> -c …` et `git --config-env=…` ont été refusés ; `git -ccore.pager=cat …` a atteint git, qui l'a rejeté (sortie 129). `git -C <chemin> --config-env=…` n'était pas dans ce relevé : à la lecture de la revue, il passait `Bash(git --config-env*)`. Un second relevé du chef, le même jour, avec les quatre règles : `git -C <chemin> --config-env=core.pager=HOME log --oneline -1` et `git --no-pager --config-env=core.pager=HOME log --oneline -1` ont été refusés, `git -C <chemin> log --oneline -1` a tourné. s210 fait écrire `git -C` à la méthode. Ce que les paires gardées d'un passage invalide montreront dira qui écrit l'ignore global.
