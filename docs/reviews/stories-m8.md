# Stories review — Polype, milestone M8 "Toutes les plateformes" (s78–s91)

> One-off review run outside `/po-stories-review` (Polype has no PRD or brief, `Entry mode: —`), by the `stories-reviewer` subagent in a fresh context, on 2026-10-08. First pass, on the framing commit `bc83edb`. Scope source: ADR-0054, plus the file-based retro, the diagnostic procedure and accessibility beyond contrast from the "Plus tard" list of `docs/references/gstack-agent-skills.md`. Scope kept out: lessons, post-deploy verification and revert, the Android emulator, the iOS simulator and real hardware. Not a Polype verdict: `/po-research` does not read this file.

Review status: complete

## Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| `Platform` setting, asked by `/po-setup`, picks the profiles offered and the drivers that apply | ADR-0054 Decision, Plateforme | s78, s79 | yes (contract order is wrong, see findings) |
| `Surface` line in each story; a story without one keeps the old rule | ADR-0054, Surface | s78, s80 | yes |
| Only a `screen` surface goes through design | ADR-0054, Design | s80 | yes |
| A `scene` has no design system; its visual cues go in the plan | ADR-0054, Design | none | **no** |
| `QA stage`: `screens` / `surfaces` / `—` | ADR-0054, QA | s78 (setting), s80 (routing) | partly: the `Dev` stops are left in place (major below) |
| One `qa` agent with one driver per surface: skill `qa-drivers`, one file per driver, preloaded, a missing driver file stops QA | ADR-0054, Pilotes / Neutral | s79 | yes |
| Driver for `screen` on web: the browser | ADR-0054 table | s79 | yes |
| Driver for `screen` on mobile: the web render at phone width | ADR-0054 table | s82 | yes |
| Driver for `command` / `endpoint`: shell scenarios and their transcripts | ADR-0054 table | s81 | yes |
| Driver for `scene`: headless engine render or WebXR | ADR-0054 table | s87 | yes (depends on the uncovered plan item) |
| Driver for `behaviour`: headless ROS 2 + Gazebo, with logs and topic recordings | ADR-0054 table | s88 | yes |
| Each profile declares its platform and its QA driver | ADR-0054, Profils | s79 | yes |
| Profiles for Expo, Flutter, native iOS and Android, Rust CLI, Hono API, Godot, ROS 2 + Gazebo | ADR-0054, Profils | s83, s84, s85, s86, s87, s88 | yes |
| Out of reach: the QA report says so | ADR-0054, Hors de portée | s79, s82, s85, s87, s88 | yes |
| Out of reach: the review carries it to "Not verified" | ADR-0054, Hors de portée | none | **no** (graded major below) |
| File-based retro | gstack "Plus tard" | s89 | yes |
| Diagnostic procedure, preloaded by the planner | gstack "Plus tard" | s90 | yes |
| Accessibility beyond contrast, in `design-doctrine` | gstack "Plus tard" | s91 | yes |

## Exclusions
No story brings back lessons, post-deploy verification or revert, the Android emulator, the iOS simulator or real hardware. s85 writes the native profiles that ADR-0054 asks for and says their screen QA stays `blocked`; it does not add the emulator.

## Checks
- [x] Exclusions
- [x] No technical layer dressed as a story. s78 is the contract (the `Surface` line and `Platform`) and has two later consumers, s79 and s80.
- [ ] Every criterion checkable by one test: s90 `planner_preloads_diagnostic` has a trigger nobody can see (minor).
- [x] Dependency order: every `Dépend de` points to an earlier id.
- [ ] Complexity: s79 and s80 are scored 4 and name no risk. No M8 story has a "Notes for the agent" section.
- [x] Ids: `s78`–`s91`, unique, increasing.
- [x] Owns overlap: the only shared path is `method/skills/design-doctrine/`, held by s82 and s91, and s91 depends on s82. The `qa-drivers/` files are disjoint per story. `AGENTS.local.md` (s78) and `method/AGENTS.md` (s80) are disjoint. Several needed paths are missing (below).

