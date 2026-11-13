# Research — s164-state-as-json

[Story](../stories.md)

## Structuring facts
- Root cause (the story carries `Corrige`, #203 and #204 in part): no component derives a project's state as data. The only derivation, `method/hooks/po-session.sh:22-280`, prints prose for a person, says nothing inside a story worktree (`po-session.sh:13`) and is frozen in bash by ADR-0116; `/po-status` is model prose (`method/commands/po-status.md:13-39`). No `po/` exists in the repository.
- False assumption of the story text: "le dossier de Polype de l'utilisateur" is `~/.claude/polype/` (`bin/polype:38-41`), the signed payload, where any file the installer did not lay down stops `install`, `update` and `remove` (`bin/polype:356-393`, ADR-0095). `po` can only live there as a recognised state file at the payload root (`bin/polype:299-305`), never under `polype/bin/`. Corrected in the plan, not worked around.
- A gap the story leaves open: run from the payload (`~/.claude/polype/bin/polype update --global`, the documented daily path, `docs/installation.md:56-60`), the installer has no `po/` sources (`bin/polype:149-150` ships only `bin/` and `method/`), so it cannot build. The plan keeps the `po` in place and says so; s171 brings the download.
- The tests change `HOME` to throwaway dirs (`tests/global-install.test.sh:9-15`, `tests/payload-refuses-foreign-files.test.sh:8-14`): a cargo launched by the installer under such a HOME loses `~/.cargo` and `~/.rustup`. `tests/run.sh` must pin `CARGO_HOME`, `RUSTUP_HOME` and `CARGO_TARGET_DIR` before any test, and give every run a throwaway `CLAUDE_CONFIG_DIR`: five installer test files never isolate it (`install.test.sh`, `installer.test.sh`, `leftovers.test.sh`, `platform-setting.test.sh`, `distribution-wiring.test.sh`) and would lay `po` into the developer's real `~/.claude/polype/`.
- Stage parity rests on `po-gate` (`method/hooks/po-gate.sh:44-50, 78-95, 134-151, 212-237`), which ADR-0116 keeps in bash: `po state` calls each lane's own `.polype/hooks/po-gate.sh` rather than re-deriving the gates in Rust.

## Diagnostic
Reproduction, on the code as it stands: `bash method/hooks/po-session.sh` inside this worktree prints nothing and exits 0 (line 13); from the repository root it prints six lines of prose (`Framing: scope by hand · stories present · stories review none …`). `ls po` fails. No command prints JSON.
- H1 — "`po-session` could print JSON behind a flag". Refutation sought: does it serve a worktree, and may it change? It exits on `story/*` (`po-session.sh:13`) and ADR-0116 keeps the hooks as they are; s172 makes it read `po state` instead. Discarded.
- H2 — "`/po-status` already exposes the state". Refutation sought: is it code? It is a command a model reads (`po-status.md:13`), its output a table of prose. Discarded.
- H3 — "the state lacks a home, not a derivation": the derivation exists (`po-session.sh:70-263`, `po-gate.sh`), only its form is wrong. Refutation sought: a rule `po state` needs that neither file holds. Found only `milestone` (no file derives it) and `waiting` (decision files, new with ADR-0107); both are new fields, not a refutation. Kept.

## Story
`po state`, run from a project or one of its worktrees, prints one JSON object (`"contract": 1`, `project`, `commit`, `method_version`, `framing`, `milestone`, `lanes`, `waiting`), with `null` for what later stories compute; the crate declares every verb, the unbuilt ones answering `not-built` in exit 2. It reads files and git only, in under a second. Each lane's `stage` follows the gates. `waiting` lists pending decisions from the folder `Decision inbox` names. `bin/polype install`/`update` build `po` with cargo into the user's Polype folder, carry on without cargo, and `check` reports a missing `po`. `po` warns `method-version-mismatch` when `.polype/version` differs. Criteria: `state_prints_one_json_object`, `state_reads_only_files_and_git`, `lane_stage_follows_the_gates`, `waiting_reads_the_inbox_setting`, `installer_builds_po_from_sources`, `po_warns_on_another_version`.

## Current code
- `po-session.sh` — project test: `AGENTS.local.md` or `.polype/version` at the top (`:12`); settings by `sed` on the first `Name:` line (`:29-31`); `GIT_OPTIONAL_LOCKS=0` (`:6`). Framing from files on `Target branch` (`:70-105`): scope by `Entry mode` (`replace|adapt` → `docs/prd.md`, `new` → `docs/brief.md`, `—` → by hand, anything else unreadable), `docs/stories.md`, last `Stories ready:` of `docs/reviews/stories.md`, `docs/architecture.md`, `docs/design-system.md`, "not needed" when every story has a `Surface` and none says screen (`:59-68`). Worktrees (`:114-142`): a lane is `<Worktree root><id>` on `story/<id>`; anything else under the root, or any `story/*` elsewhere, is an orphan. Shipped (`:152-163`): subject `^<id>:` or `^s<n>:` on `Target branch` and `origin/<Target branch>`. Per-lane human stops (`:207-239`): root cause not found, technical choice, QA blocked, `Max attempts` reached (skipping a review blocked on QA evidence), merge presumed waiting.
- `po-gate.sh` — `plan-validated` (`:44-50`), `ship-allowed` (`:78-95`), `verif-current` (`:134-151`), `qa-current` (`:212-237`); `top()` is `git rev-parse --show-toplevel` of the cwd (`:39`), so a gate run inside a worktree judges that worktree. Exit 0 pass, 1 refused (`refuse` returns 1, `:40`).
- `bin/polype` — `POLYPE_VERSION="0.2.0"` (`:27`) is what `stamp_version` writes into `.polype/version` (`:785`); `home="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"` (`:38`). `cmd_install` (`:852-896`) and `cmd_update` (`:903-960`) end with `wire_the_project` then the done message; `cmd_check` (`:962-998`) prints `missing:`/`modified:` lines and exits 1 on drift; `remove --global` deletes the whole payload dir (`:1053`). jq precedent: a missing tool is named on stderr and only its step is skipped (`:718-722`), tested with a PATH of symlinks that leaves the tool out (`tests/project-lead.test.sh:251-268`).
- `tests/run.sh` (29 lines) sources `lib.sh` and each file per test; no build step. `.github/workflows/ci.yml:22-23` installs jq then calls `bin/po-ci`, which runs `Test` (`bin/po-ci:6-15`). `.gitignore` has no `po/target/`.
- `method/templates/agents-local.md:9-40` — settings block, values table `:42-73`; the installer names any template setting a project lacks (`bin/polype:583-607`).
- `docs/interface-agent.md` — still names `.polype/hooks/po-agent.sh` (`:12`), `po-record` (`:91`), `jq absent` as an exit-2 case (`:27`), a commit hash as `method_version` (`:40`), and says nothing exists yet (`:5`).

## Attachment points
- New crate `po/` (`Cargo.toml`, `Cargo.lock`, `src/main.rs`, `src/state/`, and the five folders the story names, each answering `not-built`).
- `bin/polype`: `is_payload_state_file` (`:299-305`) learns `po`; a `build_po` step after `wire_the_project` in `cmd_install` and `cmd_update`; one line in `cmd_check`.
- `tests/run.sh` (build once, pin the cargo and Claude dirs), `tests/lib.sh` (`PO` path).
- `agents-local.md` block and table (`Decision inbox`), this repository's `AGENTS.local.md`, `.gitignore`.

## Verified interfaces
- `git worktree list --porcelain`: `worktree <path>` then `branch refs/heads/<name>` (parsed `po-session.sh:135-140`).
- Gate CLI: `po-gate.sh plan-validated|ship-allowed|verif-current|qa-current <id>` (`po-gate.sh:667-673`).
- Story headings: `^##+ s[0-9]+-[a-z0-9-]+` (`po-session.sh:20, 62`); `Dépend de`/`Depends on` and `Surface` lines (`:63, 182`). Milestone headings are `## M<n>[ bis…] — <title>`; on this repository the first such section holding an unshipped story is M21 (checked against `git log main`), sections such as `## Reportées` and `## M22 … (à cadrer)` hold none or are not milestones.
- Decision shape: `docs/interface-agent.md:100-119` (`id`, `status`, …).
- Toolchain here: `/usr/bin/cargo` 1.99 (no rustup); the GitHub `ubuntu-latest` runner ships rustup and cargo, so `ci.yml` needs no change.

## Traps
- `refuse_foreign_payload_files` (`bin/polype:356`) runs on global runs and on any run from the payload: a `po` it does not know stops them, and `tests/global-install.test.sh:133-159` counts payload files before and after a run from the payload.
- `tests/installer-leftovers.oracle.test.sh:78` reads the last lines of a failed run: building `po` after the stop point keeps them unchanged.
- `tests/structure.test.sh:8-22`, `tests/setup-modes.test.sh:13-27` and `tests/platform-setting.test.sh` freeze the template's shape: one `Name: value` per block line and a table row per setting.
- A no-op `cargo build` costs about 0.03 s here when the target dir is shared; a fresh target dir costs 6 s of compile (measured on a probe crate with the candidate dependencies). Every installer test from the repository pays the no-op.
- On this repository, `po-session` reports `stories review none · architecture missing` (`docs/reviews/stories.md` is absent on `main`: reviews are per milestone). `po state` will say `framing.stage: "stories-review"` here, faithfully; that is parity, not a fault of `po`.
- No migration. No code of a previous story is rewritten; `po-session.sh` and `po-gate.sh` stay with an empty diff.

## Open questions
- Stage of a lane whose review is blocked, and of a landed lane still on disk: the contract names no `blocked` or `landed` stage. The plan settles `review` and `ship`, and the reviewer should check that s168 can route from them.
- Which crates: settled by the owner on 2026-11-13, ADR-0118 option 1 bis (`serde` derive, `serde_json`, `chrono`, no `clap`).
- `blocked_by`: the contract shows it without values; the plan fills it from `po-session`'s per-lane stops so nothing they show is lost when s172 switches.

## Complexity
4 → 4. The Rust part is small (a few hundred lines porting `po-session`), but the story also changes the installer, the test harness and its isolation, and the payload rule of ADR-0095.

## Split
—
