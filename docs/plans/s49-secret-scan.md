---
track: flow
validated: yes
---
# Plan (short track) — s49-secret-scan

[Story](../stories.md)

Written by the planner on the short track: this file stands in for both the research and the plan; there is no `docs/research/s49-secret-scan.md`. Decision recorded in `docs/decisions/ADR-0028-secrets-refuses-par-po-gate-sans-dependance.md`.

Track: flow. `Story track: auto`, complexity 2 written in `docs/stories.md` ≤ `Flow threshold: 2`, no escalation signal, five tasks.

## Verified facts
No assumption of the story proved false. Facts the implementer needs:
- `method/hooks/pre-commit:4` only `exec`s `po-gate.sh pre-commit`; the whole check lives in `pre_commit()` at `method/hooks/po-gate.sh:62-75`.
- `po-gate.sh:65` returns 0 on any branch not `story/*`, before anything else runs. The secret scan must run **before** that line, or `secret_scan_runs_on_every_branch` cannot hold.
- `po-gate.sh:67-68` lists staged files with `--no-renames` and refuses the commit when the listing fails: the fail-closed habit to keep (ADR-0028).
- `po-gate.sh:17` `refuse()` prints `po-gate: …` to stderr and returns 1; `:8` is the header line describing `pre-commit`, to update.
- `po-gate.sh:81-94` is the precedent for a pattern table (`<fields>|<ERE>`, one row per rule, POSIX ERE, no `\s`, `\b` or `{n}` so macOS awk and mawk read it), passed to awk through `ENVIRON` (`:122`, `:174-179`). `:116` pins the diff options so user config cannot change the format: `-c core.quotePath=false`, `--no-color --no-ext-diff --no-textconv`, `--src-prefix=a/ --dst-prefix=b/`. `:126-131` `header_path` strips quotes and the `a/`/`b/` prefix.
- `git diff --cached` works on an unborn branch (checked on a scratch repo: the first commit shows as `--- /dev/null`/`+++ b/a`), so the scan needs no special case for a repository's first commit.
- Hooks are opt-in: `bin/polype:47` `--hooks`, `bin/polype:194-203` sets `core.hooksPath .polype/hooks` only then. Law 6 must therefore keep the manual `git status --porcelain` check for projects without hooks.
- Law 6's secret bullet is `method/AGENTS.md:95`. `tests/structure.test.sh:55` pins its opening `**Secrets never enter git.**`: keep those exact words.
- `method/agents/implementer.md:43` and several framing commands (`po-brief.md:46`, `po-prd.md:53`, `po-stories.md:47`…) keep their own `git status --porcelain` check; they are outside `Owns` and stay as they are.
- `tests/gate.test.sh:6-12` `sandbox` builds a committed repo on `main` with `src/app.txt`; `:14` `plan yes|no` writes `docs/plans/s01-a.md`; `:15` `passes` hides stderr; `:155-167` shows the end-to-end hook pattern (`core.hooksPath`, worktree, `git commit` captured into `err`). `tests/lib.sh:9` neutralises global git config.
- `tests/gate.test.sh:149-153` `test_pre_commit_ignores_non_story_branch` stages a harmless line on `main` and expects success: it stays green and keeps proving the plan check is story-only.
- No file in `method/`, `tests/`, `docs/` or `bin/` currently holds a string shaped like a PEM header or one of the four token formats (`grep -rnE` on the repository).

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text, no data | absent — `po-gate.sh` is a bash script, no store |
| New screen | absent — story text | absent — CLI hook only |
| Authorization or tenant scope | absent — story text: a content check, no role or tenant | absent — `pre_commit()` `po-gate.sh:62-75` has no user notion |
| API contract | absent — story text: same `pre-commit` subcommand | absent — dispatch `po-gate.sh:233-240` unchanged, exit codes stay 0/1 |
| New dependency | absent — story text | absent — bash, git, awk only; gitleaks turned down in ADR-0028 |

