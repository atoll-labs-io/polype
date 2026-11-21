# Le harnais

Certains contrôles sont trop longs pour tourner dans le cycle d'une story : une campagne de fuzzing, une simulation, la suite complète de nuit. Ils tournent à heure fixe, hors de toute story, et `po-intake` les enveloppe pour que leur échec ne se perde pas dans un journal que personne ne lit.

## Ce que fait `po-intake`

`po-intake --label <nom> [--sensitive] -- '<commande>'`, installé dans chaque projet sous `.polype/hooks/` :

```
.polype/hooks/po-intake.sh --label <nom> [--sensitive] -- '<commande>'
```

- La commande, passée en un seul argument, tourne par `bash -c` depuis la racine du dépôt. Sa sortie et son code de sortie passent tels quels : l'ordonnanceur voit le même résultat que sans le harnais. Les messages de `po-intake` vont tous sur la sortie d'erreur.
- Un contrôle qui passe ne dépose rien.
- Un contrôle qui échoue dépose une issue intitulée `<nom>: <empreinte>`. L'empreinte est la première ligne d'échec reconnue dans la sortie (`not ok <n> …` de TAP, `FAILED …` de pytest, `test … ... FAILED` de cargo, `  FAIL  …` de `tests/run.sh`), ou à défaut le code de sortie ; l'empreinte `FAILED …` s'arrête avant ` - `, de sorte qu'un message d'assertion qui change garde une seule issue. Le titre est coupé à ses 80 premiers caractères, espace final retiré. Le corps donne le contrôle, la commande, le commit, le code de sortie et les 200 dernières lignes de la sortie.
- Si une issue ouverte porte déjà exactement ce titre, `po-intake` la commente (commit, date, code de sortie) au lieu d'en ouvrir une seconde : un échec qui revient chaque nuit reste une seule issue.
- Avant tout dépôt, la sortie entière est nettoyée : `po-gate redact` remplace par `[redacted]` tout ce que le contrôle des secrets du pre-commit refuserait (même liste, même règle), puis les valeurs des variables d'environnement dont le nom contient `TOKEN`, `KEY`, `SECRET` ou `PASSWORD` sont masquées à leur tour. Le nettoyage porte sur toute la sortie avant la coupe à 200 lignes, pour qu'une clé dont l'en-tête tombe au-dessus de la coupe ne laisse pas son corps visible.

## `--sensitive`, et pourquoi

Un tracker est souvent public, et la sortie d'un fuzzer contient l'entrée qui fait planter le code : déposer cette entrée, c'est publier la façon d'exploiter la faille. Un contrôle marqué `--sensitive` n'est donc jamais déposé. Son rapport brut (contrôle, commande, commit, code de sortie, sortie complète) est écrit dans un dossier temporaire neuf, en mode 600, et seul son chemin est écrit sur la sortie d'erreur, jamais la sortie elle-même : le journal de l'ordonnanceur peut être public lui aussi. C'est la personne qui décide ensuite où va l'échec.

Une campagne de fuzzing, et plus largement tout contrôle qui exerce un décodeur d'entrées venues de l'extérieur, tourne avec `--sensitive` (`testing-doctrine`, ligne des longues campagnes).

Le rapport reste dans le dossier temporaire de la machine qui a lancé le contrôle. Un contrôle sensible tourne donc sur une machine que la personne contrôle : sur un runner de CI éphémère, le rapport disparaît avec le runner.

## Les trois valeurs de `Issue tracker`

| Valeur | Ce que fait `po-intake` |
| --- | --- |
| `github` | Seulement si `origin` est sur `github.com` et que `gh auth status --hostname github.com` passe. Les titres ouverts sont lus avec `gh issue list` ; un titre identique reçoit un commentaire, sinon `gh issue create` dépose l'issue avec le label `polype-intake`, créé s'il manque. Une liste qui échoue, ou qui atteint 1000 issues, ne prouve pas l'absence de doublon : rien n'est déposé et le rapport nettoyé part sur la sortie d'erreur. |
| `taskwarrior` | Une tâche dans `project:<nom>` (le dernier segment de `origin` sans `.git`, ou à défaut le dossier du dépôt principal), avec les tags `+issue` et `+polype-intake`, annotée du corps. Une tâche en attente qui porte le même titre est annotée au lieu d'être dupliquée. |
| `—` | Rien n'est déposé : le titre et le corps, nettoyés, partent sur la sortie d'erreur. |

Un réglage absent ou une autre valeur : rien n'est déposé, la sortie d'erreur nomme le réglage et sa valeur, puis donne le rapport nettoyé. Dans tous les cas, le code de sortie reste celui du contrôle.

## Planifier un contrôle

### GitHub Actions

```yaml
name: nightly
on:
  schedule:
    - cron: '17 3 * * *'
  workflow_dispatch:
permissions:
  contents: read
  issues: write
jobs:
  nightly:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: .polype/hooks/po-intake.sh --label nightly -- 'bash tests/run.sh'
        env:
          GH_TOKEN: ${{ github.token }}
```

