---
adr: 0094
title: La forme des constats d'une revue se contrôle à l'enregistrement
status: accepted
date: 2026-10-16
scope: story s141-review-findings-shape
supersedes: []
superseded-by: [ADR-0096]
---

# ADR-0094 — La forme des constats d'une revue se contrôle à l'enregistrement

## Context and Problem Statement
Le reviewer de s137 a écrit ses deux constats en titres (`### F1: major. …`). L'étape 3.2 de `/po-ship` ne lit que des éléments de liste ouverts par leur sévérité, et son filet ne voit pas les titres : aucun des deux constats n'a été déposé, et rien ne l'a signalé (issue #112). Le gabarit `templates/review.md` ne montrait d'ailleurs pas la forme lue par `/po-ship`. Le porteur a décidé le 2026-10-16 : un gabarit qui montre la ligne exacte, plus un contrôle déterministe dès l'enregistrement de la revue, le reviewer étant réinterrogé sur une forme fautive. Reste à fixer comment `/po-review`, qui n'a pas de shell, lance ce contrôle.

## Considered Options
Où se contrôle la forme :
- **A. À l'enregistrement, par `po-gate findings-shape <id>`.** Lancé par le contexte qui enregistre la réponse du reviewer ; un échec la renvoie une fois au reviewer, au même `Fix loop:`, sans dépenser d'unité de `Max attempts` ; un second échec va à la personne par un rapport bloqué écrit dans la revue, qui survit à une reprise. Retenue, par le porteur.
- **B. Le gabarit seul.** Écartée : un modèle remplit un gabarit librement, et la dérive revient d'une revue à l'autre ; s137 l'a montré, une revue mal formée passe sans que personne le voie.
- **C. Un refus au ship par `po-gate ship-allowed`.** Écartée : plus tard et plus brutal. La forme se découvre quand la revue est close et le reviewer parti, et une question de format arrête une livraison dont le code a été jugé bon.

Comment `/po-review` lance le contrôle, ses outils étant Read, Glob, Grep, Agent et Write (`tests/review.test.sh` exige qu'il n'ait pas `Bash`, et la convention du dépôt refuse Bash aux commandes qui n'écrivent pas de code). Les trois options sont égales sur les premiers critères du porteur (libre, auto-hébergeable, sobre, extensible) ; elles se classent sur la facilité pour une IA et l'accord avec les conventions :
1. **Une permission Bash restreinte à cette seule commande** : `Bash(.polype/hooks/po-gate.sh findings-shape:*)` dans `allowed-tools`. `/po-review` ne gagne aucun shell libre et ne peut toujours pas toucher au code ; le test et la convention gardent leur sens. Coût : un motif de permission nouveau dans la méthode, et un `cd <worktree> &&` devant la commande que le harnais doit accepter (au pire, une demande de permission, puisque les `allowed-tools` d'une commande pré-autorisent sans restreindre, ADR-0027).
2. **Bash entier pour `/po-review`.** Plus simple à écrire, mais la commande peut alors modifier n'importe quel fichier ; il faut changer `tests/review.test.sh:38` et la convention, hors du `Owns` de s141.
3. **`/po-review` applique les trois règles lui-même, avec Grep.** Aucun outil nouveau, mais deux lectures de la même règle, l'une déterministe, l'autre laissée au modèle : elles divergeront, ce que l'option A veut justement éviter.

## Decision Outcome
Option choisie : **A** (porteur, 2026-10-16). Pour `/po-review` : option 1, une permission Bash réduite à `.polype/hooks/po-gate.sh findings-shape` (porteur, 2026-10-16).

- `po-gate findings-shape <id>` lit `## Findings` du dernier bloc de `docs/reviews/<id>.md`, celui qui finit par son dernier `Ship allowed:`, jusqu'au titre `## ` suivant. Il sort 1 en citant chaque ligne fautive, numéro et texte, dans trois cas : un titre (ligne qui commence par `#`) qui contient une sévérité ; un élément de liste dont la première ligne contient une sévérité sans s'ouvrir par elle ; une ligne hors liste, non indentée, qui s'ouvre par une sévérité, nue ou en gras. Il sort 1 aussi sans section `## Findings`. Une sévérité est `critical`, `major` ou `minor`, mot entier, toute casse. Une ligne indentée est une ligne de suite, acceptée. L'emplacement `<chemin>:<ligne>` n'est pas contrôlé.
- Le gabarit montre la ligne `- <critical|major|minor> — <path>:<line> — <the problem>`, un constat par élément, jamais en titre ; le reviewer y renvoie, et son rapport bloqué garde une section `## Findings`.
- Le filet de l'étape 3.2 de `/po-ship` attrape aussi un titre qui contient une sévérité ; la phrase « No critical or major finding. » reste hors du filet.

### Consequences
- Good, because une revue mal formée est reprise par son auteur pendant que le contexte existe encore, et qu'aucun constat n'échappe au dépôt sans que la personne le sache.
- Bad, because une forme fautive coûte un appel de reviewer de plus, et des formes qu'un humain lit sans peine (`- **m1 (minor):**`, `### Critical`) sont refusées : le contrôle suit ce que `/po-ship` sait lire, pas ce qu'un humain comprend.
- Neutral: les revues déjà enregistrées ne sont pas réécrites ; plusieurs échoueraient au contrôle. `/po-orchestrator` lit encore « Any other blocked review » comme un fix run lors d'une reprise : à suivre dans `Issue tracker`.
