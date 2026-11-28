# Review — s218-next-sees-a-human-merge

[Story](../stories.md) · [Plan](../plans/s218-next-sees-a-human-merge.md) · [Verification](../verif/s218-next-sees-a-human-merge.md)

Method version: 0.13.0
Recorded: 2026-11-28T12:32:05+01:00

Diff reviewed: `git diff main...story/s218-next-sees-a-human-merge`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 08eed6a3390c54eb254896e6946e4df9968a40f9

## When blocked
- Failure cause: —
- Missing: —
- Required adaptation: —
- Next action: —

## Ownership
Diff listed with `git diff --name-only main...story/s218-next-sees-a-human-merge`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`. The paths are `bin/polype`, `po/Cargo.lock`, `po/Cargo.toml`, `po/src/context/lanes.rs`, `po/src/context/mod.rs`, `po/src/next/mod.rs`, `po/src/project.rs`, `po/src/ship/git.rs`, `po/src/ship/mod.rs`, `tests/next-sees-a-human-merge.oracle.test.sh` and `tests/next-sees-a-human-merge.test.sh`, plus the story's own research, plan and verif. `docs/decisions/ADR-0141-po-next-remote-recupere-origin-avant-de-lire.md` has status `A` and the plan names it, so it is in scope by construction.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. The only other worktree is `s219-suite-bounds-and-cleans`, whose `Owns` (seven `tests/*` files) does not overlap this diff.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s218-next-sees-a-human-merge` exited 0, so the record is reused. `Verification mode: record`, status complete, Unit suite `bash tests/run.sh` exited 0 (821 s). `Typecheck: —`: the project has no type-check command, and the cargo build inside `tests/run.sh` compiles the Rust. I read its "Not proven here" section.
- [x] `po-gate qa-current`: not required. `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1 to 6 are all present: fetch under `--remote` with `Merge mode: pr` and an `origin`, before `Context::read`; `awaits_merge` split out plus `confirm_merges`; the effective value read only when some lane awaits a merge; the two tests of the story itself; the version raised to 0.13.2 in all three places; the full suite run once. Nothing outside the plan.
- [x] Run interdicts, checked one by one:
  - `docs/interface-agent.md`, `method/commands/po-drive.md`, `method/word-budget`, `tests/ship-order-and-closed-pr*`, `tests/driver-next-action.oracle.test.sh`, `tests/fixtures/driver-cases/`: no diff.
  - `po/src/state/`, `po/src/run/`: no diff. In `project.rs` only the doc comment changed; the body of `git()` is unchanged.
  - JSON of `po next`: same shape. `Lane` is not serialised, and nothing new reaches `Next`/`Entry`.
  - `"fetch"` appears in `po/src/` only under `po/src/ship/` (`git.rs:33`, `land.rs:309`, `clean.rs:128`).
  - `PO_SUMS`: unchanged.

## References
- [x] Every call opened and confirmed:
  - `ship::git::run` / `Ran::ok` (`po/src/ship/git.rs:18-28`)
  - `ship::effective` (`po/src/ship/mod.rs:46`), which strips `(chosen)`/`(forge)`
  - `forge::read(...).verdict()`
  - `Context.target` / `Context.project` (`po/src/context/mod.rs:109,182`)
  - `Setting::Value`
  - `project.git(["remote","get-url","origin"])`, used the same way in `po/src/next/open.rs:40`
- [x] Values: `effective` gets the raw line, as `po ship forge` passes it (`po/src/ship/mod.rs:118-127`). An unreadable forge gives back the line's own value, so the offline reading holds. The fetch ignores its result, so a failure falls back to the local refs.

## Rules
- [x] `AGENTS.md` conventions respected: comments in English, version raised (ADR-0122), no new dependency.
- [x] No accepted ADR contradicted. ADR-0141 is `accepted` (owner decision d-0064) and the plan no longer holds a `Technical choice` line. ADR-0131 still holds: the landing proof is still the title on `origin/<target>`. On the unlinked amendment of ADR-0130, see Findings.

## Tests
- Oracle: `po-gate oracle-intact s218-next-sees-a-human-merge` → exit 0
- [x] Floor: `po-gate floor-guard s218-next-sees-a-human-merge main` exited 0, so nothing was lowered. `po-gate oracle-intact` exited 0 and the record lists no oracle changes.
- [x] Assertions pin the criteria. I checked for the six empty shapes and found none. The forge doubles answer per API path, origin is a real bare repository behind `insteadOf`, and the person's merge is a real squash push from another clone.
- [x] 5 tests, within `Test budget` 25.
- [x] Bite (each change undone with `git checkout -- <file>`, then `git diff --exit-code` clean; I reran only the story's two test files):
  - fetch disabled in `next::main` (`if remote && false`): 1 failing (`human_merge_is_seen`).
  - `lanes::confirm_merges` turned into a no-op (filter never matches): 1 failing (`effective_confirmation_drives_merge_waiting`).
  - The `awaits` guard in `next::confirm_merges` forced to `true`, together with the `blocked_by` reset removed from `lanes::confirm_merges`: 2 failing. The guard mutation broke `forge_read_only_when_a_merge_waits` (gh `auth status` called). The stale `blocked_by` broke `effective_confirmation_drives_merge_waiting` (`ship` instead of `wait`).
  - After the last undo, the two files ran green again on the committed code: 5 passed.
- [x] No test made useless.

## Neighbours
- [x] Readers of `blocked_by` and `stops` checked:
  - `lane::ship` (`po/src/next/lane.rs:211`) and the serial order (`:218`) read `blocked_by`, which `confirm_merges` keeps equal to `stops.first()`.
  - `po state` and `po run` also call `Context::read` but never `confirm_merges`, so they keep the written line (see Findings).
  - `stops` has a single caller (`lanes()`).
  - `Lane` is built only in `lanes.rs`.

## Lenses
Lenses run: dependencies (path `po/Cargo.lock`). The lockfile only bumps the version of the crate `po` itself; no dependency entry was added, removed or bumped. No finding.
- [x] No lens finding.

## Findings
- major — docs/interface-agent.md:271 — The contract row for `next`, `next --remote` still says nothing about the `git fetch -q origin` that `po next --remote` now runs under `Merge mode: pr`. It also does not say that `merge waiting` now follows the effective `Ship confirmation` read from the forge.
  An external agent reading the contract now meets a read verb that writes `refs/remotes/origin/*`, and the contract does not say so. ADR-0141's consequences require this row to say it.
  The file is outside the story's `Owns`. The plan recorded this gap as a run interdict and passed it to the lead, so it is not an implementer breach: a follow-up should widen the scope and update the row.
- minor — po/src/next/mod.rs:107 — Under `--remote`, only `po next` puts the `merge-waiting` stop under the effective value. `po state --remote` still reports `lanes[].stops` from the written line.
  On a collaborative forge with the line `automatic`, or a solo forge with `human (forge)`, the two verbs now disagree about the same lane. The plan scoped `po state` out on purpose; this is worth an issue.
- minor — docs/decisions/ADR-0141-po-next-remote-recupere-origin-avant-de-lire.md:7 — ADR-0141 rewords the rule of ADR-0130 ("seuls les verbes `ship` et `po next --remote` l'appellent"), but its frontmatter keeps `supersedes: []`. ADR-0130's own file carries no pointer to the amendment.
  A reader of ADR-0130 still finds the old, now partly false boundary. A link, or a note in the decisions index, would make the amendment visible.

## Not verified
- A fetch against a real forge over ssh or https: the tests use a local bare repository behind `insteadOf`. Two consequences are untested:
  - **Speed.** `po next --remote` now pays a network round-trip on every run, and `/po-drive` calls it many times per wave. Neither the latency nor a hung network has been measured; `run_with` has no timeout, the same as `po ship land`.
  - **Silent stall.** An ssh key with a passphrase and no agent could prompt on the tty despite `GIT_TERMINAL_PROMPT=0` and stdin null, stalling the driver without a word.
  - A person should run `po next --remote` from a real Polype project with a GitHub `origin`, once over https and once over ssh, and watch the time it takes.
- Two fetches at once: the fetch of `po next --remote` runs from the project root while a `po ship land` or `ship clean` lane may be fetching too. A collision on a ref lock is ignored on the `next` side, but on the ship side it would give `git-failed`. Not reproduced. A person should watch for `git-failed` on ship during a multi-lane `/po-drive` wave.
- The GitHub forge reading itself (`gh auth status`, `user`, `collaborators`, protection, rulesets): only ever exercised through a `gh` double. A real repository, solo and collaborative, has not been tried.
- `tests/ship-order-and-closed-pr*`: these now attempt a fetch from a github.com URL that does not exist. The record says they passed unchanged in 2.7 s; I did not rerun them.
- End to end and build: the project has neither (`E2E: —`, `Build: —`).

Max severity: major
Ship allowed: yes
