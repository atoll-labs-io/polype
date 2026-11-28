# Research — s218-next-sees-a-human-merge

[Story](../stories.md)

## Structuring facts
- No assumption of the story is false: every `path:line` of its notes was opened and holds. One is incomplete: the place of the fetch is not a free plan detail. ADR-0131 makes the title on `origin/<target>` after a fetch the only landing proof and turns down the forge's `MERGED` state; ADR-0130 keeps the only writing git launcher in `po/src/ship/` (`po/src/ship/git.rs:1-3`). A fetch inside `po next --remote` crosses that boundary, so the choice is drafted as ADR-0141 (`proposed`) and waits for the owner.
- #437 reproduces in the oracle fixture: after a person's merge reaches origin's `main`, `po next --remote` still answers `wait` `merge waiting` (run 2026-11-28 on the current code, `tests/next-sees-a-human-merge.oracle.test.sh`). Cause: `Landed::read` reads `main` and `origin/main` locally (`po/src/context/lanes.rs:81-91`) and nothing fetches before `po next --remote` (`method/commands/po-drive.md:30`; the only fetch is a text command of `po/src/next/open.rs:40-42`).
- #389: the `merge-waiting` stop compares the written line, suffix stripped, to `human` (`po/src/context/lanes.rs:358-360`, value from `LaneSettings::read` `:188-195`). The effective value is `ship::effective(line, verdict)` (`po/src/ship/mod.rs:43-56`) on a forge reading `ship::forge::read` (`po/src/ship/forge.rs:465-515`), both private to `po/src/ship/` today.
- The effective value needs the forge, so it can only be read under `--remote`: `docs/interface-agent.md:34` promises no forge call without the option, and `effective(line, "unreadable")` gives back the line's value (`po/src/ship/mod.rs:45-49`) — the offline reading stays what it is.
- `docs/interface-agent.md:271` describes `next --remote` and is not in the story's `Owns`: a gap of the story, reported to the lead.

