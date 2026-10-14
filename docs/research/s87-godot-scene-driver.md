# Research — s87-godot-scene-driver

[Story](../stories.md)

`XT:` = `https://github.com/GodotVR/godot-xr-template` at `7d8261cd37b07bbf28638cad39cf4b2d6cedd936` (tag `4.6.0`, HEAD of `main`, commit dated 2026-10-09 UTC). `GD:` = `https://github.com/godotengine/godot` at `ed1daf0bf001b61586d9930840f2f1394092c079` (tag `4.7.2-stable`, the version `XT:` CI pins). Both opened in clones under `/tmp`, outside the repository, on 2026-10-08.

## Structuring facts
- **Wrong reading of the story first: Godot cannot render "without a window" in its headless mode.** `--headless` swaps the display driver for `headless` (`GD:main/main.cpp:1505-1508`, help `:626`), whose creation calls `RasterizerDummy::make_current()` (`GD:servers/display/display_server_headless.cpp:40`): nothing is drawn, a capture would be empty. "Sans fenêtre" can only mean *no window on a display a person sees*: the engine opens its window on a virtual display (Xvfb), or the WebXR export runs in the session's headless browser. The story text holds under that reading; the driver must say it, and refuse `--headless` for captures.
- The Godot starter exists, is public and free: `XT:` is MIT (`XT:LICENSE:1`), tagged, platform-neutral XR template with a `WebXR` export preset (`XT:export_presets.cfg:1008-1016`) and Godot XR Tools vendored under `addons/godot-xr-tools/` (MIT, its own `LICENSE`).
- `bin/po-lint` accepts `- QA driver: scene` only once `method/skills/qa-drivers/scene.md` exists (`bin/po-lint:289-291`): the driver file must land before, or with, the profile.
- The viewpoints the driver captures already have a home: `## Scene viewpoints` of the plan (`method/templates/plan.md:15-16`, `plan-flow.md:32-33`), and the reviewer judges a `scene` against them through the QA's scene captures (`method/agents/reviewer.md:32`). `qa.md` never names the plan as a source (`method/agents/qa.md:35-39`); it reaches it only as a file of the story's diff.
- The table row `scene` / `xr` → `scene.md` is already written and tested (`method/skills/qa-drivers/SKILL.md:16`, `tests/qa-drivers.test.sh:29`); no routing, report template or lint change is needed.

## Story
A developer gets a Godot profile and a driver that captures, with no visible window, the viewpoints the plan names, so a `scene` story reaches review with captures someone looked at.
- `godot_profile_passes_the_lint` — `boilerplates/godot/profile.md` follows the template, written from a public, freely licensed starter at a named commit, platform `xr`, driver `scene`; `bin/po-lint` accepts it.
- `scene_driver_captures_without_a_window` — `qa-drivers/scene.md` renders the scene without a window (or in a browser for WebXR), captures each viewpoint of the plan, and names what only a headset would show (comfort, scale, hand tracking) as not seen.

Complexity 3, depends on s80 (shipped: `plan.md:15`, `reviewer.md:32`). Owns `boilerplates/godot/`, `method/skills/qa-drivers/scene.md`, `tests/godot-scene-driver.test.sh`.

