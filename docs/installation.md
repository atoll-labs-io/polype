# Installer Polype dans un projet

`bin/polype` pose la méthode dans un projet, la rafraîchit, l'ausculte et la retire. Il ne touche
jamais aux réglages du projet (`AGENTS.local.md`), ni à ses documents, ni aux fichiers qu'il a
ajoutés lui-même sous `.claude/`.

```
polype install <projet> [--hooks]    pose tout, en écrasant ce qui est là
polype update  <projet> [--hooks]    rafraîchit ce qui n'a pas bougé, signale ce qui a été modifié
polype check   <projet>              version installée et fichiers qui ont dérivé
polype remove  <projet>              reprend ce qui a été posé
polype help                          l'aide ci-dessus
```

Une sous-commande inconnue, une option inconnue ou un projet manquant sortent en 2 avec l'usage sur
`stderr`. `bin/polype-dev-install <projet>` reste un alias de `polype install` pour les scripts
existants. L'installation globale dans `~/.claude` n'existe pas encore : ces commandes travaillent
projet par projet.

## Ce qui est posé

| Source | Destination |
| --- | --- |
| `method/commands/` | `.claude/commands/` |
| `method/agents/` | `.claude/agents/` |
| `method/skills/` | `.claude/skills/` |
| `method/templates/` | `.polype/templates/` |
| `method/hooks/` | `.polype/hooks/` (rendus exécutables) |

En plus des copies, l'installeur :
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

| Fichier | Contenu |
| --- | --- |
| `.polype/manifest` | un chemin par ligne : tout ce que la dernière pose a écrit |
| `.polype/checksums` | le `cksum` de chaque fichier au moment où il a été posé |
| `.polype/version` | la version installée |

Aucun des trois n'est listé dans le manifeste : ils ne s'effacent donc jamais eux-mêmes au passage
suivant. Le manifeste est ce qui permet de supprimer les fichiers d'une version précédente sans
toucher à ceux du projet ; les empreintes sont ce qui permet de distinguer un fichier intact d'un
fichier modifié à la main.

## `install` ou `update`

`install` écrase : il supprime tout ce que le manifeste listait, repose la totalité de la méthode et
réécrit les trois fichiers d'état. C'est la première pose, et le moyen de revenir à une méthode
propre.

`update` ménage le travail local : il supprime les fichiers d'une version précédente qui ne sont
plus livrés, recopie ceux dont l'empreinte correspond encore à ce qui avait été posé, **laisse en
place** ceux qui ont été modifiés à la main et les nomme sur `stderr`. Un fichier laissé en place
garde l'empreinte de la version posée, donc `check` continue de le signaler tant qu'il diffère. Sur
un projet où Polype n'a jamais été installé, `update` se comporte comme `install`.

## Lire un rapport `check`

`check` affiche la version installée, et dit si cet installeur en livre une autre. Il liste ensuite
`modified: <chemin>` pour chaque fichier posé dont le contenu a changé depuis, et `missing:
<chemin>` pour chaque fichier posé qui a disparu. Il sort **1** dès que l'une des deux listes n'est
pas vide, ou si `.polype/version` manque ; **0** quand tout est intact — il dit alors combien de
fichiers sont installés et ne nomme rien. Sans `.polype/manifest`, il sort 1 : rien n'est installé.

## Ce que `remove` garde

`remove` supprime les fichiers du manifeste, les trois fichiers d'état, puis les répertoires
`.claude/` et `.polype/` devenus vides. Il retire la ligne `@AGENTS.md` de `CLAUDE.md`, supprime
`AGENTS.md` seulement s'il porte le marqueur d'assemblage, et remet `AGENTS.md.before-polype` à sa
place s'il existe. Il ne rend `core.hooksPath` à git que si ce réglage vaut `.polype/hooks`.

Restent intacts : `AGENTS.local.md`, `docs/`, le `.gitignore` (les deux lignes ajoutées y restent —
un worktree encore en place ne doit pas se retrouver suivi), et tout fichier que le projet a ajouté
sous `.claude/`, y compris ses propres commandes.
