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
- **Dépend de** : s133-any-harness-docs
- **Surface** : command
- **Owns** : `method/AGENTS.md`, `method/templates/agents-local.md`, `method/commands/po-setup.md`, `method/commands/po-ship.md`, `method/commands/po-drive.md`, `AGENTS.local.md`, `docs/decisions/ADR-0090-*`, `tests/everything-in-issues.test.sh`

**Critères d'acceptation**
- [ ] `law_files_everything_to_handle` — la Law 7 dit que toute idée de modification, fonctionnalité ou défaut à traiter, quel qu'en soit l'auteur (la personne, une revue, un subagent, le chef de projet) et où qu'il ait été noté (conversation, `docs/decisions-log.md`, revue), est déposé aussitôt dans `Issue tracker` par le chef de projet, avec son contexte ; avec `Issue tracker: —`, il est porté à la personne. La moitié « issue » de la phrase « only a person turns one into an issue or a story » disparaît, la règle « only a person turns a finding into a story » reste mot pour mot, et le titre `## Law 7 — Defects are not stories` ne change pas. `## What goes to the person` garde la règle d'une idée hors périmètre portée à la personne, et ajoute qu'elle est aussi déposée en issue.
- [ ] `ship_files_open_findings` — une fois la fusion prouvée par `/po-ship` (Step 3), y compris quand `/po-drive` prouve plus tard la fusion d'une PR laissée à une personne, chaque constat de la dernière revue qui reste ouvert (majeur ou mineur non corrigé) devient une issue titrée `<id>: <sévérité> — <début du constat>` et dont le corps nomme la story, la revue et la sévérité ; relancer n'en dépose pas une deuxième (même titre déjà ouvert). Avec `github`, le dépôt vise le dépôt github.com d'`origin` par `gh`, le jeton n'allant qu'à l'hôte qui l'a émis, comme l'ADR-0083 et l'étape de lecture de la forge de `/po-ship` le font ; `gh` absent ou non connecté : rien n'est déposé et le rapport le dit. Avec `taskwarrior`, une tâche `project:<nom du dépôt> +issue`. Avec `—`, rien n'est déposé et le rapport le dit. Un test tient les trois valeurs.
- [ ] `security_goes_to_the_person` — un constat de la lentille Security, ou une idée qui touche la sécurité, n'est jamais déposé tout seul : il est porté à la personne (ADR-0077), qui décide où il va. Un test le tient.
- [ ] `setup_proposes_the_forge` — `/po-setup` propose `github` quand `origin` est sur github.com, `taskwarrior` sinon ou sans remote, et écrit la valeur choisie ; la description du réglage dans `templates/agents-local.md` dit qu'il reçoit les idées, fonctionnalités et défauts à traiter, pas seulement les défauts ; chaque commande qui le lit le nomme dans son `Reads settings:` ; le `AGENTS.local.md` de Polype porte `Issue tracker: github`.
- [ ] `adr_records_the_rule` — une ADR nouvelle dit la règle, les options écartées (laisser la personne seule déposer ; ne déposer que les défauts ; déposer aussi la sécurité) et ce que devient un projet dont `Issue tracker` vaut `—`.

**Notes pour l'agent** : `/po-ship` lit déjà la forge (`gh api --hostname github.com`, repli `curl` avec `GH_TOKEN` ou `GITHUB_TOKEN`) : réutiliser ce chemin. Aucune autre commande ne lit `Issue tracker` aujourd'hui (`grep` du 2026-10-14). Les valeurs restent `github` · `taskwarrior` · `—` ; GitLab et Forgejo font l'objet d'une issue à part. `method/skills/agentic-stories/SKILL.md` et `method/skills/stories-review/SKILL.md` citent la règle sur les stories, qui reste. Le backlog déjà existant (portage Codex, fonctionnalités prévues, défauts connus) a été déposé en issues par le chef de projet le 2026-10-14, hors de cette story. Les tests qui citent mot pour mot la Law 7, `/po-ship`, `/po-setup` ou `/po-drive` gardent leurs phrases.

## M13 — La mise à jour garde le mode d'activation

Objectif : qu'un projet activé avec `polype init` le reste à chaque `polype update`, et qu'un projet déjà gonflé par ce défaut puisse revenir à son volet projet. Décidé par le porteur le 2026-10-14 en cadrant l'issue #73. Constat sur `main` à cette date : seul `init` fixe `mode=init` (`bin/polype:754`), aucun fichier d'état n'enregistre le mode (`.polype/` ne tient que `manifest`, `checksums` et `version`), et les manifestes de pecten et de nautile listent 65 fichiers dont 20 commandes `.claude/commands/`.

### s135-update-keeps-init-mode — La mise à jour d'un projet activé par init n'y pose que le volet projet
**En tant que** porteur d'un projet activé avec `polype init` **je veux** que `polype update <projet>` n'y pose que les gabarits et les hooks **afin que** les commandes, subagents et skills restent dans la pose globale et ne se dupliquent pas dans le dépôt.

- **Complexité** : 3
- **Dépend de** : s134-everything-to-handle-is-an-issue
- **Surface** : command
- **Corrige** : issue #73 (`Issue tracker: github`), reproduite le 2026-10-14 dans un HOME jetable
- **Owns** : `bin/polype`, `method/hooks/po-session.sh`, `method/commands/po-setup.md`, `docs/installation.md`, `README.md`, `docs/decisions/ADR-0091-*`, `tests/update-keeps-mode.test.sh`, `tests/no-claude-md.test.sh`, `tests/claude-md-setting.test.sh`, `tests/readme-onboarding.test.sh`, `tests/installer.test.sh`