## Current code
- `method/skills/qa-drivers/SKILL.md` — the driver table (`:9-17`), driver files read from the skill's base directory, missing file → `QA status: blocked` (`:23-24`), the five things a driver says (`:26-31`), the `mktemp -d` directory as the single place for by-products (`:33-34`), headset items go to `## Not seen` (`:36-37`).
- Drivers present: `browser.md`, `mobile-web.md`, `scenarios.md`. `mobile-web.md` is the closest model: five sections `## Needs`, `## Start and stop`, `## Exercising a criterion`, `## Evidence`, `## Cannot show` (`mobile-web.md:5,11,14,21,24`), a blocked branch when the tool lacks a capability (`:9`), a standing line plus a per-criterion line under `## Not seen` (`:34`). `scenarios.md` plays on a copy of the tracked files in the temporary directory and blocks on a dirty `status --porcelain --ignored` (`scenarios.md:10-12`, ADR-0059).
- `method/templates/profile.md` — ten `## ` headings (`:5-74`), fence names `Install Test Typecheck E2E Build Dev` (`:26-33`), `Dev` "serves what a person looks at and prints the address it serves" (`:35`), "A boilerplate with no screen says so in one line" (`:72`).
- `bin/po-lint` `check_profiles` (`:234-301`): headings, fence names, platform among the backticked values of `| Platform |` (`agents-local.md:53`, holds `xr`), driver `—` or an existing `qa-drivers/<name>.md` (`:283-293`), capabilities from the template list.
- `method/templates/qa.md`: `Tool:` and `Origin:` lines (`:5-6`, `—` when the driver serves nothing), `## Not seen` reasons include "a headset would show it" (`:28`).
- Profile precedent: `boilerplates/flutter/profile.md` + `tests/flutter-profile.test.sh` (lint + mutant, platform/driver lines, grounding against the source with an env override and a loud skip when unreachable, `:59-105`); plan `docs/plans/s84-flutter-profile.md`. Driver test precedent: `tests/mobile-web-driver.test.sh:9-27`.

## Attachment points
- New `method/skills/qa-drivers/scene.md` — found by the existing table row; nothing else to wire.
- New `boilerplates/godot/profile.md` — found by `po-lint`'s glob `boilerplates/*/profile.md` (`bin/po-lint:248`) and by `/po-setup` for a project whose `Platform` holds `xr`.
- New `tests/godot-scene-driver.test.sh` — picked up by `tests/run.sh:6` (`*.test.sh`), each function in its own process (`:17`).

## Verified interfaces
Polype:
- Helpers of `tests/lib.sh`: `contains`, `require_file`, `fail`, `$ROOT`, `$METHOD` (used as in `tests/flutter-profile.test.sh:4,61-62`).
- `po-lint` error text for a missing driver: `QA driver '<v>' is not a file of qa-drivers` (`bin/po-lint:291`); for a missing heading: `missing section '<h>'` (`:252`).

`XT:` (the template):
- `project.godot`: main scene `res://game/main.tscn` (`:18`), features `4.6` (`:19`), XR Tools plugin enabled (`:30`), renderer `gl_compatibility` on desktop and mobile (`:66-67`), `openxr/enabled=true` (`:73`).
- README: `main` targets Godot 4.6+ (`XT:README.md:18`); OpenXR Vendors "is not included in the repo but will be downloaded by CI scripts" (`:31`); customise by editing `game_state.gd` and replacing the demo zones (`:46-47`).
- CI pins Godot `4.7.2` (`XT:.github/workflows/publish-demo-on-push.yaml:17`) and Vendors `5.1.0-stable` (`:20`); imports with `godot --headless --verbose --import || exit 0` (`:168`); exports with `godot --headless … --export-<type> "<preset>" || exit 0` (`:174`); lints with `gdlint components` (`gdlint-on-push.yml:32`). No test framework ships.
- Export presets: `Windows`, `Linux` (→ `build/linux/Game.x86_64`), four Android presets, `WebXR` (→ `build/webxr/index.html`) (`XT:export_presets.cfg:3,67,75,108,333,558,783,1008,1016`); WebXR has no `thread_support` line, default false (`GD:platform/web/export/export_plugin.cpp:375`), so no cross-origin isolation headers are required.
- Tree: `game/` (`main.tscn`, `game_state.gd` autoload, `start_scene/`, `zones/` with `outside/`, `house_interior/`, `house_back_yard/`, `zone_database.tres` listing the three zone infos), `components/` (`persistent/`, `helpers/`), `assets/` (`prototype_materials/`, `splash/`), `addons/godot-xr-tools/`, `build/<target>/.gitignore`, `img/`, `default_env.tres`, `openxr_action_map.tres`. 126 tracked `.uid` files. `.gitignore`: `.import/`, `.godot/`, `android/` (`XT:.gitignore:1-3`).
- XR start: `addons/godot-xr-tools/xr/start_xr.gd` emits `xr_failed_to_initialize` when OpenXR fails (`:134-135`) and takes a WebXR branch on the web (`:77`, `:203-220`).

