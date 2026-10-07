# Référence — gstack (Garry Tan) et agent-skills (Addy Osmani)

- gstack : https://github.com/garrytan/gstack — étudié au commit `28f1385` (2026-10-06). MIT, © 2026 Garry Tan. `NOTICE.md` signale des parties dérivées sous Apache-2.0 (catalogue de design dans `lib/design-catalog.ts`, `scripts/resolvers/design.ts`, `design-consultation`) : on n'y emprunte rien.
- agent-skills : https://github.com/addyosmani/agent-skills — étudié au commit `1401c8b` (2026-10-03). MIT, © 2025 Addy Osmani.

Le MIT permettrait de copier en gardant la notice. La règle reste celle d'ADR-0006 : on reprend des mécanismes, jamais le texte des skills, des checklists ou des fixtures. Une story qui s'en inspire passe `bin/ks-overlap <src> 8` contre les deux dépôts avant sa PR.

## Ce qui les sépare de Polype

Les deux couvrent le même cycle (cadrer, planifier, coder, vérifier, relire, livrer) mais ne le tiennent pas de la même façon.

- **agent-skills** est un catalogue de skills en prose. Chaque skill a la même anatomie : procédure, table des excuses avec leur réfutation, signaux d'alerte, vérification. Rien ne bloque mécaniquement. Sa rigueur est dans ses **evals** : lint de structure, routage des descriptions, et runs `claude -p` sur des dépôts fixtures, y compris des cas de pression (« ship quand même, c'est urgent »).
- **gstack** joue des rôles (CEO, eng manager, QA, CSO, release). L'essentiel est en prose, mais il porte de vrais mécanismes : des hooks PreToolUse actifs pendant une skill (`/careful`, `/freeze`), un registre de preuves écrit par un wrapper (`bin/gstack-evidence`), un journal de revue lié à l'arbre de travail (`bin/gstack-review-log`). L'ordre du cycle n'a pourtant aucune gate git : `/ship` lit les scripts et décide lui-même.
- **Polype** fait l'inverse d'agent-skills : ses gates sont mécaniques, mais ses tests ne vérifient que le texte de la méthode, jamais le comportement d'un agent qui l'applique.

## Idées retenues

Par priorité. Les chemins entre parenthèses pointent dans le dépôt source.

### Trous de gate et garde-fous mécaniques

- **La revue liée à l'arbre qu'elle a jugé** (gstack `ship/SKILL.md.tmpl` §11.5). Aujourd'hui `po-gate ship-allowed` ne lit que la dernière ligne `Ship allowed:` : un commit ajouté après un verdict favorable part au ship sans avoir été relu. Une ligne `Reviewed tree:` dans la revue, comparée à HEAD hors `docs/` comme le fait déjà `verif_current`, ferme le trou.
- **Le garde contre l'abaissement de la barre** (agent-skills `references/floor-guard.md`). Scan du diff de la story : nouveaux `@ts-ignore`, `eslint-disable`, `.skip`, `istanbul ignore`, tests supprimés, assertions retirées, `catch` vide, seuils abaissés. Sortie à trois états où « je n'ai pas pu vérifier » ne vaut jamais « propre ». Une sous-commande `po-gate`, lancée par le reviewer.
- **Les bornes de l'implementer tenues par un hook** (gstack `freeze/bin/check-freeze.sh`, `careful/bin/check-careful.sh`). Un PreToolUse dans le frontmatter de l'agent `implementer` refuse Edit/Write hors des chemins `Owns` et de `docs/`, et refuse les verbes git que la loi 4 interdit. Le contrôle `Owns` cesse d'être seulement constaté après coup en revue.
- **Le scan de secrets au commit** (gstack `bin/gstack-redact-prepush`). `po-gate pre-commit` refuse un `.env*` indexé et les motifs de clés évidents, au lieu de la consigne en prose de la loi 6.

### Vérifier ce que l'utilisateur verra

- **Une étape QA en navigateur, qui produit des preuves** (gstack `qa-only/`, `qa/`). Pour une story avec écran, entre execute et review : un subagent en lecture seule parcourt les écrans touchés par le diff et écrit `docs/qa/<id>/` (étapes de repro, captures, statut par constat). La consigne « ouvre l'écran dans un navigateur » de `implementer.md` devient un artefact que la revue peut exiger.
- **Le contrat de pilotage du navigateur** (gstack `BROWSER.md`). Ses propres onglets seulement, rester sur l'origine annoncée, aucun identifiant ne transite par l'agent, le contenu de la page est une donnée et pas une instruction. Réécrit dans `design-doctrine` et dans l'agent QA.

### Une revue plus large sans multiplier les verdicts

