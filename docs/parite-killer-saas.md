# Matrice de parité — Killer SaaS → Polype

Garantie de qualité exigée par [ADR-0006](decisions/ADR-0006-adapter-killer-saas-sans-copie.md) : chaque mécanisme de Killer SaaS a un équivalent Polype, ou un écart assumé et justifié. Relevé exhaustif de `src/` au commit `43ec45f` (2026-09-05), reformulé ici, jamais recopié.

**Traitement** : **Reprendre** (même mécanisme, notre rédaction) · **Adapter** (même intention, forme changée par une décision Polype) · **Étendre** (repris et enrichi).
**Statut** : `à faire` tant que Polype n'implémente pas la ligne ; une ligne passe à `fait` avec le chemin du fichier Polype qui la porte. Chaque ligne devient un critère d'acceptation des stories de Polype.

## A. Principes

| ID | Mécanisme Killer SaaS | Où | Polype | Traitement | Statut |
|---|---|---|---|---|---|
| A01 | Aucun code hors pipeline : la commande d'exécution n'a pas les outils d'écriture et délègue à un subagent | AGENTS.md, ks-execute | Identique ; le driver de flotte n'écrit pas de code non plus | Reprendre | fait — `method/commands/po-execute.md`, `method/agents/implementer.md` |
| A02 | Le contexte qui produit ne juge jamais : revues en contexte frais, en lecture seule | reviewer, stories-reviewer | Identique, plus la vérification d'ownership de `/drive` | Étendre | partiel — `method/agents/reviewer.md` ; contrôle d'ownership en M3 |
| A03 | Fail-closed : chaque gate bloque par défaut, rien n'est forcé | partout | Identique | Reprendre | fait — `method/AGENTS.md`, `method/hooks/po-gate.sh` |
| A04 | Chaque vérification déterministe tourne une seule fois dans le cycle | DOC, testing-doctrine | Identique | Reprendre | fait — `method/skills/testing-doctrine/SKILL.md` |
| A05 | Mode correctif rapide : exception demandée explicitement, bornée par une liste positive (couleur, espacement, texte court…) et négative (feature, migration, authz, dépendance…), annoncée, diff minimal, jamais dans un worktree | AGENTS.md | Même bornage ; atterrit sur la branche cible, jamais pendant qu'une lane possède les fichiers | Adapter | fait — `method/AGENTS.md` |
| A06 | Toujours passer par les commandes, jamais un appel d'agent écrit à la main (elles portent le mode correctif, les définitions, les gates) | AGENTS.md | Identique ; plusieurs stories parallèles = plusieurs dispatchs du driver | Reprendre | fait — `method/AGENTS.md` |
| A07 | Un fichier installé n'est jamais modifié sur place ; une amélioration remonte dans les sources de la méthode ; détection de dérive avant mise à jour | AGENTS.md, install.sh | Identique ; la dérive se détecte aussi côté chezmoi | Reprendre | partiel — `method/AGENTS.md`, `bin/polype-dev-install` ; dérive chezmoi en M5 |
| A08 | Règle commune dans le fichier de règles, valeur variable dans le fichier de réglages du projet ; aucune valeur par défaut silencieuse ; `—` signifie « n'existe pas ici » | AGENTS.md | Identique | Reprendre | fait — `method/AGENTS.md`, `method/templates/agents-local.md` |
| A09 | Une doctrine que seuls deux agents appliquent vit dans un skill préchargé, pas dans le fichier de règles que tout contexte paie | DOC, skills | Identique | Reprendre | fait — `method/skills/` |
| A10 | Définition de terminé par feature : PR lisible, tests métier verts, pas de régression, revue sans critique, déployé | AGENTS.md | Identique ; « déployé » dépend de la brique de déploiement du projet | Adapter | fait — `method/AGENTS.md` |

## B. Réglages du projet

