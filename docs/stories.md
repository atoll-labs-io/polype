# User Stories — Polype

> Une story = une tranche livrable, écrite pour être exécutée par un agent.
> Identifiant `s<n>-<slug>`, réutilisé dans chaque fichier et nom de branche.
> Les critères d'acceptation sont des tests de `tests/` (commande : `bash tests/run.sh`), sauf mention « revue ».

## M1 — Le cycle

Arborescence cible : `method/` (règles, commandes, subagents, skills, templates, hooks), `bin/`, `tests/`.

### s01-regles-et-reglages — Les règles et les réglages d'un projet
**En tant que** développeur **je veux** installer les règles communes et créer les réglages de mon projet **afin que** chaque commande lise les mêmes règles et les valeurs de mon projet, sans défaut silencieux.

- **Complexité** : 2
- **Owns** : `method/AGENTS.md`, `method/templates/agents-local.md`, `method/commands/po-setup.md`, `tests/structure.test.sh`, `tests/lib.sh`, `tests/run.sh`
- **Matrice** : A01–A10, B01–B03, C01 (sans mode ni boilerplate), D01, G01–G06
- **Dépendances** : aucune

**Critères d'acceptation**
- [ ] `settings_template_one_value_per_line` — chaque réglage du gabarit est une ligne `Nom: valeur` sans commentaire.
- [ ] `settings_template_declares_all_m1_settings` — le gabarit déclare tous les réglages utilisés par les commandes M1.
- [ ] `every_setting_read_by_a_command_exists_in_template` — aucune commande ne lit un réglage absent du gabarit.
- [ ] `setup_never_overwrites_settings` — `po-setup` interdit d'écraser un fichier de réglages existant.
- [ ] `rules_state_absolute_rule_and_quick_fix_bounds` — les règles portent l'interdit de code hors pipeline et le bornage du correctif rapide.
- [ ] (revue) Aucune phrase reprise textuellement de Killer SaaS.

**Notes agentiques** : les règles sont en anglais (lues par Claude et Codex, ADR-0005), l'aide en français. `—` = « n'existe pas dans ce projet ».

### s02-gates — Les gates mécaniques
**En tant que** développeur **je veux** des gates vérifiables par script **afin qu'**aucun code ne soit commité sans plan validé et qu'aucune story ne parte sans revue favorable, quel que soit l'outil.

- **Complexité** : 2
- **Owns** : `method/hooks/`, `tests/gate.test.sh`
- **Matrice** : F01–F03, D07 (contrôle du record)
- **Dépendances** : s01

**Critères d'acceptation**
- [ ] `plan_validated_passes_only_on_exact_line` · `plan_validated_fails_without_file`
- [ ] `ship_allowed_passes_only_on_exact_line` · `ship_allowed_fails_on_no`
- [ ] `verif_current_passes_when_tree_matches` · `verif_current_fails_when_code_changed` · `verif_current_ignores_docs_changes` · `verif_current_fails_when_incomplete`
- [ ] `pre_commit_blocks_code_without_validated_plan` · `pre_commit_allows_docs_only` · `pre_commit_ignores_non_story_branch`

### s03-research — Research d'une story
**En tant que** développeur **je veux** qu'une story soit explorée dans son worktree avant d'être planifiée **afin que** le plan repose sur le code réel et que les prémisses fausses sortent tôt.

- **Complexité** : 3
- **Owns** : `method/commands/po-research.md`, `method/skills/codebase-analysis/`, `method/templates/research.md`, `method/templates/stories.md`, `tests/research.test.sh`
- **Matrice** : D01, D02, C08, C03
- **Dépendances** : s01

**Critères d'acceptation**
- [ ] `research_bootstraps_worktree_and_branch` — la commande crée ou vérifie `.worktrees/<id>` sur `story/<id>` et s'arrête sur toute incohérence.
- [ ] `research_verifies_premise_and_caps_length` — la commande exige la vérification de la prémisse et plafonne le rapport.
- [ ] `research_template_has_structuring_facts_and_complexity` — le gabarit ouvre sur les faits structurants et finit sur la complexité re-notée.
- [ ] `research_writes_no_code` — la commande n'a ni Edit ni droit de produire du code.

### s04-plan — Plan d'une story et doctrine de test
**En tant que** développeur **je veux** un plan court, vérifiable et validé **afin que** l'implémentation n'ait rien à décider.

- **Complexité** : 3
- **Owns** : `method/commands/po-plan.md`, `method/templates/plan.md`, `method/skills/testing-doctrine/`, `tests/plan.test.sh`
- **Matrice** : D04, E01–E06
- **Dépendances** : s03

**Critères d'acceptation**
- [ ] `plan_template_starts_unvalidated` — frontmatter `validated: no`.
- [ ] `plan_template_has_interdicts_and_pivot` — sections interdits d'exécution et point pivot.
- [ ] `plan_checkpoint_follows_setting` — la validation suit `Plan validation`.
- [ ] `testing_doctrine_covers_budget_layers_cuts_shapes_stages` — budget, couches, quatre coupes, six faux tests, table des étapes.

### s05-execute — Exécution déléguée
**En tant que** développeur **je veux** que l'implémentation soit faite par un subagent dédié **afin que** le contexte principal ne code jamais et que chaque run soit prouvé.

- **Complexité** : 3
- **Owns** : `method/commands/po-execute.md`, `method/agents/implementer.md`, `method/templates/verification-record.md`, `tests/execute.test.sh`
- **Matrice** : A01, D05 (une story), D06, D07
- **Dépendances** : s02, s04

