# Research — s212-real-run-in-an-outer-sandbox

[Story](../stories.md)

## Structuring facts
- **The wrapping point is one line**: every paid session is `exec env -u … "$claude" "${args[@]}"` in `evals/real/claude-print:26-27`, run on the host by the launcher `real_launcher` writes (`evals/real/lib.sh:565-570`). The outer sandbox goes there; `po`, the launcher, the grade and `real_governing` stay outside it.
- **Assumption corrected — `sandbox-runtime` brings the masks back by itself.** srt 0.0.83 applies, whatever its config says, the same mandatory write denies as Claude Code's sandbox: `.git/config`, `.git/hooks`, `.gitconfig`, `.gitmodules`, shell rc files, `.mcp.json`, `.vscode`, `.idea`, `.claude/commands`, `.claude/agents` (`dist/sandbox/sandbox-utils.js:12-38` of the npm tarball, README "Mandatory Deny Paths"). Only `filesystem.allowGitConfig` (lifts `.git/config`) or `filesystem.disabled` (drops every filesystem rule) change that. So srt alone does not make #495 and #517 go away.
- **Assumption incomplete — installing `bwrap` in CI may not be enough.** `ubuntu-latest` is Ubuntu 24.04, whose AppArmor restricts unprivileged user namespaces; bwrap then fails unless the workflow lifts `kernel.apparmor_restrict_unprivileged_userns`. Not verified on a runner: the PR's CI run shows it.
- **Every existing launch test stops playing its double once the session is wrapped**: the suite puts presence stubs `bwrap` and `socat` that `exit 0` first on `PATH` (`tests/real-run-before-a-release.oracle.test.sh:10-16`). A wrapped exec would run the stub and nothing else; the stub has to run what follows `--`.
- The confinement Claude Code does today is five keys and eight rules in `real_permissions` (`evals/real/lib.sh:115-123`); two oracle files of s208 and s209 pin them (`tests/real-run-in-the-sandbox.oracle.test.sh:11-14`, `tests/git-runs-outside-the-sandbox.oracle.test.sh:34-46`).

## Story
Each `claude -p` session of a real run runs inside a system sandbox that the launcher sets up, and Claude Code checks nothing inside it: no Claude Code sandbox, no git exception, no allow list, no prompt. The tool and the network policy are the owner's choice (ADR-0139, proposed). Criteria: `outer_sandbox_confines_the_session`, `claude_code_checks_off_inside`, `escape_is_tested` (tests); `tool_is_the_owners_choice`, `records_are_landed` (review).

## Current code
- `bin/po-eval:199-205` hands `po-eval real` to `real_main` (`evals/real/lib.sh:846-977`).
- `real_main` refuses on Linux when `bwrap` or `socat` is missing from the run's `PATH`, before the confirmation (`lib.sh:904-913`), and announces `permissions: Claude Code sandbox (git outside it), prompts denied` (`lib.sh:925`).
- `real_one` builds the run folder `$REAL_RUN` under `REAL_TMP` (`${TMPDIR:-/tmp}`, `lib.sh:939-940`), writes the launcher, builds the case, holds the governing signatures, checks `bounds: held`, launches (`lib.sh:538-561`).
- `real_env` (`lib.sh:54-73`): `HOME`, `TMPDIR`, `CLAUDE_CONFIG_DIR` inside the run folder; doubles linked from `$REAL/doubles` (`lib.sh:58-59`), i.e. from the Polype checkout; the gh double reads `tests/journey/doubles/gh` of that checkout (`evals/real/doubles/gh:15-16`). A global git ignore hides the Claude Code sandbox's masks (`lib.sh:64-67`).
- `real_permissions` (`lib.sh:115-123`): allow `Read`/`Edit` of the run folder, `Agent`, `Bash(git *)`; deny `WebFetch`, `WebSearch`, `Bash(curl:*)`, `Bash(claude:*)` and four git `-c`/`--config-env` rules; `sandbox` with `enabled`, `autoAllowBashIfSandboxed`, `failIfUnavailable`, `excludedCommands: ["git"]`, `filesystem.allowWrite`.
- `claude-print:23` passes `--permission-prompts none`; nothing passes a permission mode.
- `real_governing` (`lib.sh:196-228`) and `real_session_held` (`lib.sh:343-361`) compare what governs a session after each one; independent of the sandbox.
- `.github/workflows/ci.yml` installs only `jq`, then runs `bin/po-ci`.

## Attachment points
- `evals/real/claude-print:23-27`: the permission flag and the sandbox wrapper.
- `evals/real/lib.sh:565-570` (`real_launcher`): what the wrapper needs from the host (run folder, the person's `HOME` and `CLAUDE_CONFIG_DIR`, the checkout, the sandbox tool's path), handed as the existing `REAL_*` values are, never through the run's environment.
- `evals/real/lib.sh:115-123` (`real_permissions`), `:904-913` (tool check), `:925` (announcement).
- `.github/workflows/ci.yml`: one step installing the tool.
- `docs/evals/real-run.md:25-36` ("Ce qui confine un passage", "La limite").

