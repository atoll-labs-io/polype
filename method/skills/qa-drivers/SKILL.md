---
name: qa-drivers
description: Which driver checks a story's surface on the project's platform, where its file is read, and where a driver may leave anything besides its evidence. Preloaded by the qa subagent.
---
# QA drivers

A user meets a story through a screen, a command, a scene or a robot; each has a driver file next to this one.

## The driver table
| Surface | Platform | Driver file | Evidence |
| --- | --- | --- | --- |
| `screen` | `web` | `browser.md` | captures |
| `screen` | `mobile` | `mobile-web.md` | captures |
| `command` | `cli` | `scenarios.md` | transcripts of input, output and exit code |
| `endpoint` | `api`, `lib` | `scenarios.md` | transcripts |
| `scene` | `xr` | `scene.md` | scene captures |
| `behaviour` | `robot` | `simulation.md` | logs and topic recordings |

The surface is the story's `Surface` line in `docs/stories.md`. A story with no such line has the surface `screen` when its text shows a screen, and nothing to check otherwise. The platform is the `Platform` setting of `AGENTS.local.md`.

When `Platform` holds several values, every row matching both surface and platform applies, in table order, each one run in full.

No row matches the story's surface on the project's platform, or `Platform` is missing or `—` → the QA ends with `QA status: blocked`, and the report names the surface and the platform. With no driver, nothing was checked.

## Where a driver file is read
A driver file lives in the base directory announced for this skill, the folder holding this `SKILL.md`. When no base directory was announced, or that folder holds no file of the name the table gives, the QA ends with `QA status: blocked` and the report names the missing file.

## Lanes side by side
- **Marker.** Each lane first runs `mktemp -d "${TMPDIR:-/tmp}/polype-qa-<id>.XXXXXX"`; another `polype-qa-*` there is another lane in QA.
- **Browser.** A `screen` driver runs its own headless browser from a script in that directory, `TMPDIR` set to it, with the project's own browser-automation package, installing nothing. Without one, the session's browser tool serves only a lane alone in QA; otherwise `QA status: blocked`, naming the marker.
- **Port.** `Dev` listens on `$((20000 + $(pwd | cksum | cut -d' ' -f1) % 10000))` in the worktree, passed as `PORT` and its command's port option. That port answering before the start, or another port printed → `QA status: blocked`; never reuse a running server.
- **Deadline.** Each start, page action or capture run by Bash or the lane's script gets 120 seconds: `timeout 120`, or the script's timeout. Past it, stop what the lane started; `QA status: blocked`, naming the action.

## Outside the evidence
Anything a driver produces besides evidence — a build, a recording, a scratch file — goes into the lane's `mktemp -d` directory, removed when the QA ends, each file written through Bash, since the Write tool reaches only `docs/qa/<id>/`. It is the single exception to the rule that nothing is written outside `docs/qa/<id>/`.

## Out of reach
What only real hardware, an iOS simulator or a headset would show is listed under `## Not seen` of the report, with that reason. A driver never claims it saw it.
