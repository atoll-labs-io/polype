# Migrer de `/spec` et `/drive` vers Polype

`/spec` et `/drive` sont les deux skills globaux que Polype remplace (`docs/conception.md`). Ils
savaient interroger une idée, la découper en packets et lancer une flotte dessus ; Polype reprend ce
travail sous une autre forme, avec des gates en fichiers et un état qui se dérive au lieu de
s'écrire.

Ce document répond à trois questions, dans cet ordre : à quoi correspond chaque notion de l'ancien
régime, quels fichiers retirer et quand, et comment reprendre un projet qui a déjà des packets en
vol.

**Convention de lecture.** Un chemin nu — `docs/…`, `method/…`, `bin/…` — désigne un fichier de ce
dépôt-ci, celui de Polype. `<projet>/…` désigne un fichier du dépôt qu'on migre. `~/.claude/…`
désigne un fichier de la machine, hors de tout dépôt.

**L'ordre sûr** : poser Polype, reprendre les projets en vol, retirer `/spec` et `/drive` en
dernier. Les deux poses cohabitent sans collision de noms, alors rien n'oblige à casser l'ancien
avant que le nouveau tourne.

## 1. Correspondance

Une ligne par notion. La troisième colonne dit ce qui **disparaît** : ce qu'on ne cherchera pas à
retrouver dans Polype, parce qu'une décision l'a retiré.

| Notion de `/spec` et `/drive` | Contrepartie Polype | Ce qui disparaît |
| --- | --- | --- |
| Interrogation sceptique | le skill `interrogation`, lu par `/po-brief` | rien : même posture, une question par message |
| Carte des manques et pre-mortem | le même skill : balayage des dimensions, puis pre-mortem confié à un subagent frais | rien |
| Brief approuvé dans le vault | `<projet>/docs/brief.md` en mode `new`, `<projet>/docs/prd.md` en `replace` ou `adapt` | le cadrage hors du dépôt, et l'entrée unique « idée neuve » : `Entry mode` en ouvre trois |
| ADR par `/record-adr` (vault + Graphiti) | `<projet>/docs/decisions/NNNN-<slug>.md`, modèle `templates/adr.md` | l'écriture d'une décision **de projet** dans le vault (ADR-0002) ; le pointeur Graphiti reste |
| User stories par `/user-story` | `<projet>/docs/stories.md`, écrit par `/po-stories` et relu par `/po-stories-review` | la story isolée dans le vault ; la relecture devient un gate (`Stories ready:`) |
| Packet `F03`, contrat autoportant écrit d'avance | une story `s<n>-<slug>`, puis son plan `<projet>/docs/plans/<id>.md` | le packet comme unité : le contrat se fabrique story par story (research, puis plan), pas d'avance pour toute la spec |
| `owns` du packet | la ligne `Owns` de la story | rien : même rôle, mêmes bornes de lane |
| Acceptation exécutable et bloc `Verify` | les critères d'acceptation nommés, qui sont les noms des fonctions de test, plus `<projet>/docs/verif/<id>.md` | le `Verify` recopié dans chaque contrat : les commandes du projet vivent une seule fois, dans `AGENTS.local.md` |
| Worker : écrit le code, ses tests, et se relit | `implementer` écrit, `reviewer` juge, chacun dans son contexte (Loi 2) | le rouge d'abord imposé au worker (ADR-0012) |
| Vérification faite par le driver | trois gates en fichiers, le hook `po-gate`, et `<projet>/docs/reviews/<id>.md` | la vérification qui ne laisse pas de trace |
| Worktree `feat/<slug>/F03` | un worktree par story sous `Worktree root`, sur `story/<id>` (Loi 4) | la branche par packet |
| Branche d'intégration `spec/<slug>` et PR de milestone | squash direct sur `Target branch` dès que la revue l'autorise | **la branche d'intégration et la PR de milestone** (ADR-0015) |
| Lane et réglage `parallel` | la lane de `/po-drive`, bornée par `Owns`, réglage `Parallel` | rien, mais les ships deviennent sériels : une story atterrit seule |
| État des packets dans le tracker (`octo`, `sensei`) | état dérivé des worktrees et de git, lu par `/po-status` et `/po-drive status` | **le tracker comme source de vérité** (ADR-0018) : le réglage `Tracker` ne décide de rien, il ne fait que refléter |
| Bloc `autonomy` de la spec | des réglages d'`AGENTS.local.md` : `Merge mode`, `Plan validation`, `Ship confirmation`, `Parallel`, `Max attempts` | le grant négocié une fois et figé dans une frontmatter |
| `max_attempts` et escalade | `Max attempts`, puis deux boucles de fix après une revue bloquante, puis un humain tranche | rien |
| Fichier de spec `<projet>/docs/specs/<slug>.md` | `<projet>/docs/stories.md` pour le quoi, `<projet>/docs/architecture.md` pour le comment | le document unique qui portait tous les contrats |
| Plan `dutch` dans `<projet>/.claude/plan/<slug>.md` | un plan par story, dans le dépôt, avec ses cases à cocher | le plan de spec hors de `docs/` |
| Défauts relevés pendant la construction | Loi 7 : ils vont dans `Issue tracker`, jamais dans `docs/stories.md` | rien |