**Critères d'acceptation**
- [ ] `execute_has_no_write_tools` — `po-execute` n'a ni Write, ni Edit, ni Bash.
- [ ] `execute_fails_closed_on_unvalidated_plan`
- [ ] `implementer_preloads_testing_doctrine`
- [ ] `verification_record_has_tree_and_status`

### s06-review — Revue anti-hallucination
**En tant que** développeur **je veux** une revue en contexte frais qui prouve que les tests mordent **afin qu'**aucune story ne parte sur un filet décoratif.

- **Complexité** : 4 — risque : la preuve de morsure mute du code ; la restauration doit être prouvée.
- **Owns** : `method/commands/po-review.md`, `method/agents/reviewer.md`, `method/skills/review-antihallu/`, `method/templates/review.md`, `tests/review.test.sh`
- **Matrice** : A02, D08–D12
- **Dépendances** : s05

**Critères d'acceptation**
- [ ] `reviewer_cannot_write_files` — le reviewer n'a pas Write.
- [ ] `review_template_ends_with_verdict_lines`
- [ ] `review_antihallu_has_six_steps_and_bite_proof`
- [ ] `review_command_writes_blocked_report_on_failure`

### s07-ship — Ship d'une story
**En tant que** développeur **je veux** que seule une revue favorable ouvre le ship **afin que** les contrôles coûteux tournent une fois et que le nettoyage n'arrive que sur un merge prouvé.

- **Complexité** : 3
- **Owns** : `method/commands/po-ship.md`, `tests/ship.test.sh`
- **Matrice** : D13 (sans flotte), D14
- **Dépendances** : s06

**Critères d'acceptation**
- [ ] `ship_gate_is_mechanical`
- [ ] `ship_always_squashes`
- [ ] `ship_cleans_up_only_on_proven_merge`

### s08-pilotage — Orchestrer, suivre, aider
**En tant que** développeur **je veux** enchaîner le cycle d'une story, voir où en est chaque story et avoir un aide-mémoire **afin de** ne jamais deviner la prochaine commande.

- **Complexité** : 2
- **Owns** : `method/commands/po-orchestrator.md`, `method/commands/po-status.md`, `method/commands/po-help.md`, `method/templates/adr.md`, `tests/pilot.test.sh`
- **Matrice** : D16 (une story), D17 (depuis les fichiers en M1), D18, G04
- **Dépendances** : s07

**Critères d'acceptation**
- [ ] `orchestrator_has_two_real_checkpoints`
- [ ] `status_derives_from_files`
- [ ] `help_is_user_invoked_only`

### s09-installation-dev — Essayer Polype dans un projet
**En tant que** développeur **je veux** installer la version de travail de Polype dans un projet **afin de** la tester avant la distribution de M5.

- **Complexité** : 2
- **Owns** : `bin/polype-dev-install`, `tests/install.test.sh`, section « Installed files » de `method/AGENTS.md`
- **Matrice** : H02 (partiel)
- **Dépendances** : s08

**Critères d'acceptation**
- [ ] `install_copies_commands_agents_skills_templates`
- [ ] `install_assembles_agents_md_from_rules_and_settings`
- [ ] `install_adds_claude_md_import_once`
- [ ] `install_never_touches_settings`

### s10-validation-m1 — Une story de bout en bout
**En tant que** développeur **je veux** faire passer une vraie story dans le cycle complet sur un projet bac à sable **afin de** prouver M1 autrement que par la lecture.

- **Complexité** : 3
- **Owns** : `docs/validation/m1.md`
- **Dépendances** : s09

**Critères d'acceptation**
- [ ] (revue) Le rapport montre, sur un projet réel, un plan validé, un record de vérification à jour, une revue avec preuve de morsure et un ship proprement nettoyé.

## M2 — Le cadrage

Construit par Polype lui-même : chaque story passe par `/po-orchestrator`. Conventions à respecter (détaillées dans `AGENTS.local.md`) :
- **Méthode en anglais** (sauf `po-help`, en français) ; chaque commande et chaque subagent porte une ligne `Reads settings:` ; tout réglage lu existe dans `method/templates/agents-local.md`.
- **Tests** : un fichier `tests/<story>.test.sh` par story, fonctions `test_<nom>` avec les helpers de `tests/lib.sh` (`contains` exact et sensible à la casse, `needs_tool`, `lacks_tool`, `fail` qui termine le test). Le nom de chaque critère d'acceptation est le nom du test.
- **Aucun texte de Killer SaaS** : `tests/overlap.test.sh` échoue sinon (ADR-0006). La matrice de parité (`docs/parite-killer-saas.md`) décrit chaque mécanisme en français : on le réécrit à notre façon, jamais en traduisant une source.
- **Ne jamais modifier** `.claude/` ni `.polype/` (copies installées) : on modifie `method/`.
- Les lignes de la matrice couvertes passent à `fait — <chemin>` dans `docs/parite-killer-saas.md` (fichier possédé par chaque story pour ses propres lignes seulement).

### s11-setup-modes — Choisir le point d'entrée et la source de design au setup
**En tant que** développeur **je veux** que `/po-setup` me demande si je remplace un SaaS, en adapte un, ou pars de zéro, et qui dessine les écrans **afin que** le cadrage suive le bon chemin et que le design ne soit jamais choisi par défaut en silence.

- **Complexité** : 2
- **Dépend de** : aucune
- **Owns** : `method/commands/po-setup.md`, `method/templates/agents-local.md`, `tests/setup-modes.test.sh`
- **Matrice** : C01, B02 (réglages de cadrage, design et voie courte)

