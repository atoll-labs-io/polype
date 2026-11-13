# Review — s165-decision-inbox

[Story](../stories.md) · [Plan](../plans/s165-decision-inbox.md) · [Verification](../verif/s165-decision-inbox.md)

Diff reviewed: `git diff main...story/s165-decision-inbox`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: bb5827b09b6468309495bdbdb105782fb8b0fcd6

## When blocked
- Failure cause: —
- Missing: —
- Required adaptation: —
- Next action: —

## Ownership
I listed the diff with `git diff --name-only main...story/s165-decision-inbox` and checked each path against the story's `Owns` line (`docs/stories.md:2616`).
- [x] Every path is inside `Owns`. That covers `po/src/inbox/{add,decision,mod}.rs`, `bin/polype`, `method/AGENTS.md`, `AGENTS.local.md`, `.gitignore`, `docs/a-trancher.md` (deleted), `docs/interface-agent.md`, `docs/installation.md`, `tests/decision-inbox.oracle.test.sh`, `tests/decision-inbox.test.sh` and `tests/state-as-json.oracle.test.sh`. The research, plan and verification files under `docs/` are the story's own evidence.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`. One shared path, not graded: s167-record-writes-reports also owns `tests/state-as-json.oracle.test.sh`. Its worktree is live, but `story/s167-record-writes-reports` has no commits of its own: `merge-base --is-ancestor` against `main` exits 0. Its plan (`:71`) already expects s165 to ship first and take `inbox` out of the same verb list, so this is not the critical case. Still, under the `Owns` rule of `## The fleet`, these two lanes should not run at the same time. The lead should land s165 before s167 commits.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s165-decision-inbox` → exit 0, record reused. The unit suite `bash tests/run.sh` exited 0, and the run's tree matches `Tree:` outside `docs/`. The project has no type check (`Typecheck: —`); `tests/run.sh` builds `po` with cargo, which type-checks the Rust. I read "Not proven here": its items are carried under Not verified.
- [x] `po-gate qa-current`: not required. `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1 to 9 are all present.
  - Types and reader: `decision.rs`. `NewDecision` and `Choice` carry `deny_unknown_fields`; `Decision` does not; field order follows `docs/interface-agent.md`.
  - List, show and dispatch: `mod.rs`.
  - Add, in the order the plan gives: `add.rs`.
  - `tests/state-as-json.oracle.test.sh:151` loses only `inbox`.
  - `ignore_decision_inbox` is wired after `ignore_local_sums`.
  - The rules use draft (a)(b)(c).
  - `docs/a-trancher.md` is deleted and `AGENTS.local.md:76` is reworded.
  - The docs of task 8 and the five task tests are in.
  - Nothing appears in the diff outside the plan.
- [x] Run interdicts, one by one:
  - Nothing changed in `po/` outside `po/src/inbox/`; `Cargo.toml` and `Cargo.lock` are untouched.
  - Nothing changed in `method/` except `AGENTS.md`; the root `AGENTS.md`, `.claude/` and `.polype/` are untouched.
  - The only existing test changed is `state-as-json.oracle.test.sh:151`.
  - `po answer` still answers `not-built`; there is no `--answered` and no `consume`.
  - List and show write nothing. Add writes only the temp file and `<id>.json`, and runs only `git rev-parse` and `git check-ignore`.
  - `deny_unknown_fields` sits only on `NewDecision` and `Choice`.
  - No field was added to the decision shape.

## References
- [x] Each reference was opened and confirmed:
  - `Project::find`, `Project::setting`, `Project::git` and `project::git` (`po/src/project.rs`).
  - `output::reply`, `output::error`, `REFUSED`, `UNREADABLE` and `OK` (`po/src/output.rs`).
  - `inbox::pending_ids`, still called by `state::waiting` (`po/src/state/mod.rs:172`).
  - `chrono::SecondsFormat` and `serde_json` (dependencies already present).
  - The template line `Decision inbox:    .polype/inbox/`, inside the fence of `method/templates/agents-local.md:40`, which the installer's awk reads.
  - `wire_the_project` in `bin/polype`.
- [x] Values checked:
  - The 200-character limit and the 2 to 3 options come from the story's criterion.
  - The `d-%04d` ids and the numeric sort come from plan rows 4 and 8.
  - The exit codes match plan row 2, and the table in `docs/interface-agent.md` agrees.
  - `asked` is RFC 3339 with its offset; the oracle checks it.

## Rules
- [x] `AGENTS.md` conventions are respected. Code and comments are in English, the docs in French, and comments are sparse and say why.
  - The story's rule (`rules_send_every_stop_to_the_inbox`), judged by reading: the new paragraph in `## What goes to the person` says what the criterion asks. Everything that goes to the person is first put through `po inbox add`, with options and recommendation. When `po` is missing or refuses, the lead says it anyway, with the reason.
  - `## Installed files` now names `po` beside the hooks.
  - Word ceilings are held: 378, 516 and 3743, all tested.
- [x] `provisional_inbox_is_gone`, judged from the diff: the file is deleted, and the settings line now names the box. The open items D5 to D10 are listed in the plan's `## Left for the lead once the story ships`, with D6 and D7 marked sensitive.
- [x] No accepted ADR is contradicted. ADR-0107 holds: local files, never in git, at a configured place. ADR-0117 is respected: on read, a field that is absent comes back as `null`, and unknown fields are tolerated.

