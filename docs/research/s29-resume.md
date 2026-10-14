# Research — s29-resume

[Story](../stories.md)

## Structuring facts
- `/po-drive` already reads state from files (`method/commands/po-drive.md:26`) but its dispatch is unconditional: the "Per lane, in this order" list (`:47-51`) always sends `planner`, then `implementer`, then `reviewer`. Nothing tells it to skip a stage already done — **this is the whole gap of the story**.
- `status` is half there: the argument exists (`method/commands/po-drive.md:9,15`) and the Report section forbids side effects for it (`:72`), but the report names neither the running lanes nor the attempts.
- The attempt count survives a crash only as `Fix loop:` inside `docs/reviews/<id>.md`: `/po-review` computes the next loop as "its `Fix loop:` value plus one … (0 when there is none)" (`method/commands/po-review.md:25`). The driver's in-session counter is not durable; the file is.
- Orphan detection exists on one axis only — the branch (`method/commands/po-drive.md:44`) — and never on the path: a `story/<id>` branch checked out somewhere other than `<Worktree root><id>` passes today.
- `/po-status` already derives every stage the story lists, per story and from the worktree while it exists (`method/commands/po-status.md:22-31`); the driver cites it (`:26`) rather than re-deriving, so s29 extends that citation instead of duplicating rules.

## Story
`/po-drive` must resume instead of restarting. Three criteria:
1. `drive_resumes_from_what_exists` — per story, the stage reached is deduced from the worktree files (research, plan validated or not, record, review) and from git; the lane restarts at the next stage.
2. `drive_status_reports_lanes` — `/po-drive status` lists the lanes in flight, the attempts, the blocked stories and what they wait for, launching nothing.
3. `drive_detects_an_orphan_worktree` — a worktree whose branch or path does not match is reported and never silently repaired.

Owns: `method/commands/po-drive.md`, `tests/resume.test.sh`. Matrix line D17.

## Current code
- `method/commands/po-drive.md` (73 lines, frontmatter `Read, Glob, Grep, Bash, Agent, AskUserQuestion`, no Write/Edit). Sections: `## Checks`, `## The ready set`, `## A wave` (with `### Preparing the lanes`, `### Dispatching`), `## The verdict, and the fix runs`, `## Ships, one at a time`, `## Report`. Reads `Target branch, Worktree root, Install, Parallel, Max attempts, Tracker, Plan validation, Merge mode, Ship confirmation`.
- `method/commands/po-status.md:22-31` — the per-story derivation: complexity, track, research, design, plan (`none · draft · approved`), record (present + `po-gate verif-current <id>`), review (last `Ship allowed:` and its `Fix loop:`), shipped (a commit whose subject starts with `<id>:`), dependencies.
- `method/hooks/po-gate.sh` — `plan-validated` (`:18-23`), `ship-allowed` (`:26-32`), `verif-current` (`:35-47`). These three are the machine-readable stage probes; `verif_current` compares the record's `Tree:` to `HEAD` excluding `docs/`.
- `tests/drive.test.sh` (111 lines) — five tests, each pulling one `## <heading>` section out of `po-drive.md` with `section_of` and asserting exact phrases with `holds`. The dispatch order is asserted by extracting `subagent_type: <name>` occurrences from the `A wave` section and comparing the joined string to `"planner implementer reviewer "` (`:45-47`).

## Attachment points
- **Resume rules** → a new section of `po-drive.md`. Putting them under a new `## …` heading keeps `tests/drive.test.sh`'s `section_of` extractions untouched, which matters: `test_drive_dispatches_lanes_in_one_message` would break if a resume paragraph mentioning `subagent_type:` landed inside `## A wave`. Any resume text inside `A wave` must avoid the literal `subagent_type: <name>`.
- **Status report** → `## Report`, last section of the file; `section_of` reads to the next `## ` or EOF, so appending is safe.
- **Orphan detection** → `### Preparing the lanes` (`:42-45`), which already holds the branch check. Adding the path axis there keeps one place for "confirmed, never repaired".
- **Tests** → new file `tests/resume.test.sh`, picked up automatically by `tests/run.sh` (`tests/run.sh:6` globs `*.test.sh`). Reuse the `section_of`/`holds` shape of `tests/drive.test.sh`; those two helpers are local to that file, so `resume.test.sh` defines its own.

## Verified interfaces
- `tests/lib.sh` helpers usable as-is: `contains <file> <text>` (exact, `grep -qF`, `:43`), `require_file` (`:41`), `needs_tool`/`lacks_tool` (`:28-29`), `fail` (`:11`), `settings_read_by` (`:37`), `template_settings` (`:32`).
- `tests/run.sh:11,17` sources each file under `set -eu` and runs every `test_*` function in its own process.
- `bin/po-lint` rules that will judge the new text: `settings` (every backticked name on the `Reads settings:` line must exist in `method/templates/agents-local.md`, `:74-104`), `tools` (`:106-145`), `fail-closed` (`:153-171`) — the last one applies **only** inside sections headed `## Checks`, `## Preconditions` or `## Step 0` (awk guard at `:160`). New `→` lines outside those headings are not linted, but should still fail closed by intent.
- `tests/overlap.test.sh:15` runs `bin/ks-overlap` over `method/` and fails on 8+ consecutive shared words with Killer SaaS — new prose must be written from `docs/parite-killer-saas.md:66` (line D17), never from a Killer SaaS source.

## Traps
- `tests/drive.test.sh:45-47` is the sharpest trap: it greps `subagent_type: [a-z]*` across the whole `## A wave` body and demands exactly `planner implementer reviewer `. A resume rule phrased as "skip `subagent_type: planner` when…" inside that section turns the suite red.
- `method/commands/po-drive.md:26` already claims state is "derived the way `/po-status` derives it" and `tests/drive.test.sh:18-19` pins that phrase. The resume section must extend it, not restate it differently, or the two sentences contradict each other in the same file.
- `Max attempts` is already declared and tested (`tests/drive.test.sh:97,105`); s29 adds no setting, so `method/templates/agents-local.md` stays untouched — and it is not in this story's `Owns` anyway.
- `docs/parite-killer-saas.md` line D17 is `partiel`; per `AGENTS.local.md` a story updates its own matrix lines. But D17 is listed in the `Owns` of **s31-fleet-wiring**, and `docs/parite-killer-saas.md` is s31's file. s29 must not touch it: s28 just shipped the rule that a diff stays inside what the story owns.
- Test budget is 25 per story; three criteria means three test functions, one per criterion, names taken verbatim from the story.
- `.worktrees/` is gitignored (`.gitignore:6`), so the story worktree never shows up in `git status`.

## Open questions
- Does "the lane reprend à l'étape suivante" include re-running a stage whose output exists but is stale — a record whose `po-gate verif-current` fails? The plan decides; the honest reading is that a stale record is not a reached stage, so the lane goes back to the implementer.
- Should `status` read the `Fix loop:` of a review as the attempt count, or count fix commits on the branch? The review file is the only durable, unambiguous source; the plan should say so explicitly.

## Complexity
Story: 3 → after reading: **3**. The work is prose in one method file plus one test file, but it must thread between two existing tests that grep that same file, and it touches three sections rather than one.

## Split
Not needed.
