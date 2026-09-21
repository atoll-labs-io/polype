---
track: flow
validated: yes
---
# Plan (short track) — s31-fleet-wiring

Written by `/po-flow`. On the short track this one file stands in for both the research and the plan: there is no `docs/research/s31-fleet-wiring.md`.

## Verified facts

- **The rules say nothing about the fleet.** `method/AGENTS.md` never contains the string `drive`; the piloting paragraph `method/AGENTS.md:40` names `/po-orchestrator`, `/po-status` and `/po-help` only. `Owns` appears nowhere in `method/AGENTS.md` either — it lives in `method/skills/review-antihallu/SKILL.md:9-20`, `method/skills/agentic-stories/SKILL.md:20-21` and `method/templates/stories.md:12`. So all three claims of `rules_describe_the_fleet` are new text.
- **`/po-drive` is already in the help.** `method/commands/po-help.md:31` reads "`/po-drive` — la flotte : fait avancer en parallèle toutes les stories prêtes, une lane par story, et ship une par une." `test_every_command_listed_in_help` (`tests/pilot.test.sh:38-46`) greps `/po-<basename>` in the help for every `method/commands/po-*.md`, so it is green today and stays green.
- **The help hides the read-only mode.** `method/commands/po-drive.md:3` declares `argument-hint: [status]` and `:111-116` fix what `status` reports, but `po-help.md` never mentions it: a user reading the cheat sheet cannot discover `/po-drive status`. This is what `help_lists_po_drive` can actually bite on.
- **`/po-status` knows nothing of lanes.** `method/commands/po-status.md:11` reads `Target branch`, `Worktree root`, `Merge mode`, `Plan validation`, `Entry mode`, `Story track`, `Flow threshold` — not `Parallel`, not `Max attempts`. Step 3 (`:22-31`) derives one row per story; nothing counts running lanes, nothing reads the `Fix loop:` of `docs/reviews/<id>.md` as attempts spent, and step 4 (`:32`) sends a blocked story to `/po-execute` without ever saying it has exhausted its budget.
- **The driver already defines the three notions the status must show.** A lane is a prepared worktree on `story/<id>` (`po-drive.md:63-67`); attempts are read from the `Fix loop:` line of `docs/reviews/<id>.md`, never from memory (`po-drive.md:56`); a story is blocked by a dependency, an `Owns` collision, `Max attempts` reached, or an orphan worktree (`po-drive.md:115`). `/po-status` must mirror those, not invent its own.
- **The settings exist.** `Parallel: 3`, `Max attempts: 2`, `Tracker: none` are in `method/templates/agents-local.md` (Pipeline block) with their rows in the values table. `tests/structure.test.sh:24-34` and `bin/po-lint` (rule `settings`) both require every name on a `Reads settings:` line to exist there, so adding `Parallel` and `Max attempts` to `po-status.md` is legal.
- **`bin/po-lint` lints commands and agents only** (`bin/po-lint:72`): `method/AGENTS.md` is not linted, but `po-status.md` is. Its `fail-closed` rule flags a sentence where an absence leads to no stop (`tests/lint.test.sh:76-93`), so new `/po-status` prose must not write "X missing → assume Y".
- **Installed copies are not this story's business.** `git show --stat 91ecdfb` (s27) and `5157460` (s30) touch `method/`, `tests/` and `docs/` only — never `.claude/`, `.polype/` or the root `AGENTS.md`. `bin/polype-dev-install .` regenerates those; running it is out of scope.
- **Parity lines, current state.** `docs/parite-killer-saas.md:13` (A02) and `:58` (D09) both say `partiel — … ; contrôle d'ownership en M3`; s28 delivered that check (`review-antihallu/SKILL.md:9`). `:65` (D16) says `… ; validation groupée par vague en s30`; s30 delivered it (`po-drive.md:79-94`). `:54` (D05) is already `fait`. `:66` (D17) says `… ; tracker en M3`.
- **D17's "tracker" clause is obsolete, not pending.** ADR-0003 put fleet state in a tracker; ADR-0016 (`docs/decisions/ADR-0016-flotte-un-driver-des-subagents.md`, Consequences) moves it into the session and the worktrees and leaves the tracker as optional visibility. `po-drive.md:25` matches: `Tracker: github` is announced as not handled and the run carries on from worktrees and git. So D17 is complete once `/po-status` shows the fleet — its Polype cell is what is stale.
- **Known, not fixed here.** ADR-0016 is still `status: proposed` while `po-drive.md:18` cites it as settled. `docs/decisions/` is outside this story's `Owns`: reported, untouched.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text lists only method docs and one test file | absent — no data, no schema anywhere in `method/` |
| New screen | absent — no interface in the story | absent — `/po-status` output is terminal text, no `docs/designs/` |
| Authorization or tenant scope | absent — story text | absent — nothing in the touched files |
| API contract | absent — story text | absent — `Reads settings:` grows, but `structure.test.sh` and `po-lint` already fix that format |
| New dependency | absent — story text | absent — bash and the existing helpers only |

## Story

Developer-facing wiring: the rules, the help and the status must know about the fleet, so it can be launched, followed and stopped without reading the method files.

- `rules_describe_the_fleet` — `AGENTS.md` explains that a fleet is a driver and lanes, that ships stay serial, and that `Owns` bounds each story.
- `help_lists_po_drive` — `every_command_listed_in_help` stays green with `/po-drive`.
- `status_shows_lanes_and_attempts` — `/po-status` shows, for a fleet in flight, the lanes, the attempts and the blocked stories.
- `parity_matrix_reflects_the_fleet` — lines A02, D05, D09, D16 and D17 become `fait — <path>`.

## Tasks

