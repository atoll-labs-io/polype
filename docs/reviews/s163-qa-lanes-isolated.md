# Review — s163-qa-lanes-isolated

[Story](../stories.md) · [Plan](../plans/s163-qa-lanes-isolated.md) · [Verification](../verif/s163-qa-lanes-isolated.md)

Diff reviewed: `git diff main...story/s163-qa-lanes-isolated`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 48e57c7105ff9d26d2effe511faf6b1850ca112d

## Ownership
I listed the diff with `git diff --name-only main...story/s163-qa-lanes-isolated` and held each path against the story's `Owns` using the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`. `method/skills/qa-drivers/SKILL.md`, `method/agents/qa.md` and `tests/qa-lanes-isolated.oracle.test.sh` are listed there. `docs/research/`, `docs/plans/` and `docs/verif/` of this story are its pipeline evidence. `docs/decisions/ADR-0114-deux-qa-en-parallele-ne-partagent-ni-navigateur-ni-port.md` is added (status `A`) and the plan names it, so it is in scope too.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`. `git worktree list` shows only `main`, `framing/decisions-d1-d4` (a framing branch, not a story) and this lane.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s163-qa-lanes-isolated` passes (exit 0), so I reused the record. Its last `Unit suite` run (`bash tests/run.sh`) exited 0, on a tree whose code outside `docs/` equals `Tree:`. The earlier run that exited 1 came before it. `Typecheck: —`: the project has no type check. I read the record's "Not proven here" section: three criteria are case 3, and no live two-lane run was done.
- [x] `po-gate qa-current` is not required. The story does not go to QA (`QA stage: —`, `Surface: —`).

## Plan
- [x] Task 1 is present: `## Lanes side by side` has its four rules (Marker, Browser, Port, Deadline), and `## Outside the evidence` now points to the lane's `mktemp -d` directory. It keeps `mktemp -d` and the single-exception sentence.
- [x] Task 2 is present. `SKILL.md` went from 554 to 550 words. The cuts are the ones the plan names, in its order: the intro, the `web, mobile` example, the machine/project and fixed-path sentence, `## What each driver file says`, and that phrase in the frontmatter description. The pinned phrases are kept (table rows, `base directory`, `mktemp -d`, the whole `No row matches` line).
- [x] Task 3 is present. `qa.md:20` names "how lanes in QA together stay apart". Words were removed at `:20` ("they are not restated here") and `:22` ("whatever it is"). `qa.md` went from 1013 to 1012 words, and `:32` is unchanged.
- [x] Task 4 is present: the suite was run through `po-run`.
- [x] I checked each run interdict:
  - The name list matches the allowed set.
  - The driver files `browser/mobile-web/scenarios/scene/simulation.md`, `design-doctrine`, `po-drive.md`, `po-qa.md` and `method/hooks/` are untouched.
  - No existing test changed, and `.claude/` and `.polype/` are untouched.
  - The oracle sum holds (`po-gate oracle-intact` exit 0), and `## Oracle changes` is empty.
  - No phrase test was added.
  - Word caps: 550 ≤ 554 for `SKILL.md`, 1012 ≤ 1013 for `qa.md`.
  - `docs/parite-killer-saas.md` is untouched.
  - `tests/overlap.test.sh` is covered by the green full-suite record.

## References
- [x] Every reference was opened and confirmed:
  - `scenarios.md:14` holds the port pattern the plan reuses.
  - `browser.md:10` and `mobile-web.md:12` start `Dev` and read the printed origin. This agrees with "another port printed → blocked".
  - `qa.md:44/47/58` rely on the `mktemp -d` directory, which the skill still describes.
  - ADR-0026, ADR-0057 and ADR-0059 exist.
- [x] I evaluated the port expression in this worktree: `24052`. The 20000–29999 range sits below this machine's ephemeral range (32768–60999) and above the privileged ports. 120 s is the plan's choice, longer than the 60 s in `scenarios.md` to allow for cold compiles. Nothing confirms that it fits a large app, and the research says so.

## Rules
- [x] `AGENTS.md` conventions are respected: method files are in English, the ADR is in French, and there is no prose growth in `method/`.
- [x] No accepted ADR is contradicted.
  - ADR-0057 turned down reading driver files at a fixed `.claude/skills/` path. The deleted sentence restated that refusal in negative form. The positive rule (read from the announced base directory) is still at `SKILL.md:26`, so the decision holds.
  - ADR-0026 still holds: the QA inherits the session's tools, as ADR-0114 says.

