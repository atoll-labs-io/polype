# Profile — godot

## Identity and licence

- Name: Godot XR Template
- Origin: https://github.com/GodotVR/godot-xr-template
- Licence: MIT
- Commit profiled: 7d8261cd37b07bbf28638cad39cf4b2d6cedd936

Tag `4.6.0`, the head of branch `main`, which targets Godot 4.6 and later; the template's CI pins Godot `4.7.2`. Godot XR Tools is vendored under `addons/godot-xr-tools/`, MIT under its own licence. The OpenXR Vendors addon is not in the repository: CI downloads it.

## Platform

- Platform: xr

## QA driver

- QA driver: scene

## Commands

```
Install:           godot --headless --import
Test:              —
Typecheck:         —
E2E:               —
Build:             godot --headless --export-release Linux
Dev:               —
```

`godot` is the editor binary of Godot `4.7.2`. `--import` fills the `.godot/` cache of the project; the template's CI tolerates it failing (`|| exit 0`). No test framework ships, so `Test` stays `—`; CI lints the scripts with `gdlint components`. `Build` writes the `Linux` preset into `build/linux/` and needs the export templates of the same engine version. Running the game opens a window and serves no address, hence `Dev: —`.

Engine command: `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path <copy> --display-driver x11 --rendering-driver opengl3 --xr-mode off --resolution 1920x1080 --script <capture script>`. `1920x1080`, in both places, is the default resolution: the `scene` driver replaces it with the viewpoint's own when its line names another. This is the line the `scene` driver reads. `--headless` draws nothing and is never used for a capture.

## Code map

- `game/` — the game: main scene, game state autoload, start scene and the demo zones.
- `components/` — reusable game components: persistence and zone switching, helpers.
- `addons/` — vendored Godot XR Tools; not edited.
- `assets/` — prototype materials and the splash image.
- `build/` — export targets, one folder per preset, their output ignored.
- `img/` — images of the README.
- `project.godot` — project settings: main scene, autoloads, renderer, OpenXR.
- `export_presets.cfg` — export presets: Windows, Linux, Android and WebXR.
- `openxr_action_map.tres` — the OpenXR action map.
- `default_env.tres` — the default environment.

## Ownership granularity

A story owns a new zone, `game/zones/<zone>/`. These paths are shared, and a story touching any of them runs alone: `project.godot`, `export_presets.cfg`, `openxr_action_map.tres`, `game/zones/zone_database.tres` (it lists every zone), `game/game_state.gd`, `game/main.tscn` and `addons/`.

## Where each rule lives

Game state lives in `game/game_state.gd`, the `GameState` autoload. Saving and switching zones live in `components/persistent/`. There is no access, validation or tenant code.

## Capabilities

| Capability | Brick | Notes |
| --- | --- | --- |

The template provides none of the capabilities of the list.

## UI inventory

A scene, not a screen app: the splash `assets/splash/splash.png`, the start menu `game/start_scene/start_ui.tscn`, the wrist menu `game/zones/zone_wrist_ui.tscn`, prototype materials under `assets/prototype_materials/`, and the hands, pickables and movement functions of XR Tools under `addons/godot-xr-tools/`.

## Known traps

- `--headless` renders nothing: a capture taken in that mode is blank.
- `openxr/enabled=true` in the project settings makes startup look for an OpenXR runtime; without a headset runtime, pass `--xr-mode off`.
- Under a Wayland session, force `--display-driver x11`, or the window lands on the person's screen instead of the virtual display.
- The renderer is `gl_compatibility` (driver `opengl3`), the one that runs on Mesa software rendering.
- `.godot/` and `.import/` are ignored caches written inside the project.
- Every script has a tracked `.uid` file; commit it with the script.
- Android presets need the OpenXR Vendors addon, the Android build template and the export templates.
- Replace `addons/godot-xr-tools/` as a whole when upgrading; never edit it in place.
