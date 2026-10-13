# Review — s107-forge-token-bound-to-host

Diff reviewed: `git diff main...story/s107-forge-token-bound-to-host`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 48684dfc9731eab6a18ea2eddb1f6effd2724618

## Ownership
I listed the diff with `git diff --name-status main...story/s107-forge-token-bound-to-host`. It is one commit, d1fb935.
- [x] Every path is inside `Owns`. `method/commands/po-ship.md` (M) and `tests/forge-token-host.test.sh` (A) match the `Owns` line exactly. The research, plan and verif files for s107 are the story's own evidence. `docs/decisions/ADR-0083-un-jeton-ne-part-que-vers-l-hote-qui-l-a-emis.md` is added (status A) and the plan names it, so it is in scope too.
- [x] No path is inside another running story's `Owns`. The only other running `story/` worktree is s104-escalation-contract. Its `Owns` and its diff do not include `po-ship.md` or this test file.

## Evidence reused
- [x] `po-gate verif-current s107-forge-token-bound-to-host` exited 0, so I reused the record (`Verification mode: record`). The Unit suite `bash tests/run.sh` exited 0 on the same code outside `docs/`. The project has no type check (`Typecheck: —`), so none was run. Its "Not proven here" section says no `glab`, `tea` or forge call was made.
- [x] `po-gate qa-current` is not required. With `Surface: —` and `QA stage: —`, the story does not go to QA.

## Plan
- [x] Tasks 1–5 are all present and nothing outside the plan was added. Task 2 is split into two paragraphs (lines 29 and 31). That is a layout choice, and the content is word for word what the plan asked for.
- [x] Each run interdict is respected:
  - `method/commands/po-setup.md` has an empty diff.
  - `po-ship.md` changes only in the "Which forge" and "How it is read" paragraphs.
  - `tests/ship-follows-forge.test.sh`, `ship.test.sh` and `ship-through-pr.test.sh` have empty diffs.
  - Nothing changed under `.claude/` or `.polype/`, and `docs/stories.md` was not edited.
  - No call was made to a real forge.

## References
- [x] I confirmed the `gh` facts on the local binary (`/usr/bin/gh`):
  - `gh api --hostname` exists, with default `github.com`.
  - `GH_TOKEN` and `GITHUB_TOKEN` are used only when the target is `github.com` or a subdomain of `ghe.com`.
  - `GH_HOST` is used only when no hostname is given, so pinning `--hostname github.com` is the right guard.
- [ ] `glab api --hostname`, glab's token precedence, `tea api`, and tea's environment variables come only from documentation. Neither `glab` nor `tea` is installed. See Not verified.
- [x] The test helpers `fail` and `$METHOD` come from `tests/lib.sh`. The local `section_of` and `holds` match the pattern in `ship-follows-forge.test.sh`.

## Rules
- [x] `AGENTS.md` conventions are respected: method text is in English, there is one test file named after the story, the commit message is in English, and the overlap test is green in the full suite.
- [x] No accepted ADR is contradicted. ADR-0079 (a token is never shown or written; no token means the forge is unreadable) is kept. ADR-0083 records the owner's choice of option A, and the code applies option A.

## Tests
- [x] Floor: `po-gate floor-guard s107-forge-token-bound-to-host main` exited 0, so no check was lowered.
- [x] The assertions cover the three criteria. None of the six empty test shapes applies: the tests grep the real method file.
- [x] Budget: 3 of 25.
- [x] Bite. After each mutation I ran only `forge-token-host.test.sh`, undid the change with `git checkout --`, and confirmed with `git diff --exit-code` that the file was clean:
  - `GITLAB_TOKEN`/`GITEA_TOKEN` put back into the GitHub `curl` sentence → 1 failing (`env_token_only_for_github`).
  - glab env scrub removed → 1 failing (`other_forges_through_their_cli_only`).
  - tea env scrub removed → 1 failing (`other_forges_through_their_cli_only`).
  - "The probe carries no token" sentence removed → 1 failing (`unknown_host_gets_no_token`).
  - `--hostname github.com` pin removed from the `gh api` sentence → **0 failing**. See finding 1.
- [x] The story makes no test useless.

## Neighbours
- [x] `method/commands/po-setup.md:27` reads the forge "exactly as `/po-ship` reads it", so it inherits the fix without change, as the story says. A grep of `method/` and `docs/` finds `GITLAB_TOKEN`/`GITEA_TOKEN` only in older s102 documents, which are history, and in the s107 files.

## Lenses
Lenses run: security. The trigger is that the diff changes the HTTP calls whose host comes from `git remote get-url origin`, and which token they carry.
- [x] The tokens follow the rule now:
  - The GitHub fallback goes to the fixed `https://api.github.com`, never to the host named by `origin`.
  - GitLab and Forgejo/Gitea are read only through a CLI logged in for that host, with the environment token variables removed.
  - The probe to an unrecognised host carries no token.
  - The leak found in the s102 review is closed in the text.

## Findings
1. minor — `method/commands/po-ship.md:29` — The `--hostname github.com` pin on `gh api` is not tested; removing it fails no test. The plan's pivot names this pin as what keeps a `GH_HOST`/`GH_ENTERPRISE_TOKEN` setup out of the GitHub read. Without it, the wrong instance would be read, not a token leaked, because an Enterprise token still goes to its own host. That is why this is minor.
2. minor — `method/commands/po-ship.md:27` — "plain `curl`, no header, no `.netrc`" leaves out `~/.curlrc`. A user's curlrc can add `--netrc` or an `Authorization` header to every call. Saying `curl -q`, which skips curlrc, would make "carries no token" hold on any machine. The config belongs to the user, not to an attacker, so this is minor.
3. minor — `docs/plans/s107-forge-token-bound-to-host.md:7-18` — The plan still opens with "Waiting for the owner… Once decided, set ADR-0083 to `accepted`", but the frontmatter says `validated: yes` and ADR-0083 is `accepted`. The text is stale and misleads whoever reads it next.

## Not verified
- **glab's behaviour.** I did not check that `glab api --hostname <host>` exists, that `GITLAB_TOKEN`, `GITLAB_ACCESS_TOKEN` and `OAUTH_TOKEN` are its only token variables, or that it falls back to no other host's login. `glab` is not installed, so this rests on the research's reading of the docs. A person should check it with `glab api --help` and glab's "Token precedence" and "Environment variables" pages. That includes CI auto-login (`GLAB_ENABLE_CI_AUTOLOGIN`, `CI_JOB_TOKEN`).
- **tea's behaviour.** I did not check whether `tea api` exists in tea 1.0, which flag picks "the tea login whose URL is that host" (the text names none, e.g. `--login`), or whether tea reads other variables than `GITEA_TOKEN`, `TEA_HOST` and `GITEA_INSTANCE_URL` (e.g. `GITEA_SERVER_URL`/`GITEA_SERVER_TOKEN`). `tea` is not installed and I had no network access; ADR-0083 marks this unverified too. A person should check the tea 1.0 binary on a first Forgejo read.
- **The owner's approval.** ADR-0083 says the owner chose option A on 2026-10-13. I cannot check that consent from the repository; a person should confirm it.
- **No real run.** No forge was read on a GitLab, Forgejo or GitHub instance, and the method is only prose plus grep tests. Doing a ship on a GitLab clone with `GITLAB_TOKEN` exported, and watching the outgoing request, is the only end-to-end proof.

Max severity: minor
Ship allowed: yes
