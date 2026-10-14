# Research — s117-eval-reuses-login

[Story](../stories.md)

## Structuring facts
- **Assumption not holding, story to correct before any plan:** the story takes for granted that Claude Code reads a `.credentials.json` that is a symbolic link, and that the OAuth refresh "writes into the real file" through it. The installed Claude Code (`~/.local/share/claude/versions/2.1.296`, read from its embedded JS) has a credentials store, `storePath: join(<config dir>, ".credentials.json")`, that opens the file `O_RDONLY|O_NOFOLLOW` and maps `ELOOP` to `{state:"refused-symlink"}`. Its `probeCredentials()` returns `ELOOP` for any `isSymbolicLink()`, and the `readStrict` path turns `refused-symlink` into an error. That store sits behind a runtime gate (`j()&&e!==void 0`). The legacy `plaintext` store next to it reads with `readFileSync`, which follows links. So the link is refused on one path and followed on the other, and static reading cannot say which path a real `claude -p` takes.
- The write side does not prove "the link carries the refresh" either: the gated store writes through `writeCredentials` → `Ape(path, …, {mode:384, exactMode:384})`, whose body was not read (see Open questions). A write by temp file and rename would replace the link inside the temporary config and leave the real file untouched. If the refresh token rotates, the person's real login then holds a spent refresh token: the risk is a broken login on the machine, not just a failed eval.
- Today `--control` refuses to start without `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN` (`bin/po-eval:192-195`) and names the variables that are set in the announcement (`bin/po-eval:200-203`). The two temporary configs are `$ctl/config` (`bin/po-eval:128`) and `$ctl/rule-config` (`bin/po-eval:220`), both under `ctl="$(mktemp -d)"` (`bin/po-eval:217`), removed by `trap 'rm -rf "$ctl"' EXIT` (`bin/po-eval:218`).
- The login path the story names, `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`, is already computed once in `drift_check` (`bin/po-eval:65`) and by the installer (`bin/polype:30`).
- Without the symlink question, the change would be small: a link in each config after its install, a third login source in the guard and the announcement, two existing tests to amend. The blocker is the credential behaviour of Claude Code, not the size of the change.

## Story
`bin/po-eval --control` should reuse the Claude Code login already on the machine, so the eval runs on the Max subscription without `claude setup-token`.
- `arms_link_the_existing_login`: each temporary config gets a symlink `.credentials.json` → `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.credentials.json` when that file exists, never a copy. The temporary dirs are created `0700` and removed at exit, link included, and the target file does not change.
- `token_no_longer_required`: `--control` starts with no token when that login exists. With neither a login nor a token it refuses before any call and says to log in with `claude` or export a token. The announcement names where the login comes from (the file, or the variable names), never a value.
- `login_file_is_never_read_into_output`: no output and no results file holds the content of the login file.

## Current code
- `bin/po-eval:15-19` header: under `--control` the config dirs "hold no login: both arms need ANTHROPIC_API_KEY or CLAUDE_CODE_OAUTH_TOKEN".
- `control_setup` (`bin/po-eval:116-129`) copies `bin method evals` into `$dir/polype`, swaps the reuse sentence, then `CLAUDE_CONFIG_DIR="$dir/config" bash "$dir/polype/bin/polype" install --global`.
- The main flow, in order: arguments (`:156-168`), the `--list/--build` and `--model` guards (`:170-177`), case loading, `drift_check` (`:188-190`), the token guard (`:192-195`), the announcement (`:197-206`), `Continue?` (`:207-214`), then the configs are built (`:216-221`) and the arms run (`:230-251`).
- `run_arm` (`:132-148`) exports `CLAUDE_CONFIG_DIR="$config"` only for the `claude -p` subshell. stdout goes to `$out.md`, stderr to `$out.err`, under `results="$(mktemp -d)"` (`:223`). Nothing removes `results`: it is kept on purpose and printed (`:224`, `:253`).
- `grep -n credentials bin/po-eval` finds nothing today (an interdict of s116, `docs/plans/s116-eval-arms-same-environment.md:42`).

