# L'interface pour un agent extérieur

Polype est du côté de l'intelligence : il cadre, planifie, écrit, relit. Polype reste une brique indépendante et ne suppose aucun agent en particulier. Un agent extérieur, quel qu'il soit (une interface de discussion, un ordonnanceur, ou par exemple un assistant vocal local qui sert de majordome), ne fait que passer les plats : il demande où en est un projet, lit au porteur ce qui l'attend, rapporte sa réponse, lance ou reprend le travail. Il n'a rien à comprendre de la méthode et ne lit jamais de prose.

Ce document est le contrat de cette interface, **version 1**. Il est écrit avant le code : les stories s164 à s173 de [`stories.md`](stories.md) le construisent, et l'[ADR-0107](decisions/ADR-0107-un-agent-exterieur-interroge-polype-par-une-commande-et-du-json.md) en fixe le transport. La commande est le binaire Rust `po`, un par machine ([ADR-0106](decisions/ADR-0106-le-pilote-devient-un-automate-en-code.md), [ADR-0117](decisions/ADR-0117-un-binaire-po-par-machine.md)). `state` existe depuis s164, `inbox` depuis s165, `answer` depuis s166, `run` et `continue` depuis s169.

## La commande

Un binaire par machine, posé par l'installeur (voir [`installation.md`](installation.md), « Le binaire `po` »), lancé depuis la racine d'un projet ou depuis un de ses worktrees, qui répond pour le checkout principal :

```
${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po <verbe> [arguments]
```

| Verbe | Effet | Écrit quelque chose |
| --- | --- | --- |
| `state` | l'état du projet | non |
| `inbox` | les décisions qui attendent le porteur | non |
| `inbox <id>` | une décision, répondue ou non | non |
| `answer <id> <option>` | enregistre la réponse du porteur | oui, la décision |
| `run` | lance le chef de projet sur le projet | oui, une session |
| `continue` | relance le chef de projet après une réponse | oui, une session |

Le binaire a aussi les verbes du chef de projet, hors de ce contrat : voir `## Les verbes du chef de projet`.

Règles communes :

- La sortie standard est un seul objet JSON, toujours, y compris en cas d'échec ; rien d'autre n'y est écrit.
- Le code de sortie vaut `0` quand la demande est faite, `1` quand elle est refusée (réponse hors liste, session déjà en cours), `2` quand elle ne peut pas être lue ou exécutée : hors d'un projet Polype (`not-a-project`), un verbe inconnu (`unknown-verb`), aucun verbe (`usage`), une option inconnue (`unknown-option`), une erreur interne (`internal`), une session de chef de projet qu'on ne sait pas lire (`session-unreadable`), un état du projet illisible là où `run` en a besoin (`state-unreadable`), un lancement de Claude Code qui échoue (`launch-failed`), une boîte de décisions non réglée (`no-inbox-setting`), illisible (`unreadable-decision`), impossible à écrire (`inbox-unwritable`) ou tenue par un autre `po` (`inbox-busy`).
- Tout objet porte `"contract": 1`. Un champ ajouté ne change pas ce numéro, pas plus qu'une valeur ajoutée à une liste fermée ; un champ retiré ou renommé le change. Un lecteur tolère une valeur qu'il ne connaît pas.
- Un refus ou un échec a la forme `{"contract": 1, "error": "<code stable>", "message": "<une phrase>"}`.
- Une valeur que Polype ne peut pas lire vaut `null`. Elle n'est jamais devinée.
- `po <verbe> --help`, pour chacun des verbes `state`, `next`, `inbox`, `answer`, `record`, `run`, `continue` et `ship`, avec `--help` n'importe où parmi ses arguments, rend `{"contract": 1, "verb": "<verbe>", "usage": "<une ligne>"}` et sort en `0`, sans lire le projet ni l'entrée standard, sans rien écrire ni lancer ; pour `inbox`, la réponse porte aussi `input`, une décision que `inbox add` accepte telle quelle. `po --help` et un verbe inconnu gardent leur erreur.
- `state` et `inbox` ne lancent aucun modèle, n'interrogent aucune forge sans y être invités (`state --remote`) et, sans `--remote`, répondent en moins d'une seconde.

## `state`

```json
{
  "contract": 1,
  "project": "polype",
  "commit": "0648923",
  "method_version": "0.2.0",
  "framing": {
    "stage": "done",
    "next": null,
    "items": [
      {"item": "scope", "state": "approved"},
      {"item": "stories", "state": "present"},
      {"item": "stories-review", "state": "yes"},
      {"item": "architecture", "state": "present"},
      {"item": "design-system", "state": "not needed"}
    ]
  },
  "milestone": {"id": "M20", "stories": 5, "shipped": 0},
  "session": {"running": false, "id": null},
  "bounds": "held",
  "waiting": ["d-0003"],
  "stale": [],
  "answered": [],
  "lanes": [
    {
      "story": "s160-intake-title-bounded",
      "path": ".worktrees/s160-intake-title-bounded",
      "stage": "review",
      "next": {"action": "ship", "reason": "ship-allowed passes"},
      "blocked_by": null,
      "stops": []
    }
  ],
  "ready": ["s161-installer-leftovers"],
  "held": [{"story": "s159-ci-on-every-pr", "reason": "decision", "ref": "d-0001"}],
  "shipped": [
    {
      "story": "s152-intake-issue-becomes-a-story",
      "commit": "ff2b1e0",
      "trust": {
        "checks": "passed",
        "oracle": "intact",
        "fix_loops": 0,
        "max_severity": "major",
        "not_verified": 1,
        "method_version": "9844988",
        "track": "full",
        "duration_s": null,
        "cost_usd": null
      }
    }
  ],
  "warnings": []
}
```

- Un projet Polype a `AGENTS.local.md` ou `.polype/version` à la racine de son checkout principal ; ses réglages sont lus dans cet `AGENTS.local.md`, sur le disque.
- `project` est le nom du dossier du projet ; `commit` le commit court de `Target branch` ; `method_version` la première ligne de `.polype/version`.
- `milestone` est la première section `## M…` de `docs/stories.md` sur `Target branch` qui tient une story pas encore livrée, `id` étant le titre avant ` — ` ; `null` quand toutes le sont.
- `waiting` liste, triés, les `id` des décisions `pending` du dossier que nomme le réglage `Decision inbox` (`.polype/inbox/` dans le gabarit), lu depuis la racine du projet ou absolu ; `[]` quand le dossier manque.
- `stale` liste, triés, les `id` des décisions `pending` périmées selon la règle de `## inbox` ; `null` quand `waiting` l'est ou quand l'ensemble des stories livrées ne se lit pas.
- `answered` liste, triés, les `id` des décisions `answered` que le chef de projet n'a pas encore consommées : la même liste que `inbox --answered` ; `null` quand `waiting` l'est.

