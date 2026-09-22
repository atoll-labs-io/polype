# Installer Polype

`bin/polype` pose la méthode, la rafraîchit, l'ausculte et la retire. Il ne touche jamais aux
réglages d'un projet (`AGENTS.local.md`), ni à ses documents, ni aux fichiers qu'on a ajoutés
soi-même à côté des siens.

Deux poses, deux rôles. La pose **globale** met les commandes, les subagents et les skills dans
`~/.claude/`, donc dans tous les projets à la fois. La pose **projet** met dans le dépôt ce qui lui
appartient : les templates, le gate, `AGENTS.md`, `CLAUDE.md`, `.gitignore`.

```
polype install --global                pose commandes, subagents, skills et charge utile dans ~/.claude
polype update  --global                rafraîchit la pose globale
polype check   --global                version posée et fichiers qui ont dérivé
polype remove  --global                reprend la pose globale
polype init    <projet> [--hooks]      active un projet servi par la pose globale
polype install <projet> [--hooks]      pose tout dans un seul projet, sans rien de global
polype update  <projet> [--hooks]      rafraîchit ce qui n'a pas bougé, signale ce qui a été modifié
polype check   <projet>                version installée et fichiers qui ont dérivé
polype remove  <projet>                reprend ce qui a été posé
polype help                            l'aide ci-dessus
```

Une sous-commande inconnue, une option inconnue, un projet manquant, `--global` et un projet donnés
ensemble, ou aucune cible du tout : sortie 2 avec l'usage sur `stderr`. Une copie de Polype
incomplète — un répertoire source manquant — arrête `install`, `update` et `init` en **1** avant
d'écrire quoi que ce soit, plutôt que de poser zéro fichier en annonçant une réussite.
`bin/polype-dev-install <projet>` reste un alias de `polype install <projet>` pour les scripts
existants.

## Installation globale

`polype install --global` écrit dans `~/.claude`, ou dans `$CLAUDE_CONFIG_DIR` si cette variable est
définie — la convention de Claude Code, donc une configuration déplacée est suivie sans réglage
supplémentaire.

| Source | Destination |
| --- | --- |
| `method/commands/` | `~/.claude/commands/` |
| `method/agents/` | `~/.claude/agents/` |
| `method/skills/` | `~/.claude/skills/` |
| `bin/` | `~/.claude/polype/bin/` |
| `method/` | `~/.claude/polype/method/` |

`~/.claude/polype/` est la **charge utile** : le script et la méthode qu'il livre, côte à côte, si
bien que `~/.claude/polype/bin/polype` retrouve sa méthode par `../method` sans chemin en dur. C'est
cette copie-là qu'on lance au quotidien, indépendamment du dépôt cloné — elle n'est pas sur le
`PATH`, à quoi un lien symbolique répond :

```
ln -s ~/.claude/polype/bin/polype ~/.local/bin/polype
```

L'installeur suit les liens symboliques pour retrouver sa méthode : lancé par `~/.local/bin/polype`,
il travaille avec la charge utile qui se trouve à côté du script pointé, jamais à côté du lien.

La pose globale n'écrit ni `AGENTS.md`, ni `CLAUDE.md`, ni `.gitignore`, et ne touche pas à
`core.hooksPath` : ces quatre-là appartiennent à un projet. Elle ne retire jamais un fichier qu'elle
n'a pas posé — une commande personnelle dans `~/.claude/commands/` survit à `remove --global` — et
elle ne supprime pas `~/.claude` lui-même.

## Activer un projet

Une fois le global posé, `polype init <projet>` dépose dans le dépôt ce qui doit y vivre, et rien de
plus :

| Source | Destination |
| --- | --- |
| `method/templates/` | `.polype/templates/` |
| `method/hooks/` | `.polype/hooks/` (rendus exécutables) |

plus `AGENTS.md`, la ligne `@AGENTS.md` de `CLAUDE.md` et les deux lignes de `.gitignore` décrites
plus bas. Aucune copie des commandes, des subagents ni des skills : ils sont déjà globaux. Si
`~/.claude/polype/version` manque, `init` le dit sur `stderr` et pose quand même le volet projet.

`polype install <projet>` reste la pose complète dans un seul dépôt, sans rien de global : elle
ajoute au tableau ci-dessus `.claude/commands/`, `.claude/agents/` et `.claude/skills/`. C'est la
bonne forme pour un dépôt partagé dont on ne contrôle pas le `~/.claude` des autres.

## Suivre `~/.claude/polype/` avec chezmoi

La pose globale est faite pour être synchronisée entre machines (ADR-0004).

**Ce qui se suit** : `~/.claude/polype/bin/` et `~/.claude/polype/method/`, versionnés avec la
méthode, plus les commandes, subagents et skills posés dans `~/.claude/`. C'est exactement ce qui
doit être identique partout.

**Ce qui ne se suit pas** :
- `~/.claude/polype/manifest`, `~/.claude/polype/checksums` et `~/.claude/polype/version` : ces
  trois fichiers décrivent l'état d'**une** machine. Synchronisés, une machine hériterait du
  manifeste d'une autre et `remove` y supprimerait des chemins qu'elle n'a jamais posés. À exclure
  explicitement des dotfiles.
- l'`AGENTS.local.md` d'un projet et l'état de ce projet (`.polype/`, `AGENTS.md`, `docs/`) : ils
  vivent dans le dépôt du projet, en git, pas dans les dotfiles.
