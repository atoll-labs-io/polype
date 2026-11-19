---
validated: yes
---
# Plan — s193-ship-builds-the-landing-commit

[Story](../stories.md) · [Research](../research/s193-ship-builds-the-landing-commit.md)

Branch `story/s193-ship-builds-the-landing-commit`. Read `docs/research/s193-ship-builds-the-landing-commit.md` first; this plan builds on it without repeating it.

Track: full. The lead sent it as flow (complexity 3), and reading the code raised three escalation signals. It adds a new JSON contract to `docs/interface-agent.md` (an API contract). It needs more than six tasks. And `po` writes git state for the first time. No new ADR is needed: ADR-0130 (accepted) already settles the verb `po ship land <id>` and the second git launcher reserved to `po/src/ship/`. Reserved ADR-0131 is not used.

## Story
`po ship land <id>` runs the ship gate, Step 1's checks and the construction of the landing commit, and under `Merge mode: local` the fast-forward. It answers in JSON. `/po-ship` calls it and stops describing those operations. Criteria: `gate_comes_first`, `one_commit_no_merge`, `conflict_goes_to_a_human`, `local_mode_lands_here`, `ship_command_calls_it` (model-read), `version_goes_up`.

## The command, as the tasks fix it
`po ship land <id> [--routes yes|no] [--land]` builds; `po ship land <id> --sha <sha>` lands a commit already built (local mode only). Both run from the story worktree. Steps of the build call, in this order; each stop prints one object and writes nothing after it:

1. **Arguments.** The id is `s<n>-<slug>`. Missing or malformed → `usage` (2). `--routes` takes `yes` or `no`, at most once. `--land` and `--sha <40-hex>` are exclusive; either under `Merge mode: pr` → `usage` (2), the push being s194's.
2. **Worktree.** Inside a Polype project (`not-a-project`, 2), on `story/<id>` (`wrong-branch`, 2), as `record/mod.rs:104-133` checks.
3. **Gate.** `bash <worktree>/.polype/hooks/po-gate.sh ship-allowed <id>`, cwd the worktree. Hook missing → `no-gate` (2). Non-zero → `gate-refused` (1), `message` = the gate's stderr, trimmed.
4. **Settings.** `Target branch`, `Merge mode`, `Full suite`, `E2E stage`, `Build stage`, `Test`, `E2E`, `Build`. Missing → `missing-setting` (2); a value outside its list (research, Verified interfaces) → `unreadable-setting` (2). `Build stage: ship-if-route` without `--routes` → `usage` (2); otherwise `--routes` is ignored.
5. **Remote check.** `git remote get-url origin` read. `pr` without it → `remote-check` (1), message "a repository without a remote uses `local`". `local` with it → `remote-check` (1), message "`Merge mode: local` is only for a repository without a remote (ADR-0080); set it to `pr`."
6. **Title.** The heading `## <id> — <title>` or `### <id> — <title>` of the worktree's `docs/stories.md`. Absent → `no-title` (2).
7. **Local root.** Under `local`, the root (`Project.root`) is on `Target branch` and `git status --porcelain --untracked-files=no` prints nothing. Otherwise → `root-not-clean` (1), with what was found.
8. **Base.** `pr`: `git fetch origin` (write launcher; failure → `git-failed`, 2), then `<base>` = the full sha of `refs/remotes/origin/<Target>`. `local`: the full sha of `refs/heads/<Target>`. Missing → `no-base` (2).
9. **Probe.** `git merge-tree --write-tree --name-only --no-messages -z <base> story/<id>`. Exit 1 → `conflict` (1) with `paths`, deduplicated and in git's order. Other non-zero → `git-failed` (2).
10. **Checks**, each through `bash <worktree>/.polype/hooks/po-run.sh --story <id> --label "ship: <check>" -- '<command>'`, the child's stdout sent to `po`'s stderr:
    - unit suite: under `execute-end`, `po-gate verif-current <id>` passing → `recorded`; otherwise `<Test>` runs. Under `ship` or `both`, `<Test>` runs.
    - end to end: under `E2E stage: ship`, `<E2E>` runs verbatim; otherwise `not-at-ship`.
    - build: under `ship`, `<Build>` runs; under `ship-if-route`, it runs on `--routes yes` and is `skipped` on `no`; otherwise `not-at-ship`.

    A command set to `—` → `absent`, never replaced. Exit 0 → `passed`. The first non-zero → `check-failed` (1) with `check`, `exit` and `checks` so far, and nothing more runs. `po-run` exiting 125 → `check-unrunnable` (2).
