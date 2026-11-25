---
adr: 0140
title: Les retours d'usage remplacent le passage réel avant une publication
status: accepted
date: 2026-11-25
scope: framing
supersedes: [ADR-0134]
superseded-by: []
---

# ADR-0140 — Les retours d'usage remplacent le passage réel avant une publication

## Context and Problem Statement
L'ADR-0134 et `docs/ci.md` font précéder chaque publication d'un passage réel (`bin/po-eval real`) sur le dépôt jetable du parcours. Cinq passages, du 2026-11-23 au 2026-11-25, n'ont jamais atteint un ship : chacun a buté sur une protection de Claude Code (liste de commandes, bac à sable, `.git` protégé, commandes composées, écriture du relevé), et sept stories (s207 à s211, puis s212 cadrée) ont servi le banc plutôt que la méthode. Le porteur se sert de Polype chaque jour sur ses projets.

## Considered Options
- **Garder le passage réel comme préalable** — finir s212 (un bac à sable autour de la session) et relancer jusqu'à un passage qui aboutit ; aucune publication d'ici là.
- **Remplacer le préalable par les retours d'usage** — publier sans passage réel ; l'usage quotidien de Polype sur de vrais projets tient lieu de preuve, et ce qu'il révèle devient une issue, puis une story.
- **Publier sans preuve ni retour** — écarté : rien ne dirait plus si un modèle suit la méthode.

## Decision Outcome
Chosen option: **remplacer le préalable par les retours d'usage**, décision du porteur du 2026-11-25 : l'usage réel montre ce que le banc ne montrait pas, sans coût de banc. `bin/po-eval real` reste dans le dépôt, utilisable à la main ; s212 est reportée, son plan et son brouillon d'ADR gardés sur la branche `parked/s212-real-run-in-an-outer-sandbox`.

### Consequences
- Good, because une version peut sortir, et l'effort revient aux produits (ADR-0108).
- Bad, because aucune publication ne prouve plus, par un passage noté par script, qu'un modèle suit la méthode de bout en bout ; une régression de comportement se voit à l'usage, plus tard.
- Neutral: les cinq relevés restent dans `docs/evals/` ; les issues du banc (#502, #503, #504, #516, #517) sont étiquetées `parked` ; un passage réel redevient un préalable si le porteur le décide, par une nouvelle ADR.