## Story
`s49-secret-scan` — the pre-commit refuses a staged secret, so the `.env` rule no longer depends on an agent's care.
- `pre_commit_refuses_a_staged_env_file` — a staged `.env` or `.env.*` is refused, except `.env.example`.
- `pre_commit_refuses_obvious_keys` — an added line holding a PEM private key or a known token (AWS, GitHub, Stripe, Anthropic) is refused; the message names the file and never shows the value.
- `secret_scan_runs_on_every_branch` — applies outside `story/*` too, unlike the plan check.
- `rules_point_at_the_secret_gate` — Law 6 says the pre-commit refuses secrets when hooks are on, and keeps the `git status` check for projects that do not turn them on.

## Tasks
1. [x] **Environment files.** In `po-gate.sh`, add `secret_scan()` (called from task 3). List staged paths with `git -c core.quotePath=false diff --cached --name-only --no-renames --diff-filter=d -z` (`d` lowercase: a staged deletion of a tracked `.env` is the fix, it must pass). A path whose basename is `.env` or matches `.env.*`, at any depth, and is not `.env.example` → one line `po-gate: <path>: environment file staged — unstage it and list it in .gitignore`. A failed listing → refuse the commit. Fails if wrong: `test_pre_commit_refuses_a_staged_env_file`.
2. [x] **Token patterns.** Add a `SECRET_PATTERNS` table beside `FLOOR_PATTERNS`, rows `<rule>|<min length>|<POSIX ERE>`, comment saying how to add a format. Rows: `private-key|0|-----BEGIN[A-Z ]*PRIVATE KEY` (RSA, EC, OPENSSH, DSA, ENCRYPTED, PGP blocks); `aws-access-key|20|(AKIA|ASIA)[0-9A-Z]+`; `github-token|40|gh[pousr]_[A-Za-z0-9]+`; `github-token|40|github_pat_[A-Za-z0-9_]+`; `stripe-secret-key|24|(sk|rk)_(live|test)_[A-Za-z0-9]+`; `anthropic-key|40|sk-ant-[A-Za-z0-9_-]+`. Lengths replace `{n}` (convention of `:80`): a match counts only when its token is at least that long; a token preceded by `[A-Za-z0-9_]` does not count (`desk_live_…` is not Stripe). Scan the added lines (`+` but not `+++`) of `git -c core.quotePath=false diff --cached --no-color --no-ext-diff --no-textconv --no-renames --src-prefix=a/ --dst-prefix=b/ -U0` with one awk program reading the table through `ENVIRON`, tracking the file from `+++ b/` (reuse the header logic of `:126-131`) and the line from `@@`. Each hit prints `po-gate: <path>:<line>: <rule> (value not shown)`; **the matched text is never printed or stored in a variable that reaches stderr**. Diff or awk failure → refuse. Publishable Stripe keys (`pk_`) are not secrets and are not matched. Fails if wrong: `test_pre_commit_refuses_obvious_keys`.
3. [x] **Wire it on every branch.** In `pre_commit()`, call `secret_scan` first, before the `story/*` early return of `:65`; any hit (tasks 1 and 2 together, all hits listed) ends with `refuse "refusing the commit: <n> staged secret(s); the values are not shown"`. Update the header comment `:8` to say `pre-commit` refuses staged secrets and environment files on every branch, and code commits to `story/<id>` without an approved plan. Fails if wrong: `test_secret_scan_runs_on_every_branch`.
4. [x] **Law 6.** Rewrite `method/AGENTS.md:95`, keeping `**Secrets never enter git.**` first: `.env*` files must be ignored; when the hooks are on (`core.hooksPath` at `.polype/hooks`), the pre-commit refuses a staged environment file other than `.env.example` and an added line holding a private key or a known token, on every branch; projects that do not turn the hooks on keep checking that `git status --porcelain` lists no environment file before any commit, and stop if it does. Fails if wrong: `test_rules_point_at_the_secret_gate`.
5. [x] **Tests, then the suite.** Add the four functions below to `tests/gate.test.sh`, then run `bash tests/run.sh gate.test.sh structure.test.sh`, then the full suite once (`Full suite: execute-end`). Commit plan, ADR-0028, code and tests together.