11. **Docs commit.** `docs/reviews/<id>.md` and `docs/verif/<id>.md`, each when it exists and `git status --porcelain -- <path>` lists it, get `git add --` then `git commit -q -m "<id>: review" -- <paths>` on `story/<id>` (write launcher). `committed` is the new head, or `null` when nothing was left to commit.
12. **Landing commit.** `merge-tree` again on `story/<id>` (a conflict is handled as in 9), then `git commit-tree <tree> -p <base> -m "<id>: <title>"` → `sha`. `story/<id>` is never moved.
13. **Local landing, only with `--land`** (the effective `Ship confirmation` is `automatic`). The root is checked again as in 7, then `git -C <root> merge --ff-only <sha>` → `landed: true`. Without `--land` the call stops here, `landed: false`, with the `sha` built: under an effective `human`, `/po-ship` asks Merge / Not now now, after the checks, as today (`po-ship.md:64`). Under `pr`, always `landed: false`: the push belongs to s194.

**The landing call `--sha <sha>`** (local only), after a Merge answer: steps 1–8 as above (arguments, worktree, gate, settings, remote check, title, root, base), then the commit is checked to still be the landing of this story on the current base: `<sha>` is a commit whose only parent is `<base>`, whose subject is `<id>: <title>` and whose tree equals `merge-tree <base> story/<id>` computed now. Any difference, or a conflict now → `stale-landing` (1), nothing written: `/po-ship` calls the build again (the checks then rerun, as a rebuilt landing needs). Then the fast-forward of step 13. No check runs and no docs commit is made: `checks` is `[]`, `committed` is `null`.

