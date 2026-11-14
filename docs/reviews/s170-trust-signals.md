# Review — s170-trust-signals

[Story](../stories.md) · [Plan](../plans/s170-trust-signals.md) · [Verification](../verif/s170-trust-signals.md)

Method version: 0.2.0

Diff reviewed: `git diff main...story/s170-trust-signals`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 7715ad8fab17fab752da71e9c638cda160218341

## When blocked
- Failure cause: —
- Missing: —
- Required adaptation: —
- Next action: —

## Ownership
Diff listed with `git diff --name-only main...story/s170-trust-signals`. Each path was checked against the story's `Owns` using the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`. These paths are covered by `Owns`: `po/src/trust/{mod,forge,landed,signals}.rs` (under `po/src/trust/`), `method/hooks/po-run.sh`, `docs/interface-agent.md`, `tests/trust-signals.oracle.test.sh`, `tests/trust-signals.test.sh`, `tests/run-ledger.test.sh` and `tests/state-as-json.oracle.test.sh`. These paths are the story's own evidence: `docs/plans/`, `docs/research/` and `docs/verif/s170-trust-signals.md`.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`: `git worktree list` shows no story worktree other than this one.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s170-trust-signals` → exit 0. I reused the record: `Tree: abadca05…` equals HEAD outside `docs/`, and the last `Unit suite` row (`bash tests/run.sh`) exited 0. That run also builds `po`, which stands in for the crate's type check (`Typecheck: —`: the project has no type-check command). I read the record's "Not proven here" section.
- [x] `po-gate qa-current`: not required. With `QA stage: —`, the story does not go to QA.

## Plan
- [x] Tasks 1–9 are all present, and nothing was changed outside the plan. `## Reuse` matches the diff: `state_options` was extended in place, `read_blobs` uses one `git cat-file --batch`, times are parsed with `chrono::DateTime::parse_from_rfc3339`, the forge is read through `gh api --hostname github.com`, and `SECONDS` was used in bash.
- [x] Run interdicts, checked one by one:
  - `po-gate.sh`, `tests/execute.test.sh` and `verification-record.md` are untouched.
  - The `po-run.sh` header stays at exactly 130 words (130 before as well), and only the command/printf area changed.
  - `Cargo.toml` and `Cargo.lock` are untouched.
  - `po/src/{context,state,next,run,record,inbox}/` are untouched.
  - No forge call is made without `--remote`; this was proven by bite 2.
  - `run-ledger.test.sh` changes only line 48, and `state-as-json.oracle.test.sh` only lines 136–137.
  - No file was added under `docs/decisions/`.

## References
- [x] Every call was opened and confirmed against the code:
  - `Landed::commit` (`context/lanes.rs:91`), `Context.milestone`/`stories`/`landed`/`project` and `Project::git`.
  - The `po record` formats the parsers rely on: `Method version: <v>` in `record/compose.rs:106-122`, and ``- Oracle: `po-gate oracle-intact <id>` → exit <n>`` followed by the gate output indented two spaces, in `record/mod.rs:184-197`.
  - `Fix loop:` and `Max severity:` at column 0 (`templates/review.md:10,63`).
  - `track: flow` written by `templates/plan-flow.md:2`.
  - `po-gate`'s row reading by position (`po-gate.sh:175-178`), which is unaffected because the duration is carried inside the Time cell.
- [x] Values were checked against the real data. On this repository, the rebuilt `po state` gives `s169-run-from-outside` → `oracle: changed-with-reason` (the research trap), and `fix_loops` and `max_severity` match the reviews. `po state` takes 0.07 s and `--all` (169 stories) takes 0.09 s.

## Rules
- [x] `AGENTS.md` conventions are respected. Comments are in English and short, and the commit message is in English.
- [x] No accepted ADR is contradicted. ADR-0083 holds: `po` reads no token and calls only `gh api --hostname github.com`. ADR-0118 holds: no crate was added. ADR-0117 holds: an old review gives `null`, not an error.