## Attachment points
- Where the login is detected: after `drift_check` (`:190`), in place of the guard at `:192-195`.
- The announcement `logins` array (`:200-203`), which would gain the file path as one more source.
- The link in each config: after `install --global`, at `:128` for the control arm and `:220` for the rule arm. Alternatively `mkdir -m 700` for each config dir before its install (see Traps on modes).

## Verified interfaces
- `mktemp -d` creates its directory mode `0700`. `$ctl/config` and `$ctl/rule-config` are created by the installer (`bin/polype:30`, `mkdir -p` at `bin/polype:155` and `:369`) under the umask, so `0755` by default. Only `$ctl` itself is `0700` today.
- `rm -rf` on a dir unlinks the symlinks inside it and never follows them, so the trap at `:218` would remove the link and leave the target untouched.
- Test harness: `rl_run` (`tests/reuse-ladder-eval.test.sh:39-46`) sets `HOME`, `TMPDIR`, `CLAUDE_CONFIG_DIR="$RLTMP/cfg"` and `RL_TOKEN` (default `ANTHROPIC_API_KEY=test`, `:7`). The fake `claude` (`:18-33`) logs `cfg=$CLAUDE_CONFIG_DIR` and the copies of the skill it can reach. A credentials fixture would go in `$RLTMP/cfg/.credentials.json`.
- On this machine `~/.claude/.credentials.json` exists (mode 0600) and `CLAUDE_CONFIG_DIR` is unset. Only its metadata was read, never its content.

## Traps
- `tests/reuse-ladder-eval.test.sh:114-120` requires the no-token refusal to contain `claude setup-token`. The new message must keep that phrase, or the test is amended (the story owns this file).
- `tests/eval-arms-same-environment.test.sh:32-35` expects `login from ANTHROPIC_API_KEY` with a token and no credentials file in `cfg`. A fixture file added in `rl_setup` for every test would change that line and how the existing tests read.
- `cfg_listing` (`tests/reuse-ladder-eval.test.sh:55`) checksums the real config dir before and after. A `.credentials.json` fixture in `cfg` gets the "target unchanged" check for free.
- The s116 interdict "`grep credentials bin/po-eval` finds nothing" stops holding: the plan must say so.
- `.claude.json`: when `CLAUDE_CONFIG_DIR` is set, Claude Code reads `<config dir>/.claude.json` (the `configPath` of the embedded code, built from `process.env.CLAUDE_CONFIG_DIR`). A temporary config has none. Whether `claude -p` starts without onboarding is not established. It cannot be tested without a paid call, and the story forbids copying the file without the person.
- No migration, no new dependency, no screen.

## Diagnostic
Not a defect story (no `Corrige` line). The symlink behaviour was read in the binary and not run. Running `claude` with a linked config could refresh and rotate the person's real login, so it was not tried. A deeper read of the binary's credential writer was then refused by this session's permission classifier.

## Open questions
1. Does a real `claude -p` (2.1.296) under `CLAUDE_CONFIG_DIR=<tmp>` follow a symlinked `.credentials.json`, or does it see `refused-symlink`? That depends on the runtime gate `j()`, which cannot be read statically.
2. When it refreshes the OAuth token, does it write in place (the link carries it) or by temp file and rename (the link is replaced, the real file goes stale while its refresh token may be spent)? `Ape`'s body was not read.
3. Two arms run one after the other with one shared login. Would a refresh by one arm invalidate the other's? It cannot happen in parallel here (`:236-245` are sequential), but it can across the rule and control configs.
4. Does `claude -p` on an empty config need `.claude.json` to skip onboarding?
5. The options the person could weigh instead, none decided here: (a) keep the link, after one manual check run by the person; (b) run the arms with `CLAUDE_CONFIG_DIR` pointing at the real config, which s116 ruled out for fairness; (c) keep `claude setup-token` (the status quo), whose token is long-lived and needs no file.

## Complexity
Story 2 → 2 for the code, provided the symlink works. Behind it is a decision about Claude Code's credential handling that touches the person's real login (security, hard to undo). It has to be settled first, by the person.

## Split
Not needed.
