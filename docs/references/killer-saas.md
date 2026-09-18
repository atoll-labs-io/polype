# Référence — Killer SaaS (Mike Codeur)

- Repo : https://github.com/MikeCodeur/killer-saas — étudié au commit `43ec45f` (2026-09-05).
- **Aucun fichier LICENSE** → tous droits réservés par défaut. On reprend des idées et une structure (non protégeables), jamais le texte des commandes, skills ou templates. Tout est réécrit ici.
- Boilerplate associé : ShipSaaS (https://ship-saas.now), payant (299 / 399 / 1 997 €, achat unique). On construit un équivalent fonctionnel, sans son code.

## Idées retenues

- **Pas de code direct** : la commande d'exécution n'a pas les outils d'écriture ; elle délègue à un subagent `implementer`. La règle vit dans les permissions, pas dans la discipline.
- **Le contexte qui écrit ne se relit jamais** : revues en contexte frais, read-only.
- **Fail-closed** : pas de plan validé → pas d'exécution ; un critique en revue → pas de ship.
- **Chaque vérification une seule fois** : suite ciblée par tâche, suite complète et typecheck une fois en fin d'exécution, E2E et build une fois au ship.
- **Gates fichier** (grep sur du markdown) : `validated: yes` dans le plan, `Tree:` du record de vérification égal au commit, `Ship allowed: yes` dans la revue. Portables en hook git et en CI.
- **Preuve de morsure** en revue : neutraliser la ligne dont dépend la story et compter les tests qui virent au rouge. Un garde qu'aucun test ne voit tomber n'est pas testé.
- **Budget de tests** par story au lieu d'un volume maximal.
- **Cycle par story** : Research → Design → Plan → Execute → Review → Ship, plus une voie courte (research+plan fusionnés) pour les stories de complexité 1, avec des signaux d'escalade (migration, nouvel écran, authz/tenant, contrat d'API, nouvelle dépendance).
- **Research vérifie la prémisse** de la story, pas seulement l'existence des symboles, et re-score la complexité après lecture du code.
- **Design** : écran dérivé → deltas sans maquette ; écran nouveau → une seule maquette. Contrastes mesurés une seule fois dans le design system.
- **Settings projet** dans un fichier local (`Name: value`), aucun défaut silencieux ; règles communes assemblées à l'install.
- **État dérivé des fichiers**, jamais stocké.
- **Un défaut n'est pas une story** : il va dans le tracker d'issues.
- **PRD de kill** : cible, mode (remplacement interne / produit concurrent), boucle cœur 20 %, features scorées 1–5, cimetière explicite, angle au-delà de la parité.
