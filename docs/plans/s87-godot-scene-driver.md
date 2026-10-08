---
validated: yes
---
# Plan — s87-godot-scene-driver

Validated autonomously (`Plan validation: autonomous`): no human reviewed it. Branch `story/s87-godot-scene-driver`. Read `docs/research/s87-godot-scene-driver.md` first; this plan builds on it without repeating it (`XT:`, `GD:` as defined there). The capture route and the starter are settled in `docs/decisions/ADR-0065-le-pilote-scene-rend-chaque-point-de-vue-sur-un-affichage-virtuel.md`, written by the planner, `accepted`, uncommitted: commit it with the code, never edit its body.

## Story
A Godot profile and a driver that captures, with no visible window, the viewpoints the plan names.
- `godot_profile_passes_the_lint` — `boilerplates/godot/profile.md` follows the template, written from a public, freely licensed starter at a named commit, platform `xr`, driver `scene`; `bin/po-lint` accepts it.
- `scene_driver_captures_without_a_window` — `qa-drivers/scene.md` renders the scene without a window (or in a browser for WebXR), captures each viewpoint of the plan, and names what only a headset would show (comfort, scale, hand tracking) as not seen.

Reading of "without a window" (research, first fact): no window on a display a person sees. Godot's `--headless` renders nothing, so the driver renders on a virtual display.

## Tasks
1. [x] **The driver** — create `method/skills/qa-drivers/scene.md`, English, own words, title `# Driver — scene`, the five headings of `mobile-web.md` verbatim and in order (`## Needs`, `## Start and stop`, `## Exercising a criterion`, `## Evidence`, `## Cannot show`). Phrases in quotes below are written **verbatim** (the test quotes them).
   - Intro: checks a `scene` surface on the `xr` platform by rendering the scene with its engine at each viewpoint the plan names, on a virtual display, "never on a display a person sees" (ADR-0054, ADR-0065). Evidence: scene captures.
   - `## Needs`:
     - the viewpoints: the "`## Scene viewpoints` section of `docs/plans/<id>.md`", a file of the story's diff. Absent, `—` or empty → "the QA ends with `QA status: blocked`: the plan names no viewpoint".
     - the engine command, found in `AGENTS.local.md` (its `## Commands` and conventions), in the boilerplate profile those conventions name, or in the README; never invented.
     - a virtual display: `xvfb-run` (Xvfb) on the machine.
     - Engine command or virtual display missing, and no browser route (below) → `QA status: blocked` with that cause.
     - One sentence: "`--headless` draws nothing" in Godot, so the engine's headless mode is never used for a capture; a blank image is not evidence (ADR-0065).
     - Browser route, in a short paragraph: when the project names no engine command but `Dev` serves a WebXR page, and a tool of the session opens a page and captures it, the driver uses that page instead.
   - `## Start and stop` (written in full: an `xr`-only project reads no other driver):
     - Copy into the `mktemp -d` directory of `qa-drivers` the files `git -C <path> ls-files` lists plus the ignored `.env*` files, keeping `git -C <path> status --porcelain --ignored` from before; run `Install` in the copy when it is not `—` (Godot writes its import cache into the project).
     - Start the engine from the copy under `xvfb-run`, at the capture resolution, in a process group of its own (`setsid`); force the engine onto that display (for Godot "`--display-driver x11`", with `WAYLAND_DISPLAY` unset) and keep its XR runtime off (for Godot "`--xr-mode off`"). A window appearing on the person's display → stop it at once, `QA status: blocked`.
     - Stop what you started when the walk ends, whatever its outcome. Then compare `status --porcelain --ignored` again: a new path → `QA status: blocked`, naming it, nothing removed.
     - Browser route: start `Dev` from the worktree in the background, read the origin it prints; none, or nothing answers → `QA status: blocked`; stop it at the end.
   - `## Exercising a criterion`:
     - Each viewpoint line gives a scene, a position, a target and a framing; the framing sets the field of view, and the resolution is 1920×1080 unless the line says otherwise.
     - Write, under the temporary directory, a capture script that loads the scene, adds one camera at the viewpoint and makes it current, waits for a rendered frame and saves the image (for Godot: `RenderingServer.frame_post_draw`, then `get_viewport().get_texture().get_image().save_png()`). Nothing else in the scene changes: no light, material or node is added, moved or removed besides that camera.
     - A line too vague to place a camera, or naming a scene that does not exist → `## Not seen`, naming what it lacks; the driver "never guesses a camera".
     - An image of "a single uniform colour" is a failed render, not a capture → `QA status: blocked` with that cause.
     - Compare each capture with what its viewpoint must show, its framing, scale and light; a difference is a finding. Each acceptance criterion in scope is matched to the viewpoints that show it; a criterion no viewpoint shows → `## Not seen`.
     - Browser route: drive the page by "the `## Driving a browser` section of the preloaded `design-doctrine` skill", not repeated here; capture the view the page shows, never start an immersive session; a viewpoint the page cannot reach → `## Not seen`.
   - `## Evidence`: "one capture per viewpoint" under `docs/qa/<id>/`, named `<n>-<viewpoint>.png` in the plan's order; one "`viewpoints.txt`" listing, per viewpoint, its plan line, the scene, camera position, target, field of view, resolution, the renderer and display used, and the capture script quoted whole (browser route: the page and that only its in-page view was captured). Everything else stays in the temporary directory.
   - `## Cannot show`: bulleted — comfort (motion sickness, frame rate and latency in the headset); scale as perceived in stereo; hand tracking; controllers and haptics; passthrough and mixed reality; spatial audio; performance on the headset; an immersive WebXR session. Then: every report carries under `## Not seen` one standing line saying that what "only a headset would show" — the items above — was not seen, and one more line per criterion in scope that relies on one of them, naming criterion and item; the driver never reports one as seen. A capture made with a software renderer says so in `viewpoints.txt`, its light and shadows may differ from a GPU render.
   Fails if wrong: `test_scene_driver_captures_without_a_window`; `tests/qa-drivers.test.sh` `qa_picks_the_driver_of_the_surface` keeps the table row; `overlap.test.sh`.
