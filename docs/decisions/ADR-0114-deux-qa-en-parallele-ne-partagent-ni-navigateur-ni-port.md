---
adr: 0114
title: Deux QA en parallèle ne partagent ni navigateur ni port
status: accepted
date: 2026-11-13
scope: story s163-qa-lanes-isolated
supersedes: []
superseded-by: []
---

# ADR-0114 — Deux QA en parallèle ne partagent ni navigateur ni port

## Context and Problem Statement
`/po-drive` lance tous les `qa` d'une vague ensemble (`method/commands/po-drive.md:101`, `:107`), et chacun hérite de l'unique outil navigateur de la session (ADR-0026, `method/agents/qa.md:22`) et lance `Dev` sans port qui lui soit propre (`method/skills/qa-drivers/browser.md:10`). Sur clione, les 24 et 25 octobre 2026, deux lanes ont partagé le même navigateur et le port 4321 ; un appel bloqué a tenu une QA toute la nuit (#149). La règle en prose « Your own tabs » (`method/skills/design-doctrine/SKILL.md:42`) n'a pas suffi : un outil qui n'a qu'un onglet courant ne se partage pas par une consigne. La story s163 fixe le résultat : un navigateur et un port par lane, un délai par action.

## Considered Options
Rangées d'après les critères du porteur (`capability-bricks`, `## Ranking the options`) : toutes sont libres et locales ; elles diffèrent sur la sobriété, la tenue à l'échelle et la facilité pour un agent.
- **A. Navigateur privé dès que le projet a un paquet d'automatisation, sinon le navigateur de la session tant qu'aucune autre lane n'est en QA, su par un marqueur.** Le dossier `mktemp -d` de `qa-drivers` prend un nom fixe, `polype-qa-<id>.XXXXXX` sous `${TMPDIR:-/tmp}`, et sert de marqueur ; port tiré du chemin du worktree ; 120 secondes par action, sous `timeout` ou le délai du script.
- **B. Navigateur privé toujours.** Plus simple ; mais un projet sans paquet d'automatisation perd sa QA d'écran même seul en QA, ce qui marche aujourd'hui.
- **C. Le pilote donne à chaque lane son port et lui dit si une autre est en QA, par son prompt.** Écartée : `po-drive.md` et le prompt mot pour mot de `po-qa.md` sont hors du `Owns` de s163, et une lane lancée par `/po-qa` seule ne recevrait rien.
- **D. Sérialiser les QA dans `/po-drive`.** Écartée : hors `Owns`, et la flotte perd le parallélisme qu'elle a pour raison d'être (ADR-0016).

## Decision Outcome
Chosen option: **A**, parce que c'est la seule qui tient chaque critère de s163 dans les fichiers que la story possède sans retirer à un projet seul en QA ce qui marche aujourd'hui, et que le délai ne s'impose qu'à une action lancée par Bash ou par un script, ce que le navigateur privé est.

### Consequences
- Good, because deux lanes n'ont plus rien en commun : ni navigateur, ni profil (`TMPDIR` pointe le dossier de la lane), ni port ; un port déjà pris arrête la lane au lieu d'être réutilisé.
- Bad, because une lane qui retombe sur le navigateur de la session reste exposée à un appel d'outil qui ne rend pas la main : aucun agent n'interrompt un appel en cours, et le délai ne vaut que pour Bash et les scripts.
- Bad, because un dossier `polype-qa-*` laissé par une lane tuée fait croire à une QA en cours : une lane sans paquet s'arrête en `blocked`, et son rapport nomme le dossier trouvé pour qu'une personne le retire.
- Neutral: deux worktrees dont le `cksum` tombe sur le même port (une chance sur 10 000) se bloquent l'un l'autre au lieu de partager un serveur. ADR-0026 reste vraie : la QA hérite toujours des outils de la session, elle cesse seulement d'utiliser le navigateur partagé quand une autre lane est en QA ou qu'un paquet du projet lui en donne un à elle.