## Findings
- **critical — milestone (s87, s80, s90).** ADR-0054 says the visual cues of a `scene` go in the plan. No story makes the planner or `method/templates/plan.md` write them. Nothing in `method/` mentions a scene or a viewpoint today. Yet s87 `scene_driver_captures_without_a_window` captures "des points de vue nommés dans le plan", and s80 `review_requires_qa_for_a_surface` judges a scene "contre son plan". Both rely on a plan section nobody writes. The fix needs a criterion and `method/templates/plan.md` in some story's Owns. If that story also changes `method/agents/planner.md`, which s90 owns, it must depend on s90 or s90 on it.
- **major — s78/s79.** A project without `Dev` can never reach `surfaces`:
  - `po-setup.md:39` skips the `QA stage` question when `Dev` is `—` (s78 owns that file).
  - `po-qa.md:26` stops on `Dev` = `—` and `po-qa.md:27` on "The story shows no screen". `qa.md:29` stops on `Dev` = `—`, `qa.md:30` requires a tool that opens a page, `qa.md:35` scopes the walk to criteria seen "on a screen", and `qa.md:41` starts `Dev` (s79 owns both files).
  - `agents-local.md:81` defines `Dev` as a dev server.

  A CLI or a library, Polype included (s78 sets `Platform: cli`), would never be QA'd. No criterion of s78 or s79 lifts these stops for a non-`screen` surface. `tests/qa.test.sh:46,51` pin two of these phrases; s79 owns that test.
- **major — s80, Owns.** These files keep the "screen / `QA stage: screens`" wording that s80 rewrites, and s80 does not own them:
  - `method/templates/review.md:24`, pinned by `tests/qa-gate.test.sh:119`.
  - `method/agents/implementer.md:37`, pinned by `tests/qa-gate.test.sh:126`.
  - `README.md:31`, pinned by `tests/qa-fleet.test.sh:100`.
  - `method/commands/po-help.md:31`, pinned by `tests/qa-fleet.test.sh:96`.
  - `tests/qa-gate.test.sh:100`, which pins the `/po-qa` row of `method/AGENTS.md` that `rules_speak_of_surfaces` rewrites.
  - `method/commands/po-flow.md:37-42`: its escalation signals list "a new screen" only, so under `surfaces` a `command` story could take the short track, which has no QA. Its review would then be blocked.

  `po-help.md` is owned by s89, and s80 and s89 have no dependency between them. Adding it to s80 needs a dependency, or the help line must move into s89's scope.
- **major — s80.** No criterion makes the review move what QA left out of reach (real hardware, iOS simulator, native-only behaviour, headset) into "Not verified". Today `review-antihallu` line 28 moves only probable and unverified QA findings there, not `## Not seen`.
- **major — s78/s79.** The contract is defined after its first use. s78 `setup_asks_the_platform` filters profiles by their platform, but the `## Platform` section of profiles is created by s79, which depends on s78. Either move the profile-template section and the `po-lint` rule into s78, or move the setup filter into s79.
- **major — s82/s83/s84.** It is not defined where the web-render command lives:
  - s82 says "la commande vient du profil", and s83/s84 require the profile to "donne[r] la commande qui sert le rendu web" and to pass `po-lint`.
  - The profile's `## Commands` block holds only `Install/Test/Typecheck/E2E/Build`, and `bin/po-lint:238` refuses any other name.
  - The `qa` agent starts `Dev` from `AGENTS.local.md`, not from the profile.

  s79 owns `templates/profile.md`, so it should add `Dev` there, or s82 should say the driver uses `Dev`.