**Critères d'acceptation**
- [ ] `settings_template_declares_framing_settings` — le gabarit déclare `Entry mode` (`replace` · `adapt` · `new`), `Design source` (`internal` · `external`), `Design skill`, `Design tool`, `Story track` (`full` · `flow` · `auto`) et `Flow threshold`, chacun documenté dans le tableau des valeurs.
- [ ] `setup_asks_entry_mode_and_design_source` — `po-setup` pose, en plus de ses trois questions, la question du point d'entrée et celle de la source de design (cinq questions au total, pas davantage).
- [ ] `setup_never_defaults_design_silently` — la commande dit qu'une source de design laissée à `—` fera s'arrêter les commandes de design, qui redemanderont.

**Notes pour l'agent** : garder toutes les garanties actuelles de `po-setup` (ne jamais écraser, lire le dépôt avant de demander, commit groupé). `Story track` vaut `auto` et `Flow threshold` vaut `2` par défaut. Les tests M1 de `tests/structure.test.sh` doivent rester verts.

### s12-prd-kill — Cadrer le remplacement ou l'adaptation d'un SaaS existant
**En tant que** développeur **je veux** une commande `/po-prd <SaaS cible>` qui m'interroge une question à la fois sur la cible, le mode, la boucle cœur et le cimetière **afin que** le périmètre copie seulement les 20 % qui comptent.

- **Complexité** : 3
- **Dépend de** : s11
- **Owns** : `method/commands/po-prd.md`, `method/templates/prd.md`, `tests/prd.test.sh`
- **Matrice** : C02, C03

**Critères d'acceptation**
- [ ] `prd_reads_entry_mode_and_refuses_new` — la commande lit `Entry mode` ; avec `new`, elle s'arrête et renvoie vers `/po-brief`.
- [ ] `prd_asks_one_question_at_a_time` — la commande impose une seule question par message et n'écrit rien que l'utilisateur n'a pas validé.
- [ ] `prd_template_has_core_loop_graveyard_and_angle` — le gabarit contient la cible, le mode, la boucle cœur (tableau avec complexité 1–5 et justification), le cimetière explicite, l'angle, les critères de succès mesurables.
- [ ] `prd_challenges_the_angle_in_adapt_mode` — avec `adapt`, l'angle différenciant passe par des questions de mise à l'épreuve (preuve de douleur, consommateur exact, signal de succès) tirées de `docs/references/spec-interrogation.md`.
- [ ] `prd_scores_heavy_features_toward_the_graveyard` — une fonctionnalité notée 4 ou 5 doit justifier sa place, sinon elle rejoint le cimetière.

**Notes pour l'agent** : `remplacer` = remplacement interne (on arrête de payer, on garde les données) ; `adapter` = produit concurrent avec un angle propre. Échelle de complexité : celle de `method/templates/stories.md`. Sortie : `docs/prd.md`, commité sur `Target branch`.

### s13-brief-new — Cadrer une idée neuve par l'interrogation
**En tant que** développeur **je veux** une commande `/po-brief` qui met mon idée à l'épreuve comme un cofondateur sceptique **afin de** partir de zéro sur un brief qui a survécu aux objections.

- **Complexité** : 3
- **Dépend de** : s11
- **Owns** : `method/commands/po-brief.md`, `method/skills/interrogation/`, `method/templates/brief.md`, `tests/brief.test.sh`
- **Matrice** : C04

**Critères d'acceptation**
- [ ] `brief_runs_only_in_new_mode` — la commande lit `Entry mode` et renvoie vers `/po-prd` pour `replace` et `adapt`.
- [ ] `interrogation_skill_has_stance_forcing_questions_gap_map_premortem` — le skill `interrogation` contient la posture sceptique, les sept questions forçantes, la carte des manques avec ses dimensions critiques, le pre-mortem par un subagent en contexte frais, et au moins trois alternatives dont la moins chère.
- [ ] `brief_persists_between_sessions` — le brief est écrit dans `docs/brief.md` avec `status: interviewing` après chaque thème, et la commande reprend là où elle s'était arrêtée.
- [ ] `brief_has_exit_criteria` — la commande ne passe le brief à `status: approved` qu'après les critères de sortie (one-liner, wedge, métrique, trois non-objectifs, dimensions critiques traitées, trouvailles du pre-mortem tranchées, accord de l'utilisateur).

**Notes pour l'agent** : `docs/references/spec-interrogation.md` est le guide de l'utilisateur (son propre skill `/spec`) : on peut le reprendre et l'adapter librement, en anglais, en remplaçant le chemin du vault par `docs/brief.md`.

### s14-stories — Découper le cadrage en stories agentiques
**En tant que** développeur **je veux** une commande `/po-stories` qui transforme le PRD ou le brief en stories livrables **afin que** chaque story soit exécutable par un agent sans deviner.

- **Complexité** : 3
- **Dépend de** : s12, s13
- **Owns** : `method/commands/po-stories.md`, `method/skills/agentic-stories/`, `tests/stories.test.sh`
- **Matrice** : C05

