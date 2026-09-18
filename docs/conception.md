# Conception — Polype

Statut : brouillon (2026-09-18). Les décisions structurantes passeront par `/record-adr` une fois tranchées.

## Objectif

Remplacer `/spec` et `/drive` (skills globaux actuels) par une méthode complète qui couvre, pour un SaaS, tout le trajet : choix du point d'entrée, cadrage, architecture sur un boilerplate imposé, design system, puis construction story par story par une flotte d'agents, jusqu'à la production. D'autres méthodes spécialisées pourront suivre sur le même moteur.

## Ce que chaque source apporte

| Brique | Killer SaaS | `/spec` + `/drive` actuels | Polype |
|---|---|---|---|
| Choix du point d'entrée | kill uniquement (2 modes) | idée neuve uniquement | **remplacer / adapter / partir de zéro** |
| Cadrage produit | PRD de kill : cible, boucle cœur, cimetière | interrogation sceptique, carte des manques, pre-mortem | les deux, selon le mode |
| Boilerplate | proposé à l'architecture | absent (scaffold ad hoc) | **socle maison imposé** (voir plus bas) |
| Design system + maquettes | oui, contrastes mesurés une fois | absent | repris |
| Cycle par story | research → design → plan → execute → review → ship | packet → worker → verify → merge | cycle complet, **exécuté par la flotte** |
| Parallélisme | stories en parallèle, worktree par story | lanes par `owns`, worktrees, branche d'intégration | lanes + ownership de `/drive` |
| Revue | contexte frais, anti-hallucination, preuve de morsure | reviewer frais contrat + diff | anti-hallucination + preuve de morsure |
| Doctrine de tests | budget, chaque check une fois | tests d'acceptation d'abord | doctrine Killer SaaS + acceptation exécutable |
| Gates | fichiers + hook git + CI | vérif par le driver | fichiers + hook git + CI |
| Suivi | fichiers dans `docs/`, état dérivé | GitHub Issues (octo) / Taskwarrior (sensei) | contrats dans `docs/`, état dans le tracker |
| Décisions | ADR dans `docs/decisions/` | `/record-adr` vault + Graphiti | à trancher (voir questions ouvertes) |
| Multi-outil | Claude Code + Codex | Claude Code | Claude Code d'abord |

## Pipeline cible

```
Setup ─ choix du mode ─┬─ Remplacer ─┐
                       ├─ Adapter ───┼─ Stories ─ Revue stories ─ Architecture (boilerplate) ─ Design system
                       └─ Zéro ──────┘
puis, par story (en parallèle, une lane par ownership disjoint) :
Research ─ Design ─ Plan ─ Execute ─ Review ─ Ship (merge dans la branche d'intégration)
fin de milestone : revue transverse (/roast-me) ─ PR humaine vers main
```

- **Remplacer** : PRD de kill, mode remplacement interne. Parité fonctionnelle sur la boucle cœur, cimetière assumé.
- **Adapter** : PRD de kill, mode produit concurrent, plus l'angle différenciant formulé comme stories à part entière et challengé comme une idée neuve (forcing questions ciblées sur l'angle).
- **Partir de zéro** : interrogation `/spec` complète, brief approuvé, puis stories.

## Boilerplate — premier socle

Équivalent fonctionnel de ShipSaaS, écrit ici :

- Next.js (dernière version stable au moment du build, vérifiée via context7), React, TypeScript strict
- Postgres + Drizzle ORM, migrations versionnées
- Auth : Better Auth — email/mot de passe, OAuth, 2FA/OTP, sessions
- Autorisation : RBAC par CASL, policies testées à un seul endroit
- Multi-tenant : organisations/workspaces isolés, invitations, rôles par org
- Billing : Stripe — abonnements, coupons, factures, webhooks idempotents
- Stockage fichiers, jobs asynchrones, i18n (next-intl), formulaires (React Hook Form + Zod)
- UI : Tailwind + shadcn/ui, thèmes clair/sombre, design system documenté
- Admin : utilisateurs, organisations, revenus
- Architecture en couches Presentation → Service → Persistence, découplées et testables
- Tests : Vitest (unitaires/intégration), Playwright (E2E), CI
- `AGENTS.md` et conventions prêts pour les agents