| ID | Mécanisme Killer SaaS | Où | Polype | Traitement | Statut |
|---|---|---|---|---|---|
| B01 | Fichier de réglages local, une ligne `Nom: valeur`, jamais écrasé par l'installeur, créé par le seul setup | agents-local.md | Identique | Reprendre | fait — `method/templates/agents-local.md` |
| B02 | Réglages : mode de merge, branche cible, validation du plan, confirmation du ship, piste de story, seuil de la voie courte, source/skill/outil de design, budget de tests, mode de vérification, étapes de la suite complète, de l'E2E (étape, portée, navigateurs) et du build, tracker d'issues, racine des worktrees | agents-local.md | Tous repris ; ajout de : tracker d'état (ADR-0003), parallélisme, tentatives max, profil de boilerplate, briques choisies (ADR-0009) | Étendre | partiel — réglages M1 ; design et voie courte en M2, flotte en M3, profil et briques en M4 |
| B03 | Commandes du projet (gestionnaire de paquets, test, typecheck, E2E, build) citées telles quelles, jamais inventées | agents-local.md | Pré-remplies depuis le profil du boilerplate (ADR-0008) | Étendre | partiel — `method/templates/agents-local.md` ; pré-remplissage par profil en M4 |
| B04 | Conventions du projet remplies à l'étape architecture et assemblées dans le fichier de règles | ks-architect | Remplies depuis le profil, complétées par l'analyse | Adapter | à faire |

## C. Cadrage (une fois par produit)

| ID | Mécanisme Killer SaaS | Où | Polype | Traitement | Statut |
|---|---|---|---|---|---|
| C01 | Setup : lit d'abord ce que le repo répond, puis quatre questions seulement (où atterrit une story, qui valide un plan, qui dessine, commandes) ; confirmation du ship calquée sur la validation du plan ; n'écrase jamais un fichier existant | ks-setup | Identique, plus le choix du mode d'entrée et du boilerplate | Étendre | partiel — `method/commands/po-setup.md` ; mode d'entrée et boilerplate en M2 |
| C02 | PRD de kill, une question à la fois : cible, mode (remplacement interne / produit concurrent), pourquoi, périmètre = boucle cœur 20 %, cimetière exhaustif, angle au-delà de la parité, puis besoin, utilisateurs, contraintes, critères de succès mesurables ; rien d'écrit sans validation | ks-prd, prd.md | Modes **remplacer** et **adapter** ; pour adapter, l'angle repasse par une interrogation ciblée | Étendre | à faire |
| C03 | Échelle de complexité 1–5 définie (CRUD trivial → temps réel, migrations, systèmes externes) ; un 5 est candidat au cimetière | prd.md | Identique, partagée par PRD, stories et research | Reprendre | fait — `method/templates/stories.md` |
| C04 | — | — | Mode **partir de zéro** : interrogation sceptique, carte des manques, pre-mortem, alternatives (repris de `/spec`) | Étendre | à faire |
| C05 | Stories agentiques : tranche verticale livrable (jamais une couche technique), critères qui deviennent chacun un test, notes agentiques (fichiers, contraintes, pièges), dépendances ordonnées, taille ≤ ~10 tâches, complexité notée (un 4 annonce son risque, un 5 est découpé), la cible pointée comme référence, identifiant `s<n>-<slug>` stable | agentic-stories, stories.md | Identique, plus l'**ownership** déclaré par story et les **contrats d'abord** pour les interfaces partagées (repris de `/spec`) | Étendre | partiel — `method/templates/stories.md` (Owns) ; commande et skill de stories en M2 |
| C06 | Revue des stories en contexte frais, lecture seule, sans shell : couverture du périmètre table en main d'abord (un trou = critique), fuite du cimetière, couches techniques déguisées, critères intestables, ordre des dépendances, complexité, identifiants, chevauchements ; échelle de sévérité propre ; gate souple signalé par le statut et la research | stories-review, stories-reviewer | Identique, plus le chevauchement d'ownership entre stories parallélisables | Étendre | à faire |
| C07 | Architecture : question du boilerplate (existant, défaut scaffoldé enregistré en ADR, repo vide assumé), analyse du code hérité, conventions écrites comme règles, une ADR par décision structurante, boilerplate imposé | ks-architect | Choix dans le catalogue de profils (ADR-0008), choix des briques par capacité (ADR-0009), ADR de projet dans le repo (ADR-0002) | Adapter | à faire |
| C08 | Analyse de code : largeur d'abord puis une feature suivie de bout en bout, motifs récurrents, conventions implicites, points d'ancrage, rapport sous forme de règles, rien nommé sans l'avoir ouvert, aucune réécriture proposée | codebase-analysis | Identique ; sert aussi à générer le profil d'un boilerplate tiers | Étendre | fait — `method/skills/codebase-analysis/SKILL.md` |
| C09 | Design system : consigne, n'invente jamais ; s'arrête sans source visuelle ; inventaire des composants du boilerplate ; tokens, composants, patterns, à faire / à éviter ; **seule phase qui mesure** (contrastes de chaque paire texte/surface, clair et sombre) ; piège du mode sombre forcé | ks-design-system, design-doctrine | Identique | Reprendre | à faire |

