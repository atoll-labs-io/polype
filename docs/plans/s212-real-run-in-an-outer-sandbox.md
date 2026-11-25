---
validated: no
---
# Plan — s212-real-run-in-an-outer-sandbox

[Story](../stories.md) · [Research](../research/s212-real-run-in-an-outer-sandbox.md)

Branch `story/s212-real-run-in-an-outer-sandbox`. Read `docs/research/s212-real-run-in-an-outer-sandbox.md` first; this plan builds on it without repeating it.

Technical choice: waiting for a human

The tool and the network policy are drafted in [ADR-0139](../decisions/ADR-0139-chaque-session-d-un-passage-reel-tourne-dans-un-bac-a-sable-du-systeme.md) (`status: proposed`), ranked A `bwrap` with the host's network, B `sandbox-runtime` limited to `api.anthropic.com`, C `podman`. The tasks below are written for **A**. Another answer rewrites tasks 2 to 6 and the oracle (B: `srt` and its settings file in place of the bwrap arguments, `allowGitConfig`, Node and ripgrep in CI; C: a Containerfile and `podman run`).

## Story
Each `claude -p` session of a real run runs inside a system sandbox that the launcher sets up: it writes only in its run folder, the network is what ADR-0139 fixes, and with the tool missing no paid session starts and the command names it. Inside, Claude Code's sandbox, the git exception and the allow list are gone, and nothing prompts. The suite proves, with a fake `claude` launched by the real launcher, that a session can neither write outside its run folder nor read the person's login beyond what it is handed. ADR-0139 replaces ADR-0137 and ADR-0138 once the owner has chosen. The fifth run's record lands as the run wrote it.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| The bwrap arguments around the `exec` of `claude-print` (~25 lines) | new code, on the platform tool `bwrap`, already required (`evals/real/lib.sh:906`) | nothing in the repository wraps a process; bwrap is the platform rung and takes no wrapper library |
| Handing the person's `HOME`, config, the run folder and `bwrap`'s path to `claude-print` | already in the repository: the launcher's `REAL_*` assignments (`evals/real/lib.sh:565-570`) | — |
| The suite's pass-through `bwrap` stub (a few lines) | new code in a test fixture, replacing the presence stub (`tests/real-run-before-a-release.oracle.test.sh:10-16`) | the real bwrap would confine the doubles that report through `$RTMP/calls`; a stub that exits 0 never runs them |
| Settings, tool check, CI step, docs | changes to existing code and files | — |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/real-run-in-an-outer-sandbox.oracle.test.sh` | `2165325648 7103` |

| Criterion | Test |
| --- | --- |
| `outer_sandbox_confines_the_session` | `test_outer_sandbox_confines_the_session`: no bwrap → exit 2 naming it, before `Continue?`, no call; with the real bwrap, the double's pid 1 is `bwrap` and it writes in its run folder. The network part is judged in review against ADR-0139: under A the ADR leaves the host's network, nothing to test. |
| `claude_code_checks_off_inside` | `test_claude_code_checks_off_inside`: no `sandbox` key, no allow list, no `Bash(…)` rule; the session's arguments carry `bypassPermissions` and `--permission-prompts none`. |
| `escape_is_tested` | `test_escape_is_tested`: writes outside the run folder and into the person's `HOME` refused and absent on disk, both login files unreadable, the handed login present, no login file in the kept results. |
| `tool_is_the_owners_choice` | — judged in review: the owner's answer recorded in ADR-0139, then ADR-0137 and ADR-0138 point to it. |
| `records_are_landed` | — judged in review: `cksum < docs/evals/real-2026-11-25-v0.13.0.md` prints `938200201 1048`. |

The three oracle tests need the real `bwrap` and fail, naming it, where it is missing; they fail today for the right reasons (sandbox still configured, pid 1 `systemd`, writes outside done), checked when the file was written.

## Tasks
1. [ ] **Land the fifth run's record.** Copy `/home/lecrabe/.claude/jobs/c268121d/tmp/records/real-2026-11-25-v0.13.0.md` to `docs/evals/real-2026-11-25-v0.13.0.md`, byte for byte (`cp`, no editor). Check: `cksum` prints `938200201 1048`; the reviewer compares.
2. [ ] **Claude Code checks nothing inside.** `real_permissions` (`evals/real/lib.sh:115-123`) prints `{autoMemoryEnabled: false, permissions: {deny: ["WebFetch", "WebSearch"]}}`: no `sandbox`, no `allow`, no `Bash(…)` rule (the `curl` and `claude` doubles stay on `PATH`). `claude-print:23` adds `--permission-mode bypassPermissions` and keeps `--permission-prompts none`. Rewrite the comment above `real_permissions` (`lib.sh:107-114`) to say this and name ADR-0139. Test: `test_claude_code_checks_off_inside`.
3. [ ] **The outer sandbox.** `real_launcher` (`lib.sh:565-570`) also writes, as `%q` assignments, `REAL_SANDBOX` (bwrap's path), `REAL_RUN`, `REAL_PERSON_HOME` (`$HOME` as `po-eval` got it), `REAL_PERSON_CONFIG` (`${CLAUDE_CONFIG_DIR:-$HOME/.claude}`, read before `real_env` replaces it), `REAL_TMP`, `REAL_POLYPE` (`$POLYPE_ROOT`) and `REAL_KEEP_PATH` (`$REAL_RUN_PATH`); `export -n` them at `lib.sh:959`. `claude-print` refuses when one is empty, then execs `"$REAL_SANDBOX"` with, in this order: `--ro-bind / /`, `--dev /dev`, `--proc /proc`; `--tmpfs` over the person's `HOME`, the person's config, `/run/user/$(id -u)` and `REAL_TMP`, each only when it exists; `--ro-bind` back the directory of `realpath "$REAL_CLAUDE"`, `REAL_POLYPE`, and each folder of `REAL_KEEP_PATH` lying under a hidden one; `--bind "$REAL_RUN" "$REAL_RUN"` last; `--unshare-pid --die-with-parent --new-session`; `--unsetenv` for `DBUS_SESSION_BUS_ADDRESS`, `SSH_AUTH_SOCK` and `XDG_RUNTIME_DIR`; then `--` and the existing `env -u … "$claude" "${args[@]}"`, stdin, stdout and stderr still opened by `claude-print` on the host. Rewrite `claude-print`'s header to say what is hidden and what is not (its own login in the environment, the real binary by full path, the host's network). Tests: `test_outer_sandbox_confines_the_session`, `test_escape_is_tested`.
4. [ ] **No tool, no session.** In `real_main` (`lib.sh:904-913`), on every system, `bwrap` missing from `REAL_RUN_PATH` → `po-eval: a real run needs its outer sandbox: bwrap not found on PATH; nothing run`, exit 2, before the confirmation; keep its path for task 3. `socat` is no longer required; drop it from `real_path_spares` (`lib.sh:92`). The announcement (`lib.sh:925`) becomes `permissions: each session inside bwrap (writes held to its run folder, the person's HOME and config hidden, the host's network), Claude Code's checks bypassed, prompts denied — for a person who watches this run`. Test: first half of `test_outer_sandbox_confines_the_session`.
5. [ ] **The suite follows.** Each change below changes the clause its test checks, and says so in the verification record:
   - `tests/real-run-before-a-release.oracle.test.sh:10-16`: the `bwrap` stub skips its options up to `--` and `exec`s the rest; the `socat` stub goes. Comment: launches through this stub are not confined; the oracle of s212 proves confinement with the real bwrap.
   - `tests/real-run-before-a-release.test.sh`: line 67 checks that `WebFetch` and `WebSearch` are denied; `lead_double`'s `allowed()` (`:406-416`) allows a command when the session's arguments carry `bypassPermissions` and no `Bash(<word>:*)` deny names it.
   - `tests/real-run-in-the-sandbox.oracle.test.sh`: remove `test_sandbox_governs_bash` (its clauses move to the s212 oracle); keep the three others; header names ADR-0139.
   - `tests/git-runs-outside-the-sandbox.oracle.test.sh`: remove `test_git_runs_outside_the_sandbox`; keep `test_mask_list_is_not_governing`, since the global ignore of `real_env` stays.
   - `tests/real-run-is-usable.oracle.test.sh`: `test_law4_commands_are_allowed` checks the two web denies instead of `curl` and `claude`.
   Test: `bash tests/run.sh` on these four files and the oracle.