## Catalogue de boilerplates

La méthode ne dépend pas d'un boilerplate précis. Elle dépend de ce qu'elle sait **du** boilerplate. Chaque entrée du catalogue est donc décrite par un **profil** que tous les agents lisent :

- **Commandes** : install, test ciblé, suite complète, typecheck, E2E, build. Citées telles quelles, jamais inventées.
- **Carte** : où vit chaque chose (routes, domaines, noyau partagé, migrations, policies, composants UI).
- **Granularité d'ownership** : quel chemin une story peut posséder seule (`src/modules/<domaine>/` pour un boilerplate vertical, beaucoup plus grossier pour un horizontal).
- **Règles** : où une règle métier est testée, ce qui ne doit jamais être contourné (tenant, autorisation).
- **Inventaire UI** : composants et tokens disponibles pour le design system.
- **Origine et licence** : maison (vendorisé dans `boilerplates/`), open source (référencé par URL et version), payant (l'utilisateur apporte sa copie, Polype ne fournit que le profil).

Trois niveaux :

| Niveau | Exemple | Profil | Efficacité de la flotte |
|---|---|---|---|
| **Maison** | Carapace (nom provisoire) | écrit et testé avec la méthode | maximale : modules verticaux, tests et E2E prêts |
| **Tiers profilé** | MakerKit, next-forge, ShipSaaS | généré par l'analyse de code à l'étape architecture, puis validé par l'utilisateur | dépend de son architecture et de ses tests |
| **Sans boilerplate** | repo vide | scaffold par défaut | la plus basse : les fondations (auth, tenant, billing) deviennent des stories séquentielles avant tout parallélisme |

## Cible de déploiement

- **Prototypes** : chez un ami (mustelinet). **Production** : un gros hébergeur, choisi plus tard, une fois le SaaS viable.
- **Principe retenu en proposition** : ne s'appuyer que sur des standards qu'on retrouve partout. Postgres pour les données **et** les jobs (file dans Postgres type pg-boss ou Graphile Worker), l'API S3 pour les fichiers, une image conteneur comme artefact de déploiement (Next.js en sortie `standalone`). Aucune fonctionnalité propre à une plateforme serverless.
- Conséquence : migrer du prototype à la production revient à changer des variables d'environnement (URL Postgres, endpoint S3), pas à réécrire du code.

## Décisions prises

- Nom de la méthode : **Polype**.
- [ADR-0001](decisions/ADR-0001-un-seul-repo-methode-et-boilerplates.md) — un seul repo pour la méthode et les boilerplates.
- [ADR-0002](decisions/ADR-0002-adr-projet-dans-le-repo.md) — les ADR d'un projet vivent dans son repo, pointeur Graphiti.
- [ADR-0003](decisions/ADR-0003-etat-dans-github-ou-taskwarrior.md) — l'état du travail vit dans GitHub Issues ou Taskwarrior.
- [ADR-0004](decisions/ADR-0004-installation-globale-toutes-machines.md) — installation globale synchronisée par chezmoi.
- [ADR-0005](decisions/ADR-0005-codex-differe.md) — Codex vers mi-octobre 2026.
- [ADR-0006](decisions/ADR-0006-adapter-killer-saas-sans-copie.md) — on adapte Killer SaaS en s'en inspirant fortement, sans copie ; qualité prouvée par une matrice de parité.
- [ADR-0007](decisions/ADR-0007-modules-verticaux.md) — boilerplates maison en modules verticaux avec couches internes.

## Questions ouvertes

1. **Catalogue** : valider le principe des profils et des trois niveaux ci-dessus.
2. **Déploiement** : valider le principe « standards uniquement » ; confirmer ce que mustelinet fournit (conteneurs ? Postgres managé ? stockage S3 ?).
3. **Noms** des trois modes, du boilerplate maison et du préfixe des commandes, une fois les questions boilerplate closes.