Polype ajoute par-dessus ce que `/spec` n'avait pas : un boilerplate imposé à l'architecture, un
design system et des maquettes avant les écrans, et trois points d'entrée au lieu d'un.

Les décisions qui pèsent sur ce tableau : `docs/decisions/ADR-0002-adr-projet-dans-le-repo.md`,
`docs/decisions/ADR-0015-squash-direct-et-corrections-au-fil-de-leau.md`,
`docs/decisions/ADR-0080-tout-arrive-sur-la-branche-cible-par-une-pr-en-fast-forward.md` et
`docs/decisions/ADR-0018-ou-vit-letat-du-travail.md`.

## 2. Retirer `/spec` et `/drive`

### D'abord poser Polype

`polype install --global`, puis `polype init <projet>` sur chaque dépôt repris — la procédure
complète est dans `docs/installation.md`. Polype pose ses commandes `po-*` dans
`~/.claude/commands/` et ses skills sous `~/.claude/skills/<nom>/` : aucun de ces noms n'est
`spec` ni `drive`, donc les deux méthodes cohabitent tant qu'on n'a pas fini de basculer.

### Vérifier, avant de supprimer quoi que ce soit

- **Aucun projet en cours ne dépend d'un packet non repris.** La section 3 dit comment vider un
  projet en vol ; tant qu'un packet y attend, `/drive` reste la seule commande qui sait le lire.
- **La pose globale répond** : `polype check --global` sort 0 et nomme la version posée.
- **`octo` et `sensei` restent.** Ils vivent dans `~/.claude/agents/`, pas dans les skills, et
  servent hors de `/spec` : le backlog GitHub d'un dépôt pour l'un, le todo personnel pour l'autre.
  Les retirer ici casserait des usages qui n'ont rien à voir avec la migration.
- **Les renvois vers `/spec` et `/drive` dans les `CLAUDE.md`** — celui de la machine comme ceux des
  projets — se réécrivent en même temps, sinon un agent relancera une commande qui n'existe plus.

### Retirer, à la main

Quatre fichiers, deux répertoires :

```
rm ~/.claude/skills/spec/SKILL.md
rm ~/.claude/skills/spec/interrogation.md
rm ~/.claude/skills/spec/product-scaffold.md
rm ~/.claude/skills/drive/SKILL.md
rmdir ~/.claude/skills/spec ~/.claude/skills/drive
```

`polype remove --global` ne fera pas ce travail : la pose globale ne retire jamais un fichier
qu'elle n'a pas posé (`docs/installation.md`), et ni `spec` ni `drive` ne figurent dans son
manifeste. Le retrait est manuel, et il n'est pas automatisable sans risquer d'emporter un skill
que l'installeur n'a jamais vu.

Ces chemins **vivent hors du dépôt** : sur la machine, sous `~/.claude/` — ou sous
`$CLAUDE_CONFIG_DIR` quand cette variable est définie. Deux conséquences. Le retrait se refait sur
chaque machine. Et si `~/.claude/` est suivi par chezmoi, il faut aussi retirer ces fichiers de la
source (`chezmoi forget`), faute de quoi le prochain `chezmoi apply` les repose.

