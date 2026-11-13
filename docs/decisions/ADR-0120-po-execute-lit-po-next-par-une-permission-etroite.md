---
adr: 0120
title: /po-execute lit po next par une permission étroite
status: accepted
date: 2026-11-14
scope: story s173-drive-executes-next
supersedes: []
superseded-by: []
---

# ADR-0120 — `/po-execute` lit `po next` par une permission étroite

## Context and Problem Statement
`/po-execute` n'a ni Write, ni Edit, ni Bash, et c'est voulu : le contexte qui coordonne une story ne peut pas en écrire le code (Law 2). `bin/po-lint` et trois tests tiennent cette règle. Lancée seule, la commande ouvre pourtant un fix run sur toute revue qui porte `Ship allowed: no`, y compris celle que `po-gate findings-shape` a bloquée et qui attend une personne (#139). Depuis s168, `po next` calcule l'action juste pour cet état : `ask`. s173 demande que `/po-execute` lise cette réponse, ce qui suppose de lancer une commande.

## Considered Options
1. **Une permission étroite : `/po-execute` peut lancer `po next`, et rien d'autre.** La ligne d'`allowed-tools` nomme le binaire et le verbe, comme `/po-review` nomme `po-gate findings-shape` et `po record review`. `po next` ne fait que lire : la commande ne gagne aucun moyen d'écrire un fichier.
2. **Garder `/po-execute` sans shell et lire l'arrêt dans le fichier de revue.** Sa précondition reconnaît, dans le texte de la revue, le rapport bloqué par la forme des constats. Corrige #139 sans toucher à la règle, mais la règle de routage reste écrite en prose à un endroit de plus, que le code calcule déjà.
3. **Laisser l'implementer lancer `po next`.** Écartée : quand l'implementer démarre, le fix run est déjà choisi.

## Decision Outcome
Chosen option: **l'option 1**, choisie par le porteur le 2026-11-14 (décision d-0008 de la boîte), contre la recommandation du chef de projet, qui proposait l'option 2 comme la moins chère. Sa raison : la règle vit dans le code, pas dans une phrase qu'un modèle réinterprète, ce qui est l'objet de M21. La garantie de la Law 2 tient parce que la permission ne couvre qu'un verbe qui lit.

La permission nomme `po next` et ce verbe seul : ni `po` entier, ni un Bash nu. `bin/po-lint` et les tests qui interdisent un shell à `/po-execute` acceptent cette ligne et refusent toute autre.

### Consequences
- Good, because `/po-execute` lancé seul et `/po-drive` lisent la même réponse pour le même état.
- Bad, because une règle écrite de la méthode gagne une exception, que `bin/po-lint` doit connaître par son nom.
- Bad, because rien ne prouve encore qu'une permission étroite de cette forme correspond à la commande réellement lancée (constat « Not verified » de la revue de s167) : si elle ne correspond pas, `/po-execute` demande une confirmation, ce qui gêne une flotte sans surveillance. À vérifier au premier usage réel.
- Neutral: toute autre commande sans shell reste sans shell ; une nouvelle exception demande une nouvelle ADR.
