---
adr: 0041
title: Le retour en QA exige une revue bloquée, et la preuve non committée se committe sans nouvelle marche
status: accepted
date: 2026-10-08
scope: story s64-qa-routing
supersedes: [ADR-0037]
superseded-by: []
---

# ADR-0041 — Le retour en QA exige une revue bloquée, et la preuve non committée se committe sans nouvelle marche

## Context and Problem Statement
ADR-0034 reconnaît une revue bloquée par la QA à sa seule ligne `Next action:` nommant `/po-qa`. Or chaque revue porte une ligne `Next action:` (`templates/review.md`), et une revue complète bloquée par de vrais constats peut nommer `/po-qa` : elle part en QA au lieu d'un fix run (majeur de la revue de s57). Depuis ADR-0037, `qa-current` refuse un rapport à jour mais non committé ; la ligne de reprise de `/po-drive` qui en faisait le commit de preuve ne peut plus s'appliquer, la lane refait une marche, et la revue bloquée sur ce rapport, dont `Next action:` est le commit de preuve et non `/po-qa` (`review-antihallu`, s63), part en fix run. Il faut dire comment chaque commande reconnaît ces deux cas.

## Considered Options
Reconnaître une revue bloquée par la QA :
- **`Review status: blocked` et `Next action:` nommant `/po-qa`** — les deux lignes viennent du reviewer quand il ne peut pas conclure ; une revue complète n'est jamais un retour en QA.
- **`Next action:` seul (ADR-0034)** — attrape une revue complète qui conseille une nouvelle QA après un correctif.
- **Le message de la gate dans `Failure cause:`** — déjà écarté par ADR-0034 : une copie du message, écrite par le reviewer.

Reconnaître le rapport à jour mais non committé, dans la reprise :
- **Le refus de `po-gate qa-current <id>` qui dit `is current but`** — la gate lit l'arbre et HEAD elle-même, vérifie la fraîcheur avant le commit (ADR-0037), et ce refus n'apparaît que si tout le reste passe ; `review-antihallu` s'appuie déjà sur la même distinction. Un test relie la phrase citée par `/po-drive` au texte de `po-gate.sh`.
- **Déduire l'état : dernier `QA status: complete` et `git status` non vide sous `docs/qa/<id>/`** — aucun couplage au texte, mais committe aussi un rapport périmé, ce qui ajoute un commit `<id>: QA evidence` et rapproche à tort la borne de deux commits de preuve.
- **Une nouvelle sous-commande de `po-gate`** — la plus nette, mais `po-gate.sh` n'appartient pas à cette story ni à aucune story ouverte.

La revue bloquée sur ce rapport :
- **Un second retour en QA, nommé à part : `Review status: blocked` et `Next action:` nommant le commit `<id>: QA evidence`** — commit de preuve sans marche, puis revue au même `Fix loop:`.
- **L'inclure dans « bloquée par la QA »** — contredit le « seulement si … nomme `/po-qa` » de la story, et renverrait vers une marche inutile.
- **La laisser en fix run** — l'implementer ne peut rien corriger, un `Max attempts` est perdu.

## Decision Outcome
Chosen option: **statut bloqué exigé ; refus `is current but` de la gate pour le rapport non committé ; revue bloquée sur la preuve traitée comme un retour en QA distinct**, parce que c'est la seule combinaison qui n'envoie ni une revue complète en QA, ni une preuve à jour vers une nouvelle marche ou un fix run, sans toucher `po-gate.sh`, `/po-qa`, le reviewer ni le gabarit de revue.

Les deux retours gardent le `Fix loop:` et ne dépensent aucune unité de `Max attempts` ; la borne d'ADR-0034 (deux commits `<id>: QA evidence` depuis le dernier commit de l'implementer, puis un humain) s'applique aux deux. Ceci précise la troisième option retenue par ADR-0034 et remplace ses conséquences neutres sur `/po-flow`, `/po-execute` et le rapport non committé, ainsi que la conséquence « Bad » d'ADR-0037 sur `po-drive.md`.

### Consequences
- Good, because toutes les commandes envoient le même état au même endroit, et un rapport QA `blocked` va à un humain partout, `/po-status` compris.
- Bad, because la reprise de `/po-drive` lit le texte d'un refus de la gate ; changer ce texte sans `tests/qa-fleet.test.sh` casse la reprise en silence.
- Neutral: `/po-execute` n'a pas de shell : il s'arrête et nomme le commit de preuve au lieu de le faire. Une sous-commande dédiée de `po-gate` resterait plus nette, dans une story qui possède `po-gate.sh`.
