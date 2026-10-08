---
adr: 0068
title: Une story de défaut porte une ligne Fixes et passe par la voie complète sous la skill diagnostic
status: accepted
date: 2026-10-08
scope: story s90-diagnostic-skill
supersedes: []
superseded-by: []
---

# ADR-0068 — Une story de défaut porte une ligne `Fixes` et passe par le diagnostic

## Context and Problem Statement
La loi 7 tient les défauts hors de `docs/stories.md`, sauf quand une personne en fait une story. Polype en écrit déjà (`docs/stories.md:319`, `:675`, la ligne `**Corrige**`), mais ni `method/templates/stories.md` ni `agentic-stories` ne définissent cette ligne : un projet qui suit le gabarit ne l'écrit jamais, et rien ne dit au planner qu'une story corrige un défaut (relecture M8, `docs/reviews/stories-m8.md:204`). s90 ajoute une procédure de diagnostic ; il faut fixer ce qui la déclenche, sur quelle voie, et où son résultat s'écrit.

## Considered Options
- **Reconnaître un défaut au texte de la story** — un déclencheur que personne ne voit ni ne teste ; deux agents liraient le même texte différemment.
- **Une ligne `Corrige` seulement** — le gabarit et les fichiers de la méthode sont en anglais ; un projet anglophone écrirait une étiquette française.
- **Une ligne `Fixes`, lue aussi sous la forme `Corrige`** — retenu : même usage que `Complexity`/`Complexité`, que `/po-execute` lit déjà sous ses deux formes.
- **Diagnostic aussi sur la voie courte** — `/po-flow` n'écrit pas de fichier de recherche et tourne dans le contexte principal, qui ne précharge aucune skill ; les hypothèses écartées et la preuve n'auraient pas de place.
- **Un subagent de diagnostic à part** — un contexte de plus qui relirait le code que le planner vient de lire ; la cause racine appartient à la recherche.

## Decision Outcome
Chosen option: **une ligne `Fixes`, lue aussi sous la forme `Corrige`**, parce que le déclencheur devient une donnée écrite, vérifiable et testable, comme `Surface` (ADR-0054).

- Une story qui corrige un défaut porte `- **Fixes**: <le défaut et où il est consigné>` (`Corrige` dans un fichier de stories rédigé en français) ; le gabarit de stories et `agentic-stories` la définissent, facultative.
- Cette ligne est un signal d'escalade de plus : `/po-flow` et le planner envoient la story en voie complète, quels que soient `Story track` et `Flow threshold`. Les textes cessent de compter leurs signaux et les énumèrent.
- Le planner précharge la skill `diagnostic` et l'applique pendant la recherche : reproduire, écrire la cause racine avec sa preuve dans `docs/research/<id>.md`, puis seulement planifier le correctif et le test qui aurait attrapé le défaut. Trois hypothèses écartées arrêtent la recherche : pas de plan, un rapport qui le dit.

### Consequences
- Good, because aucun correctif n'est planifié sans une cause montrée, et le déclencheur se lit sans interprétation.
- Bad, because un défaut minuscule paie la voie complète, et `/po-stories` doit penser à écrire la ligne.
- Neutral: `/po-research` lancé à la main ne précharge pas la skill ; seul le planner (flotte) l'applique d'office. La ligne D15 de `docs/parite-killer-saas.md` parle encore de cinq signaux : hors du périmètre de s90.