Un contrôle `--sensitive` ne va pas ici : son rapport disparaîtrait avec le runner.

### systemd

`~/.config/systemd/user/polype-nightly.service` :

```ini
[Unit]
Description=Polype nightly check

[Service]
Type=oneshot
WorkingDirectory=%h/dev/mon-projet
ExecStart=%h/dev/mon-projet/.polype/hooks/po-intake.sh --label nightly -- 'bash tests/run.sh'
```

`~/.config/systemd/user/polype-nightly.timer` :

```ini
[Unit]
Description=Run the Polype nightly check

[Timer]
OnCalendar=*-*-* 03:17
Persistent=true

[Install]
WantedBy=timers.target
```

Puis `systemctl --user enable --now polype-nightly.timer`. La ligne crontab équivalente :

```
17 3 * * * cd "$HOME/dev/mon-projet" && .polype/hooks/po-intake.sh --label nightly -- 'bash tests/run.sh'
```

## Transformer les échecs en stories

`po-intake` dépose l'échec ; la commande `/po-intake` en fait une story de correction (ADR-0099). Elle lit les issues ouvertes étiquetées `polype-intake` qu'aucune ligne `Fixes` ou `Corrige` de `docs/stories.md` ne cite encore, ni sur `Target branch` ni sur une branche `framing/intake-*` en attente, et écrit une story par issue : le comportement faux et l'attendu, la reproduction dans les notes, un `Owns` tiré des chemins que l'échec met en cause. Le `stories-reviewer` relit ces seules stories, chacune sur son issue ; prêtes, elles atterrissent comme un cadrage, sur `framing/intake-<horodatage>`, et `/po-drive` les prend comme toute story. Pas prêtes, rien n'atterrit et les issues vont à la personne. Une issue qui touche la sécurité ne devient jamais une story : elle va à la personne. Seules les issues déposées par le compte `gh` de la commande sont prises ; avec l'exemple GitHub Actions, c'est le compte robot du workflow qui les dépose, et une exécution de `/po-intake` ailleurs les garde pour la personne. Aucune issue n'est fermée : chacune se ferme quand sa correction est livrée.

La commande tourne sans personne pour répondre, depuis la racine du dépôt, juste après les contrôles :

```
claude -p '/po-intake'
```

Ce qu'elle retient pour la personne part dans sa sortie, donc dans le journal de l'ordonnanceur. Elle a besoin que le `.claude/settings.json` du projet lui accorde `git`, `gh` (ou `task`) et l'écriture sous `docs/` : en mode non interactif, une permission qui manque arrête la commande au lieu de la demander.

Avec systemd, une seconde ligne `ExecStart=` dans `polype-nightly.service`, après celle du contrôle (un service `oneshot` les enchaîne, et une ligne préfixée `-` n'arrête pas la suite quand le contrôle échoue) :

```ini
ExecStart=-%h/dev/mon-projet/.polype/hooks/po-intake.sh --label nightly -- 'bash tests/run.sh'
ExecStart=/usr/bin/env claude -p '/po-intake'
```

La ligne crontab équivalente, le `;` lançant `/po-intake` que le contrôle passe ou échoue :

```
17 3 * * * cd "$HOME/dev/mon-projet" && .polype/hooks/po-intake.sh --label nightly -- 'bash tests/run.sh'; claude -p '/po-intake'
```

L'exemple GitHub Actions s'en passe : le runner n'a pas d'identifiants Claude.

## Le parcours rejoué

`tests/journey/journey.sh` fait traverser à des stories jetables tout leur cycle, de l'action `plan` de `po next` jusqu'au commit `<id>: <titre>` sur `Target branch`, sans aucun modèle : à chaque vague il lit `po next` et applique, pour chaque action, une réponse écrite d'avance (`tests/journey/answers/plain/`, ou plusieurs dossiers superposés : un fichier est pris dans le premier dossier qui l'a). Il lance `po next --remote`, comme `/po-drive`. Il tourne dans `tests/run.sh`, par `tests/journey-runs-to-a-landed-commit.oracle.test.sh`, `tests/journey-runs-to-a-landed-commit.test.sh`, `tests/journey-reaches-every-stop.oracle.test.sh` et `tests/journey-reaches-every-stop.test.sh`.