- **major — s79.** Complexity 4 with no risk named, and there are no notes.
- **major — s80.** Complexity 4 with no risk named, and there are no notes.
- **minor — s78.** `tests/setup-modes.test.sh:33` and `tests/qa.test.sh:66` pin exactly five numbered questions in step 2 of `/po-setup`. Ask `Platform` as an unnumbered follow-up (as `QA stage` is), or own the test that pins it. Of those two tests, only `qa.test.sh` is owned in M8 (by s79).
- **minor — s78.** The ADR's consequence says `/po-stories-review` must check the `Surface` line. No story owns `method/skills/stories-review/` or `method/agents/stories-reviewer.md`.
- **minor — s80.** `qa_follows_the_qa_stage` does not say what happens under `surfaces` to a story without a `Surface` line. Only the design fallback is stated.
- **minor — s79/s80.** These two run side by side with no dependency. s80 may send a non-screen story to `/po-qa` before s79 removes `po-qa.md:27` ("shows no screen → stop"). Consider making s80 depend on s79.
- **minor — s91.** It rewrites `## Driving a browser`, whose four lead phrases are pinned by `tests/qa.test.sh:27-30` (written once in `method/`). Keep them; s91 does not own that test.
- **minor — s81/s88.** Scenarios and simulations write outside `docs/qa/<id>/` (build directories, rosbag files) through shell side effects that `po-bounds` cannot see. Say where those artefacts go and that the tree must be clean after the run (`qa.md:28`).
- **minor — s89.** The reference names QA reports as the best data for a retro, but `retro_reads_only_recorded_facts` does not read `docs/qa/*`.
- **minor — s90.** Nothing marks a story as a defect fix, so "quand la story corrige un défaut" cannot be decided. Also, `/po-flow` uses no planner, so with `Story track: auto` and `Flow threshold: 2` a small defect story never gets the skill.
- **minor — milestone.** No M8 story has a "Notes for the agent" section. The pitfalls above belong there.

## Not verified
- The suite and `bin/po-lint` were not run. Tests beyond those cited were not read in full.
- Whether the upstream starter templates exist, at which commit, under which licence (Expo, Flutter, native iOS and Android, Rust/clap, Hono, Godot, ROS 2 + Gazebo). Whether headless Godot or Gazebo rendering works on this machine.
- How the `qa` mode of `po-bounds` treats shell redirections and `tee` into `docs/qa/<id>/`, which the scenario transcripts need. Only the header of `po-bounds.sh` was read.
- How `polype check .` detects a missing setting, which s78's `polype_declares_its_platform` relies on. `bin/polype` was only searched.
- Whether `po-lint` accepts placeholder content in `## Capabilities` and `## UI inventory` for non-web profiles (CLI, ROS 2).
- Whether s78's `Platform` setting also has to appear in `po-help.md` or `README.md`.
- M8's Owns were compared only with each other, not with stories of earlier milestones still in flight.

Max severity: critical
Stories ready: no

---

# Stories review: Polype, milestone M8 "Toutes les plateformes" (s78–s91), second pass

This review was run outside `/po-stories-review`, because Polype has no PRD or brief (`Entry mode: —`). It was done in a fresh context on 2026-10-08, against the stories as revised at `db261e6`.

- **Scope source:** `/home/lecrabe/dev/atoll/polype/docs/decisions/ADR-0054-polype-verifie-une-surface-pas-seulement-un-ecran.md`, plus three entries of the "Plus tard" list in `/home/lecrabe/dev/atoll/polype/docs/references/gstack-agent-skills.md`: the file-based retro, the diagnostic procedure, and accessibility beyond contrast.
- **Scope kept out:** lessons, post-deploy verification and revert, the Android emulator, the iOS simulator and real hardware.
- **First pass:** `/home/lecrabe/dev/atoll/polype/docs/reviews/stories-m8.md`.

Review status: complete

## Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| `Platform` setting: a list, asked by `/po-setup`; it picks the profiles offered and the drivers that apply | ADR-0054, Plateforme | s78 (setting, setup, profile filter), s79 (driver by surface and platform) | yes |
| `Surface` line in every story; a story without it keeps the old rule | ADR-0054, Surface | s78 (template, skill, `/po-stories`, `stories-review`), s80 (fallback rule) | yes |
| Only a `screen` surface goes through design | ADR-0054, Design | s80 `design_follows_a_screen_surface` | yes |
| A `scene` has no design system; its visual cues go in the plan | ADR-0054, Design | s87 `plan_names_scene_viewpoints`, s80 (review judges against the plan) | yes on the full track; not on the short track (major below) |
| `QA stage`: `screens` / `surfaces` / `—` | ADR-0054, QA | s78 (setting, setup asks it without `Dev`), s79 (QA runs without a screen), s80 (routing, `/po-flow` escalation) | yes |
| One `qa` agent with one driver per surface: skill `qa-drivers`, one file per driver, preloaded; a missing driver file stops QA | ADR-0054, Pilotes / Neutral | s79 | yes |
| Driver for `screen` on web: the browser | ADR-0054 table | s79 `browser_driver_is_the_first_one` | yes |
| Driver for `screen` on mobile: the web render at phone width | ADR-0054 table | s82 | yes |
| Driver for `command` / `endpoint`: shell scenarios and their transcripts | ADR-0054 table | s81 | yes |
| Driver for `scene`: headless render or WebXR, scene captures | ADR-0054 table | s87 | yes |
| Driver for `behaviour`: headless ROS 2 + Gazebo, logs and topic recordings | ADR-0054 table | s88 | yes |
| Each profile declares its platform and its QA driver | ADR-0054, Profils | s78 (`## Platform`), s79 (`## QA driver`, `Dev` in `## Commands`) | yes |
| Profiles: Expo, Flutter, native iOS and Android, Rust CLI, Hono API, Godot, ROS 2 + Gazebo | ADR-0054, Profils | s83, s84, s85, s86, s87, s88 | yes |
| Out of reach: the QA report says so | ADR-0054, Hors de portée | s79 `qa_report_names_its_driver`, s82, s85, s87, s88 | yes |
| Out of reach: the review carries it to "Not verified" | ADR-0054, Hors de portée | s80 `review_requires_qa_for_a_surface` | yes |
| File-based retro, QA reports included | gstack "Plus tard" | s89 | yes |
| Diagnostic procedure, preloaded by the planner for a defect story | gstack "Plus tard" | s90 | yes |
| Accessibility beyond contrast, in `design-doctrine` | gstack "Plus tard" | s91 | yes |

No M8 story traces to nothing: s78–s91 each serve a row above.

## Exclusions
| Excluded item | Source section | Revived by | Revived |
| --- | --- | --- | --- |
| Lessons proposed by the review | caller's kept-out list | none | no |
| Post-deploy verification and revert | caller's kept-out list | none | no |
| Android emulator | caller's kept-out list / ADR-0054 | none: s85 only says it comes in a later batch and keeps native screen QA `blocked` | no |
| iOS simulator | caller's kept-out list / ADR-0054 | none: s85 says it needs a Mac; s79 and s87 report what it would show as not seen | no |
| Real hardware (phone, headset, robot) | caller's kept-out list / ADR-0054 | none: s82, s87 and s88 report it as not seen | no |