1. [x] **`method/AGENTS.md` — the fleet in the rules.** Add a `### The fleet` subsection at the end of Law 1, after the `/po-orchestrator` paragraph (`:40`), holding three claims in your own words: `/po-drive` is one driver that opens one lane per ready story and runs those lanes at the same time; ships never overlap — they land on `Target branch` one at a time, in the order their reviews passed; each story's `Owns` line bounds what its lane may change, and two stories sharing an `Owns` path never run at once. Name `/po-drive` and `/po-drive status`. Nothing else in the file moves.
   *Fails without it:* `rules_describe_the_fleet`.
2. [x] **`method/commands/po-help.md` — the read-only mode.** Extend line 31 so the entry also names `/po-drive status` and what it answers (what is in flight, what is waiting, nothing launched). French, one or two lines, in the `## Outils` list.
   *Fails without it:* `help_lists_po_drive` (the `status` clause).
3. [x] **`method/commands/po-status.md` — the fleet in the report.** Add `Parallel` and `Max attempts` to the `Reads settings:` line (`:11`), in backticks. Add a fleet step between the per-story step and `## Output`: the lanes in flight — a worktree `<Worktree root><id>` whose HEAD is `story/<id>` — counted against `Parallel`; the attempts already spent, read from the `Fix loop:` line of `docs/reviews/<id>.md` the way `/po-drive` reads them, shown against `Max attempts`; and the blocked stories with the reason `/po-drive` fixes — a dependency not shipped, an `Owns` collision, `Max attempts` reached, an orphan worktree. State that a setting left unread stops the fleet section rather than being guessed, and keep every existing clause `tests/wiring.test.sh:38-50` and `tests/pilot.test.sh:22-31` check. No branch may read "absent → assume": `bin/po-lint` fails on it.
   *Fails without it:* `status_shows_lanes_and_attempts`.
4. [x] **`docs/parite-killer-saas.md` — five status cells.** A02 (`:13`) and D09 (`:58`) → `fait`, citing `method/skills/review-antihallu/SKILL.md` next to the file each already names. D05 (`:54`) → leave `fait`, only drop nothing. D16 (`:65`) → `fait — method/commands/po-orchestrator.md, method/commands/po-drive.md`. D17 (`:66`) → `fait — method/commands/po-status.md, method/commands/po-drive.md`, and rewrite D17's **Polype** cell so it no longer claims the state is read from a tracker: per ADR-0016 the fleet state is derived from the worktrees and git, the tracker being optional visibility. Touch no other row.
   *Fails without it:* `parity_matrix_reflects_the_fleet`.
5. [x] **`tests/fleet-wiring.test.sh` — the four tests.** New file, header `# s31 — rules, help and status know about the fleet.`, one `test_<criterion name>` per acceptance criterion, using `tests/lib.sh` helpers and the local `section_of` / `holds` pattern of `tests/drive.test.sh:7-10`. See `## Test strategy`.
   *Fails without it:* every criterion — this is the proof.

## Run interdicts

- `.claude/`, `.polype/` and the root `AGENTS.md` end with an empty diff: they are installed copies, regenerated by `bin/polype-dev-install`, which you do not run.
- `docs/decisions/` ends with an empty diff. ADR-0016 being `proposed` is reported in the record, not fixed.
- No existing test file is edited. `tests/pilot.test.sh` and `tests/wiring.test.sh` must stay green untouched.
- `docs/stories.md`, `docs/milestones.md` and every parity row other than A02, D05, D09, D16, D17 end with an empty diff.
- `bash tests/run.sh` at the end; `bash bin/po-lint` too, since `po-status.md` changes.

## Files touched

`method/AGENTS.md` · `method/commands/po-help.md` · `method/commands/po-status.md` · `docs/parite-killer-saas.md` · `tests/fleet-wiring.test.sh` — plus this story's own evidence (`docs/plans/`, `docs/verif/`).

## Test strategy

Four tests in `tests/fleet-wiring.test.sh`, well inside the budget of 25. Every one greps short exact phrases of the file under test, so deleting the clause turns it red — check that by hand before writing the record.

- `test_rules_describe_the_fleet` — `require_file` on `method/AGENTS.md`, take Law 1's body with `section_of`, then `holds` on the phrases you wrote for the three claims (driver and lanes in parallel, ships one at a time on the target branch, `Owns` bounding a lane) and on `` `/po-drive` ``. Do not re-check the Framing/Per-story ordering: `tests/wiring.test.sh:19` owns that.
- `test_help_lists_po_drive` — `require_file` on `po-help.md`, `contains` on `/po-drive status`, and on the fleet wording of the entry. The generic coverage lives in `tests/pilot.test.sh:38`; this one bites on what that test cannot see.
- `test_status_shows_lanes_and_attempts` — `require_file` on `po-status.md`, assert `settings_read_by` yields `Parallel` and `Max attempts` (the `reads_setting` shape of `tests/wiring.test.sh:17`), then `holds` on the fleet section for: the lane definition, `` `Fix loop:` ``, `` `Max attempts` ``, and each of the four blocked reasons.
- `test_parity_matrix_reflects_the_fleet` — for each of A02, D05, D09, D16, D17, pull the row with `grep -m1 "^| $id |"` and fail unless its last cell starts with `fait — `. A loop, not five copies; the assertion must reject `partiel`.

## Done when

`bash tests/run.sh` is green — the four new tests and every existing one, `tests/pilot.test.sh` and `tests/wiring.test.sh` included; `bash bin/po-lint` reports nothing; the diff stays inside the story's `Owns` plus its own evidence; `git status --porcelain` lists no environment file; one commit on `story/s31-fleet-wiring`.