## Story
The owner wants `po next` to read a fresh forge state and the effective `Ship confirmation`, so a pull request merged by hand stops reading `merge waiting` and a collaborative repository really waits for its person (#420, #437, #389). Criteria: `human_merge_is_seen`, `effective_confirmation_drives_merge_waiting`, `version_raised`.

## Current code
- `po next` (`po/src/next/mod.rs:87-120`): accepts only `--remote` (`:88-91`), reads `Context::read(project)` once (`:102`), then under `--remote` asks GitHub for pull requests closed without a merge (`closed_pull_requests`, `:133-149`, `Merge mode: pr` only, `Forge::of` github.com only).
- `Context::read` (`po/src/context/mod.rs:128-192`): `Landed::read` at `:149`, `LaneSettings::read` and `lanes::lanes` at `:165-167`; each lane's stage runs its own `po-gate` (`po/src/context/lanes.rs:248-295`) and its stops are computed once (`:228-229`, `stops` `:319-369`).
- `MergeWaiting` stop (`lanes.rs:358-367`): `Ship allowed: yes`, `Merge mode: pr`, confirmation `human`, not landed, `refs/remotes/origin/story/<id>` present. `blocked_by` is the first stop (`:229`); `MergeWaiting` is pushed last.
- Lane routing (`po/src/next/lane.rs:53-119`): `landed` → `ship` `landed` (`:56-58`) before anything; stage ship → `ship()` (`:207-232`): `blocked_by == MergeWaiting` → `wait` `merge waiting` (`:211-213`); `MergeWaiting` lanes leave the serial order (`:218`).
- `po state` (`po/src/state/mod.rs:53`) and `po run` (`po/src/run/mod.rs:89`) also call `Context::read`; neither takes part in this story.
- `po ship forge` (`po/src/ship/mod.rs:85-140`): reads `Target branch`, the `Ship confirmation` line, `forge::read`, then `effective()`; `rewrite` is ignored here.
- `po/src/project.rs:18-19`: "`po` never fetches, pulls, pushes nor writes" on the read-only launcher `git()`.

## Attachment points
- Fetch: `po/src/ship/git.rs` (the writing launcher, `run` `:26-28`, `LC_ALL=C`, `GIT_TERMINAL_PROMPT=0` `:40-41`); called from `po/src/next/mod.rs` `main`, before `Context::read`. `po ship land` fetches the same way (`po/src/ship/land.rs:309`).
- Effective value: a `pub(crate)` entry in `po/src/ship/mod.rs` wrapping `forge::read` + `effective`; `po/src/main.rs:9` declares `mod ship;`, so `crate::ship::…` is reachable from `next`.
- Stop: `po/src/context/lanes.rs` `stops` and `Lane` (`:60-71`); the override after the forge reading lives beside it, so the stop rule stays in one file.
- Version: `po/Cargo.toml:3`, `po/Cargo.lock` (line after `name = "po"`), `bin/polype:28`, all `0.13.1` (s216).

## Verified interfaces
- `pub fn git(dir: &Path, args: &[&str]) -> Option<String>` — `po/src/project.rs:20-34`, read-only, stderr dropped.
- `pub(super) fn run(dir: &Path, args: &[&str]) -> Ran` — `po/src/ship/git.rs:26`; `Ran::ok()` `:18-20`.
- `pub(super) fn effective(line: &str, verdict: &str) -> (String, Option<&'static str>)` — `po/src/ship/mod.rs:43`: `collaborative` → `human`; `solo` and the line follows the forge (bare or `(forge)`) → `automatic`; else the line's value.
- `pub fn read(project: &Project, target: &str) -> Reading` — `po/src/ship/forge.rs:465`; `Reading::verdict()` `:37-48`. `mod forge;` is private in `po/src/ship/mod.rs:8`.
- `Reading` on GitHub calls `gh auth status`, then `gh api -i` for `user`, `collaborators`, `branches/<t>/protection`, `rules/branches/<t>` (`forge.rs:155-162`, `:202-207`, `:287-404`); CODEOWNERS is read on `origin/<target>` (`:410-438`) — after the fetch, the fresh one.
- `Forge::of(project)` — `po/src/trust/forge.rs:142-145`, github.com only; `pull_request_closed` `:171-183`.
- `PO_GH`, `PO_CURL`, `PO_GLAB`, `PO_TEA` name the forge tools (`po/src/trust/forge.rs:18-29`): tests use doubles.

## Traps
- **Existing tests that run `po next --remote` with a fake github.com origin and no `insteadOf`**: `tests/ship-order-and-closed-pr.oracle.test.sh:130,158-184` and `tests/ship-order-and-closed-pr.test.sh:14,31-48` (the second also with a gitlab.com origin). With a fetch, these runs reach the network and fail to fetch; their expectations must not move (a failed fetch changes nothing, an unreadable forge leaves the line's value). Neither file is in `Owns`: they must pass unchanged, and the implementer reports any network slowness instead of editing them.
- The gitlab.com run above makes `forge::read` launch `glab` (`forge.rs:117-124`), real or missing — harmless, but a reason to read the forge only when some lane awaits a merge.
- A fetch on an ssh `origin` uses the user's ssh setup, as `po ship land` does (`land.rs:309`); no new prompt path is added.
- `po next --remote` is run many times per wave by `/po-drive`: the forge reading (four to five calls) only when at least one lane awaits a merge keeps the common run cheap.
- The `MergeWaiting` stop also feeds `po state` (`lanes[].stops`, `docs/interface-agent.md:104`), which keeps reading the line: `po state --remote` is not asked to change by the story.
- Rust has no unit tests (`grep -rn "cfg(test)" po/src` → nothing); `po` is tested in bash through the release binary built by `tests/run.sh:24-29`.
- No migration, no new dependency, no screen.

## Open questions
- Where the fetch lives (ADR-0141, `Technical choice: waiting for a human`): A `po next --remote`, B `/po-drive`, C forge merged state. The plan is written for A.
- Whether `docs/interface-agent.md` joins the `Owns` so its `next --remote` row says the fetch and the effective value (lead's call).

## Complexity
3 → 3. Two small reads join an existing verb; the weight is in the boundary decision, not the code.

## Split
—
