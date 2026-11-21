# Review — s199-journey-runs-to-a-landed-commit

[Story](../stories.md) · [Plan](../plans/s199-journey-runs-to-a-landed-commit.md) · [Verification](../verif/s199-journey-runs-to-a-landed-commit.md)

Method version: 0.11.0
Recorded: 2026-11-21T03:01:01+01:00

Review status: complete
Fix loop: 0
Reviewed tree: e917795646b5a35efe86e1c257f9d9bfd0a33ce8
Lenses run: none (the diff only touches tests, fixtures and French docs: no auth, migration, lockfile or server-side path or content)

## Scope
Diff paths (`git diff --name-status main...story/s199-journey-runs-to-a-landed-commit`): `docs/harnais.md`, `tests/journey/**`, `tests/journey-runs-to-a-landed-commit.oracle.test.sh`, `tests/journey-runs-to-a-landed-commit.test.sh`, plus the story's own research, plan and record. Every path is inside the `Owns` line of s199 (`docs/stories.md:3248`) or is the story's own evidence. Nothing under `po/`, `method/`, `bin/`, `.claude/`, `.polype/`, `tests/lib.sh` or `evals/`, so the plan's run interdict holds. No other lane is running: `git worktree list` shows only `main`, `fix/qa-deadline-wording` and this story.

## Evidence relied on
- `po-gate verif-current` exits 0. The record at `docs/verif/s199-journey-runs-to-a-landed-commit.md` has one `Unit suite` row (`bash tests/run.sh`) that exited 0 (946 passed, 464 s). Under `Verification mode: record` I did not run the full suite again. Typecheck, E2E and Build are `—`: this project has none of them.
- `po-gate oracle-intact` exits 0 and `po-gate floor-guard … main` exits 0.
- I ran the story's two files myself: 9 passed in 8.6 s. Afterwards there was no `polype-journey.*` under /tmp, nothing new under /tmp, the worktree was clean, and main and the worktree list were unchanged.

## Gates: which real script writes what the next gate reads
I traced a pr journey and read its call log.
- **Plan validation line**: `journey_validate_line` uses awk to turn `validated: no` into `validated: yes` after the `Approve` answer (`journey.sh:127-132`). In the method a model writes this line (`method/commands/po-plan.md:42`), and no script does. The awk is the correct stand-in, not a bypass.
- **Pre-commit**: `bin/polype install --hooks` installs the real one, and the oracle asserts `core.hooksPath=.polype/hooks`. A probe commit has to be refused before validation (`journey.sh:203-208`). The code commit goes through the hook: there is no `--no-verify` and no hooksPath change anywhere in the journey.
- **`po-run` rows**: written by `.polype/hooks/po-run.sh` (`journey.sh:134-138`). The `record.md` answer holds the header, `Tree:` and `Verification status: complete`, which is the implementer's part. Its `## Runs` table is empty, so the answer contains no forged row.
- **Review**: written by `"$PO" record review` reading stdin. The `review.md` answer has no `Recorded:` or `Method version:` line, so it contains nothing that only `po record` may write.
- **Ship**: the real `po ship forge`, `land`, `push`, `file` and `clean` run in that order. Logged gh calls: `auth status`, the four forge GETs, `pr list`, `pr create --base main --head story/s01-greeting`, `pr view headRefOid`, `pr checks`, `pr merge --rebase --match-head-commit`, `pr view state`, `issue list`, and `POST repos/acme/project/issues`.
- **`po next`**: the journey never answers it except in the guard tests, which override `journey_po_next` on purpose.
- **Variables**: `PO_SHIP_POLL_SECONDS=0` only shortens polling (`push.rs:432`). No variable makes a gate lenient, and the hooks do not call `po`.