**Critères d'acceptation**
- [ ] `init_then_update_stays_init` — `polype init <projet>` puis `polype update <projet>` laisse le même nombre de fichiers au manifeste (23 aujourd'hui) et aucun fichier sous `.claude/commands/`, `.claude/agents/` ni `.claude/skills/` ; `polype install <projet>` puis `polype update <projet>` garde l'install complète.
- [ ] `mode_is_recorded` — `install <projet>` et `init` écrivent le mode d'activation dans un fichier d'état de `.polype/`, committé avec les autres, que `update` lit ; `remove` l'efface avec le reste de l'état.
- [ ] `mode_inferred_without_state` — un projet sans ce fichier (posé avant ce correctif) : `update` déduit `init` d'un manifeste sans entrée `.claude/commands/`, et l'install complète sinon, puis écrit le fichier ; `po-session` applique la même règle pour choisir son indication. `update` fixe `$mode` depuis ce mode, si bien que les indications de l'installateur qui dépendent déjà de `$mode = init` (`absorb_agents_md`, `handle_claude_md`) disent `polype init .` sur un projet activé par init ; un test le tient.
- [ ] `init_shrinks_a_full_install` — `polype init <projet>` sur un projet dont le manifeste liste une install complète le ramène au volet projet (les copies `.claude/` en trop disparaissent du disque et du manifeste) et enregistre le mode `init` ; `docs/installation.md` dit que c'est la réparation d'un projet passé par ce défaut.
- [ ] `hints_say_init` — l'indication de `po-session` pour `Project CLAUDE file: absorbed` et l'étape 3 de `/po-setup` disent quelle commande relancer selon le mode du projet (`polype init .` pour un projet activé par init) ; les deux tests qui figent l'ancienne phrase changent avec elle, et le rapport le dit. La raison donnée par `README.md` et `docs/installation.md` pour ne jamais lancer `polype update .` sur un projet init (« y poserait les commandes ») cesse d'être vraie : ces deux textes disent désormais que `update` garde le mode, `polype init .` restant la commande conseillée et celle qui répare ; le test du README qui fige ce bloc change avec lui.
- [ ] `adr_records_the_mode` — une ADR nouvelle dit où vit le mode et pourquoi, avec les options écartées : la déduction seule (un projet déjà gonflé se lit comme une install complète) et une option `update --init` (qu'on oublie, et le défaut revient).

**Notes pour l'agent** : `target_is_a_project` (`bin/polype:110`) choisit déjà les `PAIRS` selon `$mode` ; le mécanisme des ghosts d'`update` et la boucle de `cmd_install` (`bin/polype:582`) retirent ce que le manifeste connaît et que le mode ne pose plus, ce qui suffit à faire maigrir un projet une fois le mode connu. Hors périmètre, décidé par le porteur : la protection d'une copie modifiée à la main que `drop_laid_file` supprime (issue #89), et la réparation de pecten et de nautile, faite après le ship par une PR dans chacun de ces dépôts. Tests hors `Owns` qui figent `docs/installation.md` et gardent leurs phrases : `tests/docs-and-eval-cleanup.test.sh` (« ceux qu'il trouve (ADR-0086) »), `tests/hooks-installer-docs-cleanup.test.sh` (pas de ligne de prose au-delà de 100 caractères) ; `tests/installer.test.sh:179` fige « relance `polype init <projet>` ou `polype update <projet>` », d'où sa place dans `Owns`.

### s136-session-hint-infers-init — L'indication de po-session devine init sans fichier de mode
**En tant que** porteur d'un projet activé avec `polype init` avant M13 **je veux** que l'indication de `po-session` dise `polype init .` même quand `.polype/mode` manque **afin que** la commande conseillée ne regonfle pas un projet posé avant ce fichier.

- **Complexité** : 1
- **Dépend de** : s135-update-keeps-init-mode
- **Surface** : command
- **Corrige** : issue #94 (`Issue tracker: github`), constat majeur de la revue de s135 : la mutation qui désactive la branche de déduction de `po-session` (`method/hooks/po-session.sh:244-245`) ne fait échouer aucun test
- **Owns** : `tests/update-keeps-mode.test.sh`

**Critères d'acceptation**
- [ ] `session_hint_infers_init_without_mode` — sur un projet activé par `init` dont `.polype/mode` a été retiré (manifeste sans entrée `.claude/commands/`), `po-session` écrit pour un `CLAUDE.local.md` sous `Project CLAUDE file: absorbed` la ligne `… → polype init . moves it into AGENTS.local.md` ; sur une install complète sans `.polype/mode`, la ligne dit `polype update .`. Le test échoue quand la branche de déduction est désactivée.

**Notes pour l'agent** : `test_hints_say_init` (`tests/update-keeps-mode.test.sh:98`) ne couvre qu'un projet qui a son fichier de mode ; s'en inspirer. Aucun changement de code attendu : si le test révèle un défaut de la branche, le rapport le dit et la story s'arrête pour la personne. Hors périmètre : les commentaires périmés (#95, #96) et l'écart de formulation (#97).

## M14 — L'installeur ne perd rien de ce que la personne a modifié

Objectif : qu'aucune commande de l'installeur ne supprime une copie que la personne a modifiée, et solder les constats mineurs laissés par s135 et s136. Décidé par le porteur le 2026-10-14 en cadrant les issues #89, #95, #96, #97 et #102 : une copie modifiée que le mode ou la version ne pose plus **reste en place** et devient un fichier de la personne, `remove` compris ; #97 est fermée sans story (écart assumé par le plan de s135, comportement livré). Constat sur `main` (058d6a2) : `drop_laid_file` (`bin/polype:236`) supprime sans comparer de somme, et `cmd_install` (`bin/polype:597`), les ghosts d'`update` (`bin/polype:639`) et `cmd_remove` (`bin/polype:742`) y passent ; `cmd_install` n'appelle pas `load_checksums`, si bien que `has_drifted` (`bin/polype:560`) n'y a rien à comparer.

### s137-modified-copy-survives-drop — Une copie modifiée que Polype ne pose plus reste en place
**En tant que** porteur d'un projet où j'ai retouché une copie posée par Polype **je veux** que `init`, `install`, `update` et `remove` la laissent en place quand ils ne la posent plus, et me le disent **afin de** ne jamais perdre une retouche sans le savoir.

- **Complexité** : 3
- **Dépend de** : s136-session-hint-infers-init
- **Surface** : command
- **Corrige** : issue #89 (`Issue tracker: github`), et issue #96 (en-tête de `bin/polype` périmé), même fichier
- **Owns** : `bin/polype`, `docs/installation.md`, `docs/decisions/ADR-0092-*`, `docs/decisions/ADR-0088-*`, `tests/drop-keeps-modified.test.sh`

**Critères d'acceptation**
- [ ] `init_keeps_a_modified_copy` — sur un projet posé par `polype install <projet>` dont une copie `.claude/commands/` a été modifiée, `polype init <projet>` laisse cette copie sur le disque octet pour octet, la retire du manifeste et des deux fichiers de sommes (`.polype/checksums`, `.claude/.polype-checksums`), écrit sur stderr `polype: modified, kept: <chemin>` ; les autres copies en trop, non modifiées, disparaissent comme avant et le manifeste revient à 23 fichiers.
- [ ] `update_ghost_keeps_a_modified_copy` — une entrée du manifeste que la version ne livre plus et dont la copie a été modifiée reste sur le disque, sort du manifeste, est signalée par la même ligne et n'est pas comptée dans « removed » du message final ; une telle entrée non modifiée est supprimée et comptée comme avant.
- [ ] `remove_keeps_a_modified_copy` — `polype remove <projet>` laisse en place une copie modifiée, le dit par la même ligne, et retire les autres comme avant.
- [ ] `modified_copy_over_a_set_aside_file` — quand une copie modifiée a aussi un `<chemin>.before-polype` (fichier de la personne mis de côté par `--set-aside`), les deux restent tels quels et la ligne nomme les deux ; rien n'est écrasé. C'est le seul cas où le fichier mis de côté n'est pas remis en place : ADR-0092 remplace en partie ADR-0088 sur ce point, et seul le `superseded-by` de l'ADR-0088 change.
- [ ] `kept_copy_becomes_the_persons` — une install suivante qui livre de nouveau ce chemin le traite comme un fichier que Polype n'a pas posé : elle s'arrête sur la collision (sortie 1, rien d'écrit) et `--set-aside` le met de côté, comme ADR-0088 le dit.
- [ ] `header_lists_the_mode_file` — le commentaire d'en-tête de `bin/polype` compte `.polype/mode` parmi les fichiers d'état d'un projet (issue #96).
- [ ] `adr_records_the_choice` — une ADR nouvelle dit qu'une copie modifiée que Polype ne pose plus reste en place et devient un fichier de la personne, avec les options écartées : la mettre de côté sous un nouveau suffixe (un fichier de plus à trier), arrêter la commande comme pour une collision (un `init` de réparation bloqué par une seule retouche), exempter `remove` (la retouche se perd au moment où l'on retire Polype). Elle nomme aussi deux limites : une copie sans somme enregistrée se supprime comme avant (cas d'un clone neuf, les sommes de `.claude/` vivant hors git depuis ADR-0087 : git garde alors la retouche), et la charge utile de `~/.claude/polype/` part entière avec son dossier au `remove` global, sans ligne « kept ». `docs/installation.md` le dit.

**Notes pour l'agent** : « modifiée » a le sens de `has_drifted` : la somme enregistrée existe et diffère de celle du fichier ; une copie sans somme enregistrée se supprime comme avant. `cmd_install` et `cmd_remove` doivent charger les sommes avant leur boucle de retrait (ni l'un ni l'autre n'appelle `load_checksums` aujourd'hui ; `cmd_remove` efface les fichiers de sommes juste après, `bin/polype:745-746`) ; la protection vit dans le seul point de suppression, `drop_laid_file`. Au `remove` global, un fichier de la charge utile (sous `polype/`) n'est jamais déclaré gardé, puisque `rm -rf "$state_dir"` (`bin/polype:748`) l'emporte ; le chemin propre de la mise de côté (`bin/polype:733-741`) reste tel quel. Tests hors `Owns` qui figent `docs/installation.md` et gardent leurs phrases : `tests/docs-and-eval-cleanup.test.sh`, `tests/hooks-installer-docs-cleanup.test.sh` (pas de ligne de prose au-delà de 100 caractères). Ne renomme pas `recorded_mode` (`bin/polype:94`) : le commentaire de s138 y renvoie. Hors périmètre : le commentaire de `po-session` (#95) et le helper de test (#102), portés par s138.

### s138-mode-hint-cleanup — Le commentaire de po-session et ses tests disent juste
**En tant que** mainteneur de Polype **je veux** que le commentaire de `po-session` donne la vraie raison de son indication et que ses deux tests partagent leurs réglages **afin que** le prochain lecteur ne soit pas trompé et que les deux tests ne divergent pas.

- **Complexité** : 1
- **Dépend de** : s136-session-hint-infers-init
- **Surface** : —
- **Corrige** : issues #95 et #102 (`Issue tracker: github`), constats mineurs des revues de s135 et s136
- **Owns** : `method/hooks/po-session.sh`, `tests/update-keeps-mode.test.sh`

**Critères d'acceptation**
- [ ] `session_comment_says_why` — le commentaire au-dessus du choix de l'indication (`method/hooks/po-session.sh:241`) ne dit plus qu'`update` poserait les commandes sur un projet init ; il dit que `polype init .` est la commande conseillée et celle qui répare un projet gonflé, et renvoie à la règle `recorded_mode` de l'installeur. Aucune ligne de code du hook ne change. Le test lit le commentaire : plus de « would lay the commands », `recorded_mode` présent.
- [ ] `absorbed_settings_helper` — `test_hints_say_init` et `test_session_hint_infers_init_without_mode` écrivent leur `AGENTS.local.md` par un seul helper du fichier de test (par exemple `absorbed_settings`) ; les deux tests passent ; `test_session_hint_infers_init_without_mode` échoue toujours quand la branche de déduction de `po-session` est désactivée, et `test_hints_say_init` tient toujours le chemin du mode enregistré (`.polype/mode` à `init`).

**Notes pour l'agent** : `recorded_mode` est la fonction de `bin/polype` que s137 ne renomme pas. Hors périmètre : `bin/polype` (s137).

## M15 — Les suites de M14

Objectif : solder ce que M14 a laissé ouvert. Décidé par le porteur le 2026-10-15 et le 2026-10-16 en cadrant les issues #107, #108, #110, #111 et #112 : un fichier modifié de la charge utile globale que Polype ne livre plus **sort de la charge utile** vers `~/.claude/polype.kept/`, et cette copie gardée **disparaît d'elle-même** dès qu'une version livre un fichier identique au même chemin (preuve que la retouche a été intégrée) ; une revue suit un **gabarit à remplir** aligné sur `/po-ship`, et sa forme est **contrôlée dès qu'elle est enregistrée**. Constat sur `main` (8d576ed) : `shipped_pairs` (`bin/polype:137`) liste tout fichier présent sous `method/` de la charge utile, si bien qu'une copie gardée par `drop_laid_file` dans `~/.claude/polype/` est reposée au run suivant (#111, reproduit par la revue de s137) ; le gabarit `method/templates/review.md` décrit ses constats sans marqueur de liste (`<one per line: severity — file:line — the problem>`) alors que l'étape 3.2 de `/po-ship` ne lit que des items de liste (#112).

### s139-payload-kept-outside — Une retouche de la charge utile sort de la charge utile
**En tant que** porteur qui a retouché un fichier de `~/.claude/polype/` **je veux** que l'installeur global le déplace hors de la charge utile quand Polype ne le livre plus, puis l'efface quand une version livre ce même contenu **afin que** ma retouche ne se perde pas sans redevenir de la méthode active.

- **Complexité** : 3
- **Dépend de** : s137-modified-copy-survives-drop
- **Surface** : command
- **Corrige** : issues #111 et #110 (`Issue tracker: github`)
- **Owns** : `bin/polype`, `docs/installation.md`, `docs/decisions/ADR-0093-la-retouche-de-la-charge-utile-sort-de-la-charge-utile.md`, `docs/decisions/ADR-0092-*`, `tests/drop-keeps-modified.test.sh`, `tests/payload-kept-outside.test.sh`

**Critères d'acceptation**
- [ ] `payload_copy_moves_out` — après `install --global`, un fichier modifié de `polype/method/` que la version suivante ne livre plus est déplacé, octet pour octet, vers `<racine>/polype.kept/<chemin sous polype/>`, retiré du manifeste et des sommes, et signalé par `polype: modified, moved out of the payload: <ancien> -> <nouveau>` ; il n'existe plus sous `polype/`.
- [ ] `moved_copy_is_not_shipped` — le run suivant lancé depuis la charge utile (`<racine>/polype/bin/polype update --global`) ne repose pas ce fichier : aucune copie active ne réapparaît (le scénario de la revue de s137 ne se reproduit plus).
- [ ] `kept_copy_removed_once_shipped` — une copie de `polype.kept/` est supprimée par une pose ou une mise à jour globale dès que la charge utile livre au même chemin un fichier de contenu identique, avec la ligne `polype: kept copy now shipped, removed: <chemin>` ; une copie dont le contenu diffère reste, sans ligne. Les dossiers vidés de `polype.kept/` disparaissent.
- [ ] `existing_kept_copy_never_overwritten` — si `polype.kept/<chemin>` existe déjà avec un autre contenu, la commande s'arrête avant d'écrire quoi que ce soit (sortie 1) et nomme les deux fichiers, comme pour un `.before-polype` déjà pris (ADR-0088) ; une copie gardée de même contenu vaut déjà gardée : le fichier de la charge utile part, et la ligne dit `polype: modified, already kept: <chemin>`.
- [ ] `remove_leaves_kept_copies` — `remove --global` déplace d'abord vers `polype.kept/` tout fichier modifié de la charge utile, encore livré ou non, avec la même ligne `moved out of the payload`, puis laisse `polype.kept/` en place et écrit `polype: kept copies left in <racine>/polype.kept` ; une copie gardée déjà prise avec un autre contenu l'arrête avant toute écriture, comme `install` et `update` ; un fichier modifié qui couvre aussi un `.before-polype` part vers `polype.kept/`, et le `.before-polype` revient par le chemin `held` d'aujourd'hui (`bin/polype:748-753`) ; le reste de la charge utile part avec son dossier, comme aujourd'hui. La raison qui écarte la suppression (la charge utile n'est pas dans git) vaut aussi au `remove`.
- [ ] `update_test_checks_all_state` — `test_update_ghost_keeps_a_modified_copy` (`tests/drop-keeps-modified.test.sh`) vérifie aussi `.polype/checksums`, par le même helper `out_of_the_state` que le test d'`init` (#110).
- [ ] `adr_records_the_kept_payload` — une ADR nouvelle remplace ADR-0092 sur deux points, la charge utile n'étant plus un endroit où une retouche reste, ni un endroit dont `remove --global` emporte une retouche (seul le `superseded-by` de l'ADR-0092 change), avec les options écartées : supprimer la retouche en la signalant (perdue pour de bon, la charge utile n'étant pas dans git), garder le dossier jusqu'à ce que la personne l'efface (rien n'en signale la fin) ; `docs/installation.md` le dit, et sa phrase qui dit que `remove --global` emporte une retouche de la charge utile (`:323-324`) disparaît.

**Notes pour l'agent** : seuls les chemins sous `polype/` en mode global sont concernés ; les copies actives (`commands/`, `agents/`, `skills/`) et les projets gardent la règle d'ADR-0092. Le déplacement se décide dans `drop_laid_file` (ou juste avant son appel) pour `mode=global` et un chemin `polype/*` ; le contrôle « déjà pris » se fait avant toute écriture ; il a besoin des sommes, donc `load_checksums` passe avant `refuse_collisions` dans `cmd_install` (`bin/polype:599-600`) et `cmd_update` (`:640-641`). Tests hors `Owns` qui figent `docs/installation.md` et gardent leurs phrases : `tests/docs-and-eval-cleanup.test.sh`, `tests/hooks-installer-docs-cleanup.test.sh` (pas de ligne de prose au-delà de 100 caractères), `tests/installer.test.sh:175`, `tests/local-copy-checksums.test.sh:156`, `tests/global-install.test.sh:119`, `tests/readme-onboarding.test.sh:143`, `tests/post-m7-texts.test.sh:5` ; s139 ajoute du texte sans retirer ces phrases. Ne renomme pas `recorded_mode`.

### s140-session-branches-tested — Les deux branches de l'indication de po-session sont tenues
**En tant que** mainteneur de Polype **je veux** qu'un test distingue la branche « mode enregistré » de la branche « mode déduit » de `po-session`, et que son commentaire se lise d'une traite **afin qu'une** régression de l'une ne passe pas inaperçue derrière l'autre.

- **Complexité** : 1
- **Dépend de** : s138-mode-hint-cleanup
- **Surface** : —
- **Corrige** : issues #107 et #108 (`Issue tracker: github`)
- **Owns** : `method/hooks/po-session.sh`, `tests/update-keeps-mode.test.sh`

**Critères d'acceptation**
- [ ] `session_hint_trusts_recorded_mode` — sur un projet gonflé (posé par `install`, manifeste avec des entrées `.claude/commands/`) dont `.polype/mode` dit `init`, `po-session` écrit pour un `CLAUDE.local.md` sous `Project CLAUDE file: absorbed` la ligne `… → polype init . moves it into AGENTS.local.md` ; le test échoue quand la condition `[ "$recorded" = init ]` est désactivée (`method/hooks/po-session.sh:245` ; #107 cite 244, la ligne qui lit `recorded`).
- [ ] `session_comment_reads_once` — le commentaire au-dessus du choix de l'indication contient le mot `advise` (mot entier, `grep -w`) une seule fois et écrit la commande entre backticks (`` `polype init .` ``), si bien que son point ne se lit plus comme une fin de phrase ; `test_session_comment_says_why` passe toujours. Aucune ligne de code du hook ne change.

**Notes pour l'agent** : `absorbed_settings` et `mode_is` existent déjà dans le fichier de test ; s'en servir.

### s141-review-findings-shape — Une revue se remplit sur un gabarit que /po-ship sait lire
**En tant que** porteur **je veux** que la revue se remplisse sur un gabarit qui montre la ligne exacte d'un constat, et qu'une revue mal formée soit redemandée dès son enregistrement **afin qu'aucun** constat n'échappe au dépôt d'issues de `/po-ship`.

- **Complexité** : 3
- **Dépend de** : s134-everything-to-handle-is-an-issue
- **Surface** : command
- **Corrige** : issue #112 (`Issue tracker: github`), et l'écart entre le gabarit et `/po-ship` relevé en cadrant (commentaire du 2026-10-16 sur #112)
- **Owns** : `method/templates/review.md`, `method/agents/reviewer.md`, `method/hooks/po-gate.sh`, `method/commands/po-review.md`, `method/commands/po-drive.md`, `method/commands/po-ship.md`, `docs/decisions/ADR-0094-la-forme-d-une-revue-se-controle-a-l-enregistrement.md`, `tests/review-findings-shape.test.sh`

**Critères d'acceptation**
- [ ] `template_shows_the_line` — la section `## Findings` de `method/templates/review.md` montre la ligne à remplir sous la forme que lit l'étape 3.2 de `/po-ship` : `- <critical|major|minor> — <chemin>:<ligne> — <le problème>`, un constat par item, et dit qu'aucun constat ne s'écrit en titre ; l'agent `reviewer` renvoie à cette forme.
- [ ] `gate_checks_findings_shape` — une sous-commande `po-gate findings-shape <id>` lit `## Findings` de la dernière revue de `docs/reviews/<id>.md` (le bloc qui finit par son dernier `Ship allowed:`) et sort 1 en citant la ligne fautive (numéro et texte) dans trois cas, et ceux-là seuls : un titre (ligne qui commence par `#`) qui contient `critical`, `major` ou `minor` ; un item de liste dont la première ligne contient une sévérité sans s'ouvrir par elle ; une ligne hors liste et non indentée qui s'ouvre par une sévérité, nue ou en gras. Elle sort 1 aussi quand la revue n'a pas de section `## Findings`. Une sévérité se reconnaît comme mot entier, sans tenir compte de la casse (`### F1: Major.` est refusé, « majority » ne compte pas) ; la section va jusqu'au titre `## ` suivant, si bien qu'un titre `###` y reste ; une sous-puce indentée est une ligne de suite, acceptée quoi qu'elle dise. Tout le reste passe : les formes d'item que lit `/po-ship` (`- major —`, `- **major** —`, `1. **minor**:`, `* minor:`), les lignes de suite indentées, les lignes vides, `none`, `None.` et une phrase sans sévérité en tête comme « No critical or major finding. ». L'emplacement `<chemin>:<ligne>` n'est pas contrôlé : un constat sans emplacement unique reste valable. Les revues de s137 (refusée) et de s138 (acceptée) tiennent lieu de cas réels.
- [ ] `recording_runs_the_check` — `/po-review` et `/po-drive` lancent `po-gate findings-shape <id>` juste après avoir enregistré la réponse du reviewer ; un échec renvoie la même revue au reviewer une fois, au même `Fix loop:`, sans dépenser d'unité de `Max attempts`, avec la ligne fautive ; sa nouvelle réponse est ajoutée après le bloc mal formé, qui reste tel quel ; un second échec va à la personne : le lead ajoute alors un rapport bloqué (`Review status: blocked`, un `Next action:` qui nomme la personne et la forme des constats, `Max severity: critical`, `Ship allowed: no`), si bien que l'arrêt survit à une reprise. `/po-flow` et `/po-orchestrator`, qui enregistrent « comme `/po-review` le dit », en héritent sans changer.
- [ ] `ship_net_catches_headings` — le filet « not filed: shape not recognised » de l'étape 3.2 de `/po-ship` attrape aussi un titre qui contient `critical`, `major` ou `minor`, de sorte qu'une revue mal formée qui arrive au ship n'est jamais ignorée en silence ; l'exception de la phrase « No critical or major finding. » reste, et la phrase actuelle du filet garde ses mots.
- [ ] `adr_records_the_shape_check` — une ADR nouvelle dit pourquoi la forme se contrôle à l'enregistrement, avec les options écartées : le gabarit seul (un modèle remplit librement, la dérive revient), un refus au ship par `po-gate ship-allowed` (plus tard et plus brutal, un format arrête une livraison).

**Notes pour l'agent** : la revue de s137 (`docs/reviews/s137-modified-copy-survives-drop.md`) est le cas réel d'une revue mal formée, et celle de s138 un cas bien formé : s'en servir comme fixtures. Le lead n'ayant ni Write ni Edit dans `/po-drive`, le contrôle passe par Bash. Les fichiers installés (`.claude/`, `.polype/`) ne se touchent pas. Tests hors `Owns` qui figent les fichiers changés et gardent leurs phrases : `tests/hooks-installer-docs-cleanup.test.sh:57` (« a finding never starts with `Ship allowed:` », à garder dans le nouveau gabarit), `tests/review.test.sh:23` et `:46`, `tests/review-lenses.test.sh:85-86`, `tests/everything-in-issues.test.sh:130` et `:181-184` (les lignes `- title:` / `- body:` de l'étape 3.2 que `cut_finding` lit, et la phrase du filet), `tests/final-leftovers.test.sh:7`, `tests/fleet-wiring.test.sh:68`, `tests/qa-fleet.test.sh:110-121`, `tests/resume.test.sh`. Hors périmètre : réécrire les revues déjà enregistrées.

## M16 — La charge utile ne relivre rien, la forme de revue se tient partout

Objectif : solder les constats laissés par M15. Décidé par le porteur le 2026-10-17 et le 2026-10-18 en cadrant les issues #115, #118 à #121, #123 et #125 à #127 : un fichier que Polype n'a pas posé sous `~/.claude/polype/` **arrête la commande**, même avec `--set-aside` (#118) ; une retouche d'un fichier de la charge utile encore livré est **signalée et ne se propage pas** (#115) ; pour que ces deux règles tiennent aussi quand la charge utile est synchronisée entre machines (ADR-0004, `docs/installation.md`), **la charge utile se signe elle-même** : une install depuis un dépôt Polype écrit dans la charge utile la liste de ses fichiers et de leurs sommes, qui voyage avec elle, et un run lancé depuis la charge utile s'y compare ; le contrôle de forme des revues est **resserré sur les seules formes que lit `/po-ship`**, par une ADR qui remplace ADR-0094 sur ce point. Constat sur `main` (c974e49) : lancé depuis la charge utile, l'installeur prend chaque fichier de `polype/` pour sa propre source (`bin/polype:112-113`, `:143`), si bien qu'il ne voit ni un fichier étranger (`refuse_collisions`, `:201`) ni une retouche (`cmd_update`, `:731`), qu'il relivre l'un et propage l'autre ; `drop_laid_file` remet un `.before-polype` dans la charge utile (`:301-303`, #118) ; `opens()` de `po-gate.sh:94` accepte des items que l'étape 3.2 de `/po-ship` ne lit pas (#126) ; `/po-orchestrator` et `/po-flow` lisent le rapport bloqué sur la forme comme une correction à faire (#123, #125).

### s142-payload-refuses-foreign-files — La charge utile se signe et n'accueille aucun fichier de la personne
**En tant que** porteur qui installe Polype globalement, sur une ou plusieurs machines **je veux** que la charge utile porte la liste de ses propres fichiers et qu'un fichier hors de cette liste arrête la commande **afin qu'aucun** de mes fichiers ne soit relivré comme méthode active, par aucun canal.

- **Complexité** : 4 — risque : le canal de synchronisation et les installs déjà posées sans signature
- **Dépend de** : s139-payload-kept-outside
- **Surface** : command
- **Corrige** : issue #118 (`Issue tracker: github`)
- **Owns** : `bin/polype`, `docs/installation.md`, `docs/decisions/ADR-0095-la-charge-utile-se-signe-et-n-accueille-aucun-fichier-etranger.md`, `docs/decisions/ADR-0088-l-installeur-s-arrete-sur-une-collision-et-absorbe-l-agents-md.md`, `tests/payload-kept-outside.test.sh`, `tests/install-collisions.test.sh`, `tests/global-install.test.sh`, `tests/drop-keeps-modified.test.sh`, `tests/payload-refuses-foreign-files.test.sh`

**Critères d'acceptation**
- [ ] `payload_signs_itself` — une install ou une mise à jour globale lancée depuis un dépôt Polype (source hors de la charge utile) écrit `<racine>/polype/payload.sums`, une ligne par fichier de la charge utile (somme `cksum` et chemin sous `polype/`), sans les fichiers d'état (`manifest`, `checksums`, `version`, `payload.sums`, tout `*.next` et tout `*.polype-next`) ; le fichier vit dans la charge utile, si bien qu'une synchronisation de `~/.claude/polype/` l'emporte avec elle.
- [ ] `foreign_payload_file_stops_install` — un fichier sous `<racine>/polype/` est **étranger** quand il n'est pas un fichier d'état, qu'il est absent du manifeste de cette machine, et que la source ne le livre pas (run depuis un dépôt : chemin absent des fichiers livrés) ou que `payload.sums` ne le liste pas (run depuis la charge utile). Un fichier étranger, ordinaire ou lien, arrête `install`, `update` et `init` avant toute écriture (sortie 1), avec ou sans `--set-aside`, en le nommant et en disant de le déplacer ; à toute install ou mise à jour, une collision sous `polype/` (un fichier de la personne, absent du manifeste, à un chemin livré) s'arrête de même, `--set-aside` ne s'y appliquant plus. Un fichier du manifeste garde les règles de retrait et de sortie de la charge utile (s137, s139), y compris quand une charge utile synchronisée ne le liste plus. Une collision hors de `polype/` garde la règle d'ADR-0088.
- [ ] `synced_payload_still_installs` — une charge utile d'une version plus récente, copiée avec son `payload.sums` dans la racine d'une autre install (le chemin de synchronisation documenté), puis `<racine>/polype/bin/polype update --global` : aucun arrêt, les fichiers nouveaux sont posés et entrent au manifeste.
- [ ] `old_set_aside_never_put_back_in_payload` — un `<chemin>.before-polype` sous `polype/`, laissé par une install antérieure, n'est jamais remis dans la charge utile ni listé comme source : il tombe sous `foreign_payload_file_stops_install` ; `remove --global` garde son chemin `held` d'aujourd'hui, qui le remet une fois la charge utile partie.
- [ ] `remove_stops_on_foreign_payload_file` — `remove --global` s'arrête avant toute écriture quand la charge utile contient un fichier absent du manifeste et de `payload.sums` (hors fichiers d'état), au lieu de l'emporter avec `rm -rf` ; il le nomme. Il ne lit aucune source livrée : seulement le manifeste et `payload.sums`.
- [ ] `unsigned_payload_says_so` — une charge utile sans `payload.sums` (posée avant ce correctif) : `install`, `update` et `init` lancés depuis la charge utile s'arrêtent avant toute écriture en disant de relancer une fois l'install depuis un dépôt Polype ; `check --global` et `remove --global` fonctionnent, avec une ligne qui dit la charge utile non signée (`remove` se fie alors au seul manifeste) ; un run depuis un dépôt écrit le fichier.
- [ ] `adr_records_the_payload_rule` — une ADR nouvelle dit que la charge utile se signe, qu'un fichier hors signature l'arrête (#118) et qu'une retouche d'un fichier signé n'en sort pas (#115), cette seconde règle étant implémentée par s143 et dite comme telle, avec les options écartées : faire confiance à la charge utile lancée depuis elle-même (une retouche s'y propage), exiger un dépôt comme source (l'usage chezmoi disparaît), ranger un fichier étranger dans `polype.kept/` (un fichier qui n'a jamais été une retouche s'y mêle), propager la retouche en le disant. Elle remplace ADR-0088 sur la mise de côté sous `polype/`, seul point remplacé, et seul le `superseded-by` de l'ADR-0088 change. `docs/installation.md` le dit, chemin de synchronisation compris.

**Notes pour l'agent** : tests qui deviennent faux avec la règle et changent avec elle, le rapport le dit : `tests/install-collisions.test.sh:171` et `tests/payload-kept-outside.test.sh:165-169` (mise de côté d'un fichier sous `polype/`), et ceux de `tests/global-install.test.sh` qui lancent depuis la charge utile sans signature. La ligne d'usage de `--set-aside` (`bin/polype:57-58`) dit qu'elle ne vaut pas sous `polype/`. Le contrôle se fait avant `refuse_collisions`, les sommes chargées. Un run « depuis la charge utile » est celui dont la source (`base`) est `<racine>/polype`. Ne renomme pas `recorded_mode`. Tests hors `Owns` qui figent `docs/installation.md` et gardent leurs phrases : `tests/docs-and-eval-cleanup.test.sh`, `tests/hooks-installer-docs-cleanup.test.sh` (100 caractères), `tests/installer.test.sh:175`, `tests/local-copy-checksums.test.sh:156`, `tests/readme-onboarding.test.sh:143`, `tests/post-m7-texts.test.sh:5`. Hors périmètre : la retouche d'un fichier signé (#115, s143), les cas des copies gardées (#119 à #121, s146).

### s143-payload-edit-not-spread — Une retouche de la charge utile reste dans la charge utile
**En tant que** porteur qui a retouché un fichier encore livré de `~/.claude/polype/` **je veux** que tout run lancé depuis la charge utile me signale cette retouche et ne la recopie nulle part **afin qu'une** modification de la méthode ne se répande pas sans que je l'aie décidé.

- **Complexité** : 2
- **Dépend de** : s142-payload-refuses-foreign-files
- **Surface** : command
- **Corrige** : issue #115 (`Issue tracker: github`)
- **Owns** : `bin/polype`, `docs/installation.md`, `tests/payload-edit-not-spread.test.sh`

**Critères d'acceptation**
- [ ] `payload_edit_reported_not_spread` — un fichier de `polype/method/` dont la somme diffère de celle que `payload.sums` donne, puis `install --global` ou `update --global` lancés depuis la charge utile : le fichier reste tel quel, la copie active correspondante garde son contenu d'avant, la sortie dit `polype: modified, left as it is: <chemin dans polype/>`, le message final la compte dans « left modified » (le message final d'`install --global`, qui ne donne aujourd'hui que le nombre de fichiers, gagne ce compte), et ni `payload.sums` ni les sommes enregistrées ne prennent la somme retouchée.
- [ ] `init_does_not_take_payload_edit` — `init <projet>` lancé depuis une charge utile qui porte une telle retouche (un gabarit ou un hook) ne la pose pas dans `.polype/` du projet : il garde la copie du projet telle qu'elle est (ou n'en pose pas si elle manque) et dit la même ligne.
- [ ] `check_lists_payload_edit` — `check --global` liste ce fichier de la charge utile comme modifié.
- [ ] `fresh_source_still_updates` — `update --global` lancé depuis un dépôt Polype remplace toujours un fichier non retouché de la charge utile et sa copie active, et réécrit `payload.sums`.

**Notes pour l'agent** : la règle est celle d'ADR-0095 (écrite par s142). Une charge utile synchronisée porte son `payload.sums` à jour : ses fichiers correspondent à leur liste et ne sont pas des retouches. Une copie active déjà retouchée garde sa règle d'aujourd'hui.

### s144-shape-gate-matches-ship — Le contrôle de forme refuse ce que /po-ship ne sait pas lire
**En tant que** porteur **je veux** que `po-gate findings-shape` n'accepte un constat que sous une forme que l'étape 3.2 de `/po-ship` lit, et que tout autre échec du gate arrête l'enregistrement par écrit **afin que** le dépôt silencieux de #112 ne revienne par aucune forme.

- **Complexité** : 2
- **Dépend de** : s141-review-findings-shape
- **Surface** : command
- **Corrige** : issues #126 et #127 (`Issue tracker: github`)
- **Owns** : `method/hooks/po-gate.sh`, `method/commands/po-review.md`, `method/commands/po-drive.md`, `docs/decisions/ADR-0096-le-controle-de-forme-suit-ce-que-po-ship-lit.md`, `docs/decisions/ADR-0094-la-forme-d-une-revue-se-controle-a-l-enregistrement.md`, `tests/review-findings-shape.test.sh`

**Critères d'acceptation**
- [ ] `gate_accepts_only_ship_shapes` — un item qui nomme une sévérité passe seulement sous une forme que l'étape 3.2 ouvre : marqueur `- `, `* ` ou `<n>. `, sévérité en minuscules, nue ou en gras, le deux-points dedans ou hors du gras, puis `—`, `:` ou `-` (`- **major:** x` et `- **major**: x` passent). Est refusé, cité avec son numéro, un titre (ligne qui commence par `#`) qui nomme une sévérité où que ce soit, comme `### F1: major.` (le cas de #112, que le test de s141 tient toujours) ; et toute autre ligne de `## Findings` hors d'un item accepté et hors ligne de suite indentée dont le premier mot, passé les caractères qui ne sont pas des lettres, est une sévérité en toute casse : `- major. a.sh:1 x`, `- major (a.sh:1) x`, `- MAJOR x`, `- Major — x`, `+ major — x`, `1) major — x`, `> major — x`, `• major — x`. Les cas acceptés de s141 (`- **major** —`, `1. **minor**:`, `* minor:`, `None.`, « No critical or major finding. ») passent toujours.
- [ ] `other_gate_failures_stop` — `po-gate findings-shape` sans id sort 2 ; `/po-review` et `/po-drive` disent qu'une sortie du gate autre que 0 et 1 n'est pas une revue mal formée : le reviewer n'est pas relancé, et le contexte qui enregistre ajoute le même rapport bloqué que pour un second échec (`Review status: blocked`, un `Next action:` qui nomme `po-gate findings-shape` et la sortie, `Max severity: critical`, `Ship allowed: no`), si bien que la reprise de `/po-drive` et celle de s145 l'envoient à la personne ; ce rapport et la ligne de la table de reprise de `/po-drive` disent que le contrôle n'a pas pu tourner (avec la sortie), et non que les constats ont échoué deux fois à leur forme.
- [ ] `adr_narrows_the_shape` — une ADR nouvelle remplace ADR-0094 sur la règle des sévérités (« toute casse », trois cas refusés) : le gate refuse tout ce que l'étape 3.2 ne sait pas ouvrir, avec les options écartées : garder « toute casse » et apprendre à `/po-ship` les autres formes (deux lectures à tenir au lieu d'une). Seul le `superseded-by` de l'ADR-0094 change.