## Checks
- [x] Exclusions: no story revives an excluded item.
- [x] No technical layer dressed as a story. s78 is the contract story (`Platform`, `Surface`, `## Platform` of profiles), and s79 and s80 consume it. In this repository the "user" of a method story is the developer running the pipeline, and every story names a behaviour a test can read.
- [x] Every criterion can be checked by one test. Each criterion names the file and the clause a bash test can quote. No story has more than five criteria.
- [x] Dependency order. The `Dépend de` lines run s79→s78, s80→s79, s81→s79, s82→s79, s83/s84/s85→s82, s86→s81, s87→s79, s88→s79, s89→s80, s90→s80, s91→s82. Every target exists and comes earlier in the file.
- [x] Complexity: no 5. s79 and s80 are scored 4 and now name their risk.
- [x] Ids: `s78`–`s91`, form `s<number>-<slug>`, unique, increasing in file order.
- [x] Owns: every story declares one. These entries are shared:

  | Shared entry | Stories | Dependency |
  | --- | --- | --- |
  | `method/templates/profile.md`, `bin/po-lint`, `boilerplates/next-forge/profile.md`, `tests/profile.test.sh`, `tests/next-forge-profile.test.sh` | s78, s79 | s79 depends on s78 |
  | `method/commands/po-flow.md` | s80, s90 | s90 depends on s80 |
  | `method/commands/po-help.md` | s80, s89 | s89 depends on s80 |
  | `method/skills/design-doctrine/` | s82, s91 | s91 depends on s82 |

  Every other pair is disjoint:
  - `qa-drivers/` is split file by file: s79 holds `SKILL.md` and `browser.md`; s81, s82, s87 and s88 hold `scenarios.md`, `mobile-web.md`, `scene.md` and `simulation.md`.
  - Each profile story owns its own `boilerplates/<name>/`.
  - `method/templates/plan.md` (s87) and `method/agents/planner.md` (s90) are disjoint files.
  - No `.worktrees/` lane is in flight, so no earlier story can collide.

## First-pass findings: are they closed?
| First-pass finding | Status | Where |
| --- | --- | --- |
| critical: nobody writes a scene's viewpoints in the plan | **closed** on the full track | s87 owns `method/templates/plan.md`, criterion `plan_names_scene_viewpoints`. A remaining gap on the short track and in the contract order is graded major below. |
| major: a project without `Dev` can never reach `surfaces` | **closed** | s78 `setup_asks_the_platform` (asks `QA stage` when a platform has no screen), s78 `platform_is_a_setting` (redefines `Dev`), s79 `qa_runs_without_a_screen` (lifts the stops at `po-qa.md:26-27` and `qa.md:29-30,35`). s79 owns `tests/qa.test.sh`. |
| major: s80 Owns misses files keeping the screen wording | **closed** | s80 now owns `method/templates/review.md`, `method/agents/implementer.md`, `README.md`, `method/commands/po-help.md`, `method/commands/po-flow.md`, `tests/qa-gate.test.sh` and `tests/qa-fleet.test.sh`. s89 depends on s80 for `po-help.md`. |
| major: the review does not carry what QA could not see to "Not verified" | **closed** | s80 `review_requires_qa_for_a_surface`; s80 owns `method/skills/review-antihallu/` and `method/agents/reviewer.md`. |
| major: the contract is defined after its first use (s78/s79, profile `## Platform`) | **closed** | s78 now owns `method/templates/profile.md` and `bin/po-lint` and writes `## Platform` itself (`profiles_declare_their_platform`). |
| major: where the web-render command lives | **closed** | s79 `profiles_declare_their_driver` adds `Dev` to the profile's `## Commands`. s82 serves the render "par la commande `Dev`". s83 and s84 depend on s82. |
| major: s79 is a 4 with no risk | **closed** | s79 complexity line |
| major: s80 is a 4 with no risk | **closed** | s80 complexity line |
| minor: five numbered setup questions are pinned | **closed** | s78 note (`Platform` is an unnumbered follow-up); s78 owns `tests/setup-modes.test.sh` |
| minor: no story owns `stories-review` | **closed for the skill** | s78 owns `method/skills/stories-review/`. A residual on the agent's settings line is listed below. |
| minor: `surfaces` with no `Surface` line | **closed** | s80 `qa_follows_the_qa_stage` (the old screen rule) |
| minor: s79/s80 run side by side | **closed** | s80 now depends on s79 |
| minor: s91 rewrites pinned lead phrases | **closed** | s91 note (and the same note on s82) |
| minor: s81/s88 artefacts outside `docs/qa/<id>/` | **closed in the drivers** | s81 `scenarios_leave_the_tree_clean`, s88 (raw recordings in the temp dir), s79 note. A clause of `qa.md` that contradicts this is listed below. |
| minor: s89 ignores QA reports | **closed** | `retro_reads_only_recorded_facts` reads `docs/qa/*` |
| minor: s90 trigger and `/po-flow` | **partly closed** | A `Corrige` line now marks a defect story, and `/po-flow` escalates it. The line is not in the stories template (minor below). |
| minor: no M8 story has notes | **mostly closed** | s78, s79, s80, s82, s87 and s91 carry notes. s81, s83–s86 and s88–s90 have none, which is acceptable at their size. |

