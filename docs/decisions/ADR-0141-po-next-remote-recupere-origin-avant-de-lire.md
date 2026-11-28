---
adr: 0141
title: po next --remote récupère origin avant de lire l'atterrissage
status: accepted
date: 2026-11-28
scope: story s218-next-sees-a-human-merge
supersedes: []
superseded-by: []
---

# ADR-0141 — `po next --remote` récupère `origin` avant de lire l'atterrissage

## Context and Problem Statement
Une pull request fusionnée par une personne reste « merge waiting » dans `po next --remote` tant que rien n'a récupéré `origin` (#437) : `po` lit l'atterrissage sur `main` et `origin/main` en local (`po/src/context/lanes.rs:81-91`), ne fait jamais de fetch (`po/src/project.rs:18-19`), et `/po-drive` lance `po next --remote` avant tout fetch (`method/commands/po-drive.md:30`), le seul fetch de la flotte étant parmi les commandes d'ouverture d'une lane (`po/src/next/open.rs:40-42`). Deux ADR acceptées bornent la réponse : l'ADR-0131 fait du titre `<id>: <titre>` sur `origin/<cible>` après un fetch la preuve d'un atterrissage, et écarte l'état `MERGED` de la forge comme preuve ; l'ADR-0130 réserve à `po/src/ship/` le seul lanceur git qui écrit (`po/src/ship/git.rs:1-3`). La story laisse au plan le lieu du fetch : `po` ou `/po-drive`.

## Considered Options
Classées par les critères du porteur : libre ou auto-hébergeable, sobre en matériel, capable de grandir, facile à manier pour une IA. Les trois sont libres et sans service : le premier critère ne les départage pas.

1. **A. `po next --remote` lance `git fetch -q origin` avant de lire**, sous `Merge mode: pr` quand `origin` existe, par une fonction du lanceur de `po/src/ship/git.rs`, qui reste le seul lanceur qui écrit. Un fetch qui échoue ne change rien : `po` lit les références locales, comme aujourd'hui.
   - Pour : la même preuve partout, celle de l'ADR-0131, sur toutes les forges (c'est du git, pas une API) ; tout appelant de `po next --remote` en profite, `/po-drive` comme l'agent extérieur de `docs/interface-agent.md`, sans phrase à suivre ; un script le vérifie (oracle) ; `/po-drive` ne change pas. Le même fetch rafraîchit le point de départ des lanes à ouvrir (#420).
   - Contre : un verbe de lecture écrit des références de suivi (`refs/remotes/origin/*`) et des objets ; la phrase « `po` never fetches » de `project.rs` cesse d'être vraie pour `po next --remote`, et l'écriture déclenchée sort de `po/src/ship/` même si le lanceur y reste ; un aller-retour réseau à chaque `po next --remote`.
2. **B. `/po-drive` lance `git -C <racine> fetch origin` avant chaque `po next --remote`**, quand `origin` existe ; `po` reste en lecture seule hors du ship.
   - Pour : aucune ADR touchée, `po` garde sa règle ; un seul fichier de prose change, dans l'`Owns`.
   - Contre : une règle en prose qu'un modèle peut sauter, qu'aucun script ne vérifie (pas d'oracle, le relecteur juge en lisant) ; un agent extérieur qui lit `po next --remote` sans passer par `/po-drive` garde la réponse fausse ; la direction demande de retirer autant de mots de `po-drive.md` qu'on en ajoute ; même aller-retour réseau que A.
3. **C. `po next --remote` demande aussi à la forge si la pull request est fusionnée** (le champ `merged_at` de l'appel que `Forge::pull_request_closed` fait déjà, `po/src/trust/forge.rs:171-183`), et une lane fusionnée reçoit `ship`, raison `landed` ; `/po-ship` refait la preuve par le titre avant de nettoyer.
   - Pour : aucun appel en plus, aucune écriture git ; la règle de l'ADR-0130 tient.
   - Contre : GitHub seulement (`Forge::of`, `po/src/trust/forge.rs:142-145`) ; une seconde notion de « fusionné », l'état de la forge, que l'ADR-0131 a écartée comme preuve, à côté du titre ; une fusion dont une personne a changé le titre se lirait `landed` puis `not-landed` au nettoyage.

Classement : **A**, puis C, puis B. Sobriété : C ne coûte rien, A et B un fetch ; capacité à grandir : A et B valent sur toute forge, C sur GitHub seule ; maniement par une IA : A et C sont du code vérifié par un script, B une phrase que rien ne vérifie. A passe devant C parce qu'il garde une seule preuve d'atterrissage, celle de l'ADR-0131, et vaut sur toutes les forges ; il est retenu malgré son fetch à chaque appel, le critère « capable de grandir » passant avant le coût d'un aller-retour.

## Decision Outcome
Chosen option: **A**, décision du porteur du 2026-11-28 (d-0064) : `po next --remote` récupère `origin` lui-même, par un lanceur de `po/src/ship/git.rs`.

### Consequences
- Good, because une fusion faite par une personne sort de « merge waiting » au prochain `po next --remote`, et `/po-drive` atteint seul la route `ship` `landed` qui nettoie la lane.
- Bad, because `po next --remote` écrit des références de suivi : la règle de l'ADR-0130 se lit désormais « le seul lanceur git qui écrit vit dans `po/src/ship/` ; seuls les verbes `ship` et `po next --remote` l'appellent », et la ligne `next --remote` de `docs/interface-agent.md` doit dire ce fetch.
- Neutral: B et C restent écartées ; l'oracle `test_human_merge_is_seen` tient le critère sans fetch lancé à la main.
