# Driver — browser

Checks a `screen` surface on the `web` platform by opening its pages. Evidence: captures.

## Needs
- `Dev` in `AGENTS.local.md`, not `—`.
- A tool of the session that opens a page and captures it.

## Start and stop
Start `Dev` from the worktree, in the background, and read the origin it prints. It prints none, or nothing answers at that origin → the QA ends with `QA status: blocked` and the reason. Stop the server you started when the walk ends, whatever its outcome.

## Exercising a criterion
Drive the browser by the `## Driving a browser` section of the preloaded `design-doctrine` skill; its rules are not repeated here. For each screen and each criterion in scope, act as its user would, compare the page with the story and the design note, and capture what you see.

## Evidence
Captures go under `docs/qa/<id>/`, one file per state worth keeping, named after the screen or the criterion, through the browser tool's own option to save a file or a copy in Bash.

## Cannot show
Screens behind a sign-in, and states the page cannot be brought to from the origin: each goes to `## Not seen` with its reason.
