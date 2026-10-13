# Installer Polype

`bin/polype` pose la méthode, la rafraîchit, l'ausculte et la retire. Il ne touche jamais aux
réglages d'un projet (`AGENTS.local.md`), ni à ses documents, ni aux fichiers qu'on a ajoutés
soi-même à côté des siens.

Deux poses, deux rôles. La pose **globale** met les commandes, les subagents et les skills dans
`~/.claude/`, donc dans tous les projets à la fois. La pose **projet** met dans le dépôt ce qui lui
appartient : les templates, le gate, `AGENTS.md`, `.gitignore`. Le projet ne garde ni
`CLAUDE.md` ni `CLAUDE.local.md` : Claude Code ne lit `AGENTS.md` que tant qu'aucun de ces deux fichiers
n'existe, et l'installeur absorbe ceux qu'il trouve (ADR-0086).

```
polype install --global                pose commandes, subagents, skills et charge utile dans ~/.claude
polype update  --global                rafraîchit la pose globale
polype check   --global                version posée et fichiers qui ont dérivé
polype remove  --global                reprend la pose globale
polype init    <projet> [--hooks]      active un projet servi par la pose globale
polype install <projet> [--hooks]      pose tout dans un seul projet, sans rien de global
polype update  <projet> [--hooks]      rafraîchit ce qui n'a pas bougé, signale ce qui a été modifié
polype check   <projet>                version, fichiers qui ont dérivé, réglages manquants
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

La pose globale n'écrit ni `AGENTS.md`, ni `.gitignore`, et ne touche pas à `core.hooksPath` : ces
trois-là appartiennent à un projet. Elle ne retire jamais un fichier qu'elle
n'a pas posé — une commande personnelle dans `~/.claude/commands/` survit à `remove --global` — et
elle ne supprime pas `~/.claude` lui-même.

## Activer un projet

Une fois le global posé, `polype init <projet>` dépose dans le dépôt ce qui doit y vivre, et rien de
plus :

| Source | Destination |
| --- | --- |
| `method/templates/` | `.polype/templates/` |
| `method/hooks/` | `.polype/hooks/` (rendus exécutables) |

plus `AGENTS.md` et les deux lignes de `.gitignore` décrites
plus bas. Aucune copie des commandes, des subagents ni des skills : ils sont déjà globaux. Si
`~/.claude/polype/version` manque, `init` le dit sur `stderr` et pose quand même le volet projet.

`polype install <projet>` reste la pose complète dans un seul dépôt, sans rien de global : elle
ajoute au tableau ci-dessus `.claude/commands/`, `.claude/agents/` et `.claude/skills/`. C'est la
bonne forme pour un dépôt partagé dont on ne contrôle pas le `~/.claude` des autres.

Ouvrir une session suffit : le chef de projet reprend le projet. Le hook `SessionStart` que la pose
ajoute à `.claude/settings.json` lui donne l'état lu sur le disque et dans git — étape du cadrage,
stories prêtes, voies en vol, ce qui attend un humain — sans commande à taper.

### Le hook des bornes de l'implementer

Le frontmatter du subagent `implementer` déclare un hook PreToolUse sur `Edit`, `Write` et `Bash`
qui appelle `.polype/hooks/po-bounds.sh implementer`. Le script refuse une écriture hors de
`docs/` et hors de l'`Owns` committé de la story dont le worktree `story/<id>` contient le chemin.
Côté git, il refuse :
- partout : `git switch`, `stash`, `push` et `worktree add` ;
- hors d'un dépôt jetable sous `${TMPDIR:-/tmp}` (même définition que pour le reviewer) :
  `git checkout`. Dans ce dépôt jetable, chaque chemin nommé et chaque cible de redirection d'un
  appel git doivent rester sous le répertoire temporaire, et un clone local lancé de là passe par
  `file://` (ADR-0072) ;
- partout aussi, depuis s62 : `git update-ref`, et `git branch` avec `-f`, `--force`, `-D`, `-M` ou
  `-C`, seuls ou groupés (`-fD`) ;
- hors d'un worktree sur une branche `story/*` : `commit`, `reset`, `merge`, `rebase`,
  `cherry-pick`, `revert`, `am` et `pull`.