## D. Cycle par story

| ID | Mécanisme Killer SaaS | Où | Polype | Traitement | Statut |
|---|---|---|---|---|---|
| D01 | Un worktree et une branche exacte par story, de la première à la dernière phase ; fichiers d'environnement non versionnés importés, dépendances installées, pas de suite de référence ; mauvaise branche ou HEAD détaché = arrêt dur ; un agent par répertoire | AGENTS.md | Identique, la branche part de la branche cible fraîchement récupérée | Adapter | fait — `method/commands/po-research.md` |
| D02 | Research : vérifie la **prémisse** de la story (comportement sur son cas, pas seulement l'existence des symboles), faits avec `chemin:ligne`, pièges, questions ouvertes honnêtes, complexité re-notée après lecture, proposition de découpe à 5, les cinq faits structurants en tête, plafond ~200 lignes ; avertit si la revue des stories manque | ks-research, research.md | Identique | Reprendre | fait — `method/commands/po-research.md`, `method/templates/research.md` |
| D03 | Design : bloqué sans design system ; source de design fixée par projet ; écran **dérivé** → deltas sans maquette, écran **nouveau** → exactement un artefact ; fidélité finale (tous les états, clair/sombre, bureau/mobile, vrai texte) ; rendu et regardé en HTTP local, sur les deux thèmes et les deux largeurs ; ce qui n'a pu être vérifié est dit ; manques du design system consignés, jamais inventés ; le repo fait foi ; la maquette est une référence, jamais du code | ks-design, design-doctrine, gabarits design | Identique | Reprendre | à faire |
| D04 | Plan : tâches ordonnées, petites, vérifiables ; chaque comportement nomme le test qui peut échouer, une tâche purement visuelle nomme sa vérification visuelle ; budget de tests ; interdits d'exécution vérifiables ; « le point sur lequel tout repose » ; fichiers touchés ; > ~10 tâches = découper ; décision structurante = ADR sur la branche ; plafond ~250 lignes ; `validated: no` puis checkpoint selon le réglage | ks-plan, plan.md | Identique ; en flotte, validation des plans groupée en une question par vague | Étendre | partiel — `method/commands/po-plan.md` ; validation groupée par vague en M3 |
| D05 | Exécution déléguée : contexte principal sans outils d'écriture, bloqué sans plan validé, mode correctif si la dernière revue bloque | ks-execute | Le driver dispatche plusieurs implémenteurs en parallèle, une lane par ownership disjoint | Étendre | partiel — `method/commands/po-execute.md` ; dispatch parallèle en M3 |
| D06 | Implémenteur : vérifie worktree et branche ; mode correctif = toutes les remarques et tâches ouvertes fermées dans le run, critiques et majeures d'abord ; par tâche : bloc complet, suite ciblée, case cochée, pas de commit ; écran ouvert dans un navigateur ; à la fin : suite complète, typecheck, record de vérification, **un seul commit** ; commandes citées telles quelles ; ADR = loi ; bloqueur = arrêt, jamais d'improvisation ; chaque déviation déclarée | implementer | Identique | Reprendre | fait — `method/agents/implementer.md` |
| D07 | Record de vérification : `Tree:` issu de `git write-tree` après `git add -A`, table des commandes avec code de sortie et compteurs, section « non prouvé ici », statut complet ; jamais de run inventé | verification-record | Identique | Reprendre | fait — `method/templates/verification-record.md`, `method/hooks/po-gate.sh` |
| D08 | Revue : délégation ; rapport bloqué structuré (cause, manquant, adaptation, prochaine action) si la revue ne peut aboutir ; verdict par deux lignes exactes | ks-review, reviewer | Identique | Reprendre | fait — `method/commands/po-review.md` |
| D09 | Procédure anti-hallucination en six étapes : record vérifié mécaniquement avant tout rerun ; chaque référence ouverte ; diff contre plan, research et ADR ; tests lus comme du code (fixtures et doublures comprises, tests décoratifs rejetés, volume jugé) ; **preuve de morsure** (neutraliser l'invariant, lancer seulement ses fichiers de test, compter les rouges, restaurer et prouver l'arbre propre ; zéro rouge = non testé) ; logique plausible mais fausse ; régressions | review-antihallu | Identique, plus le contrôle « le diff reste dans `owns` » de `/drive` | Étendre | partiel — `method/skills/review-antihallu/SKILL.md` ; contrôle d'ownership en M3 |
| D10 | Conformité design jugée à l'intention, pas à la maquette ligne à ligne ; composant hors système = majeur, critique s'il casse la cohérence | reviewer | Identique | Reprendre | à faire — M2 (design) |
| D11 | Avant le verdict, liste de ce qui n'a pas pu être vérifié et des gestes humains à faire | reviewer, review-checklist | Identique | Reprendre | fait — `method/agents/reviewer.md`, `method/templates/review.md` |
| D12 | Seul un critique (ou une revue incomplète) bloque ; un majeur est tracé et corrigé au cycle suivant ; deux boucles de correction au plus ; jamais de sévérité adoucie ou gonflée | AGENTS.md, reviewer | Identique | Reprendre | fait — `method/agents/reviewer.md`, `method/AGENTS.md` |
| D13 | Ship : gate mécanique par grep ; seule porte des contrôles coûteux (E2E une fois, build si une route ou un manifeste a bougé, suite complète seulement si le record n'est plus à jour, ou lecture des checks CI) ; rouge = retour en mode correctif ; PR avec le verdict ; squash systématique ; confirmation humaine selon le réglage | ks-ship | Squash de la story dans la branche cible, en PR ou en local selon `Merge mode` (ADR-0015) | Reprendre | fait — `method/commands/po-ship.md` |
| D14 | Nettoyage seulement sur merge **prouvé** (état `MERGED`, jamais la promesse ni `merge-base --is-ancestor` qu'un squash met en échec) ; worktree propre retiré sans `--force`, puis branche supprimée avec `-D` justifié par le squash | ks-ship | Identique | Reprendre | fait — `method/commands/po-ship.md` |
| D15 | Voie courte : même cycle en trois contextes (research et plan fusionnés), rien d'assoupli ; cinq signaux d'escalade (migration, nouvel écran, authz ou tenant, contrat d'API, nouvelle dépendance) vérifiés avant et après lecture du code ; ≤ ~6 tâches ; faits vérifiés en tête du plan, plafond ~150 lignes | ks-flow, plan-flow | Identique | Reprendre | à faire |
| D16 | Orchestrateur d'une story : choix de la piste, deux checkpoints humains réels (validation du plan, confirmation du ship), bloqué si le cadrage manque | ks-orchestrator | Le driver de flotte orchestre N stories ; les checkpoints sont groupés par vague ; l'orchestrateur mono-story reste disponible | Étendre | partiel — `method/commands/po-orchestrator.md` ; flotte en M3 |
| D17 | Statut dérivé des fichiers : réglages, cadrage, puis par story complexité, research, design, plan (brouillon/validé, avancement des cases), record, verdict, état du merge, bloqué par dépendance, prochaine commande utile | ks-status | État de travail lu dans le tracker (ADR-0003), verdicts et gates lus dans les fichiers ; même tableau et même « prochaine commande » | Adapter | partiel — `method/commands/po-status.md` (depuis les fichiers) ; tracker en M3 |
| D18 | Aide-mémoire du pipeline en français, invoqué par l'utilisateur seulement | ks-help | Identique | Reprendre | fait — `method/commands/po-help.md` |

## E. Doctrine de test

| ID | Mécanisme Killer SaaS | Où | Polype | Traitement | Statut |
|---|---|---|---|---|---|
| E01 | Budget de tests par story (25 par défaut), dépassement justifié ; le critère remplaçant le nombre : un test qui reste vert quand on supprime sa règle est pire qu'aucun test | testing-doctrine | Identique | Reprendre | fait — `method/skills/testing-doctrine/SKILL.md` |
| E02 | Où vont les tests : service et policy (la matrice des permissions une seule fois, dans le test de policy), persistance (idempotence et clause tenant appelées directement sur le repository), adaptateur (parsing, mapping de statut, jamais un 403 re-testé par rôle), composant (quasi rien), E2E (un scénario, pour ce que les mocks cachent) | testing-doctrine | Identique, cartographié dans les modules verticaux (ADR-0007) | Reprendre | fait — `method/skills/testing-doctrine/SKILL.md` |
| E03 | Quatre coupes : matrice une fois, pas d'exhaustivité d'enum, jamais la même règle à deux couches, pas d'adaptateur qui re-teste un 403 | testing-doctrine | Identique | Reprendre | fait — `method/skills/testing-doctrine/SKILL.md` |
| E04 | Pas de rouge-d'abord ni de mutation pendant l'implémentation (mesuré : zéro trouvaille) ; la mutation vit en revue, où elle trouve | testing-doctrine | Identique — **remplace** la règle « tests d'acceptation d'abord, les voir échouer » de `/drive` | Adapter | fait — `method/skills/testing-doctrine/SKILL.md` (ADR-0012) |
| E05 | Six formes de faux tests : requête écrite à la main dans le test, payload que l'interface ne produit jamais, `catch` qui avale l'échec, E2E vert sur zéro ligne, fixture dont l'identifiant laisse un garde aval répondre, doublure qui rejoue la clause | testing-doctrine | Identique | Reprendre | fait — `method/skills/testing-doctrine/SKILL.md` |
| E06 | Quand lancer quoi : suite ciblée par tâche, suite complète une fois, typecheck une fois à la toute fin (obligatoire), E2E une fois au ship, build au ship si route ou manifeste bougé, format sur les fichiers indexés seulement | testing-doctrine | Identique | Reprendre | fait — `method/skills/testing-doctrine/SKILL.md` |

## F. Gates et application

| ID | Mécanisme Killer SaaS | Où | Polype | Traitement | Statut |
|---|---|---|---|---|---|
| F01 | Script de gate : plan validé, ship autorisé, record à jour (arbre identique hors `docs/`) | ks-gate.sh | Identique | Reprendre | fait — `method/hooks/po-gate.sh` |
| F02 | Hook pre-commit optionnel via `core.hooksPath` : pas de code sur une branche de story sans plan validé, commits purement docs autorisés, réversible | pre-commit | Identique, adapté au nommage des branches de la flotte | Adapter | fait — `method/hooks/pre-commit` |
| F03 | Pas de gate au push (le squash ne laisse rien à détecter) : le ship autorisé se vérifie en CI ou par protection de branche | ks-gate.sh, DOC | Identique | Reprendre | fait — `method/hooks/po-gate.sh` |

## G. Données et documents

| ID | Mécanisme Killer SaaS | Où | Polype | Traitement | Statut |
|---|---|---|---|---|---|
| G01 | Tout en markdown sous `docs/`, versionné ; documents de cadrage sur la branche par défaut ; documents de story voyagent avec leur branche ; chaque PR porte sa research, son design, son plan, son record et sa revue | AGENTS.md | Identique | Reprendre | fait — `method/AGENTS.md` |
| G02 | Plafonds de taille (research ~200, plan ~250, revue ~150) : couper la prose, jamais les tables de décision | AGENTS.md | Identique | Reprendre | fait — `method/AGENTS.md` |
| G03 | Un commit par story (un second seulement pour ce qu'on voudrait annuler seul, typiquement une migration) ; cases du plan = suivi d'avancement, jamais déclencheur de commit | AGENTS.md | Identique | Reprendre | fait — `method/AGENTS.md`, `method/agents/implementer.md` |
| G04 | ADR MADR dans `docs/decisions/`, immuables, remplacées par une nouvelle ; celles de cadrage sur la branche par défaut, celles d'une story avec sa branche | AGENTS.md, adr.md | Identique (ADR-0002), plus un pointeur Graphiti | Étendre | fait — `method/AGENTS.md`, `method/templates/adr.md` |
| G05 | Un défaut n'est pas une story (il va dans le tracker d'issues) ; une remarque de revue reste dans son rapport sauf décision humaine | AGENTS.md | Identique | Reprendre | fait — `method/AGENTS.md` |
| G06 | État jamais stocké, dérivé des fichiers | AGENTS.md | Écart assumé : l'état de travail vit dans le tracker (ADR-0003) ; les verdicts restent dans les fichiers | Adapter | partiel — verdicts dans les fichiers ; état dans le tracker en M3 |

## H. Distribution

| ID | Mécanisme Killer SaaS | Où | Polype | Traitement | Statut |
|---|---|---|---|---|---|
| H01 | Installation projet, globale, `init` par projet après une globale, mise à jour par manifeste (pas de fantômes, commandes perso intactes), templates non modifiés rafraîchis, modifiés signalés, tampon de version, contrôle de dérive | install.sh, DOC | Globale synchronisée par chezmoi + `init` par projet (ADR-0004) ; même mise à jour par manifeste et même contrôle de dérive | Adapter | à faire |
| H02 | Fichier de règles reconstruit à chaque installation depuis la source + les réglages locaux ; `CLAUDE.md` n'importe que le fichier de règles | install.sh | Identique | Reprendre | fait — `bin/polype-dev-install` |
| H03 | Source unique, émission par outil (Claude Code, Codex) via un build sans dépendance ; tableau honnête de ce qui se dégrade | bin/ks-build.mjs, DOC | Codex vers mi-octobre (ADR-0005) ; règles en `AGENTS.md` dès maintenant | Adapter | à faire |
| H04 | Modèles : implémenteur épinglé sur le modèle le plus fort (moins d'allers-retours), relecteurs héritant du modèle de session | agents | Identique par défaut, réglable par story | Étendre | à faire |

## Tensions tranchées

| ID | Killer SaaS | `/spec` + `/drive` | Décision |
|---|---|---|---|
| T1 | Pas de rouge-d'abord, mutation en revue seulement | Tests d'acceptation d'abord, les voir échouer | Killer SaaS — [ADR-0012](decisions/ADR-0012-pas-de-rouge-dabord.md) |
| T2 | Squash d'une story dans la branche cible | Merge `--no-ff` de chaque packet dans la branche d'intégration | Squash direct dans la branche cible, corrections au fil de l'eau — [ADR-0015](decisions/ADR-0015-squash-direct-et-corrections-au-fil-de-leau.md) (remplace ADR-0013) |
| T3 | État dérivé des fichiers | État dans le tracker | Tracker pour l'état, fichiers pour les verdicts — [ADR-0003](decisions/ADR-0003-etat-dans-github-ou-taskwarrior.md) |
| T4 | Checkpoints humains par story (plan, ship) | Autonomie accordée une fois, pause entre milestones | Réglage, regroupé par vague en flotte — [ADR-0014](decisions/ADR-0014-checkpoints-groupes.md) |

## Au-delà de Killer SaaS

Ce que Polype ajoute, repris de `/spec`, `/drive` ou des décisions propres :

- **Trois modes d'entrée** : remplacer, adapter, partir de zéro (C02, C04).
- **Flotte parallèle** : lanes par ownership disjoint, claim dans le tracker, reprise après crash, un seul driver par projet, tentatives bornées puis escalade groupée, interdiction d'affaiblir une acceptation sans accord.
- **Spikes** pour les risques ouverts, avec une ADR proposée en sortie.
- **Contrats d'abord** : une interface partagée par deux stories devient une story antérieure.
- **Milestones** comme jalons de livraison, avec une revue transverse (`/roast-me`) à la demande.
- **Autonomie accordée** une fois et enregistrée (tracker, merge, push, parallélisme, tentatives).
- **Catalogue de profils de boilerplate** (ADR-0008) et **briques interchangeables par capacité**, avec tests de contrat (ADR-0009).