**Critères d'acceptation**
- [ ] `stories_reads_prd_or_brief_by_entry_mode` — la source est `docs/prd.md` (`replace`, `adapt`) ou `docs/brief.md` (`new`, approuvé) ; source absente → arrêt et renvoi vers la bonne commande.
- [ ] `agentic_stories_skill_rejects_technical_layers` — le skill impose des tranches verticales utilisables (jamais « créer la table »), avec un exemple mauvais / bon.
- [ ] `agentic_stories_skill_requires_owns_and_contracts_first` — chaque story déclare `Owns` ; une interface partagée par deux stories devient une story antérieure (contrat d'abord).
- [ ] `stories_split_complexity_five_and_order_dependencies` — un 5 est découpé tout de suite, un 4 annonce son risque, aucune story ne dépend d'une story placée après elle.
- [ ] `stories_never_revive_the_graveyard` — en mode `replace`/`adapt`, rien du cimetière ne devient une story ; chaque story peut pointer l'écran équivalent de la cible.

**Notes pour l'agent** : sortie `docs/stories.md` au format de `method/templates/stories.md`, commitée sur `Target branch`.

### s15-stories-review — Relire le découpage en contexte frais
**En tant que** développeur **je veux** qu'un subagent qui n'a pas écrit les stories les confronte au périmètre **afin qu'**un trou dans le découpage coûte une retouche de markdown et pas des cycles perdus.

- **Complexité** : 3
- **Dépend de** : s14
- **Owns** : `method/commands/po-stories-review.md`, `method/agents/stories-reviewer.md`, `method/skills/stories-review/`, `method/templates/stories-review.md`, `tests/stories-review.test.sh`
- **Matrice** : C06

**Critères d'acceptation**
- [ ] `stories_reviewer_is_read_only_without_shell` — le subagent n'a ni Write, ni Edit, ni Bash, et précharge `stories-review`.
- [ ] `stories_review_checks_coverage_first` — la couverture du périmètre (boucle cœur du PRD, ou wedge et exigences du brief) est vérifiée en premier, table en main ; un élément non couvert est critique.
- [ ] `stories_review_checks_owns_overlap` — deux stories sans dépendance entre elles qui partagent un chemin `Owns` sont signalées.
- [ ] `stories_review_template_ends_with_stories_ready` — le gabarit finit par `Max severity:` puis `Stories ready: yes|no`.
- [ ] `stories_review_is_a_soft_gate` — la commande écrit `docs/reviews/stories.md` sur `Target branch` ; `/po-research` avertit quand ce verdict manque ou vaut `no`, sans bloquer.

**Notes pour l'agent** : l'avertissement dans `/po-research` est une modification de `method/commands/po-research.md` — autorisée pour cette seule phrase ; l'ajouter à la liste des fichiers touchés du plan.

### s16-architect — Poser l'architecture sur un boilerplate
**En tant que** développeur **je veux** une commande `/po-architect` qui part du boilerplate du projet et en tire des conventions écrites comme des règles **afin que** chaque story se conforme au socle au lieu de le réinventer.

- **Complexité** : 3
- **Dépend de** : s14
- **Owns** : `method/commands/po-architect.md`, `method/templates/architecture.md`, `tests/architect.test.sh`
- **Matrice** : C07, C08

**Critères d'acceptation**
- [ ] `architect_asks_for_the_base` — sans boilerplate détecté, la commande propose : un boilerplate du catalogue ou que l'utilisateur possède, un défaut scaffoldé enregistré en ADR, ou un dépôt vide assumé (avec l'avertissement que le parallélisme en souffrira).
- [ ] `architect_analyses_code_before_deciding` — la commande applique `codebase-analysis` au socle et écrit les conventions sous forme de règles dans la section « Conventions » de `AGENTS.local.md`.
- [ ] `architect_records_structural_decisions_as_adrs` — chaque choix structurant (stack, briques par capacité selon ADR-0009, intégrations) devient une ADR dans `docs/decisions/` depuis `templates/adr.md`.
- [ ] `architect_never_rewrites_the_base` — la commande interdit de proposer une réécriture du boilerplate.

**Notes pour l'agent** : le format complet des profils de boilerplate est pour M4 ; ici, la commande lit un profil s'il existe (`boilerplates/<nom>/profile.md`) et sinon analyse le code. Sortie : `docs/architecture.md` commité sur `Target branch` avec les ADR et `AGENTS.local.md`.

### s17-design-system — Consigner le design system une fois
**En tant que** développeur **je veux** une commande `/po-design-system` qui recense tokens et composants et mesure les contrastes une fois **afin que** chaque écran se compose depuis un système stable.

- **Complexité** : 3
- **Dépend de** : s16
- **Owns** : `method/commands/po-design-system.md`, `method/skills/design-doctrine/`, `method/templates/design-system.md`, `tests/design-system.test.sh`
- **Matrice** : C09

**Critères d'acceptation**
- [ ] `design_system_never_invents_an_identity` — sans direction visuelle fournie et sans système dans le boilerplate, la commande s'arrête et demande la source.
- [ ] `design_system_measures_contrast_once` — la commande mesure chaque paire texte/surface en clair et en sombre, corrige les tokens en échec, et dit que c'est la seule étape qui mesure.
- [ ] `design_doctrine_covers_new_vs_derived_and_gaps` — le skill `design-doctrine` couvre écran nouveau (un seul artefact) contre écran dérivé (deltas, aucune maquette), l'interdiction d'inventer composant ou token, les manques consignés, le dépôt qui fait foi, la maquette qui n'est jamais du code.
- [ ] `design_system_template_has_tokens_components_patterns` — le gabarit contient tokens, inventaire des composants, patterns d'états, à faire / à éviter.

### s18-design — Dériver l'écran d'une story
**En tant que** développeur **je veux** une commande `/po-design <story>` qui dérive l'écran du design system **afin que** le plan et l'implémentation partent d'un écran décidé, jamais improvisé.

- **Complexité** : 3
- **Dépend de** : s17
- **Owns** : `method/commands/po-design.md`, `method/templates/design-screen.md`, `method/templates/design-brief.md`, `tests/design.test.sh`
- **Matrice** : D03