Ce qu'il ne voit pas (ADR-0050) : un texte entre guillemets, ou le corps d'un heredoc à délimiteur
cité, n'est pas lu comme une commande — c'est voulu, une citation n'est pas un ordre, sauf si un
shell lit ce corps. Il ne lit pas non plus une variable `$VAR` qui contient `git`, ni un alias git.
Pour `implementer` et `qa`, il ne refuse pas `GIT_DIR=… git reset`, `git --git-dir=… reset` ou
`git fetch . HEAD:main`. Il ne voit pas davantage les redirections du
shell hors du dépôt jetable, ni un `cp`. Pour tout cela, la revue garde son propre contrôle d'ownership.

Le script a besoin de `jq` ; sans lui, il refuse tout.

Après une mise à jour par `polype install --global`, relance `polype init <projet>` dans chaque
projet et committe le nouveau `.polype/hooks/po-bounds.sh` sur la branche cible : le subagent global
appelle déjà le script, et tant qu'il manque au projet,
le hook fermé refuse toute écriture de l'implementer.

Limite de confiance : avec `polype install <projet>`, les subagents vivent dans `.claude/agents/`,
et Claude Code n'exécute les hooks de leur frontmatter qu'une fois accepté le dialogue de confiance
du dossier — jamais dans une session `claude -p`, où les bornes ne sont **pas** tenues. Avec
l'installation globale, les subagents de `~/.claude/agents/` exécutent leurs hooks sans cette
condition.

### Le mode reviewer

Le frontmatter du subagent `reviewer` appelle `.polype/hooks/po-bounds.sh reviewer` sur `Edit`,
`Write` et `Bash` (ADR-0047, précisée par ADR-0051 et ADR-0052).
Le hook est un garde-fou contre les erreurs d'un agent de bonne foi, pas une barrière contre un
contournement délibéré : ADR-0052 liste les contournements connus, acceptés tels quels, et un
nouveau s'y ajoute par une ADR.

Le reviewer travaille dans deux zones. Dans le worktree de la story, il écrit hors de `.git` et n'a
de git que les verbes de lecture, plus `git checkout -- <chemin>` et `git restore`. Dans un dépôt
jetable sous `${TMPDIR:-/tmp}`, il écrit librement et lance tout verbe sauf `push` et `send-pack`,
à condition que chaque chemin nommé après le verbe (un mot, `--opt=valeur`, `-o<valeur>`)
se résolve sous le répertoire temporaire. Pour lire un dépôt hors de cette zone, il passe par une URL
`file://<chemin>`.

Une redirection n'est pas un chemin de git : `2>/dev/null` et `2>&1` passent. Dans le dépôt jetable,
la cible d'une redirection vers un fichier, lue depuis le dossier du shell, doit elle aussi rester
sous le répertoire temporaire.

Partout, le hook refuse `push`, `send-pack`, `--git-dir`, `--work-tree`, `GIT_DIR=`,
`GIT_WORK_TREE=`, `GIT_CONFIG_PARAMETERS=` et `GIT_CONFIG_COUNT=`, ainsi qu'un `core.worktree`
posé par `-c` ou `--config-env`, quelle que soit sa casse. Il refuse aussi une commande git hors des
deux zones, le checkout principal compris, ou lancée dans un dossier qu'il ne sait pas lire.

Un projet dont le `.polype/hooks/po-bounds.sh` date d'avant s70 refuse chaque appel du reviewer
(« mode inconnu ») et bloque donc toute revue : relance `polype init <projet>`, puis committe le
script sur la branche cible.

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
- absorbe, avant d'assembler `AGENTS.md`, le `CLAUDE.md` et le `CLAUDE.local.md` de la racine du
  projet (ADR-0086) : leur contenu, sans la ligne `@AGENTS.md`, va à la fin d'`AGENTS.local.md` sous
  le titre `## Notes moved from CLAUDE.md`, puis le fichier est supprimé et l'installeur le dit sur
  `stderr`. Un `CLAUDE.local.md`, même privé et ignoré par git, est déplacé lui aussi dans
  `AGENTS.local.md`, qui est commité, puis dans `AGENTS.md` : c'est la décision du propriétaire
  consignée dans `docs/decisions-log.md`. Un fichier qui ne contenait que l'import est supprimé sans
  rien ajouter. Sans `AGENTS.local.md`, un fichier qui contient autre chose est laissé tel quel,
  l'installeur le dit et la pose continue : lancer `/po-setup`, puis `polype update .`. Le `CLAUDE.md` global de
  l'utilisateur (`~/.claude/CLAUDE.md`) n'est jamais touché ; tant qu'un `CLAUDE.md` existe dans le
  projet, Claude Code le lit **à la place** d'`AGENTS.md` ;
