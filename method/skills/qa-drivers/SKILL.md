---
name: qa-drivers
description: Which driver checks a story's surface on the project's platform, where its file is read, what a driver file says, and where a driver may leave anything besides its evidence. Preloaded by the qa subagent.
---
# QA drivers

A QA checks one story the way its user meets it. A screen is opened in a browser; a command is typed and its answer read; a scene is looked at; a robot is watched. Each way of doing this is a driver, written in a file of its own next to this one.

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

When `Platform` holds several values, every row whose surface and platform both match applies, in the order of the table, each one run in full: a `screen` story on `web, mobile` runs `browser.md`, then `mobile-web.md`.

## Where a driver file is read
A driver file lives in the base directory announced for this skill when it was loaded, that is the folder holding this `SKILL.md`, whether the method was laid down for the whole machine or inside the project. It is never looked for at a fixed path such as `.claude/skills/`. When no base directory was announced, or that folder holds no file of the name the table gives, the QA ends with `QA status: blocked` and the report names the missing file.

## What each driver file says
- what it needs before it starts: a setting, a tool of the session;
- how it starts what is checked and how it stops it;
- how it exercises one acceptance criterion;
- the form of its evidence and the names of its files under `docs/qa/<id>/`;
- what it cannot show.

## Outside the evidence
A driver may produce things that are not evidence: a build, a recording, a scratch file. They go into a directory of their own, created through Bash with `mktemp -d` under `${TMPDIR:-/tmp}`, and that directory is removed when the QA ends. It is the single exception to the rule that nothing is written outside `docs/qa/<id>/`.

## Out of reach
What only real hardware, an iOS simulator or a headset would show is listed under `## Not seen` of the report, with that reason. A driver never claims it saw it.
