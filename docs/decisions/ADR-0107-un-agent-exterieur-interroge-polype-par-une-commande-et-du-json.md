---
adr: 0107
title: Un agent extérieur interroge Polype par une commande et du JSON
status: proposed
date: 2026-11-12
scope: framing
supersedes: []
superseded-by: []
---

# ADR-0107 — Un agent extérieur interroge Polype par une commande et du JSON

## Context and Problem Statement
L'agent vocal local du porteur n'est que son majordome : l'intelligence est déléguée à Claude ou à un autre grand modèle, et Polype est de ce côté-là. Un agent extérieur doit donc pouvoir demander où en est un projet, ce qui attend le porteur, rapporter sa réponse et lancer ou reprendre le travail, sans lire de prose ni tenir une conversation avec le chef de projet (#204). Aujourd'hui, ce qui attend la personne n'existe que dans le texte d'une session. Trois choses sont à décider : le transport, l'endroit où vit la boîte de décisions, et la façon de lancer une session. Le contrat lui-même est dans [`docs/interface-agent.md`](../interface-agent.md).

## Considered Options
Classées par les critères du porteur : libre ou auto-hébergeable, sobre en matériel, capable de grandir, facile à manier pour une IA.

**Transport**
1. **Une commande par projet, sortie JSON, état dans des fichiers** (`.polype/hooks/po-agent.sh <verbe>`) — aucun service qui tourne, lisible par n'importe quel agent qui sait lancer une commande, par SSH comme en local, testable par la suite existante.
2. **Un serveur MCP** — outils typés, découverts par les agents qui parlent MCP. Un processus de plus à tenir, et un agent sans MCP n'y accède pas ; il peut se poser plus tard comme une couche mince sur l'option 1.
3. **Un démon HTTP** — interrogeable du réseau. Demande un port, une authentification et un service à surveiller, pour un usage à un seul porteur.
4. **La forge seule** (issues étiquetées comme boîte de décisions) — rien à écrire. Publie ce qui attend sur un dépôt public, dépend d'un fabricant, et un constat de sécurité ne peut pas y aller (ADR-0090).

**Boîte de décisions**
1. **Des fichiers JSON locaux, hors de git** (`.polype/inbox/`, ignoré) — une décision par fichier, visible dès qu'elle est posée sans attendre un atterrissage, et un sujet sensible ne quitte pas la machine. Rien n'est partagé entre deux machines ; la trace durable est ce que la réponse produit (ADR, story, ligne de plan), qui cite l'identifiant de la décision.
2. **Des fichiers suivis par git sous `docs/`** — trace durable et partagée. Chaque question demanderait une pull request, et un sujet sensible serait publié.
3. **Le dossier d'état de l'utilisateur** (`~/.local/state/polype/`) — hors de tout dépôt. Un agent extérieur doit alors connaître deux endroits par projet.

**Lancement**
1. **`claude --bg` depuis la racine du projet**, une seule session de chef de projet à la fois — c'est déjà la façon de travailler du porteur ; la session se suit par `claude agents`, `claude attach`, `claude logs`.
2. **`claude -p`** — sans session à suivre. Les bornes des subagents n'y sont pas tenues avec une installation par projet (`docs/installation.md`, « Limite de confiance »).
3. **Un programme sur l'Agent SDK** — écarté avec l'option 3 de l'ADR-0106.

## Decision Outcome
Proposé, à trancher par le porteur. Recommandation : **l'option 1 de chaque groupe**. Une commande et des fichiers suffisent à un porteur seul, ne coûtent rien quand rien ne tourne, et gardent les sujets sensibles sur la machine. `run` refuse de lancer quand il ne peut pas prouver que les bornes seront tenues. Un serveur MCP reste possible ensuite, comme couche mince.

### Consequences
- Good, because le majordome n'a rien à comprendre de Polype : il lit du JSON, répète une question, rapporte le nom d'une option.
- Good, because une réponse hors des options listées est refusée par un script, pas par un modèle.
- Bad, because la boîte ne se partage pas entre machines : le porteur répond sur la machine où tourne le projet, ou par SSH.
- Neutral: le contrat porte un numéro de version ; un champ ajouté ne le change pas, un champ retiré ou renommé si.