**Ce qu'il prouve.** `po next` est suivi pas à pas, dans l'ordre et avec les raisons qu'il donne ; les portes `plan-validated`, `verif-current` et `ship-allowed` sont franchies pour de vrai ; le pre-commit est actif (un commit de code avant validation du plan doit être refusé) ; `po-run` et `po record review` écrivent leurs lignes ; `po ship forge`, `land`, `push`, `file` et `clean` mènent la story jusqu'au commit atterri, en local comme par pull request ; deux lanes atterrissent dans l'ordre où leurs revues ont été enregistrées, pas dans l'ordre du fichier des stories ; rien ne sort de la machine (une forge `gh` doublée, une origine en dépôt nu local, `GIT_ALLOW_PROTOCOL=file`, aucun jeton dans l'environnement, et tout appel imprévu à `gh`, `curl`, `glab`, `tea`, `task`, `claude` ou `cargo` fait échouer le parcours).

**Le pivot.** Retirer une étape veut dire ne pas la lancer : son fichier manque ou reste incomplet, `po next` redonne la même action, et le parcours s'arrête à cette porte. Une étape remplacée par un fichier écrit à la main, elle, passerait : les portes lisent des fichiers, pas qui les a écrits (une revue sans `po record`, des lignes de `## Runs` tapées à la main). Le parcours ne prouve le tampon de `po record` que par `trust.method_version` de `po state`.

**Le reste de l'automate (s200).** Le parcours connaît aussi :
- la voie courte (`track: flow`, sans recherche) ;
- une story avec écran, par `design` puis `qa` : le planificateur n'écrit que la recherche tant que le design manque, le rapport de QA passe par `po record qa`, et ses preuves forment un commit `<id>: QA evidence` à elles seules ;
- une revue refusée, par ses passes de correction (`fix`, commit `<id>: address review findings`, `Fix loop:` calculé comme le dit `/po-review`) jusqu'à `Max attempts` ;
- une décision de la boîte : sur un `ask`, une réponse `decision.json` passe par `po inbox add`, la lane attend tant que la décision n'est pas consommée ;
- une fusion humaine : sous `Ship confirmation: human (chosen)`, `po ship push` laisse la pull request à une personne ; la personne fusionne sur la forge doublée puis relance `/po-ship <id>` à la main (`journey_by_hand`, comme le dit l'étape 2 de `/po-ship`), et c'est cette relance qui nettoie la lane ;
- le protocole d'enregistrement d'une revue : une forme refusée est redemandée une fois, puis un rapport bloqué est enregistré par `po record review --composed`.

Les parcours d'arrêt (`tests/journey/stops.sh`, une fonction `stop_*` par route) changent un réglage, un champ de story, un fichier de `main` ou les réponses, puis laissent le vrai `po next --remote` répondre jusqu'à un `ask`. Le test de couverture lit les raisons `act("ask", "<raison>")` de tous les fichiers `.rs` de `po/src/next/`, sous-dossiers compris, et échoue dès que le code en tient une qu'aucun parcours n'atteint, ou une qu'il ne sait pas lire : une raison construite autrement qu'en littéral (une constante, un `format!`), coupée sur plusieurs lignes, un `"ask"` hors d'un appel `act` (un autre helper, une constante, une structure écrite à la main) ou un `act` dont l'action n'est pas un littéral sont nommés avec leur fichier et leur ligne.

**Ce qu'il ne prouve pas.**
- Qu'un modèle suive la prose des commandes (s206) ; qu'une étape falsifiée serait refusée ; que la forge doublée se comporte comme GitHub.
- Aucune marche de QA n'est réelle : pas de navigateur, le rapport et la capture sont écrits d'avance.
- Qu'aucune raison n'échappe au lecteur : il ne voit pas une action `ask` qui ne s'écrit nulle part `"ask"` dans `po/src/next/` (un `concat!`, une macro, une constante définie hors du module et passée à autre chose qu'`act`, un `act(` dont l'action est sur la ligne suivante), ni le code qu'un `include!` ou un `#[path]` tire d'ailleurs, ni une action `ask` construite hors de `po/src/next/`.
- Le second site de `setting unreadable: QA stage` (`lane.rs:69`, une lane dont l'étape ne se lit pas) n'est pas parcouru à part : le test de couverture compte la raison une fois, atteinte par le premier site.
- Le nettoyage après une fusion humaine ne passe que par la relance de `/po-ship <id>` par la personne. La route du pilote, `ship (landed)` donnée par `po next`, n'est pas prouvée : après une fusion faite sur la forge, `po next --remote` répond `wait (merge waiting)` tant que rien ne fait de `git fetch`, et le parcours ne fait pas ce fetch lui-même pour le cacher. Ce défaut est à remonter par le lead.

**Le lancer.** `bash tests/run.sh journey-runs-to-a-landed-commit.oracle.test.sh journey-runs-to-a-landed-commit.test.sh journey-reaches-every-stop.oracle.test.sh journey-reaches-every-stop.test.sh`, environ 28 secondes pour les quatre fichiers (mesuré le 21/11/2026 ; 9 pour ceux de s199 seuls), sans compilation : `po` est celui que `tests/run.sh` construit. Chaque test vit dans un seul dossier `polype-journey.XXXXXX` sous `$TMPDIR` (ou `/tmp`), retiré à toute sortie, interruption comprise ; le test de couverture y garde trois projets et leurs instantanés, environ 4 Mo. Seul un SIGKILL laisse ce dossier, et `find "${TMPDIR:-/tmp}" -maxdepth 1 -name 'polype-journey.*'` le retrouve.
