---
adr: 0132
title: Une commande qui délègue lit po next par une permission étroite
status: accepted
date: 2026-11-22
scope: framing
supersedes: []
superseded-by: []
---

# ADR-0132 — Une commande qui délègue lit `po next` par une permission étroite

## Context and Problem Statement
L'ADR-0120 a donné à `/po-execute`, qui n'a pas de shell, une ligne de permission pour le seul verbe `po next`, et note qu'« une nouvelle exception demande une nouvelle ADR ». s198 a retiré de `/po-execute`, `/po-qa` et `/po-review` ce qu'elles redisaient du routage : lancée à la main, chacune lit maintenant `po next` et n'avance que sur sa propre action. `/po-review`, qui juge et n'a que deux lignes de shell étroites pour enregistrer un verdict, a donc reçu la même ligne que `/po-execute`. Il faut dire si c'est une exception de plus, et où elle s'arrête.

## Considered Options
- **A. La même permission étroite pour toute commande qui délègue.** Une ligne `Bash("…/po" next)`, ce verbe seul, sans argument libre.
- **B. Aucune permission.** La commande ne lit pas `po next` ; elle redit en prose les préconditions que `po next` calcule, ou la personne le lance elle-même avant. Écartée : c'est la redite que s197 et s198 ont retirée, et une règle écrite deux fois dérive.
- **C. Un shell plus large** pour ces commandes. Écartée : une commande qui juge ne doit pouvoir ni écrire ni lancer autre chose (Loi 2).

## Decision Outcome
Option choisie : **A**, par le porteur le 2026-11-22 (décision d-0050), dans la ligne de sa décision d-0008 pour l'ADR-0120 : la règle vit dans le code, et la permission ne couvre qu'un verbe qui lit.

Ce qui vaut désormais :
- Une commande qui confie une story à un subagent peut lire `po next`, par une ligne de permission qui nomme ce verbe et lui seul. `/po-execute` l'a par l'ADR-0120, `/po-review` par cette ADR ; `/po-qa` a déjà un shell pour son commit de preuves.
- `bin/po-lint` et les tests qui gardent les outils d'une commande acceptent cette ligne et refusent toute forme plus large (un joker, un autre verbe, un Bash nu).
- Tout autre verbe de `po` donné à une commande sans shell, ou un shell plus large, demande sa propre ADR.

L'ADR-0120 n'est pas remplacée : cette ADR ajoute l'exception que sa dernière conséquence annonçait.

### Consequences
- Good, because une commande lancée à la main et `/po-drive` lisent la même réponse pour le même état, et la prose ne redit plus le routage.
- Bad, because la méthode compte une seconde exception à « une commande qui juge n'a pas de shell », que `bin/po-lint` connaît par sa forme.
- Neutral: rien ne prouve encore qu'une permission de cette forme correspond à la commande réellement lancée, comme le notait l'ADR-0120 ; à vérifier à la première exécution réelle (s206).