## Tests
- [x] Floor: `po-gate floor-guard s163-qa-lanes-isolated main` → exit 0, nothing lowered.
- [x] The one oracle test reads `wc -w`, which is what `no_file_grows` fixes. It is none of the six empty test shapes. The other three criteria are case 3 by the owner's rule of 2026-11-13: they are judged by reading, below.
- [x] Budget: 1 of 25 tests.
- [x] Bite, run twice and undone each time, with `git diff --exit-code` clean:
  - 10 words appended to `SKILL.md` → 1 failing test (`no_file_grows`, "560 words, 554 before").
  - 8 words appended to `qa.md` → 1 failing test ("1020 words, 1013 before").
- [x] No test is made useless by the story.

## Neighbours
- [x] I read the other callers of the changed text: the five driver files, `qa.md`, `templates/qa.md`, `templates/profile.md`, `bin/po-lint` (driver file names only) and `po-drive.md:101-107`. Nothing is broken.
  - `design-doctrine:40` still says "a browser shared with the session". That file is outside `Owns`, the research names it, and the new rule is read before the driver files.
- [x] Readers of the removed text. Nothing in `method/`, `bin/` or the tests refers to "What each driver file says" or to the fixed-path sentence.
  - The `qa` agent never used the driver-file list at runtime: each driver file carries its own Needs / Start and stop / Exercising / Evidence / Cannot show sections.
  - The intro and the `web, mobile` example lose nothing: the routing rule still says "in table order, each one run in full".

## Lenses
Lenses run: none. There are no auth, route, migration, lockfile or server-side paths, and no such content: the diff is method prose and one bash test.
- [x] No lens findings.

## Findings
- major — method/skills/qa-drivers/SKILL.md:32 — `a_stuck_driver_ends_blocked` is only partly met. The deadline binds "Bash or the lane's script" only. A lane alone in QA without a browser-automation package still drives the session's browser tool, and a hung call there still holds the QA without end. That hung call is exactly the `browser_resize` case of #149. ADR-0114 accepts this as a "Bad" consequence and the plan's pivot foresaw it, but the story's criterion ("une action du pilote qui ne répond pas … finit la QA en `QA status: blocked`") was not narrowed to match. Either the criterion is reworded by a person, or a follow-up story bounds the fallback path. The gap is contained: two lanes no longer share that browser.
- major — method/skills/qa-drivers/SKILL.md:32 — "Each start … gets 120 seconds: `timeout 120`". Read literally, this wraps the `Dev` start in `timeout 120`, and `timeout` kills that long-running server after two minutes, in the middle of the walk. The plan meant a deadline on the start answering, not on the server's life. `scenarios.md:14` has the right shape: start in the background, then wait until it answers, and block past the limit. A lane that follows the text as written loses its server mid-walk. That ends in failed actions and `blocked`, not silent damage.
- minor — method/skills/qa-drivers/SKILL.md:30 — The Browser rule leaves two cases open.
    - The package is present but its browser binaries are not. Playwright downloads them separately, and the rule says "installing nothing". It does not say whether this case falls to "Without one" or ends `blocked`.
    - A script placed in the `${TMPDIR}` lane directory cannot resolve the project's package by a bare `require`/`import` without `NODE_PATH` or an absolute path.
  A capable model works around both, but nothing in the text says so.
- minor — method/skills/qa-drivers/SKILL.md:26-28 and frontmatter `description` — Removing `## What each driver file says` costs no runtime reader. But the five-part contract a new driver file follows (needs, start/stop, exercising a criterion, evidence and file names, what it cannot show) is now implicit, only learnt by imitating the existing drivers. That matters for the next story that adds a driver.

## Not verified
- No live run of two QA lanes on a `screen` project. Neither the private browser, the marker, nor a pre-occupied port ending `blocked` was exercised, because this repository has `Platform: cli`. A person should run two `screen` stories of one wave through `/po-drive` on a web project, with and without a browser-automation package, or build the `po-eval` control arm (#208) the plan names for all three case-3 criteria.
- Whether subagents of one session share `TMPDIR`, and so see each other's marker. This is an open question in the research, not checked here. If each has its own sandbox, a lane without a package would wrongly use the shared browser. Check it by having two concurrent `qa` subagents print `${TMPDIR:-/tmp}` and list `polype-qa-*`.
- Whether a `Dev` command honours both `PORT` and a port option (for example `npm run dev -- --port`). This depends on each project. Check it on the first web project that goes through QA after this ship.
- The model's actual reading of the four rules. These criteria are case 3 and were judged by reading only.

Max severity: major
Ship allowed: yes
