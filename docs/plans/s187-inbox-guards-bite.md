---
validated: yes
---
# Plan — s187-inbox-guards-bite

[Story](../stories.md) · [Research](../research/s187-inbox-guards-bite.md)

Branch `story/s187-inbox-guards-bite`. Read `docs/research/s187-inbox-guards-bite.md` first; this plan builds on it without repeating it.

## Story
Each guard of the decision inbox gets a test that fails every time it goes (#263, #260, #329); a refusal for a path po cannot verify stops saying the path lies in the repository (#328); `output::not_built` and the contract's `not-built` go (#290); po goes 0.6.0 → 0.6.1. Criteria: `held_lock_is_refused_every_time`, `path_in_an_outside_worktree_is_refused`, `written_and_folded_paths_agree`, `unverified_path_says_so`, `not_built_is_gone`, `version_goes_up`. Lead's addition, no criterion: one implementer test for the framing guard of `Decision::stale` (#364).

Root causes (research `## Structuring facts`): the guards are right and reached by no test; the messages lose the `Place` at `kept_out_of_git`'s `bool` (`po/src/inbox/add.rs:189-198`); `not_built` has no caller.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Reason a path is not outside, by `Place` | already in this repository: `Place` (`po/src/inbox/add.rs:110-118`), which `place` already computes; one method on it | — |
| Tests' fixtures | already in this repository: `secure_fixture`/`answer`/`rec` (`tests/security-findings-stay-private.oracle.test.sh:10-44`), `fixture`/`valid`/`po_in` (`tests/decision-inbox.oracle.test.sh`) | — |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/inbox-guards-bite.oracle.test.sh` | `2315597161 6827` |

| Criterion | Test |
| --- | --- |
| `held_lock_is_refused_every_time` | `test_held_lock_is_refused_every_time` — plants `.<id>.lock`, `po answer` → exit 2 `inbox-busy`, file still pending; lock removed → answered |
| `path_in_an_outside_worktree_is_refused` | `test_path_in_an_outside_worktree_is_refused` — two plain-path contexts in a worktree outside the root → `sensitive-context-in-repo`; a context outside is accepted |
| `written_and_folded_paths_agree` | `test_written_and_folded_paths_agree` — refused, with a control context accepted |
| `unverified_path_says_so` | `test_unverified_path_says_so` — `po inbox add`, `po answer`, `po record review` on unverifiable values: codes `inbox-not-ignored`, `inbox-not-ignored`, `private-folder-unusable`, exit 1; message holds none of `.gitignore`, `in the repository`, `inside the repository` |
| `not_built_is_gone` | `test_not_built_is_gone` — `cargo build` output holds no dead-code warning. The contract half (`docs/interface-agent.md` drops `not-built`) is prose no script reads: judged in review |
| `version_goes_up` | `test_version_goes_up` — three places agree, at least 0.6.1 |

On code as it stands: the three guard tests pass (the guards are right), the last three fail. The three guard tests were run against mutants built outside the worktree: lock non-exclusive (`rewrite.rs:99` `create`), `Elsewhere` → `Outside` (`add.rs:168`), comparison off (`add.rs:130` `if true`); each failed its test, the lock one 5 runs of 5. `unverified_path_says_so` checks po's JSON output, not a method file: a binary's behaviour, which is why it is an oracle test and not a phrase test.

## Tasks
1. [x] **Messages follow the `Place`** (#328). In `po/src/inbox/add.rs`, add to `Place` a method giving why a path is not outside, `None` for `Outside`: `InRoot` "lies in the repository", `Elsewhere` "lies in another worktree of the repository", `Unverified` "could not be verified to lie outside the repository: write it without `..`" (wording free, but the `Unverified` text holds none of `.gitignore`, `in the repository`, `inside the repository`). Turn `kept_out_of_git` (`:189`) into `-> Result<(), String>`: `Ok` for `Outside` and an ignored `InRoot`; for an `InRoot` git does not ignore, today's text of `:58` (advice to `.gitignore` kept); otherwise the `Place`'s reason. `post` (`:53-62`) and `rewrite` (`rewrite.rs:48-54`) print `"<dir> <reason>"`. The sensitive check (`:39-52`): missing or relative context keeps `:49`'s text; an absolute one not outside says `"a sensitive decision needs a context outside the repository: <context> <reason>"`. `po/src/record/security.rs`: `private_folder` (`:225-227`) passes the reason to `unusable`, `check_outside` (`:233-242`) prints `"Private folder <folder> <reason>; nothing was written"`. Error codes and exits unchanged everywhere. — fails: `test_unverified_path_says_so`; existing codes held by `tests/record-review-loose-ends.test.sh:67-107`, `tests/decision-inbox.oracle.test.sh`, `tests/answer-comes-back.test.sh:118-128`.
2. [x] **Dead code out** (#290). Delete `not_built` (`po/src/output.rs:46-52`) and the stale `#[allow(dead_code)]` above `REFUSED` (`:6`; `REFUSED` is used at `add.rs:47`, `security.rs:161`). In `docs/interface-agent.md:29`, drop "un verbe pas encore construit (`not-built`),". — fails: `test_not_built_is_gone`.
3. [x] **Contract rows.** `docs/interface-agent.md:179-180` and `:197`: the refusal conditions also name a path whose place cannot be verified (e.g. "…pointe dans le dépôt ou ne se vérifie pas", "boîte dans le dépôt que git n'ignore pas, ou dont l'emplacement ne se vérifie pas"). Codes unchanged, `contract` stays 1. — judged in review (prose no script reads).
4. [x] **Implementer tests** in `tests/inbox-guards-bite.test.sh` (new): `test_inbox_in_an_outside_worktree_is_refused` — worktree outside the root, `Decision inbox` set to a folder in it, `po inbox add` → exit 1 `inbox-not-ignored`, no file written there (holds `kept_out_of_git`'s `Elsewhere` arm, `add.rs:192`, which the oracle's context test does not reach); `test_blocks_entry_not_of_story_form_is_never_stale` (#364) — through `fixture`/`valid` of `tests/decision-inbox.oracle.test.sh` sourced inside the test, a pending decision with `blocks: ["s01"]` and no `story`, a commit `s01: landed` on `main`: `po inbox` shows no `stale` key, `po state` has `stale == []`. — these are the tests; the reviewer proves by mutation that the second fails with `decision.rs:87` set to `if false` (research: mutant D marks it).
5. [x] **Version** 0.6.0 → 0.6.1: `po/Cargo.toml:3`, `po/Cargo.lock:165` (`name = "po"`), `POLYPE_VERSION` at `bin/polype:27`. — fails: `test_version_goes_up`; `bin/po-version-check` in the suite.
6. [x] **Full suite** once, through `po-run` (`Full suite: execute-end`).

## Scene viewpoints
—

## Run interdicts
- `tests/answer-comes-back.test.sh` and `tests/record-review-loose-ends.test.sh` end with an empty diff: existing tests stay green unmodified (story notes).
- `po/src/inbox/decision.rs`, `po/src/context/` and `method/hooks/` end with an empty diff: #364 is a test, not a code change.
- The lock stays `.<id>.lock` beside the decision (`rewrite.rs:57`), `LOCK_TRIES`/`LOCK_PAUSE` unchanged: the oracle plants that name.
- What `po inbox add`, `po answer` and `po record review` accept or refuse does not change for any path, nor any error code or exit (`docs/interface-agent.md` tables keep their codes).
- No file, test included, describes how to get past the path check; no comment explains why a test path is refused; test names do not describe a weakness (story notes).
- No new dependency in `po/Cargo.toml`.

## The pivot
The plan rests on the guards being right and only untested, so the work is tests plus text. Ways it could be wrong:
- A guard test passes for a reason other than its guard (fixture shape 5). Compare: each was run against its own mutant and failed (research `## Diagnostic`); the reviewer repeats the three mutations of `## Acceptance tests` plus `decision.rs:87`, and `add.rs:192` (`Elsewhere` → `true`) against task 4's first test.
- The new `Place` reason changes a code path, not just text: `kept_out_of_git` turning `Result` could flip a branch. Compare: the existing code tests listed in task 1 stay green, and `Ok`/`Err` maps exactly today's `true`/`false`.
- The held-lock test could flake on a slow machine: it only needs po to see the planted lock for ~1 s, and the planted file is never removed by po on refusal (`rewrite.rs:100`), so timing cannot make it pass wrongly.

## Files touched
`po/src/inbox/add.rs`, `po/src/inbox/rewrite.rs`, `po/src/record/security.rs`, `po/src/output.rs`, `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`, `docs/interface-agent.md`, `tests/inbox-guards-bite.oracle.test.sh` (written), `tests/inbox-guards-bite.test.sh` (new), `docs/research/`, `docs/plans/`, `docs/verif/`.

## Test strategy
Black-box through `po`, the only layer: every guard is reached by a command an agent runs. Six oracle tests plus two implementer tests: 8, within `Test budget` 25. No property test or fuzzing: the path cases are chosen to reach one guard each, and the mutation runs show they do. The bite checks (lock, `Elsewhere` in context and inbox, comparison, `decision.rs:87`) are the reviewer's (ADR-0012), each rerunning only `inbox-guards-bite*.test.sh`. Visual checks: none.

## Done when
One commit with code, tests, research, plan and record; full suite green; `cargo build` without warning; review with no open critical; issues #263, #260, #329, #328, #290 and #364 closed by the ship.
