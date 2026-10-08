# Driver — mobile web

Checks a `screen` surface on the `mobile` platform through the web render of the project's stack, opened in a browser at phone width (ADR-0054). Evidence: captures.

## Needs
- `Dev` in `AGENTS.local.md`, not `—`, serving the web render of the app.
- A tool of the session that opens a page, sets its viewport width and height, and captures it.

A tool that opens pages but cannot set their size → the QA ends with `QA status: blocked` and that cause (ADR-0060). Never capture at whatever width the window happens to have, and never emulate a phone width by zooming.

## Start and stop
Start `Dev` from the worktree, in the background, and read the origin it prints. It prints none, or nothing answers at that origin → the QA ends with `QA status: blocked` and the reason. Stop the server you started when the walk ends, whatever its outcome.

## Exercising a criterion
Drive the browser by the `## Driving a browser` section of the preloaded `design-doctrine` skill; its rules are not repeated here.

Open each screen in scope in portrait, its height greater than its width, at 360 and at 412 CSS pixels wide — for instance 360×800 and 412×915 — and walk each criterion at both widths. Act by click or tap only, never by hovering.

Hold the screen to the `## Mobile screens` section of `design-doctrine`, not repeated here either: measure the box of each control the criterion uses against the touch-target size, and record as a finding a control that appears or works only on hover. When the stack scales its web render so that a CSS pixel does not stand for a point, report the size you measured rather than assuming it conforms. Compare what you see with the story and the design note, as `browser.md` does.

## Evidence
One capture per state and per width under `docs/qa/<id>/`, named `<screen-or-criterion>-<state>-360.png` and `<screen-or-criterion>-<state>-412.png`, through the browser tool's own option to save a file or a copy in Bash. Anything else the walk produces stays in the `mktemp -d` directory of `qa-drivers`.

## Cannot show
The web render in a desktop browser does not show:
- native permission prompts;
- notifications;
- the camera and the other device sensors;
- system gestures: the back swipe, the home and app-switch gestures;
- the on-screen keyboard;
- the safe areas of a real device: the notch, the gesture bar;
- screens behind a sign-in.

Every report of this driver carries, under `## Not seen`, one standing line saying that native behaviour — the items above — was not seen, because only the web render was (ADR-0060). It adds one more line per criterion in scope that relies on one of these items, naming the criterion and the item. The driver never reports one of them as seen.