2. [x] **The profile** — create `boilerplates/godot/profile.md` after task 1 (`po-lint` accepts `scene` only once `scene.md` exists, `bin/po-lint:289-291`). Title `# Profile — godot`; the template's ten `## ` headings verbatim, in order, no other.
   - Identity: `- Name: Godot XR Template`, `- Origin: https://github.com/GodotVR/godot-xr-template`, `- Licence: MIT`, `- Commit profiled: 7d8261cd37b07bbf28638cad39cf4b2d6cedd936`. Then: tag `4.6.0`, branch `main` targets Godot 4.6+, its CI pins Godot `4.7.2`; Godot XR Tools is vendored under `addons/godot-xr-tools/` (MIT, its own licence); the OpenXR Vendors addon is not in the repository.
   - `- Platform: xr`, `- QA driver: scene`.
   - Fence: `Install: godot --headless --import`, `Test: —`, `Typecheck: —`, `E2E: —`, `Build: godot --headless --export-release Linux`, `Dev: —`.
   - Under the fence: `godot` is the editor binary of Godot `4.7.2`; `--import` fills the `.godot/` cache, which CI tolerates failing (`|| exit 0`); no test framework ships, so `Test` stays `—`; CI lints scripts with `gdlint components`; `Build` writes the `Linux` preset to `build/linux/` and needs the export templates of the same version; running the game opens a window and serves no address, hence `Dev: —`. Then the line the scene driver reads: "Engine command:" followed by `xvfb-run -a godot --path <copy> --display-driver x11 --rendering-driver opengl3 --xr-mode off --resolution 1920x1080 --script <capture script>`, and that `--headless` draws nothing.
   - Code map: `game/`, `components/`, `addons/`, `assets/`, `build/`, `img/`, `project.godot`, `export_presets.cfg`, `openxr_action_map.tres`, `default_env.tres` — each in backticks, as research lists them.
   - Ownership: a story owns a new zone `game/zones/<zone>/`; shared, run alone: `project.godot`, `export_presets.cfg`, `openxr_action_map.tres`, `game/zones/zone_database.tres` (lists every zone), `game/game_state.gd`, `game/main.tscn`, `addons/`.
   - Where each rule lives: game state in `game/game_state.gd` (autoload `GameState`); saving and zone switching in `components/persistent/`; no access, validation or tenant code.
   - Capabilities: header only, one line saying the template provides none of the list.
   - UI inventory: a scene, not a screen app — splash `assets/splash/splash.png`, start menu `game/start_scene/start_ui.tscn`, wrist menu `game/zones/zone_wrist_ui.tscn`, prototype materials under `assets/prototype_materials/`, XR Tools' hands, pickables and functions under `addons/godot-xr-tools/`.
   - Known traps: `--headless` renders nothing; `openxr/enabled=true` needs `--xr-mode off` without a headset runtime; under a Wayland session force `--display-driver x11` or the window lands on the person's screen; renderer `gl_compatibility` (`opengl3`) is the one that runs on Mesa software rendering; `.godot/` and `.import/` are ignored caches written into the project; every script has a tracked `.uid` file to commit with it; Android presets need the OpenXR Vendors addon, the Android build template and export templates; replace `addons/godot-xr-tools/` as a whole, never edit it.
   - **Every backticked token matching the grounding regex of task 3 must be tracked at the commit**: write `build/linux/`, not the untracked `build/linux/Game.x86_64`.
   Fails if wrong: `test_godot_profile_passes_the_lint`, `test_godot_profile_is_grounded_in_its_source`.
