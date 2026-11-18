---
validated: yes
---
# Plan — s192-ship-reads-the-forge

[Story](../stories.md) · [Research](../research/s192-ship-reads-the-forge.md)

Branch `story/s192-ship-reads-the-forge`. Read `docs/research/s192-ship-reads-the-forge.md` first; this plan builds on it without repeating it.

Settled by the owner on 2026-11-18. Decision d-0041: option A of [ADR-0130](../decisions/ADR-0130-le-ship-entre-dans-po-par-un-verbe-a-sous-etapes.md), now `accepted` — in `po`, one `ship` verb with steps; the tasks below are written for it. Decision d-0042: ADR-0079 holds over the wider wording the research's first fact flagged, and ADR-0083 holds for the tokens; `absence_is_not_an_error` and `token_never_travels` are reworded in `docs/stories.md` by a framing pull request, and this plan follows that wording.

## Story
`po ship forge [--target <branch>]` reads the forge and prints the verdict and the effective `Ship confirmation`; `/po-ship` and `/po-setup` read its output instead of the rule. Criteria: `verdict_follows_the_three_signals`, `absence_is_not_an_error`, `chosen_is_never_rewritten`, `token_never_travels`, `ship_command_reads_the_value` (model-read), `version_goes_up` (minor: 0.7.0 → 0.8.0).

The output, one object, exit 0 whatever the verdict:

| Field | Values |
| --- | --- |
| `forge` | `github`, `gitlab`, `forgejo`, `null` (no `origin`, unrecognised host) |
| `verdict` | `collaborative`, `solo`, `unreadable` (`po-ship.md:40`) |
| `signals` | `writer`, `codeowners`, `protection`: `true`, `false`, `null` (unreadable) |
| `failed` | `[{signal, call, reason}]`: `call` an API path or `git show <ref>:<path>`, `reason` an HTTP status or a fixed word (`unreachable`, `no-cli-no-token`, `no-glab-login`, `no-tea-login`, `no-origin`, `unrecognised-host`, `no-origin-target`, `list-truncated`, `unknown-login`); never a tool's stderr, never the `origin` URL |
| `line` | the `Ship confirmation` value as written, `null` when absent (at setup) |
| `effective` | `human` / `automatic` (`po-ship.md:42`), `null` when `line` is |
| `rewrite` | `human (forge)` / `automatic (forge)` / `null` (`po-ship.md:44`) |

Refusals, exit 2: `not-a-project`, `usage` (no step or another step than `forge`), `unknown-option`, `missing-setting` (neither `--target` nor `Target branch`).

