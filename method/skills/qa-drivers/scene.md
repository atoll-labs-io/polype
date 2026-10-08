# Driver — scene

Checks a `scene` surface on the `xr` platform by rendering the scene with its own engine at each viewpoint the plan names, on a virtual display, never on a display a person sees (ADR-0054, ADR-0065). Evidence: scene captures.

## Needs
- The viewpoints: the `## Scene viewpoints` section of `docs/plans/<id>.md`, a file of the story's diff. When that section is absent, holds `—` or is empty, the QA ends with `QA status: blocked`: the plan names no viewpoint.
- The engine command, found in `AGENTS.local.md` (its `## Commands` and its conventions), in the boilerplate profile those conventions name, or in the README. The driver never invents one.
- A virtual display: `xvfb-run` (Xvfb) installed on the machine.

Engine command or virtual display missing, and no browser route below → the QA ends with `QA status: blocked` and that cause.

In Godot, `--headless` draws nothing: it swaps the renderer for a dummy one, so the engine's headless mode is never used to capture. A blank image is not evidence (ADR-0065).

Browser route: when the project names no engine command but `Dev` serves a WebXR page, and a tool of the session opens a page and captures it, the driver works from that page instead of the engine.

## Start and stop
Every capture runs on a copy, never in the worktree (ADR-0059). Before copying, keep the output of `git -C <path> status --porcelain --ignored`. Inside the `mktemp -d` directory of `qa-drivers`, copy the files that `git -C <path> ls-files` lists, plus the ignored `.env*` files. Run `Install` in the copy when it is not `—`: Godot writes its import cache inside the project, and that cache belongs in the copy.

Start the engine from the copy under `xvfb-run -a -s "-screen 0 <width>x<height>x24"`, the virtual screen sized to the resolution of the viewpoint being captured — one engine run per capture script — in a process group of its own (`setsid`). Force the engine onto that virtual display — for Godot `--display-driver x11`, with `WAYLAND_DISPLAY` unset — and keep its XR runtime off — for Godot `--xr-mode off`. If a window shows up on the person's display, stop the engine at once and end with `QA status: blocked`.

When the walk ends, whatever its outcome, stop the process group you started, and only that one. Then run `status --porcelain --ignored` again: a path outside `docs/qa/<id>/` that the first output did not list → `QA status: blocked`, naming that path, and nothing is removed.

Browser route: start `Dev` from the worktree in the background and read the origin it prints. It prints none, or nothing answers there → `QA status: blocked` with that reason. Stop that server when the walk ends.

## Exercising a criterion
Each viewpoint line gives its scene, its position, its target, what it must show, and its framing, scale and light. A line that names no scene aims at the project's main scene — for Godot, the `run/main_scene` setting of `project.godot`. The framing sets the field of view; the resolution is 1920×1080 unless the line asks for another.

For each viewpoint, write a capture script under the temporary directory that loads the scene, adds one camera at the viewpoint and makes it current, waits until a frame has been rendered, then saves the image. For Godot, a `--script` file extends `SceneTree`, which has no `get_viewport()`: its viewport is `root`. Await `RenderingServer.frame_post_draw`, then call `root.get_texture().get_image().save_png()`. Nothing else in the scene changes: no light, material or node is added, moved or removed apart from that camera.

A line goes to `## Not seen`, saying what it lacks, when it has no position, no target or no framing, when it names a scene that does not exist, or when it names no scene in a project that has no main scene. The driver never guesses a camera.

An image made of a single uniform colour is a failed render, not a capture: the QA ends with `QA status: blocked` and that cause, with the engine's log.

Hold each capture against what its viewpoint must show: its framing, its scale, its light. A difference is a finding. Match each acceptance criterion in scope to the viewpoints that show it; a criterion no viewpoint shows goes to `## Not seen`.

Browser route: drive the page by the `## Driving a browser` section of the preloaded `design-doctrine` skill, whose rules are not repeated here. Capture the view the page shows and never start an immersive session; a viewpoint the page cannot reach goes to `## Not seen`.

## Evidence
The evidence is one capture per viewpoint under `docs/qa/<id>/`, named `<n>-<viewpoint>.png` in the order of the plan, and one `viewpoints.txt` listing for each viewpoint its plan line, the scene, the camera position, the target, the field of view, the resolution, the renderer and the display used, with the capture script quoted whole. On the browser route, `viewpoints.txt` names the page and says that only its in-page view was captured. Anything else the walk produces stays in the temporary directory.

## Cannot show
A render on a virtual display does not show:
- comfort: motion sickness, frame rate and latency inside the headset;
- scale as it is perceived in stereo;
- hand tracking;
- controllers and haptics;
- passthrough and mixed reality;
- spatial audio;
- performance on the headset itself;
- an immersive WebXR session.

Every report of this driver carries, under `## Not seen`, one standing line saying that what only a headset would show — the items above — was not seen. It adds one more line per criterion in scope that relies on one of these items, naming the criterion and the item. The driver never reports one of them as seen.

A capture rendered in software says so in `viewpoints.txt`: its light and shadows may differ from a render on a GPU.
