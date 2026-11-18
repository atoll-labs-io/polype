---
adr: 0130
title: Le ship entre dans po, par un verbe ship à sous-étapes
status: accepted
date: 2026-11-18
scope: story s192-ship-reads-the-forge
supersedes: []
superseded-by: []
---

# ADR-0130 — Le ship entre dans `po`, par un verbe `ship` à sous-étapes

## Context and Problem Statement
#211 retire de `/po-ship` les opérations qu'un modèle refait de mémoire à chaque ship : la lecture de la forge (s192), la porte et le commit d'atterrissage (s193), l'envoi, la pull request et la fusion (s194), le dépôt des constats (s195), le nettoyage (s196). `po-ship.md` compte 3 302 mots, dont 844 pour la seule règle de la forge (`method/commands/po-ship.md:24-48`). Deux questions sont au porteur (ADR-0077) avant le plan de s192, parce que les `Owns` de s192 à s196 en dépendent :

1. ce code entre-t-il dans le binaire `po`, qui aujourd'hui n'écrit aucun état git (`po/src/project.rs:18-19` : « `po` never fetches, pulls, pushes nor writes »), ou dans un script à part ;
2. quelle forme prend la commande : un verbe `ship` à sous-étapes, plusieurs verbes, ou une commande qui enchaîne tout.

L'ADR-0116 a mis dans le binaire tout le code que M21 ajoutait, parce que les verbes partageaient leurs structures ; elle ne parlait que de M21. s192 lui-même ne fait que lire : quelle que soit l'option, sa sous-étape n'écrit rien. Les écritures git et l'envoi arrivent avec s193 et s194.

## Considered Options
Classées par les critères du porteur : libre ou auto-hébergeable, sobre en matériel, capable de grandir, facile à manier pour une IA. Les quatre sont libres et sans service ; `po` est déjà posé sur chaque machine (ADR-0117) et un script bash l'est aussi par l'installeur : les deux premiers critères ne les départagent pas. Le classement se fait sur les deux derniers.

1. **A. Dans `po`, un verbe `ship` à sous-étapes** — `po ship forge` (s192, sans id : `/po-setup` s'en sert aussi), puis `po ship land <id>` (s193), `po ship push <id>` (s194), `po ship file <id>` (s195), `po ship clean <id>` (s196). Chaque sous-étape rend un objet JSON ; `/po-ship` les enchaîne et garde le jugement (description de la pull request, constats retenus pour la personne, confirmation `Merge / Not now`).
   - Pour : la forme de `po record review|qa` (`po/src/record/mod.rs:80-100`), déjà connue des commandes. Une famille, un nom : un modèle trouve chaque étape sous `ship`. Les étapes partagent leurs types (forge, réglages, preuve d'atterrissage) et le compilateur les tient. Chaque story ajoute une sous-étape sans réécrire les précédentes. Les `Owns` de s193 à s196 restent tels qu'écrits.
   - Contre : à partir de s193, `po` écrit des commits et pousse : la phrase de `project.rs:18-19` cesse d'être vraie pour `po/src/ship/`, et un défaut du binaire peut désormais toucher la forge. Il faut un second lanceur git, réservé à `po/src/ship/`, le lanceur en lecture seule restant tel quel. Chaque story monte la version (ADR-0122) et les cinq passent une à une, ce qui est déjà le cas.
2. **B. Dans `po`, plusieurs verbes de premier niveau** — `po forge`, `po land <id>`, `po push <id>`, `po file-findings <id>`, `po clean <id>`.
   - Pour : des commandes plus courtes ; mêmes types partagés et même compilateur que A ; `Owns` de s193 à s196 inchangés.
   - Contre : cinq verbes de plus dans l'usage de `po`, à côté des verbes du contrat de [`interface-agent.md`](../interface-agent.md), sans rien qui dise qu'ils forment le ship ; `po forge` se lit comme une question générale à la forge. Mêmes écritures et mêmes montées de version que A.
3. **C. Dans `po`, une seule commande `po ship <id>` qui enchaîne tout et reprend d'après ce qu'elle trouve** (fichiers, références, pull request), s'arrêtant à chaque point de jugement avec ce qu'il manque.
   - Pour : un seul appel pour le modèle, relancé jusqu'au bout ; la reprise après interruption (critère de s194) est au cœur de la commande.
   - Contre : les points de jugement demandent des entrées (le fichier de description, la liste des constats retenus) : la commande prend de toute façon des options par étape. `/po-setup` lit la forge sans story : il faut une seconde entrée. s192 livrerait un `po ship <id>` qui ne fait que lire la forge, puis chaque story réécrirait l'enchaînement ; une étape ne s'essaie plus seule.
4. **D. Un script bash à part** (`method/hooks/po-ship.sh`, posé comme `po-gate`), qui appelle `git`, `gh`, `glab`, `tea`, `curl` et `jq`.
   - Pour : pas de compilation, pas de montée de version de `po` ; les stories du ship ne partagent plus le crate avec les autres stories de `po`. Les hooks en bash écrivent déjà (`po-run` écrit le relevé).
   - Contre : le JSON est écrit et relu en `jq`, le contrat deux fois, ce que l'ADR-0116 écartait ; trois forges analysées en `jq`, sans types ; le jeton manié en bash. Les `Owns` de s192 à s196 sont à reprendre en cadrage avant leur plan : plus de `po/src/ship/`, `po/src/main.rs` ni `po/Cargo.*`, mais le script, sa pose dans `bin/polype` et ses tests.

Classement : **A**, puis B, C et D. A, B et C grandissent pareil sur le troisième critère, D moins (pas de types, `jq`) ; sur le quatrième, A donne une famille nommée et une étape essayable seule, B disperse cinq verbes, C cache l'état d'avancement dans la commande, D remet un modèle devant de la prose et du `jq`.

## Decision Outcome
Chosen option: **A**, par le porteur le 2026-11-18 (décision d-0041 de la boîte), l'option que le planner recommandait : une famille nommée, des étapes essayables une à une, et les `Owns` de s193 à s196 tels qu'écrits. Le plan de s192 est écrit pour elle : la sous-étape `po ship forge` dans `po/src/ship/`, la lecture de la forge appuyée sur `po/src/trust/forge.rs`.

### Consequences
- Good, because la règle de la forge n'est plus écrite qu'une fois, en code, et `/po-ship` comme `/po-setup` lisent sa sortie au lieu de la réinterpréter.
- Good, because s193 à s196 gardent leurs `Owns` et ajoutent chacune une sous-étape.
- Bad, because à partir de s193 le binaire écrit sur git et sur la forge : sa phrase « `po` never … writes » devient fausse pour `po/src/ship/`, et le relecteur de s193 et s194 doit vérifier que l'écriture ne sort pas de ce dossier.
- Neutral: si le porteur retient D, les `Owns` de s192 à s196 se reprennent en cadrage avant tout plan ; s'il retient B ou C, seul le nom de la commande change dans le plan de s192 et dans son oracle (la fonction `forge_read` de `tests/ship-reads-the-forge.oracle.test.sh` porte seule la forme de la commande).
