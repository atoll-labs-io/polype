---
adr: 0058
title: La règle qui envoie une story au design et en QA est écrite une fois, dans AGENTS.md, et les commandes la nomment
status: accepted
date: 2026-10-08
scope: story s80-surface-routing
supersedes: []
superseded-by: []
---

# ADR-0058 — La règle de routage par surface est écrite une fois, dans `AGENTS.md`

## Context and Problem Statement
ADR-0054 dit qu'une surface `screen` passe par le design, que `QA stage: screens` fait passer en QA les seules stories `screen` et `surfaces` toute story dont la surface n'est pas `—`, et qu'une story sans ligne `Surface` garde l'ancienne règle (elle a un écran quand son texte en montre un). Aujourd'hui la règle de l'écran est recopiée, chaque fois avec ses mots, dans `/po-drive`, `/po-orchestrator`, `/po-status`, `review-antihallu`, le reviewer, l'implementer, le gabarit de revue et la table du cycle de `AGENTS.md`. Y ajouter la surface à chaque endroit multiplie par deux les phrases à tenir d'accord, et un oubli laisse deux règles de routage différentes dans la même flotte.

## Considered Options
- **Deux termes définis une fois dans `AGENTS.md` (Loi 1, « Per story ») — « a story **has a screen** » pour le design, « a story **goes to QA** » pour la QA — et toutes les commandes, agents et gabarits qui routent emploient ces termes en renvoyant à `AGENTS.md`** — retenue. `AGENTS.md` est chargé par chaque agent, la règle y a une seule rédaction, et un test peut vérifier qu'aucun fichier qui route ne garde sa propre formule.
- **Réécrire la règle complète (surface, `QA stage`, repli sur le texte) dans chaque fichier** — écartée : c'est la duplication qui crée le risque nommé par la story ; dix rédactions divergent au premier correctif.
- **La règle dans la skill `qa-drivers`** — écartée : seul `qa` la précharge ; `/po-drive`, `/po-orchestrator`, `/po-status` et le reviewer ne la lisent pas, et elle ne parle que de QA, pas de design.
- **Un sous-commande `po-gate route <id>` qui lit la ligne `Surface` et `QA stage` et répond mécaniquement** — écartée pour cette story : le repli « son texte montre un écran » reste un jugement qu'un script ne porte pas, et `method/hooks/` n'est pas dans les `Owns`. À reconsidérer quand toutes les stories auront une ligne `Surface`.

## Decision Outcome
Chosen option: **deux termes définis dans `AGENTS.md`**, parce que la règle n'y a qu'une rédaction, que chaque agent la charge déjà, et que les fichiers qui routent se réduisent à « a story with a screen » ou « a story that goes to QA », ce qu'un test fige sans recopier la règle.

- **Has a screen** : sa ligne `Surface` dit `screen`, ou elle n'a pas de ligne `Surface` et son texte montre un écran. Le design s'applique à elle seule.
- **Goes to QA** : `QA stage` vaut `screens` et la story a un écran, ou `QA stage` vaut `surfaces` et sa ligne `Surface` dit autre chose que `—` ; sans ligne `Surface`, elle n'y va que si elle a un écran. Sous `QA stage: —`, aucune story n'y va.
- **`QA stage` absent** : une story qui a un écran ou une `Surface` autre que `—` ne peut pas être routée et s'arrête en nommant le réglage ; toute autre story n'irait en QA sous aucune valeur et continue.

### Consequences
- Good, because une correction future de la règle touche un paragraphe de `AGENTS.md` et rien d'autre, et la table de reprise de `/po-drive`, l'étape 6 de `/po-orchestrator` et `/po-status` disent la même chose par construction.
- Bad, because un lecteur d'une commande doit ouvrir `AGENTS.md` pour savoir ce que « goes to QA » recouvre ; les commandes renvoient à la Loi 1 pour le lui dire.
- Neutral: `/po-qa`, `qa`, `qa-drivers` et `/po-design` gardent leur propre formulation, déjà conforme à ADR-0054 et hors des `Owns` de s80 ; une story qui les toucherait plus tard devrait les ramener aux deux termes.
