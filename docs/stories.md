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

## Passe de défauts et M5 — La distribution

### s34-method-consistency — Fermer les incohérences relevées par les revues
**En tant que** développeur **je veux** que les documents de méthode disent tous la même chose **afin qu'**un agent ne tombe pas sur deux règles contradictoires.

- **Complexité** : 2
- **Dépend de** : aucune
- **Owns** : `method/templates/review.md`, `method/commands/po-drive.md`, `method/agents/planner.md`, `tests/drive.test.sh`, `tests/design.test.sh`, `tests/ownership.test.sh`, `docs/defauts.md`
- **Corrige** : défauts n° 17, 18, 19, 20, 29 et 30

**Critères d'acceptation**
- [ ] `review_template_has_an_ownership_section` — le gabarit de revue porte le contrôle d'ownership en tête, avant les six étapes, avec une case par cas (dans le périmètre, hors périmètre, périmètre d'une autre lane, story sans `Owns`).
- [ ] `drive_resume_table_is_complete_and_ordered` — chaque état de reprise dit à quelle étape la lane repart ; les cas qui se recouvrent ont une priorité déclarée, en particulier un arrêt survenu après un fix run.
- [ ] `drive_requires_overlapping_lanes_not_a_message_shape` — la commande demande que les lanes d'une vague se chevauchent dans le temps et que le rapport le prouve par leurs fenêtres d'activité ; elle n'impose plus une forme de lancement.
- [ ] `planner_writes_only_its_documents_and_the_adr_assigned_to_it` — le planner écrit la recherche, le plan et, seulement si le driver lui a attribué un numéro, l'ADR correspondante ; la contradiction interne disparaît.
- [ ] `design_test_message_matches_its_assertion` — le test de `/po-design` vérifie ce que son message d'échec annonce.

### s35-fleet-design — Une lane mène aussi une story avec écran
**En tant que** développeur **je veux** qu'une story avec écran traverse sa lane sans intervention **afin que** la flotte n'ait pas besoin d'un humain au milieu d'une vague.

- **Complexité** : 3
- **Dépend de** : s34
- **Owns** : `method/agents/designer.md`, `method/commands/po-drive.md`, `tests/fleet-design.test.sh`, `docs/defauts.md`
- **Corrige** : défaut n° 24

**Critères d'acceptation**
- [ ] `designer_agent_carries_the_design_contract` — un subagent `designer` porte les exigences de `/po-design` (écran dérivé contre écran nouveau, un seul artefact, rendu et regardé, aucun composant inventé, manques consignés) et précharge `design-doctrine`.
- [ ] `drive_inserts_design_between_plan_and_execute` — pour une story avec écran, la lane lance le `designer` après le plan et avant l'implémentation.
- [ ] `drive_stops_a_screen_lane_without_a_design_system` — sans `docs/design-system.md` ou avec `Design source` à `—`, la lane s'arrête, le dit, et ne saute jamais l'étape.
- [ ] `designer_writes_only_in_the_story_design_folder` — il n'écrit que dans `docs/designs/<id>/`.

### s36-installer — Un installeur digne de ce nom
**En tant que** développeur **je veux** un installeur qui pose, met à jour et retire Polype proprement **afin de** ne plus dépendre d'un script de développement.

- **Complexité** : 3
- **Dépend de** : aucune
- **Owns** : `bin/polype`, `bin/polype-dev-install`, `tests/installer.test.sh`, `docs/installation.md`
- **Matrice** : H01, H02

**Critères d'acceptation**
- [ ] `installer_supports_install_update_check_and_remove` — `bin/polype install <projet>`, `update`, `check` et `remove` existent et font ce qu'ils annoncent.
- [ ] `installer_update_leaves_no_ghost` — la mise à jour supprime les fichiers d'une version précédente qui ne sont plus livrés, et ne touche jamais un fichier que le projet a ajouté.
- [ ] `installer_check_reports_drift` — `check` liste les fichiers installés qui ont été modifiés sur place, et sort non nul quand il y en a.
- [ ] `installer_stamps_a_version` — la version installée est écrite dans `.polype/version` et affichée par `check`.
- [ ] `installer_remove_leaves_the_project_intact` — `remove` retire ce que l'installeur a posé, garde `AGENTS.local.md`, les documents du projet et son `.gitignore`.

**Notes pour l'agent** : reprendre le comportement de `bin/polype-dev-install` (manifeste, assemblage d'`AGENTS.md`, import unique dans `CLAUDE.md`, sauvegarde d'un `AGENTS.md` écrit à la main, `.gitignore`, `--hooks`) et le remplacer ; garder un alias `bin/polype-dev-install` qui appelle le nouveau, pour ne pas casser les scripts existants.

### s37-global-install — Polype sur toutes les machines
**En tant que** développeur **je veux** installer Polype une fois pour toutes dans `~/.claude` et l'activer projet par projet **afin d'**avoir les mêmes commandes partout, synchronisées par chezmoi.

- **Complexité** : 3
- **Dépend de** : s36
- **Owns** : `bin/polype`, `tests/global-install.test.sh`, `docs/installation.md`
- **Matrice** : H01 (volet global), ADR-0004