## Findings
- **major — s80/s87, contract order.** The plan's scene-viewpoints section is an interface shared by two stories, and neither depends on the other:
  - s87 `plan_names_scene_viewpoints` creates the section in `method/templates/plan.md`.
  - s80 `review_requires_qa_for_a_surface` already has the reviewer judge a `scene` "contre les points de vue de son plan".
  - s80 sits earlier and depends only on s79, so for a while it refers to a section that does not exist yet.

  Fix it in one of two ways:
  - Move the scene clause of `review_requires_qa_for_a_surface` into s87. s87 then has to depend on s80, since it would touch `reviewer.md` / `review-antihallu/`.
  - Move `plan_names_scene_viewpoints` (and `method/templates/plan.md`) into s79 or s80.
- **major — s80/s87, the short track carries no viewpoints.** Only `method/templates/plan.md` gets the section; `method/templates/plan-flow.md` does not, and no M8 story owns it. Two paths lead a `scene` story to that template:
  - In the fleet, the `planner` chooses the track itself (`method/agents/planner.md:26-32`), and its escalation signals still name only "a new screen". s80's `flow_escalates_a_surface_with_qa` covers `/po-flow`, not the planner.
  - Under `QA stage: surfaces`, `/po-drive` runs QA whatever the track.

  So a `scene` story at or below `Flow threshold` gets a `plan-flow.md` plan with no viewpoints. s87's driver ("capturer chaque point de vue du plan") then has nothing to capture, and s80's reviewer has nothing to judge against. Either make the planner send a story that `QA stage` sends to QA (or at least a `scene` story) to the full track, or add the section to `plan-flow.md`, and put the file in an Owns. s90 owns `planner.md` and depends on s80, so s90 can carry the planner half.
- **minor — s78.** Two phrases about `Dev` constrain s78 and s79:
  - `tests/qa.test.sh:62` pins `` `Dev` starts the development server `` in `method/templates/agents-local.md`. s78 rewrites that definition but does not own `tests/qa.test.sh` (s79 does), and its note warns only about the five numbered questions. The phrase must survive word for word.
  - `agents-local.md:81` goes on "`/po-qa` needs it and stops on `—`". That stops being true once s79 ships, and s79 does not own `agents-local.md`. Either s78 words it for s79's behaviour in advance, or s79 adds `method/templates/agents-local.md` to its Owns (safe, since s79 depends on s78).
- **minor — s78.** `stories_declare_a_surface` has `stories-review` check each surface against the project's platforms, so the `stories-reviewer` subagent now reads `Platform`. Its `Reads settings:` line (`method/agents/stories-reviewer.md:12`) and `method/commands/po-stories-review.md:13` must list `Platform` (repository convention), and s78 owns neither file. The criterion also does not grade a story with no `Surface` line. ADR-0054 says such a story keeps the old rule, so it should not weigh like a broken story.
- **minor — s79.** `method/agents/qa.md:54` says tools beyond the hook's reach "are never used to write a file outside `docs/qa/<id>/`". This contradicts:
  - s79's own note (driver files go "sous le répertoire temporaire");
  - s81 `scenarios_leave_the_tree_clean`;
  - s88's raw recordings in the temp dir.

  s79 owns `qa.md`, but no criterion makes it change that line. Add the temp-dir exception to `qa_runs_without_a_screen`.
