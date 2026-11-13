# La direction de Polype

Écrit le 2026-11-12, après une analyse indépendante du projet demandée par le porteur. Ce document dit où va Polype et ce qu'il ne fait plus ; il ne répète ni les règles ([`AGENTS.md`](../AGENTS.md)), ni les stories ([`stories.md`](stories.md)), ni les décisions ([`decisions/`](decisions/)).

## Ce qu'est Polype

Polype est une brique indépendante, du côté de l'intelligence : il cadre un produit, le découpe, le fait construire et relire par des agents, et ne laisse rien atterrir sans preuve. Il ne suppose aucune installation particulière chez celui qui l'utilise. La personne qui porte un projet peut lui parler dans une session, ou passer par un agent extérieur quelconque — une interface de discussion, un ordonnanceur, ou par exemple un assistant vocal local qui ne fait que transmettre et laisse l'intelligence à un grand modèle. Cet agent demande à Polype où en est un projet, rapporte ce qui attend la personne, transmet sa réponse et relance le travail ; il n'a aucune intelligence à fournir. Polype doit donc offrir une vraie interface, pas de la prose ([`interface-agent.md`](interface-agent.md)). Aucun document de la méthode ne nomme une installation précise : un exemple d'installation reste un exemple.

## Le constat

Les principes tiennent : rien hors d'une story, celui qui écrit ne juge pas, des portes fermées tant qu'un fichier ne les ouvre pas, un worktree par story. L'exécution a dérivé :

- la confiance est prouvée sur le texte de la méthode, pas sur le comportement des agents : environ 600 assertions cherchent une phrase dans un fichier ([`defauts.md`](defauts.md), motif récurrent, dès septembre) ;
- le pilote de la flotte est une machine à états écrite en prose, qu'un modèle réinterprète à chaque vague ;
- aucune intégration continue : la suite tourne sur la machine de celui qui livre, et `main` a été rouge deux fois ;
- les bornes des subagents ne sont pas tenues dans une session `claude -p` avec une installation par projet ([`installation.md`](installation.md)) ;
- 158 stories livrées sur la méthode pour 79 sur les produits.

## La direction

Ce qu'un script peut décider ou écrire quitte la prose et le modèle. La méthode ne grandit plus que tirée par un produit ([ADR-0108](decisions/ADR-0108-un-jalon-de-methode-nait-d-un-defaut-vu-sur-un-produit.md)), ou d'une décision stratégique écrite du porteur.

| Jalon | Ce qu'il livre | État |
| --- | --- | --- |
| **M20 — Le ménage** | la suite sur chaque pull request, les défauts vus sur les produits et les restes de revue fermés | livré le 2026-11-13 (s159 à s163) ; deux constats majeurs de s163 restent ouverts (#233, #234) |
| **M21 — L'interface** | l'état en JSON, la boîte de décisions, la réponse, les rapports écrits par un script, le pilote en automate, le lancement, les signaux de confiance | cadré pour bash, à reprendre par `/po-stories` pour un binaire Rust ([ADR-0106](decisions/ADR-0106-le-pilote-devient-un-automate-en-code.md)) une fois D11 et D12 tranchées |
| **M22 — La preuve par le comportement** | un parcours rejouable de bout en bout, le retrait des tests de phrase, le budget de mots, les bras de contrôle, une seule commande d'entrée, le ship en script | à cadrer quand M21 est livré |

Ensuite, Polype sert les projets qui l'utilisent et ne change que quand l'un d'eux bute sur lui.

## La façon de faire

Faut-il changer l'ordre et la forme des commandes ? Les étapes et leurs portes, non. Le nombre de commandes et la part de prose, oui.

- **Les étapes restent** : recherche, design, plan avec son oracle, exécution, QA, revue, ship. C'est l'ordre de la Law 1 ; la flotte, qui fait passer le designer après le planner, s'y aligne (#184).
- **Une seule commande fait avancer le travail** : `/po-drive`, avec un id pour une seule story. `/po-orchestrator` et `/po-flow` disparaissent comme commandes, la voie courte devenant une valeur que l'automate lit ([ADR-0109](decisions/ADR-0109-une-seule-commande-fait-avancer-le-travail.md), proposée, #210). Pas avant s168.
- **Ce qui est déterministe devient du code** : l'état (`po-state`), l'écriture d'un rapport (`po-record`), le routage (`po-state next`), puis le ship (#211). L'automate est un binaire Rust (ADR-0106). Le modèle garde ce qui demande du jugement : cadrer, planifier, écrire, relire, parler à la personne.
- **Une story de complexité 1 ou 2** garde toutes ses portes et passe par trois contextes, le minimum de la Law 2 : un planner, un implementer, un relecteur. Ce qui l'allège, ce sont les mots que chacun lit, pas une porte en moins.
- **La chaîne de cadrage** ne tourne qu'une fois par projet et ne change pas, à une question près : fixer l'architecture avant de découper les stories, pour que les `Owns` portent sur des chemins connus ([ADR-0110](decisions/ADR-0110-l-architecture-se-fixe-avant-le-decoupage.md), proposée, #212).
- **Un agent extérieur** n'appelle aucune de ces commandes : il passe par `po-agent`.

## Ce qui reste

Rien de ceci n'est remis en cause, et M20 à M22 le respectent :

- les portes de la Law 3 et `po-gate`, les bornes de `po-bounds`, l'oracle écrit par le planner ;
- la séparation entre celui qui écrit et celui qui juge (Law 2) ;
- une story, un worktree, un commit, une pull request ;
- le journal des décisions prises seul, et les trois motifs qui font remonter au porteur ;
- un choix technique n'est jamais tranché par un agent ;
- un sujet de sécurité va au porteur, jamais au tracker.

## Ce qu'on ne fait plus

- Ouvrir un jalon de méthode sans défaut vu sur un produit ni décision stratégique écrite du porteur. Les idées attendent en issues `parked`.
- Ajouter une règle en prose sans en retirer une : le nombre de mots de `method/` ne monte pas.
- Écrire un test qui cherche une phrase qu'aucun script ne lit. Un test porte sur un script, ou sur un champ qu'un script lit.
- Corriger un écart d'interprétation par une phrase de plus quand un script peut tenir la règle.
- Polir la prose : un constat de revue de pure rédaction, sans effet sur un comportement, se ferme sans story.
- Faire transcrire un rapport par un modèle.
- Construire s153, s154 et s155 (audit planifié, autres modèles, story d'exploration) avant qu'un produit en ait besoin.

## Par où reprendre

D1 à D4 ont été tranchées le 2026-11-13 : les ADR-0105 à ADR-0108 sont `accepted`.

M20 est livré depuis le 2026-11-13 : la suite tourne sur chaque pull request, et `/po-ship` attend qu'elle passe.

1. Rendre le contrôle `suite` obligatoire sur `main` (D8), geste du porteur décrit dans [`ci.md`](ci.md).
2. Poser D11 et D12 de [`a-trancher.md`](a-trancher.md) au porteur, une à la fois : la distribution du binaire Rust et ce qui y entre. Aucune story de M21 ne se planifie avant.
3. `/po-stories` reprend s164 à s170 pour le binaire Rust et la boîte à emplacement réglable, puis `/po-stories-review`.
4. `/po-drive` sur M21. D5 à D10 peuvent attendre.