**Critères d'acceptation**
- [ ] `design_fails_closed_without_system_or_source` — pas de `docs/design-system.md` ou `Design source` à `—` → arrêt, aucune maquette.
- [ ] `design_distinguishes_new_and_derived_screens` — écran dérivé → `design.md` avec les deltas seulement ; écran nouveau → `design.md` plus exactement un artefact (`mockup.html` en `internal`, `brief.md` en `external`).
- [ ] `design_renders_and_looks_without_measuring` — une maquette est ouverte dans un navigateur via HTTP local, en clair et en sombre, en largeur bureau et mobile ; on cherche ce qui est cassé et on ne mesure rien ; ce qui n'a pas pu être vu est dit.
- [ ] `design_lives_in_the_story_worktree` — tout est écrit dans `docs/designs/<id>/` du worktree de la story, qui fait foi face à tout outil externe.

### s19-flow — La voie courte pour les petites stories
**En tant que** développeur **je veux** une commande `/po-flow <story>` qui fait research et plan en une passe pour une story simple **afin de** ne pas payer six contextes pour une story de complexité 1.

- **Complexité** : 3
- **Dépend de** : s11
- **Owns** : `method/commands/po-flow.md`, `method/templates/plan-flow.md`, `tests/flow.test.sh`
- **Matrice** : D15

**Critères d'acceptation**
- [ ] `flow_keeps_every_gate` — même worktree, plan validé, implementer et reviewer délégués, gate `Ship allowed`, budget de tests : rien n'est allégé, seul le nombre de contextes baisse.
- [ ] `flow_checks_escalation_signals_twice` — les cinq signaux (migration, nouvel écran, autorisation ou périmètre tenant, contrat d'API, nouvelle dépendance) sont vérifiés avant et après la lecture du code ; un seul renvoie vers la voie complète.
- [ ] `flow_respects_story_track` — `Story track: full` refuse la voie courte ; `auto` ne l'accepte qu'à complexité ≤ `Flow threshold`.
- [ ] `plan_flow_template_carries_verified_facts` — le gabarit `plan-flow.md` porte `track: flow` dans son frontmatter, une section de faits vérifiés avec `path:line`, la vérification des signaux, et un plafond d'environ 150 lignes.

### s20-wiring — Relier le cadrage au reste du pipeline
**En tant que** développeur **je veux** que les règles, l'aide, le statut, l'orchestrateur et la revue connaissent les nouvelles étapes **afin que** le pipeline complet se lise et se suive d'un bout à l'autre.

- **Complexité** : 2
- **Dépend de** : s11 à s19
- **Owns** : `method/AGENTS.md`, `method/commands/po-help.md`, `method/commands/po-status.md`, `method/commands/po-orchestrator.md`, `method/agents/reviewer.md`, `tests/wiring.test.sh`
- **Matrice** : D10, D16, D17, D18

**Critères d'acceptation**
- [ ] `rules_list_framing_before_the_story_cycle` — la Loi 1 de `AGENTS.md` montre le cadrage (setup, prd ou brief selon le mode, stories, revue des stories, architecture, design system) avant le cycle par story, avec design et voie courte.
- [ ] `help_lists_every_command` — le test existant `every_command_listed_in_help` reste vert avec les nouvelles commandes.
- [ ] `status_reports_framing_and_track` — `/po-status` affiche l'état du cadrage (prd ou brief, stories, verdict de la revue des stories, architecture, design system) et la piste (`full` ou `flow`) de chaque story.
- [ ] `orchestrator_picks_the_track_and_runs_design` — l'orchestrateur choisit la piste selon `Story track` et `Flow threshold` (et passe la main à `/po-flow` quand elle s'applique), et insère le design pour les stories avec écran.
- [ ] `reviewer_checks_design_conformity_without_measuring` — le reviewer juge la conformité au design system et à l'intention de l'écran ; un composant ou token hors système est majeur, critique s'il casse la cohérence visuelle ; il ne mesure rien.

### s21-design-handoff — Raccorder le design à l'implémentation et au setup
**En tant que** développeur **je veux** qu'une story avec écran passe du design à l'implémentation sans arrêt, et que le setup pose ses questions de design dans le bon ordre **afin que** la première vraie story avec écran traverse le cycle, avec ou sans orchestrateur.

- **Complexité** : 2
- **Dépend de** : s20
- **Owns** : `method/agents/implementer.md`, `method/commands/po-execute.md`, `method/commands/po-plan.md`, `method/commands/po-setup.md`, `tests/design-handoff.test.sh`, `docs/defauts.md`
- **Corrige** : défauts n° 1, 2 et 3 de `docs/defauts.md`

**Critères d'acceptation**
- [ ] `implementer_expects_the_design_folder` — la liste des changements non commités attendus de l'`implementer` inclut `docs/designs/<id>/`, qu'il lit avant les tâches d'écran et commite avec la story.
- [ ] `execute_mentions_the_design_when_present` — `po-execute` signale au subagent, quand `docs/designs/<id>/` existe, que le design fait partie de la story (même sans orchestrateur).
- [ ] `plan_reads_the_design_when_present` — `po-plan` lit `docs/designs/<id>/design.md` quand il existe, et les tâches d'écran s'y tiennent.
- [ ] `setup_asks_design_details_after_the_source` — `po-setup` demande `Design skill` ou `Design tool` dans un appel `AskUserQuestion` séparé, après la réponse sur `Design source`, et seulement pour la valeur choisie.
- [ ] `defects_one_to_three_marked_fixed` — dans `docs/defauts.md`, les lignes 1 à 3 passent à `corrigé par s21`.