- ajoute au `.gitignore` la racine des worktrees (`Worktree root` lu dans `AGENTS.local.md`,
  `.worktrees/` par défaut) et `.env*`, une seule fois chacun ;
- avec `--hooks`, pointe `core.hooksPath` sur `.polype/hooks` — et seulement si ce réglage est vide
  ou déjà le nôtre : un `core.hooksPath` existant est laissé tel quel, à charger de chaîner
  `.polype/hooks/pre-commit` depuis là ; ce pre-commit refuse aussi, sur toute branche, un
  `CLAUDE.md` ou un `CLAUDE.local.md` ajouté ou modifié à n'importe quelle profondeur (sa
  suppression passe) ;
- fusionne avec `jq` le hook `SessionStart` (`.polype/hooks/po-session.sh`) dans le
  `.claude/settings.json` du projet, créé s'il manque : les autres clés et les autres hooks restent
  tels quels, et une pose répétée ne le duplique pas. Le fichier n'entre pas dans le manifeste. Sans
  `jq`, la pose continue, saute ce seul hook et le dit sur `stderr` ; un `settings.json` qui n'est
  pas un objet JSON valide n'est pas touché.

Ces fichiers, `.claude/settings.json` compris, se commitent sur la branche cible pour que les worktrees de story en héritent.

## Les fichiers d'état

Trois fichiers d'état vivent dans `.polype/` pour un projet, dans `~/.claude/polype/` pour la pose
globale ; un projet en a un quatrième, `.claude/.polype-checksums`, décrit plus bas.

| Fichier | Contenu |
| --- | --- |
| `manifest` | un chemin par ligne : tout ce que la dernière pose a écrit |
| `checksums` | le `cksum` de chaque fichier au moment où il a été posé |
| `version` | la version installée |

Aucun de ces fichiers n'est listé dans le manifeste : ils ne s'effacent donc jamais eux-mêmes au passage
suivant. Le manifeste est ce qui permet de supprimer les fichiers d'une version précédente sans
toucher à ceux du projet ; les empreintes sont ce qui permet de distinguer un fichier intact d'un
fichier modifié à la main.

Ce quatrième fichier existe parce que, dans un projet, les empreintes des copies de `.claude/` ne
sont pas dans `.polype/checksums` mais à côté d'elles, dans `.claude/.polype-checksums` (ADR-0087) : le `cksum` de chaque copie de `.claude/`
au moment où ce checkout l'a posée. Ce fichier appartient à un seul checkout et reste
ignoré par git : quand git ne l'ignore pas déjà, l'installeur ajoute la ligne
`.claude/.polype-checksums` au `.gitignore`. Il n'entre jamais dans le manifeste, et `check` lit les deux fichiers d'empreintes.
`.polype/checksums` ne garde que les fichiers de `.polype/`. `init` ne pose aucune copie sous
`.claude/`, donc n'écrit pas ce fichier. Une actualisation de `.polype/` arrivée par une pull
request ne fait donc plus passer les copies d'un autre checkout pour modifiées à la main.

## `install` ou `update`

`install` écrase : il repose la totalité de la méthode par-dessus ce qui est là, supprime les
fichiers que le manifeste listait et que cette version ne livre plus, et réécrit les fichiers
d'état. C'est la première pose, et le moyen de revenir à une méthode propre. Rien n'est supprimé
avant que la liste des fichiers à poser n'ait été lue, et chaque fichier est écrit à côté puis
renommé sur sa destination : en `--global`, la charge utile que l'installeur lit vit sous
`~/.claude/polype/`, donc à l'intérieur même de ce qu'il repose.

`update` ménage le travail local : il supprime les fichiers d'une version précédente qui ne sont
plus livrés, recopie ceux dont l'empreinte correspond encore à ce qui avait été posé, **laisse en
place** ceux qui ont été modifiés à la main et les nomme sur `stderr`. Un fichier laissé en place
garde l'empreinte de la version posée, donc `check` continue de le signaler tant qu'il diffère. Sur
un projet où Polype n'a jamais été installé, `update` se comporte comme `install`.

Une copie identique au fichier livré n'est jamais une modification à la main : `update` la recopie et
enregistre son empreinte. Une pull request qui a actualisé `.polype/`, ou des copies de `.claude/`
commitées, ne laisse donc rien de bloqué. Le premier `update` après cette version migre : sans
`.claude/.polype-checksums`, il juge les copies sur les lignes `.claude/` de l'ancien
`.polype/checksums`, écrit le fichier local, retire ces lignes de `.polype/checksums` et le dit sur
`stderr`. Un checkout déjà bloqué avant la migration, dont les copies sont plus anciennes que les
empreintes commitées, se répare avec `polype install <projet>`.