3. [x] **The test file** — `tests/godot-scene-driver.test.sh`, header `# s87 — the godot profile and the scene driver.`; helpers `section_of`, `identity_value`, `tokens_matching` as in `tests/flutter-profile.test.sh:8-14`.
   - `test_godot_profile_passes_the_lint` — `require_file`; `bash "$ROOT/bin/po-lint"` exits 0; `Origin`, `Licence MIT`, 40-hex `Commit profiled`; exact lines `- Platform: xr`, `- QA driver: scene`; fence lines `Dev:` and `Test:` at `—`, `Install:` starting `godot`. Mutant A: `mktemp -d` copy of `method/` + profile without `## Known traps` → lint non-zero, names `boilerplates/godot/profile.md`. Mutant B: the same copy with `skills/qa-drivers/scene.md` removed and the profile intact → lint non-zero with `QA driver 'scene' is not a file of qa-drivers`.
   - `test_scene_driver_captures_without_a_window` — `require_file`; the five headings with `grep -qxF`; `contains` each verbatim phrase of task 1 (`## Scene viewpoints`, `docs/plans/<id>.md`, `never on a display a person sees`, `` `--headless` draws nothing ``, `xvfb-run`, `--display-driver x11`, `--xr-mode off`, `the plan names no viewpoint`, `never guesses a camera`, `a single uniform colour`, `one capture per viewpoint`, `viewpoints.txt`, the `design-doctrine` pointer, `docs/qa/<id>/`, `ADR-0065`); the `## Cannot show` body holds `comfort`, `scale`, `hand tracking`; the file holds `## Not seen` and `only a headset would show`.
   - `test_godot_profile_is_grounded_in_its_source` — source `$GODOT_TEMPLATE_SRC` when set, else `git init` + `fetch --depth 1 --filter=blob:none` of `Commit profiled` into a `mktemp -d` (about 1 s, no checkout needed); unreachable → stderr `(godot-xr-template not reachable: grounding not checked)`, return 0. With a source: `HEAD` equals `Commit profiled`; `git show HEAD:LICENSE` starts `MIT License`; each backticked token matching `^(game|components|assets|addons|build|img)/|^(project\.godot|export_presets\.cfg|openxr_action_map\.tres|default_env\.tres)$`, skipping `<` and `*`, resolves with `git cat-file -e "HEAD:${token%/}"`; at least 6 resolve. Run once more on a copy with a made-up `` `game/levels/boss.tscn` `` and require it reported.
   Fails if wrong: each function goes red when its clause leaves the file under test; the mutants prove the checkers bite.
