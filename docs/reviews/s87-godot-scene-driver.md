# Review — s87-godot-scene-driver

[Story](../stories.md) · [Plan](../plans/s87-godot-scene-driver.md) · [Verification](../verif/s87-godot-scene-driver.md)

Diff reviewed: `git diff main...story/s87-godot-scene-driver`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: e9d5ed0d77c1e88b99511c013c82e1fe64698687

## Ownership
I listed the diff with `git diff --name-status main...story/s87-godot-scene-driver`. There is one commit, 1491ed0. The story's `Owns` line is `boilerplates/godot/`, `method/skills/qa-drivers/scene.md`, `tests/godot-scene-driver.test.sh`.
- [x] Every path is inside `Owns`:
  - `boilerplates/godot/profile.md` falls under `boilerplates/godot/`.
  - `method/skills/qa-drivers/scene.md` and `tests/godot-scene-driver.test.sh` match file entries exactly.
  - `docs/research|plans|verif/s87-godot-scene-driver.md` are pipeline evidence, in scope by construction.
  - `docs/decisions/ADR-0065-…md` is added (status `A`) and the plan names it, so it is in scope too.
- [x] No path is outside `Owns`.
- [x] No path is inside another running story's `Owns`. The only other worktree is `s85-native-profiles`, which is not an ancestor of main. Its `Owns` covers `boilerplates/native-ios/`, `boilerplates/native-android/` and `tests/native-profiles.test.sh`, and nothing there overlaps this diff. It holds ADR-0064, so ADR-0065 does not collide.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s87-godot-scene-driver` exited 0, so I reused the record. It shows Unit suite `bash tests/run.sh`, exit 0, on tree 19e4270…, and the gate confirms that tree matches the code outside `docs/`. The project has no type check (`Typecheck: —`), no E2E and no build command. The record's "Not proven here" section says:
  - Godot and Xvfb were never run on the machine that executed the story.
  - The grounding test skips when the network is unreachable.
- [x] `po-gate qa-current`: not required. The story's `Surface` is `—`, so it does not go to QA.

## Plan
- [x] Tasks 1–4 are all present: the driver, the profile, the test file and the run (focused, then full suite through `po-run`). Nothing in the diff falls outside the plan's "Files touched".
- [x] I checked each run interdict:
  - The diff is empty on `qa-drivers/SKILL.md`, `browser.md`, `mobile-web.md`, `scenarios.md`, `agents/qa.md`, `agents/reviewer.md`, `commands/po-qa.md`, `method/templates/`, `design-doctrine/` and `bin/`.
  - No existing test was edited, and nothing under `.claude/`, `.polype/` or any other `boilerplates/` folder.
  - `docs/stories.md`, `catalogue.md`, `parite-killer-saas.md` and `README.md` are unchanged. The parity matrix has no Godot/scene line, which matches the plan.
  - No ADR besides ADR-0065, and no template file enters the repository.

## References
- [x] I verified the profile against the template, using a throwaway fetch of `GodotVR/godot-xr-template` at `7d8261cd…` under the temp dir:
  - The tag `4.6.0` and the head of `main` both point to that commit.
  - `LICENSE` starts with "MIT License", and `addons/godot-xr-tools/` is tracked (516 files).
  - `addons/.gitignore` ignores `godotopenxrvendors/`, and CI downloads it.
  - CI has `GODOT_VERSION: 4.7.2`, `godot --headless --verbose --import || exit 0` and `gdlint components`.
  - `project.godot` sets `gl_compatibility`, `openxr/enabled=true`, the autoload `GameState`, and `main_scene` `res://game/main.tscn`.
  - `export_presets.cfg` has a preset named `Linux` with path `build/linux/Game.x86_64`.
  - Every path in the code map, ownership, rules and UI inventory sections exists.
- [x] I verified the engine facts against Godot `4.7.2-stable` (a trees-only fetch):
  - `servers/display/display_server_headless.cpp` calls `RasterizerDummy::make_current()` in `create_func` (around line 39; the ADR cites line 40). So "`--headless` draws nothing" holds.
  - `--xr-mode off`, `--display-driver`, `--rendering-driver`, `--resolution` and `--import` (editor-only) all exist in `main/main.cpp`.
- [x] `bin/po-lint:289-291` requires `qa-drivers/<value>.md` to exist. The driver table in `qa-drivers/SKILL.md:16` already routes `scene`/`xr` to `scene.md`. `reviewer.md:32` and `templates/plan.md:15` already carry `## Scene viewpoints`.
- [ ] Two values only look right; both are under Findings (minor): the virtual screen size, and `get_viewport()` inside a `--script` SceneTree.

## Rules
- [x] `AGENTS.md` conventions are respected. The method file is in English, the ADR in French. The tests are bash and use the `lib.sh` helpers, and each test function's name is its criterion's name.
- [x] No accepted ADR is contradicted. The work follows ADR-0054 (scene → engine render or WebXR), ADR-0057 (driver files), ADR-0059 (run on a copy in `mktemp -d`) and ADR-0065.

