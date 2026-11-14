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
- Le code de sortie vaut `0` quand la demande est faite, `1` quand elle est refusée (réponse hors liste, session déjà en cours), `2` quand elle ne peut pas être lue ou exécutée : hors d'un projet Polype (`not-a-project`), un verbe inconnu (`unknown-verb`), aucun verbe (`usage`), une option inconnue (`unknown-option`), un verbe pas encore construit (`not-built`), une erreur interne (`internal`), une session de chef de projet qu'on ne sait pas lire (`session-unreadable`), un état du projet illisible là où `run` en a besoin (`state-unreadable`), un lancement de Claude Code qui échoue (`launch-failed`), une boîte de décisions non réglée (`no-inbox-setting`), illisible (`unreadable-decision`), impossible à écrire (`inbox-unwritable`) ou tenue par un autre `po` (`inbox-busy`).
- Tout objet porte `"contract": 1`. Un champ ajouté ne change pas ce numéro, pas plus qu'une valeur ajoutée à une liste fermée ; un champ retiré ou renommé le change. Un lecteur tolère une valeur qu'il ne connaît pas.
- Un refus ou un échec a la forme `{"contract": 1, "error": "<code stable>", "message": "<une phrase>"}`.
- Une valeur que Polype ne peut pas lire vaut `null`. Elle n'est jamais devinée.
- `state` et `inbox` ne lancent aucun modèle, n'interrogent aucune forge sans y être invités (`state --remote`) et, sans `--remote`, répondent en moins d'une seconde.

## `state`