4. [x] **Run** — focused: `bash tests/run.sh godot-scene-driver.test.sh qa-drivers.test.sh profile.test.sh lint.test.sh surface-routing.test.sh overlap.test.sh`; `bash bin/po-lint` clean. Then the full suite once: `po-run --story s87-godot-scene-driver --label test -- 'bash tests/run.sh'` (`Full suite: execute-end`). No type check (`Typecheck: —`).

## Scene viewpoints
—

## Run interdicts
- Empty diff on `method/skills/qa-drivers/SKILL.md`, `browser.md`, `mobile-web.md`, `scenarios.md`, `method/agents/qa.md`, `method/agents/reviewer.md`, `method/commands/po-qa.md`, `method/templates/` (all), `method/skills/design-doctrine/`, `bin/`: routing, templates and lint already serve this driver.
- No existing `tests/*.test.sh` edited; no file under `.claude/` or `.polype/`; no other `boilerplates/` folder touched.
- `docs/stories.md`, `docs/catalogue.md`, `docs/parite-killer-saas.md` (no line covers this driver), `README.md` unchanged.
- `git diff --stat main...` lists only `scene.md`, the profile, the test, ADR-0065 and this story's `docs/` files; no file of `XT:` or `GD:` enters the repository; no clone inside the worktree.
- ADR-0065 committed as written; no other ADR created. No text from Killer SaaS (`overlap.test.sh`).

## The pivot
**A capture is an image the engine really rendered, on a virtual display, at a camera the plan placed** (ADR-0065). Ways it could be wrong:
- Never run here: this machine has neither Godot nor Xvfb. If Godot 4.7.2 on Xvfb with Mesa fails to create an `opengl3` context, every Godot QA ends blocked; the uniform-colour check keeps it honest rather than green. Compare with the first real `scene` QA; the fix would be a new ADR (e.g. Vulkan through lavapipe), not a silent fallback to `--headless`.
- `--script` replaces the main scene but autoloads still run (`GameState`, XR Tools settings, `XT:project.godot` `[autoload]`); one of them may expect XR or the staging scene. The driver reports such a crash as `blocked` with its log; it never edits the project.
- Viewpoint lines in prose may be too vague to place a camera, sending most of them to `## Not seen`. That pressure belongs on the plan template's wording (s80), not on the driver guessing.

## Files touched
- `method/skills/qa-drivers/scene.md` (new)
- `boilerplates/godot/profile.md` (new)
- `tests/godot-scene-driver.test.sh` (new)
- `docs/research/s87-godot-scene-driver.md`, this plan, `docs/decisions/ADR-0065-…md`, `docs/verif/s87-godot-scene-driver.md`

## Test strategy
Automated, 3 of a budget of 25, bash, at the only layer here — the method text, the lint and the profile's source:
- `godot_profile_passes_the_lint` — fails on a template breach, a wrong identity, platform or driver line; mutant B ties the profile to the driver file.
- `scene_driver_captures_without_a_window` — fails when any clause of the criterion (no visible window, headless refused, browser route, each viewpoint captured, headset items not seen) leaves `scene.md`.
- `godot_profile_is_grounded_in_its_source` — beyond the two criterion names, as s83, s84 and s86 did: it is the only check that "written from a starter at a named commit" is true (commit, licence, paths). Network-dependent, skips loudly.
Existing guards run unchanged: `qa-drivers.test.sh`, `profile.test.sh`, `lint.test.sh`, `surface-routing.test.sh`, `overlap.test.sh`.
Visual checks: none — the story ships no screen.

## Done when
- The three new tests and the five guarding files pass; `bin/po-lint` reports no breach; the full suite passes once through `po-run`.
- One commit on `story/s87-godot-scene-driver` carrying the driver, the profile, the test, the research, this plan, ADR-0065 and the verification record; a review with no open critical finding; squash on `main`.
