# Research — s209-git-runs-outside-the-sandbox

[Story](../stories.md)

## Structuring facts
- No story assumption is false. The note's "`real_env` writes it (`evals/real/lib.sh:64-67`) and s208's list compares it" holds: `real_env` writes `$J/home/.config/git/ignore` (`evals/real/lib.sh:65-67`) and `real_governing` lists `./.config/git/*` under `HOME` (`evals/real/lib.sh:204`).
- Reproduced without paying: the oracle's double appends one line to `$XDG_CONFIG_HOME/git/ignore` and the run ends `invalid — session 1 changed what a session runs under (home/.config/git/ignore)`, the third real run's exact line (`/tmp/po-eval-results.Ia896K/journey.1.invalid`). In that run's stream, no tool call of the lead wrote the file: the lead's five commands are `po next`, reads, `git worktree add`, `git branch -d`. So the writer is Claude Code itself or its sandbox, never a model action.
- The run's settings are one `jq` object in `real_permissions` (`evals/real/lib.sh:113-120`): no `excludedCommands`, no `Bash(...)` in `allow`. Git's exclusion and its `Bash(git *)` rule both go there.
- An invalid run keeps nothing of the change today: `real_session_held` (`evals/real/lib.sh:306-317`) writes one line to `$REAL_OUT.invalid`, and the run folder is removed by `real_drop_run` (`:649-651`) right after the grade. `REAL_GOVERNING` holds `cksum` signatures only (`:504`), never content, so "before" must be copied at the moment the signatures are taken.
- s208's oracle pins two clauses this story changes: no `Bash` rule in `allow` (`tests/real-run-in-the-sandbox.oracle.test.sh:13-14`) and a `.config/git/ignore` append that must read as governing (`:86`). Both files are in `Owns`.