## Tests
- Oracle: `po-gate oracle-intact s199-journey-runs-to-a-landed-commit` → exit 0
- **The four oracle mutants** (pre-commit, validation line, `po-run`, `po record`) are part of `real_gates_are_crossed`, which passes.
- **Bite 1, repeat guard** (`journey.sh:295`, condition forced true): 1 test failed (`real_gates_are_crossed`). This guard is what turns "a step not run" into a stop at its gate.
- **Bite 2, wait between reviews removed** (`journey.sh:229`): `two_lanes_ship_in_order` failed in 3 runs out of 3.
- **Bite 3, push-log switch removed** (`update` hook logs every push): `story_lands_through_a_pull_request` failed with "a push sent another ref than the story branch: refs/heads/main". So the assertion does catch a push of `Target branch`.
- Each mutation was undone, and `git diff --exit-code` passed after each.
- **JOURNEY_SETUP**: only setup pushes set it, as a one-command prefix, never exported. A push made by `po` carries it only if the caller's own environment exports it. I tested that case: the pr test then *fails* ("no push of story/s01-greeting reached origin"), so a leak gives a false failure, never a false pass. The forge double's merge uses `update-ref`, which is not a push and is rightly not logged. The claim "no call sends `Target branch`" holds for every push that changes a ref.
- **Pivot in `docs/harnais.md`**: stated plainly and true. Removing a step leaves its file missing, `po next` repeats the action, and the repeat guard stops there. A forged file would pass, because the gates read files, not who wrote them.
- **two_lanes**: it cannot flake. The second review waits for a later second than the one taken after the first `po record` returned, so the stamps are strictly ordered. On passing for the wrong reason, see the last finding.
- 9 tests, within the budget of 25.
- **Cleanup**: `rm -rf` only ever targets `$J`, which comes from `mktemp -d` and is resolved before the EXIT trap is set, or paths under it. All `cd` and `git -C` calls name `$R`, `$ORIGIN` or the lane under `$R`. `GIT_CONFIG_GLOBAL=/dev/null` from `tests/lib.sh` keeps the user's `insteadOf` and credential helpers out.
- **Network**: `GIT_ALLOW_PROTOCOL=file` is set. `GH_TOKEN` and `GITHUB_TOKEN` are unset, and these are the only tokens `po` reads (`forge.rs:161`). `curl`, `glab`, `tea`, `task` and `claude` resolve to the failing double. Every other external program `po` launches is `bash`, `git`, `kill` or `task`.

## Findings
- minor — tests/journey/journey.sh:30 — `journey_init` clears the forge tokens but leaves `JOURNEY_SETUP` and git's location variables (`GIT_DIR`, `GIT_WORK_TREE`, `GIT_INDEX_FILE`) as inherited. A `JOURNEY_SETUP` exported by the caller silently turns the pr test red (verified). A `GIT_DIR` exported by the caller, for example a suite launched from a git hook of this repository, would point the journey's `git -C "$R" commit`, `worktree add` and `push` at the repository it names. Nothing in the project runs the suite that way today. Unsetting these variables in `journey_init` closes both cases.
- minor — tests/journey/journey.sh:205 — the pre-commit probe counts any refusal as the plan gate and discards the hook's message. It holds today, because the only other refusals of `pre_commit` (secret scan, CLAUDE.md) cannot fire on an empty `journey-probe.txt`. Reading for "before its plan is approved" would keep it true if the hook ever gains another refusal.
- minor — tests/journey/doubles/gh:34-58 — the forge double ignores `--repo` on the `pr` subcommands, and `pr merge` rebases onto origin's `main` whatever `baseRefName` the pull request holds. A `po` that addressed the wrong repository, or merged a pull request with a wrong base, would still land. The oracle checks `--base main --head story/<id>` only on `pr create`.
- minor — tests/journey-runs-to-a-landed-commit.oracle.test.sh:123-135 — in `two_lanes_ship_in_order`, review order is the same as id order: lanes are applied by worktree path, so s01 is always reviewed first. The test separates "review order" from "rank in docs/stories.md", but not from "story id". `po next` orders by (`reviewed_at`, rank, id) (`po/src/next/lane.rs:224`), so dropping both of the first two keys would still pass. The oracle is intact; this is a limit of what it can tell apart.

## Not verified
- **The full suite**: I relied on the record (946 passed on tree 8a78bac…, matched by `verif-current`). Covering it means running `bash tests/run.sh` once more if in doubt.
- **The TERM trap**: the implementer's note says bash 5.3 runs the EXIT trap and exits 143 by itself on a TERM, so the test passes with or without the trap. The HUP and INT traps have no test. I checked the cleanup on an `ask` stop and on a TERM by running `folders_go_on_failure_and_interrupt`, not by a separate kill. Covering it means a person sends INT or HUP to a running journey and checks `find /tmp -maxdepth 1 -name 'polype-journey.*'`.
- **SIGKILL**: it leaves its `polype-journey.*` folder, which is the documented limit. Not exercised.
- **Fidelity of the gh double against a real GitHub**: header format of `api -i`, real exit codes of `pr checks` while checks are pending, the real rebase-merge result. The double is only checked against what `po ship` asks of it. Covering it is s206 territory, or a manual `po ship` on a scratch GitHub repository.
- **The `ship` answer with reason `landed`** (an interrupted ship resumed) is never reached by any test.
- **macOS**: the tests use `setsid -w` and `date -d`, which are GNU-only. CI runs on `ubuntu-latest`, and other tests already use them.
- **A run with `GIT_DIR` exported**: I did not try it, because it would aim at this repository. The first finding is a reading of the code.
- **No QA**: `QA stage: —`, so this story has no QA and no QA report.

Max severity: minor
Ship allowed: yes
