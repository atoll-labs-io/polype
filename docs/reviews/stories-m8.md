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
