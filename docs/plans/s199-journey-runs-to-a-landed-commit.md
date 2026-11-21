---
validated: yes
---
# Plan — s199-journey-runs-to-a-landed-commit

[Story](../stories.md) · [Research](../research/s199-journey-runs-to-a-landed-commit.md)

Branch `story/s199-journey-runs-to-a-landed-commit`. Read `docs/research/s199-journey-runs-to-a-landed-commit.md` first; this plan builds on it without repeating it.

## Story
A bash journey walks throwaway stories from `po next`'s `plan` to `<id>: <title>` on `Target branch` with no model. It applies one written answer per action and crosses the real gates and the five `po ship` sub-steps. It runs inside `tests/run.sh` with doubles only. The six criteria are each read by a script (the journey and `po`), so each gets an oracle test. `docs/harnais.md` is prose for people: no test. Nothing outside `Owns` changes. `po/` does not change, so no version moves.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Install of the throwaway project | `bin/polype install <dir> --hooks` (already here) | — it is the first rung. |
| Settings of the throwaway project | the fenced lines of `method/templates/agents-local.md`, extracted as `tests/lib.sh:33-35` does, then overridden | — first rung; a hand-written list would drift from the template. |
| Forge double `gh` | new file `tests/journey/doubles/gh`, adapted from the heredoc at `tests/ship-lands-through-a-pull-request.oracle.test.sh:110-176` | That double sits inside another story's oracle: sourcing it would pull that story's `test_` functions into this file. It also lacks `issue list`, the POST to `/issues` and the log of unexpected calls. |
| Remote | `insteadOf` to a local bare repository, as `tests/ship-lands-through-a-pull-request.oracle.test.sh:62-66` does | — first rung. |
| Journey engine `tests/journey/journey.sh` | new code | The fixtures of `tests/driver-next-action.oracle.test.sh:24-208` write each stage's files by hand, which is exactly what this story must not do. `/po-drive` is prose. No script yet follows `po next`. |
| JSON reading | `jq`, already required by the suite | — |
| Folder cleanup | `mktemp -d` and bash `trap` | `scratch_repo` (`tests/lib.sh:47-54`) traps EXIT only, and a TERM skips it. `tests/lib.sh` stays unchanged. |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/journey-runs-to-a-landed-commit.oracle.test.sh` | `4050906073 11578` |

| Criterion | Test |
| --- | --- |
| `journey_follows_po_next` | `test_journey_follows_po_next` |
| `story_lands_on_the_full_track` | `test_story_lands_on_the_full_track` |
| `story_lands_through_a_pull_request` | `test_story_lands_through_a_pull_request` |
| `two_lanes_ship_in_order` | `test_two_lanes_ship_in_order` |
| `real_gates_are_crossed` | `test_real_gates_are_crossed` |
| `journey_runs_in_the_suite` | `test_journey_runs_in_the_suite` |

## The interface the oracle fixes
`tests/journey/journey.sh` is sourced after `tests/lib.sh`. It only defines functions: no trap, no folder and no command run at source time. Every function works under `set -eu`.

**Variables.**
- `J`: the journey folder, a physical path.
- `JOURNEY_LOG` (`$J/journey.log`).
- `R` (`$J/project`).
- `ORIGIN` (`$J/origin.git`, pr only).
- `JOURNEY_MAX_WAVES`, default 20, read by `journey_run`.

**Functions.**
- `journey_init`: `J="$(mktemp -d "${TMPDIR:-/tmp}/polype-journey.XXXXXX")"` resolved with `pwd -P`. Traps: EXIT removes `$J`; HUP, INT and TERM exit 129, 130 and 143. It copies the doubles into `$J/bin`. It exports:
  - `PATH="$J/bin:$PATH"`, `HOME=$J/home`, `TMPDIR=$J/tmp`, `CLAUDE_CONFIG_DIR=$J/claude`;
  - `PO_GH`, `PO_CURL`, `PO_GLAB` and `PO_TEA` set to `$J/bin/<tool>`;
  - `PO_SHIP_POLL_SECONDS=0`, `GIT_ALLOW_PROTOCOL=file`, `LC_ALL=C`, and a variable the doubles use to find `$J`.

  It unsets `GH_TOKEN` and `GITHUB_TOKEN`.
- `journey_project <local|pr>`: builds `$R`. It runs `git init -b main` with a local user and `commit.gpgsign false`. It copies `tests/journey/project/`, writes `AGENTS.local.md` (Task 4) and runs `bash "$ROOT/bin/polype" install "$R" --hooks`, which calls the `cargo` double. It commits on main. Under `pr`, it also:
  - creates a bare repository `$ORIGIN`;
  - sets `remote.origin.url` to `https://github.com/acme/project.git` and `url.$ORIGIN.insteadOf` to the same URL;
  - pushes main;
  - installs an `update` hook that appends `$1` to the push log.