## Run interdicts
- No literal fake key anywhere in the diff: every test value is assembled at run time by concatenation (e.g. `"AKI""A$(printf 'Q%.0s' {1..16})"`, `"-----BEGIN RSA PRIV""ATE KEY-----"`). `grep -rnE '(AKIA|ASIA)[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{36}|sk-ant-[A-Za-z0-9_-]{20}|(sk|rk)_(live|test)_[A-Za-z0-9]{16}|BEGIN [A-Z ]*PRIVATE KEY' method tests docs` stays empty.
- No value is echoed: the refusal messages carry path, line and rule only.
- `plan_validated`, `ship_allowed`, `verif_current`, `floor_guard` and the dispatch `case` of `po-gate.sh` keep an empty diff; `method/hooks/pre-commit` unchanged.
- Existing tests of `tests/gate.test.sh` unchanged; `tests/structure.test.sh` unchanged and green.
- Files outside `Owns` keep an empty diff: `method/agents/implementer.md`, the framing commands, `bin/polype`, `docs/installation.md`, anything under `.claude/` or `.polype/` (installed copies).
- No new tool invoked by `po-gate.sh` beyond bash, git and awk (ADR-0028).

## The pivot
That scanning only the **added lines of the staged diff** with a short table catches what the story calls obvious keys, without blocking legitimate work. Ways it could be wrong:
- A pattern too wide blocks ordinary commits (a long all-caps identifier starting with `AKIA`, a doc quoting a regex). The left boundary and minimum lengths are the defence; the reviewer should try a harmless near-miss.
- Placing the scan after `:65` silently limits it to story branches: `test_secret_scan_runs_on_every_branch` must commit on `main`.
- awk printing `$0` or the match in a debug path would leak the value: the tests assert the value is absent from stderr.

## Files touched
- `method/hooks/po-gate.sh` (header, `SECRET_PATTERNS`, `secret_scan()`, first lines of `pre_commit()`)
- `method/AGENTS.md` (Law 6 bullet, line 95)
- `tests/gate.test.sh` (four new functions)
- `docs/plans/s49-secret-scan.md`, `docs/decisions/ADR-0028-secrets-refuses-par-po-gate-sans-dependance.md`

## Test strategy
Bash, on throwaway repos via `sandbox`, the only layer this repository has. Four new functions, within `Test budget` 25; each would go red if its rule were removed.
- `test_pre_commit_refuses_a_staged_env_file` — on `main`: staged `.env` refused; `config/.env.local` refused; `.env.example` passes; a tracked `.env` (committed before staging, no hook in the sandbox) then `git rm -q --cached .env` passes. Refusal stderr names the path.
- `test_pre_commit_refuses_obvious_keys` — for each of the five formats (PEM, AWS, GitHub, Stripe, Anthropic) built at run time: write `token = <value>` to `src/leak.txt`, stage, expect refusal whose stderr contains `src/leak.txt` and does **not** contain the value; `git reset -q` between. Then a near-miss line (`pk_live_` + 24 chars, and `desk_live_` + 24 chars) passes.
- `test_secret_scan_runs_on_every_branch` — a staged `.env` refused on `main`, on `feature/x`, and on `story/s01-a` with `plan yes` (the plan's approval does not bypass it); plus one end-to-end `git commit` through `core.hooksPath` on `main` (the pattern of `:155-167`) refused with `po-gate:` in its output.
- `test_rules_point_at_the_secret_gate` — `contains "$METHOD/AGENTS.md"`: `**Secrets never enter git.**`, `the pre-commit refuses`, `git status --porcelain`, `.env.example`.
Neutralising check for the reviewer: move the `secret_scan` call after `:65` → only the every-branch test turns red; drop a row of the table → the keys test turns red.

## Done when
- `bash tests/run.sh` green.
- One commit on `story/s49-secret-scan` with code, tests, plan and ADR-0028; a review with no open critical finding.
