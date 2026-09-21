# Review — s27-drive

Diff reviewed: `git diff m3-flotte...story/s27-drive`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0

## Evidence reused
- [x] `po-gate verif-current s27-drive` → exit 0; `git diff --quiet 242227c HEAD -- . ':(exclude)docs'` → exit 0. `Verification mode: record`, so the record is evidence: unit suite `bash tests/run.sh` exit 0, 149 passed / 0 failed; `bash bin/po-lint` exit 0, no breach in `method/`. Neither rerun here. The record's "Not proven here" is honest and I extend it below.
- Typecheck, E2E and Build: `AGENTS.local.md` declares `Typecheck: —`, `E2E: —`, `Build: —` — the project has none, and I substituted nothing.

## Plan
- [x] Tasks 1–10 all present in the diff: three settings + three table rows (`method/templates/agents-local.md:29-31,55-57`), the new command, its `## Checks`, ready-set, wave, verdict and ship sections, the one `/po-help` line, `tests/drive.test.sh`, and D05/D16 in the parity matrix. Nothing in the diff is outside the plan.
- [x] Run interdicts, one by one: `method/agents/reviewer.md`, `method/skills/review-antihallu/SKILL.md`, `method/AGENTS.md`, `method/commands/po-status.md`, `docs/decisions/`, `.claude/`, `.polype/` — all absent from the diff. `po-help.md` = exactly one added line. `docs/parite-killer-saas.md` = exactly the D05 and D16 cells. `Tracker: github` is declared and explicitly deferred, not implemented. Suite 144 → 149 as required; no existing test file is touched, so none was relaxed.
- [x] One commit, `5187deb`; no `.env*` in the diff.

## References
- [x] Every file the command cites was opened and says what the command claims: `method/commands/po-status.md:32` (state derived from files and git), `po-research.md:24-30` (fetch, `git worktree add -b story/<id>`, `.env*` copy, `Install`), `po-execute.md:32-40` (the prompt, word for word, plus the fix-run sentence), `po-review.md:30,35` (the reviewer prompt and the blocked fallback the driver reproduces), `po-ship.md:43-48` (repository root clean and on `Target branch`; gate, squash, cleanup on proof), `method/agents/planner.md:24` (never `git worktree add`, `switch`, `checkout`, `stash`), `method/agents/reviewer.md` (no Write — hence the Bash transcription). `Owns` is a real story field (`method/templates/stories.md`, `docs/stories.md`).
- [x] Every name in `Reads settings:` (po-drive.md:14) exists in the template, and each is actually used in the body.
- [x] Values: `Parallel 3` / `Max attempts 2` / `Tracker none` match the acceptance criterion verbatim (`docs/stories.md:420`); `Max attempts 2` agrees with `/po-review:25` ("a third blocked review in a row is not requested") — see finding 4 for the values above 2.

## Rules
- [x] `AGENTS.local.md` conventions respected: method written in English, `po-help.md` the French exception, `Reads settings:` first line, no Write/Edit on a command that must not write code, templates referenced as `templates/<name>.md`, parity cells updated for this story's own lines only.
- [x] No accepted ADR contradicted. ADR-0016 is the decision this story implements and is still `status: proposed`; the plan deliberately leaves it alone (no story owns it) — correct, since an accepted ADR is never edited but a proposed one is not this story's to promote either.
- [ ] Law 1 ("none skipped") — see finding 1.

## Tests
- [x] 5 tests, one per acceptance criterion, within `Test budget: 25`. None of the six empty shapes: no mock, no fixture, no swallowed error; they assert exact phrases of the file under test with `grep -qF`, which is the only form of coverage a method repository has.
- [x] Bite, five mutations, each run against `tests/drive.test.sh` only:
  - removed `stop at \`Parallel\` lanes` (ready set) → 1 failing test (`drive_picks_a_ready_set_without_conflicts`)
  - renamed `subagent_type: reviewer` → `checker` → 1 failing test (`drive_dispatches_lanes_in_one_message`, order assertion)
  - added `Write` to `allowed-tools` → 1 failing test (`drive_never_writes_code_or_verdicts`)
  - replaced `recorded **verbatim** into` by `summarised into` and `Ships never overlap.` by a soft sentence → 2 failing tests
  - `Parallel: 3` → `5` in the template, then deleted the `Max attempts` doc row → 1 failing test each (run separately, because the first assertion masks the second)
  - All undone; `git diff --exit-code` clean on both files and `git status --porcelain` empty before writing this.
- [x] No test made useless by the story; nothing removed.

## Neighbours
- [x] `tests/pilot.test.sh:38` (`every_command_listed_in_help`) is the only test that enumerates commands and is satisfied by the added help line; `tests/structure.test.sh:26` is satisfied by the `Reads settings:` line. `bin/po-lint` runs against `method/` in the suite and is green in the record.
- [x] `/po-setup` copies `templates/agents-local.md` wholesale (`po-setup.md:43`) and states that every unasked setting keeps the template value (`:38`), so new projects get the three settings without a change to `/po-setup`.
- [x] Nothing else in `method/` or `bin/` reads `Parallel`, `Max attempts` or `Tracker` — expected, `/po-status` and `AGENTS.md` are s31's.

