# Le harnais

Certains contrôles sont trop longs pour tourner dans le cycle d'une story : une campagne de fuzzing, une simulation, la suite complète de nuit. Ils tournent à heure fixe, hors de toute story, et `po-intake` les enveloppe pour que leur échec ne se perde pas dans un journal que personne ne lit.

## Ce que fait `po-intake`

`po-intake --label <nom> [--sensitive] -- '<commande>'`, installé dans chaque projet sous `.polype/hooks/` :

```
.polype/hooks/po-intake.sh --label <nom> [--sensitive] -- '<commande>'
```

- La commande, passée en un seul argument, tourne par `bash -c` depuis la racine du dépôt. Sa sortie et son code de sortie passent tels quels : l'ordonnanceur voit le même résultat que sans le harnais. Les messages de `po-intake` vont tous sur la sortie d'erreur.
- Un contrôle qui passe ne dépose rien.
- Un contrôle qui échoue dépose une issue intitulée `<nom>: <empreinte>`. L'empreinte est la première ligne d'échec reconnue dans la sortie (`not ok <n> …` de TAP, `FAILED …` de pytest, `test … ... FAILED` de cargo, `  FAIL  …` de `tests/run.sh`), ou à défaut le code de sortie. Le corps donne le contrôle, la commande, le commit, le code de sortie et les 200 dernières lignes de la sortie.
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
