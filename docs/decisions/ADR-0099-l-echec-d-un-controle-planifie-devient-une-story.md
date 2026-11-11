---
adr: 0099
title: L'échec d'un contrôle planifié devient une story de correction
status: accepted
date: 2026-11-11
scope: story s152-intake-issue-becomes-a-story
supersedes: [ADR-0090]
superseded-by: []
---

# ADR-0099 — L'échec d'un contrôle planifié devient une story de correction

## Context and Problem Statement
L'ADR-0090 garde « only a person turns a finding into a story » : faire d'un défaut une story reste une décision de la personne. Depuis s151, `po-intake` dépose l'échec d'un contrôle planifié dans `Issue tracker` ; cet échec attend donc qu'une personne le cadre, et la boucle de l'échec à la correction s'arrête là. Le porteur a décidé le 2026-11-10 que cette boucle se ferme seule, toutes les portes restant en place (issue #154).

## Considered Options
- **A. `/po-intake` fait de chaque échec déposé une story de correction.** Une story par issue `polype-intake` qu'aucune story ne cite, avec une ligne `Fixes`, le comportement faux et l'attendu, la reproduction et un `Owns` tiré des chemins que l'échec met en cause ; le `stories-reviewer` juge ces seules stories, chacune sur son issue, et seules des stories prêtes atterrissent, comme un cadrage ; une issue qui touche la sécurité va à la personne. Retenue, par le porteur, 2026-11-10.
- **B. L'issue seule, cadrée par une personne au jalon suivant.** Écartée : la boucle reste lente, un échec de la nuit attend le prochain cadrage pour être corrigé.
- **C. Une autonomie selon la sévérité.** Écartée : une échelle de plus à tenir, alors qu'un échec de contrôle n'a pas de sévérité à lui et que la relecture des stories dit déjà si une story est prête.

## Decision Outcome
Option choisie : **A** (porteur, 2026-11-10).

- Elle remplace l'ADR-0090 sur ce seul point : la Law 7 garde « only a person turns a finding into a story » et nomme l'échec d'un contrôle planifié déposé par `po-intake` comme sa seule exception. Les constats de revue, les idées et les autres défauts restent des issues qu'une personne seule fait devenir des stories. Le reste de l'ADR-0090 tient, la sécurité allant toujours à la personne.
- Toutes les portes restent : la story passe par le plan, l'exécution, la revue et le ship comme une autre, et `Ship confirmation` s'applique à l'atterrissage de ses stories comme à toute fusion. Portant `Fixes`, elle prend la voie complète et le skill `diagnostic` : la cause est prouvée avant tout correctif, et l'ADR-0070 rend la story à une personne après trois hypothèses écartées.
- La relecture se fait sur l'issue, qui tient lieu de PRD ou de brief, sans contrôle de couverture du reste du fichier ; son verdict est écrit dans `docs/reviews/stories-intake-<horodatage>.md`, un fichier de cadrage de la Law 6. Un verdict qui ne dit pas les stories prêtes n'en fait rien atterrir.
- La pull request de cadrage cite les issues sans mot-clé de fermeture : une issue se ferme quand sa correction est livrée, pas quand sa story est écrite.

### Consequences
- Good, because un échec de la nuit devient une story que `/po-drive` peut prendre dès le cadrage fusionné, sans que personne ait à l'écrire.
- Bad, because un `Owns` déduit d'une sortie de contrôle peut être trop étroit ou trop large ; la relecture des stories et le planner sont là pour le dire.
- Neutral: une commande qui tourne sans personne ne peut rien demander : ce qu'elle retient pour la personne part dans sa sortie, donc dans le journal de l'ordonnanceur.