- `framing.stage` : `setup`, `scope`, `stories`, `stories-review`, `architecture`, `design-system` ou `done` ; `next` est la commande à lancer, ou `null`. `framing.items` donne l'état de chaque élément du cadrage, dans cet ordre : `scope` (`approved`, `in progress`, `missing`, ou `by hand` quand `Entry mode` vaut `—`), `stories` (`present`, `missing`), `stories-review` (`yes`, `no`, `none` sans ligne `Stories ready:`), `architecture` (`present`, `missing`), `design-system` (`present`, `missing`, ou `not needed` quand le fichier manque et qu'aucune story n'a d'écran) ; `[]` au stade `setup`. `po` fait référence pour ces règles : le hook de session lira ces champs (s172) au lieu de les dériver.
- `lanes[].stage` : `research`, `design`, `plan`, `execute`, `qa`, `review`, `ship`, ou `null` quand il ne peut pas être lu. La première règle qui s'applique décide, chaque gate étant le `po-gate` du worktree lancé dans ce worktree : story livrée → `ship` ; sans plan → `research` sans recherche, `design` quand la story a un écran et que `docs/designs/<id>/design.md` manque, sinon `plan` ; `plan-validated` refuse → `plan` ; `ship-allowed` passe → `ship` ; `verif-current` refuse → `execute` ; la story va en QA et `qa-current` refuse → `qa` ; sinon `review`. Une revue bloquée sur un code inchangé reste donc `review`, et une lane livrée encore sur le disque est `ship`, son nettoyage.
- `lanes[].path` : le chemin du worktree relatif à la racine du projet, absolu quand il est hors du projet.
- `lanes[].stops` : chaque arrêt de la lane qui attend une personne, dans cet ordre, `[]` quand il n'y en a pas ; chacun porte un `code` et ses valeurs : `root-cause-not-found` (`file`, la recherche), `technical-choice` (`file`, le plan ; `command`, `/po-plan <id>`), `qa-blocked` (`file`, le rapport de QA), `max-attempts` (`fix_loop` et `max_attempts`, deux entiers), `merge-waiting` (`branch`, `story/<id>`).
- `lanes[].blocked_by` : le `code` du premier arrêt de `stops`, `null` quand `stops` est vide. `next.action` est l'une de `plan`, `validate-plan`, `design`, `execute`, `qa`, `review`, `fix`, `ship`, `wait`, `ask` ; `reason` nomme la porte ou le fichier qui en décide. `wait` porte `dependency <id>` quand une story dont celle de la lane dépend n'est pas livrée : une telle lane ne compte ni dans `Parallel` ni pour `owns` tant que cette story n'est pas livrée. Une action `plan` porte aussi `track`, la voie de la story, `full` ou `flow`, absent de toute autre action, `contract` restant `1` ; la première règle qui s'applique décide : `Story track` autre que `full`, `flow` ou `auto` → `ask`, raison `setting unreadable: Story track` ; `full` → `full` ; une story qui porte une ligne `Fixes` (`Corrige`), qui a un écran ou qui va en QA → `full`, un `QA stage` qui ne peut pas la router donnant `ask`, raison `setting unreadable: QA stage` ; `flow` → `flow` ; sous `auto`, un `Flow threshold` qui n'est pas un entier → `ask`, raison `setting unreadable: Flow threshold`, une story sans ligne `Complexity` (`Complexité`) → `ask`, raison `no complexity`, sinon `flow` quand la complexité ne dépasse pas le seuil et `full` au-delà. Une story de `ready` peut recevoir `ask` : elle reste dans `ready` jusqu'à ce que la réponse de la personne la rende planifiable. Une story qui a un écran reçoit `design` dès que sa recherche est sur le disque et que `docs/designs/<id>/design.md` manque, avant `plan` ; sans recherche, elle reçoit d'abord `plan`, raison `no research`.
- `held[].reason` : `dependency` (une story dont elle dépend n'est pas livrée), `owns` (une lane en cours tient un de ses chemins, une lane qui attend une dépendance n'en tient aucun), `decision` (une décision attend, `ref` la nomme), `parallel` (la limite `Parallel` est atteinte), `framing` (aucun titre de `docs/stories.md` ne la nomme sur le point de départ des lanes : `origin/<Target branch>` quand cette référence existe, `<Target branch>` sinon ; `ref` est alors une référence git, pas une story ni une décision, lue dans le dépôt local sans interroger de forge ; la story garde sa place dans `Parallel`). Pour `owns` seulement, l'item porte aussi `entry` (l'entrée `Owns` de la story retenue), `ref_entry` (celle de la story que nomme `ref`) et `path` (un chemin que les deux couvrent, `null` quand le recouvrement n'est gardé que par prudence, par exemple deux jokers dans un même segment ou `**/x.md` contre `src/y.md`) : la première paire qui se recouvre, dans l'ordre `Owns` de la story retenue. Ces trois champs sont absents pour toute autre raison.
- `session` : `running` dit si la session de chef de projet que `run` a lancée tourne encore, `id` en est l'identifiant court (voir `## run et continue`) ; `{"running": false, "id": null}` quand `run` n'a jamais lancé de session, `null` quand l'enregistrement ou la liste des sessions de Claude Code ne se lit pas.
- `bounds` : `held` quand les bornes des subagents seront tenues dans une session lancée par `run`, `unproven` sinon (voir `## run et continue`).
- `ready`, `held` et `lanes[].next` valent `null` tant que la story qui les calcule n'est pas livrée.
- `warnings` est toujours une liste d'objets portant un `code` : `method-version-mismatch` (`po`, `project` : `po` et le projet n'ont pas la même version), `missing-setting` et `unreadable-setting` (`setting`), `orphan-worktree` (`path`, `branch`, `null` sur une tête détachée), `unreadable-decision` (`path`), `no-gate` (`story` : son worktree n'a pas de `po-gate`). Un champ qu'un réglage absent empêche de lire vaut `null`.

### Les signaux de confiance

`shipped` liste les stories livrées du jalon courant (`milestone`) dans l'ordre de `docs/stories.md`, et toutes les stories livrées avec `state --all` ; `[]` quand aucun jalon n'est en cours sans `--all`, `null` quand les stories ou l'ensemble des stories livrées ne se lisent pas. `commit` est le commit court qui a livré la story.

Pour chaque story livrée, `shipped[].trust` est lu dans les fichiers que le pipeline écrit déjà, tels qu'ils sont au commit qui l'a livrée :

| Champ | Valeurs | Lu dans |
| --- | --- | --- |
| `checks` | `passed`, `failed`, `none`, `null` | les contrôles de GitHub sur le commit livré, par `gh api --hostname github.com`, seulement avec `--remote` ; `null` sur une autre forge, quand `gh` échoue ou tant qu'un contrôle tourne |
| `oracle` | `intact`, `changed-with-reason`, `none` | la ligne `- Oracle:` que `po record` a écrite dans le dernier bloc de la revue ; `null` pour une revue qu'il n'a pas consignée |
| `fix_loops` | un entier | la dernière ligne `Fix loop:` de ce bloc |
| `max_severity` | `none`, `minor`, `major`, `critical` | la dernière ligne `Max severity:` de ce bloc |
| `not_verified` | un entier | le nombre d'entrées de `## Not verified` de ce bloc |
| `method_version` | un identifiant | l'estampille `Method version:` que `po record` pose dans la revue |
| `track` | `full`, `flow` | le frontmatter du plan : `track: flow`, ou `full` sans ligne `track:` |
| `duration_s` | un entier ou `null` | le relevé : du début du premier contrôle lancé par `po-run` à la fin du dernier, chaque ligne portant son heure de fin et sa durée |
| `cost_usd` | `null` | aucun fichier ne le porte encore |

Un agent extérieur n'a pas à juger ces signaux : il les rapporte. Celui qui en décide est le porteur, ou le grand modèle à qui il délègue.

## `inbox`

`inbox` rend `{"contract": 1, "pending": [<décision>, …]}`, la plus ancienne d'abord. Une décision :

```json
{
  "id": "d-0003",
  "asked": "2026-11-12T14:05:00+01:00",
  "motive": "strategic",
  "sensitive": false,
  "question": "Où tourne la suite de tests sur chaque pull request ?",
  "context": "docs/decisions/ADR-0105-la-suite-tourne-sur-chaque-pull-request.md",
  "options": [
    {"key": "a", "label": "Runners hébergés de GitHub", "consequence": "rien à installer ; ni libre ni auto-hébergé"},
    {"key": "b", "label": "Runner auto-hébergé", "consequence": "sur une machine du porteur ; à isoler sur un dépôt public"},
    {"key": "c", "label": "Forgejo Actions auto-hébergé", "consequence": "tout est libre ; une forge à installer d'abord"}
  ],
  "recommended": "a",
  "why": "le contrôle est un script neutre, on changera d'endroit sans le réécrire",
  "reversible": true,
  "blocks": ["s159-ci-on-every-pr"],
  "status": "pending",
  "answer": null
}
```

- `motive` reprend les motifs de `## What goes to the person` des règles : `incoherence`, `new-idea`, `strategic`, `technical-choice`, `stop` (un arrêt qui va à un humain : cause introuvable, tentatives épuisées, QA bloquée, worktree orphelin, pull request fermée) et `security`.
- `question` tient en une phrase, lisible à voix haute. `options` en compte deux ou trois, jamais plus ; chaque `label` se dit en quelques mots.
- `recommended` nomme une `key` de la liste, `why` en donne la raison en une phrase.
- `reversible` dit si la décision se défait sans perte ; une décision difficile à défaire se lit en entier au porteur avant sa réponse.
- `blocks` liste les stories ou les étapes de cadrage qui attendent. Une décision tient les lanes qu'elle nomme jusqu'à ce qu'elle soit consommée, répondue ou non, périmée ou non.
- `story` nomme, sous la forme `s<nombre>-<slug>`, la story d'où vient la décision, sans tenir sa lane : c'est le rôle de `blocks`. Il est absent quand le chef de projet ne le donne pas ; `po record review` le pose sur la décision de sécurité qu'il publie.
- Une décision `pending` est **périmée** quand les stories qu'elle nomme, `story` et `blocks` ensemble, sont au moins une et toutes livrées sur `Target branch`. Une entrée de `blocks` qui n'a pas la forme d'une story est une étape de cadrage et empêche la marque ; une décision qui ne nomme aucune story n'est jamais périmée. `inbox` et `inbox <id>` portent alors `"stale": true` sur la décision : la marque se calcule à la lecture, n'est présente que sur une décision `pending` périmée et n'est jamais écrite dans le fichier. Sans `Target branch`, aucune décision n'est marquée.
- `consumed` (`{"ref", "at"}`) n'apparaît qu'une fois la décision consommée par le chef de projet. `story`, `stale` et `consumed` sont les seuls champs qui peuvent manquer ; en dehors d'eux, la décision a exactement la forme ci-dessus.
- `sensitive: true` : la décision touche à la sécurité. `question` et `options` ne décrivent alors aucun moyen d'exploiter quoi que ce soit, `context` pointe un fichier hors du dépôt, et la décision n'est jamais recopiée dans git, dans une issue ni dans un journal.

`inbox <id>` rend une décision seule, répondue ou non. `inbox` saute un fichier qui ne se lit pas ; `state` le signale par l'avertissement `unreadable-decision`.

### Poser une décision : `inbox add`

Le chef de projet pose une décision avec `inbox add`, qui la lit en JSON sur l'entrée standard. Il ne donne ni `id`, ni `asked`, ni `status`, ni `answer`, et aucun champ que la forme ci-dessus n'a ; `sensitive` vaut `false` et `context` `null` quand il les omet. `po` vérifie la décision, lui donne l'identifiant suivant (`d-0001`, `d-0002`…, le plus grand numéro présent plus un), la date du moment avec son décalage, le statut `pending`, l'écrit dans `<id>.json` et rend ce qu'il a écrit. Deux écritures simultanées n'obtiennent jamais le même identifiant.

La boîte est le dossier que nomme le réglage `Decision inbox`, depuis la racine du checkout principal ou en chemin absolu, même lancée depuis un worktree. Elle n'entre jamais dans git (ADR-0107) : `po` n'y écrit que si le dossier est hors du dépôt, ou dans le dépôt et ignoré par git ; l'installeur ajoute l'emplacement du gabarit, `.polype/inbox/`, au `.gitignore`.

| Cas | Code de sortie | `error` |
| --- | --- | --- |
| `Decision inbox` absent ou `—` (aussi pour `inbox` et `inbox <id>`) | 2 | `no-inbox-setting` |
| JSON illisible, champ manquant, inconnu ou mal typé, `motive` hors liste, `question` vide, sur plusieurs lignes ou de plus de 200 caractères, moins de deux ou plus de trois `options`, `key` vide ou en double, `recommended` hors des `key`, `why` vide, `story` qui n'a pas la forme `s<nombre>-<slug>` | 1 | `malformed-decision` |
| décision `sensitive` dont `context` manque, est relatif, pointe dans le dépôt ou ne se vérifie pas | 1 | `sensitive-context-in-repo` |
| boîte dans le dépôt que git n'ignore pas, ou dont l'emplacement ne se vérifie pas | 1 | `inbox-not-ignored` |
| écriture impossible | 2 | `inbox-unwritable` |
| `inbox <id>` : identifiant inconnu ou qui n'a pas la forme `d-<chiffres>` | 1 | `unknown-decision` |
| `inbox <id>` : fichier qui ne se lit pas | 2 | `unreadable-decision` |
| tout autre argument | 2 | `unknown-option` |

Un refus n'écrit rien.

## `answer`

`answer <id> <key>` n'accepte qu'une `key` listée dans `options` d'une décision `pending`. Tout le reste est refusé, sans rien écrire :

| Cas | Code de sortie | `error` |
| --- | --- | --- |
| `<id>` inconnu ou qui n'a pas la forme `d-<chiffres>` | 1 | `unknown-decision` |
| décision déjà répondue | 1 | `already-answered` |
| `<key>` hors de la liste, clé vide comprise, comparée octet par octet, sans rognage ni casse ignorée | 1 | `not-an-option` |
| boîte dans le dépôt que git n'ignore pas, ou dont l'emplacement ne se vérifie pas | 1 | `inbox-not-ignored` |
| fichier de la décision qui ne se lit pas | 2 | `unreadable-decision` |
| décision tenue par un autre `po` au-delà d'une seconde environ | 2 | `inbox-busy` |
| écriture impossible | 2 | `inbox-unwritable` |
| autre chose que deux arguments | 2 | `unknown-option` |

Une réponse acceptée rend la décision, avec `"status": "answered"` et `"answer": {"key": "a", "at": "<date>"}`. Sur une décision périmée, la réponse est enregistrée et porte aussi `"stale": true` : c'est le seul endroit où une décision répondue la montre (ADR-0127). Le porteur qui ne veut aucune des options ne répond pas par cette commande : il ouvre la session (`claude attach`) et le dit au chef de projet, qui repose une décision.

Répondre ne lance rien. C'est `continue` qui relance le chef de projet ; il lit les décisions répondues, écrit ce que chacune produit là où cela doit vivre (une ADR qui passe à `accepted`, une story, une ligne de plan) en citant son `id`, consomme chacune avec `inbox consume`, la `ref` nommant ce que la réponse a produit, puis reprend les lanes qu'elle bloquait.

Le chef de projet lit avec `inbox --answered` les décisions répondues qu'il n'a pas encore consommées : `{"contract": 1, "answered": [<décision>, …]}`, la plus ancienne d'abord, `[]` quand le dossier manque. `inbox consume <id> <ref>` note dans la décision `"consumed": {"ref": "<ref>", "at": "<date>"}` et la retire de cette liste ; elle reste `answered`. La `ref` n'est pas vérifiée sur le disque, une ligne de plan n'étant pas un chemin. Les codes `unknown-decision`, `inbox-not-ignored`, `unreadable-decision`, `inbox-busy` et `inbox-unwritable` s'y appliquent comme pour `answer`, et :

| Cas | Code de sortie | `error` |
| --- | --- | --- |
| `ref` vide une fois rognée, sur plusieurs lignes ou de plus de 200 caractères | 1 | `malformed-ref` |
| décision encore `pending` | 1 | `not-answered` |
| décision déjà consommée | 1 | `already-consumed` |
| autre chose que `consume <id> <ref>` | 2 | `unknown-option` |

## `run` et `continue`

`run` lance une session de chef de projet à la racine du projet, qui fait ce que `state` annonce : l'étape de cadrage manquante, sinon `/po-drive`. `continue` relance une session arrêtée, après une réponse.

```json
{"contract": 1, "session": "<identifiant>", "started": "2026-11-12T14:20:00+01:00", "command": "/po-drive"}
```

- `command` est la seule consigne de la session : `framing.next` tant que le cadrage n'est pas `done`, sinon `/po-drive`. Elle ne vient jamais de celui qui lance.
- `session` est l'identifiant court de la session, ses huit premiers caractères, celui que prennent `claude attach <id>` et `claude logs <id>` et que `state` rend dans `session.id`.
- `po` lance `claude --bg --session-id <uuid> <command>` avec un identifiant qu'il tire lui-même ; `continue` lance `claude --bg --resume <uuid> <command>` sur la session que `run` a enregistrée et qui ne tourne plus, et, sans session enregistrée, fait comme `run`. Le programme lancé est `$PO_CLAUDE` quand la variable est posée, sinon `claude`.
- Une session tourne quand `claude agents --json` la liste avec un `pid` ; une session arrêtée y reste sans `pid`. `state` ne pose cette question à Claude Code que si une session a été enregistrée.
- `bounds` vaut `held` quand trois conditions sont prouvées : `implementer.md`, `qa.md` et `reviewer.md` sont dans `agents/` de la configuration de Claude Code (`$CLAUDE_CONFIG_DIR`, sinon `~/.claude`) et chacun est le subagent de Polype, dont le frontmatter porte son nom et branche le hook `po-bounds` exactement comme Polype le pose ; aucun des trois n'est dans `.claude/agents/` du dépôt, car Claude Code préfère la copie du dépôt, dont les hooks attendent le dialogue de confiance qu'une session en arrière-plan ne montre jamais ; le projet a un `.polype/hooks/po-bounds.sh` exécutable, le script que ces hooks appellent. Un fichier qui porte seulement le bon nom ne prouve rien : `unproven` dans tous les autres cas.

Refus, dans cet ordre, sans rien lancer ni enregistrer :

| Cas | Code de sortie | `error` |
| --- | --- | --- |
| un argument, quel qu'il soit : `run` et `continue` n'ont aucune option | 2 | `unknown-option` |
| hors d'un projet Polype | 2 | `not-a-project` |
| un autre `po run` ou `po continue` est en train de lancer : son verrou est tenu par un `po` vivant depuis moins de dix minutes | 1 | `already-running` |
| l'enregistrement de la session ou la liste des sessions de Claude Code ne se lit pas | 2 | `session-unreadable` |
| une session de chef de projet tourne déjà | 1 | `already-running` |
| les bornes des subagents ne peuvent pas être prouvées tenues (`bounds` vaut `unproven`) | 1 | `bounds-unproven` |
| le cadrage, les lanes, les stories prêtes ou la boîte ne se lisent pas, et rien d'autre ne donne de travail | 2 | `state-unreadable` |
| rien à faire : cadrage `done`, aucune lane sur le disque, aucune story prête, aucune décision répondue et pas encore consommée | 1 | `nothing-to-do` |
| Claude Code ne se lance pas ou sort en erreur | 2 | `launch-failed` |

Un cadrage qui n'est pas `done` n'est jamais `nothing-to-do` : `run` lance alors son étape manquante.

Le verrou du lancement porte le pid du `po` qui le tient. Un verrou laissé par un `po` mort (une erreur interne, un processus tué) ou vieux de plus de dix minutes est repris par le lancement suivant : il ne bloque jamais `run` ni `continue` quand `state` dit qu'aucune session ne tourne. `already-running` veut donc toujours dire qu'un lancement ou une session est réellement en cours.

`po run` n'écrit rien dans l'arbre de travail : l'enregistrement de la session et le verrou du lancement vivent sous le dossier commun de git (voir [`installation.md`](installation.md), « Les fichiers d'état »).

