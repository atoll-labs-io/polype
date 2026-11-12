# L'interface pour un agent extérieur

Polype est du côté de l'intelligence : il cadre, planifie, écrit, relit. Polype reste une brique indépendante et ne suppose aucun agent en particulier. Un agent extérieur, quel qu'il soit (une interface de discussion, un ordonnanceur, ou par exemple un assistant vocal local qui sert de majordome), ne fait que passer les plats : il demande où en est un projet, lit au porteur ce qui l'attend, rapporte sa réponse, lance ou reprend le travail. Il n'a rien à comprendre de la méthode et ne lit jamais de prose.

Ce document est le contrat de cette interface, **version 1**. Il est écrit avant le code : les stories s164 à s170 de [`stories.md`](stories.md) le construisent, et l'[ADR-0107](decisions/ADR-0107-un-agent-exterieur-interroge-polype-par-une-commande-et-du-json.md), encore proposée, en fixe le transport. Tant que ces stories ne sont pas livrées, rien de ce qui suit n'existe ; la boîte provisoire est [`a-trancher.md`](a-trancher.md).

## La commande

Une commande par projet, lancée depuis n'importe où :

```
<projet>/.polype/hooks/po-agent.sh <verbe> [arguments]
```

| Verbe | Effet | Écrit quelque chose |
| --- | --- | --- |
| `state` | l'état du projet | non |
| `inbox` | les décisions qui attendent le porteur | non |
| `inbox <id>` | une décision, répondue ou non | non |
| `answer <id> <option>` | enregistre la réponse du porteur | oui, la décision |
| `run` | lance le chef de projet sur le projet | oui, une session |
| `continue` | relance le chef de projet après une réponse | oui, une session |

Règles communes :

- La sortie standard est un seul objet JSON, toujours, y compris en cas d'échec ; rien d'autre n'y est écrit.
- Le code de sortie vaut `0` quand la demande est faite, `1` quand elle est refusée (réponse hors liste, session déjà en cours), `2` quand elle ne peut pas être lue ou exécutée (hors d'un projet Polype, `jq` absent).
- Tout objet porte `"contract": 1`. Un champ ajouté ne change pas ce numéro ; un champ retiré ou renommé le change.
- Un refus ou un échec a la forme `{"contract": 1, "error": "<code stable>", "message": "<une phrase>"}`.
- Une valeur que Polype ne peut pas lire vaut `null`. Elle n'est jamais devinée.
- `state` et `inbox` ne lancent aucun modèle, n'interrogent aucune forge sans y être invités (`state --remote`) et répondent en moins d'une seconde.

## `state`

```json
{
  "contract": 1,
  "project": "polype",
  "commit": "0648923",
  "method_version": "0648923",
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
        "duration_s": null,
        "cost_usd": null
      }
    }
  ]
}
```

- `framing.stage` : `setup`, `scope`, `stories`, `stories-review`, `architecture`, `design-system` ou `done` ; `next` est la commande à lancer, ou `null`.
- `lanes[].stage` : `research`, `design`, `plan`, `execute`, `qa`, `review`, `ship`. `next.action` est l'une de `plan`, `validate-plan`, `design`, `execute`, `qa`, `review`, `fix`, `ship`, `wait`, `ask` ; `reason` nomme la porte ou le fichier qui en décide.
- `held[].reason` : `dependency` (une story dont elle dépend n'est pas livrée), `owns` (une lane en cours tient un de ses chemins), `decision` (une décision attend, `ref` la nomme), `parallel` (la limite `Parallel` est atteinte).
- `bounds` : `held` quand les bornes des subagents seront tenues dans une session lancée par `run`, `unproven` sinon.

### Les signaux de confiance

Lus dans les fichiers que le pipeline écrit déjà, pour chaque story livrée (`shipped[].trust`) :

| Champ | Valeurs | Lu dans |
| --- | --- | --- |
| `checks` | `passed`, `failed`, `none`, `null` | les contrôles de la forge sur le commit atterri (seulement avec `--remote`) |
| `oracle` | `intact`, `changed-with-reason`, `none` | `po-gate oracle-intact`, tel que la revue l'a consigné |
| `fix_loops` | un entier | `docs/reviews/<id>.md` |
| `max_severity` | `none`, `minor`, `major`, `critical` | la dernière ligne `Max severity:` de la revue |
| `not_verified` | un entier | le nombre d'entrées de `## Not verified` de la revue |
| `method_version` | un identifiant | l'estampille que `po-record` pose dans la revue |
| `duration_s`, `cost_usd` | un nombre ou `null` | le relevé, quand il les porte |

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
- `sensitive: true` : la décision touche à la sécurité. `question` et `options` ne décrivent alors aucun moyen d'exploiter quoi que ce soit, `context` pointe un fichier hors du dépôt, et la décision n'est jamais recopiée dans git, dans une issue ni dans un journal.

## `answer`

`answer <id> <key>` n'accepte qu'une `key` listée dans `options` d'une décision `pending`. Tout le reste est refusé, sans rien écrire :

| Cas | `error` |
| --- | --- |
| `<id>` inconnu | `unknown-decision` |
| décision déjà répondue | `already-answered` |
| `<key>` hors de la liste | `not-an-option` |

Une réponse acceptée rend la décision, avec `"status": "answered"` et `"answer": {"key": "a", "at": "<date>"}`. Le porteur qui ne veut aucune des options ne répond pas par cette commande : il ouvre la session (`claude attach`) et le dit au chef de projet, qui repose une décision.

Répondre ne lance rien. C'est `continue` qui relance le chef de projet ; il lit les décisions répondues, écrit ce que chacune produit là où cela doit vivre (une ADR qui passe à `accepted`, une story, une ligne de plan) en citant son `id`, puis reprend les lanes qu'elle bloquait.

## `run` et `continue`

`run` lance une session de chef de projet à la racine du projet, qui fait ce que `state` annonce : l'étape de cadrage manquante, sinon `/po-drive`. `continue` relance une session arrêtée, après une réponse.

```json
{"contract": 1, "session": "<identifiant>", "started": "2026-11-12T14:20:00+01:00", "command": "/po-drive"}
```

Refus, sans rien lancer :

| Cas | `error` |
| --- | --- |
| une session de chef de projet tourne déjà | `already-running` |
| les bornes des subagents ne peuvent pas être prouvées tenues | `bounds-unproven` |
| rien à faire : aucune story prête, aucune décision répondue | `nothing-to-do` |

Un agent extérieur ne passe jamais de consigne libre à `run` : le travail à faire vient de `docs/stories.md` et de la boîte, pas de celui qui lance. Une idée nouvelle du porteur devient une issue du projet, que le chef de projet lit.

## Ce que l'interface ne fait pas

- Elle ne fusionne rien et n'ouvre aucune porte : les gates restent celles des règles.
- Elle ne rend aucun contenu de fichier, seulement des chemins.
- Elle ne répond pas à la place du porteur : une décision sans réponse reste `pending`, quel que soit son âge.