```json
{
  "contract": 1,
  "project": "polype",
  "commit": "0648923",
  "method_version": "0.2.0",
  "framing": {"stage": "done", "next": null},
  "milestone": {"id": "M20", "stories": 5, "shipped": 0},
  "session": {"running": false, "id": null},
  "bounds": "held",
  "waiting": ["d-0003"],
  "lanes": [
    {
      "story": "s160-intake-title-bounded",
      "stage": "review",
      "next": {"action": "ship", "reason": "ship-allowed passes"},
      "blocked_by": null
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

- `framing.stage` : `setup`, `scope`, `stories`, `stories-review`, `architecture`, `design-system` ou `done` ; `next` est la commande à lancer, ou `null`. Les règles sont celles de `po-session`.
- `lanes[].stage` : `research`, `design`, `plan`, `execute`, `qa`, `review`, `ship`, ou `null` quand il ne peut pas être lu. La première règle qui s'applique décide, chaque gate étant le `po-gate` du worktree lancé dans ce worktree : story livrée → `ship` ; sans plan → `research` sans recherche, `design` quand la story a un écran et que `docs/designs/<id>/design.md` manque, sinon `plan` ; `plan-validated` refuse → `plan` ; `ship-allowed` passe → `ship` ; `verif-current` refuse → `execute` ; la story va en QA et `qa-current` refuse → `qa` ; sinon `review`. Une revue bloquée sur un code inchangé reste donc `review`, et une lane livrée encore sur le disque est `ship`, son nettoyage.
- `lanes[].blocked_by` : le premier arrêt qui attend une personne, `root-cause-not-found`, `technical-choice`, `qa-blocked`, `max-attempts` ou `merge-waiting`, sinon `null`. `next.action` est l'une de `plan`, `validate-plan`, `design`, `execute`, `qa`, `review`, `fix`, `ship`, `wait`, `ask` ; `reason` nomme la porte ou le fichier qui en décide.
- `held[].reason` : `dependency` (une story dont elle dépend n'est pas livrée), `owns` (une lane en cours tient un de ses chemins), `decision` (une décision attend, `ref` la nomme), `parallel` (la limite `Parallel` est atteinte), `framing` (aucun titre de `docs/stories.md` ne la nomme sur le point de départ des lanes : `origin/<Target branch>` quand cette référence existe, `<Target branch>` sinon ; `ref` est alors une référence git, pas une story ni une décision, lue dans le dépôt local sans interroger de forge ; la story garde sa place dans `Parallel`). Pour `owns` seulement, l'item porte aussi `entry` (l'entrée `Owns` de la story retenue), `ref_entry` (celle de la story que nomme `ref`) et `path` (un chemin que les deux couvrent, `null` quand le recouvrement n'est gardé que par prudence, par exemple deux jokers dans un même segment ou `**/x.md` contre `src/y.md`) : la première paire qui se recouvre, dans l'ordre `Owns` de la story retenue. Ces trois champs sont absents pour toute autre raison.
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
- `blocks` liste les stories ou les étapes de cadrage qui attendent.
- `consumed` (`{"ref", "at"}`) n'apparaît qu'une fois la décision consommée par le chef de projet ; jusque-là, la décision a exactement la forme ci-dessus.
- `sensitive: true` : la décision touche à la sécurité. `question` et `options` ne décrivent alors aucun moyen d'exploiter quoi que ce soit, `context` pointe un fichier hors du dépôt, et la décision n'est jamais recopiée dans git, dans une issue ni dans un journal.

`inbox <id>` rend une décision seule, répondue ou non. `inbox` saute un fichier qui ne se lit pas ; `state` le signale par l'avertissement `unreadable-decision`.

### Poser une décision : `inbox add`

Le chef de projet pose une décision avec `inbox add`, qui la lit en JSON sur l'entrée standard. Il ne donne ni `id`, ni `asked`, ni `status`, ni `answer`, et aucun champ que la forme ci-dessus n'a ; `sensitive` vaut `false` et `context` `null` quand il les omet. `po` vérifie la décision, lui donne l'identifiant suivant (`d-0001`, `d-0002`…, le plus grand numéro présent plus un), la date du moment avec son décalage, le statut `pending`, l'écrit dans `<id>.json` et rend ce qu'il a écrit. Deux écritures simultanées n'obtiennent jamais le même identifiant.

La boîte est le dossier que nomme le réglage `Decision inbox`, depuis la racine du checkout principal ou en chemin absolu, même lancée depuis un worktree. Elle n'entre jamais dans git (ADR-0107) : `po` n'y écrit que si le dossier est hors du dépôt, ou dans le dépôt et ignoré par git ; l'installeur ajoute l'emplacement du gabarit, `.polype/inbox/`, au `.gitignore`.

| Cas | Code de sortie | `error` |
| --- | --- | --- |
| `Decision inbox` absent ou `—` (aussi pour `inbox` et `inbox <id>`) | 2 | `no-inbox-setting` |
| JSON illisible, champ manquant, inconnu ou mal typé, `motive` hors liste, `question` vide, sur plusieurs lignes ou de plus de 200 caractères, moins de deux ou plus de trois `options`, `key` vide ou en double, `recommended` hors des `key`, `why` vide | 1 | `malformed-decision` |
| décision `sensitive` dont `context` manque, est relatif ou pointe dans le dépôt | 1 | `sensitive-context-in-repo` |
| boîte dans le dépôt que git n'ignore pas | 1 | `inbox-not-ignored` |
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
| boîte dans le dépôt que git n'ignore pas | 1 | `inbox-not-ignored` |
| fichier de la décision qui ne se lit pas | 2 | `unreadable-decision` |
| décision tenue par un autre `po` au-delà d'une seconde environ | 2 | `inbox-busy` |
| écriture impossible | 2 | `inbox-unwritable` |
| autre chose que deux arguments | 2 | `unknown-option` |

Une réponse acceptée rend la décision, avec `"status": "answered"` et `"answer": {"key": "a", "at": "<date>"}`. Le porteur qui ne veut aucune des options ne répond pas par cette commande : il ouvre la session (`claude attach`) et le dit au chef de projet, qui repose une décision.

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
| `next` | la prochaine action de chaque lane et la vague suivante | `lanes[].next`, `ready` et `held` sous `## state` |
| `record review <id>`, `record qa <id>` | écrit le rapport de revue ou de QA d'une story à partir de la réponse du subagent | `method/commands/po-review.md`, `method/commands/po-qa.md`, [ADR-0102](decisions/ADR-0102-le-rapport-de-qa-revient-en-texte.md), [ADR-0104](decisions/ADR-0104-celui-qui-consigne-une-revue-en-ecrit-l-en-tete.md) |
| `inbox add` | pose une décision | `### Poser une décision : inbox add`, parce qu'il écrit ce que l'agent extérieur lit |
| `inbox --answered` | les décisions répondues, pas encore consommées | `## answer`, parce qu'il change ce que rend `inbox <id>` |
| `inbox consume <id> <ref>` | consomme une décision répondue | `## answer` |

## Ce que l'interface ne fait pas

- Elle ne fusionne rien et n'ouvre aucune porte : les gates restent celles des règles.
- Elle ne rend aucun contenu de fichier, seulement des chemins.
- Elle ne répond pas à la place du porteur : une décision sans réponse reste `pending`, quel que soit son âge.