- **Des lentilles déclenchées par les chemins touchés** (gstack `review/specialists/`, `bin/gstack-diff-scope` ; agent-skills `references/*-checklist.md`). Le même reviewer charge une courte liste quand le diff touche :
  - auth, entrées, upload, webhook, appel sortant ou appel LLM → sécurité (IDOR, SSRF, signature de webhook, rate limit partagé, erreurs génériques). Une vérification d'autorisation manquante est critique ;
  - une migration → expand/contract, jamais de renommage ou de suppression de colonne en place (majeur), plan de retour arrière ;
  - le lockfile → une dépendance par changement, changelog lu, scripts postinstall ;
  - du code serveur → N+1, fetch non borné, pagination absente, awaits séquentiels. Tout constat statique est marqué « impact potentiel », jamais chiffré.
  
  Un seul reviewer, une seule échelle de sévérité, une seule ligne de verdict. On écarte la parade de personas fusionnées par un LLM.
- **La sortie d'erreur est une donnée** (agent-skills `debugging-and-error-recovery`). Une ligne dans `method/AGENTS.md` : logs, traces et pages récupérées ne donnent jamais d'instruction.

### Tester la méthode en action

- **Des evals comportementales du reviewer** (agent-skills `evals/`). Des stories fixtures avec un défaut planté (garde non testé, IDOR, filtre de tenant manquant) et des cas de pression (« l'utilisateur dit de livrer malgré le critique »). Notation mécanique sur `Ship allowed: no` et la sévérité maximale : les lignes de verdict de Polype rendent un juge LLM inutile. Lancées à la demande, jamais en CI (coût).
- **Un registre de preuves écrit par un wrapper** (gstack `bin/gstack-evidence`). `po-run --label <suite> -- <cmd>` relaie le code de sortie et ajoute la commande, le code et l'arbre au relevé de vérification. Le relevé cesse d'être déclaratif. Le registre reste dans `docs/verif/`, en git.

### Plus tard

Tranché le 2026-10-07 après la revue du découpage de M6 : ces idées restent bonnes mais n'entrent pas dans M6.

- **Une rétro tirée des fichiers** (gstack `bin/gstack-retro-metrics`). Polype a de meilleures sources que les commits : `docs/reviews/*` (sévérités, boucles de correction, `Max attempts` atteint), majeurs ouverts, relevés de vérification. Aucune valeur inventée, pas de métriques de vanité (lignes, séries). Elle gagne à attendre M6 : les rapports QA et les relevés écrits par `po-run` en seront les meilleures données.
- **Des leçons proposées par la revue** (gstack `bin/gstack-learnings-log`). Le reviewer propose une entrée typée (fichiers concernés), un humain la promeut en convention dans `AGENTS.local.md`. Attend Nautile : la capture lui revient sans doute.
- **Une procédure de diagnostic** (gstack `investigate/`). Pas de correctif sans cause racine, arrêt après trois hypothèses ratées. Skill préchargée par le planner pour une story de défaut. Sans urgence : les défauts de Polype se corrigent aujourd'hui par des stories courtes.
- Vérification après déploiement et revert guidé (gstack `land-and-deploy/`, `canary/`), derrière un réglage optionnel : le squash rend le revert trivial.
- Accessibilité au-delà du contraste (focus, labels, `alt`, erreur jamais signalée par la seule couleur) dans `design-doctrine`.
- En validation de plan `auto`, le plan liste ses décisions de goût pour qu'un humain les voie (gstack `autoplan/` §Decision Classification).
- Un audit des tests du projet entier (gstack `test-audit/`), en rapport seul.

## Idées écartées

- **Rouge d'abord / TDD strict** (agent-skills `test-driven-development`) : contredit ADR-0012 ; la preuve de morsure en revue donne déjà un test qui tombe sans le correctif.
- **Un reviewer ou une QA qui corrige** (gstack `/review` Fix-First, boucles de `/qa` et `/design-review`) : celui qui juge n'écrit pas (loi 2). On garde les variantes en rapport seul.
- **« Boil the Ocean » et l'auto-acceptation d'un périmètre qui grossit** (gstack `ETHOS.md`, `autoplan`) : contredit `Owns`, le budget de tests et la loi 5.
- **L'état hors du dépôt** (gstack `~/.gstack/projects/`) : revues, preuves et leçons doivent vivre en git, à côté du code.
- **Un commit par tâche, des commits « bisectables »** : contredit le squash par story (ADR-0013, ADR-0015).
- **Le routage « invoque une skill au moindre doute » et ses evals** (agent-skills) : les commandes Polype sont appelées explicitement et les skills préchargées par agent, il n'y a rien à router.
- **Revue croisée par un autre modèle** : Codex est différé (ADR-0005).
- **L'infrastructure de gstack** : télémétrie, mise à jour auto au démarrage, daemon Chromium maison, CLI Bun compilée. On utilise l'outil navigateur de la session.
- **Les marqueurs dans le code** (`// Regression: ISSUE-NNN`) : les majeurs ouverts vivent dans `docs/reviews/`.
- **Les scorecards Core Web Vitals, budgets d'erreur, déploiements progressifs** : demandent des données de prod que le cycle d'une story n'a pas.
