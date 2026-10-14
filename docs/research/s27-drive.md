# Research — s27-drive

[Story](../stories.md)

## Structuring facts
- **Wrong assumption — `Owns` is too narrow.** Creating `method/commands/po-drive.md` turns `test_every_command_listed_in_help` red at once: it loops over `method/commands/po-*.md` and demands each name in `po-help.md` (`tests/pilot.test.sh:38-46`). That file belongs to s31 (`docs/stories.md:466`), which ships after s27 and even carries `help_lists_po_drive` (`docs/stories.md:471`). s27 must own the one `/po-drive` line of `po-help.md`, or it ships a red suite.
- **Wrong assumption — "no Write, no Edit" leaves nobody to record the verdict.** `/po-review` writes `docs/reviews/<id>.md` with Write (`method/commands/po-review.md:9,33`), and `reviewer` declares `Read, Grep, Glob, Bash, Edit` (`method/agents/reviewer.md:4`) — Edit cannot create a missing file. Either the driver records through Bash, or the verdict is lost. See Open questions.
- Three mechanical rules catch a new command the moment it exists: `Reads settings:` present and every backticked name known to the template (`bin/po-lint:87-104`, `tests/structure.test.sh:24-34`), tool contract (`bin/po-lint:112-145`), fail-closed arrows inside `## Checks`/`## Preconditions`/`## Step 0` only (`bin/po-lint:153-171`).
- A new settings line must match `^[A-Z][A-Za-z0-9 ]*:[[:space:]]+[^[:space:]#][^#]*$` (`tests/structure.test.sh:10-12`); the table under the block documents each one (`method/templates/agents-local.md:31-51`).
- ADR-0016 — the law this story implements — is still `status: proposed` (`docs/decisions/ADR-0016-flotte-un-driver-des-subagents.md:6`), and no story owns it.

## Story
`s27-drive` (`docs/stories.md:406-421`, complexity 4, depends on s26 — shipped at `94b881d`). A `/po-drive` command that advances every ready story in parallel, one lane per story, instead of one story at a time.

Owns: `method/commands/po-drive.md`, `method/templates/agents-local.md`, `tests/drive.test.sh`. Matrix: D05 and D16.

Acceptance criteria, each a `test_<name>` of `tests/drive.test.sh`:
1. `drive_picks_a_ready_set_without_conflicts` — ready = not shipped, every dependency shipped, `Owns` paths disjoint from the running lanes and from the chosen batch; at most `Parallel` lanes.
2. `drive_dispatches_lanes_in_one_message` — a wave's subagents go out together, `planner` then `implementer` then `reviewer` per lane, each under its own contract.
3. `drive_never_writes_code_or_verdicts` — no Write, no Edit; it prepares worktrees, dispatches, checks and reports.
4. `drive_ships_serially_after_each_review` — ships go one by one onto the target branch, `Ship allowed` gate included; a blocked story goes back to a fix run within `Max attempts`.
5. `settings_template_declares_fleet_settings` — `Parallel` (3), `Max attempts` (2), `Tracker` (`none`, `github` when a remote exists) declared and documented.

## Current code
- `method/commands/po-orchestrator.md` — walks one story: stage 0 framing, stage 1 track, research, design, plan checkpoint, execute, review, ship. Tools `Read, Glob, Grep, Bash, Write, Agent, AskUserQuestion`; `pilot.test.sh:8-21` counts exactly two `## Stage … — checkpoint` headings in it and forbids Edit.
- `method/commands/po-status.md` — derives every story's stage from files and git alone (`method/commands/po-status.md:22-32`): plan frontmatter, `docs/verif/`, last `Ship allowed:`, a commit whose subject starts with `<id>:` on `Target branch`, dependencies not shipped. Read-only, no Write, no Edit.
- `method/commands/po-execute.md` — no Write/Edit/Bash by construction; checks the worktree through `<shared>/worktrees/<id>/gitdir` and `HEAD` (`:23`), refuses a plan without `validated: yes` (`:25`), detects a fix run from a review ending `Ship allowed: no` (`:26`), then delegates to `implementer` with a fixed prompt (`:32-40`).
- `method/commands/po-review.md` — delegates to `reviewer`, records the whole answer, and writes a blocked verdict itself when the subagent returns nothing usable (`:35`); loop number = previous `Fix loop:` + 1, a third blocked review is refused (`:25`).
- `method/commands/po-ship.md` — gate first (`po-gate ship-allowed`), then the single expensive run, squash merge, cleanup only on proof (`:46-48`). `Merge mode: local` requires the repository root clean and on `Target branch` (`:43`) — this is why ships cannot be parallel.
- `method/agents/planner.md` — the s26 subagent: reads `method/commands/po-research.md` and `po-plan.md` and honours them (`:35`), picks its track (`:26-32`), writes `validated: yes` under `Plan validation: autonomous` (`:44`), never runs `git worktree add`, `switch`, `checkout` or `stash` because "the driver prepared this lane (ADR-0016)" (`:24`).
- `method/templates/agents-local.md` — fenced Pipeline block (`:9-29`), then a `| Setting | Values |` table (`:31-51`), then the Commands block.

