---
description: Montre la carte de Polype — les étapes d'une story et la règle qui les tient
disable-model-invocation: true
---
# Polype en une page

Reads settings: none

**Aucune modification du code en dehors d'une story**, sauf un correctif rapide que tu annonces toi-même.

## Installation
- `polype install --global` puis `polype init <projet>` — la méthode dans `~/.claude` pour tous les projets, puis l'activation d'un dépôt ; `polype install <projet>` pose tout dans un seul dépôt.
- `polype check` — la version posée et les fichiers qui ont dérivé depuis.

## Mise en place (une fois)
- `/po-setup` — écrit `AGENTS.local.md` : branche cible, mode de merge, qui approuve les plans, commandes du projet.
  - Sans socle, il propose le catalogue de profils de `boilerplates/` et en reprend les commandes.
- `/po-prd <SaaS cible>` — cadre le remplacement (`replace`) ou l'adaptation (`adapt`) d'un SaaS existant, une question à la fois.
- `/po-brief` — met une idée neuve (`new`) à l'épreuve, une question à la fois, jusqu'à un brief approuvé.
- `/po-stories` — découpe le PRD ou le brief approuvé en stories livrables par un agent, dans `docs/stories.md`.
- `/po-stories-review` — fait relire les stories par un subagent en contexte frais, périmètre en main ; verdict dans `docs/reviews/stories.md`.
- `/po-architect` — part du boilerplate du projet, en tire les conventions (règles dans `AGENTS.local.md`) et une ADR par choix structurant ; écrit `docs/architecture.md`.
- `/po-design-system` — recense tokens et composants du socle, mesure une fois les contrastes en clair et en sombre ; écrit `docs/design-system.md`.
- Les stories vont dans `docs/stories.md`, sur le modèle `templates/stories.md`.

## Le cycle d'une story
1. `/po-research <story>` — ouvre le worktree, lit le code réel, vérifie les hypothèses de la story.
   - `/po-design <story>` — pour une story avec écran (`Surface: screen`, ou sans ligne `Surface` un texte qui montre un écran) : dérive l'écran du design system dans `docs/designs/<id>/`.
2. `/po-plan <story>` — découpe en tâches testables, puis approbation.
3. `/po-execute <story>` — l'implementer code, trace ses vérifications, commite.
   - `/po-qa <story>` — pour une story que `QA stage` envoie en QA : un agent vérifie sa surface avec le pilote qui lui va (navigateur, scénarios, rendu de scène, simulation) et laisse ses preuves dans `docs/qa/<id>/`, sans rien corriger. `/po-orchestrator` et `/po-drive` la lancent eux-mêmes quand `QA stage` vaut `screens` (les stories `screen`) ou `surfaces` (toute surface autre que `—`) ; une story sans ligne `Surface` n'y va que si elle a un écran.
4. `/po-review <story>` — relecture par un autre contexte, tests mis à l'épreuve, verdict.
5. `/po-ship <story>` — verdict vérifié, contrôles lourds une fois, squash, nettoyage.

## Outils
- `/po-orchestrator <story>` — choisit la piste (complète ou courte), ajoute le design pour une story avec écran et la QA pour une story que `QA stage` y envoie, enchaîne les étapes et ne s'arrête que pour tes décisions.
- `/po-drive` — la flotte : fait avancer en parallèle toutes les stories prêtes, une lane par story, et ship une par une.
  - `/po-drive status` — le même état en lecture seule : ce qui est en vol, ce qui attend et pourquoi ; ne prépare aucun worktree et ne lance rien.
- `/po-status` — l'état du cadrage, puis de chaque story (piste comprise) et la commande suivante.
- `/po-retro <jalon | premier..dernier>` — résume un jalon ou une plage de stories depuis les revues, les relevés et les rapports QA : sévérités, boucles de correction, revues et QA bloquées, majeurs encore ouverts ; chaque chiffre cite sa ligne, rien n'est écrit.
- `/po-flow <story>` — voie courte pour une petite story : research et plan en une passe, puis le même cycle, sans rien alléger.

## Repères
- Plan non approuvé : pas de code. Verdict négatif : pas de ship.
- Seul un critique bloque. Un majeur est noté et traité plus tard.
- Un bug n'est pas une story : il part dans le tracker d'issues.
