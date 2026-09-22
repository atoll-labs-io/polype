# Milestones — Polype

Un milestone livre un incrément utilisable. Chaque story atterrit sur la branche cible dès que sa revue l'autorise (ADR-0015) ; on corrige au fil de l'eau. Pas de sprint : la cadence est celle des décisions, pas du calendrier.

| Milestone | Livre | Lignes de la [matrice](parite-killer-saas.md) | Statut |
|---|---|---|---|
| **M1 — Le cycle** | Règles, réglages, research → plan → execute → review → ship sur une story, gates, doctrines test et revue | A, B, D (hors design, voie courte et flotte), E, F, G | livré |
| **M2 — Le cadrage** | Trois modes d'entrée, stories et leur revue, architecture, design system, design par story, voie courte | C, D03, D15 | livré |
| **M3 — La flotte** | Lanes parallèles, tracker GitHub/Taskwarrior, reprise après crash, checkpoints groupés | D05, D16, D17, extensions | livré |
| **M4 — Le catalogue** | Profil next-forge, briques auto-hébergées pour mustelinet, tests de contrat | ADR-0008 à ADR-0011 | à faire |
| **M5 — La distribution** | Installation globale chezmoi + `init` par projet, mise à jour par manifeste, migration depuis `/spec` et `/drive` | H | à faire |
| **M6 — Le pilote** | Un vrai SaaS construit avec Polype, comparé à Killer SaaS | validation | à faire |

**Amorçage** : M1 est construit à la main en appliquant les règles de Polype (une story, un commit, revue en contexte frais). À partir de M2, Polype construit Polype.

Préfixe provisoire des commandes : `/po-*`, renommable quand les noms seront choisis.
