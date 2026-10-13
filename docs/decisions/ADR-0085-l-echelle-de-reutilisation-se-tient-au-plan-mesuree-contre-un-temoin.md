---
adr: 0085
title: L'échelle de réutilisation se tient au plan, se juge en revue et se mesure contre un témoin, sans hook permanent
status: accepted
date: 2026-10-13
scope: story s113-reuse-ladder
supersedes: []
superseded-by: []
---

# ADR-0085 — L'échelle de réutilisation se tient au plan, mesurée contre un témoin

## Context and Problem Statement
Un plan surdimensionné passe aujourd'hui tel quel à l'implementer, qui fait ce que dit le plan et rien d'autre (`method/agents/implementer.md:51`). Rien n'oblige à dire ce qu'on aurait pu réutiliser. La revue ne relève que les dépendances qui en doublonnent une autre (`method/skills/review-lenses/SKILL.md:54`), jamais un utilitaire réécrit. L'idée vient de Ponytail (`DietrichGebert/ponytail`) : une échelle qui va de ce qui existe déjà vers le code neuf. Reste à savoir où la tenir dans le cycle, et comment savoir si elle sert à quelque chose.

## Considered Options

Les options sont classées selon les critères du porteur : open source ou auto-hébergeable, sobre, scalable, facile à manipuler pour une IA. Toutes sont du texte de méthode, sans dépendance. Elles se départagent sur la sobriété en contexte et sur ce qu'un agent peut vérifier.

- **A. Échelle au plan, jugée en revue, mesurée contre un témoin.** Les gabarits de plan portent une section `## Reuse`, et le planner, `/po-plan` et `/po-flow` l'exigent. L'étape 3 de `review-antihallu` classe **majeur** un code neuf que fournissait déjà un existant, et juge l'écart entre `## Reuse` et le diff comme un écart à une tâche. s114 mesure ensuite la règle contre un bras témoin « Follow YAGNI. ». Si elle ne le bat pas, une story suivante la retire. Coût : une section par plan, lue une fois. La revue peut comparer une trace écrite au diff. Recommandée.
- **B. Une seule ligne « Follow YAGNI. » dans les consignes.** C'est la plus sobre, mais elle ne laisse aucune trace que la revue puisse comparer au diff. C'est le témoin de s114, qui la mesure, plutôt qu'une option à retenir d'emblée.
- **C. La revue seule, sans section au plan.** Le code surdimensionné n'est relevé qu'une fois écrit, ce qui coûte une boucle de correction à chaque fois. Sans trace au plan, l'écart ne se juge pas comme un écart à une tâche.
- **D. Des hooks permanents, comme chez Ponytail.** Un rappel serait injecté à chaque session ou à chaque édition. C'est la couverture la plus continue, mais la moins sobre : du contexte payé à chaque appel, et un réglage de plus à tenir dans `po-bounds` ou les settings. Le mécanisme sortirait aussi du moment où l'on décide quoi écrire.
- **E. L'échelle dans l'implementer.** Elle contredit « Do what the plan says and nothing else » (`implementer.md:51`). Le choix de réutiliser reviendrait à celui qui écrit le code, sans plan validé pour le dire, et il échapperait au point de contrôle du plan.

## Decision Outcome
Option choisie : **A**, retenue par le porteur le 2026-10-13 (ADR-0077). Elle place l'échelle là où se décide ce qui sera écrit, au coût d'une section par plan. Elle donne à la revue une trace à comparer au diff, et elle ne se garde que si la mesure de s114 la montre meilleure qu'une ligne.

### Consequences
- Good, because chaque code neuf d'un plan dit pourquoi l'existant, la bibliothèque standard et les dépendances installées ne suffisent pas, et la revue peut le contester.
- Bad, because chaque plan s'allonge d'une section, même d'une ligne quand il n'écrit rien de neuf, dans les limites de la Loi 6.
- Neutral: la règle reste provisoire jusqu'aux taux de s114 (`docs/evals/reuse-ladder.md`). L'étape 3 garde la phrase sur une ligne à elle, pour que le bras témoin la remplace exactement.