6. [ ] **CI has the tool.** `.github/workflows/ci.yml`: one step before `bin/po-ci` that installs `bubblewrap` with `apt-get` (root or `sudo`, as the `jq` step does) and, when `/proc/sys/kernel/apparmor_restrict_unprivileged_userns` exists, sets it to 0. Check: the PR's CI shows the three oracle tests `ok`; a `bwrap` failure there names the userns restriction.
7. [ ] **Docs and ADRs.** `docs/evals/real-run.md` (`:25-36`): rewrite "Ce qui confine un passage" and "La limite" for ADR-0139 — the outer sandbox, what is hidden, what the session still reaches (its own login, the real `claude`, the host's network), Claude Code's checks off, `bwrap` required on every system, real runs Linux-only, the Claude Code sandbox case no longer tested; drop `socat`. Once the owner's answer has made ADR-0139 `accepted`: set `superseded-by: [ADR-0139]` and `status: superseded` in ADR-0137 and ADR-0138, frontmatter only. Check: review.

## Scene viewpoints
—

## Run interdicts
- `po/`, `method/`, `.claude/`, `.polype/`: empty diff.
- `evals/real/grade.sh`, `evals/real/cases/`, `evals/real/seeds/`, `real_governing` and `real_session_held` (`lib.sh:187-361`), and the global ignore of `real_env` (`lib.sh:64-67`): empty diff.
- The bodies of ADR-0134 to ADR-0138: unchanged; only the frontmatter of ADR-0137 and ADR-0138, as task 7 says.
- `docs/evals/real-2026-11-25-v0.13.0.md` sums to `938200201 1048`; `tests/real-run-in-an-outer-sandbox.oracle.test.sh` to `2165325648 7103`.
- Nothing of `/tmp/po-eval-results.*` enters the repository, and no file under `docs/` quotes a transcript.
- No paid run: never `bin/po-eval real` without a claude double first on `PATH`; `test_suite_never_pays` stays green.
- No other test file than those task 5 names changes.

## The pivot
Everything rests on moving the whole confinement from Claude Code to a `bwrap` the launcher builds, the session running `bypassPermissions` with the host's network. Ways it could be wrong:
1. **Claude Code still asks inside.** If 2.1.33x keeps some protected paths (`.git`, `.claude`) under prompt even in `bypassPermissions`, `--permission-prompts none` denies them and a real run shows `permission_denied` again. Compare: the next real run's stream (`grep -c 'has been denied'`), against the fifth run's.
2. **A hidden path the session needs.** The real `claude` under `~/.local`, a `PATH` folder under `HOME`, the doubles read from the checkout: a missing bind breaks the session before its first event. Compare: the oracle's launch covers the doubles and `REAL_TMP`; only a real run on the owner's machine covers `~/.local/share/claude`. The reviewer removes one `--ro-bind` back and reruns the oracle.
3. **The pass-through stub hides a regression.** Old launch tests no longer confine anything, so confinement rests on the three oracle tests alone. The reviewer drops `--tmpfs` over the person's `HOME`, then the `REAL_RUN` bind, and reruns only the oracle file: `test_escape_is_tested` must fail on the first, every launch on the second.
4. **The owner picks B or C.** Then tasks 2 to 6 and the oracle are rewritten by `/po-plan`; under B, the research's table shows which of #495 and #517 come back.

## Files touched
`evals/real/claude-print`, `evals/real/lib.sh`, `docs/evals/real-2026-11-25-v0.13.0.md` (new), `docs/evals/real-run.md`, `docs/decisions/ADR-0139-…md` (new, drafted here), `docs/decisions/ADR-0137-…md` and `ADR-0138-…md` (frontmatter), `.github/workflows/ci.yml`, `tests/real-run-in-an-outer-sandbox.oracle.test.sh` (new, written here), `tests/real-run-before-a-release.oracle.test.sh`, `tests/real-run-before-a-release.test.sh`, `tests/real-run-in-the-sandbox.oracle.test.sh`, `tests/git-runs-outside-the-sandbox.oracle.test.sh`, `tests/real-run-is-usable.oracle.test.sh`. All inside the story's `Owns`.

## Test strategy
- **Automated**: the three oracle tests, at the launcher's layer, through `bin/po-eval real` with a claude double and the real `bwrap` — the only layer where the wrapping exists. No new task test: task 5 changes existing tests whose clause changes, and removes two whose clauses move to the oracle. Net count well under `Test budget` (25).
- The rule each oracle test names would fail if removed: drop the wrapper → pid 1 `systemd`, writes done; drop `bypassPermissions` → args check fails; drop a `--tmpfs` → a login file is read.
- `Full suite`: `po-run --story s212-real-run-in-an-outer-sandbox --label 'Unit suite' -- 'bash tests/run.sh'`, once, at the end. No type check (`Typecheck: —`).
- **Judged by reading**: the network part of `outer_sandbox_confines_the_session` under ADR-0139; `tool_is_the_owners_choice`; `records_are_landed` (one `cksum`).
- **Seen only on a real run**, listed for the owner, not testable here: Claude Code's behaviour in `bypassPermissions`, and whether the session starts with the person's real `claude` bound back.

## Done when
- The owner has answered ADR-0139, the ADR is `accepted`, and the tasks match the chosen option.
- One commit on `story/s212-real-run-in-an-outer-sandbox` landed through a pull request whose description says what, why and how to check.
- Full suite green locally and in CI, the three oracle tests `ok` (not skipped) in CI.
- A review with no open critical finding.