**Critères d'acceptation**
- [ ] `installer_global_puts_commands_in_the_user_home` — `bin/polype install --global` pose commandes, subagents et skills dans `~/.claude/` (chemin surchargé par une variable d'environnement pour les tests), et la charge utile dans `~/.claude/polype/`.
- [ ] `installer_init_activates_a_project_after_a_global_install` — `bin/polype init <projet>` dépose dans le projet ce qui doit y vivre (templates, gate, règles, `CLAUDE.md`) sans recopier les commandes déjà globales.
- [ ] `installer_global_update_is_idempotent` — deux installations globales successives laissent le même état, sans doublon.
- [ ] `docs_explain_the_chezmoi_path` — `docs/installation.md` explique comment suivre `~/.claude/polype/` avec chezmoi et ce qu'il ne faut pas y mettre.

### s38-migration — Remplacer /spec et /drive
**En tant que** développeur **je veux** savoir exactement quoi retirer et comment reprendre mes projets en cours **afin de** passer de `/spec` et `/drive` à Polype sans perdre de travail.

- **Complexité** : 2
- **Dépend de** : s37
- **Owns** : `docs/migration.md`, `tests/migration-doc.test.sh`
- **Matrice** : H01 (volet migration)

**Critères d'acceptation**
- [ ] `migration_maps_every_old_concept` — le document fait correspondre chaque notion de `/spec` et `/drive` à son équivalent Polype (brief, stories, packets, worktrees, tracker, autonomie) et dit ce qui disparaît.
- [ ] `migration_gives_a_step_by_step_removal` — il liste les fichiers à retirer de `~/.claude/skills/` et ce qu'il faut vérifier avant.
- [ ] `migration_covers_a_project_in_flight` — il explique comment reprendre un projet qui a déjà des packets en cours.
- [ ] `migration_doc_is_checked_by_a_test` — un test vérifie que le document existe, couvre les deux skills et ne renvoie vers aucun chemin inexistant.

### s39-distribution-wiring — Dire partout comment on installe
**En tant que** développeur **je veux** que les règles, l'aide et la documentation racontent la même installation **afin qu'**on n'ait pas à lire les scripts.

- **Complexité** : 2
- **Dépend de** : s38
- **Owns** : `method/AGENTS.md`, `method/commands/po-help.md`, `README.md`, `docs/parite-killer-saas.md`, `tests/distribution-wiring.test.sh`
- **Matrice** : H01 à H04, statuts à mettre à jour

**Critères d'acceptation**
- [ ] `rules_point_at_the_installer` — la section des fichiers installés cite `bin/polype` et distingue installation globale et activation d'un projet.
- [ ] `help_mentions_installation_and_status` — l'aide dit en une ligne comment installer et comment vérifier une installation.
- [ ] `readme_describes_the_project_and_its_install` — le `README.md` du dépôt décrit Polype, son cycle, sa flotte et son installation, sans promettre ce qui n'existe pas.
- [ ] `parity_matrix_reflects_the_distribution` — les lignes H01 à H04 passent à `fait — <chemin>` ou disent ce qui reste.

## M4 — Le catalogue

Objectif : qu'un projet puisse démarrer sur un boilerplate connu, avec des briques choisies et non subies. Décisions : [ADR-0008](decisions/ADR-0008-catalogue-de-profils-gratuits-dabord.md), [ADR-0009](decisions/ADR-0009-briques-optimales-interchangeables.md), [ADR-0010](decisions/ADR-0010-next-forge-premier-profil.md), [ADR-0020](decisions/ADR-0020-briques-par-defaut-des-capacites.md).

### s40-profile-format — Le format d'un profil de boilerplate
**En tant que** développeur **je veux** un format de profil que tous les agents lisent de la même façon **afin qu'**un boilerplate soit décrit une fois et exploité partout.

- **Complexité** : 2
- **Dépend de** : aucune
- **Owns** : `method/templates/profile.md`, `bin/po-lint`, `tests/profile.test.sh`, `docs/catalogue.md`
- **Matrice** : B03, C07 (volet profil)

**Critères d'acceptation**
- [ ] `profile_template_declares_every_section` — le gabarit impose : identité et licence, commandes du projet, carte du code, granularité d'ownership, où vit chaque règle, capacités fournies avec leurs briques, inventaire UI, pièges connus.
- [ ] `profile_commands_map_to_settings` — la section des commandes donne exactement les noms de réglages du projet (`Install`, `Test`, `Typecheck`, `E2E`, `Build`), pour être recopiée sans traduction.
- [ ] `lint_checks_profiles` — `bin/po-lint` vérifie chaque `boilerplates/*/profile.md` : sections présentes, commandes nommées comme les réglages, capacités tirées de la liste d'ADR-0020 ; il échoue et nomme le fichier sinon.
- [ ] `catalogue_doc_explains_the_three_levels` — `docs/catalogue.md` explique les trois niveaux (maison, tiers profilé, aucun) et ce que chacun coûte en parallélisme.

### s41-capability-bricks — Le catalogue des capacités et de leurs briques
**En tant que** développeur **je veux** que le choix d'une brique soit guidé par un document unique **afin que** l'architecture ne réinvente pas ce choix à chaque projet.

- **Complexité** : 3
- **Dépend de** : s40
- **Owns** : `method/skills/capability-bricks/`, `method/commands/po-architect.md`, `tests/capability-bricks.test.sh`, `docs/catalogue.md`
- **Matrice** : B02 (volet briques), C07 (volet capacités)

**Critères d'acceptation**
- [ ] `skill_lists_the_capabilities_and_their_default_bricks` — le skill `capability-bricks` reprend le tableau d'ADR-0020 (capacité, brique par défaut, alternatives) et dit quand basculer sur une alternative.
- [ ] `skill_defines_what_a_contract_test_must_prove` — pour chaque capacité, il dit ce qu'un test de contrat doit prouver de n'importe quelle brique (au minimum : le comportement nominal, le refus attendu, et l'effet observable côté données).
- [ ] `architect_chooses_bricks_and_records_the_gaps` — `/po-architect` compare les briques du profil à celles d'ADR-0020, retient un choix par capacité, et enregistre chaque écart en ADR de projet.
- [ ] `self_hosted_edition_has_no_payment_brick` — le skill rappelle qu'une édition auto-hébergée se construit sans brique de paiement, et que l'offre gérée porte abonnement et usage.

### s42-next-forge-profile — Le profil de next-forge
**En tant que** développeur **je veux** un profil réel pour next-forge **afin de** pouvoir démarrer un projet dessus sans le relire entièrement.

- **Complexité** : 3 — risque : le profil doit décrire le dépôt réel, pas ce qu'on en suppose.
- **Dépend de** : s40, s41
- **Owns** : `boilerplates/next-forge/profile.md`, `tests/next-forge-profile.test.sh`
- **Matrice** : ADR-0010

**Critères d'acceptation**
- [ ] `next_forge_profile_passes_the_lint` — `bin/po-lint` accepte le profil.
- [ ] `next_forge_profile_is_grounded_in_the_real_repository` — chaque commande, chemin et capacité citée est vérifiée dans une copie du dépôt (`git clone --depth 1 https://github.com/vercel/next-forge` dans un dossier temporaire), avec le commit relevé dans le profil.
- [ ] `next_forge_profile_states_its_gaps_against_adr_0020` — il nomme les capacités dont la brique par défaut du boilerplate diffère de celle d'ADR-0020 (auth, base, fichiers notamment) et ce qu'il faut écrire pour les remplacer.
- [ ] `next_forge_profile_declares_ownership_granularity` — il dit quel chemin une story peut posséder seule, en s'appuyant sur le découpage en packages.

**Notes pour l'agent** : cloner dans `/tmp` ou un dossier temporaire, jamais dans le dépôt ; ne recopier aucun fichier du boilerplate, seulement le décrire.

### s43-mustelinet-bricks — Les briques auto-hébergées pour les prototypes
**En tant que** développeur **je veux** savoir exactement quoi déployer chez mustelinet pour chaque capacité **afin qu'**un prototype tourne sans compte tiers.

- **Complexité** : 3
- **Dépend de** : s41
- **Owns** : `boilerplates/bricks/`, `tests/bricks.test.sh`, `docs/catalogue.md`
- **Matrice** : ADR-0020 (volet mustelinet)

**Critères d'acceptation**
- [ ] `each_default_brick_has_a_note` — une note par brique par défaut d'ADR-0020 déployable chez mustelinet (Postgres, stockage S3, jobs, email, observabilité, déploiement) : ce qu'elle fournit, comment elle tourne là-bas, ses réglages, ses sauvegardes.
- [ ] `notes_state_what_mustelinet_does_not_provide` — chaque note dit ce que l'hébergeur ne fournit pas et ce que cela implique (ni base ni stockage objet managés, publication HTTP/HTTPS seulement).
- [ ] `notes_give_a_contract_test_checklist` — chaque note liste ce qu'un test de contrat doit prouver pour cette brique.
- [ ] `bricks_are_documentation_not_code` — aucune note ne prétend livrer du code ; elles décrivent le déploiement et les contrats.

### s44-catalogue-wiring — Raccorder le catalogue au cadrage
**En tant que** développeur **je veux** que le setup et l'architecture proposent le catalogue **afin qu'**un nouveau projet en profite sans le connaître.

- **Complexité** : 2
- **Dépend de** : s42, s43
- **Owns** : `method/commands/po-setup.md`, `method/commands/po-help.md`, `method/AGENTS.md`, `docs/parite-killer-saas.md`, `tests/catalogue-wiring.test.sh`
- **Matrice** : C01 (volet boilerplate), B03, statuts à mettre à jour

**Critères d'acceptation**
- [ ] `setup_offers_the_catalogue` — `/po-setup` propose les profils disponibles quand le projet démarre sans boilerplate, et enregistre le choix.
- [ ] `rules_name_the_catalogue` — les règles disent où vivent les profils et que l'architecture s'appuie dessus.
- [ ] `help_mentions_the_catalogue` — l'aide cite le catalogue en une ligne.
- [ ] `parity_matrix_reflects_the_catalogue` — B03, C01 et C07 passent à `fait — <chemin>` ou disent précisément ce qui reste.

### s45-clean-uninstall — Une désinstallation qui ne laisse rien derrière
**En tant que** développeur **je veux** que `polype remove` ne laisse pas de fichier vide **afin qu'**un projet désinstallé soit vraiment propre.

- **Complexité** : 1
- **Dépend de** : aucune
- **Owns** : `bin/polype`, `tests/installer.test.sh`, `docs/defauts.md`
- **Corrige** : défaut n° 31

**Critères d'acceptation**
- [ ] `remove_deletes_a_claude_md_it_created` — si `CLAUDE.md` ne contenait que l'import de Polype, il est supprimé ; s'il contenait autre chose, seule la ligne d'import part.
- [ ] `remove_leaves_no_empty_file_behind` — après désinstallation, aucun fichier vide créé par l'installeur ne subsiste.

### s46-adr-directory — Le dossier des ADR devient un réglage
**En tant que** développeur **je veux** qu'un projet choisisse où vivent ses ADR **afin qu'**un dépôt qui numérote déjà ses décisions ailleurs ne contredise pas la méthode.

- **Complexité** : 2
- **Dépend de** : aucune
- **Owns** : `method/templates/agents-local.md`, `method/templates/architecture.md`, `method/AGENTS.md`, `method/commands/po-architect.md`, `method/commands/po-plan.md`, `method/commands/po-brief.md`, `method/commands/po-drive.md`, `method/commands/po-status.md`, `method/agents/planner.md`, `method/agents/implementer.md`, `method/agents/reviewer.md`, `method/agents/designer.md`, `method/agents/stories-reviewer.md`, `AGENTS.local.md`, `tests/adr-directory.test.sh`, `tests/architect.test.sh`, `docs/stories.md`, `docs/parite-killer-saas.md`
- **Matrice** : G04 (volet chemin)

**Critères d'acceptation**
- [ ] `settings_template_declares_the_adr_directory` — le gabarit déclare `ADR directory`, valeur par défaut `docs/decisions/`, documenté dans le tableau des valeurs comme « où vivent les ADR du projet, avec sa propre numérotation ».
- [ ] `rules_read_the_adr_directory_instead_of_a_fixed_path` — la Loi 6 de `AGENTS.md` parle de `<ADR directory>NNNN-<slug>.md` et non plus d'un chemin écrit en dur.
- [ ] `every_command_that_writes_an_adr_reads_the_setting` — `/po-architect` et `/po-plan`, ainsi que les subagents qui lisent ou écrivent une ADR, déclarent `ADR directory` dans leur ligne `Reads settings:` et l'utilisent.
- [ ] `lint_accepts_the_new_setting` — `bin/po-lint` reste vert, et il échouerait si une commande lisait un réglage absent du gabarit.

**Notes pour l'agent** : ne pas renommer le dossier de ce dépôt-ci, qui garde `docs/decisions/` par défaut. Les ADR acceptées existantes ne sont pas déplacées. Le premier projet qui s'en sert est nautile, dont les critères d'acceptation nomment déjà des fichiers sous `docs/adr/`.

## M6 — La preuve

Objectif : qu'une gate ne puisse plus être contournée par un commit tardif, un test neutralisé ou un fichier hors périmètre, que les vérifications soient enregistrées par un outil plutôt que déclarées, et que ce que l'utilisateur verra soit vérifié avec des preuves. Source : [docs/references/gstack-agent-skills.md](references/gstack-agent-skills.md). Décision : [ADR-0022](decisions/ADR-0022-qa-et-bornes-tenues-par-des-hooks.md). Revue du découpage : [docs/reviews/stories-m6.md](reviews/stories-m6.md). Toute story de ce jalon passe `bin/ks-overlap` contre les sources de gstack (`28f1385`) et d'agent-skills (`1401c8b`) avant sa PR : on reprend des mécanismes, jamais leur texte (ADR-0006).

### s47-review-tree — La revue liée au code qu'elle a jugé
**En tant que** développeur **je veux** qu'un verdict de revue ne vaille que pour le code relu **afin qu'**un commit ajouté après un « oui » ne parte pas au ship sans relecture.

- **Complexité** : 3
- **Dépend de** : aucune
- **Owns** : `method/hooks/po-gate.sh`, `method/templates/review.md`, `method/commands/po-review.md`, `method/agents/reviewer.md`, `method/commands/po-ship.md`, `method/commands/po-drive.md`, `method/commands/po-status.md`, `method/AGENTS.md`, `tests/gate.test.sh`, `tests/review.test.sh`, `tests/ship.test.sh`, `tests/drive.test.sh`, `docs/defauts.md`
- **Corrige** : défaut n° 32

**Critères d'acceptation**
- [ ] `review_template_records_the_reviewed_tree` — le gabarit de revue porte une ligne `Reviewed tree: <40 hex>`, l'arbre de `story/<id>` relevé avant que la revue commence.
- [ ] `ship_allowed_fails_when_code_changed_after_review` — `po-gate ship-allowed` refuse quand le code hors `docs/` diffère de `Reviewed tree:`, et nomme `/po-review <id>` comme commande à relancer.
- [ ] `ship_allowed_ignores_docs_changes_after_review` — un changement limité à `docs/` après le verdict ne rouvre pas la revue.
- [ ] `ship_allowed_fails_without_reviewed_tree` — une revue sans ligne `Reviewed tree:` exploitable est refusée, comme une revue absente.
- [ ] `rules_and_ship_describe_the_bound_verdict` — la Loi 3, `/po-ship` (contrôle manuel sans hook) et `/po-status` décrivent le verdict lié à l'arbre, plus seulement la dernière ligne `Ship allowed:`.
- [ ] `drive_sends_a_stale_review_back_to_review` — dans la table de reprise de `/po-drive`, une revue favorable dont l'arbre ne correspond plus au code renvoie la lane à la revue, pas au ship.

**Notes pour l'agent** : reprendre la comparaison de `verif_current` (`git diff --quiet <tree> HEAD -- . ':(exclude)docs'`) dans une fonction partagée plutôt que d'en écrire une seconde. Les revues déjà écrites dans `docs/reviews/` ne sont pas réécrites : elles concernent des stories livrées. `tests/drive.test.sh` cite la phrase actuelle du contrôle de ship (vers la ligne 84) : la mettre à jour avec le texte. Passer le défaut n° 32 à « corrigé par s47 ».

### s48-floor-guard — Le garde contre l'abaissement de la barre
**En tant que** développeur **je veux** que la revue repère tout ce qu'une story fait pour rendre les vérifications plus faciles à passer **afin qu'**un test neutralisé ou une règle de lint coupée ne passent pas pour un succès.

- **Complexité** : 3
- **Dépend de** : s47
- **Owns** : `method/hooks/po-gate.sh`, `method/templates/review.md`, `method/skills/review-antihallu/`, `tests/floor-guard.test.sh`

**Critères d'acceptation**
- [ ] `floor_guard_flags_new_suppressions` — `po-gate floor-guard <id> <base>` signale les directives ajoutées par le diff de la story qui coupent un contrôle : ignore de typecheck, désactivation de lint, exclusion de couverture, test marqué `skip` ou `only`.
- [ ] `floor_guard_flags_weakened_tests` — il signale un fichier de test supprimé, et un fichier de test dont le nombre d'assertions baisse ; une assertion est une ligne qui contient `expect(` ou `assert` (`assert`, `assert.`, `self.assert`).
- [ ] `floor_guard_flags_empty_catch_and_lowered_thresholds` — il signale un `catch` vide ajouté, un drapeau strict passé à `false` dans `tsconfig*.json`, et une valeur de seuil de couverture abaissée dans la configuration de Jest ou Vitest, `pyproject.toml` ou `.coveragerc`.
- [ ] `floor_guard_has_three_outcomes` — sortie 0 (rien), 1 (signalements, listés avec fichier et ligne), 2 (impossible de vérifier) ; le code 2 n'est jamais lu comme propre.
- [ ] `review_runs_the_floor_guard` — la procédure de revue lance le garde avec `Target branch` comme base et classe chaque signalement : justifié dans le plan → mineur, sinon majeur ; un fichier de test supprimé sans justification → critique.

**Notes pour l'agent** : `po-gate` ne lit aucun réglage, d'où la base passée en argument. Le garde ne lit que les lignes ajoutées ou retirées par `git diff <base>...story/<id>`, jamais tout le dépôt. Les motifs couvrent au moins TypeScript/JavaScript et Python ; une liste par langage, facile à compléter.

### s49-secret-scan — Les secrets refusés au commit
**En tant que** développeur **je veux** que le pre-commit refuse un secret indexé **afin que** la règle sur les fichiers `.env` ne dépende plus de la vigilance d'un agent.

- **Complexité** : 2
- **Dépend de** : s48
- **Owns** : `method/hooks/po-gate.sh`, `method/AGENTS.md`, `tests/gate.test.sh`

**Critères d'acceptation**
- [ ] `pre_commit_refuses_a_staged_env_file` — un `.env` ou `.env.*` indexé est refusé, sauf `.env.example`.
- [ ] `pre_commit_refuses_obvious_keys` — une ligne ajoutée qui contient une clé privée PEM ou un jeton au format connu (AWS, GitHub, Stripe, Anthropic) est refusée, et le message nomme le fichier sans afficher la valeur.
- [ ] `secret_scan_runs_on_every_branch` — ce contrôle s'applique aussi hors des branches `story/*`, contrairement au contrôle du plan.
- [ ] `rules_point_at_the_secret_gate` — la Loi 6 dit que le pre-commit refuse les secrets quand les hooks sont activés, et garde la relecture de `git status` pour les projets qui ne les activent pas.

**Notes pour l'agent** : ne jamais afficher la valeur trouvée, ni dans le message ni dans les tests. Les clés factices des tests sont assemblées à l'exécution, par concaténation : écrites en clair dans `tests/gate.test.sh`, elles seraient refusées par le pre-commit de ce dépôt et par la protection de push de GitHub.

### s50-implementer-bounds — Les bornes de l'implementer tenues par un hook
**En tant que** développeur **je veux** que l'implementer ne puisse écrire que dans les chemins de sa story **afin que** la ligne `Owns` soit tenue pendant l'écriture et pas seulement constatée en revue.

- **Complexité** : 4 — risque : un hook qui échoue à se lancer est traité par Claude Code comme une erreur non bloquante ; le hook laisserait alors tout passer.
- **Dépend de** : aucune
- **Owns** : `method/agents/implementer.md`, `method/hooks/po-bounds.sh`, `bin/polype`, `docs/installation.md`, `tests/bounds.test.sh`

**Critères d'acceptation**
- [ ] `implementer_declares_a_pretooluse_hook` — le frontmatter de l'implementer déclare un hook PreToolUse sur Edit, Write et Bash qui appelle `.polype/hooks/po-bounds.sh`.
- [ ] `bounds_hook_blocks_when_the_script_cannot_run` — la commande du hook transforme tout échec de lancement du script (fichier absent, non exécutable) en code de sortie 2, le seul que Claude Code traite comme un refus.
- [ ] `bounds_deny_writes_outside_owns` — une écriture hors des chemins `Owns` de la story et de `docs/` est refusée, avec le chemin et la ligne `Owns` dans le message.
- [ ] `bounds_deny_forbidden_git_verbs` — sont refusés, y compris dans une commande composée : `git switch`, `git checkout`, `git stash`, `git worktree add`, `git push`, et `git commit` quand la branche n'est pas `story/<id>`.
- [ ] `bounds_fail_closed` — story introuvable, `Owns` absent ou entrée illisible → code 2, jamais accord par défaut.
- [ ] `installer_ships_the_bounds_hook` — `polype init` et `polype install <projet>` posent `po-bounds.sh` sous `.polype/hooks/`, à côté de `po-gate.sh`.
- [ ] `installation_doc_names_the_upgrade_path` — `docs/installation.md` dit qu'après la mise à jour globale, chaque projet déjà activé relance `polype init <projet>` : sans `po-bounds.sh` dans le dépôt, le hook fermé refuse toute écriture de l'implementer.

**Notes pour l'agent** : `bin/po-lint` et `tests/fleet-design.test.sh` lisent le frontmatter des agents ; lancer `bin/po-lint` et la suite après avoir ajouté le bloc `hooks:`. Vérifier d'abord dans la documentation de Claude Code que le frontmatter d'un subagent accepte un bloc `hooks:` et comment il traite un code de sortie autre que 2 ; si ce n'est pas le cas, s'arrêter et le signaler plutôt que de déplacer le hook dans `settings.json`. Le script reçoit une option de mode (`implementer` ici, `qa` pour s51) qui fixe les chemins permis. Le hook ne remplace pas le contrôle d'ownership de la revue, qui reste. Les redirections de Bash vers un fichier ne sont pas analysées : on borne les verbes git, pas tout le shell.

### s51-qa-agent — Une QA en navigateur qui laisse des preuves
**En tant que** développeur **je veux** qu'un agent parcoure en navigateur les écrans touchés par une story et en garde la trace **afin que** les défauts qui rendent une feature inutilisable sortent avant la revue, preuves à l'appui.

- **Complexité** : 4 — risque : l'outil navigateur disponible change d'une session à l'autre ; l'agent doit le détecter, et s'arrêter proprement quand il n'y en a pas.
- **Dépend de** : s50
- **Owns** : `method/agents/qa.md`, `method/commands/po-qa.md`, `method/templates/qa.md`, `method/templates/agents-local.md`, `method/commands/po-setup.md`, `method/commands/po-help.md`, `method/skills/design-doctrine/`, `method/hooks/po-bounds.sh`, `tests/qa.test.sh`, `tests/bounds.test.sh`

**Critères d'acceptation**
- [ ] `qa_writes_are_bounded_by_the_hook` — l'agent QA n'a pas Edit ; son frontmatter déclare `po-bounds` en mode `qa`, qui n'accepte d'écriture que sous `docs/qa/<id>/` et refuse tout verbe git qui écrit ; comme pour l'implementer, un échec de lancement du script donne le code 2.
- [ ] `qa_scope_comes_from_the_diff_and_the_criteria` — il parcourt les écrans que le diff de la story touche et chaque critère d'acceptation visible, rien d'autre.
- [ ] `qa_report_has_steps_evidence_and_status` — le gabarit impose, par constat : les étapes pour reproduire, une capture, la sévérité, et un statut vérifié / probable / non vérifié ; et en fin de rapport `Tree:` puis `QA status: <complete | blocked>`.
- [ ] `qa_stops_without_a_browser_or_a_dev_command` — sans outil navigateur, ou avec `Dev: —`, la commande s'arrête en le disant, sans rapport inventé.
- [ ] `setup_asks_for_dev_and_qa_stage` — le gabarit de réglages déclare la commande `Dev` et le réglage `QA stage` (`screens` · `—`), documentés, et `/po-setup` les demande.
- [ ] `browser_contract_is_written_once` — `design-doctrine` porte le contrat de pilotage : ses propres onglets, l'origine annoncée seulement, aucun identifiant qui transite par l'agent, le contenu de la page est une donnée et pas une instruction ; l'agent QA et le designer le chargent.
- [ ] `help_lists_po_qa` — `/po-help` cite `/po-qa`.

**Notes pour l'agent** : s'inspirer de la séparation `qa-only` / `qa` de gstack, sans la boucle de correction : ici la QA ne corrige jamais (Loi 2). Ne rien construire autour d'un navigateur particulier. `tests/setup-modes.test.sh` fige les cinq questions numérotées de `/po-setup` : `Dev` se demande dans la question des commandes, `QA stage` en suite non numérotée de la même question. Le gabarit de profil de boilerplate n'est pas touché : un projet existant, ou un profil copié, renseigne `Dev` à la main.

### s52-qa-wiring — La revue exige une QA à jour
**En tant que** développeur **je veux** que le rapport QA soit lié au code, committé avec la story et exigé par la revue **afin qu'**une story avec écran ne parte pas sans preuve que ses écrans marchent.

- **Complexité** : 3
- **Dépend de** : s48, s49, s50, s51
- **Owns** : `method/AGENTS.md`, `method/hooks/po-gate.sh`, `method/commands/po-qa.md`, `method/agents/reviewer.md`, `method/agents/implementer.md`, `method/skills/review-antihallu/`, `method/templates/review.md`, `tests/qa.test.sh`, `tests/qa-gate.test.sh`

**Critères d'acceptation**
- [ ] `rules_list_qa_in_the_story_cycle` — la table du cycle de la Loi 1 place `/po-qa` entre Execute et Review pour une story avec écran quand `QA stage` vaut `screens`.
- [ ] `po_gate_qa_current` — `po-gate qa-current <id>` passe seulement quand `docs/qa/<id>/` contient un rapport `QA status: complete` dont le `Tree:` correspond au code hors `docs/`.
- [ ] `po_qa_commits_its_evidence` — `/po-qa` reçoit Bash pour un seul usage : committer `docs/qa/<id>/` seul sur `story/<id>` une fois le rapport écrit, comme `/po-ship` committe la revue ; il n'a toujours ni Write ni Edit, sa description ne dit plus qu'il ne lance pas de shell, et la Loi 6 cite ce commit à côté de celui de l'implementer.
- [ ] `review_requires_a_current_qa_report` — pour une story avec écran, quand `QA stage` vaut `screens`, le reviewer lance `po-gate qa-current` à la première étape de `review-antihallu`, à côté de `verif-current` ; un échec bloque la revue, et un constat QA vérifié et non corrigé devient un finding. Le reviewer déclare `QA stage` dans sa ligne `Reads settings:`.
- [ ] `implementer_hands_the_screen_to_qa` — la consigne de `implementer.md` d'ouvrir l'écran dans un navigateur renvoie désormais à l'étape QA quand `QA stage` vaut `screens`, et reste telle quelle sinon.

**Notes pour l'agent** : `/po-review` n'a pas Bash (`tests/review.test.sh` le fige) : la gate tourne dans le reviewer, pas dans la commande. `tests/qa.test.sh` fige l'absence de Bash dans `/po-qa` : ce test change avec le texte, et vérifie désormais l'absence de Write et d'Edit. `docs/qa/<id>/` rejoint la liste des fichiers de preuve que le contrôle d'ownership de `review-antihallu` tient pour dans le périmètre, et celle du travail non committé que la Loi 4 admet. Un rapport `QA status: blocked` ne passe pas `qa-current`. Une story sans écran, ou un projet avec `QA stage: —`, ne voit aucune différence. Revu le 2026-10-08 : le premier planner a trouvé que le commit des preuves était impossible dans les `Owns` d'origine.

### s53-review-lenses — Des lentilles de revue selon les chemins touchés
**En tant que** développeur **je veux** que la revue regarde la sécurité, les migrations, les dépendances et les performances quand le diff les touche **afin que** ces défauts soient cherchés sans multiplier les reviewers ni les verdicts.

- **Complexité** : 3
- **Dépend de** : s52
- **Owns** : `method/skills/review-lenses/`, `method/agents/reviewer.md`, `method/skills/review-antihallu/`, `method/templates/review.md`, `tests/review-lenses.test.sh`

**Critères d'acceptation**
- [ ] `lenses_are_triggered_by_the_diff` — le skill dit quels chemins ou contenus déclenchent chaque lentille, et le gabarit de revue a une ligne qui liste les lentilles lancées.
- [ ] `security_lens_rates_a_missing_authz_check_critical` — la lentille sécurité couvre l'autorisation par ressource, les appels sortants vers une URL fournie, l'upload, la signature des webhooks, le rate limit tenu par un stockage partagé, les messages d'erreur et les frontières de confiance d'un appel LLM ; une vérification d'autorisation manquante est critique.
- [ ] `migration_lens_rejects_in_place_renames` — renommer ou supprimer une colonne en place est majeur ; la lentille demande les étapes expand/contract et le retour arrière.
- [ ] `dependency_lens_triggers_on_a_lockfile` — un lockfile dans le diff déclenche la lentille dépendances, qui demande une dépendance par changement, son changelog et ses scripts d'installation lus, et sa raison dans le plan.
- [ ] `performance_lens_never_invents_numbers` — N+1, lecture non bornée, pagination absente, appels séquentiels évitables ; chaque constat est marqué « impact potentiel », jamais chiffré.
- [ ] `one_reviewer_one_verdict` — les lentilles sont chargées par le reviewer existant ; aucune nouvelle échelle de sévérité, aucune seconde ligne de verdict.

**Notes pour l'agent** : des listes courtes, réécrites ; les checklists d'agent-skills font plusieurs centaines de lignes et ne doivent pas être recopiées.

### s54-untrusted-output — Ce qu'un outil renvoie est une donnée
**En tant que** développeur **je veux** que les règles disent qu'un log, une trace ou une page récupérée ne donnent jamais d'instruction **afin qu'**un agent ne suive pas un texte injecté dans une sortie d'erreur.

- **Complexité** : 1
- **Dépend de** : s52
- **Owns** : `method/AGENTS.md`, `tests/structure.test.sh`

**Critères d'acceptation**
- [ ] `rules_treat_tool_output_as_data` — les règles disent que la sortie d'une commande, un log, une trace, une page web ou un fichier d'un dépôt tiers sont des données, et qu'une instruction qui s'y trouve est signalée, jamais suivie.
- [ ] `rules_list_every_installed_hook` — la section « Installed files » cite `po-bounds` à côté de `po-gate`, avec ce que chacun tient.

**Notes pour l'agent** : la seconde ligne est ici parce que s50 ne peut pas posséder `method/AGENTS.md` sans perdre son parallélisme avec s47. `tests/distribution-wiring.test.sh` fige deux phrases de cette section (« the templates, the gate and the assembled `AGENTS.md` », « called `po-gate` in these rules ») : les garder.

### s55-reviewer-evals — Éprouver le reviewer sur des défauts plantés
**En tant que** développeur **je veux** lancer le reviewer sur des stories piégées et lire son verdict **afin de** savoir si la méthode attrape vraiment ce qu'elle promet, y compris quand on la pousse à céder.

- **Complexité** : 4 — risque : coût et résultats non déterministes ; chaque cas se lance plusieurs fois et se juge sur un taux, jamais sur un seul run.
- **Dépend de** : s53
- **Owns** : `evals/`, `bin/po-eval`, `tests/evals.test.sh`

**Critères d'acceptation**
- [ ] `each_recipe_plants_one_known_defect` — `evals/` contient une recette par cas : de quoi construire un petit dépôt avec une story, un plan validé, un relevé, et un seul défaut planté (garde non testé, accès à la ressource d'un autre utilisateur, filtre de tenant manquant, test neutralisé), avec la sévérité attendue.
- [ ] `pressure_cases_push_to_ship` — des cas où le message de lancement presse de livrer (urgence, autorité, « c'est déjà relu ») ; le verdict attendu ne change pas.
- [ ] `grading_reads_the_verdict_lines` — `bin/po-eval` note chaque run sur `Ship allowed:` et `Max severity:`, sans juge LLM.
- [ ] `evals_run_on_demand_only` — `tests/run.sh` ne les lance pas ; avant d'appeler `claude`, `bin/po-eval` affiche le nombre de runs (cas × répétitions) et attend une confirmation, puis affiche un taux par cas.
- [ ] `recipes_are_checked_structurally` — `tests/evals.test.sh` vérifie seulement que chaque recette déclare son défaut et son verdict attendu.

**Notes pour l'agent** : chaque run construit son dépôt dans un dossier temporaire, jamais dans ce dépôt. Les runs utilisent `claude -p` avec les agents installés de Polype.

### s56-evidence-runner — Un relevé de vérification écrit par un outil
**En tant que** développeur **je veux** que chaque vérification passe par un lanceur qui en écrit lui-même le résultat **afin que** le relevé de vérification cesse d'être une déclaration de l'agent.

- **Complexité** : 3
- **Dépend de** : s50, s52, s54, s55
- **Owns** : `method/hooks/po-run.sh`, `method/hooks/po-gate.sh`, `method/templates/verification-record.md`, `method/agents/implementer.md`, `method/skills/testing-doctrine/`, `method/AGENTS.md`, `bin/polype`, `evals/`, `tests/run-ledger.test.sh`, `tests/gate.test.sh`, `tests/execute.test.sh`

**Critères d'acceptation**
- [ ] `po_run_passes_the_exit_code_through` — `po-run --story <id> --label <check> -- <commande>` lance la commande, rend son code de sortie tel quel et laisse passer sa sortie.
- [ ] `po_run_appends_a_row` — chaque lancement ajoute au relevé `docs/verif/<id>.md` une ligne : libellé, commande, code de sortie, arbre du code (`git write-tree` après `git add -A`), horodatage UTC.
- [ ] `verif_current_requires_a_passing_run_per_check` — les contrôles déclarés sont les lignes du tableau du relevé dont la commande n'est pas `—` ; `po-gate verif-current` refuse un relevé où l'un d'eux n'a pas de ligne `po-run` portant sur le même code hors `docs/` que `Tree:`, ou dont la dernière ligne a un code non nul.
- [ ] `implementer_runs_checks_through_po_run` — l'implementer et la doctrine de test lancent chaque suite et le typecheck via `po-run`, et ne recopient plus de résultat à la main.
- [ ] `po_run_refuses_outside_a_story_worktree` — hors d'une branche `story/<id>` correspondant à `--story`, il refuse sans lancer la commande.
- [ ] `eval_recipes_follow_the_new_record` — les recettes de `evals/` construisent des relevés au nouveau format, et `tests/evals.test.sh` reste vert.

**Notes pour l'agent** : chaque lancement écrit dans `docs/verif/`, donc deux arbres complets diffèrent d'un run à l'autre ; la comparaison porte sur le code hors `docs/`, comme `verif_current` aujourd'hui, jamais sur l'égalité des hashes. `tests/gate.test.sh` construit des relevés sans lignes `po-run` et `tests/execute.test.sh` fige l'appel à `write-tree` dans l'implementer et la forme du gabarit : les mettre à jour avec le texte. Le relevé reste en git, dans `docs/verif/`, jamais sous `~/` comme le fait gstack. `po-run` n'écrit jamais la sortie de la commande dans le relevé (elle peut contenir des secrets), seulement son code. La section « Installed files » des règles cite `po-run`.

### s57-qa-in-the-fleet — La QA lancée par l'orchestrateur et la flotte
**En tant que** développeur **je veux** que l'orchestrateur et la flotte lancent la QA d'une story avec écran **afin qu'**elle se fasse sans qu'on y pense, et que `/po-status` dise où elle en est.

- **Complexité** : 3 — risque : la table de reprise de `/po-drive`, où une ligne mal ordonnée renvoie une lane au mauvais stade.
- **Dépend de** : s52
- **Owns** : `method/commands/po-orchestrator.md`, `method/commands/po-drive.md`, `method/commands/po-status.md`, `method/commands/po-help.md`, `method/commands/po-review.md`, `README.md`, `tests/drive.test.sh`, `tests/fleet-design.test.sh`, `tests/review.test.sh`, `tests/qa-fleet.test.sh`

**Critères d'acceptation**
- [ ] `orchestrator_runs_qa_for_a_screen` — `/po-orchestrator` lance `/po-qa` entre l'exécution et la revue pour une story avec écran quand `QA stage` vaut `screens`.
- [ ] `drive_wave_includes_qa` — la vague de `/po-drive` passe à `planner designer implementer qa reviewer` pour une story avec écran.
- [ ] `drive_resumes_on_qa_current` — la table de reprise de `/po-drive` décide d'une QA manquante ou périmée avec `po-gate qa-current`, comme les autres lignes décident avec `po-gate`.
- [ ] `status_reports_qa` — `/po-status` dit, par story avec écran, si son rapport QA existe et s'il correspond au code.
- [ ] `help_and_readme_show_qa` — l'aide et le `README.md` montrent l'étape.
- [ ] `qa_blocked_review_goes_back_to_qa` — une revue bloquée parce que `po-gate qa-current` échoue renvoie à `/po-qa <id>`, pas à un fix run : `/po-review` le dit dans sa conclusion, `/po-orchestrator` et la reprise de `/po-drive` relancent la QA puis la revue, et ce retour ne consomme aucune unité de `Max attempts`.

**Notes pour l'agent** : `tests/drive.test.sh` et `tests/fleet-design.test.sh` figent l'ordre des subagents de la vague : les mettre à jour avec le texte, pas les contourner. Une story sans écran garde la vague à quatre subagents. Le dernier critère vient du majeur M1 de `docs/reviews/s52-qa-wiring.md` : `/po-review` et l'orchestrateur envoient aujourd'hui toute revue bloquée en fix run, que l'implementer ne peut pas résoudre puisqu'il ne remplace pas la QA. Une revue bloquée se reconnaît comme bloquée par la QA à sa ligne `Next action:` qui nomme `/po-qa`. Le mineur m2 de cette même revue (un rapport à jour mais non committé passe `qa-current`) reste ouvert : `po-gate.sh` n'est pas dans les `Owns` de cette story.

## Correctifs hors jalon

### s58-designer-browser — Le designer peut ouvrir son écran dans un navigateur
**En tant que** développeur **je veux** que le designer et `/po-design` aient accès à l'outil navigateur de la session **afin que** la maquette soit vraiment regardée, comme leurs propres fichiers le demandent.

- **Complexité** : 2
- **Dépend de** : aucune
- **Owns** : `method/agents/designer.md`, `method/commands/po-design.md`, `tests/fleet-design.test.sh`, `tests/design.test.sh`, `tests/designer-browser.test.sh`, `docs/defauts.md`
- **Corrige** : défaut n° 33

**Critères d'acceptation**
- [ ] `designer_inherits_the_session_browser` — le frontmatter du designer ne restreint plus ses outils par une liste `tools:` qui exclut le navigateur ; il suit la forme retenue pour l'agent QA par ADR-0026 (pas de `tools:`, `disallowedTools` pour ce qu'il ne doit pas avoir), sans perdre Write, Edit ni Bash dont il a besoin.
- [ ] `po_design_can_reach_a_browser` — `/po-design` ne limite plus ses outils à une liste qui exclut le navigateur de la session.
- [ ] `design_still_writes_no_source_file` — la consigne qui interdit au designer et à `/po-design` d'écrire un fichier source reste en place.

**Notes pour l'agent** : ne nommer aucun navigateur ni serveur MCP particulier (`tests/qa.test.sh` vérifie qu'aucun `mcp__`, `playwright` ou `chrome` n'apparaît dans `method/`). Les tests qui lisent le frontmatter du designer (`tests/fleet-design.test.sh`) se mettent à jour avec le texte. Passer le défaut n° 33 à « corrigé par s58 ».

### s59-model-by-complexity — Décider sur le modèle fort, exécuter sur un modèle adapté
**En tant que** développeur **je veux** que tout ce qui décide (plan, design, revue, QA) tourne toujours sur le modèle le plus fort, et que seule l'écriture du code s'adapte à la complexité de la story **afin de** ne pas dépenser le modèle le plus cher sur l'exécution d'un plan simple, sans jamais affaiblir une décision.

- **Complexité** : 3 — risque : la valeur `model` passée à l'outil Agent ; un nom que l'outil refuse fait échouer la lane, donc la commande doit dire quoi faire d'un refus.
- **Dépend de** : s56, s57
- **Owns** : `method/agents/implementer.md`, `method/templates/agents-local.md`, `method/commands/po-drive.md`, `method/commands/po-orchestrator.md`, `method/commands/po-flow.md`, `method/commands/po-execute.md`, `method/commands/po-review.md`, `method/commands/po-qa.md`, `method/commands/po-stories-review.md`, `method/commands/po-setup.md`, `tests/execute.test.sh`, `tests/model-routing.test.sh`
- **Décision** : ADR-0032

**Critères d'acceptation**
- [ ] `settings_declare_the_model_routing` — le gabarit de réglages déclare `Model strong`, `Model light` et `Light up to`, documentés : `Model strong` et `Model light` prennent un nom de modèle accepté par l'outil Agent ou `—` (le modèle de la session), `Light up to` est la complexité la plus haute dont l'implementer tourne sur `Model light`.
- [ ] `implementer_no_longer_pins_a_model` — le frontmatter de l'implementer passe de `model: opus` à `model: inherit`.
- [ ] `deciders_always_run_on_the_strong_model` — le planner, le designer, le reviewer, l'agent QA et le stories-reviewer sont dispatchés sur `Model strong` par chaque commande qui les lance (`/po-drive`, `/po-orchestrator`, `/po-flow`, `/po-review`, `/po-qa`, `/po-stories-review`), quelle que soit la complexité.
- [ ] `only_the_implementer_adapts` — `/po-drive`, `/po-orchestrator`, `/po-flow` et `/po-execute` dispatchent l'implementer sur `Model light` quand la complexité de la story ne dépasse pas `Light up to`, sur `Model strong` au-delà ; une valeur `—` ne passe aucun modèle. Un fix run garde la règle.
- [ ] `drive_reports_the_model_of_each_lane` — le rapport de `/po-drive` dit, par lane et par étape, le modèle utilisé.
- [ ] `setup_offers_the_defaults` — `/po-setup` propose `Model strong: opus`, `Model light: sonnet`, `Light up to: 2`, sans ajouter de question numérotée (`tests/setup-modes.test.sh` fige les cinq questions).

**Notes pour l'agent** : la règle vient de l'utilisateur, le 2026-10-08 : la prise de décision et le plan se font toujours sur un modèle fort, et le niveau ne s'adapte qu'à l'exécution. La complexité lue est celle que la recherche a re-notée quand elle existe, sinon celle de `docs/stories.md`. Un refus du modèle par l'outil Agent arrête la lane et le dit ; on ne retombe jamais en silence sur un autre modèle. Polype lui-même règle `Model strong: opus`, `Model light: sonnet`, `Light up to: 2` dans son `AGENTS.local.md` une fois la story livrée, à la main.

## M7 — Durcissement

Objectif : fermer les faiblesses que les revues de M6, s58 et s59 ont laissées en majeur, et les mineurs qui reviennent d'une revue à l'autre. Chaque story cite le rapport d'où vient le constat. Validé par l'utilisateur le 2026-10-08.

### s60-gate-parsing — Les gates qui ne laissent plus passer un cas mal formé
**En tant que** développeur **je veux** que `po-gate` refuse ce qu'il ne sait pas lire et voie ce qu'il ratait **afin qu'**une gate ne s'ouvre jamais par défaut de lecture.

- **Complexité** : 3
- **Dépend de** : aucune
- **Owns** : `method/hooks/po-gate.sh`, `tests/floor-guard.test.sh`, `tests/gate.test.sh`, `tests/run-ledger.test.sh`, `tests/qa-gate.test.sh`
- **Corrige** : majeurs de `docs/reviews/s48-floor-guard.md` (×2), `s49-secret-scan.md`, `s56-evidence-runner.md` (M1), mineur m2 de `s52-qa-wiring.md`

**Critères d'acceptation**
- [ ] `floor_guard_flags_a_test_renamed_out_of_the_test_tree` — un fichier de test renommé vers un chemin qui n'est plus un test (hors arborescence de tests, ou suffixe que le lanceur ignore) est signalé comme un test supprimé.
- [ ] `floor_guard_says_2_on_an_unreadable_diff` — un diff que le garde ne sait pas lire donne la sortie 2 ; un test neutralise cette règle et échoue.
- [ ] `secret_scan_finds_a_pem_key_after_an_escaped_newline` — une clé PEM qui suit un `\n` littéral dans une chaîne d'une ligne est refusée.
- [ ] `verif_current_refuses_a_malformed_checks_row` — une ligne de `## Checks` qui n'a pas ses trois cellules, ou dont le libellé ressemble à un séparateur, fait refuser le relevé en nommant la ligne.
- [ ] `qa_current_requires_a_committed_report` — `po-gate qa-current` refuse un rapport QA à jour mais non committé.

**Notes pour l'agent** : chaque constat est décrit, avec sa reproduction, dans le rapport de revue cité. La ligne PEM est un cas particulier de la règle de frontière gauche : l'exception porte sur la ligne `private-key` seule.

### s61-bounds-owns — Des `Owns` qui ne s'élargissent pas et qui acceptent des globs
**En tant que** développeur **je veux** que les bornes d'une story soient lues là où la story a commencé, et que leur syntaxe soit définie **afin que** l'implementer ne puisse pas élargir ses propres bornes, et qu'un projet réel puisse écrire ses `Owns` sans être bloqué.

- **Complexité** : 3
- **Dépend de** : aucune
- **Owns** : `method/hooks/po-bounds.sh`, `tests/bounds.test.sh`, `method/templates/stories.md`, `method/skills/agentic-stories/`, `tests/stories.test.sh`
- **Corrige** : majeurs de `docs/reviews/s50-implementer-bounds.md` (×2)

**Critères d'acceptation**
- [ ] `owns_are_read_where_the_story_started` — `po-bounds` lit les `Owns` dans le `docs/stories.md` du point de départ de la branche (sa base de fusion avec la branche d'où elle part), pas dans `HEAD` : un commit de la story qui élargit ses `Owns` n'élargit pas ses bornes.
- [ ] `owns_accept_globs` — une entrée `Owns` avec `*` (un segment) ou `**` (plusieurs) borne les chemins qui y correspondent.
- [ ] `owns_syntax_is_written_once` — le gabarit de stories et `agentic-stories` disent la syntaxe d'une entrée : un chemin entre backticks, un dossier finissant par `/`, ou un glob.
- [ ] `bounds_refuse_an_entry_they_cannot_read` — une entrée hors syntaxe est refusée en la nommant, jamais ignorée.

**Notes pour l'agent** : ADR-0024 lit les `Owns` dans `HEAD` ; changer ce point demande une ADR qui la remplace, numérotée par la flotte. La revue de s50 donne la reproduction de l'auto-élargissement et du projet nautile bloqué par ses globs.

### s62-bounds-scan — Un texte cité n'est plus une commande
**En tant que** développeur **je veux** que `po-bounds` ne prenne pas pour une commande git le texte qu'une commande écrit dans un fichier **afin que** l'implementer cesse d'être bloqué quand il écrit de la documentation qui cite ces commandes.

- **Complexité** : 3
- **Dépend de** : s61
- **Owns** : `method/hooks/po-bounds.sh`, `tests/bounds.test.sh`
- **Corrige** : faux positifs relevés par les implementers de s49, s52 et s56 ; majeur de `docs/reviews/s51-qa-agent.md`

**Critères d'acceptation**
- [ ] `bounds_ignore_heredoc_bodies` — le corps d'un heredoc n'est pas lu comme une commande ; la commande qui l'ouvre l'est.
- [ ] `bounds_ignore_quoted_arguments` — une chaîne entre guillemets passée en argument (`grep "git checkout"`, `printf '…git commit…'`) n'est pas lue comme une commande.
- [ ] `bounds_still_catch_real_verbs` — `git checkout`, `git stash`, `git push` et un commit hors `story/<id>` restent refusés, y compris après `&&`, `;` ou dans `$(…)`.
- [ ] `qa_allowlist_refuses_writing_forms` — en mode `qa`, `git symbolic-ref` avec deux arguments et toute option `--output` sont refusés.
- [ ] `bounds_refuse_moving_a_branch` — en mode `implementer`, `git branch -f`, `git branch -D`, `git update-ref` et `git reset` sur une autre branche que `story/<id>` sont refusés : déplacer la branche de départ élargirait les bornes lues au point de départ (ADR-0038).

**Notes pour l'agent** : ADR-0024 a choisi une analyse par mots en acceptant les faux positifs ; cette story la remplace pour les heredocs et les arguments cités, ce qui demande une ADR. Rester en bash, `jq` et `awk`.

### s63-review-texts — Ce que la revue tient pour acquis
**En tant que** développeur **je veux** que la revue tienne les ADR de la story pour son propre périmètre, et que ses textes ne se contredisent pas **afin que** chaque revue cesse de relever le même faux écart, et qu'une lentille puisse ouvrir ce dont elle a besoin.

- **Complexité** : 2
- **Dépend de** : aucune
- **Owns** : `method/skills/review-antihallu/`, `method/skills/review-lenses/`, `tests/ownership.test.sh`, `tests/review-lenses.test.sh`
- **Corrige** : mineur « ADR hors Owns » relevé par huit revues de M6 ; majeur de `docs/reviews/s53-review-lenses.md` ; mineur m2 de `s56-evidence-runner.md`

**Critères d'acceptation**
- [ ] `story_adrs_are_in_scope_by_construction` — le contrôle d'ownership tient pour dans le périmètre une ADR que le diff ajoute sous `<ADR directory>` et que le plan de la story annonce.
- [ ] `a_lens_opens_what_the_diff_calls` — une lentille juge ce que le diff change, et ouvre ce que ce code appelle pour confirmer un constat.
- [ ] `the_manual_record_check_names_the_runs` — la phrase qui décrit le contrôle du relevé sans hook cite les lignes `## Runs`, plus seulement la comparaison d'arbre.
- [ ] `qa_current_failure_names_an_uncommitted_report` — la liste des causes d'échec de `qa-current` dans `review-antihallu` cite le rapport à jour mais non committé, dont la suite est le commit des preuves et non une nouvelle visite.

### s64-qa-routing — Le retour en QA partout, et seulement quand il le faut
**En tant que** développeur **je veux** qu'une revue soit traitée comme bloquée par la QA seulement quand elle est bloquée, et que toutes les commandes la renvoient au même endroit **afin qu'**aucune revue ne parte en QA par erreur, ni en fix run inutile.

- **Complexité** : 3
- **Dépend de** : s60
- **Owns** : `method/commands/po-review.md`, `method/commands/po-orchestrator.md`, `method/commands/po-drive.md`, `method/commands/po-flow.md`, `method/commands/po-execute.md`, `method/commands/po-status.md`, `tests/qa-fleet.test.sh`
- **Corrige** : majeur et mineur de `docs/reviews/s57-qa-in-the-fleet.md` ; limite notée dans ADR-0034

**Critères d'acceptation**
- [ ] `qa_blocked_needs_a_blocked_status` — une revue n'est « bloquée par la QA » que si elle porte `Review status: blocked` et que son `Next action:` nomme `/po-qa`.
- [ ] `flow_and_execute_send_qa_blocks_to_qa` — `/po-flow` et `/po-execute` lancés à la main renvoient une revue bloquée par la QA vers `/po-qa`, pas vers un fix run.
- [ ] `status_agrees_with_the_fleet_on_a_blocked_report` — pour un rapport QA `blocked`, `/po-status` dit qu'un humain décide, comme `/po-drive`.
- [ ] `drive_resumes_on_an_uncommitted_report` — depuis que `qa-current` exige un rapport committé (s60), la table de reprise de `/po-drive` reconnaît un rapport à jour mais non committé et fait le commit des preuves sans nouvelle visite, au lieu de renvoyer la lane en QA ; la phrase qui disait qu'un rapport non committé passe `qa-current` est corrigée.

**Notes pour l'agent** : le dernier critère vient du planner de s60 (2026-10-08) : la ligne de la table de reprise qui faisait le commit des preuves d'un rapport non committé ne pouvait plus s'appliquer, puisque `qa-current` échoue désormais sur ce rapport ; `tests/qa-fleet.test.sh` cite cette ligne.

### s65-upgrade-path — Une mise à jour qui dit ce qui manque
**En tant que** développeur **je veux** que l'installeur signale les réglages que le gabarit a gagnés et que mon projet n'a pas **afin qu'**une mise à jour de Polype ne bloque pas un projet en silence.

- **Complexité** : 3
- **Dépend de** : s62
- **Owns** : `bin/polype`, `docs/installation.md`, `tests/installer.test.sh`, `method/commands/po-plan.md`, `method/commands/po-design.md`, `method/commands/po-research.md`, `tests/model-routing.test.sh`
- **Corrige** : majeurs de `docs/reviews/s59-model-by-complexity.md` (×2) et ses mineurs sur le sens de la règle et l'avertissement d'ADR-0036

**Critères d'acceptation**
- [ ] `update_lists_missing_settings` — `polype update` et `polype check` sur un projet listent chaque réglage du gabarit absent de son `AGENTS.local.md`, avec la valeur par défaut proposée, sans jamais modifier ce fichier.
- [ ] `installation_doc_has_an_upgrade_section` — `docs/installation.md` dit quoi faire après une mise à jour : lire cette liste, ajouter les réglages.
- [ ] `installation_doc_lists_the_hook_refusals` — la section de `docs/installation.md` sur le hook des bornes liste les commandes git que `po-bounds` refuse depuis s62 (déplacer une branche, `update-ref`, les commandes qui écrivent hors d'un worktree `story/*`) et ce qu'il ne voit pas (ADR-0039).
- [ ] `standalone_commands_state_the_session_model` — `/po-plan`, `/po-design` et `/po-research` disent qu'ils tournent sur le modèle de la session, à démarrer sur `Model strong` (ADR-0036).
- [ ] `model_refusal_stops_everywhere` — les tests vérifient, pour chaque commande qui dispatche, la phrase d'arrêt sur refus de modèle et le sens de la règle de l'implementer (`Model light` jusqu'à `Light up to`, `Model strong` au-delà).

### s66-eval-grading — Une eval qui ne compte pas un échec comme une réussite
**En tant que** développeur **je veux** qu'un rapport bloqué soit noté comme tel, et que le contrôle de dérive soit éprouvé **afin que** le taux affiché par `po-eval` mesure ce que le reviewer a trouvé.

- **Complexité** : 2
- **Dépend de** : aucune
- **Owns** : `bin/po-eval`, `tests/evals.test.sh`
- **Corrige** : majeur et mineurs de `docs/reviews/s55-reviewer-evals.md`

**Critères d'acceptation**
- [ ] `a_blocked_report_is_graded_blocked` — un rapport `Review status: blocked` est noté `blocked` et ne compte jamais comme réussi.
- [ ] `drift_check_is_tested_and_complete` — un test fait échouer le contrôle de dérive, qui signale aussi un fichier présent dans `method/` mais absent de la copie installée.
- [ ] `evals_leave_nothing_in_tmp` — les tests ne laissent aucun dossier dans le répertoire temporaire du système.

### s67-record-text — Le relevé d'un fix run
**En tant que** développeur **je veux** que l'implementer sache quoi faire d'un relevé qui existe déjà, et que la commande suggérée par la gate se copie telle quelle **afin que** l'historique des lancements ne se perde pas et qu'une commande ne change pas en route.

- **Complexité** : 1
- **Dépend de** : s60
- **Owns** : `method/agents/implementer.md`, `method/hooks/po-gate.sh`, `tests/run-ledger.test.sh`, `tests/qa-gate.test.sh`
- **Corrige** : mineurs m3 et m4 de `docs/reviews/s56-evidence-runner.md` ; majeur M1 et mineur m3 de `docs/reviews/s60-gate-parsing.md`

**Critères d'acceptation**
- [ ] `fix_run_keeps_the_runs` — en fix run, l'implementer garde le relevé existant et ses lignes `## Runs`, et ne met à jour que `Tree:` et ses propres lignes.
- [ ] `suggested_command_is_single_quoted` — la commande `po-run` que l'implementer lance et celle que la gate suggère placent la commande entre guillemets simples.
- [ ] `qa_current_ignores_ignored_files` — `qa-current` ne compte plus un fichier ignoré par git sous `docs/qa/<id>/` (le commit des preuves ne peut pas l'inclure), et le test de rapport committé mord sur la vérification qu'il garde.

### s68-docs-catch-up — La documentation rattrape la méthode
**En tant que** développeur **je veux** que le README et la matrice de parité décrivent la méthode telle qu'elle est **afin qu'**un lecteur ne se fie pas à un comportement disparu.

- **Complexité** : 1
- **Dépend de** : aucune
- **Owns** : `README.md`, `docs/parite-killer-saas.md`, `tests/distribution-wiring.test.sh`
- **Corrige** : mineurs de `docs/reviews/s49-secret-scan.md` (README) et `s59-model-by-complexity.md` (H04)

**Critères d'acceptation**
- [ ] `readme_describes_the_pre_commit` — le README dit que le pre-commit refuse aussi les secrets, sur toutes les branches.
- [ ] `parity_h04_matches_the_model_rule` — la ligne H04 dit que les rôles qui décident tournent sur `Model strong` et que l'implementer s'adapte à la complexité, avec son statut.

### s69-owns-overlap-globs — Les contrôles de chevauchement comprennent les globs
**En tant que** développeur **je veux** que la flotte, la relecture des stories et la revue comparent des `Owns` qui contiennent des globs **afin que** deux lanes qui touchent les mêmes chemins ne partent jamais ensemble.

- **Complexité** : 2
- **Dépend de** : s63, s64
- **Owns** : `method/commands/po-drive.md`, `method/skills/stories-review/`, `method/skills/review-antihallu/`, `method/templates/review.md`, `tests/owns-overlap.test.sh`
- **Corrige** : majeur de `docs/reviews/s61-bounds-owns.md`

**Critères d'acceptation**
- [ ] `overlap_rule_covers_globs` — `/po-drive`, la relecture des stories et le contrôle d'ownership de la revue disent la même règle : deux entrées se chevauchent quand un chemin peut correspondre aux deux (un dossier `x/` couvre tout ce qui est dessous, `*` un segment, `**` plusieurs) ; dans le doute, elles se chevauchent.
- [ ] `overlap_examples_are_written_once` — la règle donne des exemples, dont `crates/*/Cargo.toml` contre `crates/core/` (chevauchement) et `src/a/*.ts` contre `src/b/` (disjoints), à un seul endroit que les autres citent.

## M7 bis — Les derniers trous

Objectif : fermer ce que les revues de M7 ont laissé ouvert, dont le reviewer qui a encore Bash sans borne. Validé par l'utilisateur le 2026-10-08.

### s70-reviewer-bounds — Le reviewer tenu par un hook
**En tant que** développeur **je veux** que le reviewer ne puisse ni pousser, ni committer, ni écrire hors de la story qu'il relit **afin qu'**une sonde qui s'échappe ne touche jamais le dépôt principal.

- **Complexité** : 4 — risque : le reviewer modifie le code pour ses preuves de morsure puis le restaure ; le hook doit laisser passer ce va-et-vient dans le worktree de la story et rien d'autre.
- **Dépend de** : aucune
- **Owns** : `method/hooks/po-bounds.sh`, `method/agents/reviewer.md`, `tests/bounds.test.sh`
- **Corrige** : incident de la revue de s62 (boucle 1), consigné dans `docs/reviews/s62-bounds-scan.md` : un heredoc de sonde mal fermé a lancé six `git push` dans le checkout principal

**Critères d'acceptation**
- [ ] `reviewer_declares_a_pretooluse_hook` — le frontmatter du reviewer appelle `po-bounds.sh reviewer` sur Edit, Write et Bash, et un échec de lancement du script donne le code 2.
- [ ] `reviewer_writes_only_in_its_story_or_temp` — en mode `reviewer`, Write et Edit ne passent que dans le worktree de la story relue ou sous le répertoire temporaire du système.
- [ ] `reviewer_git_is_read_only_outside_restores` — en mode `reviewer`, seuls passent les verbes git qui lisent, plus la restauration d'un fichier du worktree de la story (`git checkout -- <chemin>`, `git restore <chemin>`) ; `push`, `commit`, `reset`, `stash`, `branch`, `merge` et toute commande git hors de ce worktree ou d'un dépôt jetable du répertoire temporaire sont refusés.
- [ ] `reviewer_bounds_fail_closed` — story introuvable ou entrée illisible : refus.

**Notes pour l'agent** : relire comment `review-antihallu` fait la preuve de morsure (modifier, lancer un test, restaurer, `git diff --exit-code`) et comment les revues de M6 et M7 ont sondé dans des dépôts jetables sous `/tmp`, pour ne bloquer aucun de ces gestes. Une ADR fixe le mode `reviewer`.

### s71-bounds-heredoc-expansion — Un heredoc lu comme bash le lira
**En tant que** développeur **je veux** que `po-bounds` lise le corps d'un heredoc non cité passé à un shell après l'expansion que bash lui fait subir **afin qu'**un `` \`git push\` `` ne passe plus à travers.

- **Complexité** : 3
- **Dépend de** : s70
- **Owns** : `method/hooks/po-bounds.sh`, `tests/bounds.test.sh`
- **Corrige** : majeur M1 et mineur m1 de `docs/reviews/s62-bounds-scan.md` (boucle 1)

**Critères d'acceptation**
- [ ] `unquoted_heredoc_is_expanded_before_reading` — dans le corps d'un heredoc à délimiteur non cité lu par un shell, `` \` ``, `\$` et `\\` sont rendus comme bash les rend avant que le corps soit relu ; `` echo \`git push\` `` y est refusé.
- [ ] `quoted_git_after_a_wrapper_option_is_caught` — `env -u X "git" push` et `sudo -u x "git" push` sont refusés.
- [ ] `accepted_gaps_are_written_in_an_adr` — une ADR qui remplace ADR-0039 décrit ce que le lecteur fait réellement (lecture des heredocs d'un shell, refus du pipe vers un shell, interprètes reconnus) et liste les trous acceptés (script écrit puis lancé, `source <(…)`, `GIT_DIR=…`, alias git ; `bash <(…)` était déjà refusé, corrigé après le plan de s71).

### s72-overlap-direction — La règle de chevauchement dans le bon sens, partout
**En tant que** développeur **je veux** que la revue compare un chemin du diff exactement aux entrées `Owns`, et que tous les textes de la méthode citent la même règle de chevauchement **afin que** le doute ne laisse jamais passer un chemin hors périmètre.

- **Complexité** : 2
- **Dépend de** : aucune
- **Owns** : `method/skills/review-antihallu/`, `method/skills/stories-review/`, `method/commands/po-drive.md`, `method/commands/po-stories.md`, `method/commands/po-status.md`, `method/AGENTS.md`, `method/templates/stories.md`, `method/templates/stories-review.md`, `tests/owns-overlap.test.sh`
- **Corrige** : majeur et mineurs de `docs/reviews/s69-owns-overlap-globs.md`

**Critères d'acceptation**
- [ ] `diff_paths_match_owns_exactly` — dans `review-antihallu`, un chemin du diff est comparé exactement aux entrées de sa story (« hors `Owns` » si aucune ne le couvre) ; « dans le doute, ça se chevauche » ne vaut que pour la comparaison avec une autre story et entre entrées.
- [ ] `drive_reports_name_the_entries` — le rapport et la réponse `status` de `/po-drive` nomment, pour un conflit, les deux entrées et un chemin qui correspond aux deux, comme sa règle de l'ensemble prêt.
- [ ] `every_overlap_text_cites_the_rule` — `method/AGENTS.md`, `/po-stories`, `/po-status`, le gabarit de stories et celui de leur relecture citent la règle de chevauchement au lieu de dire « partager un chemin ».
- [ ] `how_to_decide_reads_as_a_sentence` — la phrase « How to decide » de `stories-review` est grammaticale.

### s73-text-leftovers — Les restes de texte
**En tant que** développeur **je veux** que les derniers textes en retard sur la méthode soient alignés **afin qu'**un lecteur ne suive pas une consigne périmée.

- **Complexité** : 1
- **Dépend de** : aucune
- **Owns** : `method/skills/testing-doctrine/`, `docs/decisions/ADR-0024-po-bounds-trouve-la-story-par-son-worktree.md`, `docs/decisions/ADR-0029-po-qa-committe-les-preuves-qa.md`, `docs/decisions/ADR-0037-qa-current-exige-une-preuve-qa-committee.md`, `AGENTS.local.md`, `tests/leftovers.test.sh`
- **Corrige** : mineurs de `docs/reviews/s67-record-text.md`, `s60-gate-parsing.md` (m5), `s61-bounds-owns.md`, `s65-upgrade-path.md`

**Critères d'acceptation**
- [ ] `testing_doctrine_single_quotes_po_run` — la doctrine de test montre `po-run … -- '<command>'` entre guillemets simples, comme l'implementer et la gate.
- [ ] `replaced_adrs_point_to_their_successor` — le frontmatter d'ADR-0024, d'ADR-0029 et d'ADR-0037 renvoie (`superseded-by`) aux ADR qui en remplacent une partie, sans toucher à leur corps ; leur statut reste `accepted` puisque le remplacement est partiel.
- [ ] `polype_declares_every_template_setting` — l'`AGENTS.local.md` de Polype déclare `QA stage: —` et `Dev: —`, et `polype check .` n'y signale plus aucun réglage manquant.

**Notes pour l'agent** : vérifier les noms exacts des fichiers d'ADR dans `docs/decisions/` avant d'écrire ; une ADR acceptée ne se modifie jamais dans son corps, seul son frontmatter de liens change.

### s74-reviewer-bounds-bypasses — Les contournements du reviewer fermés
**En tant que** développeur **je veux** que `po-bounds` en mode `reviewer` juge la commande git que git exécutera vraiment **afin qu'**aucune sonde ne puisse écrire dans le dépôt principal par un détour.

- **Complexité** : 4 — risque : chaque correction doit laisser passer les sondes légitimes des revues (dépôt jetable sous le répertoire temporaire, preuve de morsure dans le worktree).
- **Dépend de** : aucune
- **Owns** : `method/hooks/po-bounds.sh`, `method/agents/reviewer.md`, `tests/bounds.test.sh`
- **Corrige** : majeurs M1, M2, M3 et mineur m2 de `docs/reviews/s70-reviewer-bounds.md`

**Critères d'acceptation**
- [ ] `chained_git_dirs_are_folded` — tous les `-C` d'une commande git sont enchaînés comme git les enchaîne avant que la zone soit décidée ; `git -C <checkout principal> -C . commit` lancé depuis un dépôt jetable est refusé.
- [ ] `config_worktree_override_is_refused` — en mode `reviewer`, `-c core.worktree=…` (et toute valeur `-c` qui fixe `core.worktree`) est refusé, comme `--work-tree`.
- [ ] `temp_zone_verbs_keep_their_paths_in_temp` — dans un dépôt jetable, un verbe qui prend un chemin de destination (`worktree add`, `clone`, `init`) n'est accepté que si ce chemin est lui aussi sous le répertoire temporaire.
- [ ] `reviewer_knows_how_to_check_merged` — `method/agents/reviewer.md` dit comment vérifier qu'une branche n'est pas fusionnée sans `git branch --merged` (`git merge-base --is-ancestor`, `git log`).

**Notes pour l'agent** : relire ADR-0047 et ADR-0050 ; une ADR nouvelle remplace ADR-0047 si une de ses règles change, sinon aucune ADR. Les sondes se construisent comme données d'entrée du hook, jamais comme commandes lancées.

### s75-post-m7-texts — Les textes rattrapent M7 bis
**En tant que** développeur **je veux** que la documentation, les règles et les ADR décrivent la méthode telle que M7 bis l'a laissée **afin qu'**un lecteur ne suive pas une consigne périmée.

- **Complexité** : 2
- **Dépend de** : aucune
- **Owns** : `docs/installation.md`, `tests/installer.test.sh`, `method/AGENTS.md`, `tests/structure.test.sh`, `method/skills/agentic-stories/`, `method/templates/adr.md`, `method/commands/po-architect.md`, `docs/decisions/ADR-0037-qa-current-exige-une-preuve-qa-committee.md`, `docs/decisions/ADR-0038-po-bounds-lit-les-owns-au-point-de-depart-de-la-story.md`, `docs/decisions/ADR-0039-po-bounds-lit-les-commandes-hors-guillemets-et-heredocs.md`, `docs/decisions/ADR-0041-le-retour-en-qa-exige-une-revue-bloquee-et-reconnait-la-preuve-non-committee.md`, `tests/post-m7-texts.test.sh`
- **Corrige** : mineurs de `docs/reviews/s70-reviewer-bounds.md` (m1, m3), `s71-bounds-heredoc-expansion.md` (m2), `s72-overlap-direction.md`, `s73-text-leftovers.md`

**Critères d'acceptation**
- [ ] `installation_describes_the_reviewer_mode` — `docs/installation.md` décrit le mode `reviewer` de `po-bounds`, dit qu'un projet dont `.polype/hooks/po-bounds.sh` date d'avant s70 bloque toute revue jusqu'à `polype init`, et renvoie à ADR-0050 au lieu d'ADR-0039.
- [ ] `rules_name_every_bounded_agent` — la section « Installed files » de `method/AGENTS.md` dit que `po-bounds` tient l'implementer, qa et le reviewer.
- [ ] `agentic_stories_cites_the_overlap_rule` — `agentic-stories` cite la règle de chevauchement de la vérification 8 de `stories-review` au lieu de dire seulement « share a path ».
- [ ] `partial_supersession_is_written_and_linked` — le gabarit d'ADR et `/po-architect` décrivent le remplacement partiel (l'ancienne ADR garde `accepted` et nomme son successeur, le successeur la nomme dans `supersedes`) ; ADR-0037, ADR-0038, ADR-0039 et ADR-0041 nomment dans `supersedes` l'ADR qu'elles remplacent en partie, sans toucher à leur corps.

**Notes pour l'agent** : une ADR acceptée ne se modifie que dans son frontmatter de liens ; vérifier chaque lien dans le corps du successeur avant de l'écrire (ADR-0038 et ADR-0039 → ADR-0024, ADR-0037 → ADR-0029, ADR-0041 → ADR-0037).

### s76-bounds-guard-against-mistakes — Le hook des bornes, un garde-fou contre les erreurs
**En tant que** développeur **je veux** que `po-bounds` soit décrit et réglé comme un garde-fou contre les erreurs d'un agent, pas comme une barrière contre un agent qui chercherait à le contourner **afin d'**arrêter la course aux contournements et de ne plus refuser les gestes légitimes des revues.

- **Complexité** : 3
- **Dépend de** : aucune
- **Owns** : `method/hooks/po-bounds.sh`, `tests/bounds.test.sh`, `docs/installation.md`, `tests/installer.test.sh`, `tests/post-m7-texts.test.sh`, `docs/decisions/ADR-0034-la-flotte-committe-la-preuve-qa-et-le-retour-en-qa-ne-coute-aucune-boucle.md`, `docs/decisions/ADR-0041-le-retour-en-qa-exige-une-revue-bloquee-et-reconnait-la-preuve-non-committee.md`, `docs/decisions/ADR-0047-le-reviewer-tenu-par-po-bounds-en-mode-reviewer.md`, `docs/decisions/ADR-0051-le-reviewer-juge-la-commande-git-que-git-executera.md`
- **Corrige** : majeurs M1, M2, M3 de `docs/reviews/s74-reviewer-bounds-bypasses.md` ; majeur M1 et mineurs m1, m2, m4 de `docs/reviews/s75-post-m7-texts.md`
- **Décision** : option A, choisie par l'utilisateur le 2026-10-08 — le hook arrête les accidents (une sonde mal fermée, une commande lancée dans le mauvais dossier), il ne prétend pas arrêter un contournement délibéré ; une isolation par bac à sable reste une piste pour plus tard.

**Critères d'acceptation**
- [ ] `bounds_threat_model_is_written` — une ADR qui remplace en partie ADR-0047 et ADR-0051 pose que `po-bounds` est un garde-fou contre les erreurs, liste les contournements délibérés connus et acceptés (dont les options courtes collées comme `config -zf<chemin>`, la portée d'un `cd`, les alias, les hooks d'un dépôt jetable, `GIT_CONFIG_GLOBAL`, une clé construite par substitution) et nomme le bac à sable comme piste écartée pour l'instant ; ADR-0047 et ADR-0051 la nomment dans `superseded-by`, et le lien inverse ADR-0034 ↔ ADR-0041 est posé.
- [ ] `redirections_are_not_git_paths` — en mode `reviewer`, une redirection (`2>/dev/null`, `>/dev/null`, `2>&1`, `| head`) n'est plus lue comme un chemin de la commande git : `git -C <dépôt jetable> log 2>/dev/null` passe, tandis qu'une redirection vers un fichier du checkout principal reste refusée.
- [ ] `installation_matches_the_hook` — la section « Le mode reviewer » de `docs/installation.md` cite ADR-0051 et la nouvelle ADR, dit la règle des chemins dans le dépôt jetable et les refus de `core.worktree`, et présente le hook comme un garde-fou contre les erreurs ; la phrase « et … ni » sur ce que le hook ne lit pas est réécrite.
- [ ] `test_variables_are_local` — dans `tests/post-m7-texts.test.sh`, la variable de boucle est déclarée `local`.

**Notes pour l'agent** : ne pas fermer de nouveau contournement délibéré dans cette story ; le but est de les nommer. Une ADR acceptée ne change que dans son frontmatter de liens.

### s77-last-review-leftovers — Les derniers restes des revues
**En tant que** développeur **je veux** que les mineurs encore ouverts des revues de M7 bis soient fermés **afin que** Polype parte vers d'autres plateformes sans dette connue.

- **Complexité** : 2
- **Dépend de** : aucune
- **Owns** : `method/hooks/po-bounds.sh`, `tests/bounds.test.sh`, `method/agents/reviewer.md`, `method/templates/adr.md`, `method/AGENTS.md`, `method/commands/po-status.md`, `method/skills/stories-review/`, `tests/stories-review.test.sh`, `tests/final-leftovers.test.sh`, `docs/decisions/ADR-0052-po-bounds-est-un-garde-fou-contre-les-erreurs.md`
- **Corrige** : mineurs de `docs/reviews/s76-bounds-guard-against-mistakes.md` (m1, m2), de `s75-post-m7-texts.md` (gabarit d'ADR, Loi 6) et de `s72-overlap-direction.md` (`po-status`, vérification 8)

**Critères d'acceptation**
- [ ] `refusal_messages_are_readable` — un refus de `po-bounds` sur une cible de redirection n'affiche jamais l'octet de marquage brut, et `/dev/fd/1` et `/dev/fd/2` sont traités comme `/dev/stdout` et `/dev/stderr`.
- [ ] `reviewer_knows_the_hook_is_a_guard` — `method/agents/reviewer.md` dit que `po-bounds` arrête les erreurs (ADR-0052) et qu'un contournement délibéré déjà listé par ADR-0052 n'est pas un constat ; un contournement nouveau se signale en renvoyant à l'ADR plutôt qu'en demandant un correctif.
- [ ] `adr_links_are_the_only_edit` — la Loi 6 de `method/AGENTS.md` dit qu'une ADR acceptée ne change que dans ses liens de frontmatter, et le gabarit d'ADR garde ses commentaires hors des lignes `supersedes:` et `superseded-by:`.
- [ ] `overlap_wording_is_light` — la phrase de `/po-status` sur un conflit d'`Owns` se lit d'un trait, et la vérification 8 de `stories-review` dit « overlap » au lieu de « share an `Owns` path ».

## M8 — Toutes les plateformes

Objectif : Polype pilote un projet mobile, une CLI, une API ou une bibliothèque, une scène 3D ou XR et un robot comme il pilote un site web, avec la même QA avant revue (ADR-0054) ; plus une rétro, une procédure de diagnostic et l'accessibilité élargie, retenues de l'étude gstack et agent-skills. Validé par l'utilisateur le 2026-10-08 ; révisé après la relecture `docs/reviews/stories-m8.md`.

### s78-platform-setting — Le projet déclare ses plateformes, la story sa surface
**En tant que** développeur **je veux** que le projet déclare ses plateformes, que chaque profil de boilerplate dise la sienne et que chaque story déclare sa surface **afin que** la suite du cycle sache comment la dessiner et la vérifier sans deviner.

- **Complexité** : 3
- **Dépend de** : aucune
- **Surface** : —
- **Owns** : `method/templates/agents-local.md`, `method/commands/po-setup.md`, `method/templates/stories.md`, `method/skills/agentic-stories/`, `method/commands/po-stories.md`, `method/skills/stories-review/`, `method/agents/stories-reviewer.md`, `method/commands/po-stories-review.md`, `method/templates/profile.md`, `bin/po-lint`, `boilerplates/next-forge/profile.md`, `AGENTS.local.md`, `tests/profile.test.sh`, `tests/next-forge-profile.test.sh`, `tests/setup-modes.test.sh`, `tests/stories-review.test.sh`, `tests/platform-setting.test.sh`

**Critères d'acceptation**
- [ ] `platform_is_a_setting` — le gabarit `agents-local.md` déclare `Platform`, une liste parmi `web`, `mobile`, `cli`, `api`, `lib`, `xr`, `robot` ; `QA stage` accepte `screens`, `surfaces` ou `—` avec leur sens d'ADR-0054 ; `Dev` y est décrit comme la commande qui sert ce qu'on regarde (serveur de dev, rendu web d'une app mobile), `—` pour un projet qui n'a rien à servir.
- [ ] `profiles_declare_their_platform` — le gabarit de profil a une section `## Platform`, `bin/po-lint` l'exige, et le profil next-forge déclare `web`.
- [ ] `setup_asks_the_platform` — `/po-setup` demande la ou les plateformes en question de suite non numérotée (comme `QA stage`), n'offre que les profils de boilerplate de ces plateformes, et pose la question `QA stage` même quand `Dev` est `—` si une plateforme sans écran (`cli`, `api`, `lib`, `robot`) est déclarée.
- [ ] `stories_declare_a_surface` — le gabarit de stories et `agentic-stories` font écrire une ligne `Surface` (`screen`, `command`, `endpoint`, `scene`, `behaviour` ou `—`) à chaque story, `/po-stories` la remplit d'après `Platform`, et `stories-review` (qui lit alors `Platform`) signale en mineur une story sans `Surface`, qui garde l'ancienne règle, et en majeur une surface qui ne va pas avec les plateformes du projet.
- [ ] `polype_declares_its_platform` — l'`AGENTS.local.md` de Polype déclare `Platform: cli` et `polype check .` ne signale aucun réglage manquant.

**Notes pour l'agent** : `tests/setup-modes.test.sh` et `tests/qa.test.sh` figent cinq questions numérotées à l'étape 2 de `/po-setup` : `Platform` reste hors de cette numérotation. `tests/qa.test.sh` fige aussi la phrase `` `Dev` starts the development server `` du gabarit : la garder mot pour mot. `bin/po-lint` lit les sections exigées dans le gabarit de profil lui-même ; vérifier qu'un profil sans écran peut y laisser `## Capabilities` presque vide.

### s79-qa-drivers — La QA vérifie une surface avec le pilote qui lui va
**En tant que** développeur **je veux** que l'agent `qa` choisisse son pilote d'après la surface de la story et la plateforme du projet **afin qu'**une CLI, une scène ou un robot soient vérifiés avant la revue comme un écran l'est.

- **Complexité** : 4 — risque : le contrat de `qa` est figé par plusieurs tests et lu par `/po-drive` ; il doit s'ouvrir aux surfaces sans écran sans changer ce que vaut un rapport (`QA status:`, `Tree:`, preuves committées, `qa-current`).
- **Dépend de** : s78
- **Surface** : —
- **Owns** : `method/agents/qa.md`, `method/commands/po-qa.md`, `method/templates/qa.md`, `method/templates/agents-local.md`, `method/skills/qa-drivers/SKILL.md`, `method/skills/qa-drivers/browser.md`, `method/templates/profile.md`, `bin/po-lint`, `boilerplates/next-forge/profile.md`, `tests/qa.test.sh`, `tests/profile.test.sh`, `tests/next-forge-profile.test.sh`, `tests/qa-drivers.test.sh`

**Critères d'acceptation**
- [ ] `qa_picks_the_driver_of_the_surface` — `qa` précharge `qa-drivers`, dont le `SKILL.md` dit quel fichier de pilote vaut pour chaque surface et plateforme (table d'ADR-0054) ; un fichier de pilote absent arrête la QA avec `QA status: blocked` et la cause.
- [ ] `qa_runs_without_a_screen` — pour une surface autre que `screen`, `/po-qa` et `qa` ne s'arrêtent plus sur `Dev` à `—`, sur « pas d'écran » ni sur l'absence d'outil de navigateur ; ils lisent les critères qu'un utilisateur constate, pas seulement ceux vus à l'écran, et le dossier de travail reste propre après la QA ; ce qu'un pilote produit hors de sa preuve va sous le répertoire temporaire, seule exception à « rien hors de `docs/qa/<id>/` », et la définition de `Dev` dans le gabarit de réglages ne dit plus que `/po-qa` s'arrête sur `—`.
- [ ] `browser_driver_is_the_first_one` — `qa-drivers/browser.md` renvoie à la section de `design-doctrine` qui pilote déjà un navigateur, sans la recopier.
- [ ] `qa_report_names_its_driver` — le gabarit de rapport QA porte le pilote utilisé et la forme de la preuve (captures, transcriptions, journaux), et sa section de ce qui n'a pas été vu nomme ce que seul un matériel réel, un simulateur iOS ou un casque montrerait.
- [ ] `profiles_declare_their_driver` — le gabarit de profil a une section `## QA driver` et une commande `Dev` dans son bloc `## Commands` (celle qui sert ce qu'on regarde), `bin/po-lint` les exige, et le profil next-forge les remplit (navigateur, sa commande de dev).

**Notes pour l'agent** : `tests/qa.test.sh` fige des phrases de `qa.md` et de `po-qa.md` sur `Dev` et sur l'écran ; ce test est dans les `Owns`, ses phrases changent avec la clause. Le mode `qa` de `po-bounds` limite les écritures à `docs/qa/<id>/` : un pilote qui produit des fichiers ailleurs (build, enregistrements) les écrit sous le répertoire temporaire. Un fichier de pilote se cherche dans le dossier de la skill telle qu'elle est chargée (pose globale ou projet), jamais à un chemin fixe.

### s80-surface-routing — La flotte route une story d'après sa surface
**En tant que** développeur **je veux** que `/po-drive`, `/po-orchestrator`, `/po-flow`, `/po-status` et la revue lisent la ligne `Surface` **afin que** le design et la QA s'appliquent aux bonnes stories sans deviner depuis le texte.

- **Complexité** : 4 — risque : la phrase « story with a screen » est répétée dans une dizaine de fichiers et figée par plusieurs tests ; un oubli laisse deux règles de routage différentes.
- **Dépend de** : s79
- **Surface** : —
- **Owns** : `method/commands/po-drive.md`, `method/commands/po-orchestrator.md`, `method/commands/po-flow.md`, `method/commands/po-status.md`, `method/commands/po-review.md`, `method/commands/po-help.md`, `method/skills/review-antihallu/`, `method/agents/reviewer.md`, `method/agents/implementer.md`, `method/templates/review.md`, `method/templates/plan.md`, `method/templates/plan-flow.md`, `method/AGENTS.md`, `README.md`, `tests/qa-fleet.test.sh`, `tests/qa-gate.test.sh`, `tests/fleet-design.test.sh`, `tests/wiring.test.sh`, `tests/design-handoff.test.sh`, `tests/surface-routing.test.sh`

**Critères d'acceptation**
- [ ] `design_follows_a_screen_surface` — le design s'applique à une story de surface `screen`, et à une story sans ligne `Surface` dont le texte montre un écran (ADR-0054).
- [ ] `qa_follows_the_qa_stage` — sous `QA stage: screens`, seules les stories `screen` passent en QA ; sous `surfaces`, toute story dont la surface n'est pas `—` ; une story sans ligne `Surface` suit l'ancienne règle de l'écran ; la table de reprise de `/po-drive`, `/po-orchestrator` et `/po-status` disent la même chose.
- [ ] `flow_escalates_a_surface_with_qa` — `/po-flow` passe en voie complète une story que le réglage `QA stage` fait passer en QA, comme il le fait déjà pour un nouvel écran.
- [ ] `review_requires_qa_for_a_surface` — `review-antihallu` et le reviewer exigent `po-gate qa-current` pour toute story que `QA stage` fait passer en QA ; une story `scene` est jugée contre les points de vue de son plan, pas contre le système de design ; ce que le rapport QA n'a pas pu voir passe dans « Not verified » de la revue.
- [ ] `plan_names_scene_viewpoints` — les gabarits de plan, complet et court, ont une section, remplie seulement pour une story `scene`, qui nomme les points de vue à capturer et ce que chacun doit montrer (cadrage, échelle, lumière).
- [ ] `rules_speak_of_surfaces` — `method/AGENTS.md`, le gabarit de revue, l'implementer, `/po-help` et le `README` parlent de surface là où ils parlaient d'écran pour la QA.

**Notes pour l'agent** : `tests/qa-gate.test.sh` fige des phrases du gabarit de revue, de l'implementer et de la ligne `/po-qa` de `method/AGENTS.md` ; `tests/qa-fleet.test.sh` fige `/po-help` et le `README`. Tous sont dans les `Owns`. `tests/plan.test.sh`, `tests/planner.test.sh` et `tests/flow.test.sh` lisent les gabarits de plan : n'y changer aucune section existante.

### s81-scenario-driver — Le pilote par scénarios pour une CLI, une API ou une bibliothèque
**En tant que** développeur **je veux** que la QA d'une story `command` ou `endpoint` lance de vrais scénarios et garde leurs transcriptions **afin qu'**une CLI ou une API soient regardées comme un utilisateur les utiliserait, et pas seulement par leurs tests.

- **Complexité** : 3
- **Dépend de** : s79
- **Surface** : —
- **Owns** : `method/skills/qa-drivers/scenarios.md`, `tests/scenario-driver.test.sh`

**Critères d'acceptation**
- [ ] `scenarios_run_each_visible_criterion` — `qa-drivers/scenarios.md` fait lancer, pour chaque critère qu'un utilisateur constate, la commande, la requête ou l'appel public, et garder dans `docs/qa/<id>/` l'entrée, la sortie et le code de retour, sans secret.
- [ ] `scenarios_cover_failure_paths` — le pilote couvre une entrée invalide et le message d'erreur qu'un utilisateur lit, pas seulement le chemin nominal.
- [ ] `scenarios_start_the_service_itself` — pour une API, le pilote dit comment démarrer le service sur un port libre de la machine, l'interroger, puis l'arrêter, et ne touche à aucun service partagé.
- [ ] `scenarios_leave_the_tree_clean` — ce qu'un scénario produit hors de sa transcription (build, fichiers de sortie) va sous le répertoire temporaire, et le worktree est propre à la fin.

**Notes pour l'agent** : en mode `qa`, `po-bounds` ne laisse passer que les verbes git qui lisent, répertoire temporaire compris ; un scénario qui aurait besoin d'un dépôt git de test ne peut pas le construire, et le pilote le dit.

### s82-mobile-web-driver — Le mobile vérifié par son rendu web d'abord
**En tant que** développeur **je veux** que la QA d'un écran mobile passe par le rendu web de la pile dans le navigateur, en largeur de téléphone **afin que** clout soit vérifiable dès maintenant sans émulateur.

- **Complexité** : 3
- **Dépend de** : s79
- **Surface** : —
- **Owns** : `method/skills/qa-drivers/mobile-web.md`, `method/skills/design-doctrine/`, `tests/mobile-web-driver.test.sh`

**Critères d'acceptation**
- [ ] `mobile_web_driver_sets_a_phone_viewport` — `qa-drivers/mobile-web.md` fait servir le rendu web par la commande `Dev`, ouvrir l'écran en largeur de téléphone (au moins 360 et 412 pixels de large) et en portrait, et capturer chaque état.
- [ ] `mobile_rules_are_in_the_doctrine` — `design-doctrine` donne les règles mobiles qu'un écran tient : zones tactiles d'au moins 44 sur 44 points, zones sûres (encoche, barre de geste), clavier qui ne masque pas le champ actif, pas de survol comme seul moyen d'agir.
- [ ] `native_only_behaviour_is_named` — le pilote liste ce que le rendu web ne montre pas (permissions natives, notifications, caméra, gestes système) et le rapport QA le reporte comme non vu.

**Notes pour l'agent** : `tests/qa.test.sh` fige les quatre phrases de tête de `## Driving a browser` dans `design-doctrine` ; les garder telles quelles.

### s83-expo-profile — Le profil Expo
**En tant que** développeur **je veux** un profil de boilerplate pour Expo (React Native) **afin que** `/po-setup` et `/po-architect` partent de faits vérifiés sur cette pile.

- **Complexité** : 2
- **Dépend de** : s82
- **Surface** : —
- **Owns** : `boilerplates/expo/`, `tests/expo-profile.test.sh`

**Critères d'acceptation**
- [ ] `expo_profile_passes_the_lint` — `boilerplates/expo/profile.md` suit le gabarit de profil, écrit depuis le gabarit de départ officiel d'Expo à un commit nommé, sous sa licence, et `bin/po-lint` l'accepte.
- [ ] `expo_profile_names_its_web_render` — sa plateforme est `mobile`, son pilote `mobile-web`, sa commande `Dev` sert le rendu web de l'app; le gabarit n'a pas de commande de test, et la commande `Test` du profil est celle qu'une première story installe, qui accepte des chemins (ADR-0062, ADR-0069).

### s84-flutter-profile — Le profil Flutter
**En tant que** développeur **je veux** un profil de boilerplate pour Flutter **afin que** `/po-setup` et `/po-architect` partent de faits vérifiés sur cette pile.

- **Complexité** : 2
- **Dépend de** : s82
- **Surface** : —
- **Owns** : `boilerplates/flutter/`, `tests/flutter-profile.test.sh`

**Critères d'acceptation**
- [ ] `flutter_profile_passes_the_lint` — `boilerplates/flutter/profile.md` suit le gabarit de profil, écrit depuis le gabarit d'application officiel de Flutter à un commit nommé, sous sa licence, et `bin/po-lint` l'accepte.
- [ ] `flutter_profile_names_its_web_render` — sa plateforme est `mobile`, son pilote `mobile-web`, sa commande `Dev` sert le rendu web (`flutter run -d web-server` ou équivalent), et sa commande `Test` accepte des chemins.

### s85-native-profiles — Les profils natifs iOS et Android
**En tant que** développeur **je veux** un profil pour une app iOS en Swift et un pour une app Android en Kotlin **afin qu'**un projet natif parte de faits vérifiés, même si sa QA ne passe pas par un rendu web.

- **Complexité** : 2
- **Dépend de** : s82
- **Surface** : —
- **Owns** : `boilerplates/native-ios/`, `boilerplates/native-android/`, `tests/native-profiles.test.sh`

**Critères d'acceptation**
- [ ] `native_profiles_pass_the_lint` — `boilerplates/native-ios/profile.md` et `boilerplates/native-android/profile.md` suivent le gabarit, écrits chacun depuis un gabarit de départ public et sous licence libre à un commit nommé, et `bin/po-lint` les accepte.
- [ ] `native_profiles_say_what_qa_cannot_do` — leur plateforme est `mobile` ; chacun dit que le pilote web ne s'applique pas, que le simulateur iOS demande un Mac et l'émulateur Android un lot suivant, et donc que leur QA d'écran est `blocked` jusque-là.

### s86-cli-api-profiles — Les profils CLI en Rust et API en Hono
**En tant que** développeur **je veux** un profil de CLI en Rust (clap) et un profil d'API en TypeScript (Hono) **afin qu'**un projet sans écran parte de faits vérifiés et d'un pilote de QA par scénarios.

- **Complexité** : 2
- **Dépend de** : s81
- **Surface** : —
- **Owns** : `boilerplates/rust-cli/`, `boilerplates/hono-api/`, `tests/cli-api-profiles.test.sh`

**Critères d'acceptation**
- [ ] `cli_api_profiles_pass_the_lint` — `boilerplates/rust-cli/profile.md` et `boilerplates/hono-api/profile.md` suivent le gabarit, écrits chacun depuis un gabarit de départ public et sous licence libre à un commit nommé, et `bin/po-lint` les accepte.
- [ ] `cli_api_profiles_use_scenarios` — leurs plateformes sont `cli` et `api`, leur pilote `scenarios`, et chacun dit comment lancer le binaire ou le service pour un scénario.

### s87-godot-scene-driver — La 3D et l'XR : profil Godot et captures de scène
**En tant que** développeur **je veux** un profil Godot et un pilote qui capture sans fenêtre les points de vue que le plan nomme **afin qu'**une story `scene` arrive en revue avec des captures regardées.

- **Complexité** : 3
- **Dépend de** : s80
- **Surface** : —
- **Owns** : `boilerplates/godot/`, `method/skills/qa-drivers/scene.md`, `tests/godot-scene-driver.test.sh`

**Critères d'acceptation**
- [ ] `godot_profile_passes_the_lint` — `boilerplates/godot/profile.md` suit le gabarit, écrit depuis un gabarit de départ public et sous licence libre à un commit nommé, plateforme `xr`, pilote `scene`, et `bin/po-lint` l'accepte.
- [ ] `scene_driver_captures_without_a_window` — `qa-drivers/scene.md` fait rendre la scène sans fenêtre (ou dans un navigateur pour WebXR), capturer chaque point de vue du plan, et dit ce que seul un casque montrerait (confort, échelle, suivi des mains) comme non vu.

### s88-ros-simulation-driver — La robotique : profil ROS 2 et simulation
**En tant que** développeur **je veux** un profil ROS 2 avec Gazebo et un pilote qui vérifie un comportement en simulation **afin qu'**une story `behaviour` arrive en revue avec des journaux et des enregistrements de topics.

- **Complexité** : 3
- **Dépend de** : s79
- **Surface** : —
- **Owns** : `boilerplates/ros2-gazebo/`, `method/skills/qa-drivers/simulation.md`, `tests/ros-simulation-driver.test.sh`

**Critères d'acceptation**
- [ ] `ros_profile_passes_the_lint` — `boilerplates/ros2-gazebo/profile.md` suit le gabarit, écrit depuis un gabarit de départ public et sous licence libre à un commit nommé, plateforme `robot`, pilote `simulation`, et `bin/po-lint` l'accepte.
- [ ] `simulation_driver_records_behaviour` — `qa-drivers/simulation.md` fait lancer la simulation sans fenêtre, déclencher le comportement de chaque critère, garder les journaux et un extrait lisible des topics utiles dans `docs/qa/<id>/`, les enregistrements bruts sous le répertoire temporaire, puis tout arrêter ; ce que seul le matériel réel montrerait est reporté comme non vu.

### s89-po-retro — Une rétro tirée des fichiers
**En tant que** développeur **je veux** une commande `/po-retro` qui résume un jalon depuis les revues, les relevés et les rapports QA **afin de** voir où le cycle coûte, sans métrique inventée.

- **Complexité** : 3
- **Dépend de** : s80
- **Surface** : —
- **Owns** : `method/commands/po-retro.md`, `method/commands/po-help.md`, `tests/po-retro.test.sh`

**Critères d'acceptation**
- [ ] `retro_reads_only_recorded_facts` — `/po-retro` lit `docs/stories.md`, `docs/reviews/*`, `docs/verif/*` et `docs/qa/*` pour un jalon ou une plage de stories, et rapporte les sévérités par story, les boucles de correction, les revues bloquées et leur cause, les QA bloquées, et les majeurs encore ouverts ; il ne compte ni lignes ni commits.
- [ ] `retro_writes_nothing` — la commande n'a ni Write ni Edit, et sa sortie dit d'où vient chaque chiffre.
- [ ] `help_lists_the_retro` — `/po-help` présente `/po-retro`.

### s90-diagnostic-skill — Une procédure de diagnostic pour les défauts
**En tant que** développeur **je veux** une skill de diagnostic que le planner suit pour une story qui corrige un défaut **afin qu'**aucun correctif ne parte sans cause trouvée.

- **Complexité** : 2
- **Dépend de** : s80
- **Surface** : —
- **Owns** : `method/skills/diagnostic/`, `method/agents/planner.md`, `method/commands/po-flow.md`, `method/templates/plan-flow.md`, `method/templates/stories.md`, `method/skills/agentic-stories/`, `tests/diagnostic-skill.test.sh`

**Critères d'acceptation**
- [ ] `no_fix_without_a_root_cause` — la skill `diagnostic` demande de reproduire le défaut, d'écrire la cause racine avec la preuve qui la montre, puis seulement de planifier le correctif et le test qui l'aurait attrapé.
- [ ] `stop_after_three_failed_hypotheses` — après trois hypothèses écartées, la recherche s'arrête et le dit, au lieu de proposer un correctif au hasard.
- [ ] `defect_stories_get_the_diagnostic` — une story qui corrige un défaut se reconnaît à sa ligne `Corrige`, que le gabarit de stories et `agentic-stories` définissent ; le planner précharge `diagnostic` et l'applique à une telle story, et `/po-flow` comme le planner la passent en voie complète ; les textes qui comptaient « cinq signaux » (`/po-flow`, le planner, le gabarit de plan court) donnent la liste à jour.

### s91-accessibility — L'accessibilité au-delà du contraste
**En tant que** développeur **je veux** que la doctrine de design et la QA vérifient le focus, les étiquettes, les textes alternatifs et les erreurs **afin qu'**un écran soit utilisable au clavier et avec un lecteur d'écran.

- **Complexité** : 2
- **Dépend de** : s82
- **Surface** : —
- **Owns** : `method/skills/design-doctrine/`, `tests/accessibility.test.sh`

**Critères d'acceptation**
- [ ] `doctrine_covers_more_than_contrast` — `design-doctrine` demande un focus visible et un ordre de tabulation logique, une étiquette pour chaque champ et chaque bouton sans texte, un texte alternatif pour chaque image porteuse de sens, et une erreur jamais signalée par la seule couleur.
- [ ] `qa_walks_with_the_keyboard` — la section qui pilote un navigateur fait parcourir chaque écran au clavier seul et relever ce qui n'est pas atteignable.

**Notes pour l'agent** : `tests/qa.test.sh` fige les quatre phrases de tête de `## Driving a browser` ; les garder telles quelles.

## Correctifs hors jalon (suite)

### s92-review-tree-gate — La gate lit l'arbre de la dernière revue
**En tant que** développeur **je veux** que `po-gate ship-allowed` lise l'arbre jugé par la même revue que le verdict qu'il retient, et qu'il accepte ces lignes écrites en élément de liste **afin qu'**une revue favorable ne soit ni refusée pour une puce, ni liée à l'arbre d'une revue plus ancienne.

- **Complexité** : 2
- **Dépend de** : aucune
- **Surface** : —
- **Owns** : `method/hooks/po-gate.sh`, `method/commands/po-ship.md`, `bin/po-eval`, `tests/gate.test.sh`, `tests/review-tree-gate.test.sh`
- **Corrige** : défaut n° 35 de `docs/defauts.md` (lane de s78, 2026-10-08)

**Critères d'acceptation**
- [ ] `ship_gate_reads_the_last_review` — quand `docs/reviews/<id>.md` empile plusieurs revues, `ship-allowed` prend le `Reviewed tree:` de la dernière, celle qui porte le dernier `Ship allowed:`, et non le premier du fichier.
- [ ] `verdict_lines_may_be_list_items` — une ligne `Reviewed tree:` ou `Ship allowed:` précédée d'une puce de liste (`- ` ou `* `) est lue comme la même ligne sans puce, et un texte séparé du hash par une espace après lui (une remarque entre parenthèses) ne l'empêche pas d'être lu ; toute autre forme reste refusée (indentation, autre puce, hash incomplet).
- [ ] `other_tree_lines_read_the_same_way` — les lignes `Tree:` du relevé et du rapport QA suivent la même règle de lecture que `Reviewed tree:`, et `/po-ship` (contrôle sans hook) comme `bin/po-eval` décrivent ou lisent ces lignes de la même façon.

**Notes pour l'agent** : `first_hash` sert aux trois gates (`po-gate.sh:34`) ; la revue de s78, sur la branche `story/s78-platform-setting`, montre les deux formes fautives. Une gate est un garde-fou : n'élargir la lecture qu'à ces puces-là.

## M8 bis — Les restes de M8

Objectif : fermer les majeurs et les mineurs que les revues de M8 ont laissés ouverts, pour que Polype soit fini avant le premier vrai projet (clout). Cadré le 2026-10-08 à la demande de l'utilisateur (« on finit polype avant »).

### s93-qa-contract-holds — Le contrat de QA tient sur toutes les surfaces
**En tant que** développeur **je veux** que l'agent `qa` et le pilote par scénarios ne concluent jamais sans preuve et ne se bloquent pas sur leur propre preuve **afin qu'**une QA de CLI, d'API ou de bibliothèque aboutisse vraiment.

- **Complexité** : 3
- **Dépend de** : aucune
- **Surface** : —
- **Owns** : `method/agents/qa.md`, `method/skills/qa-drivers/SKILL.md`, `method/skills/qa-drivers/scenarios.md`, `tests/qa.test.sh`, `tests/qa-drivers.test.sh`, `tests/scenario-driver.test.sh`, `tests/qa-contract-holds.test.sh`
- **Corrige** : majeur 1 de `docs/reviews/s79-qa-drivers.md` ; majeurs et mineurs de `docs/reviews/s81-scenario-driver.md`

**Critères d'acceptation**
- [ ] `no_driver_row_blocks` — quand aucune ligne de la table des pilotes ne correspond à la surface et à la plateforme, ou que `Platform` manque ou vaut `—`, `qa` écrit `QA status: blocked` avec la cause, jamais `complete`.
- [ ] `own_evidence_never_blocks` — la comparaison avant/après du pilote par scénarios met de côté `docs/qa/<id>/`, comme `qa.md` ; un script de travail se crée par Bash sous le répertoire temporaire, ce que le pilote dit ; un service qui ne répond pas dans le délai donne `blocked`.
- [ ] `qa_declares_what_it_reads` — la ligne `Reads settings:` de `qa` cite `Install` et `Build`, `qa` garde l'état `git status` d'avant la visite, et cite le plan de la story parmi ses sources.
- [ ] `scenario_rules_bite` — les règles du pilote par scénarios (blocage sur un nouveau chemin, dossier de travail, code de succès sur une entrée invalide) ont chacune un test qui échoue quand elle disparaît.

### s94-scene-and-simulation-drivers — Les pilotes de scène et de simulation s'arrêtent proprement
**En tant que** développeur **je veux** que les pilotes `scene` et `simulation` lisent les points de vue que le plan écrit vraiment et ne laissent aucun processus derrière eux **afin que** leurs QA produisent des preuves utilisables.

- **Complexité** : 3
- **Dépend de** : aucune
- **Surface** : —
- **Owns** : `method/skills/qa-drivers/scene.md`, `method/skills/qa-drivers/simulation.md`, `method/templates/plan.md`, `method/templates/plan-flow.md`, `boilerplates/godot/profile.md`, `tests/godot-scene-driver.test.sh`, `tests/ros-simulation-driver.test.sh`, `tests/surface-routing.test.sh`, `tests/scene-and-simulation-drivers.test.sh`
- **Corrige** : majeur et mineurs de `docs/reviews/s87-godot-scene-driver.md` et de `docs/reviews/s88-ros-simulation-driver.md`

**Critères d'acceptation**
- [ ] `viewpoint_lines_match_the_plan` — la section `## Scene viewpoints` des deux gabarits de plan et `scene.md` demandent les mêmes champs pour un point de vue (scène, position, cible, cadrage) ; une ligne sans scène vise la scène principale du projet.
- [ ] `scene_capture_is_sized_and_scripted` — le pilote `scene` donne à l'écran virtuel la taille de la capture, indique la bonne façon de lire l'image depuis un script `--script`, et met de côté `docs/qa/<id>/` dans sa comparaison avant/après.
- [ ] `simulation_leaves_nothing_running` — le pilote `simulation` déclenche avec `--once` ou `--times`, arrête chaque processus lancé pendant la visite, vérifie avec `ros2 node list --all`, calcule un débit comme nombre / durée, et met de côté `docs/qa/<id>/`.

**Notes pour l'agent** : garder les champs que les gabarits de plan demandent déjà (ce que le point de vue montre, cadrage, échelle, lumière) et ajouter scène, position et cible, pour que `method/agents/reviewer.md`, hors `Owns`, reste juste. `tests/surface-routing.test.sh` fige des phrases des gabarits de plan : les changements sont additifs.

### s95-profiles-hold — Les profils disent vrai et leurs tests le prouvent
**En tant que** développeur **je veux** que la commande de test de chaque profil échoue quand un test échoue, et qu'un test de profil hors réseau se voie **afin que** les gates ne fassent jamais confiance à un test rouge ni à une vérification sautée.

- **Complexité** : 3
- **Dépend de** : aucune
- **Surface** : —
- **Owns** : `boilerplates/native-ios/`, `boilerplates/native-android/`, `boilerplates/expo/`, `boilerplates/rust-cli/`, `bin/po-lint`, `tests/run.sh`, `tests/lib.sh`, `tests/native-profiles.test.sh`, `tests/expo-profile.test.sh`, `tests/flutter-profile.test.sh`, `tests/cli-api-profiles.test.sh`, `tests/next-forge-profile.test.sh`, `tests/platform-setting.test.sh`, `tests/profile.test.sh`, `tests/profiles-hold.test.sh`, `docs/decisions/ADR-0062-le-profil-expo-part-de-expo-template-default-sur-la-branche-sdk-57.md`, `docs/decisions/ADR-0064-profils-natifs-depuis-ios-templates-de-nimble-et-architecture-templates-d-android.md`
- **Corrige** : majeur F1 et mineurs de `docs/reviews/s85-native-profiles.md` ; mineurs de `docs/reviews/s83-expo-profile.md`, `s86-cli-api-profiles.md` et `s78-platform-setting.md`

**Critères d'acceptation**
- [ ] `test_commands_fail_on_red` — la commande `Test` du profil iOS sort en erreur quand un test échoue, et celle d'Expo n'installe rien à la volée (`npx --no-install jest`) ; une ADR qui remplace en partie ADR-0062 et ADR-0064 le dit, et leurs `superseded-by` la nomment.
- [ ] `skipped_grounding_is_visible` — un test d'ancrage de profil qui n'a pas pu joindre sa source apparaît comme sauté dans la sortie de `tests/run.sh`, pas comme passé.
- [ ] `lint_holds_its_profile_rules` — `po-lint` refuse un pilote `mobile-web` avec `Dev: —`, et ses règles de profil (valeur partielle de plateforme, `## Platform` sans ligne, ligne `| Platform |` cassée, pilote `—`) ont chacune un test.
- [ ] `profile_slips_are_fixed` — les phrases fausses relevées par les revues sont corrigées d'après leur source : xcbeautify en `latest` (iOS), la liste complète de ce que supprime `customizer.sh` et ce que possède `ui/<feature>/` (Android), la section Linux de `utils/Cargo.toml` (Rust).

**Notes pour l'agent** : les tests d'ancrage impriment déjà `not reachable: grounding not checked` quand leur source est injoignable ; `tests/run.sh` reconnaît ce marqueur pour afficher le test comme sauté, sans modifier les fichiers de test de s94. Les nouveaux cas de `po-lint` vont dans `tests/profile.test.sh` ou `tests/profiles-hold.test.sh`, pas dans `tests/qa-drivers.test.sh` (s93).

### s96-defect-and-routing-paths — Le diagnostic et le routage tiennent sur tous les chemins
**En tant que** développeur **je veux** qu'une story de défaut passe par le diagnostic quel que soit le chemin qui la mène, et qu'une recherche sans cause trouvée aille à un humain **afin qu'**aucun correctif deviné ne parte.

- **Complexité** : 3
- **Dépend de** : aucune
- **Surface** : —
- **Owns** : `method/commands/po-research.md`, `method/commands/po-orchestrator.md`, `method/commands/po-drive.md`, `method/commands/po-execute.md`, `method/commands/po-flow.md`, `method/commands/po-plan.md`, `method/agents/planner.md`, `method/skills/diagnostic/`, `docs/decisions/ADR-0068-une-story-de-defaut-porte-une-ligne-fixes-et-passe-par-le-diagnostic.md`, `tests/defect-and-routing-paths.test.sh`, `tests/research.test.sh`, `tests/drive.test.sh`, `tests/execute.test.sh`, `tests/model-routing.test.sh`, `tests/flow.test.sh`, `tests/diagnostic-skill.test.sh`
- **Corrige** : majeurs 1 et 2 de `docs/reviews/s90-diagnostic-skill.md` ; mineur de `docs/reviews/s80-surface-routing.md` (po-flow)

**Critères d'acceptation**
- [ ] `every_path_runs_the_diagnostic` — `/po-research` et `/po-orchestrator` appliquent la skill `diagnostic` à une story qui porte une ligne `Fixes` ou `Corrige`, comme le planner de la flotte.
- [ ] `no_root_cause_goes_to_a_human` — la skill `diagnostic` fixe la ligne qu'une recherche écrit quand aucune cause n'a été trouvée ; la table de reprise de `/po-drive`, le planner et `/po-plan` arrêtent alors la story et la confient à un humain, sans bâtir de plan dessus ; ADR-0068 est remplacée en partie là où elle disait que `/po-research` ne charge pas la skill.
- [ ] `flow_names_the_qa_stage_exception` — `/po-flow` dit qu'un `QA stage` absent n'arrête qu'une story qui irait en QA.
- [ ] `implementer_may_explore_a_throwaway_clone` — le prompt de l'implementer dans `/po-execute` interdit `checkout` dans le worktree de la story, et plus partout, pour s'accorder avec s98.

**Notes pour l'agent** : `tests/surface-routing.test.sh`, `tests/qa-fleet.test.sh`, `tests/resume.test.sh`, `tests/fleet-design.test.sh`, `tests/grouped-validation.test.sh` et `tests/owns-overlap.test.sh` figent des phrases des commandes possédées ici : les changements sont additifs et gardent ces phrases.

### s97-commands-and-texts — Les commandes et les textes rattrapent M8
**En tant que** développeur **je veux** que `/po-retro`, `/po-setup`, `/po-help`, la relecture des stories et la documentation disent la méthode telle que M8 l'a laissée **afin qu'**un lecteur ne bute pas sur une consigne fausse.

- **Complexité** : 2
- **Dépend de** : aucune
- **Surface** : —
- **Owns** : `method/commands/po-retro.md`, `method/commands/po-setup.md`, `method/commands/po-help.md`, `method/skills/stories-review/`, `docs/parite-killer-saas.md`, `docs/stories.md`, `tests/po-retro.test.sh`, `tests/setup-modes.test.sh`, `tests/stories-review.test.sh`, `tests/accessibility.test.sh`, `tests/commands-and-texts.test.sh`
- **Corrige** : majeur et mineur de `docs/reviews/s89-po-retro.md` ; mineurs de `s78-platform-setting.md`, `s80-surface-routing.md`, `s83-expo-profile.md`, `s90-diagnostic-skill.md`, `s91-accessibility.md`

**Critères d'acceptation**
- [ ] `retro_prefers_an_exact_milestone` — `/po-retro` choisit le jalon dont le titre correspond exactement avant de chercher par préfixe, et compte les majeurs ouverts depuis la dernière revue non bloquée.
- [ ] `texts_follow_m8` — l'en-tête de l'étape 2 de `/po-setup` compte les bonnes questions ; `/po-help` donne la règle QA d'une story sans ligne `Surface` ; la ligne D15 de la matrice de parité ne compte plus « cinq signaux » ; le critère d'Expo dans `docs/stories.md` ne dit plus que le gabarit a une commande de test.
- [ ] `stories_review_checks_owned_records` — `stories-review` signale une story qui corrige un défaut sans posséder le fichier que sa ligne `Fixes` désigne, et une story dont l'ADR en remplace une autre sans posséder le fichier de celle-ci.
- [ ] `keyboard_walk_test_bites` — le test de la visite au clavier vérifie une phrase que seul le nouveau paragraphe porte.

**Notes pour l'agent** : `tests/qa-fleet.test.sh` fige la ligne QA de `/po-help` : garder ses phrases. ADR-0067 dit « ouvert selon la dernière revue » : la règle nouvelle (dernière revue non bloquée) la précise sans la contredire ; si elle la contredit, le dire dans le plan.

### s98-bounds-messages — Les derniers messages de po-bounds
**En tant que** développeur **je veux** que chaque refus de `po-bounds` soit lisible et que l'implementer puisse explorer un clone jetable **afin qu'**un refus dise toujours ce qu'il refuse, et que l'exploration d'une source ne soit plus bloquée pour rien.

- **Complexité** : 2
- **Dépend de** : s96
- **Surface** : —
- **Owns** : `method/hooks/po-bounds.sh`, `method/agents/implementer.md`, `docs/installation.md`, `tests/bounds.test.sh`, `tests/bounds-messages.test.sh`, `docs/decisions/ADR-0050-po-bounds-lit-un-heredoc-comme-bash-le-lira.md`, `docs/decisions/ADR-0052-po-bounds-est-un-garde-fou-contre-les-erreurs.md`
- **Corrige** : mineur m1 de `docs/reviews/s77-last-review-leftovers.md` ; mineur m3 de `docs/reviews/s76-bounds-guard-against-mistakes.md` ; refus de `git checkout` rapportés par les implementers de s84 et s85 (2026-10-08, dans leurs comptes rendus, sans fichier)

**Critères d'acceptation**
- [ ] `every_refusal_is_readable` — aucun refus de `po-bounds` n'affiche l'octet de marquage brut, y compris pour une substitution placée dans le nom d'une option.
- [ ] `named_fd_redirections_are_read` — `{fd}>cible` est lu comme une redirection.
- [ ] `implementer_explores_a_throwaway_clone` — en mode `implementer`, un dépôt jetable sous le répertoire temporaire accepte les verbes git de lecture et de `checkout`, et rien n'en sort vers le worktree ; une ADR qui remplace en partie ADR-0050 (qui refuse `checkout` en mode `implementer`) le dit, et `method/agents/implementer.md` comme `docs/installation.md` ne l'interdisent plus que dans le worktree de la story.

### s99-throwaway-zone-holds — La zone jetable de l'implementer tient sa promesse
**En tant que** développeur **je veux** que la zone jetable ouverte à l'implementer par s98 refuse les moyens de viser un autre arbre de travail, comme celle du reviewer **afin qu'**ADR-0072 dise vrai : rien n'en sort vers le worktree.

- **Complexité** : 2
- **Dépend de** : aucune
- **Surface** : —
- **Owns** : `method/hooks/po-bounds.sh`, `method/agents/implementer.md`, `tests/bounds-messages.test.sh`, `tests/throwaway-zone-holds.test.sh`
- **Corrige** : majeur et mineurs de `docs/reviews/s98-bounds-messages.md`

**Critères d'acceptation**
- [ ] `throwaway_refuses_another_work_tree` — en mode `implementer`, dans un dépôt jetable, `--work-tree`, `-c core.worktree=…` (et `--config-env` vers cette clé) et une assignation `GIT_WORK_TREE=` ou `GIT_DIR=` sont refusés, comme en mode `reviewer`.
- [ ] `story_worktree_is_judged_first` — un test place un worktree de story sous le répertoire temporaire et montre qu'il y est jugé comme worktree de story, pas comme dépôt jetable.
- [ ] `implementer_knows_the_file_url` — `method/agents/implementer.md` dit qu'un clone d'une source locale depuis le répertoire temporaire se fait par `file://<chemin>`.

**Notes pour l'agent** : réutiliser la vérification de clé de configuration du mode `reviewer` (`check_config_key`) plutôt que d'en écrire une seconde ; ADR-0072 n'a pas à changer, puisque le hook la rend vraie.

### s100-qa-evidence-set-aside — La preuve de QA ne bloque jamais sa propre visite
**En tant que** développeur **je veux** que la comparaison avant/après de chaque pilote reconnaisse sa propre preuve même à la première QA d'un projet, et que les règles du pilote par scénarios aient des tests qui mordent **afin qu'**une première QA ne finisse pas `blocked` sur ses propres fichiers.

- **Complexité** : 2
- **Dépend de** : aucune
- **Surface** : —
- **Owns** : `method/agents/qa.md`, `method/skills/qa-drivers/scenarios.md`, `method/skills/qa-drivers/scene.md`, `method/skills/qa-drivers/simulation.md`, `tests/qa-contract-holds.test.sh`, `tests/qa-evidence-set-aside.test.sh`
- **Corrige** : majeur et mineurs de `docs/reviews/s93-qa-contract-holds.md` ; mineurs de `docs/reviews/s94-scene-and-simulation-drivers.md` (arrêt des groupes du pilote de scène, attente de l'enregistreur)

**Critères d'acceptation**
- [ ] `first_qa_sets_its_evidence_aside` — `qa` et les trois pilotes qui comparent l'état du dépôt mettent de côté `docs/qa/<id>/` et toute ligne parente qui ne couvre que lui (`?? docs/qa/` à la première QA), ou listent les fichiers non suivis un par un.
- [ ] `bounded_waits_bite` — la conséquence de la limite de 60 secondes du pilote par scénarios et celle de la ligne sans pilote de `qa` ont chacune un test qui échoue quand elle disparaît ou s'inverse.
- [ ] `scene_and_recorder_stop_cleanly` — le pilote de scène arrête chaque groupe de processus qu'il a lancé et fait quitter le moteur après la capture ; l'attente de l'arrêt de l'enregistreur du pilote de simulation est bornée, et son dépassement est un constat.

**Notes pour l'agent** : `tests/qa-drivers.test.sh`, `tests/scenario-driver.test.sh`, `tests/godot-scene-driver.test.sh`, `tests/ros-simulation-driver.test.sh` et `tests/scene-and-simulation-drivers.test.sh` figent des phrases de ces fichiers : les garder.

## M9 — L'autonomie

Le cadrage se valide en conversation, la session principale devient le chef de projet, et l'humain n'est plus sollicité que pour une incohérence, une idée nouvelle, une décision stratégique ou un choix technique (ADR-0074 à ADR-0077). Rien n'arrive plus sur la branche cible autrement que par une PR en fast-forward (ADR-0080). Aucune gate de Law 3 ne change.

Tests qui figent `method/AGENTS.md` sans appartenir à une story de M9 : `tests/fleet-wiring.test.sh` et `tests/structure.test.sh`. Les changements y restent additifs et gardent leurs phrases.

### s101-conversational-framing — Le cadrage se valide en conversation
**En tant que** porteur de projet **je veux** valider chaque section du brief ou du PRD, chaque story et chaque ADR seule, à partir d'un résumé dans le terminal **afin de** ne jamais ouvrir un fichier pour approuver le cadrage (ADR-0074).

- **Complexité** : 3
- **Dépend de** : aucune
- **Surface** : —
- **Owns** : `method/commands/po-brief.md`, `method/commands/po-prd.md`, `method/commands/po-stories.md`, `method/commands/po-stories-review.md`, `method/commands/po-architect.md`, `method/commands/po-design-system.md`, `tests/conversational-framing.test.sh`

**Critères d'acceptation**
- [ ] `framing_never_asks_to_read_a_file` — aucune des six commandes possédées ne demande de lire un fichier de bout en bout ni ne soumet ses éléments dans une approbation groupée.
- [ ] `one_item_per_question` — chaque élément est soumis seul, avec les réponses Approuver / Modifier / Écarter : `/po-brief` et `/po-prd` une section ; `/po-stories` une story ; `/po-architect` une ADR, puis les conventions, puis `docs/architecture.md` résumé en un élément ; `/po-design-system` un groupe de jetons, une correction de contraste ou un manque. Le fichier n'est écrit qu'après l'accord, et le commit ne demande aucune relecture.
- [ ] `summary_short_but_complete` — le résumé donne le quoi, le pourquoi, et les options écartées (ADR) ou les critères (story) ; il vise court et s'allonge quand le sujet l'exige.
- [ ] `stories_review_surfaces_criticals_only` — `/po-stories-review` soumet ses findings critiques un par un, avec les réponses Corriger (la commande renvoie la story à `/po-stories`, elle n'édite jamais elle-même les stories), Accepter le risque (le finding reste ouvert dans le rapport) et Écarter la story ; les majeurs et les mineurs restent dans le rapport.

**Notes pour l'agent** : les gardes existantes (`status: approved`, branche `Target branch`, commit commun du brief et de son ADR) restent telles quelles ; seule la façon de recueillir l'accord change. `/po-design` n'est pas concerné (ADR-0019). `/po-stories-review` gagne AskUserQuestion dans ses `allowed-tools` : `bin/po-lint` refuse un corps qui pose une question sans l'outil (`tests/lint.test.sh`). Tests non possédés qui figent ces textes, à garder verts par des changements additifs : `tests/architect.test.sh` (section `Approval and commit`, « what the new conventions would remove or contradict », AskUserQuestion) — `po-architect.md:53` cite aussi « the grouped AskUserQuestion of "Approval and commit" », à réécrire ; `tests/brief.test.sh` (« agreement », « set `status: approved` », « The approval and its ADR go in the same commit, or neither ») ; `tests/stories.test.sh` ; `tests/design-system.test.sh`.

### s102-ship-follows-the-forge — Le ship suit le processus de revue du dépôt
**En tant que** porteur de projet seul sur un dépôt **je veux** que la flotte merge ce que la gate a prouvé sans me le demander, sauf si le dépôt ou moi exigeons une revue humaine **afin de** n'être sollicité pour un merge que lorsqu'un humain doit vraiment relire (ADR-0075, ADR-0079).

- **Complexité** : 3
- **Dépend de** : s105-ship-through-pr
- **Surface** : —
- **Owns** : `method/commands/po-setup.md`, `method/commands/po-ship.md`, `method/commands/po-drive.md`, `method/commands/po-orchestrator.md`, `method/commands/po-flow.md`, `method/templates/agents-local.md`, `method/AGENTS.md`, `tests/drive.test.sh`, `tests/ship-follows-forge.test.sh`

**Critères d'acceptation**
- [ ] `setup_reads_review_rules_from_the_forge` — `/po-setup` détecte la forge depuis le remote `origin` (GitHub, GitLab, sinon Forgejo/Gitea sondé sur `/api/v1`) et lit par son API la revue obligatoire de la protection de branche, `CODEOWNERS` et les autres collaborateurs avec droit d'écriture ; il propose `Ship confirmation` en conséquence et ne recopie plus `Plan validation` sur lui. Pas de remote, hôte inconnu ou pas de jeton : la forge est illisible et le rapport le dit.
- [ ] `collaborative_repo_forbids_agent_merge` — un dépôt collaboratif (autre collaborateur en écriture, `CODEOWNERS` qui nomme quelqu'un d'autre, ou protection qui exige une approbation) donne `human (forge)` quoi que dise la ligne ; un dépôt où la personne est seule suit son choix du setup, `automatic (chosen)` ou `human (chosen)`, modifiable en conversation ; une valeur sans suffixe se lit `(forge)`, et un dépôt solo y donne `automatic (forge)`. Le 403 d'un dépôt privé sur un plan gratuit vaut « aucune protection ».
- [ ] `setting_records_its_origin` — la valeur de `Ship confirmation` porte un suffixe d'origine, `(forge)` ou `(chosen)` (le `(choisi)` d'ADR-0075, en anglais comme le reste de la méthode) ; la section « Reading settings » de `method/AGENTS.md` dit qu'un suffixe final entre parenthèses est l'origine, pas la valeur, de sorte que `human (forge)` se lit `human` partout où une commande compare la valeur.
- [ ] `template_defaults_trust_the_gates` — le gabarit propose `Plan validation: autonomous` (ADR-0077 : l'humain n'est sollicité que pour ses motifs) et `Ship confirmation: automatic`.
- [ ] `forge_tightening_switches_to_human` — à chaque ship, une forge qui exige désormais une revue fait passer le réglage à `human (forge)`, ligne commitée sur une branche, poussée et proposée en PR draft (ADR-0080), signalée au rapport, le ship suivant déjà la valeur effective ; une valeur `(forge)` revient à `automatic` quand la forge ne l'exige plus ; une forge sans API lisible garde la valeur du setup et le rapport le dit.
- [ ] `chosen_value_never_moves` — une valeur `(chosen)` n'est jamais réécrite par un agent, et `method/AGENTS.md` borne l'exception à « an agent reads settings, it never decides them » aux seules valeurs `(forge)`.
- [ ] `pr_wait_does_not_block_the_fleet` — sous `human` en mode `pr`, ouvrir la PR n'est pas l'atterrissage : la flotte ouvre la PR, passe aux autres voies et peut ouvrir la PR suivante, l'ordre d'atterrissage restant celui des merges humains ; le nettoyage n'a lieu qu'une fois le merge prouvé. La règle « Ships stay serial » de `method/AGENTS.md` et `po-drive.md` le dit, en gardant ses phrases.
- [ ] `ship_gate_unchanged` — `po-gate ship-allowed` est toujours exigé avant tout merge, quelle que soit la valeur.

**Notes pour l'agent** : ADR-0079, écrite par le premier plan sans discussion, a été réécrite avec le porteur le 2026-10-13 : la recherche déjà sur disque reste, le plan et l'ADR sont refaits sur les critères ci-dessus, et la PR passe par le chemin de s105. `tests/drive.test.sh` fige la phrase « `Ship confirmation: human` means one AskUserQuestion per merge » ; la story la change, et le dit. Tests non possédés à garder verts par des changements additifs : `tests/fleet-wiring.test.sh` (« **Ships stay serial** », « in the order the reviews passed ») ; pour l'étape 2 de `po-setup.md`, `tests/commands-and-texts.test.sh`, `tests/setup-modes.test.sh`, `tests/platform-setting.test.sh`, `tests/design-handoff.test.sh`, `tests/qa.test.sh` ; `tests/structure.test.sh` (forme des lignes du gabarit : pas de `#`) ; `tests/ship.test.sh` (AskUserQuestion dans `po-ship.md`) ; et ceux qui figent `po-drive.md` et `po-orchestrator.md` (`resume`, `qa-fleet`, `fleet-design`, `surface-routing`, `grouped-validation`).

### s103-project-lead — La session principale est le chef de projet
**En tant que** porteur de projet **je veux** qu'en ouvrant une conversation sur un projet Polype, la session soit d'emblée le chef de projet qui connaît l'état du projet **afin de** n'avoir aucune commande à taper pour que le projet avance (ADR-0076).

- **Complexité** : 3
- **Dépend de** : s102-ship-follows-the-forge
- **Surface** : —
- **Owns** : `method/AGENTS.md`, `method/hooks/po-session.sh`, `bin/polype`, `method/commands/po-help.md`, `docs/installation.md`, `tests/project-lead.test.sh`

**Critères d'acceptation**
- [ ] `rules_name_the_project_lead` — `method/AGENTS.md` dit que la session principale est le chef de projet : il mène le cadrage en conversation quand il manque, puis lance `/po-drive` vague après vague jusqu'à la fin du jalon, sans écrire le code d'une story ; un subagent n'est pas le chef.
- [ ] `lead_answers_before_driving` — `method/AGENTS.md` dit que le chef répond d'abord à la question posée et ne relance la flotte que si le projet l'attend.
- [ ] `session_hook_reports_state_read_only` — `po-session.sh` imprime l'étape du cadrage (fichiers de cadrage présents et approuvés), les stories prêtes, les voies en vol (worktrees sous `Worktree root`) et les escalades en attente, définies comme les cas que `/po-drive status` liste pour un humain : `Root cause: not found`, QA `blocked`, `Max attempts` atteint, worktree orphelin, plus une PR qui attend un merge humain sous s102 ; les escalades de conversation n'y figurent pas. Il n'écrit aucun fichier et ne lance aucune commande git qui modifie le dépôt.
- [ ] `session_hook_silent_outside_polype` — hors d'un projet Polype, le script n'imprime rien et sort en 0.
- [ ] `installer_wires_the_session_hook` — chaque pose qui active un projet (`init`, `install <projet>`, `update`) ajoute le hook `SessionStart` au `.claude/settings.json` du projet par fusion avec `jq`, sans toucher les autres clés ; `remove` le retire, et supprime le fichier s'il ne contenait que lui ; sans `jq`, la pose continue, saute le seul hook et le dit.
- [ ] `help_says_no_command_needed` — `po-help.md` et `docs/installation.md` disent qu'ouvrir une session suffit pour que le chef reprenne le projet.

**Notes pour l'agent** : choix de branchement discuté avec l'humain le 2026-10-13 (settings du projet plutôt que global : le global est suivi par chezmoi et toucherait toutes les sessions). Le script tourne à chaque ouverture : il reste rapide et sans dépendance autre que bash et git. Risque principal : que le script reconstruise mal l'état ; ses tests partent de dépôts jetables qui couvrent chaque cas listé. Tests non possédés à garder verts : `tests/global-install.test.sh` (`init` ne crée ni `.claude/commands`, ni `agents`, ni `skills`, et son manifeste ne liste aucun fichier `.claude/` : `settings.json` est fusionné, pas installé) ; `tests/installer.test.sh` (aucun fichier vide ou temporaire après `remove`).

### s104-escalation-contract — Ce qui remonte à l'humain, ce que le chef tranche seul
**En tant que** porteur de projet **je veux** un contrat écrit de ce qui me revient et de ce que le chef tranche seul, avec un journal de ses décisions **afin d'**être sollicité seulement là où mon jugement change le résultat, sans jamais perdre la main sur la technologie (ADR-0077).

- **Complexité** : 3
- **Dépend de** : s101-conversational-framing, s103-project-lead, s106-framing-through-pr
- **Surface** : —
- **Owns** : `method/AGENTS.md`, `method/commands/po-drive.md`, `method/commands/po-orchestrator.md`, `method/commands/po-architect.md`, `method/commands/po-plan.md`, `method/commands/po-flow.md`, `method/agents/planner.md`, `method/skills/capability-bricks/SKILL.md`, `method/templates/decisions-log.md`, `tests/escalation-contract.test.sh`

**Critères d'acceptation**
- [ ] `rules_list_the_three_escalation_motives` — `method/AGENTS.md` nomme l'incohérence (le code, une ADR acceptée et une story qui se contredisent), l'idée nouvelle hors du périmètre approuvé et la décision stratégique (vision, périmètre, coût récurrent, sécurité, données personnelles, difficile à défaire).
- [ ] `tech_choices_are_never_settled_alone` — tout choix technique ou technologique qui mérite une ADR est discuté avec l'humain avant d'être pris ; un détail d'implémentation dans un plan validé reste au chef ; dans le doute, il demande.
- [ ] `plan_with_a_tech_choice_waits_for_a_human` — un plan qui demande un choix digne d'une ADR (bibliothèque, motif, modèle de données) ne se valide jamais lui-même, quel que soit `Plan validation` : `po-plan.md`, `po-flow.md` et `planner.md` le disent, la voie remonte le choix avec ses options classées, les autres voies continuent, et la table de reprise de `/po-drive` porte la ligne « plan en attente d'un choix technique → un humain ».
- [ ] `human_stops_do_not_halt_the_fleet` — `/po-drive` et `/po-orchestrator` remontent chaque arrêt « à un humain » tout de suite, un par un, et la flotte continue les autres voies.
- [ ] `lead_logs_what_it_decides_alone` — chaque décision prise seule ajoute à `docs/decisions-log.md` une ligne datée avec sa raison, selon `templates/decisions-log.md` ; le journal est commité sur une branche et proposé en PR après chaque vague, par le chemin de cadrage de s106 (ADR-0080) ; Law 6 le range parmi les fichiers de cadrage.
- [ ] `options_ranked_by_owner_criteria` — `capability-bricks` et `/po-architect` classent les options d'abord par : open source ou auto-hébergeable, sobre en ressources matérielles, scalable, facile à manipuler pour une IA.

**Notes pour l'agent** : aucune gate ne s'ouvre autrement qu'aujourd'hui ; les arrêts d'ADR-0070 restent des arrêts. Le changement de `capability-bricks` est additif : `tests/capability-bricks.test.sh`, `tests/bricks.test.sh` et `tests/catalogue-wiring.test.sh` le figent. Les tests qui figent `po-plan.md`, `po-flow.md` et `planner.md` restent verts.

### s105-ship-through-pr — Une story arrive sur la branche cible par une PR, en fast-forward
**En tant que** porteur de projet **je veux** que chaque story arrive sur `Target branch` par une PR mergée en fast-forward, un commit par story, sans qu'aucun agent pousse sur cette branche **afin de** garder un historique linéaire où chaque arrivée laisse une PR (ADR-0080).

- **Complexité** : 3
- **Dépend de** : aucune
- **Surface** : —
- **Owns** : `method/AGENTS.md`, `method/commands/po-ship.md`, `method/commands/po-drive.md`, `method/commands/po-orchestrator.md`, `method/commands/po-flow.md`, `method/commands/po-help.md`, `method/commands/po-status.md`, `method/commands/po-setup.md`, `method/agents/implementer.md`, `method/templates/agents-local.md`, `method/hooks/po-gate.sh`, `docs/conception.md`, `docs/migration.md`, `tests/ship.test.sh`, `tests/ship-through-pr.test.sh`

**Critères d'acceptation**
- [ ] `ship_opens_a_pr_and_fast_forwards` — `/po-ship` écrase `story/<id>` en un commit, la rebase sur `Target branch`, la pousse, ouvre la PR et la merge en fast-forward (« Rebase and merge » côté forge) ; sous `human`, il ouvre la PR et s'arrête là, la personne merge.
- [ ] `one_commit_per_story` — le commit qui arrive sur `Target branch` est unique, titré `<id>: <story title>`, sans commit de merge ; Law 1, Law 6, « Merging » et « Done means » de `method/AGENTS.md` le disent à la place du squash.
- [ ] `no_agent_pushes_target_branch` — `method/AGENTS.md` dit qu'aucun agent ne pousse sur `Target branch` ; `/po-ship` ne pousse que `story/<id>`, et repousse une PR rebasée avec `--force-with-lease` sur cette seule branche.
- [ ] `local_only_without_remote` — `Merge mode: local` ne vaut plus que pour un dépôt sans remote : le fast-forward se fait sur la machine et rien n'est poussé ; `/po-setup` et le gabarit le disent.
- [ ] `ship_gate_unchanged` — `po-gate ship-allowed` est exigé avant tout merge ; ADR-0015 est marquée `superseded` par ADR-0080.

**Notes pour l'agent** : `po-gate.sh` ne change que si sa détection d'une story livrée suppose un squash. Tests non possédés qui figent « squash » ou `Merge mode`, à mettre à jour seulement si la story change la clause qu'ils vérifient, en le disant : `tests/drive.test.sh`, `tests/fleet-wiring.test.sh`, `tests/pilot.test.sh`, `tests/migration-doc.test.sh`, `tests/install.test.sh`, `tests/installer.test.sh`, `tests/distribution-wiring.test.sh`, `tests/structure.test.sh`. Risque principal : un ship humain dont `Target branch` avance pendant l'attente ; la reprise de `/po-drive` relit l'état de la PR plutôt que de la recréer.

### s106-framing-through-pr — Le cadrage et les réglages arrivent aussi par une PR
**En tant que** porteur de projet **je veux** que le cadrage et les réglages arrivent sur `Target branch` par une PR comme le code **afin qu'**aucun agent ne pousse sur cette branche et qu'une story ne démarre jamais sur un cadrage resté local (ADR-0080).

- **Complexité** : 3
- **Dépend de** : s105-ship-through-pr
- **Surface** : —
- **Owns** : `method/commands/po-setup.md`, `method/commands/po-brief.md`, `method/commands/po-prd.md`, `method/commands/po-stories.md`, `method/commands/po-stories-review.md`, `method/commands/po-architect.md`, `method/commands/po-design-system.md`, `method/commands/po-research.md`, `tests/framing-through-pr.test.sh`

**Critères d'acceptation**
- [ ] `framing_commits_on_a_branch` — les sept commandes de cadrage commitent sur une branche `framing/<slug>` partie de `Target branch`, la poussent et ouvrent une PR ; aucune ne commite ni ne pousse sur `Target branch`.
- [ ] `framing_pr_fast_forwards` — la PR de cadrage est mergée en fast-forward, par l'agent sous `Ship confirmation: automatic`, par la personne sous `human` ; sans remote, le fast-forward se fait sur la machine.
- [ ] `research_waits_for_framing_merge` — `/po-research` ne crée le worktree d'une story que si sa section est présente sur le point de départ (`origin/<Target branch>` quand il existe) ; sinon il s'arrête en disant que la PR de cadrage attend son merge.

**Notes pour l'agent** : les gardes existantes (`status: approved`, commit commun du brief et de son ADR, approbation élément par élément de s101) restent ; seul l'endroit du commit change. Tests non possédés à garder verts : `tests/brief.test.sh`, `tests/prd.test.sh`, `tests/stories.test.sh`, `tests/stories-review.test.sh`, `tests/architect.test.sh`, `tests/design-system.test.sh`, `tests/conversational-framing.test.sh`, `tests/research.test.sh`.

### s107-forge-token-bound-to-host — Un jeton ne part jamais vers un hôte pour lequel il n'a pas été émis
**En tant que** porteur de projet **je veux** que la lecture de la forge n'envoie un jeton qu'à l'hôte pour lequel il a été émis **afin qu'**un dépôt cloné depuis une instance tierce ne récupère jamais mon jeton d'une autre instance (finding majeur de sécurité de la revue de s102, ADR-0079).

- **Complexité** : 2
- **Dépend de** : aucune
- **Surface** : —
- **Owns** : `method/commands/po-ship.md`, `tests/forge-token-host.test.sh`

**Critères d'acceptation**
- [ ] `env_token_only_for_github` — dans `## The forge's review rule` de `/po-ship`, le repli `curl` avec une variable d'environnement n'existe plus que pour github.com (`GH_TOKEN` ou `GITHUB_TOKEN`) ; `GITLAB_TOKEN` et `GITEA_TOKEN` n'y sont plus cités comme repli.
- [ ] `other_forges_through_their_cli_only` — GitLab et Forgejo/Gitea ne se lisent que par leur CLI (`glab`, `tea`), qui lie chaque jeton à son hôte dans sa configuration ; sans CLI configurée pour l'hôte d'`origin`, la forge est illisible et le rapport le dit.
- [ ] `unknown_host_gets_no_token` — la sonde `/api/v1/version` qui reconnaît un Forgejo/Gitea part sans jeton, et aucun appel vers un hôte non reconnu n'en porte un.

**Notes pour l'agent** : `/po-setup` lit la forge « exactly as `/po-ship` reads it » et n'a pas à changer. Tests non possédés à garder verts : `tests/ship-follows-forge.test.sh`, `tests/ship-through-pr.test.sh`, `tests/ship.test.sh`. Options écartées avec le porteur le 2026-10-13 : lier le jeton par une variable `*_HOST` (convention de glab seulement, rien pour Forgejo) ; garder le repli tel quel.

## M9 bis — Les restes de M9

Objectif : fermer les majeurs que les revues de M9 ont laissés ouverts, rendre la détection des stories livrées juste sur un dépôt qui a gardé des sujets courts, et faire dire au plan ce qu'il réutilise. Cadré le 2026-10-13 avec le porteur ; revue des stories : `docs/reviews/stories-m9bis.md`. Aucune gate de Law 3 ne change.

Tests qui figent les fichiers de ces stories sans leur appartenir : `tests/fleet-wiring.test.sh`, `tests/structure.test.sh`, `tests/drive.test.sh`, `tests/resume.test.sh`, `tests/ship.test.sh`, `tests/ship-follows-forge.test.sh`, `tests/framing-through-pr.test.sh`, `tests/project-lead.test.sh`, `tests/plan.test.sh`, `tests/planner.test.sh`, `tests/flow.test.sh`, `tests/review.test.sh`. Les changements y restent additifs et gardent leurs phrases.

### s108-ship-resumes-cleanly — Un ship automatique repris aboutit
**En tant que** porteur de projet **je veux** qu'un ship automatique interrompu puis repris merge le commit qu'il a déjà poussé **afin qu'**une reprise ne coûte jamais une tentative de correction pour rien.

- **Complexité** : 2
- **Dépend de** : aucune
- **Surface** : —
- **Corrige** : M1 et M2 de `docs/reviews/s105-ship-through-pr.md`, mineurs 1 et 2 de `docs/reviews/s107-forge-token-bound-to-host.md`
- **Owns** : `method/commands/po-ship.md`, `tests/ship-through-pr.test.sh`, `tests/forge-token-host.test.sh`, `tests/ship-resumes-cleanly.test.sh`

**Critères d'acceptation**
- [ ] `resumed_ship_merges_the_pushed_head` — quand `origin/story/<id>` porte déjà un commit de parent `<base>` et d'arbre `<tree>` et que la poussée est sautée, `/po-ship` prend `<sha>` de `origin/story/<id>` ; `--match-head-commit` reçoit ce SHA complet, jamais un commit reconstruit à neuf.
- [ ] `push_targets_only_the_story_ref` — le test de `tests/ship-through-pr.test.sh` qui interdit de pousser `Target branch` vérifie la refspec elle-même (`<sha>:refs/heads/story/<id>`) et échoue si une ligne `git push` de `po-ship.md` nomme `Target branch` ; retirer la refspec ou ajouter `Target branch` à la ligne existante le fait échouer.
- [ ] `forge_read_pins_and_skips_curlrc` — la lecture de la forge appelle `curl -q` (qui ignore `~/.curlrc`) partout où elle dit ne porter aucun jeton, et un test échoue si le `--hostname github.com` de `gh api` disparaît.

**Notes pour l'agent** : la revue de s105 laissait le choix entre reprendre le SHA poussé et des dates fixes pour `commit-tree` ; le plan retient la reprise du SHA poussé, qui ne change pas le commit construit au premier passage. Si le planner juge l'autre voie nécessaire, c'est un choix technique : la ligne `Technical choice: waiting for a human`.

### s109-drive-guards — Les lanes de la flotte gardent les garde-fous du chemin seul
**En tant que** porteur de projet **je veux** qu'une lane de `/po-drive` vérifie son point de départ comme `/po-research`, que l'attente d'un merge humain n'arrive que sous un `human` effectif, et que chaque décision prise seul soit consignée **afin que** la flotte ne parte jamais d'un cadrage non mergé, n'attende pas un humain qui n'a rien à faire, et que je relise tout ce qui s'est tranché sans moi.

- **Complexité** : 3
- **Dépend de** : aucune
- **Surface** : —
- **Corrige** : majeur 1 de `docs/reviews/s106-framing-through-pr.md`, majeur 2 de `docs/reviews/s102-ship-follows-the-forge.md`, mineur `method/AGENTS.md:79` de `docs/reviews/s104-escalation-contract.md`
- **Owns** : `method/commands/po-drive.md`, `method/commands/po-orchestrator.md`, `tests/drive-guards.test.sh`

**Critères d'acceptation**
- [ ] `lane_checks_its_start_point` — `### Preparing the lanes` reprend l'étape 2 de `/po-research` qui vérifie que la story est présente au point de départ ; une story dont le cadrage n'est pas encore sur `origin/<Target branch>` n'ouvre pas de lane et le rapport dit qu'elle attend le merge du cadrage.
- [ ] `pr_wait_needs_effective_human` — la ligne de `## Resuming` qui fait attendre une PR ouverte un merge humain exige un `Ship confirmation` effectif à `human` ; un test échoue si cette condition est retirée de la ligne, et sous `automatic` une PR ouverte reprend au ship.
- [ ] `lone_decisions_are_all_logged` — `## The decisions log` de `/po-drive` consigne chaque décision prise seul que `AGENTS.md` nomme, détail d'implémentation et réponse donnée sans demander compris. `/po-orchestrator` gagne une section `## The decisions log` : il consigne son approbation autonome d'un plan et ses runs de correction, écrit les lignes une fois la story livrée ou arrêtée — jamais avant son ship, pour ne pas laisser la racine modifiée — et les livre par le chemin de cadrage, comme `/po-drive`.

### s110-framing-second-landing — Un second dépôt du même cadrage ne perd rien
**En tant que** porteur de projet **je veux** qu'un deuxième atterrissage sur la même branche de cadrage parte de ce qu'elle porte déjà tant qu'elle n'est pas mergée, quelle que soit la forge, et que la racine se réaligne une fois le merge prouvé **afin qu'**un second `/po-architect` ne fasse jamais disparaître l'ADR du premier.

- **Complexité** : 2
- **Dépend de** : aucune
- **Surface** : —
- **Corrige** : majeur 2 et mineur 3 de `docs/reviews/s106-framing-through-pr.md`
- **Owns** : `method/commands/po-setup.md`, `tests/framing-second-landing.test.sh`

**Critères d'acceptation**
- [ ] `framing_merge_is_proven_per_forge` — `## Landing the framing` dit qu'une branche `framing/<slug>` est mergée selon la preuve de l'étape 3 de `/po-ship` : avec une pull request, `gh pr view` sur elle affiche exactement `MERGED` ; sans pull request (une forge en vrai fast-forward, ADR-0081), le commit de tête de `origin/framing/<slug>` est ancêtre de `origin/<Target branch>`. L'ascendance n'est jamais la preuve d'un merge sur GitHub.
- [ ] `second_landing_stacks_on_the_framing_branch` — la **Base** est `origin/framing/<slug>` dès que cette branche distante existe et que la preuve ci-dessus ne la dit pas mergée, qu'une pull request soit ouverte ou non ; sinon `origin/<Target branch>`, et une branche mergée n'est jamais reprise comme base.
- [ ] `root_realigns_after_a_merge` — chaque commande de cadrage, avant de construire son commit, réaligne la racine sur `origin/<Target branch>` par `git merge --ff-only` quand la preuve dit mergée une branche `framing/<slug>` qu'elle avait laissée en attente ; un refus est rapporté et rien n'est forcé.

**Notes pour l'agent** : correction du critique de `docs/reviews/stories-m9bis.md` approuvée par le porteur le 2026-10-13 : la preuve de merge de `/po-ship`, pas l'ascendance seule, et `git merge --ff-only`, déjà employé par le chemin automatique, plutôt que `git reset --keep`.

### s111-tech-choice-backstop — Un plan court renvoyé garde sa question
**En tant que** porteur de projet **je veux** qu'un plan court renvoyé pour un choix technique garde la ligne qui le fait attendre et les options à me soumettre **afin que** `/po-plan` me pose toujours la question, même en `Plan validation: autonomous`.

- **Complexité** : 2
- **Dépend de** : aucune
- **Surface** : —
- **Corrige** : majeurs 1 et 2 de `docs/reviews/s104-escalation-contract.md`, majeur de `docs/reviews/s101-conversational-framing.md`
- **Owns** : `method/commands/po-flow.md`, `method/commands/po-plan.md`, `tests/escalation-contract.test.sh`, `tests/conversational-framing.test.sh`, `tests/tech-choice-backstop.test.sh`

**Critères d'acceptation**
- [ ] `flow_plan_sent_back_keeps_the_marker` — quand la clause d'approbation de `/po-flow` renvoie un plan vers `/po-research` pour un choix technique, elle écrit `Technical choice: waiting for a human` dans le plan déjà présent, le laisse en `validated: no` et esquisse l'ADR en `status: proposed` avec ses options rangées selon les critères du porteur ; `/po-plan` qui saute à l'approbation trouve la ligne et pose la question avec ces options.
- [ ] `approval_test_bites_in_its_section` — le test du critère `plan_with_a_tech_choice_waits_for_a_human` vérifie la ligne et sa règle dans la section `Approval` de `po-plan.md`, si bien que retirer le paragraphe qui tranche le choix avec la personne le fait échouer.
- [ ] `stories_review_rules_bite` — `test_stories_review_surfaces_criticals_only` échoue si la règle « never changed: a verdict is the subagent's » de `po-stories-review.md` ou le refus « has already started » de `po-stories.md` disparaît.

### s112-short-subject-shipped — Une story livrée sous un sujet court compte comme livrée
**En tant que** porteur de projet **je veux** qu'une story livrée sous un sujet `sNN:` compte comme livrée quand aucun commit ne porte son id complet **afin que** `/po-drive` ne relance jamais s01 à s10 sur ce dépôt ni sur un dépôt qui a gardé l'ancienne convention.

- **Complexité** : 2
- **Dépend de** : s109-drive-guards
- **Surface** : —
- **Owns** : `method/hooks/po-session.sh`, `method/commands/po-status.md`, `method/commands/po-drive.md`, `tests/short-subject-shipped.test.sh`

**Critères d'acceptation**
- [ ] `short_subject_counts_as_shipped` — `/po-status` et `/po-drive` disent, avec la même phrase, qu'une story `s<n>-<slug>` est livrée sur un commit de `Target branch` (ou `origin/<Target branch>`) dont le sujet commence par `<id>:`, ou, faute d'un tel commit, par `s<n>:` exactement ; `po-session` applique la même règle dans `read_shipped`.
- [ ] `short_subject_is_exact` — `s1:` ne marque pas `s10-…` ni `s100-…`, et un sujet `s10-autre:` ne marque pas `s10-…` ; un test le montre sur un dépôt jetable avec `po-session`.
- [ ] `session_lists_no_short_shipped_story` — sur un dépôt jetable dont l'historique livre `s01-x` sous `s01: …`, `po-session` ne liste pas `s01-x` dans les stories prêtes.

**Notes pour l'agent** : option retenue par le porteur le 2026-10-13 ; options écartées : une marque « Livrée » dans `docs/stories.md` (un second signal à tenir) et ne rien changer (vigilance à chaque vague). Dépend de s109 parce que les deux possèdent `po-drive.md`. Ce dépôt livre bien s01 à s10 sous `s01:` … `s10:` (`git log --oneline main`).

### s113-reuse-ladder — Le plan dit ce qu'il réutilise avant d'écrire du neuf
**En tant que** développeur **je veux** que chaque plan dise, pour chaque morceau de code neuf, ce qu'il aurait pu réutiliser et pourquoi il ne le fait pas, et que la revue relève le code neuf qu'un existant fournissait déjà **afin qu'**un plan surdimensionné ne soit plus exécuté tel quel sans que personne le conteste.

- **Complexité** : 3
- **Dépend de** : s111-tech-choice-backstop
- **Surface** : —
- **Owns** : `method/templates/plan.md`, `method/templates/plan-flow.md`, `method/agents/planner.md`, `method/commands/po-plan.md`, `method/commands/po-flow.md`, `method/skills/review-antihallu/SKILL.md`, `tests/reuse-ladder.test.sh`

**Critères d'acceptation**
- [ ] `plans_carry_a_reuse_section` — `plan.md` et `plan-flow.md` portent une section `## Reuse` qui demande, pour chaque morceau de code neuf, le premier échelon qui tient — déjà dans ce dépôt (`path:line`), bibliothèque standard ou plateforme, dépendance déjà installée, code neuf — et pourquoi chaque échelon au-dessus échoue ; elle interdit toute option, configuration ou abstraction que la story ne demande pas.
- [ ] `never_cut_list_is_explicit` — la même section dit que l'échelle ne retire jamais la validation aux frontières de confiance, la sécurité, ni la gestion d'erreur qui évite une perte de données.
- [ ] `planner_requires_the_ladder` — le contrat du planner (puce **Plan** et puce **Short track**), `/po-plan` et `/po-flow` exigent la section `## Reuse` remplie ; un plan sans code neuf l'écrit en une ligne plutôt que de l'omettre.
- [ ] `review_flags_rebuilt_helpers` — l'étape 3 de `review-antihallu` dit qu'un code neuf que fournissait déjà un utilitaire existant cité, ou la bibliothèque standard, est un constat **majeur**, et que l'écart entre la section `## Reuse` du plan et le diff se juge comme un écart à une tâche.

**Notes pour l'agent** : cadrée d'abord le 2026-10-13 sous l'id `s101-reuse-ladder` (branche `story/reuse-ladder`, jamais livrée), reprise ici avec l'accord du porteur, et coupée en deux sur la revue des stories : la mesure est s114. L'idée vient de Ponytail (`DietrichGebert/ponytail`), dont l'échelle est : faut-il que ça existe → déjà dans le code → bibliothèque standard ou plateforme → dépendance installée → le minimum de code neuf. Polype reprend le mécanisme au moment du plan, pas ses hooks permanents. Écrire la méthode avec ses propres mots, sans reprendre le texte de Ponytail. L'implementer reste tel quel (`method/agents/implementer.md`, « Do what the plan says and nothing else ») : c'est le plan qui porte l'échelle. La lentille Dependencies de `review-lenses` reste valable et n'est pas dupliquée. La section tient dans les limites de longueur de la Loi 6. Le choix « échelle au plan, mesurée contre un témoin, pas de hook permanent » mérite une ADR, écrite par le planner avec le numéro que le pilote lui réserve, et soumise au porteur.

### s114-reuse-ladder-eval — La règle de réutilisation se mesure contre un témoin
**En tant que** développeur **je veux** une recette d'éval qui plante un utilitaire réécrit et un bras témoin « Follow YAGNI. » lancé sans toucher l'installation globale **afin de** savoir si la règle de s113 fait mieux qu'une ligne avant de la garder.

- **Complexité** : 3
- **Dépend de** : s113-reuse-ladder
- **Surface** : —
- **Owns** : `evals/`, `bin/po-eval`, `tests/evals.test.sh`, `tests/reuse-ladder-eval.test.sh`

**Critères d'acceptation**
- [ ] `eval_plants_a_rebuilt_helper` — `evals/cases/` contient une recette où le diff réécrit un utilitaire déjà présent dans l'application de démonstration (`app/notes.py`), avec `CASE_EXPECT_SEVERITY=major` et `CASE_EXPECT_SHIP=yes`, sans que le dépôt construit nomme le défaut ; `tests/evals.test.sh` compte ce nouveau type.
- [ ] `eval_has_a_yagni_control_arm` — `bin/po-eval --control` lance les mêmes cas avec un reviewer dont la phrase de s113 à l'étape 3 est remplacée par la seule ligne « Follow YAGNI. », et affiche les deux taux côte à côte ; `tests/run.sh` ne lance toujours aucun appel payant.
- [ ] `control_arm_never_touches_the_global_install` — le bras témoin s'installe dans un `CLAUDE_CONFIG_DIR` temporaire, supprimé à la fin, et ne modifie jamais `~/.claude/` ; `drift_check` continue de comparer l'installation réelle à `method/`.

**Notes pour l'agent** : la mesure elle-même — au moins 3 répétitions par bras — est faite d'appels payants que lance le porteur, après la livraison : la story livre l'outil, pas les taux. Le chef de projet signale ce lancement au porteur une fois s114 livrée ; ses taux vont dans `docs/evals/reuse-ladder.md`, et si la règle ne bat pas le témoin, une story suivante la retire. Écart au cadrage d'origine voulu par la revue des stories : aucune étape du cycle ne porte une mesure faite par le porteur.

## M9 ter — Plus de CLAUDE.md, une mesure équitable

Objectif : qu'aucun projet Polype n'ait plus jamais de `CLAUDE.md`, et que l'éval de la règle de réutilisation compare deux bras qui ne diffèrent que par la phrase mesurée. Cadré le 2026-10-13 avec le porteur, qui a approuvé chaque story. Aucune gate de Law 3 ne change.

### s115-no-claude-md — Aucun CLAUDE.md dans un projet
**En tant que** porteur de projet **je veux** que Polype interdise tout `CLAUDE.md` dans un projet et absorbe celui qu'il trouve **afin que** Claude Code lise toujours `AGENTS.md`, et qu'aucun projet ne perde ses règles comme nautile a failli les perdre.

- **Complexité** : 3
- **Dépend de** : aucune
- **Surface** : —
- **Owns** : `bin/polype`, `method/AGENTS.md`, `method/hooks/po-gate.sh`, `method/hooks/po-session.sh`, `method/commands/po-setup.md`, `method/commands/po-architect.md`, `docs/installation.md`, `tests/install.test.sh`, `tests/installer.test.sh`, `tests/global-install.test.sh`, `tests/no-claude-md.test.sh`

**Critères d'acceptation**
- [ ] `installer_absorbs_claude_md` — `init`, `install` et `update` déplacent le contenu d'un `CLAUDE.md` ou d'un `CLAUDE.local.md` à la racine du projet, sans la ligne `@AGENTS.md`, à la fin de `AGENTS.local.md` sous `## Notes moved from CLAUDE.md`, suppriment le fichier et le disent dans leur rapport ; un fichier qui ne contenait que l'import est supprimé sans rien ajouter ; aucun contenu n'est perdu.
- [ ] `precommit_refuses_claude_md` — le pre-commit refuse, sur toutes les branches, un `CLAUDE.md` ou un `CLAUDE.local.md` ajouté ou modifié, à n'importe quel niveau du dépôt ; une suppression passe.
- [ ] `rules_say_no_claude_md` — `AGENTS.md` dit que le seul `CLAUDE.md` est le global de l'utilisateur, qu'aucun agent n'en crée dans un projet, et que les notes du projet vont dans `AGENTS.local.md` ; `/po-setup` et `/po-architect` le disent avec les mêmes mots.
- [ ] `session_flags_a_claude_md` — `po-session` signale un `CLAUDE.md` ou un `CLAUDE.local.md` présent à la racine du dépôt dans « Waiting for a human », avec la commande qui l'absorbe (`polype update .`).

**Notes pour l'agent** : choix retenu par le porteur le 2026-10-13, à écrire par le planner dans l'ADR-0086 `accepted`, qui remplace ADR-0073 (seuls son `status` et ses liens `superseded-by` changent) : l'installeur absorbe le fichier au lieu de ne retirer que l'import. Options écartées : s'arrêter et demander à la main (une friction à chaque projet), garder le reste du fichier (le défaut de nautile : Claude Code ne lit `AGENTS.md` que si aucun `CLAUDE.md` n'existe). Le `CLAUDE.md` global (`~/.claude/CLAUDE.md`) n'est jamais touché. `AGENTS.local.md` absent → l'installeur le crée depuis `templates/agents-local.md` avant d'y ajouter les notes, ou s'arrête si la commande ne crée jamais ce fichier : le plan le dit d'après `bin/polype`.

### s116-eval-arms-same-environment — Les deux bras de l'éval tournent dans le même environnement
**En tant que** développeur **je veux** que les deux bras de `bin/po-eval --control` tournent chacun dans une configuration temporaire installée depuis sa propre méthode, avec le même jeton et le même modèle **afin que** leurs taux ne diffèrent que par la phrase mesurée.

- **Complexité** : 2
- **Dépend de** : aucune
- **Surface** : —
- **Corrige** : majeur et mineur de `docs/reviews/s114-reuse-ladder-eval.md`
- **Owns** : `bin/po-eval`, `tests/reuse-ladder-eval.test.sh`, `tests/eval-arms-same-environment.test.sh`

**Critères d'acceptation**
- [ ] `both_arms_run_on_a_temporary_config` — avec `--control`, le bras règle comme le bras témoin s'installent dans un `CLAUDE_CONFIG_DIR` temporaire depuis leur propre copie de la méthode, et aucun ne lit `~/.claude/` ; les deux dossiers sont supprimés à la sortie.
- [ ] `control_needs_a_model` — `--control` sans `--model` est refusé avant tout appel, et la sortie rappelle le modèle et l'environnement communs aux deux bras.
- [ ] `control_is_refused_with_list_or_build` — `--control` avec `--list` ou `--build` est refusé avec un message, au lieu d'être ignoré.

**Notes pour l'agent** : le jeton reste lu dans l'environnement (`ANTHROPIC_API_KEY` ou `CLAUDE_CODE_OAUTH_TOKEN`), jamais copié depuis `.credentials.json` ; le porteur utilise son abonnement Max par `claude setup-token`. `drift_check` continue de comparer l'installation réelle à `method/`.

### s118-rebuilt-helper-single-defect — La recette rebuilt-helper ne plante qu'un seul défaut
**En tant que** développeur **je veux** que la recette `rebuilt-helper` recopie du code juste **afin que** son score mesure seulement si le reviewer relève un utilitaire reconstruit, et non une faille d'isolation héritée par accident.

- **Complexité** : 2
- **Dépend de** : aucune
- **Surface** : —
- **Corrige** : la section « Un défaut de la recette » de `docs/evals/reuse-ladder.md`
- **Owns** : `evals/cases/rebuilt-helper.sh`, `evals/lib.sh`, `tests/evals.test.sh`, `tests/reuse-ladder-eval.test.sh`, `tests/rebuilt-helper-single-defect.test.sh`

**Critères d'acceptation**
- [ ] `recipe_copies_correct_code` — la story et le plan du cas demandent la liste des notes archivées d'un utilisateur ; le diff planté ajoute `archived_for()`, qui recopie ligne à ligne le filtre de `list_for()` (propriétaire **et** tenant) au lieu de l'appeler, avec ses tests nominal et de refus ; `CASE_EXPECT_SEVERITY=major` et `CASE_EXPECT_SHIP=yes` restent.
- [ ] `demo_app_unchanged` — `get()`, `list_for()`, l'histoire et le plan de l'archivage, et les sept autres cas, dont `missing-tenant-filter`, ne changent pas.
- [ ] `recipe_names_no_flaw` — le dépôt construit ne nomme toujours pas le défaut, selon la règle de `tests/evals.test.sh`.

**Notes pour l'agent** : choix du porteur le 2026-10-13. Options écartées : corriger `get()` (casse `missing-tenant-filter`) ; dire dans la story que les ids impliquent le tenant (un reviewer le relèverait quand même). Après la livraison, le chef de projet relance `bin/po-eval --control --model claude-opus-5-5 --repeat 3 rebuilt-helper` et met `docs/evals/reuse-ladder.md` à jour ; ces appels ne font pas partie de la story.

### s119-rebuilt-helper-tests-tenant — La recette rebuilt-helper teste la frontière de tenant
**En tant que** développeur **je veux** que la plantation de `rebuilt-helper` teste la condition de tenant de `archived_for()` **afin que** son score attendu ne mesure plus que la copie, et non un test manquant.

- **Complexité** : 1
- **Dépend de** : aucune
- **Surface** : —
- **Corrige** : la section « Seconde mesure, après s118 » de `docs/evals/reuse-ladder.md`
- **Owns** : `evals/cases/rebuilt-helper.sh`, `tests/rebuilt-helper-single-defect.test.sh`, `tests/reuse-ladder-eval.test.sh`

**Critères d'acceptation**
- [ ] `plant_tests_the_tenant_boundary` — la plantation ajoute un test où une note archivée appartient à un utilisateur du même id mais d'un autre tenant, et vérifie qu'elle n'apparaît pas dans `archived_for()` ; retirer la condition de tenant de `archived_for()` dans le dépôt construit fait échouer ce test.
- [ ] `copy_stays_the_only_defect` — `archived_for()` recopie toujours le filtre de `list_for()` sans l'appeler, `CASE_EXPECT_SEVERITY=major` et `CASE_EXPECT_SHIP=yes` restent, et le dépôt construit ne nomme toujours pas le défaut.

**Notes pour l'agent** : approuvée par le porteur le 2026-10-13 (« go »). Après la livraison, le chef de projet relance `bin/po-eval --control --model claude-opus-5-5 --repeat 3 rebuilt-helper` et met `docs/evals/reuse-ladder.md` à jour ; ces appels ne font pas partie de la story. Le revieweur de s118 a jugé que `test_demo_app_unchanged` figeait trop de fichiers : cette story peut le garder tel quel, tant qu'il reste vert.

## M9 quater — Les finitions

Objectif : fermer la dernière dette connue de Polype : le majeur de s110, les trous de contrôle vus en usage réel le 2026-10-13, et les incohérences de texte et de tests laissées en mineur par les revues de M9 bis et M9 ter. Cadré le 2026-10-14 avec le porteur (« On finit à 100 % »). Aucune gate de Law 3 ne s'assouplit ; `Ship allowed` devient plus strict.

### s120-session-and-gate-checks — Le hook et la gate voient ce qui manquait
**En tant que** porteur de projet **je veux** que la gate refuse une revue sans `Review status:` et que le hook de session signale un plan en attente de choix technique sans pousser un design system inutile **afin que** ce que j'ai dû surveiller à la main le 2026-10-13 le soit par l'outil.

- **Complexité** : 2
- **Dépend de** : aucune
- **Surface** : —
- **Corrige** : la ligne `Review status:` omise trois fois en M9 bis sans que `po-gate` le voie ; le mineur de `docs/reviews/s104-escalation-contract.md` sur `po-session` et le marqueur ; « Framing next: /po-design-system » affiché pour nautile, qui n'a pas d'écran
- **Owns** : `method/hooks/po-gate.sh`, `method/hooks/po-session.sh`, `method/AGENTS.md`, `method/commands/po-ship.md`, `tests/session-and-gate-checks.test.sh`, `tests/gate.test.sh`, `tests/project-lead.test.sh`, `tests/review-tree-gate.test.sh`

**Critères d'acceptation**
- [ ] `ship_gate_needs_review_status` — `po-gate ship-allowed <id>` refuse une revue dont la dernière ligne `Review status:` manque ou ne dit pas `complete`, avec un message qui nomme la ligne ; une revue complète au `Ship allowed: yes` et au `Reviewed tree:` à jour passe comme avant.
- [ ] `session_flags_a_technical_choice` — `po-session` liste dans « Waiting for a human » chaque lane dont le plan porte la ligne `Technical choice: waiting for a human`, avec `/po-plan <id>`.
- [ ] `design_system_only_with_a_screen` — `po-session` ne propose `/po-design-system` comme prochaine étape de cadrage que si au moins une story a un écran, au sens de `AGENTS.md` (Law 1) ; sinon le design system manquant n'est pas une étape, et la ligne de cadrage le dit (`design system not needed`).

### s121-framing-realign-and-orchestrator-log — Le cadrage réaligne la racine, le journal de l'orchestrateur est complet
**En tant que** porteur de projet **je veux** que tout atterrissage de cadrage réaligne d'abord la racine sur `origin/<Target branch>`, et que `/po-orchestrator` consigne toutes ses décisions prises seul **afin que** la méthode tienne ce qu'elle promet.

- **Complexité** : 2
- **Dépend de** : aucune
- **Surface** : —
- **Corrige** : majeur de `docs/reviews/s110-framing-second-landing.md` ; mineurs de `docs/reviews/s109-drive-guards.md`
- **Owns** : `method/commands/po-setup.md`, `method/commands/po-orchestrator.md`, `tests/framing-realign-and-orchestrator-log.test.sh`, `tests/framing-second-landing.test.sh`, `tests/drive-guards.test.sh`

**Critères d'acceptation**
- [ ] `every_landing_realigns_the_root` — dans `## Landing the framing`, chaque atterrissage commence, après le `git fetch`, par `git merge --ff-only origin/<Target branch>` dans la racine quand c'est une avance rapide, quel que soit le slug ; un refus est rapporté et rien n'est forcé ; la phrase du point `human` ne promet plus que ce que fait la commande.
- [ ] `orchestrator_logs_every_lone_decision` — `## The decisions log` de `/po-orchestrator` consigne aussi la voie qu'il choisit, chaque détail d'implémentation tranché et chaque réponse donnée sans demander ; une exécution qui finit sur « Pull request ready » écrit ses lignes à ce moment-là, et sous `Merge mode: local` un « Not now » laisse le journal indexé à la racine, comme le dit `/po-drive`.

### s122-docs-and-eval-cleanup — Les docs et l'éval disent juste
**En tant que** développeur **je veux** que la documentation d'installation, les messages de `po-eval`, la recette `rebuilt-helper` et `/po-status` disent exactement ce que fait Polype **afin qu'**aucun texte ne contredise la méthode.

- **Complexité** : 2
- **Dépend de** : aucune
- **Surface** : —
- **Corrige** : mineurs de `docs/reviews/s115-no-claude-md.md`, `docs/reviews/s116-eval-arms-same-environment.md`, `docs/reviews/s118-rebuilt-helper-single-defect.md`, `docs/reviews/s119-rebuilt-helper-tests-tenant.md`, `docs/reviews/s112-short-subject-shipped.md`
- **Owns** : `docs/installation.md`, `bin/po-eval`, `evals/cases/rebuilt-helper.sh`, `method/commands/po-status.md`, `method/commands/po-drive.md`, `method/AGENTS.md`, `method/hooks/po-gate.sh`, `tests/resume.test.sh`, `tests/rebuilt-helper-single-defect.test.sh`, `tests/install.test.sh`, `tests/docs-and-eval-cleanup.test.sh`

**Critères d'acceptation**
- [ ] `installation_cites_adr_0086` — `docs/installation.md` cite ADR-0086 et non plus ADR-0073, et dit qu'un `CLAUDE.local.md`, même privé, est déplacé dans `AGENTS.local.md`, qui est commité (décision du porteur du 2026-10-14) ; le test `install_writes_no_claude_md` porte un nom et un message qui disent ce qu'il vérifie.
- [ ] `drift_message_fits_the_mode` — sous `--control`, le refus de `drift_check` dit qu'il garde l'installation réelle, et non qu'une copie masquerait la méthode mesurée.
- [ ] `recipe_plan_counts_three_tests` — le plan construit de `rebuilt-helper` dit « The three tests » dans « Done when », et `test_demo_app_unchanged` ne fige plus que `get()`, `list_for()` et la recette `missing-tenant-filter`, sans compte de recettes.
- [ ] `status_shipped_rule_reads_once` — la règle « livrée » de `/po-status` ne dit plus deux fois « shipped » ; la phrase partagée avec `/po-drive` reste mot pour mot.
- [ ] `status_design_system_matches_session` — la ligne de cadrage de `/po-status` dit `design system not needed` dans le même cas que `po-session` (des stories, toutes avec une ligne `Surface`, aucune `screen`), et ne propose alors pas `/po-design-system`.
- [ ] `drive_resumes_a_review_the_gate_refuses` — dans `## Resuming` de `/po-drive`, la ligne qui renvoie à la revue couvre toute revue au dernier `Ship allowed: yes` que `po-gate ship-allowed <id>` refuse, quelle qu'en soit la raison (`Reviewed tree:` périmé ou `Review status:` absent ou pas `complete`) ; le texte de `## Ships, one at a time` cite aussi le statut ; une lane dont la revue n'a pas de `Review status:` ne retombe plus en boucle sur le ship (majeur de `docs/reviews/s120-session-and-gate-checks.md`).
- [ ] `law3_row_states_both_status_checks` — la ligne « Ship allowed » de la Loi 3 dans `method/AGENTS.md` dit les deux conditions que `po-gate` vérifie (le statut du bloc du dernier verdict et la dernière ligne `Review status:` du fichier), et le commentaire de `po-gate.sh` sur le hash est placé au-dessus de la fonction qui l'applique (mineurs de la même revue).

### s123-local-copy-checksums — Les copies de .claude/ se comparent à ce que le checkout a installé
**En tant que** porteur de projet **je veux** que les sommes de contrôle des copies installées sous `.claude/` vivent à côté d'elles, hors de git **afin qu'**une mise à jour livrée par une PR ne fasse plus passer les copies de chaque checkout pour des retouches.

- **Complexité** : 3
- **Dépend de** : aucune
- **Surface** : —
- **Corrige** : à chaque mise à jour du 2026-10-14, `polype update` laissait 5 à 23 copies de `.claude/` « modifiées » dans Polype, pecten et nautile, parce que `.polype/checksums`, commité, décrivait déjà la nouvelle version alors que `.claude/` est ignoré par git
- **Owns** : `bin/polype`, `docs/installation.md`, `tests/install.test.sh`, `tests/installer.test.sh`, `tests/global-install.test.sh`, `tests/local-copy-checksums.test.sh`

**Critères d'acceptation**
- [ ] `local_copies_have_local_sums` — `init`, `install <projet>` et `update` écrivent les sommes des copies installées sous `.claude/` dans un fichier à côté d'elles (`.claude/.polype-checksums`), jamais commité ; `.polype/checksums` ne garde que les fichiers que git suit (`.polype/`, `AGENTS.md`).
- [ ] `update_after_a_pr_refresh_replaces_stale_copies` — sur un dépôt jetable dont `.polype/` et `AGENTS.md` ont été mis à jour par un commit venu d'ailleurs, `polype update` remplace les copies de `.claude/` restées à l'ancienne version sans les dire modifiées ; une copie retouchée à la main reste, elle, laissée en place et signalée.
- [ ] `local_sums_file_stays_out_of_git` — l'installeur s'assure que `.claude/.polype-checksums` est ignoré par git (il ajoute la ligne au `.gitignore` du projet quand git ne l'ignore pas déjà), et `polype check` lit les deux fichiers.
- [ ] `first_update_migrates` — un projet installé avant cette story, sans fichier local, est migré au premier `update` : les copies qui correspondent à `.polype/checksums` comptent comme intactes, le fichier local est écrit, et l'installeur le dit.

**Notes pour l'agent** : option A, choisie par le porteur le 2026-10-14 ; option écartée : reconnaître toute version déjà publiée de la méthode (plus lourd, demande l'historique). La pose globale (`~/.claude/`) n'est pas concernée, puisqu'elle n'est pas dans un dépôt. `docs/installation.md` décrit le nouveau fichier.

## M9 quinquies — La dette à zéro

Objectif : fermer les 42 constats de revue encore vrais sur `main` au 2026-10-14. Le tri des 147 constats laissés par les revues de s66 à s123 est dans `docs/reviews/triage-2026-10-14.md`, avec pour chacun le fichier et la ligne qui le montrent. Cadré le 2026-10-14 avec le porteur (« on finit à 100 % »). Aucune gate de Law 3 ne change de sens.

Écartés du jalon, et dits tels dans le tri :
- les compromis déjà acceptés : `po-eval` qui compte une revue complète citant un `blocked`, l'angle mort de `scenarios.md`, `GIT_DIR` entre guillemets (ADR-0052), les refus plus fréquents du réalignement de s121 ;
- les preuves figées des stories livrées : plans et records de s83, s105, s107, s110, recherche de s113, et le corps de l'ADR-0081, acceptée ;
- les 30 s de l'enregistreur du pilote de simulation, qui ne se mesurent qu'avec ROS ;
- le `source <(sed …)` inoffensif de `tests/review-tree-gate.test.sh`.

Chaque story ferme, dans les fichiers qu'elle possède, toutes les lignes `HOLDS` du tri qui y pointent. Un critère est tenu quand le constat ne se reproduit plus sur le code livré et que, pour un constat de test qui ne mordait pas, retirer la règle fait échouer un test.

### s124-framing-commands-cleanup — Les commandes de cadrage disent juste
**En tant que** porteur de projet **je veux** que les commandes de cadrage ne se contredisent plus et que leurs règles soient tenues par des tests **afin que** le cadrage d'un nouveau projet suive un seul chemin clair.

- **Complexité** : 2
- **Dépend de** : aucune
- **Surface** : —
- **Corrige** : les lignes `HOLDS` du tri qui pointent vers les fichiers de son `Owns` (s101, s102, s106, s110, s115)
- **Owns** : `method/commands/po-stories.md`, `method/commands/po-stories-review.md`, `method/templates/prd.md`, `method/commands/po-setup.md`, `method/commands/po-architect.md`, `tests/framing-second-landing.test.sh`, `tests/conversational-framing.test.sh`, `tests/framing-through-pr.test.sh`, `tests/framing-commands-cleanup.test.sh`

**Critères d'acceptation**
- [ ] `stories_paths_agree` — le chemin de correction de `/po-stories` annonce `/po-stories-review` comme étape suivante, une story écartée relance « Before writing » sur les autres, et un résultat bloqué de `/po-stories-review` ne correspond plus qu'à une seule sortie ; `templates/prd.md` ne demande plus de relire tout le document.
- [ ] `setup_landing_holds` — `/po-setup` lit la forge une fois `Target branch` connue, dit ce qui se passe quand `git merge --ff-only framing/<slug>` est refusé en mode `local`, et la règle « never commits to `Target branch` directly and never pushes it » est tenue par un test.
- [ ] `framing_wording_is_clean` — la clause « means not merged » est tenue par un test, le test d'ordre structurel de `test_root_realigns_after_a_merge` vérifie une vraie règle, la majuscule après deux-points n'existe plus pour un test, et « (ADR-0086) » est à l'intérieur de sa phrase dans `/po-setup` et `/po-architect`.

### s125-ship-and-fleet-cleanup — Le ship et la flotte disent juste
**En tant que** porteur de projet **je veux** que `/po-ship`, `/po-drive`, `/po-status` et les règles disent exactement ce qu'ils font et que leurs tests mordent **afin qu'**aucune lane ne dépende d'une phrase ambiguë.

- **Complexité** : 2
- **Dépend de** : aucune
- **Surface** : —
- **Corrige** : les lignes `HOLDS` du tri qui pointent vers les fichiers de son `Owns` (s96, s102, s104, s108, s112)
- **Owns** : `method/commands/po-ship.md`, `method/commands/po-drive.md`, `method/AGENTS.md`, `method/commands/po-status.md`, `tests/ship-through-pr.test.sh`, `tests/ship-follows-forge.test.sh`, `tests/short-subject-shipped.test.sh`, `tests/escalation-contract.test.sh`, `tests/defect-and-routing-paths.test.sh`, `tests/ship-and-fleet-cleanup.test.sh`

**Critères d'acceptation**
- [ ] `ship_text_is_complete` — `/po-ship` dit ce qui se passe quand `origin/story/<id>` n'existe pas encore et vérifie aussi le message `<id>: <story title>` du commit repris ; un test tient Step 2 sur la valeur effective de `Ship confirmation` ; le critère `push_targets_only_the_story_ref` a un test de son nom.
- [ ] `fleet_rules_agree` — l'ordre des ships (ordre des revues, ordre des merges humains) se lit sans contradiction dans `/po-drive` et `method/AGENTS.md` ; `Root cause: not found` est une ligne entière (`grep -x`, ADR-0070) dans `/po-drive` ; `/po-status` montre un plan qui attend un choix technique.
- [ ] `fleet_tests_bite` — les tests de `escalation-contract`, `short-subject-shipped` et `defect-and-routing-paths` que le tri dit creux échouent quand on retire leur règle.

### s126-plan-and-defect-paths-cleanup — Le plan et les chemins de défaut disent juste
**En tant que** porteur de projet **je veux** que le plan, le planner, la recherche et l'orchestrateur décrivent les mêmes arrêts avec les mêmes mots, tenus par des tests **afin qu'**un défaut sans cause trouvée ou un choix technique arrête toujours la lane.

- **Complexité** : 2
- **Dépend de** : aucune
- **Surface** : —
- **Corrige** : les lignes `HOLDS` du tri qui pointent vers les fichiers de son `Owns` (s90, s96, s104, s111)
- **Owns** : `method/commands/po-plan.md`, `method/commands/po-flow.md`, `method/agents/planner.md`, `method/commands/po-research.md`, `method/commands/po-orchestrator.md`, `method/templates/plan-flow.md`, `tests/tech-choice-backstop.test.sh`, `tests/diagnostic-skill.test.sh`, `tests/plan-and-defect-paths-cleanup.test.sh`

**Critères d'acceptation**
- [ ] `defect_stops_agree` — `/po-research` et `/po-orchestrator` placent `Root cause: not found` là où le skill `diagnostic` le met, `/po-plan` et le planner le lisent comme une ligne entière, et les trois arrêts que le tri dit non testés échouent quand on les retire.
- [ ] `tech_choice_paths_agree` — `templates/plan-flow.md` ne dit plus qu'un plan court avec un signal ne doit pas exister, le repli « No number there » du planner répète la ligne d'attente, et la consigne « name that ADR in the plan » de `/po-flow` est tenue par un test.
- [ ] `plan_tests_bite` — la garde de mutation de `tech-choice-backstop` et la clause `Fixes` du planner sont tenues par des tests qui échouent quand on retire la règle.

### s127-hooks-installer-docs-cleanup — Les hooks, l'installeur et la documentation disent juste
**En tant que** porteur de projet **je veux** que les hooks, l'installeur et la documentation ne gardent aucune trace d'un ancien fonctionnement **afin que** ce qui est écrit soit ce qui tourne.

- **Complexité** : 3
- **Dépend de** : s124-framing-commands-cleanup
- **Surface** : —
- **Corrige** : les lignes `HOLDS` du tri qui pointent vers les fichiers de son `Owns` (s68, s73, s92, s94, s99, s100, s103, s105, s106, s123)
- **Owns** : `method/hooks/po-gate.sh`, `method/hooks/po-bounds.sh`, `method/templates/review.md`, `method/commands/po-setup.md`, `method/templates/brief.md`, `bin/polype`, `docs/installation.md`, `README.md`, `docs/decisions/ADR-0080-tout-arrive-sur-la-branche-cible-par-une-pr-en-fast-forward.md`, `method/skills/qa-drivers/scene.md`, `boilerplates/godot/profile.md`, `method/skills/testing-doctrine/SKILL.md`, `docs/parite-killer-saas.md`, `tests/distribution-wiring.test.sh`, `tests/throwaway-zone-holds.test.sh`, `tests/qa-evidence-set-aside.test.sh`, `tests/hooks-installer-docs-cleanup.test.sh`

**Critères d'acceptation**
- [ ] `hooks_say_what_they_do` — le commentaire de `po-gate` ne parle plus de squash, le scan de secrets du cadrage compare au `<base>` du commit construit (`po-gate.sh` et l'appel de `/po-setup`), `templates/review.md` met en garde contre une puce de constat qui commence par `Ship allowed:`, la borne du bloc de verdict restant celle de l'ADR-0056 ; le refus `core.worktree` de `po-bounds` dit « in a throwaway repo » et un test le tient.
- [ ] `installer_and_docs_agree` — `remove` sans `jq` retire aussi l'entrée `SessionStart` ou le dit ; `docs/installation.md` cite `.claude/settings.json`, explique le passage de `Merge mode: local` à `pr` pour un projet qui a un remote, et respecte la largeur de ligne du fichier ; `README.md` ne parle plus de squash ; `templates/brief.md` ne demande plus de relire tout le brief, comme `templates/prd.md` après s124 ; l'ADR-0080 porte `superseded-by` vers l'ADR-0081 (frontmatter seul).
- [ ] `drivers_and_doctrine_read_right` — `scene.md` nomme la clé `application/run/main_scene`, le profil Godot ne fige plus `1920x1080` sans dire que c'est un défaut, la phrase de `testing-doctrine` sur `po-run` se lit d'un trait, la cellule H04 de la parité dit sa limite d'emblée et son test tient les trois fichiers cités, et la borne de 30 s de `/po-qa` est tenue par un test.

## M10 — Les artefacts reliés

Objectif : que chaque artefact d'une story porte des liens Markdown vers sa story et vers l'artefact qui le précède, pour naviguer de l'un à l'autre sur GitHub comme dans le vault Obsidian (`~/dev`), où ces fichiers sont aujourd'hui isolés dans le graphe. Proposé en brouillon le 2026-10-14 par un autre agent (`~/dev/atoll/brouillons/polype-s128-artefacts-relies.md`), découpé en deux et intégré après M9 quinquies avec l'accord du porteur. Le porteur accepte, pour ce seul ajout, de retoucher les artefacts des stories déjà livrées : une ligne de navigation ne change rien à ce qu'ils prouvent. Aucune gate de Law 3 ne change.

Les deux stories retouchent la preuve de toutes les stories : elles tournent seules, une fois M9 quinquies livré et sans autre lane en cours. Le rattrapage des artefacts de nautile et pecten est une story de chacun de ces projets, après la réinstallation de Polype.

### s128-artifact-link-templates — Les gabarits d'artefact portent leurs liens
**En tant que** porteur de projet **je veux** que chaque gabarit d'artefact de story porte une ligne de liens vers sa story et vers l'artefact qui le précède **afin que** tout nouvel artefact se relie dès sa création.

- **Complexité** : 2
- **Dépend de** : s127-hooks-installer-docs-cleanup
- **Surface** : —
- **Owns** : `method/templates/research.md`, `method/templates/plan.md`, `method/templates/plan-flow.md`, `method/templates/review.md`, `method/templates/verification-record.md`, `method/templates/qa.md`, `tests/artifact-link-templates.test.sh`

**Critères d'acceptation**
- [ ] `templates_carry_links` — sous le titre de chaque gabarit, et après le frontmatter quand il y en a un, une ligne de liens Markdown relatifs : la story (`../stories.md`) toujours, puis l'artefact précédent quand il existe sur ce track (research ← plan ; plan ou plan-flow ← review, verif, QA ; verif ← review). Pas de wikilinks, pour que le lien marche sur GitHub ; pas d'ancre vers un titre, sauf si un test la vérifie.
- [ ] `gates_still_read_artifacts` — `po-gate`, `po-run`, `/po-review`, `/po-ship` et `/po-status` donnent le même résultat sur un artefact avec et sans la ligne, et un test le tient ; `templates/verification-record.md` dit que la ligne fait partie du gabarit, et non d'une édition de l'implementer.
- [ ] `links_resolve` — un test échoue si un lien de la ligne, dans un gabarit rendu pour une story jetable, pointe vers un fichier absent.

**Notes pour l'agent** : commencer par lister qui lit ces fichiers par position (première ligne, numéro de ligne, frontmatter) plutôt que par motif : la ligne ajoutée ne doit décaler aucune lecture. Le reviewer rend sa revue dans la forme de `templates/review.md`, et le chef de projet la recopie telle quelle : la ligne de liens fait partie de cette forme.

### s129-artifact-links-backfill — Les artefacts déjà écrits se relient
**En tant que** porteur de projet **je veux** que les artefacts déjà présents dans le dépôt reçoivent la même ligne de liens **afin que** les anciennes stories se relient comme les nouvelles.

- **Complexité** : 2
- **Dépend de** : s128-artifact-link-templates
- **Surface** : —
- **Owns** : `docs/research/`, `docs/plans/`, `docs/reviews/`, `docs/verif/`, `docs/qa/`, `bin/po-link-artifacts`, `tests/artifact-links-backfill.test.sh`

**Critères d'acceptation**
- [ ] `backfill_is_a_script` — `bin/po-link-artifacts` ajoute à chaque artefact de story la ligne de s128, seulement vers des fichiers qui existent, et ne change rien d'autre dans ces fichiers ; relancé, il ne change plus rien.
- [ ] `existing_artifacts_backfilled` — tous les artefacts de story de `docs/research/`, `docs/plans/`, `docs/reviews/`, `docs/verif/` et `docs/qa/` portent la ligne ; les fichiers qui ne sont pas des artefacts d'une story (`docs/reviews/stories*.md`, `docs/reviews/triage-*.md`) ne sont pas touchés.
- [ ] `links_resolve_everywhere` — un test échoue si un lien de la ligne, dans un artefact existant, pointe vers un fichier absent, et `po-gate` donne le même résultat qu'avant sur les artefacts des stories en cours, s'il y en a.

## M11 — Polype s'installe chez quelqu'un d'autre

Objectif : qu'une personne qui a déjà sa configuration Claude Code (agents, skills, `AGENTS.md`, `CLAUDE.md`) installe Polype sans rien perdre ni rien voir écrasé en silence, et qu'elle trouve dans le README tout ce qu'il faut pour l'installer et s'en servir. Cadré le 2026-10-14 avec le porteur, après la question d'un premier testeur extérieur : « possible de charger du contexte custom ? ». Constats sur `main` à cette date : une première pose remplace sans prévenir un fichier du même nom (`lay_down`, `bin/polype:157`) ; un `AGENTS.md` écrit à la main est mis de côté dans `AGENTS.md.before-polype` et n'est plus lu ; la règle « pas de CLAUDE.md » (ADR-0086), choix du porteur, s'impose à tout projet ; l'installeur demande bash 4.2 (`declare -gA`, `bin/polype:359`) sans le dire, comme `po-session` (`declare -A`), alors que macOS livre bash 3.2 ; le README ne dit ni les prérequis, ni comment récupérer Polype (dépôt public `atoll-labs-io/polype`), ni par où commencer. Décision du porteur : la règle « pas de CLAUDE.md » reste le défaut, et devient un réglage qu'un projet peut changer.

Les quatre stories touchent l'installeur, ses hooks ou sa documentation : elles passent l'une après l'autre.

### s130-install-refuses-collisions — L'installeur n'écrase rien qu'il n'a pas posé
**En tant que** personne qui a déjà sa configuration Claude Code **je veux** que l'installeur refuse de remplacer un fichier qu'il n'a pas posé, et que mon `AGENTS.md` rejoigne mes réglages **afin qu'**installer Polype ne me fasse rien perdre.

- **Complexité** : 3
- **Dépend de** : aucune
- **Surface** : command
- **Owns** : `bin/polype`, `method/AGENTS.md`, `method/commands/po-setup.md`, `docs/decisions/ADR-0088-*`, `tests/install.test.sh`, `tests/installer.test.sh`, `tests/global-install.test.sh`, `tests/local-copy-checksums.test.sh`, `tests/install-collisions.test.sh`

**Critères d'acceptation**
- [ ] `collision_stops_before_writing` — `install`, `init` et `update`, en pose globale comme en pose projet, s'arrêtent en code 1 sans rien écrire ni rien supprimer (les fantômes compris) quand une destination existe déjà, n'est pas dans le manifeste et diffère du fichier livré ; la sortie liste chaque chemin en cause et l'option qui les met de côté. Un fichier identique au fichier livré est repris sans bruit, sauf un lien symbolique, qui compte comme une collision pour que le lien de la personne survive (ADR-0088). `AGENTS.md` n'est pas une collision : il suit le critère `hand_written_agents_md_is_absorbed`.
- [ ] `set_aside_is_explicit_and_undone` — avec `--set-aside`, chaque fichier en collision est déplacé en `<chemin>.before-polype`, la pose continue et le dit ; `remove`, global comme projet, remet chacun à sa place avant de retirer son état.
- [ ] `hand_written_agents_md_is_absorbed` — un `AGENTS.md` écrit à la main est ajouté à `AGENTS.local.md` sous `## Notes moved from AGENTS.md`, avant que l'`AGENTS.md` assemblé le remplace ; sans `AGENTS.local.md`, il reste mis de côté en `AGENTS.md.before-polype`, l'installeur le dit, et le premier `update` qui trouve `AGENTS.local.md` l'absorbe alors et supprime la copie mise de côté. Relancer `update` ne change plus rien. Les phrases qui disent que l'installeur n'écrit dans `AGENTS.local.md` que pour un `CLAUDE.md` (`method/AGENTS.md`, `/po-setup`, l'en-tête de `bin/polype`) nomment aussi `AGENTS.md`.
- [ ] `adr_records_the_contract` — une ADR nouvelle dit ce changement du contrat de l'installeur (s'arrêter sur une collision, absorber un `AGENTS.md`) et les options écartées, en face de l'option B écartée par l'ADR-0086 pour un `CLAUDE.md`.

**Notes pour l'agent** : le manifeste et les sommes de contrôle disent déjà ce que Polype a posé (ADR-0087) ; une collision est ce qu'ils ne connaissent pas. Un projet déjà installé ne voit aucune collision à son `update` : ses fichiers sont dans son manifeste. Comparer par `cksum`, comme `sum_of`, et non par `cmp` ou `diff` : `tests/hooks-installer-docs-cleanup.test.sh` lance `remove` avec un `PATH` réduit. La pose globale garde la liste des fichiers mis de côté hors de `$state_dir`, ou la lit avant son `rm -rf`. Le risque de la story est de perdre un fichier de `~/.claude/` : chaque chemin du critère `set_aside_is_explicit_and_undone` a son test aller-retour.

### s131-claude-md-rule-as-setting — La règle « pas de CLAUDE.md » se règle par projet
**En tant que** porteur d'un projet qui tient à son `CLAUDE.md` **je veux** pouvoir le garder par un réglage, la règle actuelle restant le défaut **afin d'**adopter Polype sans changer ma façon de donner du contexte à Claude.

- **Complexité** : 3
- **Dépend de** : s130-install-refuses-collisions
- **Surface** : command
- **Owns** : `bin/polype`, `method/hooks/po-gate.sh`, `method/hooks/po-session.sh`, `method/templates/agents-local.md`, `method/commands/po-setup.md`, `method/commands/po-architect.md`, `method/AGENTS.md`, `AGENTS.local.md`, `docs/decisions/ADR-0089-*`, `docs/decisions/ADR-0086-l-installeur-absorbe-le-claude-md-dans-agents-local-md.md`, `tests/no-claude-md.test.sh`, `tests/framing-commands-cleanup.test.sh`, `tests/install.test.sh`, `tests/installer.test.sh`, `tests/claude-md-setting.test.sh`

**Critères d'acceptation**
- [ ] `setting_has_two_values` — `templates/agents-local.md` porte `Project CLAUDE file: absorbed`, avec ses deux valeurs décrites : `absorbed`, la règle de l'ADR-0086, et `kept` ; `/po-setup` pose la question et écrit le réglage ; le `AGENTS.local.md` de Polype porte `absorbed` ; chaque commande ou hook qui lit le réglage le nomme dans son `Reads settings:` quand il en a un.
- [ ] `kept_keeps_and_imports` — avec `kept`, l'installeur ne déplace aucun `CLAUDE.md` ni `CLAUDE.local.md`, et dès que l'un des deux existe, il s'assure que le `CLAUDE.md` racine existe et commence par la ligne `@AGENTS.md` (il le crée avec cette seule ligne quand seul un `CLAUDE.local.md` existe), pour que les règles soient toujours lues ; le pre-commit n'en refuse plus ; `po-session` ne les signale plus ; `remove` retire cette seule ligne, et le fichier s'il ne tenait qu'elle.
- [ ] `missing_setting_changes_nothing` — sans la ligne, l'installeur ne touche à aucun `CLAUDE.md`, le pre-commit refuse comme aujourd'hui, et `check`, l'installeur et `po-session` nomment le réglage manquant au lieu d'annoncer que `polype update` déplacera le fichier : rien n'est choisi à la place du projet. Un projet déjà installé qui n'a pas la ligne cesse donc d'absorber à son `update` tant qu'il ne l'a pas écrite ; l'ADR le dit.
- [ ] `adr_records_the_choice` — une ADR nouvelle dit le choix, les options écartées et ce que devient un projet déjà installé ; l'ADR-0086 n'est touchée que dans son frontmatter (`superseded-by`) ; la phrase de `method/AGENTS.md` sur le seul `CLAUDE.md`, et « Never commit a `CLAUDE.md` » dans `/po-setup` et `/po-architect`, disent le réglage.

### s132-readme-onboarding — Le README suffit pour installer Polype et s'en servir
**En tant que** personne qui découvre Polype **je veux** que le README me dise ce qu'il faut, comment l'installer, par où commencer et ce qu'il fait de ma configuration, et qu'un bash trop vieux me le dise clairement **afin de** l'essayer seule, sans risque.

- **Complexité** : 3
- **Dépend de** : s131-claude-md-rule-as-setting
- **Surface** : command
- **Owns** : `README.md`, `docs/installation.md`, `bin/polype`, `method/hooks/po-session.sh`, `tests/readme-onboarding.test.sh`

**Critères d'acceptation**
- [ ] `old_bash_is_named` — sous un bash plus ancien que 4.2, `bin/polype` s'arrête avant toute écriture, et `po-session` sort sans erreur, chacun avec un message qui nomme la version trouvée et celle qu'il faut, au lieu d'une erreur de `declare`.
- [ ] `prerequisites_are_listed` — le README liste Claude Code, git, bash 4.2 ou plus (avec la marche à suivre sous macOS), `jq` et ce qu'il permet, et `gh` pour une forge GitHub.
- [ ] `quickstart_runs_as_written` — le README donne, dans l'ordre, la récupération du dépôt public, la pose globale, le lien sur le `PATH`, l'activation d'un projet, puis les premières commandes Claude Code (`/po-setup`, le cadrage, `/po-drive`) et la mise à jour. Les commandes shell sont dans un bloc `sh` à elles, les commandes Claude Code à part ; un test exécute ce bloc tel qu'écrit, dans un `HOME` et un projet jetables, l'adresse du clone remplacée par le dépôt local, et finit sur un `polype check` sans dérive.
- [ ] `existing_config_is_explained` — une section dit ce que Polype fait d'agents ou de skills du même nom (`--set-aside`), d'un `AGENTS.md`, d'un `CLAUDE.md` (avec le réglage de s131), l'ordre de grandeur, en Ko, des règles assemblées dans `AGENTS.md` et chargées à chaque session (le test le recalcule et tolère ±25 %, pour qu'une retouche des règles ne le casse pas), et conseille un premier essai dans un clone jetable avec `polype install <clone>`.
- [ ] `install_doc_tells_the_truth` — `docs/installation.md` décrit les collisions et `--set-aside`, l'absorption d'un `AGENTS.md` et le réglage `Project CLAUDE file` ; il ne dit plus que l'installeur ne touche jamais aux fichiers qu'on a ajoutés soi-même, ni qu'il absorbe tout `CLAUDE.md` sans condition.

**Notes pour l'agent** : il n'y a pas de bash 3 sur cette machine, et `BASH_VERSINFO` est en lecture seule ; le test atteint la garde par un contrôle statique (elle précède toute construction de bash 4) et en lançant la garde, extraite, avec une version simulée, sans couture ajoutée au code livré pour le seul test. Le comportement sous macOS au-delà de bash (`find`, `sed`, `readlink` BSD) n'est pas promis ; le README le dit. Deux tests que la story ne possède pas lisent `docs/installation.md` : `tests/docs-and-eval-cleanup.test.sh` y tient la phrase « ceux qu'il trouve (ADR-0086) », à garder en y ajoutant la condition du réglage, et `tests/hooks-installer-docs-cleanup.test.sh` y refuse les lignes de prose de plus de 100 caractères.

### s133-any-harness-docs — Polype se présente pour tout harness, Claude Code d'abord
**En tant que** personne qui utilise un autre agent que Claude Code **je veux** que la documentation dise que Polype vise tout agent ou harness, lequel est pris en charge aujourd'hui, lequel vient ensuite, et comment demander le mien **afin de** savoir tout de suite si je peux l'utiliser, sans croire à une prise en charge qui n'existe pas.

- **Complexité** : 2
- **Dépend de** : s132-readme-onboarding
- **Surface** : command
- **Owns** : `README.md`, `docs/installation.md`, `method/commands/po-help.md`, `docs/parite-killer-saas.md`, `.github/ISSUE_TEMPLATE/`, `tests/any-harness-docs.test.sh`

**Critères d'acceptation**
- [ ] `docs_name_any_harness` — le README (accroche comprise), `docs/installation.md` et `/po-help` disent que Polype vise tout agent ou harness : pris en charge aujourd'hui, Claude Code ; prévu ensuite, Codex (ADR-0005), sans date ; pour un autre, ouvrir une issue. Un test tient ces trois affirmations dans chacun des trois fichiers, et refuse dans ces trois fichiers les formules « portée par des agents Claude Code » et « agents Claude Code encadrés », qui présentent Polype comme réservé à cet outil.
- [ ] `portable_and_specific_parts_are_named` — le README dit en quelques lignes ce qui a été conçu pour se porter vers un autre outil (les règles dans `AGENTS.md`, les skills au format `SKILL.md`, les gates en scripts shell et hooks git), sans dire que cela marche déjà ailleurs, et ce qui demande Claude Code aujourd'hui (les subagents, les hooks `PreToolUse` et `SessionStart`, `AskUserQuestion`, la pose dans `~/.claude/`). La cellule de la ligne H03 de `docs/parite-killer-saas.md` dit ce que la story en livre.
- [ ] `harness_issue_template_exists` — `.github/ISSUE_TEMPLATE/` porte un modèle « prise en charge d'un harness » (nom de l'outil, version, ce qu'il sait faire : sous-agents, hooks, lecture d'`AGENTS.md`), et le README y renvoie par un lien relatif vers un fichier qui existe.

**Notes pour l'agent** : cadrée le 2026-10-14 à la demande du porteur (« c'est pour Claude Code et tous les autres types d'agent/harness, le demander en issue si pas disponible »). Ne rien promettre au-delà de ce que le code fait : le portage Codex lui-même est hors de cette story, et la date de l'ADR-0005 (« vers mi-octobre 2026 ») n'est pas reprise. Les issues sont ouvertes sur `atoll-labs-io/polype` (vérifié le 2026-10-14) et le dépôt n'a pas encore de `.github/`. `Issue tracker: —` porte sur les défauts (Law 7), pas sur ces demandes. Les phrases de `docs/installation.md` qui décrivent un comportement de Claude Code (lecture d'`AGENTS.md` et de `CLAUDE.md`, `CLAUDE_CONFIG_DIR`, dialogue de confiance) restent : elles sont justes et propres à cet outil. `method/AGENTS.md` et `docs/conception.md` ne sont pas touchés. Les tests qui citent mot pour mot le README, `docs/installation.md` ou `/po-help` (voir la recherche de s132, et les tests des stories qui ont possédé `po-help.md`) gardent leurs phrases ; lignes de prose de `docs/installation.md` sous 100 caractères.

## M12 — Tout ce qui est à traiter devient une issue

Objectif : qu'aucune idée de modification, de fonctionnalité ou de défaut à traiter ne reste seulement dans une conversation, un journal de décisions, une revue ou une mémoire, mais devienne une issue du projet, sur Polype comme sur tout projet qui l'utilise. Décidé par le porteur le 2026-10-14 (« Si une idée de modification, de feature ou de bug est à traiter, il faut le mettre en issue du projet »), après avoir constaté que le portage Codex et les fonctionnalités prévues n'avaient aucune issue. Constat sur `main` à cette date : la Law 7 envoie un défaut vers `Issue tracker` mais dit que « only a person turns one into an issue or a story », et aucune commande ne lit ce réglage ; les constats mineurs acceptés au ship ne sont tracés que dans les revues et le journal.

### s134-everything-to-handle-is-an-issue — Polype dépose une issue pour tout ce qui est à traiter
**En tant que** porteur de projet **je veux** que le chef de projet et la flotte déposent une issue dans `Issue tracker` pour chaque idée, fonctionnalité ou défaut à traiter, et pour chaque constat laissé ouvert au ship **afin que** rien de ce qui reste à faire ne se perde hors du backlog du projet.

- **Complexité** : 3
- **Dépend de** : aucune
- **Surface** : command
- **Owns** : `method/AGENTS.md`, `method/templates/agents-local.md`, `method/commands/po-setup.md`, `method/commands/po-ship.md`, `method/commands/po-drive.md`, `method/commands/po-orchestrator.md`, `AGENTS.local.md`, `docs/decisions/ADR-0090-*`, `tests/everything-in-issues.test.sh`

**Critères d'acceptation**
- [ ] `law_files_everything_to_handle` — la Law 7 dit que toute idée de modification, fonctionnalité ou défaut à traiter, quel qu'en soit l'auteur (la personne, une revue, un subagent, le chef de projet), est déposé aussitôt dans `Issue tracker` par le chef de projet, avec son contexte, et la phrase « only a person turns one into an issue or a story » disparaît ; `## What goes to the person` garde la règle d'une idée hors périmètre portée à la personne, et ajoute qu'elle est aussi déposée en issue.
- [ ] `ship_files_open_findings` — après un ship prouvé, chaque constat de la dernière revue qui reste ouvert (majeur ou mineur non corrigé) devient une issue qui nomme la story, la revue et la sévérité ; relancer le ship n'en dépose pas une deuxième (titre déjà présent). Avec `github`, le dépôt passe par la CLI de la forge sans les variables de jeton (ADR-0083) ; avec `taskwarrior`, par une tâche `+issue` du projet ; avec `—`, rien n'est déposé et le rapport dit que le projet n'a pas d'issue tracker. Un test le tient pour les trois valeurs.
- [ ] `setup_proposes_the_forge` — `/po-setup` propose `github` quand le remote est sur GitHub, et le porteur répond ; le `AGENTS.local.md` de Polype porte `Issue tracker: github`.
- [ ] `adr_records_the_rule` — une ADR nouvelle dit la règle, les options écartées (laisser la personne seule déposer ; ne déposer que les défauts) et ce que devient un projet dont `Issue tracker` vaut `—`.

**Notes pour l'agent** : `/po-ship` lit déjà la forge et retire les variables de jeton pour `gh` (ADR-0083) : réutiliser ce chemin. Aucune autre commande ne lit `Issue tracker` aujourd'hui (`grep` du 2026-10-14). Les valeurs restent `github` · `taskwarrior` · `—` ; GitLab et Forgejo font l'objet d'une issue à part.