`GD:` (the engine):
- Options (help `GD:main/main.cpp`): `--display-driver` (`:602`), `--rendering-method` (`:621`), `--rendering-driver` (`:622`), `--headless` (`:626`), `--write-movie` (`:629`), `--resolution <W>x<H>` (`:639`), `--xr-mode default|off|on` (`:644`, parsed `:1991-2000`), `--fixed-fps` (`:684`), `-s, --script` (`:695`), `--import` editor-only (`:700`). `--export-release <preset>` needs a project path (`:4135-4138`).
- Linux display drivers `x11`, `wayland`, `headless` (`GD:main/main.cpp:2796`).
- Capture API: `Viewport.get_texture()` (`GD:doc/classes/Viewport.xml:122`), `Texture2D.get_image()` (`Texture2D.xml:152`), `Image.save_png()` (`Image.xml:532`), signal `RenderingServer.frame_post_draw` (`RenderingServer.xml:4687`).
- Licence MIT (`GD:LICENSE.txt`).

## Traps
- **Headless renders nothing** (above). A driver that follows the engine's own help ("Useful for servers and with --script", `main.cpp:626`) would save blank images and call them captures.
- **A window on the person's desktop.** With `WAYLAND_DISPLAY` set, Godot may pick `wayland` and open on the user's screen; the driver must force the display it created (`--display-driver x11` with the `DISPLAY` of `xvfb-run`). This machine runs a Wayland session (Hyprland).
- **The import cache lands in the project.** Running Godot writes `.godot/` (ignored, `XT:.gitignore:2`), invisible to a plain `status --porcelain`: play on a copy, as ADR-0059 settles for scenarios.
- **OpenXR without a runtime**: `openxr/enabled=true` (`project.godot:73`) makes startup try OpenXR; `--xr-mode off` avoids it on a machine with no headset runtime.
- **Software rendering**: a QA machine without GPU renders through Mesa; the template's `gl_compatibility` (`opengl3` driver) is the renderer most likely to work there. Light and shaders may differ from a GPU render — record which renderer was used.
- **`--import` exit status**: CI swallows it (`|| exit 0`, workflow `:168`); whether it exits non-zero on a clean import was not established.
- **Export needs more than the repo**: export templates for the exact engine version; Android presets also need the Android build template and the OpenXR Vendors addon (README `:31`).
- Tests: `qa-drivers.test.sh`, `profile.test.sh`, `lint.test.sh`, `surface-routing.test.sh`, `overlap.test.sh` read the files around this story and must stay green unchanged. `overlap.test.sh` forbids 8 shared consecutive words with Killer SaaS in `method/`.
- No migration; no shared method file changes.

## Open questions
- Engine route or browser route as the default for a Godot project? The engine route can place a camera at each viewpoint; the browser route only shows what the page offers before "Enter VR", and needs export templates. → plan / ADR-0065.
- How the driver turns a prose viewpoint line into a camera (position, target, field of view): the plan template asks for "where it looks from", which may be vague. A line too vague to place a camera → not seen, or blocked? → plan.
- Whether `Dev` should be set for the profile: Godot run opens a window and serves no address, which does not match the template's `Dev` (`profile.md:35`). → plan (proposed `—`).
- Whether `godot --headless --import` returns 0 on a fresh copy: not runnable here (no Godot binary, no Xvfb on this machine). The profile states CI's tolerance as a trap instead of a claim.

## Complexity
Story 3 → 3. Two new markdown files and one test file, no shared file changes; the real work is the capture route (headless trap, virtual display, viewpoint placement) and grounding the profile in `XT:`, both settled in ADR-0065.

## Split
—