**Notes pour l'agent** : les formulations de l'orchestrateur (étape 5, phrase ajoutée au prompt de `/po-execute`) restent valables ; `po-execute` doit porter la même information par lui-même. Les tests existants de `tests/setup-modes.test.sh` qui citent l'ancienne formulation de la question 4 changent avec elle : le dire dans le rapport.

## Correctifs des défauts de M2

Mêmes conventions que M2. Chaque story ferme des lignes de `docs/defauts.md` et les passe à `corrigé par <id>`.

### s22-brief-order — Écrire le brief approuvé seulement après les contrôles
**En tant que** développeur **je veux** que `/po-brief` fasse ses contrôles avant d'écrire quoi que ce soit d'approuvé, et que l'exigence « brief approuvé » de `/po-stories` soit réellement testée **afin qu'**un arrêt en cours de route ne laisse pas un brief à moitié approuvé.

- **Complexité** : 2
- **Dépend de** : aucune
- **Owns** : `method/commands/po-brief.md`, `method/commands/po-stories.md`, `tests/brief.test.sh`, `tests/stories.test.sh`, `docs/defauts.md`
- **Corrige** : défauts n° 4 et 5

**Critères d'acceptation**
- [ ] `brief_checks_before_writing_approved` — la branche, les fichiers d'environnement et tout autre contrôle bloquant passent **avant** l'écriture de `status: approved` et avant l'ADR ; un arrêt laisse le brief en `status: interviewing`.
- [ ] `brief_commits_approval_and_adr_together` — l'approbation et son ADR partent dans le même commit, ou aucun des deux.
- [ ] `stories_requires_an_approved_source_with_a_biting_test` — le test distingue un brief approuvé d'un brief en cours : il échoue si la commande accepte `status: interviewing`.

### s23-stories-review-nongoals — Les non-objectifs jouent le rôle du cimetière
**En tant que** développeur **je veux** que la revue des stories traite les non-objectifs d'un brief comme le cimetière d'un PRD **afin qu'**une story hors périmètre soit signalée aussi bien pour une idée neuve que pour un clone.

- **Complexité** : 2
- **Dépend de** : aucune
- **Owns** : `method/skills/stories-review/SKILL.md`, `method/templates/stories-review.md`, `tests/stories-review.test.sh`, `docs/defauts.md`
- **Corrige** : défaut n° 6

**Critères d'acceptation**
- [ ] `stories_review_treats_non_goals_as_the_graveyard` — pour un brief, le contrôle de périmètre porte sur le wedge et les exigences, et les non-objectifs sont contrôlés comme une liste d'exclusions, jamais « non applicable ».
- [ ] `stories_review_template_separates_scope_and_exclusions` — le gabarit a une section de couverture et une section d'exclusions, chacune remplie quelle que soit la source.

### s24-architect-conventions — Ne jamais perdre une convention écrite à la main
**En tant que** développeur **je veux** que `/po-architect` complète la section Conventions au lieu de la remplacer, et que la protection des blocs de réglages soit testée **afin qu'**une relance ne fasse disparaître ni réglage ni convention.

- **Complexité** : 2
- **Dépend de** : aucune
- **Owns** : `method/commands/po-architect.md`, `tests/architect.test.sh`, `docs/defauts.md`
- **Corrige** : défauts n° 7 et 8

**Critères d'acceptation**
- [ ] `architect_merges_conventions_instead_of_replacing` — à la relance, les conventions déjà présentes sont conservées ; les nouvelles s'ajoutent, et une convention contredite est signalée à l'utilisateur au lieu d'être écrasée en silence.
- [ ] `architect_protects_the_settings_blocks` — la commande ne touche aucun bloc de réglages, et le test échoue si cette garantie disparaît du fichier.

### s25-method-lint — Un linter qui fait mordre les règles de méthode
**En tant que** développeur **je veux** un contrôle mécanique des invariants de la méthode **afin qu'**une règle supprimée d'un prompt fasse échouer la suite, au lieu de passer parce qu'un test cherchait seulement une phrase.

- **Complexité** : 3
- **Dépend de** : aucune
- **Owns** : `bin/po-lint`, `tests/lint.test.sh`, `tests/design.test.sh`, `tests/design-system.test.sh`, `tests/flow.test.sh`, `docs/defauts.md`
- **Corrige** : défauts n° 9, 10 et 11

