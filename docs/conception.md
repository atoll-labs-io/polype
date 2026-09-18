# Conception — agentic-saas

Statut : brouillon (2026-09-18). Les décisions structurantes passeront par `/record-adr` une fois tranchées.

## Objectif

Remplacer `/spec` et `/drive` (skills globaux actuels) par une méthode complète qui couvre, pour un SaaS, tout le trajet : choix du point d'entrée, cadrage, architecture sur un boilerplate imposé, design system, puis construction story par story par une flotte d'agents, jusqu'à la production. D'autres méthodes spécialisées pourront suivre sur le même moteur.

## Ce que chaque source apporte

| Brique | Killer SaaS | `/spec` + `/drive` actuels | agentic-saas |
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

## Questions ouvertes

1. **Noms** : méthode, trois modes, boilerplate, préfixe des commandes.
2. **Un repo ou deux** : méthode et boilerplate ensemble (conventions et règles d'architecture versionnées d'un bloc) ou séparés (le boilerplate vit sa vie de template).
3. **Stockage et jobs** : services managés (Supabase, Inngest) comme ShipSaaS, ou briques auto-hébergeables (S3 compatible, queue sur Postgres) cohérentes avec le reste d'Atoll.
4. **Décisions** : ADR dans le repo du projet (`docs/decisions/`, lisibles par les workers) ou dans le vault + Graphiti (existant), ou les deux avec un pointeur.
5. **Tracker** : garder GitHub Issues / Taskwarrior pour l'état, ou état dérivé des fichiers comme Killer SaaS.
6. **Distribution** : installation globale (`~/.claude`) qui remplace `/spec` et `/drive`, par projet, ou les deux ; synchronisation via chezmoi.
7. **Codex** : support dès le départ ou plus tard.