- tout secret : jeton, `.env`, clé. Les dotfiles partent sur un remote.

**Mettre à jour une autre machine** : synchroniser les dotfiles, puis lancer la charge utile fraîche
sur elle-même — `~/.claude/polype/bin/polype install --global` — pour réécrire le manifeste et les
empreintes locales ; la charge utile se repose sur elle-même sans se détruire. `polype check
--global` dit ensuite ce qui a dérivé, charge utile comprise. Chaque projet suit avec `polype init
<projet>`.

## Ce qui est posé dans un projet

| Source | Destination | `init` | `install <projet>` |
| --- | --- | --- | --- |
| `method/commands/` | `.claude/commands/` | non | oui |
| `method/agents/` | `.claude/agents/` | non | oui |
| `method/skills/` | `.claude/skills/` | non | oui |
| `method/templates/` | `.polype/templates/` | oui | oui |
| `method/hooks/` | `.polype/hooks/` (rendus exécutables) | oui | oui |

En plus des copies, `init` comme `install <projet>` :
- réécrit `AGENTS.md` = les règles de la méthode, puis `---`, puis l'`AGENTS.local.md` du projet ;
  un `AGENTS.md` écrit à la main est d'abord sauvegardé en `AGENTS.md.before-polype` ;
- ajoute la ligne `@AGENTS.md` à `CLAUDE.md`, une seule fois ;
- ajoute au `.gitignore` la racine des worktrees (`Worktree root` lu dans `AGENTS.local.md`,
  `.worktrees/` par défaut) et `.env*`, une seule fois chacun ;
- avec `--hooks`, pointe `core.hooksPath` sur `.polype/hooks` — et seulement si ce réglage est vide
  ou déjà le nôtre : un `core.hooksPath` existant est laissé tel quel, à charger de chaîner
  `.polype/hooks/pre-commit` depuis là.

Ces fichiers se commitent sur la branche cible pour que les worktrees de story en héritent.

## Les trois fichiers d'état

Ils vivent dans `.polype/` pour un projet, dans `~/.claude/polype/` pour la pose globale.

| Fichier | Contenu |
| --- | --- |
| `manifest` | un chemin par ligne : tout ce que la dernière pose a écrit |
| `checksums` | le `cksum` de chaque fichier au moment où il a été posé |
| `version` | la version installée |

Aucun des trois n'est listé dans le manifeste : ils ne s'effacent donc jamais eux-mêmes au passage
suivant. Le manifeste est ce qui permet de supprimer les fichiers d'une version précédente sans
toucher à ceux du projet ; les empreintes sont ce qui permet de distinguer un fichier intact d'un
fichier modifié à la main.

## `install` ou `update`

`install` écrase : il repose la totalité de la méthode par-dessus ce qui est là, supprime les
fichiers que le manifeste listait et que cette version ne livre plus, et réécrit les trois fichiers
d'état. C'est la première pose, et le moyen de revenir à une méthode propre. Rien n'est supprimé
avant que la liste des fichiers à poser n'ait été lue, et chaque fichier est écrit à côté puis
renommé sur sa destination : en `--global`, la charge utile que l'installeur lit vit sous
`~/.claude/polype/`, donc à l'intérieur même de ce qu'il repose.

`update` ménage le travail local : il supprime les fichiers d'une version précédente qui ne sont
plus livrés, recopie ceux dont l'empreinte correspond encore à ce qui avait été posé, **laisse en
place** ceux qui ont été modifiés à la main et les nomme sur `stderr`. Un fichier laissé en place
garde l'empreinte de la version posée, donc `check` continue de le signaler tant qu'il diffère. Sur
un projet où Polype n'a jamais été installé, `update` se comporte comme `install`.

## Lire un rapport `check`

`check` affiche la version installée, et dit si cet installeur en livre une autre. Il liste ensuite
`modified: <chemin>` pour chaque fichier posé dont le contenu a changé depuis, et `missing:
<chemin>` pour chaque fichier posé qui a disparu. Il sort **1** dès que l'une des deux listes n'est
pas vide, ou si le fichier `version` manque ; **0** quand tout est intact — il dit alors combien de
fichiers sont installés et ne nomme rien. Sans `manifest`, il sort 1 : rien n'est installé. En
`--global`, les chemins sont relatifs à `~/.claude`, charge utile (`polype/bin/`, `polype/method/`)
comprise.

## Ce que `remove` garde

`remove --global` supprime les fichiers du manifeste puis `~/.claude/polype/` en entier, et élague
les répertoires devenus vides **sous** `~/.claude/commands/`, `~/.claude/agents/` et
`~/.claude/skills/` — jamais ces trois-là, jamais `~/.claude`, jamais un répertoire que Polype n'a
pas créé.

`remove <projet>` supprime les fichiers du manifeste, les trois fichiers d'état, puis les répertoires
`.claude/` et `.polype/` devenus vides. Il retire la ligne `@AGENTS.md` de `CLAUDE.md`, supprime
`AGENTS.md` seulement s'il porte le marqueur d'assemblage, et remet `AGENTS.md.before-polype` à sa
place s'il existe. Il ne rend `core.hooksPath` à git que si ce réglage vaut `.polype/hooks`.

Restent intacts : `AGENTS.local.md`, `docs/`, le `.gitignore` (les deux lignes ajoutées y restent —
un worktree encore en place ne doit pas se retrouver suivi), et tout fichier que le projet a ajouté
sous `.claude/`, y compris ses propres commandes.