## Tests
- [x] Floor: `po-gate floor-guard s87-godot-scene-driver main` exited 0, so nothing was lowered.
- [x] The assertions pin down both criteria plus the grounding check. Mutants A and B prove the lint bites, and a made-up path proves the grounding check bites. None of the six empty test shapes appears: each test calls the real `po-lint` or the real git source.
- [x] 3 tests, within a `Test budget` of 25. The third, beyond the two criterion names, is justified in the plan.
- [x] Bite 1: in `scene.md`, `## Cannot show` `- hand tracking;` → `- tracking;` → 1 failing test (`scene_driver_captures_without_a_window`). Undone, `git diff --exit-code` clean.
- [x] Bite 2: in `profile.md`, `game/game_state.gd` → `game/state.gd` → 1 failing test (`godot_profile_is_grounded_in_its_source`, "path not in the source: game/state.gd"). Undone, `git diff --exit-code` clean. This also proves the grounding check really ran over the network instead of skipping.
- [x] No existing test is made useless.

## Neighbours
- [x] I read the neighbours: `qa-drivers/SKILL.md` (routing), `agents/qa.md` (steps 5–7), `templates/plan.md` (the `## Scene viewpoints` contract), `agents/reviewer.md:32` and `scenarios.md` (the copy and porcelain pattern the driver reuses). Nothing is broken; two contract gaps are listed below.

## Lenses
Lenses run: none. No path or content in the diff matches the security, migration, dependencies or performance triggers: the diff is method markdown, a profile, an ADR and a bash test.

## Findings
- **major** — `method/skills/qa-drivers/scene.md:26,30`: the driver and the plan template disagree on what a viewpoint line contains.
  - The driver assumes "Each viewpoint line gives a scene, a position, a target and a framing", and sends any line lacking one of these to `## Not seen`.
  - The producer of those lines, `method/templates/plan.md:16`, asks only for "where it looks from, what it must show, and its framing, scale and light". It asks for no scene and no target.
  - So a plan that follows the template faithfully can have most of its viewpoints land in `## Not seen`. Nothing is hidden, but the driver's main output is undercut.
  - The plan's pivot names this risk and defers it to the template, which is outside this story's `Owns` (an interdict here). That makes a follow-up story on `method/templates/plan.md` necessary, or a driver rule for a line that names no scene (for instance, the project's main scene).
- **minor** — `boilerplates/godot/profile.md:33` and `scene.md:19`: the engine command never sizes the virtual screen.
  - It asks for `--resolution 1920x1080`, but `xvfb-run -a` starts Xvfb with its default screen, which as far as I know is 1280x1024x24 (not checked here: xvfb-run is not installed). That is smaller than the capture resolution.
  - The window then overflows the root window. Whether Godot clamps it, or the viewport texture still comes out at 1920×1080, was not checked.
  - `xvfb-run -s "-screen 0 1920x1080x24"` (or matching the line's resolution) would remove the doubt.
- **minor** — `scene.md:28`: the Godot hint may not work as written.
  - It says to call `get_viewport().get_texture().get_image().save_png()` from a capture script passed with `--script`.
  - A `--script` file must extend `SceneTree`/`MainLoop`, and `SceneTree` has no `get_viewport()`; the equivalent is `root.get_texture()`, or calling from a node added to the tree.
  - The hint can mislead the agent writing the first capture script.
- **minor** — `scene.md:21`: the wording blocks on any new path, including the driver's own evidence.
  - "a path the first output did not list → `QA status: blocked`" does not set aside `docs/qa/<id>/`, where this same driver writes its PNGs and `viewpoints.txt` during the walk.
  - `agents/qa.md:48` does set it aside, and `scenarios.md:12` carries the same wording, so this is inherited. A literal reading of the driver alone would still block every walk.

## Not verified
- **The capture route itself.** Neither Godot nor Xvfb (`xvfb-run`, `Xvfb`) is on this machine. I never ran the engine command, the opengl3 context on Mesa/Xvfb, the window staying off the person's display under Wayland, the `frame_post_draw` capture, or the uniform-colour check. A person should run one capture with Godot 4.7.2 under `xvfb-run` on the template at `7d8261cd…` (main scene, one camera), or let the first real `scene` QA serve as this test.
- **Autoloads under `--script`.** `XRToolsUserSettings`, `GameState` and `XRToolsRumbleManager` may misbehave without XR or the staging scene. I did not run this; it is the same check as above.
- **The browser (WebXR) route.** I never exercised it. The Godot profile has `Dev: —`, so this route never applies to it.
- **The `Build` command `godot --headless --export-release Linux`.** I did not run it: no engine here, and it needs export templates. I verified only the preset name and export path.
- **The full unit suite and `overlap.test.sh`.** I did not rerun them; I reused the record (`Verification mode: record`). Of the suite, only `godot-scene-driver.test.sh` was run here.
- **The project's own type check, E2E and build.** The project has none (`—`).
- **Whether ADR-0065 is word-for-word the planner's draft.** I cannot check this from the diff, since it was added in the same commit.
- **QA and viewpoints.** None to check: the story has no surface (`Surface: —`), and its plan's `## Scene viewpoints` is `—`.

Max severity: major
Ship allowed: yes
