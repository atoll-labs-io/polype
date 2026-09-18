# agentic-saas

> Nom de travail. L'usine d'Atoll : une méthode de dev agentique qui emmène un SaaS de l'intention à la production, portée par des agents Claude Code encadrés par des gates mécaniques.

**Statut** : conception. — `project:agentic-saas` sous `+atoll`.

## Trois points d'entrée

| Objectif | Point de départ | Cadrage |
|---|---|---|
| **Remplacer** un SaaS existant | Un SaaS que je paie et veux internaliser | Analyse de la cible, boucle cœur (20 %), cimetière des features lourdes |
| **Adapter** un SaaS existant | Un concurrent à reprendre avec un angle propre | Idem + l'angle au-delà de la parité, devient des stories dédiées |
| **Partir de zéro** | Une idée sans cible à copier | Interrogation sceptique, carte des manques, pre-mortem, puis brief |

Les trois convergent vers le même tronc : architecture sur un boilerplate imposé, design system, puis un cycle par story exécuté en parallèle par une flotte d'agents.

## Contenu prévu

- `method/` — commandes, skills, subagents, templates et règles installables dans un projet ou globalement.
- `boilerplates/` — socles de départ ; le premier est un fullstack Next.js SaaS complet (auth, billing, multi-tenant, admin, tests).
- `install.sh` — installation projet / globale, mise à jour sans fantômes.

Conception détaillée : [docs/conception.md](docs/conception.md).

## Inspiration

Méthode [Killer SaaS](https://github.com/MikeCodeur/killer-saas) de Mike Codeur et boilerplate [ShipSaaS](https://ship-saas.now). Aucun contenu n'en est copié : voir [docs/references/killer-saas.md](docs/references/killer-saas.md).