**Notes pour l'agent** : la forme acceptée est celle des deux premiers points de l'étape 3.2 de `method/commands/po-ship.md` (« Which findings ») ; un seul motif dans le gate. Tests hors `Owns` qui figent `po-review.md` et `po-drive.md` : `tests/review.test.sh`, `tests/fleet-wiring.test.sh:68`, `tests/qa-fleet.test.sh:110-121`, `tests/resume.test.sh`, `tests/drive.test.sh` (aucun `` `cd `` dans `po-drive.md`).

### s145-resume-shape-stop — /po-orchestrator et /po-flow respectent l'arrêt sur la forme
**En tant que** porteur **je veux** que `/po-orchestrator` et `/po-flow` m'envoient une revue bloquée sur la forme de ses constats au lieu d'en faire une correction **afin qu'aucune** tentative ne soit dépensée sur un code que personne n'a mis en cause.

- **Complexité** : 2
- **Dépend de** : s141-review-findings-shape
- **Surface** : command
- **Corrige** : issues #123 et #125 (`Issue tracker: github`)
- **Owns** : `method/commands/po-orchestrator.md`, `method/commands/po-flow.md`, `tests/resume-shape-stop.test.sh`

**Critères d'acceptation**
- [ ] `orchestrator_stops_on_shape_block` — à son Stage 7, `/po-orchestrator` enregistre la revue « as `/po-review` says » (la phrase de délégation « Delegate to `reviewer` the way `/po-review` does » reste telle quelle) et, avant sa règle « Any other blocked review → back to stage 5 as a fix run », envoie à la personne une revue `Review status: blocked` dont le `Next action:` nomme `po-gate findings-shape`, sans dépenser de correction.
- [ ] `flow_stops_on_shape_block` — l'étape « Fix loops » de `/po-flow` fait de même, avant « Any other `Ship allowed: no` → a fix run », la ligne existante restant entière.

**Notes pour l'agent** : le rapport bloqué et son `Next action:` sont ceux de `method/commands/po-review.md` (`## Recording`, s141) ; les citer, ne pas les réécrire. Le message à la personne reprend la cause que le rapport écrit : « the check could not run » pour une sortie autre que 0 et 1 (s144), l'échec de forme répété sinon. Tests hors `Owns` qui figent ces deux fichiers et gardent leurs phrases : `tests/pilot.test.sh:19`, `tests/model-routing.test.sh:113` (la phrase de délégation), `tests/qa-fleet.test.sh:162` (la ligne de `/po-flow`).

### s146-kept-copy-edge-fixes — Les copies gardées tiennent leurs cas limites
**En tant que** porteur **je veux** que le balayage des copies gardées soit tenu par un test sur `update`, qu'un lien n'arrête pas la commande à tort, et qu'un déplacement raté ne soit jamais annoncé **afin que** `polype.kept/` dise toujours vrai.

- **Complexité** : 2
- **Dépend de** : s143-payload-edit-not-spread
- **Surface** : command
- **Corrige** : issues #119, #120 et #121 (`Issue tracker: github`)
- **Owns** : `bin/polype`, `tests/payload-kept-outside.test.sh`

**Critères d'acceptation**
- [ ] `update_sweeps_shipped_kept_copy` — `update --global` supprime une copie de `polype.kept/` dont la charge utile livre désormais le contenu identique ; le test échoue quand l'appel du balayage dans `cmd_update` est retiré (#119).
- [ ] `symlink_payload_path_not_refused` — un chemin de la charge utile qui est un lien symbolique n'arrête pas la commande sur une copie gardée qu'il ne déplacerait jamais : `refuse_taken_kept_copies` applique le même `[ ! -L … ]` que `drop_laid_file` (#120).
- [ ] `failed_move_is_not_reported_as_done` — quand un parent de `polype.kept/<chemin>` est un fichier ordinaire, la commande s'arrête avant toute écriture en nommant ce parent ; la ligne `moved out of the payload` n'est jamais écrite pour un fichier resté en place (#121).

**Notes pour l'agent** : les trois constats et leurs reproductions sont dans `docs/reviews/s139-payload-kept-outside.md` (`## Findings`).

## M17 — Le harnais : chaque gain d'autonomie se paie par un vérificateur

Objectif : que la méthode porte le harnais qui rend fiable le code écrit par agent, c'est-à-dire des contrôles rapides, vérifiables par une machine, autour de chaque story, et des capteurs qui tournent hors des stories et produisent eux-mêmes le travail à faire. Issues #151 à #156, tirées de la vidéo Underscore_ « On ne paie plus les développeurs pour écrire du code ? » avec Quentin Adam (Clever Cloud, 2026-09-07). Décidé par le porteur le 2026-11-10 en cadrant ces issues : **le contrôle strict (compilateur au plus strict, lints en erreur) est le défaut d'un projet, qui n'y déroge que par une ADR** (#156) ; **le planner écrit les tests d'acceptation de la story**, que l'implémenteur ne modifie qu'avec une raison consignée que le relecteur juge, ce qui complète l'ADR-0012 sans la remplacer (#152) ; **l'audit planifié reste neutre sur le fournisseur** : un réglage liste des endpoints compatibles OpenAI, `—` veut dire Claude seul et le rapport le dit (#153) ; **l'échec d'un contrôle planifié devient de lui-même une story de correction** que `/po-drive` peut prendre, toutes les portes restant en place, ce qui remplace en partie la Law 7 (#154) ; M17 ne porte que ces six issues, les restes de M16 (#132, #134, #136, #137, #139, #143, #144) vont à un jalon à part ; cadrage seulement, sans `/po-drive`. Ce que la Law 7 garde : un constat de sécurité n'est jamais déposé seul, il va à la personne (ADR-0090), y compris quand il vient de l'audit ; pour cela, décidé par le porteur le même jour après la relecture des stories (`docs/reviews/stories-m17.md`), **un contrôle planifié se déclare sensible** (fuzzing, décodeurs d'entrée) : son échec n'est jamais déposé et va à la personne, et la sortie d'un contrôle non sensible est purgée de ses secrets avant tout dépôt (#154) ; pour l'audit, seuls ses constats de sécurité sont sensibles, ses autres constats sont déposés (réponse du porteur à la seconde relecture). Constat sur `main` (c5ad4ec) : `/po-architect` recopie `Typecheck` des réglages sans juger de sa rigueur (`method/commands/po-architect.md:57`) et aucun profil ne dit si son contrôle est strict (`method/templates/profile.md:24-35`) ; la doctrine de tests ne connaît que des tests par l'exemple (`method/skills/testing-doctrine/SKILL.md:17-25`) ; les tests d'une story sont écrits par celui qui écrit le code, le planner n'écrivant aucun fichier de test (`method/agents/planner.md:55`), et seul le relecteur les met à l'épreuve (étape *Bite*, `method/skills/review-antihallu/SKILL.md:44`) ; la lentille sécurité ne lit que le diff (`method/skills/review-lenses/SKILL.md:21`) et rien ne relit le dépôt entier ; seule une personne fait d'un constat une story (`method/AGENTS.md:125`, ADR-0090).

### s147-strict-checks-by-default — Le contrôle strict est le défaut d'un projet
**En tant que** porteur qui lance un projet avec Polype **je veux** que chaque profil dise ce qu'est le contrôle strict de sa base et que `/po-architect` le retienne par défaut **afin que** l'agent reçoive du compilateur et des lints une erreur précise dès qu'il se trompe, plutôt qu'à l'exécution.

- **Complexité** : 4 — risque : neuf dépôts d'origine à relire pour remplir les profils ; un profil qui ne peut être relu dit `not run`, et le plan peut dépasser dix tâches, auquel cas le planner propose de séparer les profils de la règle
- **Dépend de** : aucune
- **Surface** : command
- **Owns** : `method/templates/profile.md`, `bin/po-lint`, `boilerplates/*/profile.md`, `method/commands/po-architect.md`, `method/templates/architecture.md`, `docs/decisions/ADR-0097-le-controle-strict-par-defaut.md`, `tests/strict-checks-by-default.test.sh`

**Critères d'acceptation**
- [ ] `profile_declares_strictness` — `templates/profile.md` gagne une section `## Strictness` de trois lignes : `Strict check:` (une seule commande : le compilateur au plus strict et le linter, avertissements en erreurs), `Turned on by:` (le fichier et le réglage de la base qui l'activent) et `Passes at the commit profiled:` (`yes`, `no` ou `not run`) ; `bin/po-lint` refuse un profil sans cette section ou sans l'une des trois lignes.
- [ ] `every_profile_fills_strictness` — les neuf profils de `boilerplates/` portent la section, que `bin/po-lint` accepte ; une base sans contrôle strict possible écrit `—` sur les deux premières lignes, avec la raison en une phrase. Les valeurs viennent du dépôt d'origine au commit profilé, lu par l'implémenteur, et le relevé dit lesquelles ont été lues ; une commande que personne n'a lancée vaut `not run`, jamais `yes`.
- [ ] `architect_retains_strict` — à son étape 3, `/po-architect` rédige une ADR de projet « contrôle strict » qui retient le contrôle strict par défaut, avec sa commande, ses options classées comme les autres ; un projet ne garde un contrôle non strict que par cette ADR, qui en donne la raison (base héritée, outil absent pour ce langage).
- [ ] `strict_command_reaches_typecheck` — le contrôle strict passe par la commande `Typecheck`, sans nouveau réglage ; `/po-architect` ne modifie aucun réglage : il donne la commande à recopier dans `Typecheck` et demande à la personne de le faire, comme il le fait déjà pour une commande différente ; `templates/architecture.md` la cite.
- [ ] `strict_switch_is_a_story` — une base dont le contrôle strict ne passe pas encore (`no`), ou dont on ne sait pas s'il passe (`not run`), n'est pas modifiée par `/po-architect` : `docs/architecture.md` nomme le passage au strict comme une story à écrire, et la commande stricte n'entre dans `Typecheck` qu'une fois cette story livrée.
- [ ] `adr_records_strict_default` — l'ADR-0097 dit : strict par défaut, dérogation par ADR de projet ; options écartées, dans leur ordre : l'imposer sans exception (bloque un projet repris sur une base héritée), le recommander seulement (de la prose qu'un agent peut ignorer), un réglage `Lint` à part (un réglage de plus que chaque commande doit lire, alors que l'étape du contrôle de type, une fois après la dernière modification, est celle où un lint bloquant doit tourner).

**Notes pour l'agent** : le compilateur strict est la boucle de rétroaction la plus courte qu'un agent puisse avoir (#156). Points de départ : `rust-cli` déclare `cargo check --workspace --all-targets` (`boilerplates/rust-cli/profile.md:25`) ; `expo` a déjà un TypeScript strict (`boilerplates/expo/profile.md:46`) ; `next-forge` n'a pas de contrôle de type à la racine (`boilerplates/next-forge/profile.md:108`) ; `flutter analyze` s'appuie sur `flutter_lints` (`boilerplates/flutter/profile.md:46`). Aucune commande n'est inventée : ce qui n'a pas été lu dans le dépôt d'origine vaut `not run`. Tests hors `Owns` qui figent les profils, `po-lint` et `/po-architect`, et gardent leurs phrases : `tests/profile.test.sh`, `tests/profiles-hold.test.sh`, `tests/lint.test.sh`, `tests/*-profile.test.sh`, `tests/native-profiles.test.sh`, `tests/architect.test.sh`, `tests/capability-bricks.test.sh`.

### s148-tests-beyond-examples — La doctrine de tests va au-delà des exemples
**En tant que** porteur **je veux** que la doctrine dise quand une story prend un test par propriétés, du fuzzing ou une simulation déterministe avec pannes, et qu'elle préfère le vrai service à un mock écrit à la main **afin que** les défauts qu'aucun exemple choisi à la main ne montre soient cherchés là où ils se cachent.

- **Complexité** : 2
- **Dépend de** : aucune
- **Surface** : —
- **Owns** : `method/skills/testing-doctrine/SKILL.md`, `tests/tests-beyond-examples.test.sh`

**Critères d'acceptation**
- [ ] `doctrine_says_when_property_tests` — la doctrine nomme le test par propriétés : une règle vraie pour toute entrée d'un domaine (aller-retour d'un encodage, invariant d'un calcul, idempotence), pour la logique pure, les parseurs et les sérialiseurs ; il compte pour un test dans `Test budget`.
- [ ] `doctrine_says_when_fuzzing` — elle nomme le fuzzing pour le code qui décode une entrée venue du dehors (protocole, format de fichier, requête) ; une story n'en lance qu'une courte campagne à graine fixe, qui se rejoue.
- [ ] `doctrine_says_when_simulation` — elle nomme la simulation déterministe avec injection de pannes (paquets perdus, nœud redémarré, horloge décalée, capteur muet) pour un comportement distribué, temporel ou robotique ; une graine rend chaque échec rejouable, et un échec qui ne se rejoue pas n'est pas un résultat.
- [ ] `real_service_over_handwritten_mock` — un test de persistance ou d'adaptateur parle au vrai service (un conteneur ou une instance locale) quand le projet sait le démarrer ; un mock écrit à la main d'un service que le projet possède demande une phrase dans la stratégie de test du plan, faute de quoi le relecteur le relève sous le sixième des « tests qui ne prouvent rien ».
- [ ] `long_campaigns_run_outside_stories` — le tableau « When does each check run? » gagne une ligne : une longue campagne de fuzzing ou de simulation tourne hors du cycle d'une story, planifiée, et son échec va dans `Issue tracker` (Law 7) ; la story n'en lance que la version courte.

**Notes pour l'agent** : la doctrine nomme le genre de test, jamais une bibliothèque : celle-ci vient du profil ou des conventions du projet (proptest, Hypothesis, fast-check…). La simulation suit le modèle du simulateur de FoundationDB cité par #151. Les sections existantes (couches, « Four things to cut », « No red-first while implementing », « Tests that prove nothing ») gardent leur texte, que figent `tests/planner.test.sh`, `tests/plan.test.sh`, `tests/execute.test.sh`, `tests/review.test.sh` et `tests/run-ledger.test.sh`.

### s149-planner-writes-the-oracle — Le planner écrit les tests d'acceptation de la story
**En tant que** porteur **je veux** que les tests d'acceptation d'une story soient écrits par le planner, depuis ses critères, avant que l'implémenteur n'écrive le code **afin que** le code soit jugé par des tests dont son auteur ne partage pas les angles morts.

- **Complexité** : 4 — risque : le planner écrit des tests contre une interface qui n'existe pas encore ; ils visent le contrat que fixent les tâches du plan, jamais un détail interne. Le plan peut dépasser dix tâches : la coupe naturelle sépare l'oracle et son écriture du câblage du travail attendu (Law 4 et les vérifications d'état), et le planner la propose plutôt qu'un plan trop long
- **Dépend de** : s148-tests-beyond-examples
- **Surface** : —
- **Owns** : `method/agents/planner.md`, `method/commands/po-plan.md`, `method/commands/po-flow.md`, `method/commands/po-execute.md`, `method/commands/po-orchestrator.md`, `method/templates/plan.md`, `method/templates/plan-flow.md`, `method/agents/implementer.md`, `method/templates/verification-record.md`, `method/skills/testing-doctrine/SKILL.md`, `method/AGENTS.md`, `AGENTS.local.md`, `docs/decisions/ADR-0098-le-planner-ecrit-l-oracle-d-acceptation.md`, `tests/planner-writes-the-oracle.test.sh`

**Critères d'acceptation**
- [ ] `plan_lists_its_oracle` — `templates/plan.md` et `templates/plan-flow.md` gagnent `## Acceptance tests` : les fichiers d'oracle, chacun avec sa somme `cksum` telle que le planner l'a laissé, puis une ligne par critère d'acceptation avec le nom du test qui le tient ; un test par critère qui se vérifie par un test, comptés dans `Test budget` ; `—` avec la raison pour une story dont aucun critère ne se vérifie par un test (purement visuelle), ou pour une story d'exploration, que sa mesure juge (s155).
- [ ] `oracle_lives_in_its_own_files` — l'oracle vit dans des fichiers à lui, que le planner écrit et que l'implémenteur ne change qu'aux conditions de `implementer_keeps_the_oracle` ; ces fichiers sont dans l'`Owns` de la story (sinon `po-bounds` et la revue les refusent), et un oracle qu'il faudrait écrire hors de l'`Owns` est signalé par le planner comme un trou de la story au lieu d'être écrit ; les tests que l'implémenteur ajoute vont dans d'autres fichiers, si bien qu'ils ne changent aucune somme. Dans Polype, la convention de `AGENTS.local.md` le dit : les fonctions des critères d'une story vont dans `tests/<slug>.oracle.test.sh`, les autres tests dans `tests/<slug>.test.sh`, qui n'existe que s'il porte au moins un test (`tests/run.sh:15` fait échouer un fichier sans fonction `test_`).
- [ ] `planner_writes_oracle_files` — le planner, et `/po-plan` et `/po-flow` quand ils écrivent le plan dans leur propre contexte, écrivent ces fichiers de test et aucun autre fichier de test : la section `## Limits` de `method/agents/planner.md` le dit, et dit que chaque test passe par l'interface que les tâches du plan fixent.
- [ ] `oracle_files_are_expected_work` — les fichiers que nomme `## Acceptance tests` comptent comme travail non commité légitime : la Law 4 les ajoute à sa liste (`method/AGENTS.md:105`), la vérification d'état du planner les accepte quand il reprend une voie (`method/agents/planner.md:22`), et l'implémenteur (`method/agents/implementer.md:24`), `/po-execute` et `/po-orchestrator` les comptent parmi les changements attendus ; l'implémenteur les commite avec la story.
- [ ] `implementer_keeps_the_oracle` — l'implémenteur ne modifie un fichier d'oracle qu'en ajoutant au relevé, sous une section `## Oracle changes` de `templates/verification-record.md`, une ligne qui nomme le fichier, ce qui change et pourquoi ; un oracle qui lui semble faux sans raison qu'il puisse écrire est un arrêt de la tâche, signalé. Il ne réécrit jamais un oracle pour le faire passer.
- [ ] `oracle_runs_with_its_task` — un test d'oracle tourne avec la tâche qui le rend passable, comme tout test de tâche ; personne ne le lance rouge d'abord : la section « No red-first while implementing » de la doctrine reste et dit que l'oracle vient d'un autre contexte que le code.
- [ ] `adr_records_the_oracle` — l'ADR-0098 dit : le planner écrit l'oracle d'acceptation, dans des fichiers à lui, l'implémenteur ne le change qu'avec une raison consignée que le relecteur juge, et le contrôle des sommes (s150) protège de l'erreur, pas d'un implémenteur qui réécrirait aussi la somme, comme l'ADR-0052 le dit de `po-bounds` ; elle complète l'ADR-0012 sans la remplacer (aucun lien `supersedes`) ; options écartées : un agent oracle dédié (une étape et un contexte de plus à chaque story), le relecteur en boîte noire (un trou découvert seulement en revue, au prix d'une boucle de correction), ne rien changer (l'étape *Bite* trouve une règle mal testée, pas un critère mal compris par celui qui a écrit le code et ses tests).

**Notes pour l'agent** : dans Polype lui-même, le nom d'un critère est déjà le nom de sa fonction de test (`AGENTS.local.md`, `## Conventions`) : l'oracle d'une story de Polype, ce sont ces fonctions-là, dans leur fichier `.oracle.test.sh` ; `tests/run.sh` lance tout `tests/*.test.sh`, donc les deux fichiers. Une story de Polype peut avoir jusqu'à sept critères, d'où un test par critère plutôt qu'un plafond fixe. Les phrases que `/po-execute` (`:50`) et `/po-orchestrator` (`:62`) donnent sur le travail attendu d'un design servent de modèle. La somme suit le format de `cksum` déjà utilisé par `bin/polype`. Le planner n'a pas de hook `po-bounds` ; ce qu'il écrit reste vérifié par la vérification d'état (`method/agents/planner.md:22`) et par la ligne des changements attendus de l'implémenteur (`method/agents/implementer.md:24`). Tests hors `Owns` qui figent ces fichiers et gardent leurs phrases : `tests/planner.test.sh`, `tests/plan.test.sh`, `tests/flow.test.sh`, `tests/execute.test.sh`, `tests/escalation-contract.test.sh`, `tests/reuse-ladder.test.sh`, `tests/run-ledger.test.sh`, `tests/bounds.test.sh`. Le contrôle des sommes est s150.

### s150-oracle-intact-gate — Un oracle modifié en silence bloque la revue
**En tant que** porteur **je veux** qu'un contrôle compare les tests d'oracle livrés à ceux que le planner a laissés, et que le relecteur traite un changement non consigné comme un test supprimé **afin qu'un** oracle changé par erreur ou sans le dire ne passe pas inaperçu.

- **Complexité** : 3
- **Dépend de** : s149-planner-writes-the-oracle
- **Surface** : command
- **Owns** : `method/hooks/po-gate.sh`, `method/skills/review-antihallu/SKILL.md`, `tests/oracle-intact-gate.test.sh`, `tests/oracle-intact-gate.oracle.test.sh`

**Critères d'acceptation**
- [ ] `gate_compares_oracle_sums` — `po-gate oracle-intact <id>` lit `## Acceptance tests` du plan de la story et compare chaque fichier, sur `story/<id>`, à sa somme : toutes égales → sortie 0 ; un fichier différent ou absent que `## Oracle changes` du relevé ne nomme pas → sortie 1, en le nommant ; un fichier nommé → sortie 0, avec une ligne par changement à juger.
- [ ] `gate_without_oracle_says_so` — un plan sans section `## Acceptance tests` (écrit avant M17), ou qui y écrit `—` → sortie 0 et une ligne qui le dit ; un plan, une branche ou un relevé illisible → sortie 2, comme les autres contrôles de `po-gate`. L'usage du contrôle, dans l'en-tête de `po-gate.sh`, dit qu'il protège de l'erreur et non d'un implémenteur qui réécrirait aussi la somme, celle-ci vivant dans le plan qu'il commite (ADR-0052, ADR-0098).
- [ ] `review_runs_the_oracle_gate` — l'étape 4 de `review-antihallu` lance ce contrôle avant de lire un test : sortie 1 → constat **critical** (un oracle changé sans le dire vaut un fichier de test supprimé sans raison) ; chaque changement consigné est jugé, et celui qui affaiblit le critère que le test tient est **major** au moins ; sortie 2 → revue bloquée, le message du contrôle en `Failure cause:`.
- [ ] `bite_starts_with_the_oracle` — l'étape *Bite* choisit d'abord, parmi les règles dont la story dépend, celles que tiennent les tests d'oracle.

**Notes pour l'agent** : le modèle est `floor_guard` (`method/hooks/po-gate.sh:375`), son usage dans l'en-tête (`:20`) et son aiguillage (`:518`) ; même code de sortie 2 par `unverifiable`. Tests hors `Owns` qui figent `po-gate.sh` et `review-antihallu` et gardent leurs phrases : `tests/gate.test.sh`, `tests/floor-guard.test.sh`, `tests/review.test.sh`, `tests/review-lenses.test.sh`, `tests/ownership.test.sh`, `tests/owns-overlap.test.sh`, `tests/session-and-gate-checks.test.sh`.

### s151-failing-check-files-an-issue — Un contrôle planifié qui échoue dépose une issue
**En tant que** porteur **je veux** qu'un contrôle long lancé hors des stories (simulation, fuzzing, suite complète de la nuit) dépose une issue reproductible quand il échoue, sans doublon **afin qu'aucun** échec ne reste dans un journal que personne ne lit.

- **Complexité** : 4 — risque : un secret ou une faille qui part sur un tracker public ; le tri par sensibilité et la purge des secrets passent avant tout dépôt
- **Dépend de** : s150-oracle-intact-gate
- **Surface** : command
- **Owns** : `method/hooks/po-intake.sh`, `method/hooks/po-gate.sh`, `method/AGENTS.md`, `method/skills/testing-doctrine/SKILL.md`, `docs/harnais.md`, `tests/failing-check-files-an-issue.test.sh`, `tests/failing-check-files-an-issue.oracle.test.sh`

**Critères d'acceptation**
- [ ] `intake_passes_through` — `po-intake --label <nom> [--sensitive] -- '<commande>'` lance la commande depuis la racine du dépôt, laisse passer sa sortie et son code de sortie ; une sortie 0 ne dépose rien.
- [ ] `sensitive_failure_goes_to_the_person` — l'échec d'un contrôle lancé avec `--sensitive` n'est jamais déposé : le rapport est écrit dans un fichier hors du dépôt, dont `po-intake` donne le chemin sur la sortie d'erreur, et va à la personne (Law 7, ADR-0090) ; la ligne de la doctrine de tests sur les longues campagnes dit qu'une campagne de fuzzing, ou tout contrôle qui exerce un décodeur d'entrée venue du dehors, tourne avec `--sensitive`.
- [ ] `failure_files_one_issue` — l'échec d'un contrôle non sensible dépose dans `Issue tracker` une issue titrée `<nom>: <empreinte>`, dont le corps donne la commande, le commit, le code de sortie et la fin de la sortie (200 lignes au plus) purgée de ses secrets ; l'empreinte est le nom du premier test en échec : le texte qui suit `not ok <n> ` (TAP), qui suit `FAILED ` (pytest), qui précède ` ... FAILED` sur une ligne `test <nom> ... FAILED` (cargo), ou qui suit `  FAIL  ` (`tests/run.sh` de Polype) ; aucune de ces formes → le code de sortie ; le texte passe par un fichier, jamais par un argument du shell (Law 7).
- [ ] `secrets_are_scrubbed` — avant tout dépôt, la sortie passe par un mode `po-gate redact <fichier>` qui applique le même repérage que le contrôle des secrets (`SECRET_PATTERNS`, `po-gate.sh:224-234`, avec la longueur minimale et la limite de mot de `hit()`, `:260-268`), jamais une copie de la liste ou de la règle : chaque chaîne repérée devient `[redacted]`, et une ligne `private-key` efface tout le bloc, de `BEGIN` jusqu'à sa ligne `END`, ou jusqu'à la fin de la sortie sans `END` ; `po-intake` y ajoute chaque valeur d'au moins 8 caractères d'une variable d'environnement dont le nom contient `TOKEN`, `KEY`, `SECRET` ou `PASSWORD`. Le test dépose une sortie qui porte un bloc PEM complet, un jeton GitHub et une telle valeur, et vérifie qu'aucun n'en reste, tandis que `desk_live_` suivi de 24 caractères reste tel quel.
- [ ] `same_failure_not_filed_twice` — un échec dont le titre a déjà une issue ouverte y ajoute un commentaire (commit, date) au lieu d'ouvrir une seconde issue.
- [ ] `tracker_values_hold` — avec `github`, le dépôt passe par `gh issue create` comme l'étape 3 de `/po-ship` (`method/commands/po-ship.md:95`, aucun appel HTTP direct), avec l'étiquette `polype-intake`, créée par `gh label create` quand elle manque ; avec `taskwarrior`, une tâche `+issue +polype-intake` dans le projet que `/po-ship` calcule ; avec `—`, rien n'est déposé : le rapport va sur la sortie d'erreur et le code de sortie reste celui de la commande.
- [ ] `rules_name_po_intake` — `## Installed files` de `method/AGENTS.md` nomme `po-intake` et ce qu'il fait (`tests/structure.test.sh:73-83`), et la Law 7 dit que `po-intake` dépose, comme le chef de projet, l'échec d'un contrôle planifié non sensible ; `docs/harnais.md`, en français, en donne deux exemples de planification : un workflow planifié de forge, et un timer systemd ou une ligne cron.

**Notes pour l'agent** : l'installeur pose `method/hooks/` entier par les paires `method/hooks:.polype/hooks` (`bin/polype:135`, `:138`), si bien que `po-intake` arrive dans `.polype/hooks/` sans changer `bin/polype`. La liste des formes de secrets existe déjà, dans `po-gate.sh` (`SECRET_PATTERNS`, avec sa règle de limite de mot), et la Law 6 s'y appuie (`method/AGENTS.md:121`) : la purge réutilise son repérage par un mode de `po-gate`, sans dupliquer la liste ni la règle. Tests hors `Owns` qui figent `po-gate.sh` et gardent leurs phrases : `tests/gate.test.sh` (dont le contrôle des secrets), `tests/session-and-gate-checks.test.sh`, `tests/floor-guard.test.sh`. Le dépôt et la recherche de doublon suivent l'étape 3 de `/po-ship` (`po-ship.md:93-97`). `docs/harnais.md` est un document du dépôt Polype, en français, sous `docs/`.

### s152-intake-issue-becomes-a-story — L'échec d'un contrôle planifié devient une story de correction
**En tant que** porteur **je veux** qu'une issue déposée par `po-intake` devienne une story de correction que `/po-drive` peut prendre, sans que j'aie à la cadrer **afin que** la boucle de l'échec à la correction se ferme seule, toutes les portes restant en place.

- **Complexité** : 4 — risque : un `Owns` déduit d'un échec peut être trop large ou trop étroit ; la relecture des stories tourne avant tout atterrissage
- **Dépend de** : s151-failing-check-files-an-issue
- **Surface** : command
- **Owns** : `method/commands/po-intake.md`, `method/commands/po-help.md`, `method/AGENTS.md`, `method/skills/agentic-stories/SKILL.md`, `method/skills/stories-review/SKILL.md`, `method/agents/stories-reviewer.md`, `docs/harnais.md`, `docs/decisions/ADR-0099-l-echec-d-un-controle-planifie-devient-une-story.md`, `docs/decisions/ADR-0090-tout-ce-qui-est-a-traiter-devient-une-issue.md`, `tests/intake-issue-becomes-a-story.test.sh`, `tests/intake-issue-becomes-a-story.oracle.test.sh`

**Critères d'acceptation**
- [ ] `intake_writes_defect_stories` — `/po-intake` lit les issues ouvertes étiquetées `polype-intake` qu'aucune story de `docs/stories.md` ne cite et écrit pour chacune une story de correction : une ligne `Fixes` (`Corrige` dans un fichier français) qui nomme l'issue, des critères qui disent le comportement faux et l'attendu, la reproduction de l'issue dans les notes, un `Owns` tiré des chemins que l'échec met en cause ; les ids suivent les stories existantes.
- [ ] `intake_stories_reviewed_first` — le `stories-reviewer` reçoit les seules stories nouvelles, chacune avec son issue pour source de périmètre à la place du PRD ou du brief : le skill `stories-review` et `method/agents/stories-reviewer.md` disent ce mode, où une story de correction se juge sur son issue, sans contrôle de couverture du reste du fichier, si bien qu'il tourne aussi avec `Entry mode: —` ; son verdict est écrit dans `docs/reviews/stories-intake-<horodatage>.md` (date et heure à la minute, si bien que deux passages d'un même jour ne se confondent pas), fichier que la Law 6 ajoute à ses fichiers de cadrage, et un verdict qui ne les dit pas prêtes arrête la commande et porte les issues concernées à la personne, sans rien faire atterrir.
- [ ] `intake_lands_as_framing` — les stories prêtes atterrissent sur `Target branch` comme un cadrage (`## Landing the framing` de `/po-setup`), sur une branche `framing/intake-<horodatage>`, dont la description cite les issues sans mot-clé de fermeture ; `Ship confirmation` s'y applique comme à toute fusion.
- [ ] `security_issue_goes_to_the_person` — une issue `polype-intake` qui touche la sécurité ne devient pas une story : `/po-intake` la porte à la personne (ADR-0090).
- [ ] `law_7_names_the_exception` — la Law 7 garde « only a person turns a finding into a story » et y ajoute la seule exception : l'échec d'un contrôle planifié, déposé par `po-intake`, que `/po-intake` transforme ; la section « Defect stories » d'`agentic-stories` le dit aussi ; `po-help.md` liste `/po-intake` ; `docs/harnais.md` montre comment planifier `/po-intake` après les contrôles.
- [ ] `adr_records_the_intake_loop` — l'ADR-0099 dit la règle et ses options écartées : l'issue seule, cadrée par une personne au jalon suivant (la boucle reste lente), une autonomie selon la sévérité (une échelle de plus à tenir) ; elle remplace l'ADR-0090 sur ce seul point, dont seul le `superseded-by` change.

**Notes pour l'agent** : une story écrite par `/po-intake` porte `Fixes`, donc la voie complète et le skill `diagnostic` : la cause est prouvée avant tout correctif, et trois hypothèses écartées la rendent à un humain (ADR-0070). Les commandes de cadrage qui lancent déjà le `stories-reviewer` (`method/commands/po-stories-review.md`) et l'atterrissage d'un cadrage (`method/commands/po-setup.md`, `## Landing the framing`) sont à citer, pas à réécrire. Tests hors `Owns` qui figent la Law 7 et `agentic-stories` et gardent leurs phrases : `tests/everything-in-issues.test.sh`, `tests/defect-and-routing-paths.test.sh`, `tests/commands-and-texts.test.sh`.

## M18 — La QA va jusqu'au bout de sa marche

Objectif : qu'une marche de QA lancée par `/po-qa`, `/po-drive` ou `/po-orchestrator` aboutisse à un rapport committé au lieu de s'arrêter sur le harnais. Issues #148 (doublon #88) et #167, constatées sur nacre, clione et lagon, où elles bloquent la voie QA de `s01-page-projet`. Décidé par le porteur le 2026-11-10 en les confiant au chef de projet : **le subagent `qa` rend son rapport en texte et le contexte coordinateur l'écrit tel quel dans `docs/qa/<id>/report.md` avant le commit de preuve**, comme `/po-drive` le fait déjà pour la revue, par Bash ; `qa` garde l'écriture de ses fichiers de preuve (#148, proposition de l'issue). `po-bounds` laisse passer en mode qa les verbes git qui ne font que lire, comme `check-ignore` (#167). Ces deux stories ne touchent aucun chemin de s149, en vol : `/po-orchestrator` applique `/po-qa` tel qu'écrit et n'est donc pas modifié.

### s156-qa-report-returned-as-text — Le rapport de QA revient en texte et le coordinateur l'écrit
**En tant que** porteur **je veux** que le subagent `qa` rende son rapport dans sa réponse et que le contexte qui l'a lancé l'écrive tel quel dans `docs/qa/<id>/report.md` **afin que** la marche ne s'arrête plus sur le refus du harnais (« Subagents should return findings as text, not write report files ») et que le commit de preuve ait toujours son rapport.

- **Complexité** : 3 — risque : un coordinateur qui réécrit ou résume le rapport au lieu de le transcrire ; la transcription est mot pour mot, comme celle d'une revue
- **Dépend de** : aucune
- **Surface** : —
- **Corrige** : issues #148 et #88, son doublon (`Issue tracker: github`)
- **Owns** : `method/agents/qa.md`, `method/commands/po-qa.md`, `method/commands/po-drive.md`, `method/skills/qa-drivers/SKILL.md`, `method/templates/qa.md`, `docs/decisions/ADR-0102-le-rapport-de-qa-revient-en-texte.md`, `docs/decisions/ADR-0029-po-qa-committe-les-preuves-qa.md`, `tests/qa-report-returned-as-text.test.sh`, `tests/qa-report-returned-as-text.oracle.test.sh`, `tests/qa.test.sh`, `tests/qa-drivers.test.sh`, `tests/qa-evidence-set-aside.test.sh`, `tests/qa-gate.test.sh`, `tests/qa-fleet.test.sh`, `tests/qa-contract-holds.test.sh`, `tests/leftovers.test.sh`

**Critères d'acceptation**
- [ ] `qa_returns_its_report` — `method/agents/qa.md` ne fait plus écrire `docs/qa/<id>/report.md` au subagent : sa réponse finale est le rapport entier, rempli sur `templates/qa.md`, avec sa ligne `QA status:` (`complete` ou `blocked`) et son `Tree:` ; partout où l'agent « écrit le rapport » (`blocked` pour un pilote manquant, une surface sans pilote, des chemins hors `docs/qa/<id>/`), il le rend. Il continue d'écrire ses fichiers de preuve sous `docs/qa/<id>/`, et n'écrit jamais le rapport par un autre chemin (Bash, outil hérité) : ce serait contourner un refus. `## Your final message` de `method/agents/qa.md` et `## Report` de `method/commands/po-qa.md` le disent : la réponse est le rapport, et `/po-qa` relaie le chemin où il l'a écrit.
- [ ] `po_qa_records_the_report` — `/po-qa` écrit la réponse du subagent, entière et mot pour mot, dans `docs/qa/<id>/report.md` du worktree, par Bash, avant le commit de preuve et seulement quand elle porte une ligne `QA status:` ; le texte passe par un heredoc entre quotes (`<<'…'`) dont le délimiteur n'apparaît pas dans le rapport, jamais dans un argument du shell (Law 7), puisqu'un rapport cite des sorties de commande ; il la transcrit, il n'en est pas l'auteur (aucun constat ajouté, adouci ou retiré). Une réponse sans ligne `QA status:` → aucun rapport, aucun commit, la raison du subagent est relayée. La commande garde son absence de Write et d'Edit ; son Bash sert ces deux usages et aucun autre.
- [ ] `drive_records_the_report` — l'étape QA de `/po-drive` (`method/commands/po-drive.md:107`) transcrit le rapport rendu de la même façon, par le même heredoc, dans le worktree de la voie, avant le commit de preuve, à côté de la phrase qui fait de même pour la revue (`:136`) ; « pas de rapport » y veut dire une réponse sans ligne `QA status:`.
- [ ] `qa_report_path_stays` — le rapport committé reste `docs/qa/<id>/report.md` et le commit de preuve reste `<id>: QA evidence`, si bien que `po-gate qa-current` et la revue le lisent sans changement ; une marche `blocked` est transcrite et committée comme avant.
- [ ] `adr_records_report_as_text` — l'ADR-0102 dit la règle ; elle remplace l'ADR-0029 sur un seul point, la portée du Bash de `/po-qa` (un usage, le commit, devient deux : la transcription et le commit), et l'ADR-0029 gagne `superseded-by: ADR-0102` sans changer de statut ni de corps ; elle complète l'ADR-0034 sans la remplacer. Options écartées : laisser l'agent écrire le rapport par Bash (contourne un refus du harnais, et deux chemins différents ont déjà été suivis, #148) ; donner Write à `/po-qa` comme à `/po-review` (une commande sans Write ni Edit ne peut éditer aucun fichier du dépôt, et `/po-drive` transcrit déjà la revue par Bash).

**Notes pour l'agent** : modèle de transcription, `method/commands/po-drive.md:136` (par Bash) ; `method/commands/po-review.md` (`## Recording`) transcrit par Write. L'oracle : si s149 a atterri avant le plan, les fonctions des critères vont dans `tests/qa-report-returned-as-text.oracle.test.sh`, sinon dans `tests/qa-report-returned-as-text.test.sh`. `method/skills/qa-drivers/SKILL.md` n'est à changer que s'il dit qui écrit le rapport. À vérifier par la recherche : le refus du harnais vise-t-il aussi les transcriptions `.txt` que `qa-drivers/scenarios.md:30` demande (les PNG de lagon sont passés) ; si oui, c'est un trou de la story à signaler, pas à combler en douce. Reproductions dans les commentaires de #148 (nacre 2026-10-22, clione 2026-10-24, lagon 2026-11-10). `/po-orchestrator` (`method/commands/po-orchestrator.md:67`) applique `/po-qa` tel qu'écrit et appartient à s149 : il n'est pas touché ; la transcription vit dans `## The evidence commit` de `/po-qa`, si bien que « as written » l'inclut, et la reformulation de sa liste d'étapes est déposée en issue pour après s149. Au livrage, #88 est fermée comme doublon de #148.

### s157-qa-reads-ignore-rules — po-bounds laisse la QA lire les règles d'ignorance de git
**En tant que** porteur **je veux** que `po-bounds` accepte en mode qa les verbes git qui ne font que lire, comme `git check-ignore` **afin qu'une** vérification inoffensive ne soit plus un refus, donc un arrêt qui laisse la marche à moitié faite.

- **Complexité** : 1
- **Dépend de** : aucune
- **Surface** : —
- **Corrige** : issue #167 (`Issue tracker: github`)
- **Owns** : `method/hooks/po-bounds.sh`, `docs/decisions/ADR-0103-la-qa-lit-les-regles-d-ignorance-de-git.md`, `docs/decisions/ADR-0026-qa-herite-le-navigateur-et-lit-git-par-liste-blanche.md`, `tests/qa-reads-ignore-rules.test.sh`, `tests/qa-reads-ignore-rules.oracle.test.sh`

**Critères d'acceptation**
- [ ] `qa_allows_check_ignore` — en mode qa, `git -C <worktree> check-ignore -v site/dist site/.astro` passe `po-bounds` (sortie 0) ; le test échoue quand `check-ignore` est retiré de la liste des verbes de lecture (`QA_GIT_VERBS`, `method/hooks/po-bounds.sh:319`).
- [ ] `qa_allows_check_attr` — `git check-attr` passe de même, étant lui aussi en lecture seule.
- [ ] `qa_still_refuses_writing_verbs` — en mode qa, un verbe qui écrit (`git add`, `git commit`) reste refusé avec le message « forbidden in mode qa, which runs reading verbs only », et la liste de `QA_GIT_VERBS` est celle de l'ADR-0103, que le relecteur partage en zone story.
- [ ] `adr_widens_the_qa_allowlist` — l'ADR-0103 ajoute `check-ignore` et `check-attr` à la liste de l'ADR-0026, dit que le relecteur les reçoit aussi (ADR-0047, ADR-0051), et remplace l'ADR-0026 sur ce seul point : l'ADR-0026 gagne `superseded-by: ADR-0103` sans changer de statut ni de corps. Option écartée : laisser la QA reformuler (ADR-0026:33), qui a coûté la marche de lagon, un refus étant un arrêt.

**Notes pour l'agent** : reproduction dans #167 (lagon, 2026-11-10, `git check-ignore -v site/dist site/.astro`). Le relecteur partage `QA_GIT_VERBS` en zone story : il y gagne les mêmes verbes, tous en lecture. Tests hors `Owns` qui figent `po-bounds.sh` et gardent leurs phrases : `tests/bounds.test.sh`, `tests/bounds-messages.test.sh`. L'oracle : si s149 a atterri avant le plan, les fonctions des critères vont dans `tests/qa-reads-ignore-rules.oracle.test.sh`, sinon dans `tests/qa-reads-ignore-rules.test.sh`.

## M19 — Une revue consignée porte toujours son en-tête

Objectif : qu'aucune revue consignée ne casse plus `main` faute de sa ligne de liens. Issue #169, après #168 (revue de s147, 2026-11-10) et la même casse sur la revue de s156 (2026-11-11), chaque fois réparées à la main par un quick fix (#170, #187). Décidé par le porteur le 2026-11-11, contre « insérer la ligne seulement si elle manque » et « refuser la revue et arrêter la voie » : **celui qui consigne la revue écrit lui-même l'en-tête du fichier — le titre et la ligne de liens de `templates/review.md` — puis la réponse du relecteur, mot pour mot, en dessous** ; l'en-tête n'est pas un jugement, le verdict reste transcrit tel quel. Passe avant s151, qui reprend ensuite la suite de M17.

### s158-review-header-recorded — Celui qui consigne une revue en écrit l'en-tête
**En tant que** porteur **je veux** que le contexte qui consigne une revue écrive le titre et la ligne de liens du gabarit avant la réponse du relecteur **afin qu'une** revue livrée ne fasse plus échouer `tests/artifact-links-backfill.test.sh` sur `main`, quel que soit ce que le relecteur a recopié du gabarit.

- **Complexité** : 2
- **Dépend de** : aucune
- **Surface** : —
- **Corrige** : issue #169 (`Issue tracker: github`)
- **Owns** : `method/commands/po-review.md`, `method/commands/po-drive.md`, `method/agents/reviewer.md`, `method/templates/review.md`, `docs/decisions/ADR-0104-celui-qui-consigne-une-revue-en-ecrit-l-en-tete.md`, `tests/review-header-recorded.oracle.test.sh`, `tests/review-header-recorded.test.sh`

**Critères d'acceptation**
- [ ] `recorder_writes_the_header` — `## Recording` de `/po-review` dit : toute première écriture de `docs/reviews/<id>.md` commence par le titre et la ligne de liens de `templates/review.md`, `<id>` remplacé, puis une ligne vide, puis le corps, quel qu'il soit — la réponse du relecteur, entière et mot pour mot, ou le rapport `blocked` que la commande compose elle-même quand le subagent échoue, expire ou répond sans ses deux lignes de verdict (`po-review.md:41`) ; un fichier qui existe déjà (boucle de correction, nouvelle demande après `findings-shape`, rapport `blocked` composé par la commande) garde son en-tête et ne reçoit que le nouveau bloc à la suite. Un lien dont la cible n'existe pas dans le worktree est retiré de la ligne, jamais inventé.
- [ ] `drive_writes_the_header` — `/po-drive` (`## The verdict, and the fix runs`) consigne la revue de la même façon, par Bash, en écrivant l'en-tête puis la réponse transcrite, y compris quand la première écriture est un rapport `blocked` qu'il compose lui-même ; la phrase « You transcribe it, you do not author it » reste, et dit que l'en-tête vient du gabarit, pas du relecteur.
- [ ] `reviewer_answers_below_the_header` — `## Your answer` de `method/agents/reviewer.md` et l'invite de `/po-review` disent que la réponse commence sous l'en-tête : ni titre `# Review`, ni ligne de liens, que le contexte qui consigne écrit lui-même ; tout le reste de `templates/review.md`, hors la note qui suit la ligne de liens (`template_marks_the_header`), reste la forme de la réponse.
- [ ] `template_marks_the_header` — `templates/review.md` dit, sous sa ligne de liens, que ces deux lignes sont écrites par celui qui consigne la revue et non par le relecteur, sans changer la ligne de liens elle-même (`bin/po-link-artifacts` la lit telle quelle).
- [ ] `adr_records_the_header_rule` — l'ADR-0104 dit la règle et la place dans la règle de transcription : le verdict, les constats et les lignes de statut restent mot pour mot ; seul l'en-tête du fichier vient du gabarit. Options écartées, dans cet ordre : insérer la ligne seulement quand elle manque (une exception conditionnelle de plus à la transcription, qui dépend de ce que le relecteur a recopié) ; faire refuser la revue par `po-gate` et arrêter la voie (chaque oubli du relecteur devient un arrêt pour la personne, et une nouvelle réponse ajoutée à la suite ne répare pas la ligne sous le premier titre).

**Notes pour l'agent** : `po-gate findings-shape` lit le dernier bloc de verdict, pas l'en-tête : il n'est pas touché, pas plus que `po-gate.sh`, que s151 et s155 possèdent. `/po-orchestrator` et `/po-flow` consignent « as `/po-review` says » et n'ont pas à changer. Tests hors `Owns` qui figent ces fichiers et gardent leurs phrases : `tests/review.test.sh`, `tests/review-findings-shape.test.sh`, `tests/review-tree-gate.test.sh`, `tests/drive.test.sh`, `tests/artifact-links-backfill.test.sh`, `tests/artifact-link-templates.test.sh` ; la recherche les confirme. Les fonctions des critères vont dans `tests/review-header-recorded.oracle.test.sh`, écrit par le planner (s149) ; d'autres tests éventuels vont dans `tests/review-header-recorded.test.sh`. Aucune voie ne doit être en vol avec une revue déjà consignée sans en-tête quand s158 atterrit (aucune ne l'est au cadrage, 2026-11-11) ; une revue antérieure qui en manquerait se répare avec `bin/po-link-artifacts`, par la personne, jamais par une insertion conditionnelle.

## M20 — Le ménage : la suite tourne seule, les défauts connus se ferment

Objectif : remettre le dépôt d'aplomb avant de changer la façon dont Polype se pilote. Une analyse indépendante du projet, demandée par le porteur et rendue le 2026-11-12, conclut que les principes tiennent mais que l'exécution a dérivé : la confiance est prouvée sur le texte de la méthode et non sur le comportement des agents, le pilote est un automate en prose, il n'y a pas d'intégration continue, et la méthode a reçu deux fois plus de stories que les produits qu'elle sert ([`direction.md`](direction.md)). Décidé par le porteur le même jour : **le ménage d'abord, puis le développement reprend** ; **Polype offre une vraie interface à un agent extérieur**, son majordome vocal ne portant aucune intelligence (M21) ; **s153, s154 et s155 sont reportées** derrière M20 à M22, jusqu'à ce qu'un produit en ait besoin, parce qu'elles ajoutent des capteurs à une méthode dont les contrôles de base ne tournent encore sur aucune machine neutre. M20 ne porte que ce qui manque pour qu'une story livrée soit vérifiée sans dépendre de la machine de celui qui livre (#201), les défauts que des produits ont rencontrés (#87 sur lophelia, #149 sur clione, #184 sur lagon, avec #166) et les restes de revue qui touchent du code (#197, #134, et les restes de M16 et de M11 : #132, #137, #143, #144, #79). Les constats de pure rédaction sont fermés sans story. L'ADR-0105 est `accepted` depuis le 2026-11-13 (runners hébergés de la forge) : s159 se planifie comme les autres. Les cinq stories ont des `Owns` disjoints et peuvent tourner ensemble. Règle commune, jugée en revue : une story de M20 qui ajoute des mots à un fichier de `method/` en retire au moins autant du même fichier. **Tests des critères, tranché par le porteur le 2026-11-13** : le plan range chaque critère dans un de trois cas. Cas 1, un script lit déjà ce que le critère fixe (un réglage, un champ, un compte de mots, le comportement d'un script) : son test d'oracle porte là-dessus. Cas 2, la règle peut quitter la prose pour un script petit et local : la story écrit ce script et le teste ; sinon le critère passe au cas 3. Cas 3, la règle s'adresse à un modèle : pas de test d'oracle, aucun test de phrase, le relecteur la juge en lisant le fichier, et le plan l'inscrit comme candidate à un bras de contrôle de `po-eval` (#208). La recherche vérifie que la porte de l'oracle admet un critère sans test ; sinon la lane s'arrête et va au porteur.

### s159-ci-on-every-pr — La suite complète tourne sur chaque pull request
**En tant que** porteur **je veux** que la suite complète tourne sur chaque pull request et que `/po-ship` ne fusionne que si elle passe sur le commit d'atterrissage **afin qu'aucun** fichier, y compris sous `docs/`, ne rende plus `main` rouge sans que personne l'ait vu.

- **Complexité** : 4 — risque : `/po-ship` attend désormais les contrôles de la forge, sur trois forges et avec un délai ; un projet dont `AGENTS.local.md` n'a pas encore le réglage ne doit pas voir son prochain ship changer
- **Dépend de** : aucune
- **Surface** : command
- **Corrige** : issue #201 (`Issue tracker: github`), après #168 et #187
- **Owns** : `.github/workflows/`, `bin/po-ci`, `docs/ci.md`, `method/commands/po-ship.md`, `method/templates/agents-local.md`, `AGENTS.local.md`, `tests/ci-on-every-pr.oracle.test.sh`, `tests/ci-on-every-pr.test.sh`

**Critères d'acceptation**
- [ ] `ci_entry_runs_the_suite` — `bin/po-ci` lance la commande `Test` du projet depuis la racine, laisse passer sa sortie et sort avec son code ; il ne lit aucune variable propre à une forge et ne lance jamais `po-eval`.
- [ ] `workflow_only_calls_the_entry` — le workflow se déclenche sur chaque pull request et sur chaque poussée vers `Target branch`, installe `jq` et n'a qu'une étape de contrôle, qui appelle `bin/po-ci` ; il n'accorde aucun droit d'écriture au jeton de la forge.
- [ ] `setting_declares_forge_checks` — `templates/agents-local.md` gagne `Forge checks:`, qui vaut `required` ou `—` ; `AGENTS.local.md` de ce dépôt le pose à `required`.
- [ ] `ship_waits_for_green_checks` — avec `Forge checks: required` et `Merge mode: pr`, `/po-ship` attend les contrôles de la forge sur le commit d'atterrissage et ne fusionne que s'ils passent tous ; un contrôle rouge, ou aucun contrôle au bout du délai que la commande dit, arrête le ship et va à la personne, la pull request restant ouverte ; avec `—`, rien ne change.
- [ ] `missing_setting_changes_nothing` — sans ligne `Forge checks:` dans `AGENTS.local.md`, `/po-ship` fusionne comme avant la story et nomme le réglage manquant dans son rapport, comme `Project CLAUDE file` (ADR-0089) ; `/po-setup` n'est pas touché, le gabarit porte la ligne pour les projets à venir.
- [ ] `docs_say_how_to_require_the_check` — `docs/ci.md` dit ce que le contrôle lance, où il tourne, et le geste par lequel la personne le rend obligatoire sur `Target branch`, qu'aucun agent ne fait à sa place.

**Notes pour l'agent** : l'ADR-0105 est `accepted` : le workflow tourne sur les runners hébergés de GitHub, et reste écrit pour qu'un autre endroit ne demande que de le déplacer. `/po-ship` fusionne déjà par `gh pr merge … --match-head-commit` : l'attente se place juste avant, et se lit par `gh pr checks` ou l'équivalent de la forge du projet (`po-ship.md` nomme déjà les trois forges). Tests hors `Owns` qui figent `po-ship.md` et `templates/agents-local.md` et gardent leurs phrases : `tests/ship.test.sh`, `tests/ship-through-pr.test.sh`, `tests/structure.test.sh`, `tests/installer.test.sh`. Le `AGENTS.md` racine est régénéré par le cadrage après le ship, pas par toi.

### s160-intake-title-bounded — Le titre d'une issue déposée par le harnais est borné et stable
**En tant que** porteur **je veux** que `po-intake` dépose toujours son issue, quel que soit ce que le contrôle a écrit sur sa ligne d'échec **afin qu'un** échec de nuit ne se perde plus dans le journal de l'ordonnanceur parce que son titre était trop long ou changeait à chaque passage.

- **Complexité** : 2
- **Dépend de** : aucune
- **Surface** : command
- **Corrige** : issues #197 et #134 (`Issue tracker: github`)
- **Owns** : `method/hooks/po-intake.sh`, `method/hooks/po-gate.sh`, `docs/harnais.md`, `tests/intake-title-bounded.oracle.test.sh`, `tests/intake-title-bounded.test.sh`

**Critères d'acceptation**
- [ ] `title_is_cut_at_80_characters` — le titre `<nom>: <empreinte>` ne dépasse jamais 80 caractères, coupé sans casser un caractère sur plusieurs octets ; une ligne d'échec de 400 caractères donne une issue déposée, pas `not_filed`.
- [ ] `fingerprint_drops_the_assertion_message` — pour une ligne `FAILED <chemin>::<test> - <message>`, l'empreinte s'arrête avant ` - ` : deux passages dont seul le message change donnent le même titre, et le second commente la première issue.
- [ ] `existing_fingerprints_unchanged` — les formes TAP, cargo et `tests/run.sh`, et le repli sur le code de sortie, donnent le même titre qu'avant tant qu'il tient en 80 caractères.
- [ ] `unreadable_review_exits_2` — `po-gate findings-shape` sur un fichier de revue qui existe mais ne peut pas être lu sort en 2 avec un message qui le dit, et non en 1 comme une revue mal formée (ADR-0096).

**Notes pour l'agent** : `/po-ship` coupe déjà ses titres à 80 caractères (`po-ship.md`, étape 3) : même règle, mais ici dans le script. `docs/harnais.md` dit l'empreinte : mets-la à jour. Ne touche pas à `po-gate redact` ni à la purge des secrets : un constat à son sujet attend le porteur (`docs/a-trancher.md`, D6). Tests existants de ces scripts : `tests/failing-check-files-an-issue*.test.sh`, `tests/review-findings-shape.test.sh`.

### s161-installer-leftovers — L'installeur ne laisse plus de fichier égaré sans le dire
**En tant que** personne qui installe ou retire Polype **je veux** que chaque arrêt de l'installeur nomme les fichiers qu'il a déplacés et où ils sont **afin de** ne jamais perdre un fichier à moi parce qu'une commande s'est arrêtée au milieu.

- **Complexité** : 3
- **Dépend de** : aucune
- **Surface** : command
- **Corrige** : issues #143, #137, #144, #132 et les points d'installeur de #79 (`Issue tracker: github`)
- **Owns** : `bin/polype`, `docs/installation.md`, `method/AGENTS.md`, `tests/installer-leftovers.oracle.test.sh`, `tests/installer-leftovers.test.sh`

**Critères d'acceptation**
- [ ] `failed_remove_names_held_files` — un `remove --global` dont un déplacement hors de la charge utile échoue remet à leur place les fichiers tenus dans `.polype-restore.<pid>`, ou à défaut nomme chacun et le dossier où il se trouve ; aucun n'y reste sans message.
- [ ] `interrupted_run_leaves_a_named_trace` — une installation `--set-aside` qui échoue après ses déplacements liste chaque fichier écarté et son nouveau chemin avant de sortir.
- [ ] `orphan_before_polype_is_reported` — un `AGENTS.md.before-polype` sans `AGENTS.md` posé par Polype n'est plus supprimé en silence : l'installeur le garde et le dit.
- [ ] `state_pattern_stays_at_the_top` — `*.next` et `*.polype-next` ne comptent comme fichiers d'état de l'installeur qu'à la racine de la charge utile ; plus profond, un fichier de ce nom est un fichier étranger, signalé comme tel.
- [ ] `docs_describe_the_kept_copy_stops` — `docs/installation.md` dit quand surviennent les deux arrêts ajoutés par s146 et ce que fait la personne ; `method/AGENTS.md` (`## Installed files`) dit que `--set-aside` ne s'applique pas sous `~/.claude/polype/` (ADR-0095), sans allonger la section.

**Notes pour l'agent** : `bin/polype` est le seul fichier de code touché ; lis `cmd_remove`, `move_out_of_payload` et `is_payload_state_file`. Les deux points de pure présentation de #79 (colonne du réglage, « ADR-0005 » sans lien) ne sont pas repris, pas plus que son point sur un `CLAUDE.md` à BOM ou en lien symbolique sous `kept`, écarté au journal des décisions. Tests hors `Owns` qui figent l'installeur et sa doc et gardent leurs phrases : `tests/installer.test.sh`, `tests/install-collisions.test.sh`, `tests/payload-refuses-foreign-files.test.sh`, `tests/drop-keeps-modified.test.sh`, `tests/payload-kept-outside.test.sh`.

### s162-defects-seen-on-products — Les trois arrêts inutiles vus sur lagon et lophelia
**En tant que** chef de projet d'un produit **je veux** que le designer accepte les fichiers d'oracle du planner, que le `Owns` d'une story liste son oracle dès le cadrage, et que `/po-setup` refuse un skill de design qui n'est pas installé **afin que** la flotte ne s'arrête plus au milieu d'une story sur un défaut que le cadrage pouvait voir.

- **Complexité** : 2
- **Dépend de** : aucune
- **Surface** : —
- **Corrige** : issues #184, #166 et #87 (`Issue tracker: github`)
- **Owns** : `method/agents/designer.md`, `method/templates/stories.md`, `method/skills/agentic-stories/SKILL.md`, `method/skills/stories-review/SKILL.md`, `method/agents/stories-reviewer.md`, `method/commands/po-setup.md`, `tests/defects-seen-on-products.oracle.test.sh`, `tests/defects-seen-on-products.test.sh`

**Critères d'acceptation**
- [ ] `designer_accepts_the_oracle_files` — le contrôle d'état du designer tient pour légitimes les fichiers non commités que le plan liste sous `## Acceptance tests` avec leur somme de contrôle, et seulement ceux-là ; tout autre fichier hors `docs/` l'arrête comme avant.
- [ ] `owns_lists_the_oracle` — `templates/stories.md` et `agentic-stories` disent que le `Owns` d'une story qui a des critères d'acceptation liste son fichier d'oracle ; `stories-review` en fait un constat **major** quand il manque, dans son contrôle du `Owns` existant et non dans un contrôle de plus.
- [ ] `setup_refuses_a_missing_design_skill` — `/po-setup` n'écrit `Design skill: <nom>` que si le designer peut charger ce skill : `.claude/skills/<nom>/SKILL.md` ou `~/.claude/skills/<nom>/SKILL.md` existe ; un skill fourni par un plugin n'est accepté que si la recherche montre que le designer le charge, et le plan le dit. Sinon `/po-setup` le dit, propose `—` et n'écrit pas le nom.
- [ ] `no_file_grows` — aucun des fichiers de `method/` touchés ne compte plus de mots après la story qu'avant.

**Notes pour l'agent** : #184 a été vu sur lagon le 2026-11-10 (le pilote a dû confirmer les fichiers à la main), #87 sur lophelia. Le planner et l'implementer acceptent déjà l'oracle (`method/agents/planner.md`, s149) : reprends leur formulation plutôt que d'en inventer une. Tests hors `Owns` qui figent ces fichiers et gardent leurs phrases : `tests/design.test.sh`, `tests/designer-browser.test.sh`, `tests/owns-overlap.test.sh`, `tests/planner-writes-the-oracle.test.sh`.

### s163-qa-lanes-isolated — Deux QA en parallèle ne partagent ni navigateur ni port
**En tant que** chef de projet **je veux** que chaque lane en QA ait son propre navigateur et son propre port de développement **afin que** deux QA lancées ensemble ne se bloquent plus l'une l'autre toute une nuit.

- **Complexité** : 3
- **Dépend de** : aucune
- **Surface** : —
- **Corrige** : issue #149 (`Issue tracker: github`)
- **Owns** : `method/skills/qa-drivers/SKILL.md`, `method/agents/qa.md`, `tests/qa-lanes-isolated.oracle.test.sh`, `tests/qa-lanes-isolated.test.sh`

**Critères d'acceptation**
- [ ] `each_lane_drives_its_own_browser` — pour une surface `screen`, `qa-drivers` fait lancer à la lane un navigateur sans tête qui lui est propre, depuis le paquet du projet, et interdit le navigateur partagé de la session quand une autre lane est en QA ; le skill dit comment la lane le sait.
- [ ] `each_lane_serves_on_its_own_port` — le serveur de développement d'une lane écoute sur un port tiré du worktree de la story et jamais sur le port par défaut du projet ; la réutilisation d'un serveur déjà lancé est coupée.
- [ ] `a_stuck_driver_ends_blocked` — une action du pilote qui ne répond pas dans le délai que le skill fixe finit la QA en `QA status: blocked` avec la raison, au lieu d'attendre sans fin.
- [ ] `no_file_grows` — ni le skill ni `qa.md` ne comptent plus de mots après la story qu'avant.

**Notes pour l'agent** : vu sur clione les 24 et 25 octobre 2026 : un `browser_resize` bloqué 30 minutes, une navigation arrivée dans l'onglet de l'autre lane, deux lanes sur le port 4321 par `reuseExistingServer`. `po-bounds` borne ce que le subagent `qa` peut écrire : un navigateur privé ne doit rien laisser hors de `docs/qa/<id>/` (`qa-drivers`, « where a driver may leave anything »). Tests hors `Owns` qui figent ces fichiers et gardent leurs phrases : `tests/qa*.test.sh`, `tests/mobile-web-driver.test.sh`, `tests/godot-scene-driver.test.sh`.

## M21 — L'interface : un agent extérieur lit l'état, voit ce qui attend, répond et relance

Objectif : que Polype se pilote par une commande qui rend du JSON, et non par de la prose qu'un modèle réinterprète. Précisé par le porteur le 2026-11-12 : Polype reste une brique indépendante, du côté de l'intelligence, et ne suppose aucune installation particulière ; la personne peut passer par un agent extérieur quelconque (par exemple un assistant vocal local qui délègue l'intelligence à un grand modèle), qui doit pouvoir l'interroger vraiment et par lequel ses réponses reviennent (#204). Le contrat est écrit d'avance dans [`interface-agent.md`](interface-agent.md) et les stories le construisent sans le réinventer. Le même mouvement retire au modèle ce que du code fait mieux : dériver l'état (#203), écrire un rapport de revue ou de QA (#202, qui ferme #172, #180, #181, #186, #191, #193), calculer la prochaine action d'une lane (#203, qui ferme #139), rapporter les signaux de confiance (#205). Reprises le 2026-11-13 après les décisions du porteur : l'automate est un binaire Rust (ADR-0106), où entre tout ce que M21 ajoute, les hooks existants restant en bash (ADR-0116) ; il s'appelle `po`, il y en a un par machine, qui prévient quand sa version n'est pas celle du projet et lit ce qu'une version plus ancienne a écrit (ADR-0117) ; il est compilé depuis les sources dès s164, puis précompilé et vérifié par s171 (ADR-0115) ; l'interface est cette commande, la boîte vit dans des fichiers locaux hors de git dont l'emplacement est un réglage, le lancement passe par `claude --bg` (ADR-0107). s171 à s173 sont nées de cette reprise : la distribution du binaire, que rien ne portait, et deux morceaux retirés de s164 et de s168 pour les garder sous dix tâches. s174 est née de la revue de s164 (#249, et #248 qu'elle corrige aussi), sur décision du porteur le 2026-11-13 (d-0005) : elle donne aux verbes le contexte de projet que `state` gardait pour lui, et porte un numéro plus grand que s168, qui dépend d'elle, parce qu'un id ne change pas ; elle est la seule à toucher aux dossiers de trois verbes, pour la signature de leurs fonctions, et ces trois stories passent après elle. Ordre : s164 d'abord, qui pose le crate et dépend de s159 et de s161, livrées, dont elle reprend des fichiers ; puis s165 et s167 ensemble ; s166 après s165 ; s174 après s166, puis s168 ; s169 après s168 ; s171 après s169, s170 après s175 ; s172 après s170 ; s175 après s168 et s169, placée avant s170 qui partage ses fichiers et dépend d'elle, puis s173 après s167 et s175. s175 est née de la recherche de s173, sur décisions du porteur le 2026-11-14 (d-0009, d-0010) : `po next` rend le chemin en collision et retient une story absente du point de départ, que `/po-drive` calculait en prose ; la pull request fermée sans fusion rejoindra `po next` quand il lira la forge (issue #286), et l'ADR-0120 (d-0008) laisse `/po-execute` lancer `po next`. Le code de `po` est sous `po/`, un dossier par verbe, pour que deux stories ne tiennent jamais le même fichier. Un critère qui porte sur `po` a son test d'oracle, qui lance le binaire sur un dépôt d'essai ; un critère qui porte sur une règle lue par un modèle n'en a pas, il est jugé en revue et le plan le liste comme candidat à un bras de contrôle `po-eval` (#208). La règle de M20 sur les mots de `method/` vaut ici aussi, et s173 la chiffre.

### s164-state-as-json — L'état d'un projet se lit en JSON
**En tant qu'** agent extérieur **je veux** demander l'état d'un projet à une commande et recevoir du JSON **afin de** dire au porteur où en est son projet sans lancer de modèle ni lire de prose.

- **Complexité** : 4 — risque : deux à la fois. Le JSON doit dire la même chose que ce que `/po-status` et `po-session` dérivent aujourd'hui, et un écart devient un mensonge servi à la personne ; et c'est la story qui fait entrer Rust dans le dépôt (le crate, la compilation à l'installation, la suite et la CI qui construisent le binaire)
- **Dépend de** : s159-ci-on-every-pr, s161-installer-leftovers
- **Surface** : command
- **Corrige** : issue #203 en partie, #204 en partie (`Issue tracker: github`)
- **Owns** : `po/`, `bin/polype`, `method/templates/agents-local.md`, `AGENTS.local.md`, `docs/interface-agent.md`, `docs/installation.md`, `.gitignore`, `.github/workflows/ci.yml`, `evals/lib.sh`, `tests/lib.sh`, `tests/run.sh`, `tests/state-as-json.oracle.test.sh`, `tests/state-as-json.test.sh`

**Critères d'acceptation**
- [ ] `state_prints_one_json_object` — `po state`, lancé dans un projet ou dans un de ses worktrees, écrit sur sa sortie standard un seul objet JSON portant `"contract": 1` et les champs `project`, `commit`, `method_version`, `framing`, `milestone`, `lanes` et `waiting` de `docs/interface-agent.md` ; les champs que d'autres stories calculent (`lanes[].next`, `ready`, `held`, `session`, `bounds`, `shipped`) valent `null` ; hors d'un projet Polype il sort en 2 avec un objet `error`, et un verbe pas encore construit sort en 2 avec `"error": "not-built"` ; tout verbe, refus et échec compris, écrit un seul objet JSON et sort en 0, 1 ou 2 comme le contrat le dit.
- [ ] `state_reads_only_files_and_git` — `po state` n'écrit rien, ne prend aucun verrou git, n'interroge aucune forge et ne lance aucun modèle ; sur ce dépôt il répond en moins d'une seconde.
- [ ] `lane_stage_follows_the_gates` — pour un dépôt d'essai construit par le test, chaque état d'une story (worktree sans plan, plan non validé, plan validé, code commité avec relevé à jour, revue bloquée, revue qui autorise le ship, commit atterri) donne le `stage` attendu, celui que `po-gate` donnerait.
- [ ] `waiting_reads_the_inbox_setting` — `waiting` liste les identifiants des décisions `pending` du dossier que le réglage `Decision inbox` nomme (`.polype/inbox/` dans le gabarit) ; il vaut `[]` quand le dossier manque, et `null` quand la ligne manque dans `AGENTS.local.md`, `warnings` nommant alors le réglage.
- [ ] `installer_builds_po_from_sources` — `bin/polype install` et `update` compilent `po` depuis les sources avec `cargo` et le posent dans le dossier de Polype de l'utilisateur, un par machine ; sans `cargo`, l'installeur pose tout le reste, dit que `po` manque et pourquoi, et ne sort pas en erreur ; `check` signale un `po` absent.
- [ ] `po_warns_on_another_version` — quand la version de `po` n'est pas celle que `.polype/version` du projet nomme, l'objet rendu porte `warnings` avec `method-version-mismatch` et les deux versions, et `po` répond quand même (ADR-0117).

**Notes pour l'agent** : lis les ADR-0106, 0115, 0116 et 0117 avant ton plan. Le crate est sous `po/`. `main` déclare dès cette story tous les verbes du contrat et ceux du chef de projet (`state`, `next`, `inbox`, `answer`, `record`, `run`, `continue`), chacun dans son dossier (`po/src/inbox/`, `po/src/record/`, `po/src/next/`, `po/src/run/`, `po/src/trust/`) qui rend `not-built` : les stories suivantes remplissent leur dossier sans toucher aux tiens. Pour cela, `state` demande ses champs à ces dossiers — `lanes[].next`, `ready` et `held` à `next/`, `session` et `bounds` à `run/`, `shipped` à `trust/` — par une fonction qui rend `null` tant que la story n'est pas passée ; et les arguments d'un verbe, comme les options de `state` qu'une autre story apporte (`--all`, `--remote`), sont lus dans le dossier de cette story, pas dans `main`. Les dépendances du crate sont un choix technique : ton plan porte la ligne `Technical choice: waiting for a human` avec la liste courte (lire et écrire du JSON, lire les arguments, donner une date avec son décalage horaire, dont s165, s166 et s170 ont besoin), classée par les critères du porteur ; aucune story suivante n'en ajoute. `docs/installation.md` donne le chemin où `po` est posé : c'est par ce chemin que les commandes et les hooks l'appellent. `po-session.sh` contient la dérivation à porter (cadrage, lanes, attentes) : lis-le, ne le modifie pas (s172). `po-gate.sh` n'est pas modifié. La compilation depuis les sources est le repli de l'ADR-0115 ; le binaire précompilé est s171. `Test` reste `bash tests/run.sh`, qui construit `po` une fois avant les tests ; les tests d'oracle lancent le binaire sur un dépôt d'essai, et la CI doit passer sur un runner neuf : `ci.yml` ne change que si le runner n'a pas `cargo`, et garde une seule étape de contrôle, qui appelle `bin/po-ci` (l'oracle de s159, `tests/ci-on-every-pr*.test.sh`, le fige). Dans `docs/interface-agent.md`, remplace le chemin et le nom de la commande par `po`, ajoute `warnings`, et dis que l'emplacement de la boîte est un réglage. Tests hors `Owns` qui figent l'installeur et le gabarit des réglages : `tests/install*.test.sh`, `tests/global-install.test.sh`, `tests/structure.test.sh`, `tests/setup-modes.test.sh`, `tests/platform-setting.test.sh`.

### s165-decision-inbox — Ce qui attend le porteur est un fichier, pas une phrase dans une session
**En tant que** porteur **je veux** que chaque question que Polype me pose soit rangée dans une boîte, avec ses options et une recommandation **afin de** la retrouver et d'y répondre par l'agent extérieur de mon choix, même quand la session qui l'a posée est fermée.

- **Complexité** : 3
- **Dépend de** : s164-state-as-json
- **Surface** : command
- **Corrige** : issue #204 en partie (`Issue tracker: github`)
- **Owns** : `po/src/inbox/`, `bin/polype`, `method/AGENTS.md`, `AGENTS.local.md`, `.gitignore`, `docs/a-trancher.md`, `tests/decision-inbox.oracle.test.sh`, `tests/decision-inbox.test.sh`, `tests/state-as-json.oracle.test.sh`, `docs/interface-agent.md`, `docs/installation.md`

**Critères d'acceptation**
- [ ] `add_writes_one_decision_file` — `po inbox add` lit une décision en JSON sur son entrée standard, lui donne l'identifiant suivant (`d-0001`, `d-0002`…) et l'écrit dans `<id>.json` sous le dossier que `Decision inbox` nomme, résolu depuis la racine du dépôt, y compris lancé depuis le worktree d'une story ; il rend l'objet écrit. Sans ligne `Decision inbox` dans `AGENTS.local.md`, il sort en 2 avec `no-inbox-setting`, nomme le réglage et n'écrit rien : aucun emplacement n'est deviné.
- [ ] `add_refuses_a_malformed_decision` — une décision sans `motive` connu, dont la `question` manque, tient sur plus d'une ligne ou dépasse 200 caractères, avec moins de deux ou plus de trois `options`, avec un `recommended` hors de la liste, sans `why`, sans `reversible` ou sans `blocks` est refusée en sortant en 1 avec un objet `error`, et rien n'est écrit.
- [ ] `list_prints_pending_oldest_first` — `po inbox` rend `{"contract": 1, "pending": […]}`, la plus ancienne d'abord, en moins d'une seconde ; `po inbox <id>` rend une décision, répondue ou non.
- [ ] `inbox_never_enters_git` — quel que soit l'emplacement réglé : dans le dépôt et non ignoré par git, `po inbox add` sort en 1 avec `inbox-not-ignored` et n'écrit rien ; hors du dépôt, il écrit. À l'installation et à la mise à jour, l'installeur ajoute l'emplacement du gabarit au `.gitignore` du projet quand il n'y est pas, et le dit.
- [ ] `sensitive_decisions_carry_no_detail` — une décision `sensitive: true` n'est acceptée que si son `context` pointe hors du dépôt ; `po inbox` la rend comme les autres.
- [ ] `rules_send_every_stop_to_the_inbox` — `## What goes to the person` de `method/AGENTS.md` dit que tout ce qui remonte à la personne est posé par `po inbox add` avant d'être dit, et que le chef de projet le dit quand même à la personne, avec la raison, quand `po` manque ou refuse. Règle lue par un modèle : pas de test d'oracle, jugée en revue ; le test vérifie seulement que la section ne compte pas plus de mots qu'avant.
- [ ] `provisional_inbox_is_gone` — `docs/a-trancher.md` est supprimé et la ligne de `AGENTS.local.md` qui y renvoyait nomme la boîte ; ce qui y restait ouvert est listé dans le plan de la story, pour que le chef de projet le pose avec `po inbox add` une fois la story livrée.

**Notes pour l'agent** : l'ADR-0107 fixe la boîte : des fichiers locaux, jamais dans git, à un emplacement réglé. La forme d'une décision est dans `docs/interface-agent.md` (`## inbox`) ; ne l'étends pas. Tu remplis `po/src/inbox/` et tu ne touches à aucun autre dossier du crate ; il te manque une dépendance → arrête-toi et dis-le. `.polype/` est commité : seule la boîte est ignorée, et l'installeur ne doit pas la prendre pour un fichier étranger. `## Installed files` de `method/AGENTS.md` nomme `po` à côté des hooks, sans que le fichier gagne un mot. Un projet installé avant cette story n'a pas la ligne `Decision inbox` : `polype update` la lui signale, comme tout réglage ajouté au gabarit. Une décision de sécurité de `a-trancher.md` (D6, D7) se repose en `sensitive`, sans plus de détail que ce fichier public n'en donne. Tests hors `Owns` qui figent `## What goes to the person` : `tests/escalation-contract.test.sh`, `tests/everything-in-issues.test.sh`.

### s166-answer-comes-back — Une réponse du porteur n'est acceptée que si elle nomme une option listée
**En tant que** porteur **je veux** répondre à une décision en nommant une de ses options, par l'agent extérieur de mon choix **afin que** ma réponse arrive au chef de projet telle que je l'ai donnée, et qu'une réponse mal comprise soit refusée plutôt qu'interprétée.

- **Complexité** : 3
- **Dépend de** : s165-decision-inbox
- **Surface** : command
- **Corrige** : issue #204 en partie (`Issue tracker: github`)
- **Owns** : `po/src/inbox/`, `method/AGENTS.md`, `tests/answer-comes-back.oracle.test.sh`, `tests/answer-comes-back.test.sh`, `tests/state-as-json.oracle.test.sh`, `docs/interface-agent.md`

**Critères d'acceptation**
- [ ] `answer_accepts_only_a_listed_option` — `po answer <id> <key>` passe la décision à `"status": "answered"` avec `answer.key` et `answer.at`, et la rend ; une `key` hors de `options` sort en 1 avec `"error": "not-an-option"` et ne change pas le fichier.
- [ ] `answer_refuses_twice_and_unknown` — une décision déjà répondue rend `already-answered`, un identifiant inconnu `unknown-decision` ; dans les deux cas rien n'est écrit.
- [ ] `answer_launches_nothing` — `po answer` ne lance aucune commande, aucun modèle et aucune session.
- [ ] `answered_decisions_are_listed_until_consumed` — `po inbox --answered` rend les décisions répondues que le chef de projet n'a pas encore traitées ; `po inbox consume <id> <ref>` note ce que la réponse a produit (le chemin d'une ADR, l'id d'une story) et la sort de cette liste.
- [ ] `rules_say_who_consumes` — `method/AGENTS.md` dit que le chef de projet lit les décisions répondues au début d'une session, écrit ce que chacune produit là où cela doit vivre en citant son identifiant, puis la consomme ; une décision `sensitive` n'est citée que par son identifiant. Règle lue par un modèle : pas de test d'oracle, jugée en revue ; le test vérifie seulement que `method/AGENTS.md` ne compte pas plus de mots qu'avant.

**Notes pour l'agent** : `docs/interface-agent.md` (`## answer`) fixe les codes d'erreur. Une réponse est une donnée venue de l'extérieur : `<key>` est comparée aux clés listées, jamais évaluée ni passée à un shell. Le porteur qui ne veut aucune option ne répond pas par cette commande : c'est écrit dans le contrat, n'ajoute pas de texte libre.

### s167-record-writes-reports — Un rapport de revue ou de QA est écrit par du code
**En tant que** porteur **je veux** qu'une commande écrive le fichier d'une revue ou d'une QA à partir de la réponse du subagent **afin que** l'en-tête, la forme et la version de la méthode ne dépendent plus de ce qu'un modèle a recopié.

- **Complexité** : 3
- **Dépend de** : s164-state-as-json
- **Surface** : command
- **Corrige** : issues #202, #172, #180, #181, #186, #191 et #193 (`Issue tracker: github`)
- **Owns** : `po/src/record/`, `method/commands/po-review.md`, `method/commands/po-qa.md`, `method/commands/po-orchestrator.md`, `method/commands/po-flow.md`, `method/commands/po-drive.md`, `method/templates/review.md`, `method/templates/qa.md`, `tests/record-writes-reports.oracle.test.sh`, `tests/record-writes-reports.test.sh`, `tests/review-header-recorded.oracle.test.sh`, `tests/review-header-recorded.test.sh`, `tests/qa-report-returned-as-text.test.sh`, `tests/state-as-json.oracle.test.sh`

**Critères d'acceptation**
- [ ] `record_writes_header_then_answer` — `po record review <id>` et `po record qa <id>` lisent la réponse du subagent sur leur entrée standard et écrivent `docs/reviews/<id>.md` ou `docs/qa/<id>/report.md` : le titre et la ligne de liens du gabarit, `<id>` remplacé, puis la réponse mot pour mot ; une réponse qui apporte son propre en-tête ne le voit pas doublé.
- [ ] `record_stamps_the_method_version` — le rapport porte une ligne `Method version:` tirée de `.polype/version`, que `po` écrit et que le subagent ne fournit pas.
- [ ] `record_checks_the_shape` — `po record review` lance `po-gate findings-shape` sur ce qu'il vient d'écrire et sort avec son code ; `po record qa` refuse une réponse sans ligne `QA status:` et n'écrit alors rien.
- [ ] `record_refuses_the_wrong_branch` — hors de la branche `story/<id>`, `po record` sort en 2 sans écrire.
- [ ] `record_notes_the_oracle_gate` — `po record review` ajoute sous `## Tests` le résultat de `po-gate oracle-intact <id>`, qu'il lance lui-même.
- [ ] `commands_call_po_record` — `/po-review`, `/po-qa`, `/po-orchestrator`, `/po-flow` et `/po-drive` consignent par `po record` et perdent leurs consignes de transcription (heredoc, en-tête, ordre des contrôles). Règle lue par un modèle : pas de test d'oracle, jugée en revue ; le test vérifie seulement que chacun de ces fichiers compte moins de mots qu'avant.
- [ ] `resume_paths_reuse_the_report` — les deux chemins de reprise qui renvoyaient au commit des preuves sans nouvelle marche (#180) relancent `po record qa` sur le rapport déjà écrit, ou disent pourquoi il n'y en a pas ; même régime que le critère précédent.

**Notes pour l'agent** : cette story remplace la mécanique de s156 et de s158 sans changer leurs règles (ADR-0102, ADR-0104) : le coordinateur consigne, le subagent qui juge n'écrit pas. Elle change donc les clauses que `tests/review-header-recorded*.test.sh` et `tests/qa-report-returned-as-text.test.sh` vérifient : ces fichiers sont dans `Owns`, dis dans le plan quelles assertions changent. `po record` appelle `po-gate.sh` sans le modifier. Tu remplis `po/src/record/` et tu ne touches à aucun autre dossier du crate ; il te manque une dépendance → arrête-toi et dis-le. Tests hors `Owns` qui figent ces commandes et gardent leurs phrases : `tests/review.test.sh`, `tests/review-findings-shape.test.sh`, les `tests/qa*.test.sh` autres que celui de `Owns`, `tests/drive.test.sh`, `tests/flow.test.sh`.

### s174-verbs-read-project-context — Les verbes de `po` lisent le même contexte de projet
**En tant que** porteur **je veux** que `next`, `run` et les signaux de confiance calculent leurs champs à partir de ce que `state` a déjà lu du projet **afin qu'** aucune story de M21 ne relise le dépôt à sa façon, et qu'un écart entre deux lectures ne devienne pas deux réponses différentes à la même question.

- **Complexité** : 3 — risque : c'est un remaniement de `po state` ; sa sortie ne doit pas bouger d'un champ, et l'oracle de s164 est là pour le dire
- **Dépend de** : s164-state-as-json, s166-answer-comes-back
- **Surface** : —
- **Corrige** : issue #249, issue #248 (`Issue tracker: github`)
- **Owns** : `po/src/context/`, `po/src/state/`, `po/src/project.rs`, `po/src/main.rs`, `po/src/next/mod.rs`, `po/src/run/mod.rs`, `po/src/trust/mod.rs`, `po/src/inbox/`, `tests/verbs-read-project-context.oracle.test.sh`, `tests/verbs-read-project-context.test.sh`, `tests/state-as-json.oracle.test.sh`, `tests/state-as-json.test.sh`

**Critères d'acceptation**
- [ ] `state_output_does_not_move` — sur les dépôts d'essai de l'oracle de s164, `po state` rend l'objet que le `po` de `Target branch` rendait avant la story, consigné dans le test, champ pour champ et `warnings` compris dans leur ordre, hors le commit, la version et le chemin temporaire du dépôt d'essai, et hors les champs que s168 à s170 calculeront ; sur ce dépôt, `po state` n'écrit toujours rien, ne prend aucun verrou git et répond en moins d'une seconde.
- [ ] `landed_lane_reports_ship_whatever_its_review` — une lane dont la story est livrée sur `Target branch` donne le `stage` `ship` même quand sa revue manque ou ne correspond plus au code ; le dépôt d'essai porte ce cas, et le test tombe si la règle « livrée → `ship` » est retirée (#248).
- [ ] `verbs_receive_one_context` — `lane_next`, `ready`, `held`, `session`, `bounds` et `shipped` reçoivent un même contexte, construit une fois par appel de `po` : la racine du projet, les réglages lus, les stories de `docs/stories.md` avec leurs dépendances et leur `Owns`, l'ensemble des stories livrées, le commit atterri de chacune, le jalon de chaque story et le jalon en cours, l'étape de cadrage, les lanes avec le chemin de leur worktree et leur `stage`, et les décisions de la boîte avec leur `status`, leur `blocks` et leur `consumed`. Cette liste est un minimum : ce que les critères de s168, de s169 et de s170 demandent de calculer fait foi, et le plan le relève critère par critère. Plus rien de cela n'est privé à `po/src/state/` ni à `po/src/inbox/` ; `state` lui-même se construit sur ce contexte, et c'est lui qui prouve qu'il suffit. Règle de structure du code, sans sortie qu'un script lise : pas de test d'oracle, jugée en revue.

**Notes pour l'agent** : lis le constat de la revue de s164 (`docs/reviews/s164-state-as-json.md`, `## Findings`) et les stories s168, s169 et s170, qui sont tes trois clients : ton contexte doit porter ce que leurs critères demandent de calculer, sans calculer à leur place. Tu ne remplis ni `next/`, ni `run/`, ni `trust/` : tu n'y changes que la signature des fonctions que `state` appelle, qui rendent toujours `None`, et leurs verbes répondent toujours `not-built`. Les types que `next/`, `run/` et `trust/` rendent restent définis chez eux, pour que s168 donne ses raisons (`dependency`, `owns`, `parallel`, `decision`, `ref`) sans toucher à `state/`. Dans `po/src/inbox/`, tu ne fais qu'ouvrir la lecture des décisions au contexte : aucun verbe de la boîte ne change de comportement. Aucune dépendance de plus (ADR-0118). Les lectures restent celles de s164 : fichiers et git en lecture seule, `GIT_OPTIONAL_LOCKS=0`. Le cas de la lane livrée vit dans ton oracle ; si tu touches à `tests/state-as-json.oracle.test.sh`, ce n'est qu'au dépôt d'essai de cette lane, et le plan dit quelle assertion change.

### s168-driver-next-action — La prochaine action d'une lane est calculée, pas interprétée
**En tant que** porteur **je veux** qu'une commande calcule quelles stories peuvent s'ouvrir et ce que chaque lane doit faire ensuite **afin que** la flotte se comporte de la même façon d'une session à l'autre, et qu'une règle de routage se lise dans une table de cas.

- **Complexité** : 4 — risque : la parité avec le pilote en prose ; un cas de routage oublié changera le comportement de la flotte quand `/po-drive` lira cette sortie (s173), d'où une table de cas tirée de `po-drive.md` section par section
- **Dépend de** : s164-state-as-json, s166-answer-comes-back, s174-verbs-read-project-context
- **Surface** : command
- **Corrige** : issue #203 en partie, #139 en partie (`Issue tracker: github`)
- **Owns** : `po/src/next/`, `tests/fixtures/driver-cases/`, `tests/driver-next-action.oracle.test.sh`, `tests/driver-next-action.test.sh`, `tests/state-as-json.oracle.test.sh`, `po/src/context/mod.rs`

**Critères d'acceptation**
- [ ] `next_gives_one_action_per_lane` — `po next` rend, pour chaque lane et chaque story prête, une action parmi `plan`, `validate-plan`, `design`, `execute`, `qa`, `review`, `fix`, `ship`, `wait`, `ask`, avec la raison qui nomme la porte ou le fichier lu ; `po state` porte la même dans `lanes[].next`. Une story prête, ou une lane sans recherche ni plan, reçoit `plan` : le planner fait la recherche, choisit la voie et écrit le plan, comme `/po-drive` le lui confie aujourd'hui ; une recherche qui porte `Root cause: not found` donne `ask`. La liste des actions du contrat ne change pas.
- [ ] `ready_and_held_say_why` — `po state` rend dans `ready` les stories qui peuvent s'ouvrir et dans `held` celles qui attendent, avec la raison `dependency`, `owns`, `parallel` ou `decision` ; une story que le `blocks` d'une décision `pending` nomme est tenue avec `decision` et `ref`.
- [ ] `every_routing_case_is_a_fixture` — `tests/fixtures/driver-cases/` tient un cas par règle de routage de `po-drive.md` tel qu'il est : un état de dépôt et l'action attendue ; le plan en donne la liste, section par section du fichier, et le test les rejoue tous.
- [ ] `blocked_on_shape_asks_and_never_fixes` — une revue bloquée par `po-gate findings-shape` donne `ask`, jamais `fix` (#139).
- [ ] `fix_loops_stop_at_max_attempts` — après `Max attempts` fix runs, l'action est `ask` ; avant, `fix`.
- [ ] `ships_stay_serial_in_review_order` — deux lanes dont la revue autorise le ship donnent `ship` à celle dont la revue est passée la première et `wait` à l'autre.
- [ ] `answered_decision_releases_its_lanes` — une lane que le `blocks` d'une décision `pending` nomme donne `wait` ; la décision répondue et consommée, elle reprend son action.

**Notes pour l'agent** : commence par la table des cas, relue contre `po-drive.md` section par section. `po-drive.md` n'est pas à toi : cette story calcule, s173 fait lire le résultat à `/po-drive` et retire la prose. Le recouvrement de deux `Owns` suit la règle du contrôle 8 de `stories-review`, que `tests/owns-overlap.test.sh` exerce déjà. Tu remplis `po/src/next/` et tu ne touches à aucun autre dossier du crate, sauf `po/src/context/mod.rs` pour y rendre visible un type que le contexte porte déjà ; il te manque une dépendance → arrête-toi et dis-le. Si la table demande plus de dix tâches, dis-le avant de faire valider le plan et propose la coupe par section.

### s169-run-from-outside — Un agent extérieur lance et relance le chef de projet
**En tant qu'** agent extérieur **je veux** lancer et relancer le chef de projet par la commande qui me donne déjà l'état et la boîte **afin de** piloter un projet pour le porteur sans rien connaître de Polype.

- **Complexité** : 4 — risque : lancer une session sans personne devant ; `run` refuse quand il ne peut pas prouver que les bornes des subagents seront tenues, et ne passe jamais de consigne libre à la session
- **Dépend de** : s166-answer-comes-back, s168-driver-next-action, s174-verbs-read-project-context
- **Surface** : command
- **Corrige** : issue #204 (`Issue tracker: github`)
- **Owns** : `po/src/run/`, `docs/interface-agent.md`, `docs/installation.md`, `README.md`, `tests/run-from-outside.oracle.test.sh`, `tests/run-from-outside.test.sh`, `tests/state-as-json.oracle.test.sh`, `po/src/context/mod.rs`

**Critères d'acceptation**
- [ ] `run_starts_one_lead_session` — `po run` lance une session de chef de projet à la racine du projet par la commande que le test remplace par un double, avec pour seule consigne la commande que `po state` annonce (l'étape de cadrage manquante, sinon `/po-drive`), et rend `session`, `started` et `command`.
- [ ] `continue_resumes_after_an_answer` — avec une session lancée par `run` puis arrêtée et une décision répondue non consommée, `po continue` relance cette session par la commande de reprise, que le test remplace par un double, et rend `session`, `started` et `command` ; sans session connue, il en lance une comme `run`.
- [ ] `run_refuses_a_second_session` — tant qu'une session lancée par `run` tourne, `run` et `continue` rendent `already-running` et ne lancent rien ; `po state` porte `session.running` et `session.id`.
- [ ] `run_refuses_unproven_bounds` — quand les subagents du projet ne sont posés que dans `.claude/agents/` du dépôt et que rien ne prouve le dialogue de confiance accepté, `po state` porte `"bounds": "unproven"` et `run` rend `bounds-unproven` sans rien lancer ; avec l'installation globale, `"bounds": "held"`.
- [ ] `run_refuses_when_nothing_to_do` — sans story prête, sans lane en cours et sans décision répondue à consommer, `run` et `continue` rendent `nothing-to-do`.
- [ ] `run_takes_no_free_text` — `run` et `continue` refusent tout argument qui n'est pas une option documentée.
- [ ] `docs_show_the_agent_loop` — `docs/interface-agent.md` n'annonce plus que rien n'existe et montre la boucle d'un agent extérieur (`state`, `inbox`, `answer`, `continue`) ; `README.md` y renvoie en une ligne ; `docs/installation.md` dit, sous « Limite de confiance », ce que `bounds` rapporte ; `docs/interface-agent.md` liste à part, hors du contrat de l'agent extérieur, les verbes du chef de projet (`next`, `record`, `inbox add`, `inbox --answered`, `inbox consume`). Documentation : pas de test d'oracle, jugée en revue.

**Notes pour l'agent** : l'ADR-0107 fixe le lancement : `claude --bg` depuis la racine, que le porteur suit par `claude agents`, `claude attach <id>`, `claude logs <id>`. Le test ne lance jamais de vraie session : la commande passe par une variable que le test pointe sur un double. Vérifie dans la doc de Claude Code comment savoir qu'une session de fond tourne encore avant de choisir entre un fichier de verrou et une interrogation de `claude agents`. Aucune preuve du dialogue de confiance n'est connue aujourd'hui : une installation par projet vaut donc toujours `unproven`, n'invente pas de mécanisme pour la prouver. Ce que `run` laisse sur la machine (un verrou, l'identifiant de la session) reste hors de git ; nomme ces fichiers dans le plan, s171 les nettoie à la montée de version (ADR-0117). Tu remplis `po/src/run/` et tu ne touches à aucun autre dossier du crate, sauf `po/src/context/mod.rs` pour y rendre visible un type que le contexte porte déjà ; il te manque une dépendance → arrête-toi et dis-le.

### s175-held-says-what-collides — Une story retenue dit sur quoi elle bute
**En tant que** porteur **je veux** que `po next` nomme le chemin sur lequel deux stories se heurtent et dise qu'une story attend son cadrage **afin que** le rapport de la flotte garde ce qu'il m'explique aujourd'hui quand `/po-drive` ne fera plus que lire `po next`.

- **Complexité** : 3
- **Dépend de** : s168-driver-next-action, s169-run-from-outside
- **Surface** : command
- **Corrige** : issue #280 (`Issue tracker: github`)
- **Owns** : `po/src/next/`, `po/src/context/`, `docs/interface-agent.md`, `tests/fixtures/driver-cases/`, `tests/driver-next-action.oracle.test.sh`, `tests/driver-next-action.test.sh`, `tests/held-says-what-collides.oracle.test.sh`, `tests/held-says-what-collides.test.sh`, `tests/state-as-json.oracle.test.sh`, `tests/verbs-read-project-context.oracle.test.sh`

**Critères d'acceptation**
- [ ] `owns_collision_names_the_path` — une story tenue pour la raison `owns` porte, dans `held` de `po next` et de `po state`, les deux entrées d'`Owns` qui se recouvrent et un chemin que les deux couvrent, en plus de la story qui tient ce chemin dans `ref` ; quand le recouvrement est retenu par prudence sans qu'un chemin commun se nomme (par exemple deux jokers dans le même segment, ou `**/x.md` contre `src/y.md`), ce chemin vaut `null` ; une story tenue pour une autre raison ne porte pas ces champs.
- [ ] `story_off_the_start_point_is_held` — une story prête dont aucune ligne de titre (`## <id>` ou `### <id>`) ne nomme l'id dans `docs/stories.md` du point de départ (`origin/<Target branch>` quand cette ref existe, `<Target branch>` sinon) n'est pas dans `ready` : elle est dans `held` avec la raison `framing` et le point de départ dans `ref`, et garde sa place de `Parallel`, qu'aucune autre story ne vient remplir, comme `/po-drive` le fait aujourd'hui. `po` lit cette ref dans le dépôt local, sans interroger aucune forge.
- [ ] `contract_says_the_new_fields` — `docs/interface-agent.md` décrit ces champs et cette raison, et dit que `ref` porte alors une ref git et non un id de story ou de décision ; aucun champ n'est retiré ni renommé, `contract` reste `1`, et le contrat dit qu'une valeur ajoutée à une liste fermée ne change pas ce numéro, un lecteur devant tolérer une valeur qu'il ne connaît pas (dans l'esprit de l'ADR-0117). Document sans sortie qu'un script lise : pas de test d'oracle, jugé en revue.
- [ ] `routing_cases_follow` — `tests/fixtures/driver-cases/` gagne un cas pour chacune des deux règles, et le test qui rejoue les cas passe.

**Notes pour l'agent** : c'est la règle de `## The ready set` et de `### Preparing the lanes` de `method/commands/po-drive.md`, que s173 retirera de la prose : relis-les, et ne touche pas à ce fichier. `po/src/next/overlap.rs` dit seulement si deux entrées se recouvrent : le chemin commun est à construire à côté, sans changer ce que la règle décide. Dans `po/src/context/`, tu n'ajoutes que la lecture des stories du point de départ ; la sortie de `po state` ne bouge pas ailleurs, et l'oracle de s174 le dit. Aucune dépendance de plus (ADR-0118). La pull request fermée sans fusion n'est pas ici : elle demande de lire la forge, et l'issue #286 la porte.

### s170-trust-signals — Chaque story livrée dit à quel point on peut s'y fier
**En tant que** porteur **je veux** lire, pour chaque story livrée, les signaux qui disent si je peux m'y fier **afin de** décider quoi relire moi-même sans ouvrir chaque revue, et de comparer la voie courte à la voie complète.

- **Complexité** : 3
- **Dépend de** : s167-record-writes-reports, s169-run-from-outside, s174-verbs-read-project-context, s175-held-says-what-collides
- **Surface** : command
- **Corrige** : issue #205 (`Issue tracker: github`) ; donne sa mesure à #209
- **Owns** : `po/src/trust/`, `method/hooks/po-run.sh`, `method/templates/verification-record.md`, `docs/interface-agent.md`, `tests/trust-signals.oracle.test.sh`, `tests/trust-signals.test.sh`, `po/src/context/mod.rs`

**Critères d'acceptation**
- [ ] `shipped_stories_carry_trust` — `po state` rend pour chaque story livrée du jalon en cours `shipped[].trust` avec `oracle`, `fix_loops`, `max_severity`, `not_verified`, `method_version`, lus dans `docs/reviews/<id>.md`, et `track` (`full` ou `flow`), lu dans le plan ; `po state --all` le rend pour toutes les stories livrées.
- [ ] `unknown_is_null_never_guessed` — une revue d'avant s167, sans ligne `Method version:`, donne `"method_version": null` ; une valeur illisible vaut `null`, jamais une valeur par défaut, et `po` ne sort pas en erreur sur un rapport d'une version plus ancienne (ADR-0117).
- [ ] `checks_are_read_only_on_request` — sans `--remote`, `checks` vaut `null` et aucune forge n'est interrogée ; avec `--remote`, `checks` est l'état des contrôles de la forge sur le commit atterri (`passed`, `failed`, `none`), lu par la commande que le test remplace par un double.
- [ ] `duration_comes_from_the_record` — `po-run` note dans la ligne de chaque contrôle sa durée, le relevé porte l'heure de son premier et de son dernier contrôle, et `duration_s` en est tirée ; `cost_usd` vaut `null` tant qu'aucun fichier ne le porte, et le contrat le dit.

**Notes pour l'agent** : `docs/interface-agent.md` (`### Les signaux de confiance`) fixe les champs et leurs valeurs ; ajoute-y `track` et `--all`. `po-run.sh` écrit la ligne d'un contrôle dans `docs/verif/<id>.md`, que `po-gate` relit : ajoute la durée sans changer ce que la porte lit, et vérifie-le par les tests existants de `po-gate` et de `po-run`. Le coût d'une session n'est écrit nulle part aujourd'hui : ne l'invente pas, laisse `null` et dis-le au chef de projet si tu trouves où le lire. Tu remplis `po/src/trust/` et tu ne touches à aucun autre dossier du crate, sauf `po/src/context/mod.rs` pour y rendre visible un type que le contexte porte déjà. Tests hors `Owns` : `tests/gate.test.sh`, `tests/verification*.test.sh`.

### s171-po-prebuilt-and-verified — Une machine sans Rust reçoit `po`, vérifié
**En tant que** personne qui installe Polype **je veux** recevoir `po` déjà compilé pour ma plateforme, vérifié par sa somme de contrôle **afin de** ne pas avoir à installer Rust et de savoir quel binaire tourne.

- **Complexité** : 4 — risque : la chaîne d'approvisionnement ; un binaire téléchargé puis exécuté sur la machine du porteur n'est sûr que si la somme attendue vient d'ailleurs que du téléchargement lui-même
- **Dépend de** : s165-decision-inbox, s169-run-from-outside
- **Surface** : command
- **Owns** : `bin/po-release`, `.github/workflows/release.yml`, `bin/polype`, `docs/installation.md`, `docs/ci.md`, `tests/po-prebuilt-and-verified.oracle.test.sh`, `tests/po-prebuilt-and-verified.test.sh`, `tests/run.sh`

**Critères d'acceptation**
- [ ] `release_builds_one_binary_per_platform` — `bin/po-release` compile `po` pour la plateforme où il tourne et écrit le binaire et sa somme de contrôle sous un nom qui porte la version et la plateforme ; le workflow de release ne fait que l'appeler, une fois par plateforme publiée, et publier ce qu'il rend.
- [ ] `installer_downloads_and_verifies` — `bin/polype install` et `update` prennent le binaire de la plateforme par la commande que le test remplace par un double, comparent sa somme à la somme attendue et le posent ; une somme différente ne pose rien, garde le `po` en place et sort en erreur en nommant les deux sommes.
- [ ] `installer_falls_back_to_sources` — sans binaire publié pour la plateforme, ou sans réseau, l'installeur compile depuis les sources (s164) et le dit ; sans `cargo` non plus, il pose le reste et dit que `po` manque.
- [ ] `upgrade_cleans_what_the_old_version_left` — une mise à jour qui remplace `po` retire l'ancien binaire et les fichiers de machine que l'ancienne version a laissés et que la nouvelle ne lit plus, et dit ce qu'elle a retiré ; elle ne touche à aucune boîte de décisions ni à aucun fichier suivi par git (ADR-0117).
- [ ] `check_audits_po` — `bin/polype check` signale un `po` absent, un `po` dont la somme n'est pas celle de la version installée, et un `po` d'une autre version que celle du projet.
- [ ] `docs_say_what_is_verified` — `docs/installation.md` dit d'où vient le binaire, ce que la somme prouve et ne prouve pas, et comment forcer la compilation depuis les sources ; `docs/ci.md` dit comment publier une version. Documentation : pas de test d'oracle, jugée en revue.

**Notes pour l'agent** : dans `tests/run.sh`, tu ne fais que brancher un faux téléchargement qui refuse, pour qu'aucun test de la suite ne télécharge le jour où une somme est inscrite ; l'ADR-0115 fixe la voie : précompilé et vérifié, compilé en repli. Deux choix techniques restent au porteur, et ton plan porte la ligne `Technical choice: waiting for a human` pour chacun : la liste des plateformes publiées, et l'endroit où l'installeur lit la somme attendue (l'ADR-0115 dit ce que chaque endroit prouve). Un constat de sécurité sur cette chaîne va au porteur, jamais au tracker. Le test ne télécharge jamais rien. Le workflow suit la règle de s159 : il n'appelle que le script, dans une syntaxe que Forgejo Actions lit aussi (ADR-0105). Les fichiers de machine que `run` laisse sont nommés dans le plan de s169. Tests hors `Owns` qui figent l'installeur : `tests/install*.test.sh`, `tests/global-install.test.sh`, `tests/installer-leftovers*.test.sh`.

### s172-commands-read-po-state — `po-session`, `/po-status` et `/po-retro` lisent le même état
**En tant que** porteur **je veux** que ce que la session affiche au démarrage, ce que `/po-status` rapporte et ce que `/po-retro` chiffre viennent de `po state` **afin qu'** il n'y ait plus qu'une lecture de l'état d'un projet, celle que l'agent extérieur reçoit aussi.

- **Complexité** : 2
- **Dépend de** : s170-trust-signals
- **Surface** : command
- **Corrige** : issue #203 en partie (`Issue tracker: github`)
- **Owns** : `method/hooks/po-session.sh`, `method/commands/po-status.md`, `method/commands/po-retro.md`, `tests/commands-read-po-state.oracle.test.sh`, `tests/commands-read-po-state.test.sh`, `tests/session-and-gate-checks.test.sh`

**Critères d'acceptation**
- [ ] `session_hook_prints_from_po_state` — `po-session` tire ce qu'il affiche de `po state` et ne dérive plus rien lui-même ; ce qu'il affiche pour les cas de ses tests existants ne change pas.
- [ ] `session_hook_survives_a_missing_po` — sans `po` sur la machine, `po-session` affiche une ligne qui nomme l'installeur et sort en 0 ; un avertissement de version de `po` est affiché tel quel.
- [ ] `status_and_retro_read_po_state` — `/po-status` et `/po-retro` disent de lire `po state` et perdent leurs propres règles de dérivation et de lecture des revues. Règle lue par un modèle : pas de test d'oracle, jugée en revue ; le test vérifie seulement que chacun des deux fichiers compte moins de mots qu'avant.

**Notes pour l'agent** : `po-session.sh` reste en bash (ADR-0116) : il appelle `po` et met en forme. `tests/session-and-gate-checks.test.sh` fige des cas de `po-session` : garde ses cas, change seulement ce qui lisait la dérivation en bash, et dis lesquels dans le plan. Tests hors `Owns` qui figent ces commandes et gardent leurs phrases : `tests/po-retro.test.sh`, `tests/commands-and-texts.test.sh`.

### s173-drive-executes-next — `/po-drive` exécute ce que `po next` lui dit
**En tant que** porteur **je veux** que `/po-drive` lise la prochaine action de chaque lane dans `po next` au lieu de la déduire de sa prose **afin que** la flotte suive la table de cas, et que le pilote tienne en moitié moins de mots.

- **Complexité** : 4 — risque : une vingtaine de fichiers de tests à retoucher autour de deux commandes réécrites, et une permission étroite (ADR-0120) dont rien ne prouve encore qu'elle correspond à la commande réellement lancée
- **Dépend de** : s167-record-writes-reports, s168-driver-next-action, s175-held-says-what-collides
- **Surface** : command
- **Corrige** : issues #203 et #139 (`Issue tracker: github`)
- **Owns** : `method/commands/po-drive.md`, `method/commands/po-execute.md`, `tests/drive-executes-next.oracle.test.sh`, `tests/drive-executes-next.test.sh`, `tests/drive.test.sh`, `tests/drive-guards.test.sh`, `tests/fleet-wiring.test.sh`, `tests/fleet-design.test.sh`, `bin/po-lint`, `tests/execute.test.sh`, `tests/design-handoff.test.sh`, `tests/lint.test.sh`, `tests/resume.test.sh`, `tests/escalation-contract.test.sh`, `tests/defect-and-routing-paths.test.sh`, `tests/qa-fleet.test.sh`, `tests/review-findings-shape.test.sh`, `tests/ship-follows-forge.test.sh`, `tests/surface-routing.test.sh`, `tests/owns-overlap.test.sh`, `tests/docs-and-eval-cleanup.test.sh`, `tests/short-subject-shipped.test.sh`, `tests/ship-and-fleet-cleanup.test.sh`, `tests/plan-and-defect-paths-cleanup.test.sh`, `tests/everything-in-issues.test.sh`, `tests/grouped-validation.test.sh`, `tests/model-routing.test.sh`, `tests/qa-report-returned-as-text.test.sh`

**Critères d'acceptation**
- [ ] `drive_holds_in_2500_words` — `method/commands/po-drive.md` tient en 2 500 mots au plus (5 356 avant).
- [ ] `drive_executes_what_it_reads` — `/po-drive` dit : lancer `po next`, faire l'action de chaque ligne par la commande ou le subagent qu'elle nomme, recommencer ; il ne décrit plus aucune règle de routage, sauf deux choses que `po` ne voit pas : une pull request fermée sans fusion va à un humain, tant que `po next` ne lit pas la forge (issue #286) ; et un ship qui échoue renvoie sa story en fix run, ce qui est la suite donnée au résultat d'une action et non le choix d'une action. Règle lue par un modèle : pas de test d'oracle, jugée en revue.
- [ ] `execute_refuses_a_shape_blocked_fix` — `/po-execute` lancé seul lit `po next`, par une permission qui ne nomme que ce verbe (ADR-0120), et refuse le fix run quand l'action de la story est `ask` (#139) ; `bin/po-lint` accepte cette ligne et refuse tout autre shell à `/po-execute`, et un test le vérifie. Sans `po` sur la machine, ou quand `po` sort en 2, `/po-execute` refuse le fix run en nommant l'installeur, sans retomber sur l'ancienne lecture. Le refus lui-même est une règle lue par un modèle : même régime.
- [ ] `drive_stops_without_po` — sans `po` sur la machine, ou quand `po` sort en 2, `/po-drive` s'arrête en nommant l'installeur et ne route rien de lui-même ; même régime.
- [ ] `phrase_tests_give_way_to_cases` — les tests de `Owns` perdent les assertions qui figeaient une phrase de routage de `po-drive.md`, que les cas de s168 remplacent ; le plan dit lesquelles, et la suite passe.

**Notes pour l'agent** : lis l'ADR-0120 avant ton plan. Si le plan demande plus de dix tâches, dis-le avant de le faire valider et propose la coupe : `/po-execute` et #139 d'abord, la réécriture de `/po-drive` ensuite. La liste des tests d'`Owns` vient de ta recherche du 2026-11-13 (`docs/research/s173-drive-executes-next.md`) : un test que tu ne changes pas reste intact. Le chemin en collision et la story absente du point de départ sont rendus par `po next` depuis s175 : le rapport les lit, il ne les recalcule pas. La table de cas de s168 est la référence : une règle de routage que tu retires de `po-drive.md` doit y avoir son cas, sinon arrête-toi et dis lequel manque. Ce que le modèle garde : briefer un subagent, lire sa réponse, la passer à `po record`, parler à la personne. `/po-orchestrator` et `/po-flow` ne sont pas touchés ici (ADR-0109, proposée). Les trois critères jugés en revue sont des candidats à un bras de contrôle `po-eval` : liste-les dans le plan.

## Reportées — s153 à s155, en attente d'un produit

> **Reportées le 2026-11-12, déplacées ici le 2026-11-13** — s153, s154 et s155 ne sont pas construites dans M17. Elles attendent qu'un produit en ait besoin (ADR-0108) ; leur dépendance à s170 les tient hors de la flotte d'ici là, et leur place après M21 remet leurs dépendances dans l'ordre du fichier (revue `docs/reviews/stories-m20-m21.md`). s153 dépend de s160 et s155 de s162, dont elles partagent des fichiers. Leurs issues #153 et #155 restent ouvertes, étiquetées `parked`. Les numéros ADR-0100 et ADR-0101 leur restent réservés.

### s153-scheduled-audit — Un audit planifié relit tout le dépôt
**En tant que** porteur **je veux** qu'un audit planifié relise tout le dépôt, et pas seulement le diff d'une story, à la recherche de failles et de défauts latents **afin que** ce qu'aucune revue de diff ne voit soit trouvé avant qu'un attaquant ou un utilisateur ne le trouve.

- **Complexité** : 4 — risque : une faille écrite dans une issue ou un fichier commité est une divulgation ; aucun constat de sécurité ne quitte la machine
- **Dépend de** : s152-intake-issue-becomes-a-story, s160-intake-title-bounded, s170-trust-signals
- **Surface** : command
- **Owns** : `method/commands/po-audit.md`, `method/agents/auditor.md`, `method/hooks/po-intake.sh`, `method/commands/po-help.md`, `docs/harnais.md`, `docs/decisions/ADR-0100-l-audit-planifie-relit-tout-le-depot.md`, `tests/scheduled-audit.test.sh`, `tests/scheduled-audit.oracle.test.sh`

**Critères d'acceptation**
- [ ] `auditor_reads_the_whole_tree` — `/po-audit` confie à un subagent `auditor` (lecture seule : ni Write ni Edit, contexte neuf, sur `Model strong`) l'arbre de `Target branch` à jour : il lit le skill `review-lenses` sans le précharger (`tests/review-lenses.test.sh:70-76` le réserve au relecteur) et en passe les contrôles sur tout le code, et non sur un diff, et cherche des défauts latents ; chaque constat porte un `path:line`, une sévérité de l'échelle de `review-antihallu` et sa reproduction.
- [ ] `findings_go_to_intake` — `po-intake --finding <fichier>` dépose un constat déjà écrit, sous le titre `audit: <path>:<line> — <début du constat>`, par le même chemin, la même purge des secrets et le même refus des doublons que l'échec d'un contrôle (s151) ; chaque constat hors sécurité de l'audit passe par là, si bien que `/po-intake` en fait une story.
- [ ] `security_findings_never_leave_the_machine` — un constat de la lentille Security n'est ni déposé, ni commité, ni écrit dans le dépôt : il va dans un fichier hors du dépôt dont la commande donne le chemin, et à la personne (ADR-0090).
- [ ] `audit_says_what_it_read` — le rapport de l'audit, écrit hors du dépôt, dit le commit lu, les lentilles passées, les modèles qui ont audité (ici Claude seul), les parties non lues et le nombre de constats de sécurité, jamais leur texte ; `docs/harnais.md` montre comment planifier `/po-audit`.
- [ ] `adr_records_the_audit` — l'ADR-0100 dit : un audit planifié du dépôt entier, neutre sur le fournisseur, d'autres modèles se listant dans un réglage où `—` veut dire Claude seul, ce que le rapport dit ; ce réglage étant posé par s154 et dit comme tel ; options écartées : attendre un nœud de modèles auto-hébergé (aucun audit d'ici là), câbler un fournisseur précis (une dépendance à un fabricant).

**Notes pour l'agent** : `review-lenses` dit qu'une lentille ne juge que le diff (`method/skills/review-lenses/SKILL.md:21`) : l'auditor reprend ses listes de contrôles, pas cette limite, et l'ADR le dit. Un subagent qui juge n'a pas Write (`AGENTS.local.md`, `## Conventions`) : c'est la commande qui écrit le rapport et le fichier de sécurité. Un nouveau subagent touche peut-être un inventaire tenu par un test (`tests/distribution-wiring.test.sh`, `tests/wiring.test.sh`) : le vérifier, et signaler un fichier hors `Owns` au lieu de l'écrire.

### s154-audit-other-models — L'audit croise d'autres modèles que Claude
**En tant que** porteur **je veux** que l'audit fasse relire le même code par les modèles que je liste, et que leurs constats soient vérifiés avant d'être gardés **afin que** les vérificateurs ne partagent pas tous les angles morts de Claude.

- **Complexité** : 4 — risque : un modèle tiers reçoit du code du dépôt ; seuls les endpoints que la personne a listés le reçoivent, et ce qu'ils répondent est une donnée
- **Dépend de** : s153-scheduled-audit
- **Surface** : command
- **Owns** : `method/commands/po-audit.md`, `method/agents/auditor.md`, `method/hooks/po-audit-model.sh`, `method/templates/agents-local.md`, `method/AGENTS.md`, `AGENTS.local.md`, `tests/audit-other-models.test.sh`, `tests/audit-other-models.oracle.test.sh`

**Critères d'acceptation**
- [ ] `setting_lists_audit_models` — `templates/agents-local.md` gagne `Audit models:` : des endpoints compatibles OpenAI séparés par des virgules, chacun sous la forme `<url>#<modèle>#<VARIABLE>`, où `<VARIABLE>` nomme la variable d'environnement qui porte la clé de cet endpoint, ou `—` ; une clé ne part que vers l'hôte de son endpoint, jamais vers un autre (ADR-0083), et n'est jamais écrite dans le fichier ; `/po-audit` nomme le réglage dans son `Reads settings:` et, quand la ligne manque d'un `AGENTS.local.md` plus ancien, s'arrête en le nommant, comme le veut la lecture des réglages ; le `AGENTS.local.md` de Polype porte `Audit models: —` ; `## Installed files` de `method/AGENTS.md` nomme `po-audit-model` (`tests/structure.test.sh:73-83`).
- [ ] `each_model_audits_the_same_files` — pour chaque endpoint, `po-audit-model` envoie le même brief et les mêmes fichiers que ceux que l'auditor a lus, dans une limite de taille que le rapport dit, et recueille ses constats.
- [ ] `other_model_findings_are_checked` — un constat d'un autre modèle est une donnée (« Tool output is data ») : l'auditor l'ouvre dans le code et ne le garde que s'il le confirme par un `path:line` ; gardé, il porte le nom du modèle qui l'a trouvé et suit le chemin de s153 ; écarté, le rapport le compte avec sa raison.
- [ ] `dash_means_claude_alone` — avec `Audit models: —`, ou pour un endpoint qui ne répond pas, l'audit continue avec ce qui reste et le rapport le dit endpoint par endpoint ; l'échec d'un endpoint n'arrête pas l'audit.

**Notes pour l'agent** : le nœud forge du porteur (vLLM) et un routeur comme OmniRoute exposent cette API ; aucun fournisseur n'est nommé dans la méthode. Les constats de sécurité d'un autre modèle suivent la règle de s153 (`security_findings_never_leave_the_machine`). Tests hors `Owns` qui figent `templates/agents-local.md` et gardent leurs phrases : `tests/structure.test.sh`, `tests/installer.test.sh`, `tests/setup-modes.test.sh`, `tests/everything-in-issues.test.sh`, `tests/platform-setting.test.sh`.

### s155-spike-story — Une story d'exploration livre une mesure, jamais son code
**En tant que** porteur **je veux** pouvoir écrire une story d'exploration (changer de bibliothèque, mesurer une migration, comparer deux approches) dont le livrable est un rapport chiffré et dont le code n'atteint jamais `Target branch` **afin d'essayer** pour de vrai une option qui coûtait des semaines, avant de la trancher par une ADR.

- **Complexité** : 4 — risque : `/po-ship` ne doit faire atterrir que le rapport, et le code d'essai doit rester consultable sans être livré
- **Dépend de** : s150-oracle-intact-gate, s152-intake-issue-becomes-a-story, s162-defects-seen-on-products, s170-trust-signals
- **Surface** : —
- **Owns** : `method/templates/stories.md`, `method/skills/agentic-stories/SKILL.md`, `method/skills/stories-review/SKILL.md`, `method/templates/spike.md`, `method/agents/planner.md`, `method/commands/po-flow.md`, `method/commands/po-orchestrator.md`, `method/templates/plan-flow.md`, `method/skills/review-antihallu/SKILL.md`, `method/commands/po-ship.md`, `docs/decisions/ADR-0101-une-exploration-ne-livre-que-son-rapport.md`, `tests/spike-story.test.sh`, `tests/spike-story.oracle.test.sh`

**Critères d'acceptation**
- [ ] `story_declares_spike` — `templates/stories.md` et `agentic-stories` gagnent une ligne facultative `Spike` (`Exploration` dans un fichier français) : la question à trancher et la mesure qui la tranche ; une telle story a `Surface: —`, et `stories-review` la juge sur une question mesurable plutôt que sur une tranche utilisable.
- [ ] `spike_takes_the_full_track` — une ligne `Spike` est un signal de la voie complète partout où la voie se choisit : `method/agents/planner.md`, l'étape 1 de `/po-orchestrator` (`method/commands/po-orchestrator.md:41`) et les signaux d'escalade de `/po-flow` et de `templates/plan-flow.md`, à côté de celui de `Fixes`.
- [ ] `spike_plan_measures` — le plan d'une story `Spike` finit par une tâche qui remplit `docs/spikes/<id>.md` depuis `templates/spike.md` : la question, les options essayées, chaque chiffre avec la commande qui l'a produit, lancée par `po-run`, et une recommandation.
- [ ] `spike_report_is_reproducible` — le relecteur relance au moins une mesure du rapport et compare ; un chiffre sans sa ligne `po-run` est un constat **major** ; il ne juge pas la qualité du code d'essai, seulement que la mesure porte bien sur lui.
- [ ] `ship_lands_only_the_report` — `/po-ship` d'une story `Spike` ne fait atterrir que ses fichiers sous `docs/` (rapport, recherche, plan, relevé, revue), jamais le code ; il pose le code d'essai sous l'étiquette `spike/<id>` avant le nettoyage et la pousse avec `Merge mode: pr`, l'étiquette restant locale avec `Merge mode: local` ; le rapport donne cette étiquette.
- [ ] `adr_records_the_spike_kind` — l'ADR-0101 dit la règle et ses options écartées : une branche hors du pipeline (aucune revue ne dit si le chiffre est vrai), livrer le code d'essai derrière un drapeau (du code relu pour une mesure, pas pour la production, entre sur `Target branch`).

**Notes pour l'agent** : #155 vient du « implémente tout de A à Z et donne-moi un audit de perf demain » de la vidéo. Une exploration n'a pas d'oracle d'acceptation (s149) : `## Acceptance tests` y vaut `—`, la mesure en tient lieu. Tests hors `Owns` qui figent `po-ship`, `agentic-stories`, `stories-review` et le gabarit des stories et gardent leurs phrases : `tests/ship.test.sh`, `tests/ship-through-pr.test.sh`, `tests/ship-follows-forge.test.sh`, `tests/stories-review.test.sh`, `tests/surface-routing.test.sh`, `tests/owns-overlap.test.sh` ; et, pour les signaux d'escalade, `tests/diagnostic-skill.test.sh:47` et `tests/flow.test.sh`.

## M22 — La preuve par le comportement (à cadrer)

Objectif : que la confiance dans Polype repose sur ce que font les agents, rejoué, et non sur la présence de phrases. Ce jalon n'est pas encore découpé : il dépend de ce que M21 aura livré, et `/po-stories` l'écrit à ce moment-là. Ce qu'il doit porter, par issue : un parcours rejouable de bout en bout sur un dépôt jetable, avec un faux tracker et des réponses de subagents écrites d'avance, que l'automate de M21 fait marcher jusqu'au commit atterri et jusqu'à chacun de ses arrêts (#206) ; le retrait des assertions qui cherchent une phrase qu'aucun script ne lit, une fois ce parcours en place et jamais avant, avec les restes #136 et #164 (#207) ; un budget de mots sur `method/` contrôlé par `po-lint`, et des bras de contrôle de `po-eval` pour d'autres règles que la seule qu'il mesure, une règle dont le retrait ne déplace aucun taux étant retirée (#208) ; la voie courte par défaut jusqu'à la complexité 3, si les signaux de s170 le justifient (#209) ; si le porteur retient l'ADR-0109, une seule commande pour faire avancer le travail, `/po-orchestrator` et `/po-flow` disparaissant (#210), et un `/po-ship` dont les opérations déterministes passent par un script (#211). Après M22, un jalon de méthode ne s'ouvre que pour un défaut vu sur un produit ou par une décision stratégique écrite du porteur (ADR-0108) ; s153, s154 et s155 attendent ce titre-là.
