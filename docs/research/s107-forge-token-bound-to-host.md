# Research — s107-forge-token-bound-to-host

[Story](../stories.md)

## Structuring facts
- **False assumption of the story.** Criterion `other_forges_through_their_cli_only` says `glab` binds each token to its host in its configuration. It does only when no token sits in the environment: glab's documented token precedence (docs.gitlab.com/cli/authentication, "Token precedence", read 2026-10-13) uses `GITLAB_TOKEN`, then `GITLAB_ACCESS_TOKEN`, then `OAUTH_TOKEN` **before** the credentials stored for the host, for every host. With `GITLAB_TOKEN` exported, `glab api` on a clone from `gitlab.attacker.tld` sends that token there. Dropping the `curl` fallback alone does not close the leak.
- `tea` 1.0 (README of gitea/tea, main, read 2026-10-13) also takes credentials from the environment: `GITEA_TOKEN` with its instance in `TEA_HOST` or `GITEA_INSTANCE_URL`. What tea does with `GITEA_TOKEN` and no instance variable is not documented there (open question 1).
- The whole leak lives in one paragraph, `method/commands/po-ship.md:29` ("How it is read"): `curl` fallback with `GH_TOKEN`/`GITHUB_TOKEN`, `GITLAB_TOKEN`, `GITEA_TOKEN`, sent to whatever host `origin` names.
- The probe `https://<host>/api/v1/version` (`method/commands/po-ship.md:27`) says nothing about credentials: the text neither sends nor forbids a token on it.
- `/po-setup` reads the forge "exactly as `/po-ship` reads it" (`method/commands/po-setup.md:27`): fixing po-ship fixes setup, as the story says.

## Story
The forge reading sends a token only to the host it was issued for, so a repository cloned from a third-party instance never collects a token of another instance (major security finding of the s102 review, ADR-0079). Complexity 2, `Owns`: `method/commands/po-ship.md`, `tests/forge-token-host.test.sh`.
- `env_token_only_for_github` — in `## The forge's review rule`, the `curl` + environment-variable fallback exists for github.com only (`GH_TOKEN` or `GITHUB_TOKEN`); `GITLAB_TOKEN` and `GITEA_TOKEN` are no longer cited as a fallback.
- `other_forges_through_their_cli_only` — GitLab and Forgejo/Gitea are read only through `glab` / `tea`, which bind each token to its host in their configuration; with no CLI configured for `origin`'s host, the forge is unreadable and the report says so.
- `unknown_host_gets_no_token` — the `/api/v1/version` probe goes without a token, and no call to an unrecognised host carries one.
Owner-rejected options (2026-10-13): binding the token by a `*_HOST` variable (glab only); keeping the fallback as is.

## Current code
- `method/commands/po-ship.md:24-46` — `## The forge's review rule`, between Step 0 and Step 1 (position checked by `tests/ship-follows-forge.test.sh:72-77`).
  - `:27` Which forge: `github.com` → GitHub; host containing `gitlab` → GitLab; other host → probe `/api/v1/version`, JSON with `version` → Forgejo/Gitea; else unreadable.
  - `:29` How it is read: `gh api`, `glab api`, `tea api` (after `tea api --help`); otherwise `curl` with the env token "the environment already gives that CLI"; "No CLI and no token → the forge is unreadable."
  - `:32-34` the three signals, API paths per forge; `:38` verdict, an unreadable signal leaves the line's value and "the report names the call that failed and why".
- `method/commands/po-ship.md:86` — finish line names the effective `Ship confirmation` and, when unreadable, "the call that failed".
- Host classification by substring (`:27`) means any host containing `gitlab` (e.g. `gitlab.attacker.tld`) is treated as GitLab and sent to `glab`.

## Attachment points
- Paragraph `**How it is read.**` at `method/commands/po-ship.md:29` — rewritten.
- Paragraph `**Which forge.**` at `method/commands/po-ship.md:27` — gains "the probe carries no token" and "no token for an unrecognised host".
- New test file `tests/forge-token-host.test.sh`, reusing the `section_of` helper pattern of `tests/ship-follows-forge.test.sh:11` (the helper is defined per file, not in `tests/lib.sh`).

## Verified interfaces
- `tests/lib.sh:11` `fail`; `tests/lib.sh:5-6` `ROOT`, `METHOD`; no `section_of` nor `holds` in lib.sh — each test file defines its own (`tests/ship-follows-forge.test.sh:11,13`).
- `tests/run.sh:9-27` runs every `test_*` of each file in its own process; focused run `bash tests/run.sh forge-token-host.test.sh`.
- Phrases `tests/ship-follows-forge.test.sh:31-32` require inside the forge section, verbatim: ``host `github.com` → GitHub``, ``a host containing `gitlab` → GitLab``, `/api/v1/version`, `` `gh api` ``, `` `glab api` ``, `` `tea api` ``, `No CLI and no token → the forge is unreadable`.
- `gh` honours `GH_TOKEN`/`GITHUB_TOKEN` for github.com only (`GH_ENTERPRISE_TOKEN` for other hosts) — GitHub is detected only on host `github.com`, so its env token goes to its own issuer. `gh` installed here (`/usr/bin/gh`); `glab` and `tea` are not, so their behaviour is from their docs only.
- ADR-0079:33 "via sa CLI quand elle est installée", "pas de jeton : la forge est illisible" — compatible with the story; ADR-0079:46 tokens never written nor shown — kept.

## Traps
- `tests/ship-follows-forge.test.sh:32` needs `No CLI and no token → the forge is unreadable` verbatim in the section: the rewrite must keep that sentence (it stays true for GitHub).
- `tests/ship.test.sh`, `tests/ship-through-pr.test.sh`, `tests/review-tree-gate.test.sh` also read po-ship.md; none checks lines 27-29 (grep of `token`/`curl` in `tests/ship*.sh` only hits ship-follows-forge:32). Keep them green.
- `tests/overlap.test.sh`: no 8-word run shared with Killer SaaS — write in own words.
- A new criterion test checking that `GITLAB_TOKEN` is "no longer cited" must look at the section, not the whole file — and if the plan names `GITLAB_TOKEN` in an "unset these" clause, the test must distinguish "cited as fallback" from "named to be scrubbed" (pivot of the plan).
- No migration, no dependency, no code: the change is method text plus one bash test file.

## Open questions
1. With `GITEA_TOKEN` exported and neither `TEA_HOST` nor `GITEA_INSTANCE_URL`, does tea 1.0 send `GITEA_TOKEN` to the host of the current repository's remote? Unverified; the plan treats it as possible.
2. Exact tea 1.0 flag to pin the host or login for `tea api` — tea 1.0 changed its flags (README); unverified without the binary.
3. How to close the glab environment precedence — a security choice the story did not settle (ADR-0077: security goes to the owner). Options and recommendation are in the plan and in the proposed ADR-0083.

## Complexity
Story 2 → 2. One paragraph of method text and one test file; the extra weight is the decision on environment tokens for the CLIs, not volume.

## Split
—
