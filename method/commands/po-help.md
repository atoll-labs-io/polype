---
description: Montre la carte de Polype — les étapes d'une story et la règle qui les tient
disable-model-invocation: true
---
# Polype en une page

Reads settings: none

**Aucune modification du code en dehors d'une story**, sauf un correctif rapide que tu annonces toi-même.

## Mise en place (une fois)
- `/po-setup` — écrit `AGENTS.local.md` : branche cible, mode de merge, qui approuve les plans, commandes du projet.
- `/po-prd <SaaS cible>` — cadre le remplacement (`replace`) ou l'adaptation (`adapt`) d'un SaaS existant, une question à la fois.
- `/po-brief` — met une idée neuve (`new`) à l'épreuve, une question à la fois, jusqu'à un brief approuvé.
- `/po-stories` — découpe le PRD ou le brief approuvé en stories livrables par un agent, dans `docs/stories.md`.
- `/po-stories-review` — fait relire les stories par un subagent en contexte frais, périmètre en main ; verdict dans `docs/reviews/stories.md`.
- Les stories vont dans `docs/stories.md`, sur le modèle `templates/stories.md`.

## Le cycle d'une story
1. `/po-research <story>` — ouvre le worktree, lit le code réel, vérifie les hypothèses de la story.
2. `/po-plan <story>` — découpe en tâches testables, puis approbation.
3. `/po-execute <story>` — l'implementer code, trace ses vérifications, commite.
4. `/po-review <story>` — relecture par un autre contexte, tests mis à l'épreuve, verdict.
5. `/po-ship <story>` — verdict vérifié, contrôles lourds une fois, squash, nettoyage.

## Outils
- `/po-orchestrator <story>` — enchaîne les cinq étapes et ne s'arrête que pour tes décisions.
- `/po-status` — l'état de chaque story et la commande suivante.

## Repères
- Plan non approuvé : pas de code. Verdict négatif : pas de ship.
- Seul un critique bloque. Un majeur est noté et traité plus tard.
- Un bug n'est pas une story : il part dans le tracker d'issues.
