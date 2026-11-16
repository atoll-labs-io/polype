---
adr: 0127
title: Une décision périmée est signalée
status: accepted
date: 2026-11-16
accepted: 2026-11-16
decisions: [d-0032, d-0033]
scope: story s186-stale-decisions-are-flagged
supersedes: []
superseded-by: []
---

# ADR-0127 — Une décision périmée est signalée

## Context and Problem Statement
Une décision de la boîte peut porter sur une story qui est livrée avant que le porteur réponde : ses options parlent alors d'un état qui n'existe plus. C'est arrivé le 2026-11-14 : d-0022, posée à 17:10 sur un constat de sécurité mineur de s178, proposait « Le corriger dans s178 » ; s178 a été livrée à 17:30 ; le porteur a répondu `a` à 18:15, et le chef de projet a dû comprendre « le corriger dans une nouvelle story », devenue s180 (#331). Aujourd'hui rien ne le signale : `po state` et `po inbox` listent une décision `pending` sur son seul statut (`po/src/state/mod.rs:57-64`, `po/src/inbox/mod.rs:159`), et `po answer` ne vérifie que le statut et la clé (`po/src/inbox/mod.rs:55-71`).

Deux questions sont à trancher. La première vient de la recherche de s186 : d-0022 avait `"blocks": []`, parce qu'un constat mineur ne retient pas sa lane (d-0021) ; `po record review` pose encore cette forme (`po/src/record/security.rs:186`). Une règle qui ne lit que `blocks`, celle qu'écrit la story, ne l'aurait pas marquée. La seconde est celle de la story : ce que fait `po answer` d'une décision périmée.

## Considered Options

### Question 1 — Comment une décision connaît sa story
Les trois options sont du code de `po`, sans service ni matériel : les deux premiers critères du porteur ne les départagent pas ; le troisième (grandir) et le quatrième (facile pour une IA) décident. Ordre : 1-A, 1-B, 1-C.

- **1-A. Un champ facultatif nomme la story d'origine** (`story`), distinct de `blocks` : `po inbox add` l'accepte, `po record review` le remplit avec la story revue.
  - Pour : d-0022 et toute décision de sécurité mineure sont couvertes ; le champ est lisible tel quel par un agent ; ajouter un champ garde `contract` à `1` (d-0012).
  - Contre : la story s'élargit d'un fichier, `po/src/record/security.rs` ; une décision posée à la main par le chef de projet n'est couverte que s'il pense à remplir le champ, ce que rien ne contrôle.
- **1-B. `blocks` seul**, comme la story l'écrit.
  - Pour : aucun champ nouveau ; l'`Owns` de s186 suffit.
  - Contre : le cas qui a ouvert #331 reste invisible, ainsi que toute décision de sécurité mineure à venir ; le défaut paraît corrigé sans l'être.
- **1-C. Lire la story dans le texte de la question**, que `po record review` commence par `<id>:` (`po/src/record/security.rs:172`).
  - Pour : aucun champ nouveau.
  - Contre : `po` interprète une phrase libre ; une question écrite par le chef de projet (« La revue de s178… », d-0022) n'est pas reconnue ; une reformulation casse la règle sans qu'aucun test le voie.

### Question 2 — Ce que fait `po answer` d'une décision périmée
Même lecture des critères. Ordre : 2-A, 2-C, 2-B.

- **2-A. Enregistrer la réponse, et la rendre avec la marque.** La décision passe à `answered` ; le chef de projet, en la consommant, voit la marque et relit la réponse contre ce qui a été livré.
  - Pour : la boucle de l'agent extérieur ne change pas ; ce que le porteur a dit n'est jamais perdu ; c'est ce qui s'est passé à la main pour d-0022.
  - Contre : la réponse peut vouloir dire autre chose que l'option enregistrée ; la relecture repose sur le chef de projet, un modèle.
- **2-C. Refuser, sauf confirmation explicite** : `po answer <id> <key>` refuse (code 1, erreur nouvelle) ; l'agent le dit au porteur, puis repasse la réponse avec une option de confirmation.
  - Pour : le porteur répond en sachant que la story est livrée.
  - Contre : une option nouvelle sur un verbe du contrat et un aller-retour de plus pour l'agent ; une fois confirmée, la réponse a le même sens incertain qu'en 2-A.
- **2-B. Refuser** : code 1, erreur nouvelle listée dans `docs/interface-agent.md`, la décision reste `pending`.
  - Pour : aucune réponse n'est jamais enregistrée sur une option fausse.
  - Contre : aucun verbe ne retire une décision `pending` (`po inbox consume` la refuse, `po/src/inbox/mod.rs:87-89`) : elle reste dans `waiting` et au démarrage de chaque session tant que personne n'édite le fichier ; le chef de projet doit reposer la question, et ce que le porteur voulait dire est perdu.

## Decision Outcome
Options choisies : **1-A** et **2-A**, par le porteur le 2026-11-16 (décisions d-0032 et d-0033 de la boîte), comme cette ADR les recommandait. Il en connaissait le coût : la story s'élargit d'un fichier, et une décision posée à la main n'est couverte que si le champ est rempli (1-A) ; la clé enregistrée peut vouloir dire autre chose que l'option stockée, et la relecture repose sur le chef de projet qui voit la marque (2-A). 1-B ne couvrait pas le cas de #331 ; 1-C faisait lire une phrase libre à `po`. 2-C et 2-B ajoutaient un aller-retour ou laissaient une décision morte.

Ce que la story s186 en fixe :
- **Le champ** : `story`, facultatif, absent du fichier quand il n'est pas donné. `po inbox add` l'accepte quand il a la forme d'un id de story (`s<nombre>-<slug>`) et refuse toute autre valeur par `malformed-decision`. `po record review` le remplit avec la story relue quand il pose la décision d'un constat de sécurité. Une décision écrite sans ce champ se lit comme avant.
- **La règle** : une décision `pending` est périmée quand elle nomme au moins une story, sa story d'origine et celles de `blocks` réunies, et que toutes sont livrées. Une entrée de `blocks` qui n'a pas la forme d'un id de story est une étape de cadrage : elle empêche la marque, quelles que soient les stories nommées par ailleurs. Une décision qui ne nomme aucune story n'est jamais marquée.
- **La marque** : `"stale": true` sur l'objet décision, présente seulement sur une décision périmée, calculée à la lecture contre les stories livrées sur `Target branch` et jamais écrite dans le fichier, une story pouvant être livrée après lui. `po inbox` et `po inbox <id>` la portent ; `po state` liste les `id` des décisions périmées dans un champ `stale` à part, `waiting` restant une liste d'`id`. `po answer` enregistre la réponse à une décision périmée et rend la décision avec la marque : c'est le seul endroit où une décision `answered` la montre.
- **Ce qui ne change pas** : `po next` ; une décision retient ses lanes jusqu'à sa consommation, périmée ou non.

### Consequences
- Good, because un porteur à qui un agent lit `po inbox` apprend qu'une décision est périmée avant d'y répondre, et le chef de projet qui lit la réponse de `po answer` sait qu'il doit la relire contre ce qui a été livré.
- Bad, because une décision posée à la main sans `story` n'est signalée que par `blocks`, tant qu'aucune règle de la méthode ne demande de remplir le champ ; et `po-session` ne montre pas la marque.
- Neutral: `po inbox` lit désormais les stories livrées par `git log` sur `Target branch` ; sans ce réglage, aucune décision n'est marquée et rien n'est refusé.
