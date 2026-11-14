---
adr: 0124
title: Les constats ordinaires d'une revue où la lentille sécurité a tourné sont déposés
status: accepted
date: 2026-11-14
scope: story s179-ship-files-the-other-findings
supersedes: [ADR-0090]
superseded-by: []
---

# ADR-0124 — Les constats ordinaires d'une revue où la lentille sécurité a tourné sont déposés

## Context and Problem Statement
L'ADR-0090, acceptée, retient tous les constats d'une revue dont la lentille Security a tourné (`Consequences`, « Un constat d'une revue dont la lentille Security a tourné, ou dont le texte touche la sécurité, n'est jamais déposé seul »). `/po-ship` l'applique à son étape 3 (`method/commands/po-ship.md`). Le texte de la revue était public : un constat ordinaire pouvait laisser deviner une faiblesse que le relecteur n'avait pas isolée. Depuis l'ADR-0123, le relecteur marque `[security]` tout constat de sécurité, quelle que soit la lentille qui l'a trouvé. `po record review` en retire le texte et ne laisse dans la revue que `Security findings: <n> — decision <d-NNNN>`. Le motif de la retenue par lentille disparaît. La retenue, elle, reste : depuis le 2026-10-14, aucun constat ordinaire de s170, s173, s177 ni s178 n'est arrivé dans le tracker. Il a fallu une décision à la main (d-0006) pour déposer ceux de s165 à s167. L'ADR-0123 précise que le reste de l'ADR-0090 tient. Lever cette retenue est donc une décision de sécurité, qui revient au porteur (ADR-0077). La note de jalon de M21 bis la range sous D7 b ; le journal des décisions (2026-11-14) dit qu'elle a été annoncée au porteur sans réponse de sa part.

## Considered Options
Classées par les critères du porteur : open source ou auto-hébergeable, sobre, passant à l'échelle, facile à manier pour un agent. Les trois options sont de la prose de méthode, sans brique ni coût : les deux premiers critères ne les départagent pas.

- **A. Lever la retenue par lentille.** `/po-ship` dépose les constats ouverts d'une revue même quand la lentille sécurité a tourné. Il retient un constat qui porte la marque `[security]`, ce qu'un `po` antérieur à l'ADR-0123 laisse dans la revue publique, ainsi qu'un constat dont le texte touche la sécurité : un secret ou un jeton, un contrôle d'autorisation ou de tenant, une injection. Il cite la ligne `Security findings:` telle qu'elle est écrite, sans jamais ouvrir la décision.
  - Pour : passe à l'échelle sans geste de la personne. La règle se lit sur le constat lui-même, plus sur la revue entière. Elle suit la Loi 7 (« tout ce qui est à traiter est déposé ») et la réponse d-0006, où le porteur a fait déposer à la main les constats que la lentille retenait.
  - Contre : un constat ordinaire qui touche à la sécurité sans que le relecteur l'ait marqué n'est retenu que par le jugement de l'agent qui livre. C'était déjà le cas pour les revues sans lentille.
- **B. Garder la retenue par lentille** (statu quo). s179 se borne à citer la ligne de compte et à la faire compter par `/po-retro`.
  - Pour : aucun constat d'une revue sensible ne part, même mal classé par le relecteur.
  - Contre : les constats ordinaires de ces revues ne vont dans aucun tracker, ce que la Loi 7 interdit. Il faut une décision à la main chaque fois (d-0006), et la retenue n'a plus de texte à protéger.
- **C. Demander à la personne revue par revue.** `/po-ship` pose dans la boîte une décision qui liste les titres des constats ordinaires d'une revue à lentille sécurité, et ne dépose qu'après sa réponse.
  - Pour : la personne voit chaque cas.
  - Contre : une question par livraison concernée. Cela ne passe pas à l'échelle d'une flotte, et la question répète ce que A tranche une fois pour toutes.

## Decision Outcome
Option choisie : **A**, par le porteur le 2026-11-14 (décision d-0023 de la boîte). Seuls les constats de sécurité restent retenus : ceux qui portent la marque `[security]` et ceux dont le texte touche la sécurité. Les autres sont déposés, quelle que soit la lentille qui a tourné. C'est la seule des trois options qui passe à l'échelle et dépose ce que la Loi 7 demande, sans rien perdre de ce que l'ADR-0123 protège.

L'ADR-0090 ajoute ADR-0124 à sa ligne `superseded-by`, sans que son corps change. Le reste de l'ADR-0090 tient, dont « un constat de sécurité n'est jamais déposé seul ».

### Consequences
- Good, because les constats ordinaires d'une revue sensible reviennent dans le tracker sans geste de la personne, et la revue publique, la pull request, les issues et le journal ne portent d'un constat de sécurité que son compte et l'identifiant de sa décision.
- Bad, because un constat de sécurité que le relecteur n'a pas marqué n'est plus retenu que si son texte le montre.
- Neutral: les trois règles qui en découlent (`/po-ship`, `/po-drive`, `/po-retro`) sont lues par un modèle : elles sont candidates à un bras de contrôle `po-eval` (#208).