## Tests
- [x] Floor: `po-gate floor-guard s165-decision-inbox main` → 0, nothing lowered. `po-gate oracle-intact` → 0, and the oracle's cksum matches the plan (`2626157713 12113`).
- [x] The assertions pin down the criteria. The tests run the real `po` and the real installer on throwaway repositories, with no mocks. None of the six shapes of tests that prove nothing appear. The fixtures carry no ids that answer for another check: `test_an_id_never_reaches_the_filesystem` even plants `.polype/x.json`, so the path-traversal assertion would really bite.
- [x] 10 tests against a `Test budget` of 25.
- [x] Bite tests (each change undone, and `git diff --exit-code po/src/inbox/add.rs` clean after each):
  - `kept_out_of_git` forced to true → 1 failing test (`inbox_never_enters_git`).
  - In `place`, a path in a worktree outside the root treated as outside the repository (`Place::Elsewhere` → `Place::Outside`, `add.rs:138`) → **0 failing tests**. See the first finding.
  - `hard_link` replaced by an overwriting `rename` → `parallel_adds_never_share_an_id` failed in 2 of 3 runs. The test is racy but does bite.
- [x] No test became useless. The `inbox` entry left the not-built loop of s164's oracle, as task 4 says.

## Neighbours
- [x] `state::waiting` is the only other caller of `pending_ids`, which is now built on the shared reader. The task test checks that `waiting` and the list agree. One narrowing of behaviour is noted as a minor finding.
- [x] `main.rs` dispatch is unchanged.
- [x] The installer's `.polype/` handling: the foreign-file refusal applies only to the global payload, and `remove` prunes only empty directories. A project's inbox is never taken for a foreign file and is never deleted, as `docs/installation.md` now says.

## Lenses
Lenses run: security — triggered by content. A decision id taken from the command line becomes a file path (`po inbox <id>`), and `po inbox add` writes files whose content comes from stdin. No path triggered any lens. Migration, dependencies and performance did not run: no trigger path or content.
- [x] Security checks:
  - Only `^d-[0-9]+$` ever reaches the filesystem; `../x` and `d-1/../x` are refused, and this is tested.
  - Writes never overwrite: a temp file, then a hard link.
  - Whether the inbox is ignored is checked from the root, never from a worktree.
  - A sensitive decision's `context` must be an absolute path outside the repository. Symlinks are resolved, and a worktree placed outside the root counts as inside the repository.
  - Nothing new found beyond the first finding.

## Findings
- major — po/src/inbox/add.rs:137-138 — No test exercises the case of a path inside a worktree placed outside the root (`Place::Elsewhere`).
    Replacing `Place::Elsewhere` with `Place::Outside` fails none of the 10 story tests. In practice, that would let a sensitive decision's `context` point into a worktree of `../`, and let `po inbox add` write into an unignored folder of such a worktree.
    The plan's `## The pivot` asked for exactly this: "test a folder under a worktree of `../`". The oracle's `$W` lies under `$F/.worktrees/`, so it only ever reaches the lexical `InRoot` branch.
    I probed by hand on a throwaway repository with a worktree outside the root. Today's code refuses a sensitive `context` there (`sensitive-context-in-repo`, also for a path that does not exist yet), refuses an inbox there (`inbox-not-ignored`), and refuses one reached through a symlink into the root. So the behaviour is right; only the test is missing.
    Fix: add one task test with a worktree created at `$SCRATCH/wt` covering both refusals.
- minor — po/src/inbox/mod.rs:46-55, po/src/inbox/decision.rs:50-64 — `po state` reads less leniently than before.
    `pending_ids` now parses every file into the typed `Decision`. A file whose `id` and `status` are fine but whose other field has another type (for example `blocks` as a string) now goes to `unreadable-decision`. s164's narrow `DecisionStatus` used to count it as waiting.
    This is consistent with `po inbox` and is warned about, so nothing is silently lost. But it narrows what ADR-0117's forward compatibility tolerates to "same types".
- minor — method/AGENTS.md:73,77 — Two pieces of wording were dropped to fit the word ceiling: the examples of what counts as a technical choice ("a library, a framework, a data model, a protocol, a hosting"), and the closing clause "raising them early changes when the person hears of them, not what they hold back".
    The plan authorised both cuts and no test froze them. Still, a model reading the rule loses the concrete list of what deserves an ADR discussion. Worth restoring in a later wording pass, if words can be freed elsewhere.

## Not verified
- `po inbox add` on this repository itself. Main's `.gitignore` gains `.polype/inbox/` only once the story ships, so until then it answers `inbox-not-ignored`; the record says so. After shipping, a person should run `po inbox` and one `po inbox add` from the root and from a worktree.
- The installer path that builds `po` with cargo present. The oracle hides cargo; I relied on the record's full-suite run (`test_installer_builds_po_from_sources`) and did not rerun it.
- I did not rerun the full unit suite: the record is current and was reused. I ran only the two story test files, with a target directory under the temp dir.
- An inbox on a filesystem without hard-link support (some FUSE or FAT mounts, reachable through an absolute `Decision inbox`). `po inbox add` would answer `inbox-unwritable`; I did not exercise it.
- Re-asking D5 to D10 through `po inbox add` after shipping, with an absolute `context` outside the repository for D6 and D7, is left to the lead (plan, `## Left for the lead once the story ships`).
- CI on the pull request runs at ship.
- The rule `rules_send_every_stop_to_the_inbox` was judged by reading only. It is a candidate for a `po-eval` control arm (#208).

Max severity: major
Ship allowed: yes