Un agent extérieur ne passe jamais de consigne libre à `run` : le travail à faire vient de `docs/stories.md` et de la boîte, pas de celui qui lance. Une idée nouvelle du porteur devient une issue du projet, que le chef de projet lit.

## La boucle d'un agent extérieur

```
po run                       # une fois : lance le chef de projet
po state                     # où en est le projet ; session.running dit s'il travaille
po inbox                     # ce qui attend le porteur, lu à voix haute
po answer <id> <key>         # rapporte sa réponse
po continue                  # relance le chef de projet, qui consomme la réponse
```

L'agent recommence à `po state` à son rythme. `already-running` veut dire que le chef de projet travaille encore : rien à relancer. `nothing-to-do` veut dire que le projet n'attend rien : l'agent le dit au porteur et ne relance pas. `bounds-unproven` va au porteur, qui installe Polype en pose globale (voir [`installation.md`](installation.md)). Pour suivre la session, `claude attach <session>` et `claude logs <session>`.

## Les verbes du chef de projet

Le binaire a d'autres verbes, que lance le chef de projet et jamais l'agent extérieur ; ils ne font pas partie de ce contrat.

| Verbe | Effet | Forme décrite |
| --- | --- | --- |
| `next`, `next --remote` | la prochaine action de chaque lane et la vague suivante, chaque action `plan` portant la voie `track` de sa story ; les ships passent dans l'ordre de la ligne `Recorded:` la plus récente de chaque revue, à défaut de la date de modification du fichier ; avec `--remote`, sous `Merge mode: pr` et sur GitHub seulement (`gh api --hostname github.com`), une lane dont la pull request a été fermée sans merge reçoit `ask`, raison `pull request closed`, et sort de l'ordre des ships ; une réponse illisible ne change rien ; `state` ne pose pas cette question ; une action `plan` de raison `ready`, et elle seule, porte `commands`, les commandes qui ouvrent sa lane, que le chef de projet lance une à une, chacune telle quelle, `po` n'en lançant aucune : `git -C <racine> fetch origin` quand `origin` existe, `git -C <racine> worktree add -b story/<id> <lane> <départ>` (`<départ>` le point de départ de `held`, `framing`), ou `git -C <racine> worktree add <lane> story/<id>` quand la branche existe déjà sans worktree, un `cp <racine>/<f> <lane>/<f>` par fichier `.env*` de la racine que git ignore, précédé d'un `mkdir -p` quand `<f>` tient un `/`, puis `(cd <lane> && <Install>)` sauf sous `Install: —` ; chaque chemin est absolu, entre apostrophes dès qu'il tient un caractère hors de `[A-Za-z0-9_@%+=:,./-]` ; `commands` vaut `null` sans réglage `Install`, comme quand `Worktree root` ou le point de départ ne se lit pas ; un fichier `.env*` de la racine que git n'ignore pas donne `ask`, raison `env file not ignored`, sans `track` ni `commands` | `lanes[].next`, `ready` et `held` sous `## state` |
| `record review <id>`, `record qa <id>` | écrit le rapport de revue ou de QA d'une story à partir de la réponse du subagent ; chaque bloc d'une revue porte, sous `Method version:`, une ligne `Recorded:` datée avec son décalage ; une revue garde de ses constats marqués `[security]` la seule ligne `Security findings: <n> — decision <id>`, leur texte allant dans un fichier sous `Private folder`, hors du dépôt, que désigne une décision `sensitive` de motif `security` ; sans réglage, refus `no-private-folder-setting` (sortie 2), réglage dans le dépôt ou relatif, refus `private-folder-unusable` (sortie 1), et rien n'est écrit | `method/commands/po-review.md`, `method/commands/po-qa.md`, [ADR-0102](decisions/ADR-0102-le-rapport-de-qa-revient-en-texte.md), [ADR-0104](decisions/ADR-0104-celui-qui-consigne-une-revue-en-ecrit-l-en-tete.md), [ADR-0123](decisions/ADR-0123-le-texte-d-un-constat-de-securite-reste-hors-du-depot.md) |
| `ship forge`, `ship forge --target <branche>` | lit la forge de l'URL configurée d'`origin` (`remote.origin.url`, avant toute réécriture `insteadOf` : un remote écrit par un raccourci comme `gh:<propriétaire>/<dépôt>` se lit donc comme un hôte non reconnu) et rend, sortie 0 quel que soit le verdict : `forge` (`github`, `gitlab`, `forgejo`, `null` sans `origin` ou hôte non reconnu), `verdict` (`collaborative`, `solo`, `unreadable`), `signals` (`writer`, `codeowners`, `protection` : `true`, `false`, `null` si illisible), `failed` (`[{signal, call, reason}]`, `signal` `null` quand c'est la forge elle-même qui n'a pu être reconnue ; `reason` un statut HTTP ou un mot fixe, jamais la sortie d'un outil ni l'URL d'`origin`), `line` (la valeur de `Ship confirmation` telle qu'écrite, `null` sans elle), `effective` (`human`, `automatic`, `null` quand `line` l'est), `rewrite` (`human (forge)`, `automatic (forge)` ou `null`) ; `--target` remplace `Target branch`, pour `/po-setup` avant `AGENTS.local.md` ; refus en sortie 2 : `not-a-project`, `usage` (pas d'étape, ou une autre que `forge`, `land`, `push`, `file` et `clean`), `unknown-option`, `missing-setting` (ni `--target` ni `Target branch`) ; n'écrit rien, n'interroge que la forge d'`origin` | `method/commands/po-ship.md` `## The forge's review rule`, [ADR-0079](decisions/ADR-0079-le-ship-suit-la-forge-lue-par-son-api-et-un-choix-solo-ne-bouge-pas.md), [ADR-0130](decisions/ADR-0130-le-ship-entre-dans-po-par-un-verbe-a-sous-etapes.md) |
| `ship land <id> [--routes yes\|no] [--land]`, `ship land <id> --sha <sha>` | depuis le worktree de la story, dans cet ordre : arguments, worktree sur `story/<id>`, `po-gate ship-allowed <id>`, réglages (`Target branch`, `Merge mode`, `Full suite`, `E2E stage`, `Build stage`, `Test`, `E2E`, `Build`), contrôle du remote (`pr` exige `origin`, `local` l'interdit), titre lu dans `docs/stories.md`, racine sur `Target branch` sans fichier suivi modifié sous `local`, base (`git fetch origin` puis `origin/<cible>` sous `pr`, `<cible>` sous `local`) ; quand un commit de la base hors de `story/<id>` porte exactement le sujet `<id>: <titre>`, la story a déjà atterri, quoi que la base ait fait de ses lignes depuis (modifiées, effacées ou défaites) : la commande rend aussitôt `landed: true`, `already_landed: true`, `sha` le plus récent de ces commits, `tree` son arbre, `checks` `[]`, `committed` `null`, avant la sonde, sans contrôle ni écriture ; sinon sonde `git merge-tree <base> story/<id>` ; quand elle rend l'arbre de la base, soit `story/<id>` n'a aucun changement propre depuis sa base commune (`nothing-to-land`, rien d'écrit), soit la base tient déjà ce que la story apporte sous un autre sujet, et la commande rend `already_landed: true` avec la base pour `sha` ; une base qui tient seulement une partie du changement de la story sans porter son sujet n'est pas reconnue : la story est alors traitée comme à faire atterrir ; sinon les contrôles par `po-run` (étiquettes `ship: unit suite`, `ship: end to end`, `ship: build`, leur sortie sur stderr), le commit sur `story/<id>` de `docs/reviews/<id>.md` et `docs/verif/<id>.md` (message `<id>: review`), le commit d'atterrissage `git commit-tree <tree> -p <base> -m "<id>: <titre>"`, et sous `local` avec `--land` le `git merge --ff-only` de la racine ; `--land` est refusé tant que la ligne `Ship confirmation`, son origine ôtée, ne lit pas `automatic` ; `--routes` est exigé sous `Build stage: ship-if-route` ; `--sha`, après une réponse Merge sous `local`, refait les étapes jusqu'à la base, vérifie que le commit a la base pour seul parent, le titre et l'arbre d'un `merge-tree` refait, puis avance la racine sans contrôle ni commit ; rend, sortie 0 : `id`, `mode` (`pr`, `local`), `base`, `tree`, `sha`, `title`, `committed` (la nouvelle tête de `story/<id>` ou `null`), `checks` (`[{check, outcome, command}]`, `check` `unit suite`, `end to end` ou `build`, `outcome` `recorded`, `passed`, `absent`, `skipped` ou `not-at-ship`, `command` celle qui a tourné, sinon `null`), `landed`, `already_landed` ; refus en sortie 1 : `gate-refused` (le motif de la porte), `confirmation-required` (`--land` hors `automatic`), `remote-check`, `root-not-clean`, `nothing-to-land` (une branche qui n'apporte rien et qu'aucun commit de la base ne titre), `conflict` (avec `paths`), `check-failed` (avec `check`, `exit`, `checks`), `stale-landing` (`--sha` seulement) ; en sortie 2 : `usage` (`--land` ou `--sha` sous `pr` compris), `unknown-option`, `not-a-project`, `wrong-branch`, `no-gate`, `missing-setting`, `unreadable-setting`, `no-title`, `no-base`, `git-failed`, `check-unrunnable` ; écrit : le fetch sous `pr`, le commit des documents sur `story/<id>`, des objets isolés, l'avance rapide sous `local` avec `--land` ou `--sha` ; ne pousse jamais, ne déplace jamais `story/<id>` | `method/commands/po-ship.md` `## Step 1`, [ADR-0080](decisions/ADR-0080-tout-arrive-sur-la-branche-cible-par-une-pr-en-fast-forward.md), [ADR-0081](decisions/ADR-0081-comment-une-story-atterrit-en-fast-forward-selon-la-forge.md), [ADR-0130](decisions/ADR-0130-le-ship-entre-dans-po-par-un-verbe-a-sous-etapes.md) |
| `ship push <id> --sha <sha> --body-file <fichier>` | sous `Merge mode: pr`, depuis le worktree de la story, dans cet ordre : arguments (les trois exigés, `--sha` de 40 hexadécimaux, `--body-file` un fichier existant et non vide, la description que `/po-ship` a écrite), worktree sur `story/<id>`, `po-gate ship-allowed <id>`, réglages (`Target branch`, `Merge mode` qui doit valoir `pr`, `Ship confirmation`, `Forge checks` `required`, `—` ou absent, `E2E stage`, `Build stage`), contrôle du remote, titre, base (`git fetch origin` puis `origin/<cible>`), lecture de la forge comme `ship forge` et valeur effective, qu'aucune option ne remplace et dont la commande seule décide la fusion ; quand `rewrite` n'est pas `null`, le commit de réglage `chore: Ship confirmation follows the forge` est bâti sur `origin/<cible>` hors de tout checkout (seul `AGENTS.local.md` change), envoyé avec un bail sur `framing/ship-confirmation` sauf si cette branche porte déjà la ligne ou si `origin/<cible>` la porte, puis, sur GitHub, le brouillon ouvert du dépôt d'`origin` dont la tête est ce commit est repris, sinon un brouillon est ouvert ; un échec n'arrête pas le ship ; un commit de la base qui porte exactement le sujet `<id>: <titre>` → `state: merged` sans rien écrire ; sinon sonde `merge-tree` (`conflict`) ; la tête de `story/<id>` est lue sur `origin` par `git ls-remote` : tant qu'elle est encore l'atterrissage (la base pour seul parent, le sujet, l'arbre de la sonde), elle devient `sha` et rien n'est envoyé ; sinon `--sha`, s'il est l'atterrissage, est envoyé par `git push --force-with-lease=refs/heads/story/<id>:<tête lue ou vide> origin <sha>:refs/heads/story/<id>` ; sans dépôt GitHub → `state: no-pull-request`, une personne ouvre la pull request ; sinon `gh pr list --head story/<id> --state all`, la plus récente de celles dont la tête vit dans le dépôt d'`origin` lui-même (`isCrossRepository` faux, `headRepositoryOwner` son propriétaire ; une pull request qui ne le dit pas → `pr-unreadable`, aucune n'est reprise) : `MERGED` sur `sha` → `state: merged`, `MERGED` sur un autre commit → `pr-head-differs`, `CLOSED` → `pull-request-closed`, `OPEN` reprise, aucune → `gh pr create --base <cible> --head story/<id> --title "<id>: <titre>" --body-file <fichier>` ; effective `human` → la tête de la pull request, relue jusqu'à 10 fois, doit être `sha`, sinon `pr-head-differs`, puis `state: waiting-for-human` ; effective `automatic` → sous `Forge checks: required` ou une étape `ci`, jusqu'à 60 lectures espacées de `PO_SHIP_POLL_SECONDS` secondes (30 par défaut) de `gh pr view --json headRefOid` puis, une fois égale à `sha`, de `gh pr checks --json name,bucket,link`, décidées sur le JSON et jamais sur le code de sortie (une liste vide n'est jamais un succès) ; puis `po-gate ship-allowed <id>` relu, `gh pr merge <url> --rebase --match-head-commit <sha>`, et `gh pr view --json state` : `MERGED` → `state: merged`, sinon `merging` ; chaque appel `gh` porte `--repo github.com/<propriétaire>/<dépôt>` et passe par son propre login, aucun jeton dans un argument, un fichier ou la sortie ; rend, sortie 0 : `id`, `sha` (le commit envoyé ou repris, ou celui de la base qui porte le sujet), `base`, `pushed`, `pull_request` (`{url, number, created}` ou `null`), `verdict`, `effective`, `forge_checks` (`null` sans la ligne), `checks` (`[{name, bucket, link}]` de la dernière lecture, `[]` sans attente), `rewrite` (`{line, branch, pushed, url, refused, next}` ou `null`, `branch` `null` quand `origin/<cible>` porte déjà la ligne ; `next` dit ce qui reste à une personne : `open-pull-request` quand la branche est envoyée sans brouillon possible, hors GitHub, `write-line` quand `refused`, `null` sinon), `state` (`merged`, `merging`, `waiting-for-human`, `no-pull-request`) ; refus en sortie 1 : `gate-refused` (à l'entrée ou avant la fusion), `remote-check`, `conflict` (avec `paths`), `stale-landing` (relancer `po ship land`), `push-refused` (jamais forcé), `pr-unreadable`, `pr-failed`, `pr-head-differs` (la pull request ne pointe pas sur `sha` : ni annoncée prête ni fusionnée ; relancer, ou une personne), `pull-request-closed` (une personne), `checks-failed` (avec `pull_request` et `checks`, les contrôles `fail` ou `cancel` avec leur lien ; la story repart en fix run par `/po-execute <id>`), `checks-timeout` et `checks-unreadable` (une personne), `merge-refused` ; en sortie 2 : `usage` (`Merge mode: local` compris), `unknown-option`, `not-a-project`, `wrong-branch`, `no-gate`, `missing-setting`, `unreadable-setting`, `no-title`, `no-base`, `git-failed` ; écrit : le fetch, `refs/heads/story/<id>` et `refs/heads/framing/ship-confirmation` sur `origin`, des objets isolés, une pull request, un brouillon, une fusion ; ne pousse jamais `Target branch` ; une relance reprend où la précédente s'est arrêtée sans rien écrire deux fois | `method/commands/po-ship.md` `## Step 2`, [ADR-0080](decisions/ADR-0080-tout-arrive-sur-la-branche-cible-par-une-pr-en-fast-forward.md), [ADR-0081](decisions/ADR-0081-comment-une-story-atterrit-en-fast-forward-selon-la-forge.md), [ADR-0130](decisions/ADR-0130-le-ship-entre-dans-po-par-un-verbe-a-sous-etapes.md) |
| `ship file <id> [--file] [--hold <ligne>]… [--fixed <ligne>]…` | après l'atterrissage, depuis le worktree de la story, dans cet ordre : arguments (`--file` une fois ; `--hold` et `--fixed` répétables, un numéro de ligne de la revue, jamais deux fois le même), worktree sur `story/<id>`, réglages (`Target branch`, `Merge mode` `pr` ou `local`, `Issue tracker` `github`, `taskwarrior` ou `—`), titre, base (`git fetch origin` puis `origin/<cible>` sous `pr`, `<cible>` sous `local`), preuve : un commit de la base hors de `story/<id>` qui porte exactement le sujet `<id>: <titre>`, sans quoi `not-landed` avant toute lecture de la revue et tout appel au tracker ; puis la revue telle qu'elle a atterri (`git show <sha>:docs/reviews/<id>.md`), son dernier bloc lu comme `po-gate findings-shape` le lit : un constat est un élément de liste en colonne 0 qui s'ouvre sur sa sévérité, pris avec ses lignes suivantes ; titre `<id>: <sévérité> — <début>`, coupé à 80 caractères quelle que soit la locale ; chaque ligne de `--hold` ou `--fixed` doit ouvrir un élément de ce bloc. Sans `--file`, rend, sortie 0, sans appel au tracker : `state: listed`, `id`, `landed` (le commit d'atterrissage), `tracker`, `findings` (`[{line, last, severity, title}]`, les `major` et `minor`), `pending` (`[{lines, title}]`, ce que `--file` déposerait : les constats moins `--hold` et `--fixed`, un par titre), `held`, `fixed`, `critical` (les `critical` que `--fixed` ne retire pas), `security` (`{count, decision, lines}`, lus sur la ligne `Security findings:` et les éléments marqués `[security]`, désignés par leur ligne seule), `unrecognised` (`[{line, text}]`, les lignes que le filet de la porte refuserait, `text` `null` quand elle touche un élément marqué). Avec `--file` : sous `—`, `state: no-tracker` ; sous `github`, `gh issue list --repo github.com/<propriétaire>/<dépôt> --state open --limit 1000 --json title`, puis pour chaque titre absent, à l'identique, `gh api --hostname github.com --method POST repos/<propriétaire>/<dépôt>/issues --input <fichier>` ; sous `taskwarrior`, `task rc.confirmation=off project:<nom> +issue status:pending export`, puis `task rc.confirmation=off import <fichier>` (`<nom>` : le dernier segment d'`origin` sans `.git`, sinon le dossier du checkout principal) ; succès : `state: filed`, `filed` (`[{lines, title, url}]` ou `uuid`), `already_open`. Refus en sortie 1, chacun avec `pending` sauf `not-landed` : `not-landed`, `tracker-unavailable` (`origin` hors de github.com, `gh` ou `task` qui ne démarre pas), `listing-failed` (sortie non nulle ou réponse qui n'est pas une liste), `too-many-open` (1 000 titres), `file-failed` (avec `filed` jusque-là ; une relance ne dépose que ce qui manque) ; en sortie 2 : `usage`, `unknown-option`, `not-a-project`, `wrong-branch`, `missing-setting`, `unreadable-setting`, `no-title`, `no-base`, `git-failed`, `no-review` (revue absente du commit, sans bloc de verdict ou sans `## Findings`), `unknown-finding`. Écrit : le fetch sous `pr`, des tickets ou des tâches, et, le temps de l'appel, un dossier `0700` sous `TMPDIR` aux fichiers `0600`, toujours effacé. Ne dépose jamais un élément `[security]`, un `critical`, une ligne non reconnue ni un bloc antérieur ; le texte d'un constat ne passe ni par un argument, ni par une variable d'environnement, ni par un journal ; aucune option ne prend de texte | `method/commands/po-ship.md` `## Step 3`, [ADR-0090](decisions/ADR-0090-tout-ce-qui-est-a-traiter-devient-une-issue.md), [ADR-0124](decisions/ADR-0124-les-constats-ordinaires-d-une-revue-de-securite-sont-deposes.md), [ADR-0130](decisions/ADR-0130-le-ship-entre-dans-po-par-un-verbe-a-sous-etapes.md) |
| `ship clean <id>` | depuis la racine du dépôt (ou n'importe où dans le projet : les appels git tournent à la racine), après l'atterrissage, dans cet ordre : arguments (un id, aucune option), réglages (`Target branch`, `Merge mode` `pr` ou `local`, `Worktree root`), contrôle du remote, base (`git fetch origin` puis `origin/<cible>` sous `pr`, `<cible>` sous `local`), titre lu dans `docs/stories.md` tel que la base le tient, preuve : un commit de la base, hors de `refs/heads/story/<id>` tant qu'elle existe, qui porte exactement le sujet `<id>: <titre>`, sans quoi `not-landed` ; puis la liste `git worktree list --porcelain` : le chemin de la lane tenant une autre branche → `not-the-lane`, la branche tenue ailleurs → `branch-in-use` (chemin nommé), un dossier de lane dont `git status --porcelain` n'est pas vide → `dirty-worktree` (avec `paths`) ; la tête locale de `story/<id>`, qui n'est supprimée que si l'atterrissage tient déjà tous ses changements (le `git merge-tree` de l'atterrissage et de cette tête rend l'arbre de l'atterrissage), sans quoi `branch-not-landed` ; sous `pr`, la tête que `origin` tient pour `refs/heads/story/<id>` (`git ls-remote`), qui n'est supprimée que si elle est l'atterrissage : le commit trouvé sur la base, ou un commit de même sujet, fils unique d'un commit que la base tient, dont l'arbre est celui de l'atterrissage ou dont le patch (`git patch-id --verbatim`, sur les octets du diff) est le sien, ce dernier cas étant celui d'une fusion rebasée sur une base qui avait avancé. Rien n'est supprimé avant la fin de ces contrôles. Puis `git worktree remove <chemin>` sans `--force` (refus → `worktree-refused`, rien ne suit), `git update-ref -d refs/heads/story/<id> <tête lue>` (jamais `branch -D`), et sous `pr` `git push --force-with-lease=refs/heads/story/<id>:<tête lue> origin --delete refs/heads/story/<id>` (refus → `delete-refused`, le worktree et la branche locale étant déjà retirés) ; chaque suppression est sautée quand sa cible n'existe plus, si bien qu'une relance après une coupure finit ce qui restait sans erreur. Rend, sortie 0 : `state` `cleaned`, `id`, `landed` (le commit trouvé), `worktree` (`removed`, `absent`), `branch` (`deleted`, `absent`), `remote` (`deleted`, `absent`, `null` sous `local`), `remote_head` et `message` `null`. Quand la tête de `origin` n'est pas l'atterrissage (un commit gagné après l'envoi, un autre sujet, un autre changement), elle est gardée, le nettoyage local déjà fait n'est pas défait, et la réponse, sortie 1, porte `state: remote-kept`, `remote: kept`, `remote_head` (la tête observée) et `message` : une personne la regarde et la supprime à la main ; une relance rend le même `state`, le même `remote_head` et la même sortie 1, avec `worktree` et `branch` à `absent` au lieu de `removed` et `deleted`. Refus en sortie 1 : `remote-check`, `not-landed`, `not-the-lane`, `branch-in-use`, `dirty-worktree`, `branch-not-landed`, `worktree-refused`, `branch-refused`, `delete-refused` ; en sortie 2 : `usage`, `unknown-option`, `not-a-project`, `missing-setting`, `unreadable-setting`, `no-title`, `no-base`, `git-failed`. Écrit : le fetch sous `pr` (et, si la tête de `origin` manque en local, celui de `refs/heads/story/<id>`, objets seuls), le retrait du worktree, `refs/heads/story/<id>` local et sur `origin` ; ni porte, ni commit, ni forge ni jeton : aucun appel à `gh` | `method/commands/po-ship.md` `## Step 3`, [ADR-0081](decisions/ADR-0081-comment-une-story-atterrit-en-fast-forward-selon-la-forge.md), [ADR-0130](decisions/ADR-0130-le-ship-entre-dans-po-par-un-verbe-a-sous-etapes.md) |
| `inbox add` | pose une décision | `### Poser une décision : inbox add`, parce qu'il écrit ce que l'agent extérieur lit |
| `inbox --answered` | les décisions répondues, pas encore consommées | `## answer`, parce qu'il change ce que rend `inbox <id>` |
| `inbox consume <id> <ref>` | consomme une décision répondue | `## answer` |

## Ce que l'interface ne fait pas

- Elle ne fusionne rien et n'ouvre aucune porte : les gates restent celles des règles.
- Elle ne rend aucun contenu de fichier, seulement des chemins.
- Elle ne répond pas à la place du porteur : une décision sans réponse reste `pending`, quel que soit son âge.