## Tests
- Oracle: `po-gate oracle-intact s170-trust-signals` → exit 0
- Oracle: `po-gate oracle-intact s170-trust-signals` → exit 0.
- [x] Floor: `po-gate floor-guard s170-trust-signals main` → 0, nothing lowered.
- [x] Assertions pin down the four criteria through the `po` binary, the real `po-run` and fixtures in a real git repository. None of the six empty test shapes applies. The `PO_GH` double answers by commit hash and logs its calls, so it does not reproduce the logic under test.
- [x] 7 new tests and 2 changed clauses, within `Test budget` 25.
- [x] Bite (each mutation was undone, and `git diff --exit-code` came back clean every time):
  - Milestone filter disabled in `trust/mod.rs:58` (`&&` made always true) → 1 failing test (`shipped_stories_carry_trust`).
  - Forge called without `--remote` (`mod.rs:68`) → 1 failing test (`checks_are_read_only_on_request`).
  - Last `- Oracle:` line taken instead of the first (`signals.rs`, `position` → `rposition`) → 1 failing test (`shipped_stories_carry_trust`, with `intact` instead of `changed-with-reason`).
- [x] No test was made useless. The old `shipped == null` clause was replaced, and this is logged in `## Oracle changes` of the record.

## Neighbours
- [x] Other callers were read:
  - `state/mod.rs:35,85` is the only caller of `state_options` and `shipped`.
  - `po-gate.sh` reads run rows by cell position, so the duration inside the Time cell changes nothing for it.
  - `po-retro.md` only counts rows and exits.
  - `tests/execute.test.sh:58` pins the header, which is unchanged.
  - `verbs-read-project-context.oracle.test.sh` drops `.shipped`.
  - The pre-existing `dead_code` warning on `output::not_built` comes from outside the diff.

## Lenses
Lenses run: security — `po/src/trust/forge.rs` builds a forge API path from the `origin` URL and runs `PO_GH`/`gh`; performance — `mod.rs:80` makes one `gh api` call per shipped story inside the map.
- [x] Each lens finding is graded and listed under Findings. Security found nothing to report:
  - The request is a GET pinned to github.com.
  - Owner and repo come from the user's own git config, with `/` refused.
  - `Command::new` gets separate arguments and no shell is involved.
  - `PO_GH` follows the existing `PO_CLAUDE` double pattern.

## Findings
- minor — po/src/trust/mod.rs:80 — With `--remote --all`, `po` makes one sequential `gh api` call per shipped story, inside the map. That is 169 process launches and network round trips on this repository. The plan and the contract both state this and claim no time bound. Potential impact only, and only on an explicit request.
- minor — po/src/trust/signals.rs:89 — A plan whose frontmatter explicitly says `track: full` gives `track: null`, although the value is plainly readable and is one of the contract's two values. No template writes that line today, so the plan's "any other value → null" rule has no visible effect yet. It is still a refusal of a valid value, not a guard against guessing.
- minor — docs/interface-agent.md:102 — The `oracle` row names only one `null` case: a review `po record` did not write. The code also returns `null` when the recorded gate exited 1 or 2 or did not run (`signals.rs`, `verdict != "→ exit 0"`). The common `null` rule (`:32`) covers this, so the issue is wording only.

## Not verified
- `checks` against the real GitHub API. Every test uses the `PO_GH` double, and the response shape follows the one example quoted in the research. A person should run `po state --remote` once on this repository and compare with `gh api repos/<o>/<r>/commits/<sha>/check-runs` for one landed commit.
- `gh` missing from PATH. The code maps a launch failure to `null`; I read this in the code, but no test exercises it.
- The time taken by `po state --remote` and `--remote --all`. I did not measure it, and no bound is claimed.
- `duration_s` on real records. Every story landed so far, s170 included, has rows written by the installed pre-story `.polype/hooks/po-run.sh`, which carries no duration, so the value will read `null` until Polype is reinstalled and new stories run. A person should check one story recorded after the reinstall.
- The contract text of `docs/interface-agent.md` (task 8) was judged by reading only. It is a candidate for a `po-eval` control arm (#208), as the plan says.
- Pagination beyond 100 check runs gives `null` by design. This was not exercised against a real forge.

Max severity: minor
Ship allowed: yes
