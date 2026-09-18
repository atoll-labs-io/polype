---
description: Affiche le pipeline Polype — l'ordre des étapes et la règle unique
disable-model-invocation: true
---
# Polype — le pipeline

Reads settings: none

**Règle unique : aucun code hors pipeline.** Chaque changement qui n'est pas un correctif rapide annoncé est une story, et une story passe par toutes les étapes.

## Une fois par projet
0. `/po-setup` — réglages du projet (`AGENTS.local.md`) : où atterrit une story, qui valide un plan, commandes du projet
1. Les stories, dans `docs/stories.md` (gabarit `templates/stories.md`)

## Pour chaque story
2. `/po-research <story>` — worktree dédié, code réel, prémisses vérifiées
3. `/po-plan <story>` — tâches courtes et vérifiables, puis validation
4. `/po-execute <story>` — l'implementer code, enregistre ses runs, un seul commit
5. `/po-review <story>` — relecture en contexte frais, preuve de morsure, verdict
6. `/po-ship <story>` — gate, contrôles coûteux une seule fois, squash, nettoyage sur merge prouvé

## Utilitaires
- `/po-orchestrator <story>` — tout le cycle d'une story, avec les checkpoints humains
- `/po-status` — où en est chaque story, et la prochaine commande

## À retenir
- Pas de plan validé → pas de code. Pas de `Ship allowed: yes` → pas de ship.
- Seul un critique bloque ; un majeur est tracé et corrigé au cycle suivant.
- Un défaut n'est pas une story : il va dans le tracker d'issues.
