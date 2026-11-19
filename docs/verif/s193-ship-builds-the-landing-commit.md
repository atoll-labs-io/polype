# Verification — s193-ship-builds-the-landing-commit

[Story](../stories.md) · [Plan](../plans/s193-ship-builds-the-landing-commit.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: b1580e528f7c2edbe27027ea01ed9de437500ff7

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project; `tests/run.sh` builds `po` with `cargo build --release --locked` first, without warning |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |
| `tests/ship-builds-the-landing-commit.oracle.test.sh` | The fixture of `project` writes one more setting line, `Ship confirmation: automatic`; no assertion changes (cksum `4197583642 9815`). | Fix run, review major at `land.rs:531`: `po` now refuses `--land` unless the `Ship confirmation` line reads `automatic`, so `test_local_mode_lands_here`, which calls `--land` as an effective `automatic` would, needs the project to declare it. |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- `ship_command_calls_it` is a model-read rule: no test, judged in review; `po-ship.md` is at 2 298 words (`LC_ALL=C wc -w`), only the 2 700 ceiling of s179 being checked by a script.
- `po ship land` ran only on throwaway repositories under `mktemp -d`, whose only remote is a local bare repository; never on this repository nor a real forge. A project with `core.hooksPath` set (the pre-commit on the docs commit) was not exercised.
- `E2E stage: ship`, `Build stage: ship` and `--routes yes` are tested with `true`/`false` commands only (`test_e2e_and_build_run_at_ship`), never a real `<E2E>` or `<Build>`. `E2E scope` and `E2E browsers` are left to the project's `<E2E>` command (review major at `po-ship.md:11`, not fixed in this story: the lead files it as an issue).
- The already-landed guard (fix run 3, review major at `land.rs:491`) recognises exactly two states, both before any check and writing nothing. First, before the conflict probe: a commit of `<base> ^story/<id>` whose subject is exactly `<id>: <title>` (ids are never reused); `sha` is the newest such commit, `tree` its tree, whatever later commits did to the story's lines. Tested under `local` with `main` moved past the landing by an unrelated file (checks that append rows, and a recorded suite), by an edit of the line the story changed (no `conflict`), and by a revert of it (no check, no second commit, the revert kept on `main`); and under `pr` with a local bare origin whose `main` moved past a merged landing. Second, with no such commit: `merge-tree <base> story/<id>` gives back the base's own tree while `story/<id>` holds a change of its own since its merge base, meaning the base already holds the story's change under another subject; `sha` is the base. Tested once under `local`.
- What the guard does not recognise: a landing whose subject was changed (a forge squash merge appending ` (#N)`, a reworded commit) once the base holds only part of the story's change or changed its lines afterwards. That story is treated as not landed: it goes to the conflict probe, the checks and a new landing commit. Untested, read from the code.
- A story branch with no change of its own since its merge base (no commit, or commits that undo each other), when no commit of the base carries the subject, is refused as `nothing-to-land`, exit 1, writing nothing. Tested with a branch with no commit of its own; commits that undo each other are read from the code.
- A second conflict after the docs commit (base already holding `docs/reviews/<id>.md`) is handled in code, with no test.
- No type check, end-to-end or build exists in this project.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 8b5d455f91620d3a173f6854509410e577a5c109 | 2026-11-18T17:04:33Z (391s) |
| Unit suite | `bash tests/run.sh` | 0 | 702107f6bf00fb7df45b88b88c66ff0db706c902 | 2026-11-18T17:20:49Z (392s) |
| Unit suite | `bash tests/run.sh` | 0 | 094e49827478e041f7d3c4e51bd5d4c815d73467 | 2026-11-18T17:34:44Z (395s) |
| Unit suite | `bash tests/run.sh` | 0 | 8ac9ab2af1d8dddf27340a44cea16325815e6e3d | 2026-11-19T10:13:38Z (477s) |