Reply, exit 0: `{"contract":1,"id","mode":"pr"|"local","base","tree","sha","title","committed","checks":[{"check":"unit suite"|"end to end"|"build","outcome":"recorded"|"passed"|"absent"|"skipped"|"not-at-ship","command":<string|null>}],"landed"}`. Refusals: `{"contract":1,"error","message"}` plus `paths` (conflict) or `check`, `exit`, `checks` (check-failed). `stale-landing` is a refusal (1) of the `--sha` call only.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Write-capable git launcher `po/src/ship/git.rs` | new code | `project::git` (`po/src/project.rs:20-33`) drops the exit code and stderr and is documented read-only; ADR-0130 asks for a second launcher reserved to `po/src/ship/` |
| Gate and `po-run` runner | new code, modelled on `po/src/record/gate.rs:12-33` | `record::gate` is private (`record/mod.rs:6`), and `po/src/record/` is outside `Owns` |
| Worktree check | new code, modelled on `po/src/record/mod.rs:104-133` | `record::worktree` is private, outside `Owns` |
| Settings, project root | in repo: `Project::find`, `Project::setting` (`project.rs:38-67`) | — |
| Story title | new code, a few lines | `context::Story` has no title (`context/stories.rs:6-22`), outside `Owns` |
| JSON output | in repo: `output::reply`/`error` | — |
| Merge, commit, fast-forward | the platform: `git merge-tree`, `commit-tree`, `merge --ff-only` (ADR-0081) | — |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/ship-builds-the-landing-commit.oracle.test.sh` | `1041508211 9785` |

| Criterion | Test |
| --- | --- |
| `gate_comes_first` | `test_gate_comes_first`: refusing review under `pr`, exit 1, `gate-refused` carrying the gate's reason; every ref (origin included) and both statuses unchanged, no `docs/verif` |
| `one_commit_no_merge` | `test_one_commit_no_merge`: origin moved (docs only), local tracking ref stale; `base` = fresh origin, one parent, title `s01-a: Un titre`, code outside `docs/` = reviewed tree, base's file kept, `story/s01-a` keeps its reviewed tree, nothing sent to origin, local `main` unmoved |
| `conflict_goes_to_a_human` | `test_conflict_goes_to_a_human`: under `local`, exit 1, `conflict`, `paths == ["code.txt"]`, refs and statuses unchanged, no check ran |
| `local_mode_lands_here` | `test_local_mode_lands_here`: `--land` → `landed: true`, `main` = `sha` by fast-forward, root working copy updated, no remote; without `--land` → `landed: false`, `main` unmoved, then `--sha <that sha>` lands that very commit without rerunning the checks; a modified tracked file in the root → `root-not-clean`, nothing written |
| `ship_command_calls_it` | — model-read: judged in review (`po-ship.md` ≤ 2 300 words, `LC_ALL=C wc -w`, down from 2 700). Candidate for a `po-eval` control arm (#208) |
| `version_goes_up` | `test_version_goes_up`: the three places agree, above 0.8.0 |

## Tasks
1. [x] `po/src/ship/git.rs`: `pub(super) fn run(dir: &Path, args: &[&str]) -> Ran { code, stdout, stderr }`, `LC_ALL=C`, stdin null. Its doc comment says it is the only git launcher of `po` that writes, reserved to `po/src/ship/` (ADR-0130). In `po/src/ship/mod.rs`, dispatch on `forge` / `land`; `USAGE` names both; `po ship land` without an id → `usage`. Test: `tests/ship-reads-the-forge.test.sh:119-120` stays green; task test `test_land_refuses_outside_its_story` (wrong-branch from the root, usage without id).
2. [x] `po/src/ship/land.rs` steps 2–3 (worktree, gate, plus a gate/`po-run` runner). Test: oracle `test_gate_comes_first`.
3. [x] Steps 4–7 (settings, remote check, title, local root). Tests: task test `test_remote_check_both_ways` (`pr` without origin, `local` with origin → `remote-check`, nothing written); oracle `test_local_mode_lands_here` (second half).
4. [x] Steps 8–9 (fetch, base, probe). Test: oracle `test_conflict_goes_to_a_human`.
5. [x] Step 10 (checks). Tests: task test `test_failed_check_stops_the_ship` (`Test: false` → `check-failed`, `exit` 1, no landing commit, `story/<id>` head unchanged); task test `test_recorded_suite_is_not_rerun` (`Full suite: execute-end`, a record that passes `verif-current`, `Test: false` → exit 0, unit suite `recorded`); task test `test_route_answer_is_required` (`Build stage: ship-if-route` without `--routes` → `usage`, exit 2, nothing written; `--routes no` → build `skipped`).
6. [x] Steps 11–13, `--land`, the `--sha` landing call and the reply. Tests: oracle `test_one_commit_no_merge`, `test_local_mode_lands_here`; task test `test_review_lands_with_the_story` (`committed` non-null, `sha:docs/reviews/s01-a.md` and `sha:docs/verif/s01-a.md` exist, worktree clean afterwards); task test `test_stale_landing_is_refused` (`main` moves between the build and `--sha` → `stale-landing`, `main` unmoved; `--land` or `--sha` under `pr` → `usage`).
7. [x] Version 0.8.0 → 0.9.0 in `po/Cargo.toml`, `po/Cargo.lock` and `POLYPE_VERSION` of `bin/polype` (ADR-0122). Test: oracle `test_version_goes_up`.
8. [x] `docs/interface-agent.md`: one row after `ship forge` (`:272`) for `ship land <id> [--routes yes|no] [--land]` and `ship land <id> --sha <sha>`, giving its steps, its reply fields, its refusals by code and exit, and "writes: fetch under `pr`, the docs commit on `story/<id>`, loose objects, the fast-forward under `local` with `--land` or `--sha`; never pushes". Links: ADR-0080, ADR-0081, ADR-0130. Check: the review reads it against the code.
9. [x] `method/commands/po-ship.md`, ≤ 2 300 words.
    - Step 0 keeps `po-gate ship-allowed <id>` from the worktree and its stop line; the "Without the hook" fallback goes.
    - Step 1 becomes one call to `po ship land <id>`. It says how the model answers `--routes`: under `Build stage: ship-if-route`, the model reads `git diff --name-only <Target branch>...story/<id>` and passes `yes` when routing, a manifest or file-based routes are touched, otherwise `no`, and the finish says why the build was skipped. It names each refusal's next move: `gate-refused` → the existing "Cannot ship" line; `check-failed` → **One failure and the ship stops**, fix run; `conflict` → a human, paths listed; `remote-check` / `root-not-clean` → stop and describe. `checks`, `sha`, `tree` and `base` go to the finish. It keeps the `ci` bullet.
    - Step 2 keeps "Message and title", the sentence of `:45`, a one-sentence **Remote check** naming both rules (the phrase "`Merge mode: local` is only for a repository without a remote" stays, for `po-setup.md:67`), and the `pr` bullets, now reading `<sha>`, `<tree>` and `<base>` from the reply.
    - Local mode, where it stands today, after the checks: `- \`Ship confirmation: human\`, the effective value →` the build call (without `--land`) has run; AskUserQuestion "Land <id> on <Target branch> as one commit?", Merge / Not now; on Merge, `po ship land <id> --sha <sha>`; `stale-landing` → build again and ask again. `- \`automatic\`, the effective value →` the build call carries `--land`. Nothing is pushed.
    - The forge section and Step 3 are not touched.
