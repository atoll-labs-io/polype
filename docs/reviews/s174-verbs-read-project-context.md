# Review — s174-verbs-read-project-context

[Story](../stories.md) · [Plan](../plans/s174-verbs-read-project-context.md) · [Verification](../verif/s174-verbs-read-project-context.md)

Method version: 0.2.0

Diff reviewed: `git diff main...story/s174-verbs-read-project-context`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 1bd723bfa6d37c5a8aa12d17b8aee8755e5fb28d

## When blocked
- Failure cause: —
- Missing: —
- Required adaptation: —
- Next action: —

## Ownership
I listed the diff with `git diff --name-only main...story/s174-verbs-read-project-context` and checked each path against the s174 `Owns` line.
- [x] Every path inside `Owns`. The `po/src/context/*` files and the rename of `po/src/state/lanes.rs` to `po/src/context/lanes.rs` fall under `po/src/context/` and `po/src/state/`. `po/src/inbox/mod.rs` falls under `po/src/inbox/`. `main.rs`, `next/mod.rs`, `run/mod.rs`, `trust/mod.rs` and `tests/verbs-read-project-context.oracle.test.sh` are listed as files. The research, plan and verif files are the story's own pipeline evidence.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. `git worktree list` shows only the main checkout and this lane.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s174-verbs-read-project-context` exits 0, so I reused the record. Under `Verification mode: record`, the record proves the unit suite (`bash tests/run.sh`, exit 0, on code equal to `Tree:` outside `docs/`). The project has no type check (`Typecheck: —`); `cargo build` inside `tests/run.sh` compiles the crate. I read the record's "Not proven here" and carried it to Not verified below.
- [x] `po-gate qa-current`: not required, because the story does not go to QA (`QA stage: —`, `Surface: —`).

## Plan
- [x] Tasks 1 to 7 are all present.
  - The `context/` module holds the moved `Warning`, `Warnings`, `Settings`, `Stage`, `BlockedBy` and readers. The landed set is renamed `Landed`.
  - `Story` gains `depends_on`, `owns` and `milestone`.
  - `Landed` reads `%H %s` in the same single `git log` and gains `commit()`.
  - In `inbox`, `pub use decision::Decision` and `read_decisions` replace `pending_ids`/`Pending`.
  - `Context::read` reads in the research's warning order.
  - The six seams take `&Context` and still return `None`.
  - `state` is composed from the context.
  - Nothing is outside the plan.
- [x] Each run interdict, checked one by one:
  - `po/Cargo.toml` and `Cargo.lock`: empty diff.
  - `record/`, `output.rs`, `inbox/add.rs`, `inbox/rewrite.rs`, `inbox/decision.rs`: empty diff.
  - In `next/`, `run/`, `trust/`: only `mod.rs` changed, and only signatures and `use` lines.
  - `tests/state-as-json.oracle.test.sh`, `tests/decision-inbox*`, `tests/answer-comes-back*`, `method/`, `docs/interface-agent.md`, `bin/`: empty diff.
  - No new git command. `Landed::read` keeps one `git log`, with only the format changed.
  - No Rust test module was added.

## References
- [x] Every import, call, API and configuration key opened and confirmed:
  - `Project::{setting, git, commit, on_target, has_local_md, method_version, name}` in `po/src/project.rs`.
  - `decision::read_dir` and the `pub` fields `Decision.{status, blocks, consumed}` at `po/src/inbox/decision.rs:49-107`.
  - `next::NextAction`/`Held`, `run::Session`/`Bounds`, `trust::Shipped`/`StateOptions`/`state_options`.
  - The crate builds with no warning.
  - `stage()` and `blocked_by()` in `po/src/context/lanes.rs` match `main` line for line apart from the `shipped`→`landed` rename. `LaneSettings` is the same block lifted out, with the same read order: `QA stage` optional, then `Max attempts`, `Merge mode`, `Ship confirmation`, then `Worktree root`. The old `framing.rs` was split into `stories.rs` and `framing.rs` with no behaviour change; the only additions are the deps/`Owns`/milestone fields.
- [x] Values that only look right: `--format=%H %s` with `split_once(' ')`, and `or_insert_with`, keep the most recent commit in git log order. The `Depends on`/`Dépend de` parse matches `po-session.sh:178-184`: the value after the first colon, then every `s<n>-<slug>`, left to right. The `Owns` parse differs from `po-bounds`; see Findings.

## Rules
- [x] `AGENTS.md` conventions respected. The code, comments and commit message are in English, and the commit has no co-author trailer.
- [x] No accepted ADR contradicted. ADR-0118 (no new dependency) holds: `Cargo.toml` and the lockfile are untouched.