**Critères d'acceptation**
- [ ] `lint_checks_every_command_declares_its_settings` — `bin/po-lint` échoue si une commande ou un subagent n'a pas de ligne `Reads settings:`, ou lit un réglage absent du gabarit.
- [ ] `lint_checks_tool_permissions_match_the_contract` — il échoue si une commande qui interdit d'écrire du code possède Write, Edit ou Bash, si un subagent qui juge possède Write, ou si une commande qui pose une question n'a pas AskUserQuestion.
- [ ] `lint_checks_fail_closed_rules_have_a_stop` — chaque règle annoncée comme bloquante (un fichier manquant, un réglage à `—`, un verdict négatif) est suivie d'un arrêt explicite dans le même paragraphe ; sinon il échoue.
- [ ] `lint_is_part_of_the_suite` — `tests/lint.test.sh` lance `bin/po-lint` et échoue avec lui.
- [ ] `design_stop_rules_bite` — les tests de `/po-design`, `/po-design-system` et `/po-flow` vérifient la conséquence de chaque règle (l'arrêt, l'absence de production, l'escalade), pas seulement la présence d'une phrase.

**Notes pour l'agent** : `bin/po-lint` est un script bash sans dépendance, à la façon de `bin/ks-overlap`. Il lit `method/` et sort non nul en listant chaque manquement avec `fichier:ligne`. Les règles qu'il vérifie sont celles que l'on peut décider sans interpréter : présence, permissions, voisinage d'un arrêt.

## M3 — La flotte

Objectif : faire avancer plusieurs stories en parallèle, reprendre après un arrêt, et garder toutes les garanties du cycle. Architecture retenue : [ADR-0016](decisions/ADR-0016-flotte-un-driver-des-subagents.md) — un driver unique qui lance des subagents.

### s26-planner — Le subagent qui explore et planifie
**En tant que** développeur **je veux** un subagent `planner` qui fait la research et le plan d'une story dans son worktree **afin que** le driver puisse lancer plusieurs stories à la fois, puisqu'un subagent ne peut pas exécuter une commande.

- **Complexité** : 3
- **Dépend de** : aucune
- **Owns** : `method/agents/planner.md`, `tests/planner.test.sh`
- **Matrice** : D02 et D04 côté flotte

**Critères d'acceptation**
- [ ] `planner_carries_the_research_and_plan_contracts` — le subagent porte les exigences de `/po-research` (vérification des hypothèses, faits avec `path:line`, plafond) et de `/po-plan` (tâches vérifiables, interdits, pivot, budget de tests, plafond), sans les réécrire à sa façon.
- [ ] `planner_preloads_testing_doctrine_and_codebase_analysis` — les deux skills sont préchargés.
- [ ] `planner_never_writes_code` — il n'écrit que `docs/research/<id>.md` et `docs/plans/<id>.md`, et s'arrête si le worktree ou la branche ne correspondent pas.
- [ ] `planner_reports_the_track_it_used` — il dit s'il a produit une research séparée ou un plan de voie courte, selon `Story track` et `Flow threshold`.

### s27-drive — Le driver de la flotte
**En tant que** développeur **je veux** une commande `/po-drive` qui fait avancer toutes les stories prêtes en parallèle **afin de** ne plus lancer une story à la fois.

- **Complexité** : 4 — risque : plusieurs lanes écrivent dans le même dépôt ; l'isolation tient aux worktrees et à `Owns`.
- **Dépend de** : s26
- **Owns** : `method/commands/po-drive.md`, `method/templates/agents-local.md`, `tests/drive.test.sh`
- **Matrice** : D05 et D16 côté flotte

**Critères d'acceptation**
- [ ] `drive_picks_a_ready_set_without_conflicts` — sont prêtes les stories non livrées dont toutes les dépendances sont livrées et dont les chemins `Owns` ne recoupent ni ceux des autres lanes en cours ni ceux du lot choisi ; au plus `Parallel` lanes.
- [ ] `drive_dispatches_lanes_in_one_message` — les subagents d'une vague sont lancés ensemble, `planner` puis `implementer` puis `reviewer` par lane, chacun selon son contrat.
- [ ] `drive_never_writes_code_or_verdicts` — le driver n'a ni Write ni Edit ; il prépare les worktrees, lance, vérifie et rapporte.
- [ ] `drive_ships_serially_after_each_review` — les ships passent un par un sur la branche cible, gate `Ship allowed` compris ; une story bloquée repart en fix run dans la limite de `Max attempts`.
- [ ] `settings_template_declares_fleet_settings` — `Parallel` (défaut 3), `Max attempts` (défaut 2) et `Tracker` (`none` par défaut ; `github` quand le dépôt a un remote) sont déclarés et documentés.

**Notes pour l'agent** : `Tracker: github` n'est pas implémenté ici ; la valeur est déclarée et la commande dit qu'elle la traitera quand le dépôt aura un remote. L'état d'une story se lit dans son worktree et dans git, comme le fait `/po-status`.

### s28-ownership — Le diff d'une story reste dans ce qu'elle possède
**En tant que** développeur **je veux** que le dépassement de périmètre d'une story soit détecté **afin que** deux lanes parallèles ne se marchent pas dessus sans qu'on le voie.

- **Complexité** : 2
- **Dépend de** : s27
- **Owns** : `method/agents/reviewer.md`, `method/skills/review-antihallu/SKILL.md`, `tests/ownership.test.sh`
- **Matrice** : A02 et D09 côté flotte

**Critères d'acceptation**
- [ ] `reviewer_checks_the_diff_against_owns` — la revue compare les fichiers du diff aux chemins `Owns` de la story ; un fichier hors périmètre est un finding majeur, critique s'il appartient à une autre story en cours.
- [ ] `review_procedure_places_the_ownership_step_first` — le contrôle de périmètre vient avant la lecture du diff, car il décide de ce qui doit être lu.

### s29-resume — Reprendre une flotte interrompue
**En tant que** développeur **je veux** que `/po-drive` reprenne ce qui existe déjà **afin qu'**un arrêt, un crash ou une session close ne fasse pas recommencer les stories à zéro.

- **Complexité** : 3
- **Dépend de** : s27
- **Owns** : `method/commands/po-drive.md`, `tests/resume.test.sh`
- **Matrice** : D17 côté flotte

**Critères d'acceptation**
- [ ] `drive_resumes_from_what_exists` — pour chaque story, l'étape atteinte se déduit des fichiers du worktree (research, plan validé ou non, record, revue) et de git ; la lane reprend à l'étape suivante.
- [ ] `drive_status_reports_lanes` — `/po-drive status` liste les lanes en cours, les tentatives, les stories bloquées et ce qu'elles attendent, sans rien lancer.
- [ ] `drive_detects_an_orphan_worktree` — un worktree dont la branche ou le chemin ne correspond pas est signalé et n'est jamais réparé en silence.

### s30-grouped-validation — Valider les plans d'une vague en une fois
**En tant que** développeur **je veux** approuver les plans d'une vague en une seule question **afin de** garder un regard humain sans sérialiser la flotte.

- **Complexité** : 2
- **Dépend de** : s27
- **Owns** : `method/commands/po-drive.md`, `docs/decisions/ADR-0017-validation-groupee.md`, `tests/grouped-validation.test.sh`
- **Matrice** : ADR-0014 (volet restant)

**Critères d'acceptation**
- [ ] `drive_groups_plan_approval_per_wave` — avec `Plan validation: human`, le driver présente les plans de la vague dans un seul `AskUserQuestion` : approuver tout, choisir, ou arrêter ; seuls les plans approuvés passent à `validated: yes`.
- [ ] `drive_says_when_nobody_reviewed` — avec `autonomous`, le driver le dit explicitement dans son rapport de vague.
- [ ] `adr_0017_records_the_remaining_scope_of_adr_0014` — une ADR acceptée enregistre que la validation groupée reste, que le ship se fait par story (ADR-0015), et qu'ADR-0014 est remplacée.

### s31-fleet-wiring — Relier la flotte aux règles, à l'aide et au statut
**En tant que** développeur **je veux** que les règles, l'aide et le statut connaissent la flotte **afin qu'**on sache la lancer, la suivre et l'arrêter sans lire les fichiers de méthode.

- **Complexité** : 2
- **Dépend de** : s26 à s30
- **Owns** : `method/AGENTS.md`, `method/commands/po-help.md`, `method/commands/po-status.md`, `tests/fleet-wiring.test.sh`, `docs/parite-killer-saas.md`
- **Matrice** : D05, D16, D17, A02, D09 — statuts à mettre à jour

**Critères d'acceptation**
- [ ] `rules_describe_the_fleet` — `AGENTS.md` explique qu'une flotte est un driver et des lanes, que les ships restent en série, et que `Owns` borne chaque story.
- [ ] `help_lists_po_drive` — le test `every_command_listed_in_help` reste vert avec `/po-drive`.
- [ ] `status_shows_lanes_and_attempts` — `/po-status` affiche, pour une flotte en cours, les lanes, les tentatives et les stories bloquées.
- [ ] `parity_matrix_reflects_the_fleet` — les lignes A02, D05, D09, D16 et D17 passent à `fait — <chemin>`.

### s32-fleet-consistency — Une lane complète, un linter honnête, des documents d'accord
**En tant que** développeur **je veux** que la flotte respecte le cycle complet, que le linter ne certifie que ce qu'il a lu, et que les documents ne se contredisent pas **afin que** ce qui est livré en M3 soit fiable.

- **Complexité** : 3
- **Dépend de** : s31
- **Owns** : `method/commands/po-drive.md`, `bin/po-lint`, `tests/lint.test.sh`, `tests/drive.test.sh`, `docs/parite-killer-saas.md`, `docs/conception.md`, `docs/defauts.md`
- **Corrige** : défauts n° 12, 13 et 14

**Critères d'acceptation**
- [ ] `drive_lane_includes_design_when_the_story_has_a_screen` — une lane insère l'étape de design entre le plan et l'implémentation pour une story avec écran, aux conditions de `/po-design` (design system présent, `Design source` décidé) ; sans elles, la lane s'arrête et le dit, elle ne saute pas l'étape.
- [ ] `lint_fails_when_it_reads_nothing` — `bin/po-lint` sort non nul si le listage des fichiers de méthode échoue ou ne renvoie aucun fichier, et n'affiche jamais un résumé favorable dans ce cas.
- [ ] `lint_reports_how_many_files_it_read` — le résumé indique le nombre de fichiers lus, et le test le vérifie sur un répertoire vide comme sur le vrai.
- [ ] `matrix_and_adr_index_agree_on_the_fleet` — la matrice dit d'une seule voix où vit l'état de la flotte, et `docs/conception.md` présente ADR-0017 comme la décision vivante, ADR-0014 comme remplacée.

### s33-real-parallelism — Des lanes qui tournent vraiment ensemble
**En tant que** développeur **je veux** que les lanes d'une vague soient lancées en un seul message, que le driver ne se déplace jamais, et que les ADR ne se disputent pas de numéro **afin que** la flotte tienne la promesse du parallélisme.

- **Complexité** : 3
- **Dépend de** : s32
- **Owns** : `method/commands/po-drive.md`, `method/agents/planner.md`, `tests/drive.test.sh`, `docs/defauts.md`
- **Corrige** : défauts n° 22, 23 et 24

**Critères d'acceptation**
- [ ] `drive_dispatches_a_whole_stage_in_one_message` — la commande exige explicitement que tous les subagents d'une même étape d'une vague partent dans **un seul message** (plusieurs appels d'outil dans ce message), et interdit d'enchaîner un appel par message ; elle dit pourquoi : un appel par message revient à exécuter les lanes l'une après l'autre.
- [ ] `drive_reports_what_it_observed_not_what_it_intended` — le rapport de vague indique, par étape, combien de subagents ont été lancés ensemble ; il n'affirme jamais un parallélisme qu'il n'a pas exercé.
- [ ] `drive_uses_absolute_paths_only` — le driver ne change jamais de répertoire : il passe par `git -C <chemin absolu>` et donne des chemins absolus aux subagents ; le test échoue si la commande autorise un `cd`.
- [ ] `shared_numbering_is_assigned_by_the_driver` — les numéros d'ADR sont attribués par le driver avant le lancement d'une vague, un par lane qui en a besoin, et le planner ne choisit jamais un numéro lui-même.