10. [x] Phrase tests of `Owns` (each removal below, nothing else):
    - `tests/ship.test.sh:13` (`the **last** line starting with`), `:28` (`the single end-to-end run of the whole cycle`), `:43-44` (Step 0 `Reviewed tree:` / `':(exclude)docs'`) fall. `:29` and the order check stay.
    - `tests/session-and-gate-checks.test.sh:37` falls.
    - `tests/review-tree-gate.test.sh:62` falls.
    - `tests/ship-through-pr.test.sh:8`, `:9`, `:11` (merge-tree, commit-tree, `--ff-only`) and `:70` (`story/<id>` is never rewritten, now checked by the oracle) fall. `:54` stays.

    `tests/ship-and-fleet-cleanup.test.sh` and `tests/ship-files-the-other-findings.oracle.test.sh` are unchanged. No replacement phrase test.
11. [x] Full suite through `po-run --story s193-ship-builds-the-landing-commit --label 'full suite' -- 'bash tests/run.sh'`, then the record.

## Scene viewpoints
—

## Run interdicts
- Empty diff: `po/src/project.rs`, `po/src/record/`, `po/src/trust/`, `po/src/context/`, `po/src/ship/forge.rs`, `method/hooks/`, `method/AGENTS.md`, `method/commands/po-setup.md`, `method/commands/po-drive.md`, `.claude/`, `.polype/`, `docs/decisions/`.
- In `po-ship.md`: `## The forge's review rule` (`:24-31`) and `## Step 3` (`:67-86`) byte-identical; the `pr` push/PR/merge/checks bullets (`:57-61`) keep their commands.
- Tests outside `Owns` unchanged and green: `tests/ship-follows-forge.test.sh`, `tests/ship-resumes-cleanly.test.sh`, `tests/ship-reads-the-forge.test.sh`, `tests/ship-reads-the-forge.oracle.test.sh`.
- `grep -rn 'Command::new("git")' po/src` shows no new launcher outside `po/src/ship/git.rs`; no `push` argument anywhere in `po/src/ship/` (s194).
- No ADR written; ADR-0131 stays unused.

## The pivot
The build call does gate → checks → docs commit → landing commit, and fast-forwards only with `--land`; under an effective `human` in local mode the fast-forward is a second call, `--sha`, after `/po-ship` has asked — so the human checkpoint stays where `po-ship.md:64` puts it, after the checks (lead's revision). Ways it could be wrong:
- **The `--sha` call lands a commit that no longer matches.** Its guard is: gate again, clean root, only parent = current base, subject, tree = a fresh `merge-tree`. Compare with ADR-0081 (the landing commit is exactly `merge-tree <base> story/<id>` on `<base>`); a `story/<id>` commit added after the build changes the tree outside `docs/` only if it changes code, which the gate then refuses.
- **The model passes `--land` under `human`.** `po` cannot see the effective value; `/po-ship` decides it from `po ship forge`. The review reads that `po-ship.md` passes `--land` only under `automatic`.
- **The `po-run` rows committed on `story/<id>`.** `verif-current` compares code outside `docs/` (`po-gate.sh:134-148`), so it stays true. Check that the committed record does not make `po next` read the lane differently (`po/src/context/lanes.rs:204-270`).
- **`<E2E>` runs verbatim**, with `E2E scope` and `E2E browsers` left to the project's command. Compare with `po-ship.md:36`.
- Also check that the conflict probe runs before any check, so nothing is written on a conflict except the fetch in `pr` mode.

## Files touched
`po/src/ship/mod.rs`, `po/src/ship/land.rs` (new), `po/src/ship/git.rs` (new), `po/src/main.rs` (usage only, if needed), `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`, `docs/interface-agent.md`, `method/commands/po-ship.md`, `tests/ship-builds-the-landing-commit.oracle.test.sh` (written), `tests/ship-builds-the-landing-commit.test.sh` (new, sources the oracle's fixtures), `tests/ship.test.sh`, `tests/session-and-gate-checks.test.sh`, `tests/review-tree-gate.test.sh`, `tests/ship-through-pr.test.sh`.

## Test strategy
- Automated: 5 oracle tests and 8 task tests (named in tasks 1, 3, 5, 6), 13 in all, within `Test budget: 25`. They exercise the built binary on throwaway repositories under `mktemp -d`. The only remote is a local bare repository, no forge is called, and checks are `true`/`false`. One layer: `po`'s command. The gate and `po-run` are the real hooks copied from `method/hooks/`, never mocked.
- No phrase test replaces those that fall (owner's rule, 2026-11-13). `ship_command_calls_it` is judged in review.
- Visual checks: none.

## Done when
The full suite is green through `po-run`, the record is complete, and the review has no open critical. `po-ship.md` is ≤ 2 300 words and the version is 0.9.0 in all three places. It ships as one commit `s193-ship-builds-the-landing-commit: Le commit d'atterrissage d'une story est construit par une commande`.