Un agent ne fait pas cette suppression à la place de l'utilisateur : c'est une écriture hors dépôt,
donc on la lance soi-même, après avoir lu ce qui précède.

## 3. Reprendre un projet en vol

Le cas difficile : un dépôt qui a déjà `<projet>/docs/specs/<slug>.md`, une branche d'intégration
`spec/<slug>`, des worktrees ouverts sous `<projet>/.claude/worktrees/` et des packets dans un
tracker. Dans l'ordre :

1. **Arrêter la flotte.** On ne relance pas `/drive` sur cette spec. Un packet à moitié fait ne se
   migre pas : soit il se termine sous l'ancien régime, soit son travail est jeté et il redevient
   une story neuve. Le plus simple est de finir la vague en cours et de ne rien laisser en chantier.
2. **Vider les worktrees de `/drive`.** Pour chacun : `git worktree remove <chemin>`, puis
   `git branch -d feat/<slug>/F03` une fois son travail fusionné, puis `git worktree prune`.
   L'état de Polype se dérivant des worktrees et de git (ADR-0018), un worktree orphelin est du
   bruit dans tout rapport d'état — on les enlève avant de commencer, pas après.
3. **Solder la branche d'intégration.** Elle ne survit pas à la migration (ADR-0015) : ce qui est
   vert dedans part dans `Target branch` en une fusion ou une PR, comme on l'aurait fait en fin de
   milestone, et la branche est supprimée. Si rien de vert n'y est, elle est supprimée telle quelle.
   Ensuite, chaque story Polype arrive sur `Target branch` en un commit, par une PR (ADR-0080).
4. **Réécrire les packets restants en stories.** Chaque packet non commencé devient une story de
   `<projet>/docs/stories.md`, au format de `templates/stories.md` : le but du packet devient la
   phrase « En tant que … je veux … afin de … », `owns` se recopie tel quel dans `Owns`, `depends`
   devient `Dépend de`, et chaque item d'acceptation garde son nom de fonction de test. Les
   identifiants ne se gardent pas : on renumérote en `s01-…`, `s02-…`, dans l'ordre des
   dépendances. `milestone`, `model` et `kind` ne se transposent pas — Polype choisit la piste d'une
   story par `Story track` et `Flow threshold`. Ce que les sections « Interface » et « Notes » d'un
   packet portaient de structurant va dans `<projet>/docs/architecture.md` ou dans un ADR ; le reste
   sera retrouvé par la recherche de la story.
5. **Rapatrier le cadrage.** Le brief du vault devient `<projet>/docs/brief.md`, ou
   `<projet>/docs/prd.md` selon `Entry mode`. Les ADR du vault qui gouvernent ce code se recopient
   dans `<projet>/docs/decisions/` au format `templates/adr.md` (ADR-0002) : on les recopie telles
   quelles, on ne les rejuge pas — une décision acceptée ne se réécrit jamais, elle se supersède.
6. **Fermer le tracker.** Les issues ou les tâches des packets repris se ferment ou s'annotent ;
   elles ne pilotent plus rien (ADR-0018). Les défauts connus, eux, restent là où ils sont : dans
   `Issue tracker`, jamais dans `docs/stories.md` (Loi 7).

**À partir de quel état on lance Polype.** Quand `Target branch` contient tout ce qui était vert,
qu'aucun worktree de `/drive` n'est ouvert et que l'arbre est propre : `polype init <projet>`
(ou `polype install <projet>` pour un dépôt partagé), puis `/po-setup` pour écrire
`AGENTS.local.md`, puis le cadrage — `/po-prd` ou `/po-brief` — `/po-stories`,
`/po-stories-review`, `/po-architect`, et `/po-design-system` si le produit a des écrans. C'est
seulement là que `/po-orchestrator` ou `/po-drive` ont de quoi travailler.

## 4. Ce qui ne bouge pas

`octo`, `sensei`, `dutch`, `/record-adr` pour les décisions transverses ou personnelles, et la
revue transverse à la demande : rien de tout cela n'appartient à `/spec` ni à `/drive`, et la
migration ne les touche pas. Le pointeur daté dans Graphiti reste la recherche entre projets
(ADR-0002).
