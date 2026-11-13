---
validated: yes
---
# Plan — s164-state-as-json

[Story](../stories.md) · [Research](../research/s164-state-as-json.md)

Branch `story/s164-state-as-json`. Read `docs/research/s164-state-as-json.md` first; this plan builds on it without repeating it.

The crate's dependencies are settled by [ADR-0118](../decisions/ADR-0118-les-dependances-du-crate-po.md), `accepted`: option 1 bis, the owner's answer of 2026-11-13. That means `serde` with derive, `serde_json`, and `chrono` with `default-features = false` plus `clock` and `std`. Arguments are read by hand and there is no `clap`. No other crate.

### Typed contract (ADR-0118)
- Every object `po` prints is a `#[derive(Serialize)]` struct. A field that the contract shows as `null` until its story ships is an `Option<T>` that is always serialized (never `skip_serializing_if`). The key is therefore present with `null`, and the compiler checks its type.
- Each folder owns the types of the fields it computes, written now from `docs/interface-agent.md`:
  - `next::NextAction {action, reason}`, `next::Held {story, reason, ref}`;
  - `run::Session {running, id}`, `run::Bounds` (enum `held`/`unproven`, serialized in lowercase);
  - `trust::Shipped {story, commit, trust}`.
- Each folder's function returns `None` for now. A later story fills its function and may reshape only its own types.
- `deny_unknown_fields` goes on every type that `po` parses from outside: standard input and arguments. s165's decision input is the first; s164 parses none.
- A file `po` reads back from disk is read through a narrow view that ignores fields it does not know, per ADR-0117: a field added by a newer `po` must not make an older one drop the file. For s164 that view is `inbox::DecisionStatus {id, status}`.
- No `serde_json::Value` in the state's types. `Value` stays allowed only to pass through a sub-object a later story owns, and s164 has none.

## Story
`po state` prints a project's state as one JSON object read from files and git, from the root or a worktree; the crate declares every verb of the contract and of the lead, the unbuilt ones answering `not-built`; the installer builds `po` from its sources. Criteria: `state_prints_one_json_object`, `state_reads_only_files_and_git`, `lane_stage_follows_the_gates`, `waiting_reads_the_inbox_setting`, `installer_builds_po_from_sources`, `po_warns_on_another_version`. All six are read by a script (the binary or the installer): each has its oracle test. The documentation of task 8 is judged by reading, with no phrase test.