- `journey_story <id> <title> [<answers dir>]`: appends to `docs/stories.md` on main a block with `### <id> — <title>`, `**Complexité** : 3`, `**Surface** : command` and `**Owns** : \`src/<id>.txt\`, \`checks/<id>.check\``. It commits, pushes under pr, and binds the answers (default `tests/journey/answers/plain`).
- `journey_answers <id> <dir>`: binds the answers alone. It works before any project exists.
- `journey_snapshot` and `journey_restore`: save `$R` (and `$ORIGIN`), then put them back. Restoring also empties the log and the call logs.
- `journey_run`: empties `$JOURNEY_LOG`, then runs the loop in a subshell. Each po next entry it meets logs `entry<TAB><wave><TAB><story><TAB><action><TAB><reason><TAB><track or ->`. A stop logs `stopped<TAB><message>` and returns 1. When `po next` lists no action, it audits the doubles, logs `done<TAB><wave>` and returns 0. `$R` is read only through `journey_po_next` and the answers, so a run with `journey_po_next` overridden needs no project.
- `journey_audit`: prints one line `unexpected call to <tool>: <args>` per call outside the expected list, and returns 1 when there is any.
- `journey_calls <tool>`: prints that double's calls, one line per call, with the arguments joined by spaces.
- `journey_pushed`: prints the refs that origin's hook logged.

  Both always return 0.
- Overridable steps: `journey_po_next` (prints `"$PO" next` run from `$R`), `journey_validate_line <id>`, `journey_po_run <id>`, `journey_record_review <id> <file>`.
- Exact stop messages:
  - `no written answer for <action> of <id>`;
  - `<id>: po next answers <action> (<reason>) again after its answer: stopped at that gate`;
  - `the pre-commit accepted a code commit on story/<id> before its plan was approved`;
  - `more than <N> waves`;
  - `ask for <id>: <reason>`;
  - `po next warns: <warnings>`;
  - `po next failed: <output>`;
  - `nothing moves`;
  - the audit's lines.

## Tasks
1. [x] **Throwaway project and written answers.**
   - `tests/journey/project/` holds:
     - `checks/run.sh`, which runs every `checks/*.check` and fails on the first failure;
     - `docs/architecture.md` and `docs/design-system.md`, one line each;
     - `docs/reviews/stories.md`, holding `Stories ready: yes`;
     - `docs/stories.md`, holding `# Stories` then `## M1 — Parcours`.
   - `tests/journey/answers/plain/` holds, with the placeholders `@ID@`, `@TITLE@` and `@TREE@`:
     - `research.md`;
     - `plan.md`, frontmatter `validated: no`, `## Acceptance tests` holding `—` with its reason, and two tasks;
     - `validate-plan`, holding `Approve`;
     - `code.patch`: a git patch that creates `src/@ID@.txt` and `checks/@ID@.check`, the check holding `grep -qx` on the text;
     - `record.md`, in the shape of `templates/verification-record.md`: `Tree: @TREE@`, a `Unit suite` row holding `` `sh checks/run.sh` ``, a `Type check` row holding `—` with its reason, and `Verification status: complete`;
     - `review.md`, in the shape of `templates/review.md` below its header: `Review status: complete`, `Fix loop: 0`, `Reviewed tree: @TREE@`, **exactly one** finding `- minor — src/@ID@.txt:1 — …`, `Max severity: minor` and `Ship allowed: yes`;
     - `pr-body.md`.
   - Test: `test_story_lands_on_the_full_track` and `test_story_lands_through_a_pull_request` (one issue filed).