## Story
git alone leaves the real run's sandbox and is allowed by `Bash(git *)`; an entry Claude Code adds to git's global ignore no longer invalidates a run; an invalid run keeps the changed governing file, before and after, scrubbed; the 2026-11-24 record and the second 2026-11-23 record land as written (#494, #495; owner's choice of 2026-11-24, option a).
- `git_runs_outside_the_sandbox` — `sandbox.excludedCommands` is `git` alone, `Bash(git *)` allows it, sandbox still on, deny list unchanged, a new ADR replaces ADR-0137 on this point.
- `mask_list_is_not_governing` — an addition to the global ignore does not invalidate; masks stay out of `git status`; an invalid run keeps the changed file, before and after, scrubbed as `po-intake` scrubs.
- `records_are_landed` — judged in review.

## Current code
- `real_env` (`evals/real/lib.sh:54-73`) exports `HOME=$J/home`, `XDG_CONFIG_HOME=$J/home/.config`, `GIT_CONFIG_GLOBAL=$J/home/.gitconfig`, `GIT_CONFIG_NOSYSTEM=1`, `GIT_ALLOW_PROTOCOL=file` (`:69-72`), and writes the twelve mask patterns to `$J/home/.config/git/ignore` (`:64-67`). With `GIT_CONFIG_GLOBAL` set, git still reads `$XDG_CONFIG_HOME/git/ignore` as the default `core.excludesFile` (nothing sets that key).
- `real_permissions` (`:113-120`): `allow: [Read(/$run/**), Edit(/$run/**), Agent]`, `deny: [WebFetch, WebSearch, Bash(curl:*), Bash(claude:*)]`, `sandbox: {enabled, autoAllowBashIfSandboxed, failIfUnavailable, filesystem: {allowWrite: [$run]}}`.
- `real_governing` (`:191-223`): one signature line per governing file, each line's first field a label path — `config/…`, `config/projects/…`, `config/.claude.json`, `home/…`, `home/.claude.json`, `bin/…`, `gh/…`, `git-config` (key lines of `$R/.git/config`), `git-hooks/…`, `origin-config`, `origin-hooks/…`, `run/…`, `worktrees/…`, `above:<absolute path>`, `project/…`, `worktree/<rel>/<path>` (a lane's file differing from the root's).
- `real_session_held` (`:306-317`): diffs `REAL_GOVERNING` against a fresh `real_governing`, takes the first changed label path (`sed -n 's/^[<>] \([^ ]*\).*/\1/p' | head -n 1`), writes `session $n changed what a session runs under (<path>)` to `$REAL_OUT.invalid`, returns 1. `real_launch` (`:320-343`) calls it in the drive loop and once more at the end (`:342`), so on an invalid run it runs twice.
- `real_one` (`:492-514`): `REAL_RUN` under `REAL_TMP`, `REAL_OUT="$REAL_RESULTS/$case.$n<suffix>"`, then in a `set -e` subshell `real_env`, `real_build_case`, `REAL_GOVERNING="$(real_governing)"` (`:504`), bounds, launch, grade; then `real_drop_run`.
- `real_scrub <dir>` (`:622-647`) rewrites every file under a folder with `po-gate redact` and the secret-named environment values replaced by `[redacted]`, "as `method/hooks/po-intake.sh:81-103` does". `real_finish` (`:653-659`) runs it on `REAL_RESULTS` under `--keep`, otherwise removes the folder.
- `REAL_WORK` (`:903`) is the launcher's own folder under the caller's `TMPDIR`, outside every run folder, removed at exit (`:655`); it already holds each run's launcher script (`:498`).

## Attachment points
- `real_permissions` (`:113-120`): `"Bash(git *)"` in `allow`, `excludedCommands: ["git"]` in `sandbox`.
- `real_governing`, `HOME` selection (`:200-204`): `./.config/git/*` stays, `./.config/git/ignore` leaves it.
- `real_one` (`:504`): where the governing files' content must be copied, beside the signatures.
- `real_session_held` (`:310-314`): where the kept pair is written, under `$REAL_OUT.changed/`.
- `docs/evals/real-run.md:16` (`--keep`), `:28` (what confines a run), `:35` (the limit, the governing lists).
- `docs/decisions/ADR-0137-…md` frontmatter: `superseded-by: [ADR-0138]`, status stays `accepted` (replaced in part; `templates/adr.md`, status comment).

## Verified interfaces
- `sandbox.excludedCommands` — Claude Code settings key, a list of command names that run outside the sandbox and go through the normal permission path (story note, https://code.claude.com/docs/en/sandboxing). With `--permission-prompts none` (`evals/real/claude-print:23`), a command that is not allowed is refused: hence the `Bash(git *)` rule, written as the story writes it.
- `real_run y <args>` (`tests/real-run-before-a-release.oracle.test.sh:71-90`): launches `po-eval real` on a pseudo-terminal with the claude double first on `PATH` and `ANTHROPIC_API_KEY=$SENTINEL`; the double receives the run's environment (`HOME`, `XDG_CONFIG_HOME`, `CLAUDE_CONFIG_DIR`, the login) and its stdout becomes `<REAL_OUT>.session<n>.jsonl` (`evals/real/claude-print:26-27`).
- `real_session_fault` (`evals/real/grade.sh:24-31`) accepts a session whose last `result` has no error and a `success` or missing subtype.
- `po-gate redact` knows `sk-ant-[A-Za-z0-9_-]+` (`method/hooks/po-gate.sh:243`): the oracle's sentinel `sk-ant-sentinel-s206-…` is erased.
- The two records: `/home/lecrabe/.claude/jobs/c268121d/tmp/records/real-2026-11-24-v0.12.0.md` (`cksum` `776923962 984`, byte-identical to the untracked copy at the main checkout's `docs/evals/`) and `…/real-2026-11-23-v0.12.0-2.md` (`2639938192 1077`). `-2` is the name `real_record` gives a day's second record (`evals/real/lib.sh:684-692`).

## Traps
- **Do not move the mask list behind `core.excludesFile`** (#494's first option). If Claude Code writes `$XDG_CONFIG_HOME/git/ignore` without asking git where the global ignore is, git would no longer read that file and the file would still be compared: the run stays invalid. Dropping only that file from the list holds whoever writes it.
- **Only `ignore` leaves `.config/git/`.** `$XDG_CONFIG_HOME/git/attributes` is still read by git with `GIT_CONFIG_GLOBAL` set, and a filter it names runs a program: keep the rest of `.config/git/*` compared.
- **The kept pair is written once.** `real_session_held` runs twice on an invalid drive run (`:326`, `:342`); the second call must not overwrite what the first kept.
- **"Before" lives out of the session's reach, and decides nothing.** The validity decision stays on the in-memory signatures; the content copy goes to `REAL_WORK`, used only to explain an invalid run. Git now runs outside the sandbox and can write outside the run folder, so the copy is evidence, not proof.
- **Privacy of the kept files.** `config/.claude.json` or `home/.claude.json` may hold an account e-mail, which no scrub removes. The results folder is mode 700 and only kept under `--keep` (`:900`, `:657`); no record carries it. Acceptable; say it in the doc line on `--keep`.
- **Git outside the sandbox runs anything git can start** — `git -c alias.x='!cmd' x`, `-c core.hooksPath=…`, `core.sshCommand`, `core.fsmonitor` — with the person's write and network reach. `GIT_ALLOW_PROTOCOL=file` (`:72`) limits git's own transports; the root's and origin's config and hooks are compared (`:208-211`); a `-c` on the command line is not. ADR-0138 and `docs/evals/real-run.md:35` must say it.
- **Tests that change with the clause**: `tests/real-run-in-the-sandbox.oracle.test.sh:13-14` and `:86`. No other test pins `allow`, the ignore or ADR-0137 (grep of `tests/`); `tests/real-run-before-a-release.test.sh:413-415` reads `Bash(<w>:*)` for `gh` only.
- **Parallel lane s210** changes `method/` and `bin/po-lint`; this story touches neither, nor `po/`.
- **The main checkout** holds an untracked `docs/evals/real-2026-11-24-v0.12.0.md`; once this story lands the same path, the lead removes that copy before pulling `main` (not this lane's job).

## Open questions
- Who appends to the global ignore (Claude Code's own settings-local entry is the likely one) stays unproven; the kept pair of the next invalid run, if any, answers it. Not needed to fix the run.
- Whether `Bash(git *)` matches `git -C <path> …` in Claude Code's matcher: the docs' wildcard form says yes; only a real run shows it. s210 makes the method use that form.

## Complexity
2 → 3: the kept pair needs a label-to-path mapping for sixteen label families and a content copy at hold time; the settings and the list are one line each.

## Split
—