## Findings
- **major** — `method/commands/po-drive.md:49-52` — a lane is `planner` → `implementer` → `reviewer`, with no design stage. `AGENTS.md` Law 1 lists design among the per-story stages, "none skipped, none reordered"; `/po-orchestrator:31,47,57-58` stops when `docs/design-system.md` or `Design source` is missing, runs `/po-design`, then appends the design sentence to the `/po-execute` prompt; `/po-execute:27,38-40` and `/po-status:32` both expect `docs/designs/<id>/`. A story with a screen driven by `/po-drive` is therefore implemented with no design and no design-system prerequisite check, and the `## Report` section has no line that says the stage was skipped — unlike `Tracker: github`, which is acknowledged in `## Checks`. No later fleet story covers it: s28 is ownership, s29 resume, s30 grouped validation, s31 wiring. The gap traces back to ADR-0016, which lists only the three subagents, so the fix is a method decision (a design lane, or a stated interdict "a story with a screen does not enter a wave"), not a rewrite of this file. Harmless in this repository, which has no screens.
- **minor** — `method/commands/po-drive.md:20-25` — the only framing the Checks look at is `docs/stories.md`. `/po-research:20` warns (without blocking) when `docs/reviews/stories.md` does not end with `Stories ready: yes`, and `/po-orchestrator:31` stops on missing design prerequisites. A wave launched straight from `/po-drive` loses both signals.
- **minor** — `method/commands/po-drive.md:35` — "`Owns` paths are disjoint" never says how two paths are compared. `docs/stories.md` mixes directories (`method/skills/review-antihallu/`, s06) with files under them (`method/skills/review-antihallu/SKILL.md`, s28); read as string inequality, those are disjoint and both lanes start on the same file — precisely the risk the story names ("l'isolation tient aux worktrees et à `Owns`"). One clause ("a directory covers everything under it") closes it.
- **minor** — `method/commands/po-drive.md:61,68` and `method/templates/agents-local.md:30,56` — `Max attempts` is an open integer, while `/po-review:25` hard-codes that a third blocked review in a row is not requested. The default 2 agrees; a project setting 3 makes the driver ask for a review `/po-review` refuses. Either bound the value in the template row or make `/po-review` read the setting (a later story).
- **minor** — `method/commands/po-drive.md:16,50,71` — the grouped `AskUserQuestion` under `Plan validation: human` and the `status` argument state behaviour owned by s30 (`drive_groups_plan_approval_per_wave`) and s29 (`drive_status_reports_lanes`); no test of s27 covers either, and the D16 cell simultaneously announces grouped validation "en s30". Not an ownership breach (s27 owns the file too), but two promises in prose that nothing yet holds. Same cell also names a story id where its siblings name a milestone ("en M3").
- **minor** — repository root `AGENTS.local.md:9-27` — the three fleet settings exist in the template but not in this project's own settings file, which the installer never rewrites. `/po-drive`'s own check ("One of the settings above missing → stop and name it") means the command cannot run on Polype itself as shipped. Not the story's to fix (`Owns` excludes `AGENTS.local.md`, and its history shows it is only ever touched by framing commits): a human adds `Parallel: 3`, `Max attempts: 2`, `Tracker: none` to the Pipeline block before the first `/po-drive` run here.

## Not verified
- **That `/po-drive` drives anything.** Every check in this review, and every test in `tests/drive.test.sh`, reads markdown: they prove the command file states the readiness clauses, the single-message dispatch, the verbatim recording, the `Max attempts` cap and the serial ships. No wave was run — no parallel worktrees created, no `planner`/`implementer`/`reviewer` dispatched, no review transcribed by Bash, no squash merge. A person must run a real `/po-drive` on a project with two independent ready stories and check: both worktrees created before any subagent starts, the two lanes genuinely concurrent, `docs/reviews/<id>.md` byte-identical to the reviewer's answer, and the second ship waiting for the first.
- **`Tracker: github`**: declared as a value and explicitly deferred; no code path, no test, nothing to review.
- **`/po-drive` is not installed here.** `.claude/` and `.polype/` are untouched by design (run interdict), so the command is not invocable in this worktree; only `bin/polype-dev-install .` on `m3-flotte` after the ship makes it real. Worth one check then that the new command appears under `.claude/commands/`.
- **Unit suite and `bin/po-lint` were not rerun**; both come from `docs/verif/s27-drive.md`, whose `Tree:` matches the commit outside `docs/` (gate exit 0). Only `tests/drive.test.sh` was run here, for the five mutations.
- **No screen, no design artefacts** — this story ships markdown and one bash test file; `docs/design-system.md` and `docs/designs/s27-drive/` do not apply.
- **Typecheck, end-to-end, build, formatting**: the project declares none (`Typecheck: —`, `E2E: —`, `Build: —`, no formatter), so nothing is deferred to ship for them.

Max severity: major
Ship allowed: yes