## Après une mise à jour

Le gabarit des réglages gagne des lignes au fil des versions ; l'`AGENTS.local.md` d'un projet, lui,
ne bouge pas. `install`, `init` et `update` sur un projet nomment donc, sur `stderr`, chaque réglage
du gabarit que l'`AGENTS.local.md` du projet ne déclare pas, avec la valeur du gabarit, une ligne par
réglage :

```
missing setting: <Nom>: <valeur>
```

L'installeur n'écrit jamais ce fichier (ADR-0043) : c'est au projet de choisir ses valeurs. Un projet
servi par la pose globale voit cette liste quand `polype init <projet>` tourne après
`polype install --global`. `polype check <projet>` la redonne à la demande.

Pour chaque ligne : lis le tableau des valeurs de `.polype/templates/agents-local.md`, garde la
valeur proposée ou choisis-en une autre, puis ajoute chaque ligne à `AGENTS.local.md`, dans le bloc
où le gabarit la range. Ensuite relance `polype init <projet>` ou `polype update <projet>` pour que
`AGENTS.md` porte les nouvelles lignes, et committe `AGENTS.local.md` et `AGENTS.md` sur la branche
cible. D'ici là, une commande qui lit un réglage absent s'arrête en le nommant ; les réglages de
modèle de s59 (`Model strong`, `Model light`, `Light up to`) arrêtent ainsi toutes les commandes qui
délèguent à un subagent.

## Lire un rapport `check`

`check` affiche la version installée, et dit si cet installeur en livre une autre. Il liste ensuite
`modified: <chemin>` pour chaque fichier posé dont le contenu a changé depuis, et `missing:
<chemin>` pour chaque fichier posé qui a disparu. Il sort **1** dès que l'une des deux listes n'est
pas vide, ou si le fichier `version` manque ; **0** quand tout est intact — il dit alors combien de
fichiers sont installés et ne nomme rien. Sans `manifest`, il sort 1 : rien n'est installé. En
`--global`, les chemins sont relatifs à `~/.claude`, charge utile (`polype/bin/`, `polype/method/`)
comprise. Sur un projet, `check` liste enfin les mêmes lignes `missing setting:` que la mise à jour ;
elles ne changent pas son code de sortie.

`check` compare chaque copie aux empreintes enregistrées et rien d'autre : il n'applique pas la
règle « identique au fichier livré » de `update`. Dans un projet qui commite `.claude/`, les copies
actualisées par une pull request tirée sur ce checkout restent donc listées `modified:` tant que
`update` n'a pas tourné ; c'est `update` qui les reconnaît intactes et réécrit
`.claude/.polype-checksums`.

## Ce que `remove` garde

`remove --global` supprime les fichiers du manifeste puis `~/.claude/polype/` en entier, et élague
les répertoires devenus vides **sous** `~/.claude/commands/`, `~/.claude/agents/` et
`~/.claude/skills/` — jamais ces trois-là, jamais `~/.claude`, jamais un répertoire que Polype n'a
pas créé.

`remove <projet>` supprime les fichiers du manifeste, les fichiers d'état (`.claude/.polype-checksums` compris), puis les répertoires
`.claude/` et `.polype/` devenus vides. Il se contente de retirer l'ancienne ligne `@AGENTS.md` de `CLAUDE.md`, sans rien déplacer dans `AGENTS.local.md`, supprime
`AGENTS.md` seulement s'il porte le marqueur d'assemblage, et remet `AGENTS.md.before-polype` à sa
place s'il existe. Il ne rend `core.hooksPath` à git que si ce réglage vaut `.polype/hooks`.

`remove <projet>` retire aussi le hook `SessionStart` de `.claude/settings.json` (avec `jq` ; sans
lui, il le dit et laisse le fichier). Si plus rien d'autre n'y reste, le fichier est supprimé, puis
`.claude/` s'il est vide — y compris quand le fichier ne contenait que `{}` avant la pose : `remove`
ne sait pas distinguer ce cas d'un fichier vidé par lui.

Restent intacts : `AGENTS.local.md`, `docs/`, le `.gitignore` (les deux lignes ajoutées y restent —
un worktree encore en place ne doit pas se retrouver suivi), et tout fichier que le projet a ajouté
sous `.claude/`, y compris ses propres commandes.
