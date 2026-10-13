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
Research ─ Design ─ Plan ─ Execute ─ Review ─ Ship (un commit par PR, ADR-0080)
à la demande : revue transverse (/roast-me)
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

La méthode ne dépend pas d'un boilerplate précis. Elle dépend de ce qu'elle sait **du** boilerplate ([ADR-0008](decisions/ADR-0008-catalogue-de-profils-gratuits-dabord.md)). Chaque entrée du catalogue est décrite par un **profil** que tous les agents lisent :

- **Commandes** : install, test ciblé, suite complète, typecheck, E2E, build. Citées telles quelles, jamais inventées.
- **Carte** : où vit chaque chose (routes, domaines, noyau partagé, migrations, policies, composants UI).
- **Granularité d'ownership** : quel chemin une story peut posséder seule.
- **Règles** : où une règle métier est testée, ce qui ne doit jamais être contourné (tenant, autorisation).
- **Capacités** : quelles capacités il fournit, avec quelles briques ([ADR-0009](decisions/ADR-0009-briques-optimales-interchangeables.md)).
- **Inventaire UI** : composants et tokens disponibles pour le design system.
- **Origine et licence**.

On commence par des boilerplates **open source**. Les boilerplates maison naîtront des projets, quand l'un d'eux aura un socle réutilisable (et suivront alors [ADR-0007](decisions/ADR-0007-modules-verticaux.md)). Sans boilerplate, la méthode marche encore, mais les fondations (auth, tenant, billing) deviennent des stories séquentielles avant tout parallélisme.

### Candidats gratuits (relevé du 2026-09-18, tous MIT)

| Boilerplate | Framework | Auth | Données | Billing | Multi-tenant | Remarque |
|---|---|---|---|---|---|---|
| **next-forge** (Vercel) | Next.js, Turborepo | Clerk (hébergé) | Prisma + Neon | Stripe | via Clerk | **un package par capacité** (auth, database, payments, storage, email, observability…) |
| **ixartz/SaaS-Boilerplate** | Next.js | Clerk (hébergé) | Drizzle + Postgres | Stripe | via Clerk | i18n, Sentry, Storybook, Vitest + Playwright |
| **nextjs/saas-starter** | Next.js | maison (JWT) | Drizzle + Postgres | Stripe | équipes | minimal, moins actif (dernier push 2025-12) |
| **Open SaaS** (Wasp) | Wasp (React + Node) | intégrée | Prisma + Postgres | Stripe, Lemon Squeezy ou Polar | non | S3, jobs pg-boss, paiement déjà interchangeable |
| **Epic Stack** | React Router | maison (TOTP, passkeys) | Prisma + SQLite/LiteFS | non | non | culture de test de référence, orienté Fly.io |

## Capacités et briques

Chaque capacité a une interface, une brique par défaut choisie pour être optimale pour notre usage, et des briques alternatives activées par configuration quand un hébergeur l'impose ([ADR-0009](decisions/ADR-0009-briques-optimales-interchangeables.md)). Chaque interface a un jeu de tests de contrat que toutes ses briques passent.

Capacités à couvrir : base de données, auth, autorisation, multi-tenant, fichiers, jobs, email, paiement, cache, observabilité, i18n, déploiement.

## Cible de déploiement

- **Prototypes** : mustelinet, cloud OpenStack d'un ami (voir [références](references/mustelinet.md)). VM, volumes et Kubernetes managé ; pas de base ni de stockage objet managés, donc hébergés par nous ; publication HTTP/HTTPS seulement.
- **Production** : un gros hébergeur, choisi une fois le SaaS viable. Il se traduira par des briques de déploiement et, au besoin, des briques managées (base, fichiers) à la place des briques auto-hébergées.

## Décisions prises

- Nom de la méthode : **Polype**.
- [ADR-0001](decisions/ADR-0001-un-seul-repo-methode-et-boilerplates.md) — un seul repo pour la méthode et les boilerplates.
- [ADR-0002](decisions/ADR-0002-adr-projet-dans-le-repo.md) — les ADR d'un projet vivent dans son repo, pointeur Graphiti.
- [ADR-0003](decisions/ADR-0003-etat-dans-github-ou-taskwarrior.md) — l'état du travail vit dans GitHub Issues ou Taskwarrior.
- [ADR-0004](decisions/ADR-0004-installation-globale-toutes-machines.md) — installation globale synchronisée par chezmoi.
- [ADR-0005](decisions/ADR-0005-codex-differe.md) — Codex vers mi-octobre 2026.
- [ADR-0006](decisions/ADR-0006-adapter-killer-saas-sans-copie.md) — on adapte Killer SaaS en s'en inspirant fortement, sans copie ; qualité prouvée par une matrice de parité.
- [ADR-0007](decisions/ADR-0007-modules-verticaux.md) — boilerplates maison en modules verticaux avec couches internes.
- [ADR-0008](decisions/ADR-0008-catalogue-de-profils-gratuits-dabord.md) — catalogue de boilerplates décrits par profils, open source d'abord, maison au fil des projets.
- [ADR-0009](decisions/ADR-0009-briques-optimales-interchangeables.md) — techno optimale par capacité, briques interchangeables selon l'hébergeur.
- [ADR-0010](decisions/ADR-0010-next-forge-premier-profil.md) — next-forge comme premier boilerplate profilé.
- [ADR-0011](decisions/ADR-0011-usage-cible-et-distribution.md) — B2C d'abord, auto-hébergé en avant, offre gérée par abonnement et à l'usage.
- [ADR-0012](decisions/ADR-0012-pas-de-rouge-dabord.md) — pas de rouge-d'abord à l'implémentation, preuve de morsure en revue.
- ~~ADR-0013~~ — remplacée par ADR-0015.
- ~~ADR-0014~~ — remplacée par ADR-0017.
- ~~ADR-0015~~ — remplacée par ADR-0080.
- [ADR-0016](decisions/ADR-0016-flotte-un-driver-des-subagents.md) — la flotte est un driver unique qui lance des subagents en parallèle ; l'état se lit dans les worktrees et git (encore `status: proposed` alors que M3 l'a implémentée).
- [ADR-0017](decisions/ADR-0017-validation-groupee.md) — validation des plans groupée par vague, ship story par story (remplace ADR-0014).
- [ADR-0080](decisions/ADR-0080-tout-arrive-sur-la-branche-cible-par-une-pr-en-fast-forward.md) — chaque story arrive sur la branche cible en un commit, par une PR, et aucun agent ne pousse sur elle (remplace ADR-0015).

## Qualité

La [matrice de parité](parite-killer-saas.md) liste chaque mécanisme de Killer SaaS et son traitement dans Polype. Chaque ligne devient un critère d'acceptation des stories de Polype. `bin/ks-overlap` vérifie à chaque milestone qu'aucun texte n'est repris.

## Questions ouvertes

1. **Catalogue de capacités** : brique par défaut de chaque capacité, à la lumière d'ADR-0011.
2. **Noms** : au fil de l'eau.
