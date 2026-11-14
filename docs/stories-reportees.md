# Stories reportées

[Stories](stories.md)

Stories écrites et relues, que personne ne construit tant qu'un produit n'en a pas besoin (ADR-0108). Elles sont hors de `docs/stories.md` pour que `po` ne les lise pas : une story qui y figure et dont les dépendances sont livrées est annoncée prête. Pour en reprendre une, replace son texte dans `docs/stories.md`, sous le jalon qui la porte.

## Reportées — s153 à s155, en attente d'un produit

> **Reportées le 2026-11-12, sorties de `docs/stories.md` le 2026-11-14** — s153, s154 et s155 ne sont pas construites. Elles attendent qu'un produit en ait besoin (ADR-0108), et c'est leur absence de `docs/stories.md` qui les tient hors de la flotte (décision d-0016 du porteur) : leurs lignes `Dépend de` disent ce dont elles ont besoin, pas quand les construire. s153 dépend de s160 et s155 de s162, dont elles partagent des fichiers. Leurs issues #153 et #155 restent ouvertes, étiquetées `parked`. Les numéros ADR-0100 et ADR-0101 leur restent réservés.

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
