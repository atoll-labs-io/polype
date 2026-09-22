# Catalogue de boilerplates — Polype

Un boilerplate n'est utile aux agents que s'ils le lisent tous de la même façon. Le **profil** le décrit une fois pour toutes (ADR-0008) : le setup y prend les commandes du projet, l'architecture le découpage et les briques, le planner et l'implementer la place de chaque règle et les pièges connus.

## Le profil

- Il vit dans `boilerplates/<nom>/profile.md`, à côté de `method/` (ADR-0001).
- Son format est fixé par `method/templates/profile.md`, en huit sections : identité et licence, commandes, carte du code, granularité d'ownership, où vit chaque règle, capacités et briques, inventaire UI, pièges connus.
- La section commandes porte exactement les noms des réglages `Install`, `Test`, `Typecheck`, `E2E` et `Build` d'`AGENTS.local.md`, pour que leurs valeurs y soient recopiées telles quelles.
- La table des capacités ne reprend que les noms de la liste d'ADR-0020 (Database, Auth, Authorization, Multi-tenancy, Files, Jobs, Email, Payment, Cache and rate limiting, Observability, i18n, Deployment) ; un profil ne garde que les lignes qu'il fournit.
- `bin/po-lint` vérifie chaque `boilerplates/*/profile.md` contre ce gabarit : une section absente, une commande mal nommée ou une capacité inconnue fait échouer le lint, qui nomme le fichier et la ligne. Sans dossier `boilerplates/`, il n'y a rien à vérifier.

## Capacités et briques

- Les briques par défaut, leurs alternatives, le moment d'en changer et ce que prouve un test de contrat vivent dans `method/skills/capability-bricks/SKILL.md`, repris d'ADR-0020.
- `/po-architect` compare les briques d'un profil à ce tableau, retient une brique par capacité et enregistre chaque écart dans l'ADR de projet de cette capacité.
- Les noms de capacités d'un profil sont les douze de ce skill, dans le même ordre.

## Trois niveaux de boilerplate

La flotte ne fait tourner deux stories ensemble que si les chemins qu'elles possèdent sont disjoints (ADR-0007). Le boilerplate retenu fixe donc le parallélisme qu'un projet peut atteindre.

| Niveau | Ce que c'est | Coût en parallélisme |
|---|---|---|
| **maison** | Un boilerplate Polype, en modules verticaux `src/modules/<domaine>/` avec un noyau partagé `src/core/` (ADR-0007). | Le plus faible : une story possède un module, les stories de modules différents tournent ensemble ; seules celles qui touchent au noyau passent seules. |
| **tiers profilé** | Un boilerplate externe du catalogue, qui garde son architecture ; son profil déclare la granularité d'ownership qu'il permet. | Dépend de cette granularité : des paquets fins laissent tourner beaucoup de stories à la fois, des paquets larges les font s'attendre les unes les autres. |
| **aucun** | Un scaffold par défaut, sans profil, analysé par `/po-architect`. | Le plus élevé au départ : l'ownership n'est connu qu'une fois le code écrit, les premières stories passent pour l'essentiel l'une après l'autre. |