2. [x] **Doubles** in `tests/journey/doubles/`.
   - `gh` logs every call as `$*` in `$J/calls/gh`. It keeps the pull requests under `$J`. It answers the calls the research lists:
     - `auth status`;
     - `api -i` GETs, answering the forge as solo: the login `me`, one collaborator `me`, protection `404`, rules `[]`;
     - `pr list`, `pr view`, `pr create`, `pr checks` (one passing check), `pr merge` (a rebase made by the forge with `commit-tree` onto origin's main, bound to `--match-head-commit`);
     - `issue list` (`[]`) and the POST to `repos/acme/project/issues` (an `html_url`).

     Any other call is logged to `$J/calls/unexpected` and exits 1.
   - `cargo` logs to `$J/calls/cargo` and exits 1. It is expected, but only from the installer.
   - One `unexpected` script, copied as `curl`, `glab`, `tea`, `task` and `claude`, logs every call as unexpected and exits 1.
   - Test: `test_journey_runs_in_the_suite`.
3. [x] **`journey.sh`: environment, audit, logs.** `journey_init`, `journey_audit`, `journey_calls` and `journey_pushed`, as the interface says. Test: `test_journey_runs_in_the_suite`; folders: test 3 of Task 6.
4. [x] **`journey.sh`: projects and stories.**
   - `journey_project` writes `AGENTS.local.md` as the template's fenced lines with these values:
     - `Merge mode: local|pr`, `Plan validation: human`, `Ship confirmation: automatic`;
     - `Full suite: execute-end`, `E2E stage: —`, `Build stage: —`, `QA stage: —`;
     - `Issue tracker: —` under local and `github` under pr;
     - `Story track: auto`, `Flow threshold: 2`, `Forge checks: required`;
     - `Private folder: $J/private/` and `Test: sh checks/run.sh`.
   - It installs once per project.
   - `journey_story`, `journey_answers`, `journey_snapshot` and `journey_restore`.
   - Test: every oracle test builds through them.
5. [x] **`journey.sh`: the loop and the answers** (`method/commands/po-drive.md`'s order, `po-ship.md` Steps 0-3).
   - **Each wave.** Run `journey_po_next`.
     - An exit other than 0, or `.contract != 1` → `po next failed`.
     - A non-empty `warnings` → stop.
     - An empty `actions` → audit, then done.
   - **Each entry, in its listed order.** Log it. Then:
     - `wait`: nothing is done.
     - `ask`: stop.
     - Anything else: check the repeat guard on the story's last applied `(action, reason)` first, then apply the action's answer. A missing answer file stops the run, naming it.
     - A wave where nothing was applied → `nothing moves`.
     - Past `JOURNEY_MAX_WAVES` → stop.
   - **The answers, by action.**
     - `plan` (`ready`): open the lane by `po-research.md`'s steps. Under pr that means a `git fetch` and the start point `origin/main`. Then write `research.md` (full track) and `plan.md`.
     - `validate-plan`: first the pre-commit probe. Commit a staged `journey-probe.txt`: if the commit is accepted, stop; once it is refused, reset and remove the file. Then `journey_validate_line` turns `validated: no` into `validated: yes`.
     - `execute`: `git apply` the patch, then `git add -A` and `git write-tree` → the record's `Tree:`. Then `journey_po_run`, which runs `.polype/hooks/po-run.sh --story <id> --label 'Unit suite' -- '<Test>'`. Last, one commit `<id>: <title>` through the hook.
     - `review`: put `git rev-parse 'story/<id>^{tree}'` in `@TREE@`. Wait until the second differs from the previous review's. Then `journey_record_review` pipes the answer into `"$PO" record review <id>` from the lane.
     - `ship` (`ship-allowed passes`): `po ship forge`, and its `effective` must be `automatic`.
       - Under local: `po ship land <id> --land` must give `landed: true`.
       - Under pr: `po ship land <id>`, then write the body into a `mktemp -d` under `$J/tmp`, then `po ship push … --body-file` must give `merged`.
     - `ship` (`landed`, or once landed): `po ship file <id>`, then `--file` must give `filed` or `no-tracker`. Then `po ship clean <id>` from `$R` must give `cleaned`.
   - Every `po` reply that is not the one awaited stops the run, quoting `error` and `message`.
   - Test: the six oracle tests.
6. [x] **`tests/journey-runs-to-a-landed-commit.test.sh`**, for the journey's own guards:
   - `test_canned_po_next_stops`, with `journey_po_next` overridden in subshells and no project:
     - an `ask` → `ask for s01-greeting: Max attempts reached`;
     - a warning → `po next warns:`;
     - an exit 2 → `po next failed`;
     - only `wait` → `nothing moves`;
     - an override that calls `gh repo view` before answering no action → the run fails with `unexpected call to gh: repo view`.
   - `test_wave_cap_stops_the_journey`: with `JOURNEY_MAX_WAVES=2` on a local project, the run logs `more than 2 waves` and lands nothing.
   - `test_folders_go_on_failure_and_interrupt`: a child `bash -c` runs with `TMPDIR` set to a folder the test owns, under `setsid`.
     - A run stopped on an `ask` leaves no `polype-journey.*`.
     - A run blocked in `journey_po_next() { sleep 30; }` gets TERM on its process group. It exits 143 within 5 s, and the folder is gone.
7. [x] **`docs/harnais.md`**: add `## Le parcours rejoué`, about ten lines in French.
   - What it proves: `po next` followed step by step; `plan-validated`, `verif-current` and `ship-allowed` crossed; the pre-commit active; `po-run` and `po record` run; `po ship forge|land|push|file|clean`; ships in review order; no network.
   - What it does not prove:
     - that a model follows the prose (s206);
     - design, QA and the stops (s200);
     - that a forged step would be refused: gates are file checks (research, first fact);
     - that the forge double behaves like GitHub.
   - How to run it, and the folder a SIGKILL leaves behind.
   - No test.
8. [x] **Measure.** Run `bash tests/run.sh journey-runs-to-a-landed-commit.oracle.test.sh journey-runs-to-a-landed-commit.test.sh` and write its duration under "Not proven here" of the record. Then run the full suite through `po-run`.

## Scene viewpoints
—

## Run interdicts
- `git diff main...story/s199-journey-runs-to-a-landed-commit -- po/ method/ bin/ .claude/ .polype/ tests/lib.sh evals/` is empty.
- The oracle file keeps `4050906073 11578`; any change goes through `## Oracle changes` of the record.
- No test file other than the two of this story. No new `*.test.sh` under `tests/journey/`.
- `journey.sh` and the doubles write only under `$J`. `$ROOT` is only read: `bin/polype`, the template, `tests/journey/`.
- No journey runs against this repository, a worktree, its remote, a real forge or a real tracker. No call to `cargo` outside the installer's own (to the double). No sleep longer than one second.

## The pivot
"Removing a step" means **not running it**. The gates are file checks, so a step that does not run leaves its file missing or incomplete: `po next` names the same action again, and the repeat guard stops there. This could be wrong in three ways:
- **A step replaced by a forgery goes through** (a review written without `po record`, run rows written by hand). Compare `po-gate.sh:77-96` and `:150-208`. The journey proves the stamp only through `po state`'s `trust.method_version` (`shipped` in the oracle), and `docs/harnais.md` says so. Whether a gate should read it is for the lead to file, not for this story.
- **The ship-order test depends on the order lanes are applied in** (by id, since `git worktree list` sorts by path) **and on whole seconds** (`lane.rs:260`). If `po next` stopped sorting by path, or wrote reviews faster than a second apart without the wait, the test could stop telling "review order" from "rank". Compare with the `recorded_at` assertion.
- **Cost.** In the probe, an install took 0.45 s, `po next` 14 ms, and a local journey under 3 s. The estimate is 30 s at most for both files: 7 installs and about 40 waves. Above 90 s at Task 8, stop and report rather than cut tests.

## Files touched
- `tests/journey/journey.sh`
- `tests/journey/doubles/{gh,cargo,unexpected}`
- `tests/journey/project/…`
- `tests/journey/answers/plain/…`
- `tests/journey-runs-to-a-landed-commit.oracle.test.sh` (written, sum above)
- `tests/journey-runs-to-a-landed-commit.test.sh`
- `docs/harnais.md`
- `docs/research/`, `docs/plans/` and `docs/verif/` of the story

## Test strategy
- **Automated: 9 tests**, within `Test budget` 25: the 6 of the oracle and 3 for the guards (Task 6). They are end-to-end by nature: real `po`, real hooks, real git, with only the forge, `cargo`, the tracker and any model doubled. A double here stands for an outside tool, never for a script of this project.
- **Each guard and the test that fails without it:**
  - missing answer: `journey_follows_po_next`;
  - repeat guard and pre-commit probe: `real_gates_are_crossed`, four mutants;
  - audit, protocol rule and token removal: `journey_runs_in_the_suite`;
  - wave cap: `wave_cap`;
  - `ask`, warnings, unreadable `po next`, "nothing moves" and the audit inside a run: `canned_po_next_stops`;
  - cleanup on failure and interrupt: `folders_go_on_failure_and_interrupt`;
  - the wait between two reviews: `two_lanes_ship_in_order`. Without the wait, the two stamps tie and the rank wins, so s02 lands first.

  A reply check inside an answer (for example `push` not giving `merged`) only sharpens a message: without it, the repeat guard still stops the run.
- **Costs.**
  - Builds: none. `po` comes from `tests/run.sh`, and the installer's `cargo build` meets the double.
  - Installs: 7, one per test that builds a project. `real_gates_are_crossed` installs once and restores its copy three times.
  - Time: about 30 s, measured at Task 8.
  - On failure or interrupt: nothing is left. Everything sits under one `polype-journey.XXXXXX`, removed on EXIT, HUP, INT and TERM. A SIGKILL alone leaves that folder, about 2 MB, findable by its name.
- **Visual checks:** none.

## Done when
- The two files pass in `tests/run.sh`, and the full suite passes through `po-run` (Task 8).
- A review with no open critical finding.
- One commit landed through a pull request whose description says what the journey proves and does not prove.