### What this plan settles in the contract
- Place: `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po`, one per machine, a state file at the payload root beside `version` (research, fact 2), so ADR-0095's foreign-file rule lets it be.
- `po`'s version is `CARGO_PKG_VERSION`, kept equal to `POLYPE_VERSION` of `bin/polype:27`; the oracle reads the latter, so a drift fails it.
- Project root: the parent of `git rev-parse --path-format=absolute --git-common-dir`, so a worktree resolves to the main checkout. A Polype project has `AGENTS.local.md` or `.polype/version` there (`po-session.sh:12`); otherwise exit 2, `not-a-project`. Settings read from the root's `AGENTS.local.md` on disk, first `Name:` line, as `po-session.sh:29-31`.
- Fields: `project` = basename of the root; `commit` = `git rev-parse --short=7 <Target branch>`, `null` when unreadable; `method_version` = first line of `.polype/version`, `null` when missing; `framing` = `{stage, next}` by `po-session.sh:70-105` (`next: null` when `done`; no `AGENTS.local.md` → `{"stage": "setup", "next": "/po-setup"}`); `milestone` = `{id, stories, shipped}` of the first `## M…` section of `docs/stories.md` on `Target branch` holding a story not shipped, `id` being the heading text before ` — `, `null` when none; `waiting` (task 6); `lanes` (task 5); `ready`, `held`, `session`, `bounds`, `shipped` = `null`, each asked of its folder.
- `warnings`: always an array, of objects `{"code": …}`: `method-version-mismatch` `{po, project}`; `missing-setting` and `unreadable-setting` `{setting}`; `orphan-worktree` `{path, branch}`, `branch` `null` when detached; `unreadable-decision` `{path}`; `no-gate` `{story}`. A field that a missing setting prevents is `null`.
- Lane stage, first rule that applies, each gate run as the lane's own `.polype/hooks/po-gate.sh <gate> <id>` with the lane as working directory, `GIT_OPTIONAL_LOCKS=0`, stderr dropped: shipped (rule of `po-session.sh:150`) → `ship`; no plan → `research` without a research file, `design` when the story's `Surface` line says `screen` and `docs/designs/<id>/design.md` is missing, else `plan`; `plan-validated` refuses → `plan`; `ship-allowed` passes → `ship`; `verif-current` refuses → `execute`; the story goes to QA (Law 1, from `QA stage` and the `Surface` line) and `qa-current` refuses → `qa`; else `review`. A blocked review on unchanged code stays `review` (s168 gives it `fix`); a landed lane still on disk is `ship` (its clean-up). No gate script → `stage: null` and `no-gate`. `QA stage` missing for a story that has a screen or a `Surface` other than `—` → `stage: null` and `missing-setting`.
- `lanes[].blocked_by`: the first of `po-session.sh:213-238`, as a code: `root-cause-not-found`, `technical-choice`, `qa-blocked`, `max-attempts`, `merge-waiting`; else `null`.
- Exit and output: every verb prints one object and exits 0, 1 or 2; a panic prints `{"contract": 1, "error": "internal", …}` and exits 2; unknown verb → 2 `unknown-verb`; no verb → 2 `usage`.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Gate verdicts per lane | Repository: `method/hooks/po-gate.sh:667-673`, called as a process | — |
| Framing, worktrees, shipped, per-lane stops | Repository: ported from `po-session.sh:59-239`, same rules | `po-session` prints prose and exits in a worktree (`:13`); ADR-0116 keeps it as it is |
| Settings line reader | Repository rule `po-session.sh:29-31`, rewritten in Rust | No Rust in the repository yet |
| Git, process, files, arguments | Standard library (`std::process::Command`, `std::fs`, `std::env::args`) | — |
| JSON in and out as derived types, local date with offset | New dependencies, ADR-0118 option 1 bis (owner's choice) | The standard library has neither; a hand-written JSON reader on input from outside is ruled out by the ladder's trust-boundary clause |
| Installer step without cargo | Repository: the jq precedent `bin/polype:718-722`, atomic copy as `lay_down` `bin/polype:224-230` | `lay_down` writes under `$root`, which is the project in project mode |
| Test PATH without cargo | Repository: `tests/project-lead.test.sh:251-258` | — |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/state-as-json.oracle.test.sh` | `4147897992 14356` |

| Criterion | Test |
| --- | --- |
| `state_prints_one_json_object` | `test_state_prints_one_json_object` |
| `state_reads_only_files_and_git` | `test_state_reads_only_files_and_git` |
| `lane_stage_follows_the_gates` | `test_lane_stage_follows_the_gates` |
| `waiting_reads_the_inbox_setting` | `test_waiting_reads_the_inbox_setting` |
| `installer_builds_po_from_sources` | `test_installer_builds_po_from_sources` |
| `po_warns_on_another_version` | `test_po_warns_on_another_version` |

The oracle fixes these interfaces: `po` at `${CARGO_TARGET_DIR:-$ROOT/po/target}/release/po`; `.project` is the root's basename; warnings carry `code`; the installer says `cargo not found` and `check` says `po missing`.

## Tasks
1. [x] **Crate and contract.**
   - `po/Cargo.toml`: `name = "po"`, `version = "0.2.0"`, edition 2021, `[profile.release]` defaults. Dependencies exactly as ADR-0118 writes them: `serde` with `derive`, `serde_json`, `chrono` with `default-features = false` and `clock`, `std`. `po/Cargo.lock` is committed.
   - `po/src/main.rs`: dispatch of `state`, `next`, `inbox`, `answer`, `record`, `run`, `continue`, passing the remaining arguments to the verb's folder.
   - `po/src/output.rs`: a generic `Reply<T: Serialize>` that flattens `"contract": 1` into one object; `ErrorReply {contract, error, message}`; the exit code; a panic hook that prints `ErrorReply` with `internal`.
   - Folders `po/src/next/`, `po/src/run/`, `po/src/trust/`, `po/src/inbox/`, `po/src/record/`, each a `mod.rs` whose verb returns `not-built` (exit 2).
   - In those folders, the types of the typed contract above, and functions returning `None`: `next::lane_next`, `next::ready`, `next::held`, `run::session`, `run::bounds`, `trust::shipped`.
   - `trust::state_options(args)` refuses any argument for now (exit 2, `unknown-option`), so s170 adds `--all` and `--remote` there. `.gitignore`: `po/target/`. — Fails if wrong: the `not-built` and unknown-verb part of `test_state_prints_one_json_object`.
2. [x] **Harness.** `tests/run.sh`, before any test: export `CARGO_HOME` and `RUSTUP_HOME` when unset (`$HOME/.cargo`, `$HOME/.rustup`, taken before a test moves `HOME`), `CARGO_TARGET_DIR` when unset (`<root>/po/target`), and a fresh `CLAUDE_CONFIG_DIR` under a temporary directory removed at exit (always, so no test reaches the real `~/.claude`); then `cargo build --release --locked --quiet --manifest-path <root>/po/Cargo.toml`, stopping with exit 1 and cargo's output when it fails. `tests/lib.sh`: `PO` set to the same path the oracle uses. `ci.yml` unchanged. — Fails if wrong: every oracle test (`po is not built`), and the installer tests that move `HOME`.
3. [x] **Context.** `po/src/project.rs`: root resolution, settings reader, a `git` helper (`GIT_OPTIONAL_LOCKS=0`, never `fetch`, `pull`, `push` or any write), `project`, `commit`, `method_version`, the `method-version-mismatch` warning. `po/src/state/mod.rs` holds the derived `State`, `Framing`, `Milestone`, `Lane` and `Warning` types: `Warning` is an enum tagged `code` in kebab-case, each variant carrying its own fields. It assembles the object. — Fails if wrong: `test_po_warns_on_another_version`, the root and worktree parts of `test_state_prints_one_json_object`, `test_state_reads_only_files_and_git`.
4. [x] **Framing and milestone** in `po/src/state/framing.rs`, by the rules above. — Fails if wrong: the parity test of task 9 (`po state` against `po-session` on the same fixtures).
5. [x] **Lanes** in `po/src/state/lanes.rs`: worktrees as `po-session.sh:114-142`, shipped as `:152-163`, stage through the gates, `blocked_by`, orphan warnings, `next` from `next::lane_next`. — Fails if wrong: `test_lane_stage_follows_the_gates`; `blocked_by` by the test of task 9.
6. [x] **Waiting.** `po/src/inbox/mod.rs` gains `pending_ids(dir) -> Result<Vec<String>, …>`: every `*.json` of the folder, parsed as `DecisionStatus` (unknown fields ignored, per the typed contract), kept when `status` is `pending`, sorted by `id`; an unreadable file is skipped with `unreadable-decision`. The folder is `Decision inbox` resolved from the root (absolute kept as is): missing folder → `[]`; missing line → `null` and `missing-setting`; `—` → `null` and `unreadable-setting`. `method/templates/agents-local.md`: `Decision inbox:     .polype/inbox/` in the block after `Forge checks`, and its table row (folder of the decision files waiting for the person, from the repository root or absolute, never in git, ADR-0107). This repository's `AGENTS.local.md`: the same line. — Fails if wrong: `test_waiting_reads_the_inbox_setting`; the template's shape by `tests/structure.test.sh` and `tests/setup-modes.test.sh`.
7. [x] **Installer.** `bin/polype`: `po` joins the root state files of `is_payload_state_file` (`:299-305`); `build_po`, called after `wire_the_project` in `cmd_install` and `cmd_update`, all modes: no `$base/po/Cargo.toml` (a run from the payload) → stderr `polype: no po sources in <base>; po was not built` and the place of the `po` kept, or missing; no cargo → `polype: cargo not found; po was not built …` naming the path; otherwise `cargo build --release --locked --quiet --manifest-path "$base/po/Cargo.toml" --target-dir "${CARGO_TARGET_DIR:-$base/po/target}"`, a failure named with cargo's output; success copies the binary to `<path>.polype-next`, `chmod +x`, `mv -f`. None of these exits non-zero. `cmd_check`: `po missing: <path> …` when it is absent, exit status unchanged. — Fails if wrong: `test_installer_builds_po_from_sources`; `tests/global-install.test.sh`, `tests/payload-refuses-foreign-files.test.sh`, `tests/installer-leftovers.oracle.test.sh`, `tests/project-lead.test.sh` unchanged and green.
8. [x] **Docs.** `docs/interface-agent.md`: the command is `po <verb>` at the path above; `:5` says `state` exists and the other verbs answer `not-built` until their story; `jq absent` (`:27`) becomes a verb not built yet; `warnings` and its codes; `method_version` is the content of `.polype/version`; the stage rules and `blocked_by` codes; the inbox folder is the `Decision inbox` setting, `.polype/inbox/` in the template; `po-record` becomes `po record`. `docs/installation.md`: where `po` lives, built by `install` and `update` run from a clone, kept by a run from the payload until s171, what happens without cargo, the `check` line, `remove --global` takes it, and `po` joins the per-machine files chezmoi must not track. — Judged by reading.
8 bis. [x] **Eval isolation** (added after the blocker, `evals/lib.sh` joined `Owns` in PR #246): `eval_base` runs its `bin/polype install` under a throwaway `CLAUDE_CONFIG_DIR`, removed afterwards, so building `po` never touches the config `po-eval` guards. — Fails if wrong: `eval-arms-same-environment.test.sh`, `reuse-ladder-eval.test.sh`.
9. [x] **Tests of the story and the full run.** `tests/state-as-json.test.sh`, task tests: framing parity (for each of setup, scope, stories, stories-review, architecture, design-system needed and not needed, done, `framing.next` equals what `po-session` prints after `Framing next:` on the same fixture, `none — framing done` reading `null`); milestone (the first `## M` section holding an unshipped story, `null` when all shipped); `blocked_by` (one lane per code) and an orphan worktree warning; the payload (`po` at its root does not stop `install --global` nor `update --global` run from the payload, and `remove --global` takes it). Then the full suite and the record: `po-run --story s164-state-as-json --label 'Unit suite' -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- Empty diff: `method/` except `method/templates/agents-local.md`; in particular `method/hooks/po-session.sh`, `method/hooks/po-gate.sh`, `method/AGENTS.md`.
- Empty diff: `.github/workflows/ci.yml`, `bin/po-ci`, `.claude/`, `.polype/`, `docs/a-trancher.md`, every existing `tests/*.test.sh`; a failing installer test is fixed in `bin/polype`, never in the test.
- No crate beyond ADR-0118's option 1 bis (no `clap`, no other argument parser), no `build.rs`, no network call from `po`.
- No `#[serde(deny_unknown_fields)]` on a type read back from a file `po` wrote; none missing on a type parsed from standard input or arguments.
- `po state` writes no file, takes no git lock, calls no forge and no model; no other verb gains behaviour.
- `po/src/` holds `main.rs`, `output.rs`, `project.rs`, `state/` and the five folders named in task 1, so later stories each fill one folder.
- `tests/lib.sh`: only `PO` is added; existing helpers keep their text.

## The pivot
Stage parity rests on calling `po-gate` inside each lane rather than re-deriving the gates. Wrong if the gate runs with the root as working directory (it would judge `main`): `test_lane_stage_follows_the_gates` sees every lane at `plan`. Wrong if four bash gates per lane break the second on a repository with many lanes: time `po state` on a fixture of `Parallel` lanes. Wrong if `review` for a blocked review and `ship` for a landed lane leave s168 without the information it routes on: compare with `po-drive.md`'s resume rules before ship. Second hinge: `po` as a root state file of the payload; wrong if a run from the payload counts it as foreign or `check --global` lists it as drift, which `tests/global-install.test.sh:133-159` and task 9's payload test show.

## Files touched
`po/Cargo.toml`, `po/Cargo.lock`, `po/src/**`, `bin/polype`, `method/templates/agents-local.md`, `AGENTS.local.md`, `docs/interface-agent.md`, `docs/installation.md`, `.gitignore`, `tests/run.sh`, `tests/lib.sh`, `tests/state-as-json.test.sh`; written by the planner: `tests/state-as-json.oracle.test.sh`, `docs/research/s164-state-as-json.md`, this plan, `docs/decisions/ADR-0118-les-dependances-du-crate-po.md`.

## Test strategy
- Oracle (6): the binary on throwaway repositories built by the test, and the installer in a throwaway `CLAUDE_CONFIG_DIR`, with a PATH that hides cargo for the fallback.
- Task tests (4, `tests/state-as-json.test.sh`): framing parity with `po-session`, milestone, `blocked_by` and orphans, the payload rule. Gates are not retested: `tests/gate.test.sh` owns them.
- 10 tests in `Test budget` 25. No mock: the real `po-gate`, the real git, the real installer.
- Not tested, judged by reading: the docs of task 8. Candidate for a `po-eval` control arm: none, no rule here speaks to a model.

## Validation
Checked by the planner against each criterion, with no human review (`Plan validation: autonomous`). The technical choice was settled by the owner on 2026-11-13 (ADR-0118, `accepted`).
- `state_prints_one_json_object`:
  - covered by tasks 1, 3 and 5;
  - the `Option<T>` fields that are always serialized give the required `null`s;
  - the panic hook and `ErrorReply` keep refusals and failures to one object.
- `state_reads_only_files_and_git`:
  - covered by task 3's git helper and task 5's gates under `GIT_OPTIONAL_LOCKS=0`;
  - no forge or model is called anywhere in the plan;
  - the timing on this repository is judged by the oracle.
- `lane_stage_follows_the_gates`:
  - covered by task 5's stage rules, through the lane's own `po-gate`;
  - the seven oracle states map to `research`, `plan`, `execute`, `review`, `review`, `ship`, `ship`, as the rules above give.
- `waiting_reads_the_inbox_setting`:
  - covered by task 6 for `[]`, `null` with `missing-setting`, and the sort by id;
  - the oracle's decisions carry only contract fields, so the narrow view reads them.
- `installer_builds_po_from_sources`:
  - covered by task 7 (build, place, the message without cargo, the `check` line);
  - task 2 keeps the run isolated.
- `po_warns_on_another_version`:
  - covered by task 3, with `CARGO_PKG_VERSION` equal to `POLYPE_VERSION`;
  - `Warning::MethodVersionMismatch {po, project}` serializes with `code`.

## Done when
The six oracle tests and the four task tests pass with the full suite under `po-run`; `po state` answers on this repository from its root and from this worktree; one commit on `story/s164-state-as-json`, reviewed, shipped as `s164-state-as-json: L'état d'un projet se lit en JSON`.