- **minor — s79.** `qa_picks_the_driver_of_the_surface` stops QA when a driver file is missing, but it does not say where the agent looks. Under the global pose the skill lives in `~/.claude/skills/qa-drivers/`, and under the project pose in `.claude/skills/qa-drivers/`. A check against a single path would misfire on the other.
- **minor — s81.** The `qa` mode of `po-bounds` allows only reading git verbs, everywhere, temp dir included (`method/hooks/po-bounds.sh:13-17, 728-729`). Unlike the reviewer, it has no throwaway-repo zone. A scenario for a CLI that needs a git fixture cannot build it: `git init`, `git commit` in the temp dir. Polype itself is one such CLI, and s78 makes it `Platform: cli`. No M8 story owns `po-bounds.sh`. Today Polype keeps `QA stage: —`, so nothing breaks yet; the driver should name the limit.
- **minor — s90.** `defect_stories_get_the_diagnostic` keys on a `Corrige` line. Polype's own `docs/stories.md` uses that line (lines 319, 340…), but neither `method/templates/stories.md` nor `agentic-stories` defines it. A project that follows the template never writes it, so the skill never triggers there. s90 can own the template safely, since it reaches s78 through s80→s79.
- **minor — s80/s90.** Each adds a reason to leave the short track, which makes "five signals" stale. The phrase appears in `method/commands/po-flow.md:37,61` (s80 and s90 own it), in `method/agents/planner.md:32,39` (s90) and in `method/templates/plan-flow.md:13` ("Each of the five"), which nobody owns. `tests/flow.test.sh:38-48` pins only the signal names, so additions do not break it.

## Not verified
- The suite and `bin/po-lint` were not run. Only the tests cited above were read, and some only in part (`qa.test.sh`, `flow.test.sh`, `leftovers.test.sh`, `catalogue-wiring.test.sh` fully; `profile.test.sh` and `lint.test.sh` by search).
- Whether upstream starter templates exist, at which commit and under which licence, for Expo, Flutter, native iOS and Android, Rust/clap, Hono, Godot and ROS 2 + Gazebo. Also whether headless Godot or Gazebo rendering works on this machine. These are outside the files in scope.
- Whether `bin/po-lint` will accept profiles that are almost empty in `## Capabilities` and `## UI inventory` (CLI, API, ROS 2). s78's note asks the implementer to check this; only the lint's profile rule header was read (`bin/po-lint:184-256`).
- How `po-bounds` finds the `Owns` line once a `Surface` line sits between `Dépend de` and `Owns`. The match at `po-bounds.sh:161` looks anchored on `**Owns**` and should be unaffected, but it was not exercised.
- Whether s78's platform filter fits the catalogue phrases pinned by `tests/catalogue-wiring.test.sh:10-16`, which no M8 story owns. They look additive-compatible; that was not proven.
- Whether `method/commands/po-design.md:24` and `method/agents/designer.md:23` ("the story has no screen to show → stop") should read the `Surface` line. They are judged consistent with s80's routing, since only `screen` stories reach design, but a story whose surface is `screen` while its text shows no screen was not considered.
- The French documentation under `docs/` (other than the files read) was not checked for screen-only QA wording.

Max severity: major
Stories ready: yes

> Answered at the next commit: the scene-viewpoints criterion moved to s80, which now owns both plan templates (full and short), and s87 depends on s80; s78 owns the stories-reviewer's settings lines and grades a missing `Surface` as minor; s79 owns `agents-local.md`, states the temp-dir exception and where a driver file is looked up; s81 names the `qa` git limit; s90 defines `Corrige` in the stories template and updates the "five signals" texts, `plan-flow.md` included.