## Attachment points
- New file `method/commands/po-drive.md`, frontmatter like the other commands: `description`, `argument-hint`, `allowed-tools`.
- `method/templates/agents-local.md`: three lines inside the Pipeline fence, three rows in the table.
- New file `tests/drive.test.sh`, sourced automatically by `tests/run.sh:6` (`*.test.sh`).
- One `/po-drive` line in `method/commands/po-help.md` — see the first structuring fact.
- `docs/parite-killer-saas.md:54` (D05) and `:65` (D16) status cells.

## Verified interfaces
- `tests/lib.sh` helpers: `fail`, `frontmatter`, `tools_of`, `has_tool`/`needs_tool`/`lacks_tool` (`:27-29`), `template_settings` (`:32`), `settings_read_by` (`:37`), `require_file` (`:41`), `contains` — exact and case-sensitive `grep -qF` (`:43`), `scratch_repo` (`:46`).
- `section_of` / `line_of` / `holds` / `reads_setting` are local to `tests/wiring.test.sh:10-17`; `cap_of` is local to `tests/planner.test.sh:9`. Nothing shared: a test file that wants them redefines them.
- `po-gate` verbs: `plan-validated <id>`, `ship-allowed <id>`, `verif-current <id>`, `pre-commit` (`method/hooks/po-gate.sh:4-7`). `ship_allowed` reads the **last** `Ship allowed:` line (`:28`).
- `tests/run.sh` runs each `test_*` in its own `bash -c` with `set -eu`, so `fail` ends only that test (`tests/run.sh:17`).
- Baseline on `story/s27-drive` before any change: `bash tests/run.sh` → **144 passed, 0 failed**; `bash bin/po-lint` → no breach.

## Traps
- `tests/pilot.test.sh:38` is the one that breaks. Nothing else enumerates commands; `tests/structure.test.sh:26` also loops over `commands/*.md` but only demands a `Reads settings:` line with known names, which the new file will have.
- `bin/po-lint:125-128` reports `Agent` + `Edit` together. `Agent` + `Write` is legal (`po-review`), `Agent` + `Bash` too (`po-flow`). The frontmatter phrase `cannot edit files or run a shell` forbids Write/Edit/Bash (`bin/po-lint:131`) — do not copy that sentence from `po-execute.md` into a driver that needs Bash.
- `bin/po-lint:153-171` only scans `## Checks`, `## Preconditions`, `## Step 0`. An arrow line in those sections whose left side says "No/no/None/none/Missing/missing/not/`—`/Any other/Another" must contain `stop`, `ask`, `carry on` or `never blocks`.
- `docs/parite-killer-saas.md` belongs to s31 (`docs/stories.md:466`), yet `AGENTS.local.md` tells every story to update its own matrix lines. s26 resolved the same clash by not touching the file at all (`git show 94b881d --stat`), leaving D02/D04 stale — a silent precedent, not a decision.
- `docs/defauts.md` is the issue tracker while there is no GitHub remote (`docs/defauts.md:3`); `Issue tracker: —` in `AGENTS.local.md`.
- No remote here (`git remote -v` empty), so a `Tracker` default derived from "the repository has a remote" evaluates to `none` in this repository.
- `Merge mode: local` + `Ship confirmation: automatic` in this project: a wave's ships all touch the same repository root, which `po-ship.md:43` requires clean — serial ships are a constraint, not a preference.
- No migration, no screen, no dependency added. The change is markdown plus one bash test file.

## Open questions
- Who writes `docs/reviews/<id>.md` in a lane? The driver through a Bash heredoc (keeps criterion 3 literally true, records the answer verbatim), or the `reviewer` told to write its own report (it has Bash, but its file is owned by s28)? The plan decides and says why.
- Does s27 add the `/po-drive` line to `po-help.md` itself, or does it accept a red test until s31? Leaving the suite red contradicts `AGENTS.local.md` ("Keep existing tests green") and the implementer's end-of-run full suite.
- Does s27 update D05 and D16 in `docs/parite-killer-saas.md` despite s31 owning the file, or record the omission in `docs/defauts.md`?
- Should ADR-0016 move to `accepted` here, since s27 is its implementation? No story owns it.

## Complexity
Story says 4; after reading the code, still **4**. The command itself is one markdown file, but it must restate four existing contracts without drifting from them, and its `Owns` collides with two later stories.

## Split
Not required at 4.