## Tests
- Oracle: `po-gate oracle-intact s174-verbs-read-project-context` → exit 0
- [x] Oracle: `po-gate oracle-intact` exits 0, and the record has no `## Oracle changes` row.
- [x] Floor: `po-gate floor-guard s174-verbs-read-project-context main` exits 0, so nothing was lowered.
- [x] The assertions pin down the acceptance criteria, and none of the six empty test shapes appears. The oracle runs the real binary on throwaway repositories built by s164's fixture helpers. I checked the frozen golden independently: I cloned `main` (4c33d40, same `po/` as de387bb) under the temp dir, built its `po`, and ran this story's oracle with `PO=<main's po>`. Both tests pass, so the expected objects really are `main`'s output.
- [x] Within `Test budget`: 2 tests out of 25.
- [x] Bite 1: in `po/src/context/lanes.rs:222` I changed the condition to `false && landed.contains(id)`. Then 1 of the 2 oracle tests fails: `landed_lane_reports_ship_whatever_its_review`, with "s04-code-recorded: review instead of ship; s07-landed: execute instead of ship". I undid it with `git checkout`, and `git diff --exit-code` is clean.
- [x] Bite 2: in `po/src/context/mod.rs` I moved `read_inbox` before the lanes read. Then 1 of the 2 oracle tests fails: `state_output_does_not_move`, because `unreadable-decision` now comes before `orphan-worktree`. I undid it with `git checkout`, and `git diff --exit-code` is clean. I then rebuilt `po` from the committed code.
- [x] No test is made useless by the story.

## Neighbours
- [x] Other callers read, nothing broken. The only caller of `pending_ids` was `state/mod.rs`, and no reference is left in `po/src`, `tests`, `method`, `bin` or `docs/stories.md`. The seams' only caller is `state::compose`. `inbox::locate` and the inbox and answer verbs are unchanged. s168's `Owns` (`po/src/next/`, `tests/state-as-json.oracle.test.sh`, …) can fill its seams without touching `context/`, because `Project::setting` is reachable through `Context.project`.

## Lenses
Lenses run: none. The diff has no auth, route or upload path, no migration, and no lockfile or manifest change. `po` is a CLI with no server-side code, and the diff adds no query or call inside a loop.
- [x] No lens findings.

## Findings
- minor — po/src/context/stories.rs:141 — The `Owns` reader is looser than `po-bounds`, which `AGENTS.md` names as the matcher of `Owns` entries.
    - It reads only `- **Owns**` lines. `po-bounds.sh:170` also accepts `* **Owns**` and a space before the colon.
    - It merges every `Owns` line of a story, where `po-bounds` takes the first.
    - It keeps every backticked span, so a trailing note such as "(see `x`)" would become an entry, where `po-bounds`' `parse_owns` refuses it as unreadable.
    - All 173 `Owns` lines of `docs/stories.md` today are `- **Owns**`, so nothing is affected yet. s168 will compute `owns` holds from this field, and an overlap it computes could then differ from what `po-bounds` enforces. s168 should align the two readers, or reject what `po-bounds` rejects.
- minor — po/src/context/mod.rs:15-17 — `Story` and `Section` are not re-exported: `mod stories` is private and only `Stories` is `pub use`d.
    - Later verbs can reach their fields through `Stories.list` and `Stories.milestones`, but they cannot name the types, for example in a helper that takes `&Story`.
    - A small gap against "plus rien de cela n'est privé". It costs s168 one line in `context/`, which s168 does not own.
- minor — po/src/context/mod.rs:95 — `#[allow(dead_code)]` covers the whole `Context` struct, and the same at `:82` for `Inbox`. The plan asked for a scoped allow; this silences dead-code warnings for fields already read, such as `framing` and `warnings`. Pure tidying.

## Not verified
- The warnings and stops no fixture reaches: `no-gate`, the `QA stage` warnings, `merge-waiting`, `max-attempts`, `qa-blocked` and `root-cause-not-found`. No test covers them. I compared their code with `main` by reading only, and it is identical apart from the rename. A person can trust that comparison, or add fixtures in a later story.
- The new readers (deps, `Owns`, each story's milestone, the landed commit) have no observable output yet. I checked them by reading the code against `po-session.sh` and `po-bounds.sh` and did not run them. Their first test arrives with s168 and s170.
- `verbs_receive_one_context` is a code-structure criterion that no script reads. I judged it by reading: the context carries the root, the target and lane settings, `Project::setting` for any other setting, stories with deps, `Owns` and milestone, the landed set with commits, the current milestone, framing, lanes with path and stage, and inbox decisions with `status`, `blocks` and `consumed`. Whether it is enough is only proven once s168 to s170 build on it.
- The read-only, no-lock and under-1-second clauses rest on s164's `test_state_reads_only_files_and_git`, inside the recorded full-suite run. I did not run it here.
- I used a probe clone of `main` at /tmp/tmp.buJp4ms5po/main. `git archive` had been refused by po-bounds, and I then used the clone route the agent file sanctions for probes.

Max severity: minor
Ship allowed: yes