## Verified interfaces
- `bwrap` 0.13.1 at `/usr/bin/bwrap`; `socat`, `podman` 6.2.0 and `pasta` installed; `srt` not installed; `node` and `npm` present; Claude Code 2.1.332 at `~/.local/bin/claude`.
- `bwrap --ro-bind / / --dev /dev --proc /proc --tmpfs "$HOME" --unshare-pid --die-with-parent --new-session -- sh -c …`, run here: `$HOME` reads empty, a write to `/tmp` is refused (read-only filesystem), `/proc/1/comm` reads `bwrap` (outside: `systemd`).
- `claude --help` (2.1.332, no session started): `--permission-mode` takes `bypassPermissions`; `--dangerously-skip-permissions` says "Recommended only for sandboxes with no internet access"; `--permission-prompts none` denies anything that would prompt, "the permission mode still decides everything else".
- `@anthropic-ai/sandbox-runtime` 0.0.83, Apache-2.0, "Beta Research Preview", Node ≥ 22.12, CLI `srt [--settings f] [--] cmd…` with arguments shell-quoted (`dist/cli.js:268-278, 456`); Linux: bwrap with `--unshare-net`, HTTP and SOCKS proxies on the host behind Unix sockets, `allowedDomains` allow-only, reads allowed everywhere unless `denyRead`, Unix sockets blocked by seccomp, ripgrep needed for the mandatory-deny scan. Read from the npm tarball, never run.
- No agent of `method/agents/` sets `permissionMode` (grep): subagents inherit the session's mode.
- The fifth run's record: `/home/lecrabe/.claude/jobs/c268121d/tmp/records/real-2026-11-25-v0.13.0.md`, `cksum` `938200201 1048`, verified.

## The seven obstacles of the five runs
| Obstacle | Under bwrap with Claude Code's checks off | Under srt |
| --- | --- | --- |
| Command list (#476, ADR-0136) | gone | gone |
| `cd` + `git`, redirections | gone: no rule matches a command | gone |
| `.git` protected (#495) | gone: nothing masked | stays unless `allowGitConfig`; `.git/hooks` stays read-only |
| git exception lets programs out (d-0062, d-0063, #502) | gone: git runs inside like the rest | gone |
| Compound commands kept in the sandbox (#508) | gone | gone |
| Verification record refused (#516) | gone if a permission layer refused it, which bypass removes; cause never established | same |
| Mask taken for a rule change (#517) | the masks are gone; the empty kept pair stays (`lib.sh:351-355` copies only files and links) | masks fixed at wrap time from the root, under the global ignore; empty pair stays |

What stays whatever the option: a session can still rewrite what governs the next one (`real_governing` keeps invalidating); it reads its own login from its environment; the real `claude` binary must be readable inside to run, so a nested paid session by full path stays possible (ADR-0134 accepted that reach); WebSearch runs on Anthropic's side, so only a deny rule stops it, never a network policy.

## Traps
- **Hiding the person's login**: `HOME` and the person's `CLAUDE_CONFIG_DIR` (outside `HOME` in the suite: `$RTMP/cfg`) must be hidden, then the real `claude` binary, the doubles (`$REAL/doubles`, `tests/journey/doubles`) and any `PATH` folder the run keeps under `HOME` bound back read-only. `/run/user/<uid>` holds the keyring and D-Bus sockets; `/proc` of the host shows other processes' environment unless `--unshare-pid`. With the host's network shared, abstract Unix sockets stay reachable.
- **The results folder** (mode 700, same user) and earlier runs' `/tmp/po-eval-results.*` are readable by a session unless `REAL_TMP` is hidden; the stream reaches the results only through the file descriptors `claude-print` opens on the host (`claude-print:27`).
- Tests that pin the old settings must change, with their clause: `tests/real-run-in-the-sandbox.oracle.test.sh:7-36`, `tests/git-runs-outside-the-sandbox.oracle.test.sh:29-47`, `tests/real-run-is-usable.oracle.test.sh:56-61`, `tests/real-run-before-a-release.test.sh:67-68` and the `allowed()` of `lead_double` (`:406-416`), which reads the `sandbox` keys to decide that `gh` runs.
- Doubles that write `$FAKE_CALLS` (`$RTMP/calls`) would be refused inside a real sandbox; the oracle's double reports through its stream, kept by `--keep`.
- `test_suite_never_pays` (`tests/real-run-before-a-release.oracle.test.sh:170-187`) requires any file launching `po-eval` to carry its own `/bin/claude"` double.
- Story touches no `po/` and no `method/`: no version bump (ADR-0122).
- ADR-0137 and ADR-0138 are accepted: only their frontmatter (`superseded-by`, `status`) changes, once ADR-0139 is accepted.

## Open questions
- The tool and the network policy (ADR-0139): the owner's.
- Whether Claude Code 2.1.33x in `bypassPermissions` still prompts for some protected paths (`.git`, `.claude`), then denied by `--permission-prompts none`: only a real run shows it.
- Under srt: whether Claude Code honours the `HTTPS_PROXY` srt sets, which hosts besides `api.anthropic.com` it needs (telemetry can be cut by `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`), and whether `allowGitConfig` also frees `.git/config.lock`. Not verified: no paid session was started.
- Whether WebFetch and WebSearch stay denied (the plan keeps them; see its pivot).

## Complexity
4 → 4. One exec to wrap and one settings function to shrink, but five existing test files pin the old shape, the suite's presence stubs must become pass-through, CI needs a privileged step, and the escape proof needs the real tool.

## Split
Not needed at 4.