GitLab and Forgejo/Gitea: read exactly through the calls `po-ship.md:31-36` names, through `glab` and `tea` launched without their token variables; `forge` says which. Never proven on a real instance (#75 `parked`): the tests use doubles only, and any failure gives `unreadable`, never `solo`. Nothing else changes for them (ADR-0081: no pull request opened there).

## Reuse

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Program lookup for `curl`, `glab`, `tea` | in this repository: `gh_program` (`po/src/trust/forge.rs:18-23`), generalised to `program(var, default)` | — |
| API call that keeps the HTTP status | new code beside `gh_api` (`forge.rs:37-48`), same `Command` shape | `gh_api` returns `None` for 404, 403 and unreachable alike; no HTTP crate is allowed (ADR-0118) |
| Feeding the token to `curl` on stdin | in this repository: the writer-thread pattern of `po/src/trust/landed.rs:17-33` | — |
| Reading a setting, a file on `origin/<target>` | in this repository: `Project::setting` (`project.rs:55`), `Project::on_target` (`:92`) | — |
| Suffix of `Ship confirmation` | in this repository: the stripping of `po/src/context/lanes.rs:188-196`, copied into `po/src/ship/` | sharing it would change `po/src/context/`, outside `Owns` |
| Step dispatch and option parsing | in this repository: the shape of `po record` (`po/src/record/mod.rs:80-100`) | — |
| JSON | dependency already installed: `serde` derive, `serde_json` (ADR-0118) | — |

## Acceptance tests

| Oracle file | cksum |
| --- | --- |
| `tests/ship-reads-the-forge.oracle.test.sh` | `1510592051 17386` |

| Criterion | Test |
| --- | --- |
| `verdict_follows_the_three_signals` | `test_verdict_follows_the_three_signals` |
| `absence_is_not_an_error` | `test_absence_is_not_an_error` — the absences ADR-0079 names (404 on the protection, empty ruleset list, the plan's 403) read `false`; a rights 403 on the protection, a 404 on the collaborators, an unreachable forge and no `origin` read `unreadable` (d-0042) |
| `chosen_is_never_rewritten` | `test_chosen_is_never_rewritten` |
| `token_never_travels` | `test_token_never_travels` |
| `ship_command_reads_the_value` | — rule read by a model, judged in review; candidate for a `po-eval` control arm (#208). Its word counts are held by the ceilings of task 8 |
| `version_goes_up` | `test_version_goes_up` |

The oracle's doubles are named by `PO_GH`, `PO_CURL`, `PO_GLAB`, `PO_TEA` and also put first on `PATH`; `forge_read` is the only line that writes the command's shape.

## Tasks
1. [x] **Version.** `0.7.0` → `0.8.0` in `po/Cargo.toml`, `po/Cargo.lock` (the `name = "po"` entry) and `POLYPE_VERSION` of `bin/polype`. Test: `test_version_goes_up`; `bin/po-version-check` passes.
2. [x] **Launcher** in `po/src/trust/forge.rs`: `program(var, default)` for `PO_GH`, `PO_CURL`, `PO_GLAB`, `PO_TEA` (empty = default), `gh_program` becoming one call of it; an `ApiAnswer` = `Status(u16, Value-or-text)` | `Unreachable`, read from a tool run with `-i`/`--include`: the first line `HTTP/<v> <code> …`, the body after the first line that is empty once `\r` is trimmed; no status line → `Unreachable`. stdin null (piped only for `curl`'s header), stderr null always. `glab` runs with `env_remove` of `GITLAB_TOKEN`, `GITLAB_ACCESS_TOKEN`, `OAUTH_TOKEN`; `tea` with `env_remove` of `GITEA_TOKEN`, `TEA_HOST`, `GITEA_INSTANCE_URL`. `gh_api`, `checks`, `pull_request_closed` keep their behaviour. Test: `test_token_never_travels`; `tests/trust-signals*.test.sh` and `tests/ship-order-and-closed-pr*.test.sh` green unchanged.
3. [x] **Which forge** in `po/src/ship/forge.rs`: `git remote get-url origin` (read-only `project.git`); host taken after dropping scheme, userinfo and port, from the https, scp-like and ssh forms; `owner/repo` from the path, `.git` dropped. `github.com` → GitHub; host containing `gitlab` → GitLab; otherwise the probe `curl -q -sS --max-time 10 https://<host>/api/v1/version`, no header, no `-n`, stdin null, and a JSON answer holding `version` → Forgejo/Gitea. No `origin` or none of these → `forge: null`, verdict `unreadable`, `failed` naming `no-origin` or `unrecognised-host`. Test: `test_absence_is_not_an_error` (no origin), `test_token_never_travels` (probe, userinfo).
4. [x] **How it is read** (same file). GitHub: `gh auth status --hostname github.com` succeeds → `gh api -i --hostname github.com <path>`; otherwise a non-empty `GH_TOKEN` or else `GITHUB_TOKEN` → `curl -q -sS -i --max-time 20 -H @- https://api.github.com/<path>`, stdin `Authorization: Bearer <token>` and `Accept: application/vnd.github+json`; otherwise every signal `null`, reason `no-cli-no-token`. GitLab: `glab auth status --hostname <host>` fails → `no-glab-login`; else `glab api -i --hostname <host> <path>` with `:id`, as `po-ship.md:34,36` write it. Forgejo/Gitea: `tea api --help` fails → `no-tea-login`; the `tea` login whose URL host is `<host>` (from `tea logins list --output json`, unverified on a real `tea`, ADR-0083 Neutral), none → `no-tea-login`; else `tea api --login <name> <path>`. Own login: GitHub `user.login`, GitLab `user.username`, Forgejo `user.login`; unreadable → `unknown-login`. Test: `test_token_never_travels`; task test `test_github_read_is_pinned_and_curl_skips_curlrc`.
5. [x] **The signals and the verdict** (same file), by `po-ship.md:33-42`. *Writer*: GitHub `repos/{o}/{r}/collaborators?per_page=100`, `permissions.push` true and login ≠ own (ASCII case-insensitive); GitLab `projects/:id/members/all?per_page=100`, `access_level` ≥ 30; Forgejo collaborators then `…/collaborators/<login>/permission` `write`/`admin`. A full page (100) without a positive entry → `null`, `list-truncated`. *CODEOWNERS*: `Project::on_target("origin/<target>", p)` for `CODEOWNERS`, `docs/`, `.github/`, `.gitlab/`, `.gitea/`, `.forgejo/`; owners are the words after the pattern on non-comment lines; an owner other than `@<own login>` → `true`; no file → `false`; `origin/<target>` missing → `null`, `no-origin-target`; own login unknown and only `@user` owners → `null`. *Protection*: GitHub `branches/<t>/protection` (`required_pull_request_reviews.required_approving_review_count` > 0) or `rules/branches/<t>` (a `pull_request` rule, `parameters.required_approving_review_count` > 0); GitLab `projects/:id/approval_rules` (`approvals_required` > 0); Forgejo `branch_protections`, the entry whose `rule_name` or `branch_name` is `<t>`, `required_approvals` > 0. Absence, by `:38` and ADR-0079 only: a 404 on a protection call, an empty list, a GitHub 403 whose body `message` holds `Upgrade to GitHub Pro`; any other status or `Unreachable` → `null` with its `failed` entry. Verdict: one `true` → `collaborative`; all `false` → `solo`; else `unreadable`. Test: `test_verdict_follows_the_three_signals`, `test_absence_is_not_an_error`; task test `test_full_collaborator_page_is_unreadable`.
6. [x] **The step and the value** in `po/src/ship/mod.rs` and `po/src/main.rs`: `Some("ship") => ship::main(&rest)`, usage `po <state|next|inbox|answer|record|run|continue|ship> [arguments]`; `po ship forge [--target <branch>]` with the refusals of the Story section; `line` from `Ship confirmation`; suffix read as `lanes.rs:188-196` reads it, by a copy in `po/src/ship/` (a bare value reads as `(forge)`, `AGENTS.md` « Reading settings »). `effective`: `collaborative` → `human`; else the value without suffix, except `(forge)` or bare on `solo` → `automatic`. `rewrite`: only for `(forge)` or bare, only when the value changes — `collaborative` and not `human` → `human (forge)`; `solo` and `human` → `automatic (forge)`; never on `unreadable`, never for `(chosen)`. Nothing is written: no file, no ref, no forge call but reads. Test: `test_chosen_is_never_rewritten`; task tests `test_setup_reads_with_target_only` (project with `.polype/version` and no `AGENTS.local.md`: `line` and `effective` `null`, verdict read) and `test_ship_refuses_unknown_step_and_option`.
7. [x] **Contract**: one row in `docs/interface-agent.md` « Les verbes du chef de projet » for `ship forge`, `ship forge --target <branche>`: fields of the table above, the refusals, « n'écrit rien, n'interroge que la forge d'`origin` ». Judged in review.
8. [x] **The two commands.** `method/commands/po-ship.md`: `## The forge's review rule` keeps its heading and place between Step 0 and Step 1, keeps « It never opens, skips or replaces `po-gate ship-allowed <id>` », replaces `:25-44` by: run `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" ship forge` from the worktree, `effective` is this ship's `Ship confirmation`, `verdict`, `signals` and `failed` go to the finish; `po` missing or exit 2 → stop and name `polype install`. `:46-48` stay, their trigger becoming a non-null `rewrite` (s194 moves them). `:62` stays verbatim; `:96` names the `forge` the command reports; `:103` is shortened. ≤ 2 702 words. `method/commands/po-setup.md`: `:27` runs `po ship forge --target <Target branch>` once question 1 gives the branch (keeping « once question 1 of Step 2 has given `Target branch` » and « ## The forge's review rule »), `po` missing → the forge counts as unreadable and the question says why; `:75` and `:90` keep their phrases and refer to that output; not one word more than 2 274. Lower the ceilings to the new counts: `tests/ship-files-the-other-findings.oracle.test.sh:9` (`po-ship.md`) and `tests/defects-seen-on-products.oracle.test.sh:14` (`po-setup.md`). Test: those two ceilings; the tests of Traps outside `Owns` stay green.
9. [x] **Phrase tests that fall** (see Test strategy), then the full suite through `po-run --story s192-ship-reads-the-forge --label 'Unit suite' -- 'bash tests/run.sh'`, after committing (`tests/readme-onboarding.test.sh` clones HEAD, #254).

## Scene viewpoints
—

## Run interdicts
- `po` writes nothing: no file, no ref, no `git fetch`; `po/src/project.rs` `git()` keeps its read-only body and comment.
- No forge call other than the reads listed in tasks 3–5; no `-X`/`--method` on `gh`, no `pr`, no `issue`.
- No token in an argument, an output, a file, a test or a log; `curl` gets it on stdin only, and only for `https://api.github.com/`.
- `po/Cargo.toml` `[dependencies]` unchanged (ADR-0118).
- Empty diff: `method/AGENTS.md`, `method/commands/po-intake.md`, `method/commands/po-drive.md`, `method/hooks/`, `po/src/next/`, `po/src/context/`, `.claude/`, `.polype/`, `tests/ship-reads-the-forge.oracle.test.sh`.
- `po-ship.md` Steps 0–3 unchanged except `:96` and `:103`; `po-ship.md:62` verbatim.
- No test reaches a real forge: every test sets `PO_GH`, `PO_CURL`, `PO_GLAB`, `PO_TEA` to doubles and puts them first on `PATH`.
- The `(forge)` line rewrite (branch, draft pull request) stays prose until s194; cleanup and findings untouched.

## The pivot
The three-way reading of each signal — positive, absent, unreadable — rests on the HTTP status `gh api -i` and `curl -i` print. Ways it could be wrong: (1) a forge answering through a proxy or redirect prints several header blocks (`curl -i` without `-L` prints one; compare against a `curl` double emitting `HTTP/1.1 301` → must be `null`); (2) gh changes its error output (checked 2026-11-18: status on line 1, body after the blank line, exit 1); (3) a rights 403 read as absence would turn a protected repository `solo`: ADR-0079 and d-0042 forbid it, and the oracle's rights-403 case catches it; GitHub telling the two 403s apart only by `message` stays to watch (ADR-0079 Neutral).

## Files touched
`po/src/ship/mod.rs`, `po/src/ship/forge.rs`, `po/src/trust/forge.rs`, `po/src/main.rs`, `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`, `docs/interface-agent.md`, `method/commands/po-ship.md`, `method/commands/po-setup.md`, `tests/ship-reads-the-forge.test.sh`, `tests/ship-follows-forge.test.sh`, `tests/forge-token-host.test.sh` (deleted), `tests/ship-resumes-cleanly.test.sh`, `tests/ship-files-the-other-findings.oracle.test.sh`, `tests/defects-seen-on-products.oracle.test.sh`, `docs/decisions/ADR-0130-…` (accepted, d-0041), `docs/research/`, `docs/plans/`.

## Test strategy
Oracle: 5 tests. Task tests in `tests/ship-reads-the-forge.test.sh`, against the same doubles: `test_github_read_is_pinned_and_curl_skips_curlrc` (every `gh api` call carries `--hostname github.com`, every `curl` call starts with `-q`; replaces `ship-resumes-cleanly`'s phrase test), `test_full_collaborator_page_is_unreadable`, `test_setup_reads_with_target_only`, `test_ship_refuses_unknown_step_and_option`, `test_gitlab_and_forgejo_signals` (a GitLab member at 30 and a Forgejo `write` collaborator each give `collaborative` through answering doubles). 10 tests, within `Test budget` 25.

Phrase assertions that fall, one by one, with no phrase test in their place:
- `tests/ship-follows-forge.test.sh` — `test_setup_reads_review_rules_from_the_forge`: the seven forge-section phrases of `:31-32` (`host \`github.com\` → GitHub`, `a host containing \`gitlab\` → GitLab`, `/api/v1/version`, `` `gh api` ``, `` `glab api` ``, `` `tea api` ``, `No CLI and no token → the forge is unreadable`); the rest stays. `test_collaborative_repo_forbids_agent_merge`: removed, its seven phrases (`permissions.push`, the CODEOWNERS bullet, `required_approving_review_count`, the collaborative `human`, the solo `automatic`, `"Upgrade to GitHub Pro"`, `all count as "no protection"`) now held by the oracle. `test_forge_tightening_switches_to_human`: `collaborative and not \`human\` → \`human (forge)\``, `solo and \`human\` → back to \`automatic (forge)\``, `the line's value stands, and the report names the call that failed`; the draft-branch phrases and the position check stay. `test_chosen_value_never_moves`: its two forge-section phrases; the two « Reading settings » ones stay. 19 in all. `test_ship_gate_unchanged`, `test_setting_records_its_origin`, `test_template_defaults_trust_the_gates`, `test_pr_wait_does_not_block_the_fleet` stay whole.
- `tests/forge-token-host.test.sh` — all three tests (`test_env_token_only_for_github`, `test_other_forges_through_their_cli_only`, `test_unknown_host_gets_no_token`) fall; the file is deleted (`tests/run.sh` fails a file with no test). Held by `test_token_never_travels`.
- `tests/ship-resumes-cleanly.test.sh` — `test_forge_read_pins_and_skips_curlrc` falls; `test_resumed_ship_merges_the_pushed_head` stays.

Visual checks: none. Type check: `Typecheck` is `—`; `cargo build --release --locked` without warning, run by `tests/run.sh`.

## Done when
The oracle and task tests pass, the full suite passes through `po-run`, `po-ship.md` ≤ 2 702 words and `po-setup.md` ≤ 2 274, the version reads 0.8.0 in three places, one commit on `story/s192-ship-reads-the-forge`, a review with no open critical finding, landed through a pull request.
